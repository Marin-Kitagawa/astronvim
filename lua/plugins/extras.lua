-- Extra quality-of-life plugins, chosen to not overlap with anything already
-- here (snacks, blink, mini, flash, grapple, grug-far, ...). None of them bind
-- keys that are taken:
--   - diffview uses <Leader>gD/gF/gH (snacks git keys are all lowercase)
--   - hlslens only touches n/N/*/# (unmapped in this config)
--   - treesitter-context / illuminate / lightbulb are automatic, no keys

---@type LazySpec
return {
  -- nvim-treesitter-context -- sticky header showing the function/class the
  -- cursor is inside when it has scrolled out of view.
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    opts = {},
    -- toggle with :TSContextToggle
  },

  -- vim-illuminate -- highlight every other occurrence of the word/symbol under
  -- the cursor (LSP-aware, falls back to treesitter/regex). Pairs with snacks
  -- `]]`/`[[` which jumps between references; this one makes them visible.
  {
    "RRethy/vim-illuminate",
    event = "VeryLazy",
    config = function()
      require("illuminate").configure {
        providers = { "lsp", "treesitter", "regex" },
        filetypes_denylist = { "dirbuf", "dirvish", "fugitive", "alpha", "NvimTree", "neo-tree", "toggleterm", "TelescopePrompt" },
        under_cursor = false,
      }
    end,
  },

  -- diffview.nvim -- full git diff/history UI: staged vs unstaged side-by-side,
  -- per-file history, merge-conflict resolution view. Complements the quick
  -- `<Leader>gd` hunks picker from snacks, which stays as it is.
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
    keys = {
      { "<Leader>gD", "<Cmd>DiffviewOpen<CR>", desc = "Diff view (working tree)" },
      { "<Leader>gF", "<Cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
      { "<Leader>gH", "<Cmd>DiffviewFileHistory<CR>", desc = "Git history (whole repo)" },
    },
    opts = {},
  },

  -- nvim-hlslens -- when jumping with n/N/*/#, shows "match 3 of 12" style lens
  -- and highlights all visible matches. Search itself stays plain (flash's
  -- search mode is disabled), this only annotates it.
  {
    "kevinhwang91/nvim-hlslens",
    keys = {
      {
        "n",
        "<Cmd>execute('normal! ' . vim.v.count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>",
        silent = true,
        desc = "Next search match (with lens)",
      },
      {
        "N",
        "<Cmd>execute('normal! ' . vim.v.count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>",
        silent = true,
        desc = "Previous search match (with lens)",
      },
      { "*", "*<Cmd>lua require('hlslens').start()<CR>", silent = true, desc = "Search word under cursor" },
      { "#", "#<Cmd>lua require('hlslens').start()<CR>", silent = true, desc = "Search word under cursor (backwards)" },
      { "g*", "g*<Cmd>lua require('hlslens').start()<CR>", silent = true, desc = "Search substring under cursor" },
      { "g#", "g#<Cmd>lua require('hlslens').start()<CR>", silent = true, desc = "Search substring under cursor (backwards)" },
    },
    opts = { calm_down = true },
  },

  -- nvim-lightbulb -- shows a sign in the signcolumn when an LSP code action
  -- is available at the cursor (actions themselves stay on <Leader>la).
  {
    "kosayoda/nvim-lightbulb",
    event = "VeryLazy",
    opts = {
      autocmd = { enabled = true },
      sign = { enabled = true, text = "󰌵" },
      ignore = {
        ft = { "markdown", "help", "cheater" },
      },
    },
  },
}
