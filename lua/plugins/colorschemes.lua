-- Colorschemes.
--
-- Catppuccin Mocha is the default. The others are installed but lazy-loaded, so
-- they cost nothing until used -- switch live with `<Leader>uC` (snacks colorscheme
-- picker, already bound in snacks.lua).
--
-- `lazy = true` + `priority = 1000` on the non-default themes means lazy.nvim only
-- loads one at startup but any of them can be pulled in on demand by the picker.

---@type LazySpec
return {
  -- tell AstroUI which colorscheme to apply once plugins are loaded
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = { colorscheme = "catppuccin" },
  },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      background = { light = "latte", dark = "mocha" },
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
      },
      -- Catppuccin themes each plugin explicitly rather than relying on generic
      -- highlight groups, so every plugin in this config is opted in here.
      integrations = {
        aerial = true,
        blink_cmp = true,
        gitsigns = true,
        grug_far = true,
        markdown = true,
        mini = { enabled = true, indentscope_color = "" },
        native_lsp = { enabled = true, underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          information = { "undercurl" },
          warnings = { "undercurl" },
        } },
        neotree = true,
        noice = true,
        notify = true,
        snacks = { enabled = true },
        todo_comments = true,
        treesitter = true,
        which_key = true,
      },
    },
  },

  { "folke/tokyonight.nvim", lazy = true, priority = 1000, opts = { style = "night" } },
  { "rose-pine/neovim", name = "rose-pine", lazy = true, priority = 1000, opts = { variant = "moon" } },
  { "rebelot/kanagawa.nvim", lazy = true, priority = 1000, opts = { theme = "dragon" } },
  { "neanias/everforest-nvim", lazy = true, priority = 1000 },
}
