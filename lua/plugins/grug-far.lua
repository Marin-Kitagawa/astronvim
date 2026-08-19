-- grug-far.nvim -- project-wide search and replace in a normal buffer.
--
-- Opens a buffer with search/replace/filter fields at the top and live results
-- below. Edit the fields, watch matches update, then apply. Backed by ripgrep,
-- which is already on PATH here.
--
-- This is the piece the config was missing: snacks.picker greps well but cannot
-- replace across a project.

---@type LazySpec
return {
  "MagicDuck/grug-far.nvim",
  cmd = { "GrugFar", "GrugFarWithin" },
  opts = { headerMaxWidth = 80 },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<Leader>r"] = { desc = " Replace" }
        maps.n["<Leader>rr"] = { function() require("grug-far").open() end, desc = "Search / replace in project" }
        maps.n["<Leader>rf"] = {
          function() require("grug-far").open { prefills = { paths = vim.fn.expand "%" } } end,
          desc = "Search / replace in this file",
        }
        maps.n["<Leader>rw"] = {
          function() require("grug-far").open { prefills = { search = vim.fn.expand "<cword>" } } end,
          desc = "Replace word under cursor",
        }
        maps.x["<Leader>r"] = {
          function() require("grug-far").with_visual_selection() end,
          desc = "Search / replace selection",
        }
      end,
    },
  },
}
