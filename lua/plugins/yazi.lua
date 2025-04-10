--[[
return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  dependencies = { "folke/snacks.nvim", lazy = true },
  keys = {
    -- 👇 in this section, choose your own keymappings!
    {
      "<leader>-",
      mode = { "n", "v" },
      "<cmd>Yazi<cr>",
      desc = "Open yazi at the current file",
    },
    {
      -- Open in the current working directory
      "<leader>cw",
      "<cmd>Yazi cwd<cr>",
      desc = "Open the file manager in nvim's working directory",
    },
    {
      "<c-up>",
      "<cmd>Yazi toggle<cr>",
      desc = "Resume the last yazi session",
    },
  },
  ---@type YaziConfig | {}
  opts = {
    -- if you want to open yazi instead of netrw, see below for more info
    open_for_directories = false,
    keymaps = {
      show_help = "<f1>",
    },
  },
  -- 👇 if you use `open_for_directories=true`, this is recommended
  init = function()
    -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
    -- vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
}
]]--

---@module "lazy"
---@module "yazi"

---@type LazySpec
return {
  {
    "mikavilpas/yazi.nvim",
    -- dir = "~/git/yazi.nvim/",
    event = "VeryLazy",
    dependencies = { "folke/snacks.nvim", lazy = true },
    keys = {
      { "<up>", "<cmd>Yazi<cr>", desc = "Open yazi" },
      { "<s-up>", "<cmd>Yazi cwd<cr>", desc = "Open yazi in cwd" },
      { "<c-up>", "<cmd>Yazi toggle<cr>", desc = "Open yazi with the last hovered file" },
    },
    ---@type YaziConfig
    opts = {
      open_multiple_tabs = true,
      open_for_directories = true,
      floating_window_scaling_factor = {
        width = 0.95,
        height = 0.95,
      },
      -- log_level = vim.log.levels.DEBUG,
      integrations = {
        grep_in_directory = "snacks.picker",
        grep_in_selected_files = "snacks.picker",
      },
    },
    init = function()
      -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
      vim.g.loaded_netrwPlugin = 1
    end,
  },
  {
    name = "easyjump.yazi",
    url = "https://gitee.com/DreamMaoMao/easyjump.yazi.git",
    lazy = true,
    build = function(plugin)
      require("yazi.plugin").build_plugin(plugin)
    end,
  },
  {
    "Rolv-Apneseth/starship.yazi",
    lazy = true,
    build = function(plugin)
      require("yazi.plugin").build_plugin(plugin)
    end,
  },
  {
    "yazi-rs/flavors",
    name = "yazi-flavor-catppuccin-macchiato",
    lazy = true,
    build = function(spec)
      require("yazi.plugin").build_flavor(spec, {
        sub_dir = "catppuccin-macchiato.yazi",
      })
    end,
  },
  {
    -- https://github.com/yazi-rs/plugins
    "yazi-rs/plugins",
    name = "yazi-rs-plugins",
    lazy = true,
    build = function(plugin)
      require("yazi.plugin").build_plugin(plugin, {
        sub_dir = "git.yazi",
      })
    end,
  },
  {
    "ndtoan96/ouch.yazi",
    lazy = true,
    build = function(plugin)
      require("yazi.plugin").build_plugin(plugin)
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      -- ../../../../../.local/share/nvim/lazy/neo-tree.nvim/lua/neo-tree/defaults.lua
      sources = {
        "filesystem",
      },
      mappings = {
        ["<cr>"] = { "open", config = { expand_nested_files = true } }, -- expand nested file takes precedence
      },
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
        hijack_netrw_behavior = "disabled",
      },
      follow_current_file = { enabled = true },
    },
  },
}
