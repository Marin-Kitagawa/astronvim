return {
  "saghen/blink.cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  version = "*",
  dependencies = {
    "rafamadriz/friendly-snippets", -- Required for snippets
  },
  build = "cargo build --release",
  keys = {
	  -- chartoggle
	  {
	    '<C-;>',
	    function()
	  	  require('blink.chartoggle').toggle_char_eol(';')
	    end,
	    mode = { 'n', 'v' },
	    desc = 'Toggle ; at eol',
	  },
	  {
	    ',',
	    function()
	  	  require('blink.chartoggle').toggle_char_eol(',')
	    end,
	    mode = { 'n', 'v' },
	    desc = 'Toggle , at eol',
	  },

	  -- -- tree
	  -- { '<C-e>', '<cmd>BlinkTree reveal<cr>', desc = 'Reveal current file in tree' },
	  -- { '<leader><E', '<cmd>BlinkTree toggle<cr>', desc = 'Reveal current file in tree' },
	  -- { '<leader><leader>e', '<cmd>BlinkTree toggle-focus<cr>', desc = 'Toggle file tree focus' },
  },
  ---@module "blink.cmp"
  ---@type blink.cmp.Config
  opts = {
    -- Use opts function to ensure we don't conflict with other config loading mechanisms
    -- Keymap presets
    keymap = {
      preset = "default",
      ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-e>"] = { "hide" },j
      ["<C-y>"] = { "select_and_accept" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-b>"] = { "scroll_documentation_up", "fallback" },
      ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    },

    appearance = {
      -- Sets the fallback highlight groups to nvim-cmp's highlight groups
      -- Useful for when your theme doesn't support blink.cmp
      -- use_nvim_cmp_as_default = true,
      -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- nerd_font_variant = "mono",
    },

    completion = {
      menu = { 
        auto_show = true,
        auto_show_delay_ms = 500
      },
      ghost_text = { enabled = false },
    },

    sources = {
      default = {
        "lsp",
        "path",
        "snippets",
        "buffers"
      },
    },

    -- Experimental signature help
    signature = { enabled = true },

    cmdline = {
      enabled = true,
      ---@diagnostic disable-next-line: assign-type-mismatch
      sources = function()
        local type = vim.fn.getcmdtype()
        if type == "/" or type == "?" then
          return { "buffer" }
        end
        if type == ":" or type == "@" then
          return { "cmdline", "path" }
        end
        return {}
      end,
      completion = {
        menu = { auto_show = true },
        ghost_text = { enabled = false },
      },
    },
  }
}
