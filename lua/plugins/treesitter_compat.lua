-- Applies the Neovim 0.12 query-handler shim in `lua/ts_compat.lua`.
-- See that file for the full explanation of what breaks and why.

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  optional = true,
  -- This replaces AstroNvim's own `init` (lazy.nvim keeps the last spec's value),
  -- so the two lines it performs are reproduced verbatim before the shim runs.
  init = function(plugin)
    -- == AstroNvim default: add queries + custom predicates to the rtp early ==
    require("lazy.core.loader").add_to_rtp(plugin)
    pcall(require, "nvim-treesitter.query_predicates")

    -- Override the handlers nvim-treesitter just registered.
    require("ts_compat").apply()

    -- Fallback: if `query_predicates` was not reachable above it will be required
    -- when the plugin actually loads, re-registering the broken handlers.
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyLoad",
      callback = function(args)
        if args.data ~= "nvim-treesitter" then return end
        require("ts_compat").apply()
        return true -- one-shot
      end,
    })
  end,
}
