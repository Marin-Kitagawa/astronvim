-- Customize Mason plugins to auto-install tools

---@type LazySpec
return {
  -- use mason-lspconfig to configure LSP installations
  {
    "williamboman/mason-lspconfig.nvim",
    -- overrides `require("mason-lspconfig").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "biome", -- json, javascript, typescript
        "lua_ls", -- lua
        "nil_ls", -- nix (LSP)
        "ruff", -- python (LSP)
        "vtsls", -- javascript, typescript (LSP)
        "yamlls", -- YAML (LSP)
        -- "stylua" is a formatter, handled in mason-null-ls below
      })
    end,
  },
  -- use mason-null-ls to configure Formatters/Linter installation for null-ls sources
  {
    "jay-babu/mason-null-ls.nvim",
    -- overrides `require("mason-null-ls").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "biome", -- json, javascript, typescript (formatter/linter)
        "black", -- python (formatter)
        "luacheck", -- lua (linter)
        "nixfmt", -- nix (formatter)
        "prettier", -- angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml
        "ruff", -- python (linter/formatter)
        "stylua", -- lua
        "yamlfmt", -- YAML formatter
        "yamllint", -- YAML Linter
      })
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    -- overrides `require("mason-nvim-dap").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "python", -- debugpy
        "cpptools", -- c, c++, rust
        "bash-debug-adapter", -- bash
        "delve", -- go (go-debug-adapter)
      })
    end,
  },
}
