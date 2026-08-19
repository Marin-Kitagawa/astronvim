-- grapple.nvim -- pin the handful of files you are actually working on and jump
-- between them instantly, instead of fuzzy-finding the same paths all day.
--
-- `<Leader>ma` tags the current file, `<Leader>mm` opens the tag list, and
-- `<Leader>1`..`<Leader>4` jump straight to the first four tags. Tags are scoped
-- per git repository and persist across sessions.

---@type LazySpec
return {
  "cbochs/grapple.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Grapple",
  opts = { scope = "git_branch" },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<Leader>m"] = { desc = "󰛢 Grapple" }
        maps.n["<Leader>ma"] = { function() require("grapple").toggle() end, desc = "Tag / untag this file" }
        maps.n["<Leader>mm"] = { function() require("grapple").toggle_tags() end, desc = "Open tag list" }
        maps.n["<Leader>mn"] = { function() require("grapple").cycle_tags "next" end, desc = "Next tag" }
        maps.n["<Leader>mp"] = { function() require("grapple").cycle_tags "prev" end, desc = "Previous tag" }
        for i = 1, 4 do
          maps.n["<Leader>" .. i] = {
            function() require("grapple").select { index = i } end,
            desc = "Grapple tag " .. i,
          }
        end
      end,
    },
  },
}
