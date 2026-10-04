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
  -- Two Windows-specific fixes over yazi.nvim's build_plugin helper:
  -- 1. yazi 26 on Windows reads its config from %APPDATA%\yazi\config, NOT
  --    ~/.config/yazi (the helper's default).
  -- 2. The helper installs via fs_symlink, which fails with EPERM without
  --    Developer Mode. Plain recursive copies work everywhere.
  local yazi_config_dir = vim.env.YAZI_CONFIG_HOME
    or vim.fs.joinpath(vim.env.APPDATA or vim.fn.expand "~", "yazi", "config")
  local function copy_tree(src, dst)
    vim.fn.mkdir(dst, "p")
    for name, ftype in vim.fs.dir(src) do
      if name == ".git" then -- don't ship repo internals into the yazi config
        goto continue
      end
      local s, d = vim.fs.joinpath(src, name), vim.fs.joinpath(dst, name)
      if ftype == "directory" then
        copy_tree(s, d)
      else
        assert(vim.uv.fs_copyfile(s, d), "failed to copy " .. s)
      end
      ::continue::
    end
  end
  local function install_yazi_plugin(src, name)
    local to = vim.fs.joinpath(yazi_config_dir, "plugins", name)
    vim.fn.delete(to, "rf")
    copy_tree(src, to)
  end
  {
    -- https://github.com/yazi-rs/plugins (official collection, GitHub-hosted)
    "yazi-rs/plugins",
    name = "yazi-rs-plugins",
    lazy = true,
    build = function(plugin)
      install_yazi_plugin(vim.fs.joinpath(plugin.dir, "git.yazi"), "git.yazi")
    end,
  },
  {
    -- flash.nvim-style jumping inside yazi: press F, type the first character
    -- of an entry, land on it. GitHub-hosted replacement for the gitee-only
    -- easyjump.yazi (see docs/maintenance.md → Deliberately excluded plugins).
    "yazi-rs/plugins",
    name = "yazi-rs-plugins-jump-to-char",
    lazy = true,
    build = function(plugin)
      install_yazi_plugin(vim.fs.joinpath(plugin.dir, "jump-to-char.yazi"), "jump-to-char.yazi")
    end,
  },
  {
    "ndtoan96/ouch.yazi",
    lazy = true,
    build = function(plugin)
      install_yazi_plugin(plugin.dir, "ouch.yazi")
    end,
  },
--   {
--     "nvim-neo-tree/neo-tree.nvim",
--     opts = {
--       -- ../../../../../.local/share/nvim/lazy/neo-tree.nvim/lua/neo-tree/defaults.lua
--       sources = {
--         "filesystem",
--       },
--       mappings = {
--         ["<cr>"] = { "open", config = { expand_nested_files = true } }, -- expand nested file takes precedence
--       },
--       filesystem = {
--         filtered_items = {
--           hide_dotfiles = false,
--         },
--         hijack_netrw_behavior = "disabled",
--       },
--       follow_current_file = { enabled = true },
--     },
--   },
}

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

