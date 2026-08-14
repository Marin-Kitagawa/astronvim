return {
  "saghen/blink.cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  version = "v1.0.*",
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
