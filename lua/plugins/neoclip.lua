-- neoclip -- persistent yank/clipboard history.
--
-- neoclip has no UI of its own: it needs a picker to browse the history. The
-- telescope dependency used to be commented out, which left the plugin
-- recording yanks with no way to ever look at them. Telescope is installed
-- anyway (cheatsheet.nvim depends on it), so it is wired up here. `<Leader>y`
-- opens the history; entry is free (nothing else used it).
return {
  "AckslD/nvim-neoclip.lua",
  dependencies = {
    { "nvim-telescope/telescope.nvim" },
  },
  config = function()
    require('neoclip').setup()
  end,
  keys = {
    {
      "<leader>y",
      function()
        require("telescope").load_extension "neoclip"
        require("telescope").extensions.neoclip.neoclip()
      end,
      desc = "Clipboard history",
    },
  },
}
