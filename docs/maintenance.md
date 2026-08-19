# Maintenance notes

Everything in this config that is not stock AstroNvim, why it is here, and what to do
when things move. Written 2026-08-14.

- [The short version](#the-short-version)
- [Environment](#environment)
- [After `:Lazy update`](#after-lazy-update)
- [Treesitter parsers](#treesitter-parsers)
- [Verifying the config](#verifying-the-config)
- [Troubleshooting](#troubleshooting)
- [Background: why any of this is necessary](#background-why-any-of-this-is-necessary)
- [What is customised in this repo](#what-is-customised-in-this-repo)
- [Added plugins and their keymaps](#added-plugins-and-their-keymaps)

---

## The short version

Two things about this machine drive everything below.

1. **Neovim 0.12 changed the treesitter query API.** Plugins written for the old API
   crash. This was fixed by upgrading AstroNvim v4 → v6, which moves nvim-treesitter to
   its `main` branch.
2. **There is no C compiler on this machine.** No `cl.exe`, no MSVC, no Windows SDK, no
   gcc/clang — only zig. nvim-treesitter `main` compiles every parser on demand, so
   `:TSInstall` and `:TSUpdate` **cannot work**. Parsers are built with
   [`scripts/build-ts-parser.ps1`](../scripts/build-ts-parser.ps1) instead.

The single most important consequence:

> **After `:Lazy update` moves nvim-treesitter, run `scripts\build-ts-parser.ps1 -All`.**
> Skipping this leaves parsers built against old grammar revisions while the queries have
> moved on, and highlighting breaks with `Query error ... Invalid field name`.

---

## Environment

| Component | Value |
| --- | --- |
| Neovim | 0.12.2, tree-sitter runtime ABI 15 |
| Neovim install | `C:\Users\Ahri\Software\Neovim` |
| Config | `%LOCALAPPDATA%\nvim` (this repo) |
| Plugin clones | `%LOCALAPPDATA%\nvim-data\lazy` |
| Parsers + queries | `%LOCALAPPDATA%\nvim-data\site\{parser,queries}` |
| AstroNvim | v6, tracked as `version = "^6"` in `lua/lazy_setup.lua` |
| nvim-treesitter | `main` branch, pinned by AstroNvim's `lazy_snapshot.lua` |
| aerial.nvim | `^3` (pinned by AstroNvim) |
| tree-sitter CLI | 0.26.12, installed via Mason |
| zig | 0.16.0-dev, `C:\Users\Ahri\Software\Ziglang\zig.exe` |
| C compiler | **none** — this is the constraint everything else works around |

`lua/lazy_setup.lua` sets `pin_plugins = nil`, which means "pin plugins because a
`version` is being tracked". So plugin versions come from AstroNvim's
`lua/astronvim/lazy_snapshot.lua`, not from whatever is newest upstream.

---

## After `:Lazy update`

Run these in order. Steps 1 and 2 are always required; step 3 only when nvim-treesitter
actually moved.

### 1. Run `:Lazy update` twice

Because plugins are pinned to AstroNvim's snapshot, the first pass updates *AstroNvim
itself* and the second pass applies the snapshot that the new AstroNvim ships. AstroNvim
prints a reminder to do this; it is not optional. One pass leaves plugins on the previous
snapshot's versions.

### 2. Check whether nvim-treesitter moved

```powershell
git -C $env:LOCALAPPDATA\nvim diff -- lazy-lock.json | Select-String nvim-treesitter
```

No output means nothing to do — skip to verification. Any output means the pinned commit
changed, so continue to step 3.

### 3. Rebuild every parser

```powershell
.\scripts\build-ts-parser.ps1 -All
```

This reads the new pinned revision for each installed language straight out of
nvim-treesitter's own `parsers.lua`, rebuilds it with zig, and reinstalls it together with
the matching queries. It takes a few minutes for ~10 languages.

**Why this is mandatory:** parsers and queries are a matched pair. nvim-treesitter ships
queries written against specific grammar revisions. When the plugin updates, the queries
update, but the compiled `.so` files sitting in `site/parser` do not. A query that
references a node type or field the old parser never had fails to compile at runtime.

### 4. Verify

```vim
:checkhealth nvim-treesitter
```

Every installed language should show ✓ in the H/L/F/I/J columns. Then open a Lua and a
Markdown file and confirm highlighting looks right.

> ⚠️ `:checkhealth nvim-treesitter` reports **OK** on this machine even though there is no
> C compiler. It only checks for the tree-sitter CLI, `tar` and `curl`, which are all
> present. A green healthcheck does **not** mean `:TSInstall` will work.

---

## Treesitter parsers

### Why `:TSInstall` does not work

nvim-treesitter `main` installs a parser by running `tree-sitter build`, which shells out
to a C compiler. On Windows that means MSVC. This machine has none, so every install ends
with:

```
Failed to execute the C compiler with the following command:
"cl.exe" "-nologo" "-MD" "-O2" ...
Error: program not found
[nvim-treesitter]: Installed 0/9 languages
```

Zig cannot be dropped in as `CC` either. The tree-sitter CLI is an MSVC-target binary, so
its build harness emits MSVC-style flags (`-nologo`, `/Fo`, `-link`) that zig's
clang-based driver rejects. Setting `CC="zig cc"` also fails outright, because the
harness treats `CC` as a single executable and invokes `zig -O2 ...`, dropping the `cc`.

### What the script does instead

[`scripts/build-ts-parser.ps1`](../scripts/build-ts-parser.ps1) bypasses the CLI entirely:

1. Asks nvim-treesitter for each grammar's repository URL and **pinned revision**.
2. Shallow-clones the grammar at exactly that revision.
3. Compiles `src/parser.c` (plus `scanner.c`/`scanner.cc` when present) with
   `zig cc` / `zig c++` into `site/parser/<lang>.so`.
4. Copies `runtime/queries/<lang>` from the nvim-treesitter checkout into
   `site/queries/<lang>`, so parser and queries always come from the same revision.

Because the revision comes from nvim-treesitter itself, the result is equivalent to what
`:TSInstall` would have produced.

### Adding a language

```powershell
.\scripts\build-ts-parser.ps1 rust yaml typescript
```

Then confirm with `:checkhealth nvim-treesitter`. If a grammar has no pre-generated
`src/parser.c` in its repository the script reports it as failed — those grammars need
`tree-sitter generate`, which is out of scope here.

### Windows-specific gotchas the script handles

`zig cc` emits linker byproducts next to the output that both break things:

- **`<lang>.pdb`** — Neovim globs `parser/<lang>.*` and will try to `dlopen` the `.pdb`
  first, failing with `uv_dlopen: ... is not a valid Win32 application`.
- **`parser.lib`** — nvim-treesitter lists every basename in `site/parser` as an installed
  language, so this shows up as a phantom language called `parser`.

The script deletes both after each build. If you ever build a parser by hand, do the same.

---

## Verifying the config

Headless checks, useful after any change.

**All queries compile against their parsers** — the check that catches parser/query drift:

```powershell
$lua = @'
-- "parsers" matters: a bare get_installed() also returns query-only entries such as
-- `ecma` and `jsx`, which are shared query fragments that javascript/typescript
-- inherit from. They have no parser by design, so checking them always "fails".
local langs = require("nvim-treesitter.config").get_installed("parsers")
table.sort(langs)
local bad = 0
for _, lang in ipairs(langs) do
  local errs = {}
  for _, kind in ipairs({ "highlights", "injections", "folds", "indents" }) do
    local ok, err = pcall(vim.treesitter.query.get, lang, kind)
    if not ok then bad = bad + 1; errs[#errs+1] = kind end
  end
  print(("%-16s %s"):format(lang, #errs == 0 and "OK" or ("BROKEN: " .. table.concat(errs, ", "))))
end
print("broken query files: " .. bad)
'@
$lua | Set-Content "$env:TEMP\qcheck.lua"
# forward slashes matter: backslashes are escape sequences inside a Lua string literal
$tmp = "$env:TEMP".Replace('\', '/')
nvim --headless -c "lua dofile('$tmp/qcheck.lua')" -c "qa!"
```

Expect `broken query files: 0`.

> When writing headless checks, run work via `-c "lua ..." -c "qa!"` at startup rather
> than `vim.defer_fn`. `copilot.vim` spawns `npx @github/copilot-language-server`, which
> keeps a long-lived headless Neovim alive indefinitely.

---

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Query error ... Invalid field name "x"` | Parser and queries are from different nvim-treesitter revisions | `.\scripts\build-ts-parser.ps1 -All` |
| `Failed to execute the C compiler ... cl.exe ... program not found` | Something called `:TSInstall`/`:TSUpdate` | Use the build script; these commands cannot work here |
| `uv_dlopen: ...pdb is not a valid Win32 application` | A `.pdb` left in `site/parser` | Delete `site\parser\*.pdb` |
| A language named `parser` appears as installed | A `.lib` left in `site/parser` | Delete `site\parser\*.lib` |
| `attempt to call method 'type'/'range' (a nil value)` in a treesitter path | A plugin using the pre-0.12 query API — i.e. something is pinned to an old version again | Check what `lazy-lock.json` moved to; see the background section |
| Plugins did not actually update | Only ran `:Lazy update` once with pinned plugins | Run it a second time |
| Headless `nvim` never exits | copilot's language server | Use `-c "..." -c "qa!"`, not `vim.defer_fn` |

---

## Background: why any of this is necessary

### The Neovim 0.12 query API change

Neovim 0.11 deprecated and 0.12 removed the `all` option on
`vim.treesitter.Query:iter_matches()`. Captures are now **always** delivered as a list of
nodes:

```lua
-- before (all = false):  match[capture_id] -> TSNode
-- now:                   match[capture_id] -> TSNode[]
```

Code written for the old shape does `local node = match[id]` and then calls node methods on
what is now a plain Lua table. The two crashes this config hit:

- **aerial 2.x** — `extensions.lua:115`, `attempt to call method 'type' (a nil value)`,
  on every markdown file.
- **nvim-treesitter `master`** — its `query_predicates.lua` registered handlers with
  `{ all = false }`. The markdown injection query calls `#set-lang-from-info-string!`,
  which called `get_node_text()` on a table, producing
  `attempt to call method 'range' (a nil value)` from inside the async parse coroutine.
  The traceback only showed core Neovim frames, never naming the plugin.

Both were symptoms of the same root cause: **AstroNvim v4's `lazy_snapshot.lua` pinned
plugin versions that predate Neovim 0.12.** AstroNvim v5 does not fix this — it explicitly
sets `branch = "master"` on nvim-treesitter. **v6** is the release that migrated to
`main`, so that is the upgrade target.

### The v4 → v6 migration

- `lua/lazy_setup.lua`: `version = "^4"` → `"^6"`.
- `update_notifications` → `update_notification`. v6 renamed it to the singular; the
  plural key was silently ignored (v4 had no such option at all).
- Deleted `lua/ts_compat.lua` and `lua/plugins/treesitter_compat.lua`, shims that
  re-registered nvim-treesitter's query handlers in a node-list-aware way. `main` has no
  `query_predicates.lua`, so there is nothing left to patch.
- Deleted `lua/plugins/aerial.lua`, a `version = "^4"` override. AstroNvim v6 pins aerial
  `^3`, which already contains the fix.

Other v6 breaking changes that did not affect this config, because the relevant specs are
disabled: mason-lspconfig v2, AstroLSP v4, `vim-illuminate` → `snacks.words`,
`nvim-web-devicons` + `lspkind` → `mini.icons`, `telescope` → `snacks.picker`,
`alpha-nvim` → `snacks.dashboard`.

Migrating the old parsers was attempted first and **did not work** — `lua` and `vim` both
failed with `Invalid field name "operator"`, because 2025-09-07 parsers are too old for
`main`'s queries. This is the concrete evidence for why step 3 above is mandatory.

---

## What is customised in this repo

| Path | Purpose |
| --- | --- |
| `lua/lazy_setup.lua` | Tracks AstroNvim `^6`; leader keys; plugin pinning |
| `scripts/build-ts-parser.ps1` | Builds treesitter parsers with zig — the only way to install parsers on this machine |
| `docs/maintenance.md` | This file |
| `lua/plugins/*.lua` | Per-plugin overrides. Several are disabled with `if true then return {} end` on line 1 — that is the AstroNvim template's way of keeping an example around without activating it |

Files disabled this way (`astrocore`, `astrolsp`, `astroui`, `mason`, `none-ls`,
`treesitter`, `user`) are inert. That is why the v6 upgrade was low-risk: almost none of
AstroNvim's core configuration is actually overridden here.

---

## Added plugins and their keymaps

Added 2026-08-19. Everything here is pure Lua, so none of it is affected by the
missing C compiler described above.

### Appearance

| Plugin | Notes |
| --- | --- |
| `catppuccin/nvim` | Default colorscheme, Mocha flavour. Set via `astroui.colorscheme` in `lua/plugins/colorschemes.lua`. Integrations are opted in explicitly for snacks, noice, neo-tree, blink, gitsigns, aerial, which-key, markview and mini |
| `tokyonight` / `rose-pine` / `kanagawa` / `everforest` | Installed but `lazy = true`, so they cost nothing until selected. Switch live with `<Leader>uC` |
| `mini.animate` | Animated window open/close/resize and cursor movement. Its `scroll` animation is **disabled on purpose** — `snacks.scroll` already animates scrolling and running both double-animates it |
| `snacks.zen` / `snacks.dim` | Keymaps for these already existed (`<Leader>z`, `<Leader>Z`, `<Leader>uD`) but the modules were never configured, so they only ran on defaults |

### Workflow

| Keys | Plugin | Does |
| --- | --- | --- |
| `s` / `S` | flash.nvim | Jump to any visible position in ~2 keystrokes; `S` selects a treesitter node |
| `gsa` / `gsd` / `gsr` | mini.surround | Add / delete / replace surrounding quotes, brackets, tags |
| `vif` `cic` `dao` | mini.ai | Text objects for function, class, block/loop/conditional |
| `<Leader>rr` | grug-far.nvim | Project-wide search **and replace** with live preview |
| `<Leader>rw` | grug-far.nvim | Same, prefilled with the word under the cursor |
| `<Leader>rf` | grug-far.nvim | Same, scoped to the current file |
| `<Leader>ma` | grapple.nvim | Tag / untag the current file |
| `<Leader>mm` | grapple.nvim | Open the tag list |
| `<Leader>1`–`<Leader>4` | grapple.nvim | Jump straight to tag 1-4 |
| `<Leader>ip` | img-clip.nvim | Paste an image from the clipboard into the document |
| `<Leader>U` | undotree | Browse undo history as a tree |

### Two things worth knowing

**`s` and `gs`.** flash.nvim takes `s`, which is normally Vim's synonym for `cl`.
mini.surround is therefore moved off its default `s` prefix onto `gs`. If you ever
drop flash, move surround back.

**mini.icons must be set up.** `mini.nvim` bundles a copy of every mini module,
including `mini.icons`, which AstroNvim also installs standalone as
`nvim-mini/mini.icons`. Both provide the `mini.icons` Lua module and either copy can
win on the runtimepath. Whichever wins still has to have `setup()` called, or its
highlight groups (`MiniIconsAzure` and friends) never get created and heirline throws
`Invalid highlight name` every time it draws the statusline. `lua/plugins/mini.lua`
guards this with `if not _G.MiniIcons then require("mini.icons").setup() end`.

### Full inventory

`C:\Users\Ahri\neovim-plugin-inventory.md` lists every plugin on awesome-neovim
(AI section excluded) marked with whether it is installed here. It lives outside this
repo because it describes the machine, not the config.
