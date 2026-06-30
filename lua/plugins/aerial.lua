-- Override AstroNvim v4's aerial pin.
-- AstroNvim v4's lazy_snapshot pins aerial.nvim to `version = "^2.2"` (-> v2.7.0),
-- which crashes on Neovim 0.12+ ("attempt to call method 'type' (a nil value)" in
-- treesitter/extensions.lua). aerial <4.0 used `iter_matches({ all = false })`, an
-- API behavior removed in nvim 0.12. aerial 4.0.0 dropped support for nvim <0.12 and
-- fixed the treesitter backend, so we track ^4 here to clear the ^2.2 ceiling.
return {
  "stevearc/aerial.nvim",
  version = "^4",
}
