# AstroNvim Template

**NOTE:** This is for AstroNvim v6+

A template for getting started with [AstroNvim](https://github.com/AstroNvim/AstroNvim)

## ⚠️ Read this before running `:Lazy update`

After `:Lazy update` moves `nvim-treesitter`, rebuild the parsers or highlighting will
break with `Query error ... Invalid field name`:

```vim
:TSUpdate
```

Also note that pinned plugins need `:Lazy update` run **twice**.

This machine has no usable MSVC, so treesitter parsers are compiled with **zig** through
a `cl.exe`-compatible shim ([`scripts/zig-cl.c`](scripts/zig-cl.c)), wired up
automatically by `lua/plugins/treesitter-zig-cc.lua`. `:TSInstall` and `:TSUpdate` work
normally as a result — no manual setup and nothing to put on `PATH`.

Full details, rationale and troubleshooting: **[`docs/maintenance.md`](docs/maintenance.md)**.

## 🛠️ Installation

#### Make a backup of your current nvim and shared folder

```shell
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

#### Create a new user repository from this template

Press the "Use this template" button above to create a new repository to store your user configuration.

You can also just clone this repository directly if you do not want to track your user configuration in GitHub.

#### Clone the repository

```shell
git clone https://github.com/<your_user>/<your_repository> ~/.config/nvim
```

#### Start Neovim

```shell
nvim
```
