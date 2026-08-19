-- undotree -- browse the undo history as a tree.
--
-- Vim keeps every branch of your edits, not just a linear undo stack, but there
-- is no built-in way to see them. `<Leader>U` opens the tree so you can recover
-- a change you undid past.

---@type LazySpec
return {
  "mbbill/undotree",
  cmd = { "UndotreeToggle", "UndotreeShow", "UndotreeFocus" },
  init = function()
    vim.g.undotree_WindowLayout = 2
    vim.g.undotree_SetFocusWhenToggle = 1
  end,
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        opts.mappings.n["<Leader>U"] = { "<Cmd>UndotreeToggle<CR>", desc = "Undo tree" }
      end,
    },
  },
}
