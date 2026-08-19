-- flash.nvim -- jump anywhere on screen in about two keystrokes.
--
-- Press `s`, type the two characters you want to land on, then press the label
-- that appears next to the match. Also upgrades `f`/`t`/`F`/`T` so they keep
-- working past the current line, and makes `/` searches labelled.
--
-- `s` is free here: AstroNvim binds nothing to it, and mini.surround is moved to
-- the `gs` prefix (see mini_modules.lua) specifically so flash can own `s`.

---@type LazySpec
return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {
    modes = {
      -- keep `/` and `?` usable as plain search; labels only on demand
      search = { enabled = false },
      char = {
        -- f/t/F/T enhanced, but do not hijack `;`/`,` repeat
        jump_labels = true,
      },
    },
  },
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter select" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter search" },
    { "<C-s>", mode = "c", function() require("flash").toggle() end, desc = "Toggle flash search" },
  },
}
