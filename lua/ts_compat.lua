-- Neovim 0.12 compatibility shim for nvim-treesitter's legacy `master` branch.
--
-- AstroNvim v4's lazy_snapshot pins nvim-treesitter to f8aaf5c (2025-03-18), which
-- registers its query predicates/directives with `{ force = true, all = false }`:
--   nvim-data/lazy/nvim-treesitter/lua/nvim-treesitter/query_predicates.lua:19
--
-- Neovim 0.12 removed the `all` option, so handlers now *always* receive
-- `table<integer, TSNode[]>` -- a list of nodes per capture, never a bare node.
-- The legacy handlers do `local node = match[id]` and then call node methods on
-- what is now a plain Lua table. Opening any markdown file with a fenced code
-- block runs `#set-lang-from-info-string!` (queries/markdown/injections.scm:5)
-- during injection parsing and crashes inside the async parse coroutine with:
--   treesitter.lua:196: attempt to call method 'range' (a nil value)
--
-- This re-registers the affected handlers with `force = true`, unwrapping the node
-- list first. Behaviour is otherwise identical to upstream.
--
-- Remove this once nvim-treesitter is on the `main` branch (i.e. after upgrading
-- to AstroNvim v5); `master` is EOL and does not support Neovim 0.12.

local M = {}

--- Unwrap a capture into a single node.
--- The old `all = false` behaviour returned the *last* node captured for an id,
--- so `nodes[#nodes]` reproduces it exactly.
---@param match table<integer|string, TSNode[]|TSNode>
---@param id integer|string
---@return TSNode|nil
local function capture_node(match, id)
  local nodes = match[id]
  if type(nodes) ~= "table" then return nodes end -- already a bare TSNode (userdata)
  return nodes[#nodes]
end

-- Copied verbatim from nvim-treesitter/lua/nvim-treesitter/query_predicates.lua
local html_script_type_languages = {
  ["importmap"] = "json",
  ["module"] = "javascript",
  ["application/ecmascript"] = "javascript",
  ["text/ecmascript"] = "javascript",
}

local non_filetype_match_injection_language_aliases = {
  ex = "elixir",
  pl = "perl",
  sh = "bash",
  uxn = "uxntal",
  ts = "typescript",
}

local function get_parser_from_markdown_info_string(injection_alias)
  local match = vim.filetype.match { filename = "a." .. injection_alias }
  return match or non_filetype_match_injection_language_aliases[injection_alias] or injection_alias
end

--- Re-register the node-list-aware handlers. Safe to call more than once, and
--- must be called *after* nvim-treesitter has registered its own versions.
function M.apply()
  local query = require "vim.treesitter.query"
  local force = { force = true }

  query.add_predicate("nth?", function(match, _, _, pred)
    local node = capture_node(match, pred[2])
    local n = tonumber(pred[3])
    if node and n and node:parent() and node:parent():named_child_count() > n then
      return node:parent():named_child(n) == node
    end
    return false
  end, force)

  query.add_predicate("is?", function(match, _, bufnr, pred)
    local node = capture_node(match, pred[2])
    if not node then return true end

    -- Avoid circular dependencies
    local locals = require "nvim-treesitter.locals"
    local _, _, kind = locals.find_definition(node, bufnr)

    return vim.tbl_contains({ unpack(pred, 3) }, kind)
  end, force)

  query.add_predicate("kind-eq?", function(match, _, _, pred)
    local node = capture_node(match, pred[2])
    if not node then return true end
    return vim.tbl_contains({ unpack(pred, 3) }, node:type())
  end, force)

  query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
    local node = capture_node(match, pred[2])
    if not node then return end

    local type_attr_value = vim.treesitter.get_node_text(node, bufnr)
    if not type_attr_value then return end

    local configured = html_script_type_languages[type_attr_value]
    if configured then
      metadata["injection.language"] = configured
    else
      local parts = vim.split(type_attr_value, "/", {})
      metadata["injection.language"] = parts[#parts]
    end
  end, force)

  query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
    local node = capture_node(match, pred[2])
    if not node then return end

    local text = vim.treesitter.get_node_text(node, bufnr)
    if not text then return end

    metadata["injection.language"] = get_parser_from_markdown_info_string(text:lower())
  end, force)

  query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
    local id = pred[2]
    local node = capture_node(match, id)
    if not node then return end

    local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
    if not metadata[id] then metadata[id] = {} end
    metadata[id].text = string.lower(text)
  end, force)
end

return M
