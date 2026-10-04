# Neovim Configuration (AstroNvim v6)

The documentation lives in AsciiDoc:

- **[README.adoc](README.adoc)** — overview, plugin map, requirements, treesitter/zig setup
- **[docs/keybindings.adoc](docs/keybindings.adoc)** — complete keybinding reference
- **[docs/maintenance.md](docs/maintenance.md)** — environment, post-`:Lazy update` workflow, troubleshooting

> [!WARNING]
> After `:Lazy update` moves `nvim-treesitter`, run `:TSUpdate` — skipping this breaks
> highlighting with `Query error ... Invalid field name`. Run `:Lazy update` **twice**
> (plugins are pinned to AstroNvim's snapshot). Details in [docs/maintenance.md](docs/maintenance.md).
