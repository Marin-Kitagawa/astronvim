-- This file explicitly disables plugins that conflict with Blink.cmp or Snacks.nvim
return {
  -- Disable nvim-cmp and friends (replaced by Blink.cmp)
  { "hrsh7th/nvim-cmp", enabled = false },
  { "hrsh7th/cmp-nvim-lsp", enabled = false },
  { "hrsh7th/cmp-buffer", enabled = false },
  { "hrsh7th/cmp-path", enabled = false },
  { "saadparwaiz1/cmp_luasnip", enabled = false },
  { "L3MON4D3/LuaSnip", enabled = false }, -- Blink handles snippets internally
  
  -- Disable extra cmp sources that might cause errors
  { "rcarriga/cmp-dap", enabled = false }, -- Fixes the "module 'cmp' not found" error
  
  -- Disable COQ (conflicts with Blink/CMP)
  { "ms-jpq/coq_nvim", enabled = false },
  { "ms-jpq/coq.artifacts", enabled = false },
  { "ms-jpq/coq.thirdparty", enabled = false },

  -- Disable plugins replaced by Snacks.nvim
  { "goolord/alpha-nvim", enabled = false }, -- Replaced by Snacks.dashboard
  { "nvim-tree/nvim-tree.lua", enabled = false }, -- Replaced by Snacks.explorer (optional, but recommended)
  { "nvim-neo-tree/neo-tree.nvim", enabled = false }, -- Replaced by Snacks.explorer (optional)
  { "rcarriga/nvim-notify", enabled = false }, -- Replaced by Snacks.notifier
  { "lukas-reineke/indent-blankline.nvim", enabled = false }, -- Replaced by Snacks.indent
  { "numToStr/Comment.nvim", enabled = false }, -- Built-in to Neovim 0.10+, or use mini.comment if needed
  
  -- Disable nvim-ufo (causes errors with current Treesitter version and was originally disabled)
  { "kevinhwang91/nvim-ufo", enabled = false },
}
