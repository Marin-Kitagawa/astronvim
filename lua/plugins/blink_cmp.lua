-- blink.cmp removed its `blink.chartoggle` module at some point, which these
-- two bindings used to call -- pressing `,` or `<C-;>` just errored out. The
-- toggle is reimplemented here so the mappings keep working: in normal mode it
-- toggles the char at the end of the current line, in visual mode it does so
-- for every line in the selection.
local function toggle_char_eol(char)
  return function()
    local mode = vim.api.nvim_get_mode().mode
    local a, b
    if mode:find "^[vV\22]" then
      a, b = vim.fn.line "'<", vim.fn.line "'>"
    else
      a, b = vim.fn.line ".", vim.fn.line "."
    end
    for lnum = math.min(a, b), math.max(a, b) do
      local text = vim.fn.getline(lnum)
      if text:sub(-1) == char then
        vim.fn.setline(lnum, text:sub(1, -2))
      else
        vim.fn.setline(lnum, text .. char)
      end
    end
  end
end

return {
  "saghen/blink.cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  version = "v1.0.*",
  build = "cargo build --release",
  keys = {
	  -- chartoggle
	  {
	    '<C-;>',
	    toggle_char_eol(';'),
	    mode = { 'n', 'v' },
	    desc = 'Toggle ; at eol',
	  },
	  {
	    ',',
	    toggle_char_eol(','),
	    mode = { 'n', 'v' },
	    desc = 'Toggle , at eol',
	  },

	  -- -- tree
	  -- { '<C-e>', '<cmd>BlinkTree reveal<cr>', desc = 'Reveal current file in tree' },
	  -- { '<leader><E', '<cmd>BlinkTree toggle<cr>', desc = 'Reveal current file in tree' },
	  -- { '<leader><leader>e', '<cmd>BlinkTree toggle-focus<cr>', desc = 'Toggle file tree focus' },
  },
  ---@module "blink.cmp"
  ---@type blink.cmp.Config
  opts = {
    cmdline = {
      enabled = true,
      ---@diagnostic disable-next-line: assign-type-mismatch
      sources = function()
        local type = vim.fn.getcmdtype()
        if type == "/" or type == "?" then
          return { "buffer" }
        end
        if type == ":" or type == "@" then
          return { "cmdline", "path" }
        end
        return {}
      end,
      completion = {
        menu = { auto_show = true },
        ghost_text = { enabled = false },
      },
    },
  }
}
