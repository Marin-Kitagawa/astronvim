-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo({ { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

require "lazy_setup"
require "polish"

require("astrotheme").setup({
  palette = "astrodark",
  background = {
    light = "astrolight",
    dark = "astrodark",
  },
  style = {
    transparent = false,
    inactive = true,
    float = true,
    neotree = true,
    border = true,
    title_invert = true,
    italic_comments = true,
    simple_syntax_colors = true,
  },
  termguicolors = true,
  terminal_color = true,
  plugin_default = "auto",
  plugins = {
    ["noice.nvim"] = false,
    ["bufferline.nvim"] = false,
  },
  palettes = {
    global = {
      my_grey = "#ebebeb",
      my_color = "#ffffff",
    },
    astrodark = {
      ui = {
        red = "#800010",
        accent = "#CC83E3",
      },
      syntax = {
        cyan = "#800010",
        comments = "#CC83E3",
      },
      my_color = "#000000",
    },
  },
  highlights = {
    global = {
      modify_hl_groups = function(hl, c)
        hl.PluginColor4 = { fg = c.my_grey, bg = c.none }
      end,
      ["@String"] = { fg = "#ff00ff", bg = "NONE" },
    },
    astrodark = {
      modify_hl_groups = function(hl, c)
        hl.Comment.fg = c.my_color
        hl.Comment.italic = true
      end,
      ["@String"] = { fg = "#ff00ff", bg = "NONE" },
    },
  },
})
