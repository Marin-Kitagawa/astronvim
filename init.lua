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

-- Astrotheme is not managed via a Lazy plugin spec, so configure it here directly.
require("astrotheme").setup({
  palette = "astrodark",
  background = {
    light = "astrolight",
    dark  = "astrodark",
  },

  style = {
    transparent        = false,
    inactive           = true,
    float              = true,
    neotree            = true,
    border             = true,
    title_invert       = true,
    italic_comments    = true,
    simple_syntax_colors = true,
  },

  termguicolors  = true,
  terminal_color = true,
  plugin_default = "auto",

  -- Disable built-in highlights for plugins we style ourselves
  plugins = {
    ["noice.nvim"]      = false,
    ["bufferline.nvim"] = false,
  },

  palettes = {
    global = {
      my_grey  = "#ebebeb",
      my_color = "#ffffff",
    },
    astrodark = {
      ui     = { red = "#800010", accent = "#CC83E3" },
      syntax = { cyan = "#800010", comments = "#CC83E3" },
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
        hl.Comment.fg     = c.my_color
        hl.Comment.italic = true
      end,
      ["@String"] = { fg = "#ff00ff", bg = "NONE" },
    },
  },
})

-- ── Shell (PowerShell on Windows) ─────────────────────────────────────────
vim.o.shell        = "pwsh"
vim.o.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
vim.o.shellredir   = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
vim.o.shellpipe    = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
vim.o.shellquote   = ""
vim.o.shellxquote  = ""

-- ── UFO folding (disabled — kept for reference) ───────────────────────────
-- vim.o.foldcolumn     = '1'
-- vim.o.foldlevel      = 99
-- vim.o.foldlevelstart = 99
-- vim.o.foldenable     = true
-- vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
-- vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
-- require('ufo').setup({
--   provider_selector = function(bufnr, filetype, buftype)
--     return { 'treesitter', 'indent' }
--   end,
-- })
