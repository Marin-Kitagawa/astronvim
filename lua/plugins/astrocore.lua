-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 500, lines = 10000 }, -- set global limits for large files
      autopairs = true, -- enable autopairs at start
      cmp = false, -- DISABLE 'cmp' feature because we are using Blink.cmp
      diagnostics_mode = 3, -- diagnostic mode on start (0 = off, 1 = no signs/virtual text, 2 = no virtual text, 3 = on)
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "yes", -- Always show sign column to prevent layout shifts
        wrap = false, -- sets vim.opt.wrap
        termguicolors = true, -- Enable 24-bit RGB color
        cursorline = true, -- Highlight current line
        pumblend = 10, -- Popup menu transparency
        winblend = 10, -- Floating window transparency
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
      },
    },
    -- Mappings can be configured through AstroCore as well.
    mappings = {
      -- first key is the mode
      n = {
        -- Navigate buffer tabs with `H` and `L`
        L = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        H = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- Standard Buffer Mappings
        ["<Leader>bD"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Pick to close",
        },
        ["<Leader>b"] = { desc = "Buffers" },
        
        -- Better window navigation
        ["<C-h>"] = { "<C-w>h", desc = "Move to left window" },
        ["<C-j>"] = { "<C-w>j", desc = "Move to lower window" },
        ["<C-k>"] = { "<C-w>k", desc = "Move to upper window" },
        ["<C-l>"] = { "<C-w>l", desc = "Move to right window" },
      },
      t = {
        -- setting a mapping to false will disable it
        -- ["<esc>"] = false,
      },
    },
  },
}
