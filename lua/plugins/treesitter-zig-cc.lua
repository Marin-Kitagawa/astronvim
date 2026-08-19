-- Make `:TSInstall` / `:TSUpdate` work without MSVC, by compiling parsers with zig.
--
-- nvim-treesitter `main` builds parsers through the tree-sitter CLI, which uses
-- Rust's `cc` crate and expects `cl.exe`. There is no usable MSVC on this machine
-- (Build Tools are installed but the Windows SDK component is missing, so there
-- are no headers), and zig cannot be pointed at CC directly -- the cc crate treats
-- CC as a single executable, so `CC="zig cc"` runs `zig -O2 ...` and fails.
--
-- `scripts/zig-cl.c` is a tiny shim that accepts what the cc crate emits and
-- re-invokes `zig cc`. Setting CC to it is enough for parser installs to work
-- normally, including AstroNvim's automatic install-on-demand.
--
-- The shim is built on first use into stdpath("data")/bin and cached there.

local function find_zig()
  local exe = vim.fn.exepath "zig"
  if exe ~= "" then return exe end
  local fallback = "C:/Users/Ahri/Software/Ziglang/zig.exe"
  if vim.uv.fs_stat(fallback) then return fallback end
  return nil
end

---@return string|nil path to the shim, or nil if it could not be produced
local function ensure_shim(zig)
  local bin = vim.fs.joinpath(vim.fn.stdpath "data", "bin")
  local shim = vim.fs.joinpath(bin, "zig-cl.exe")
  if vim.uv.fs_stat(shim) then return shim end

  local src = vim.fs.joinpath(vim.fn.stdpath "config", "scripts", "zig-cl.c")
  if not vim.uv.fs_stat(src) then return nil end

  vim.fn.mkdir(bin, "p")
  local res = vim.system({ zig, "cc", "-O2", "-o", shim, src }, { text = true }):wait()
  if res.code ~= 0 or not vim.uv.fs_stat(shim) then
    vim.notify("zig-cl: build failed\n" .. (res.stderr or ""), vim.log.levels.ERROR)
    return nil
  end

  -- zig drops a .pdb and .lib next to the binary; harmless here, but tidy up
  for _, ext in ipairs { ".pdb", ".lib" } do
    pcall(vim.fn.delete, (shim:gsub("%.exe$", ext)))
  end
  vim.notify("zig-cl: built parser compiler shim", vim.log.levels.INFO)
  return shim
end

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  optional = true,
  init = function()
    if vim.fn.has "win32" == 0 then return end
    local zig = find_zig()
    if not zig then
      vim.notify("zig not found; :TSInstall will fail (no C compiler)", vim.log.levels.WARN)
      return
    end

    local ok, shim = pcall(ensure_shim, zig)
    if not ok or not shim then return end

    -- the shim shells out to zig, and zig is not necessarily on PATH
    vim.env.ZIG_EXE = zig
    vim.env.CC = shim
  end,
}
