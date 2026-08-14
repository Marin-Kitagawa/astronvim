-- Unpin aerial from AstroNvim's lazy_snapshot (`version = "^2.2"`).
--
-- aerial 2.x's treesitter backend calls `Query:iter_matches(..., { all = false })`.
-- Neovim 0.12 dropped that option, so every capture now comes back as a *list*
-- of nodes instead of a single node. The extension code then does
-- `level_node:type()` on a plain table and blows up with:
--   backends/treesitter/extensions.lua:115: attempt to call method 'type' (a nil value)
--
-- Fixed upstream in aerial v3.1.0 (commit f93dcee); v4.0.0 additionally requires
-- Neovim >= 0.12, which this setup runs.
return {
  "stevearc/aerial.nvim",
  version = "^4",
}
