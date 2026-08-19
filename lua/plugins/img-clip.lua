-- img-clip.nvim -- paste an image straight from the clipboard into a document.
--
-- Take a screenshot, then `<Leader>ip` in a markdown file: the image is written
-- into an `assets/` folder next to the file and the correct markdown link is
-- inserted. Pairs with markview.nvim, which renders the result inline.

---@type LazySpec
return {
  "HakonHarnes/img-clip.nvim",
  cmd = { "PasteImage" },
  opts = {
    default = {
      dir_path = "assets",
      relative_to_current_file = true,
      prompt_for_file_name = true,
      drag_and_drop = { enabled = true, insert_mode = true },
    },
  },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<Leader>i"] = { desc = " Image" }
        maps.n["<Leader>ip"] = { "<Cmd>PasteImage<CR>", desc = "Paste image from clipboard" }
      end,
    },
  },
}
