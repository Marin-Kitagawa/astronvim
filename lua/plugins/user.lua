-- Cleaned up User Plugins
---@type LazySpec
return {
  -- Cleaned up Yazi integration
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = { "folke/snacks.nvim" },
    keys = {
      { "<leader>-", "<cmd>Yazi<cr>", desc = "Open yazi at the current file" },
      { "<leader>cw", "<cmd>Yazi cwd<cr>", desc = "Open yazi in cwd" },
    },
    opts = {
      open_multiple_tabs = true,
      open_for_directories = true,
      integrations = {
        grep_in_directory = "snacks.picker",
        grep_in_selected_files = "snacks.picker",
      },
    },
  },
  
  -- Treesitter Context (Sticky headers for functions)
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufRead",
    opts = {
      mode = "cursor",
      max_lines = 3,
    },
  },
  
  -- Wakatime
  { 'wakatime/vim-wakatime', lazy = false },
}
