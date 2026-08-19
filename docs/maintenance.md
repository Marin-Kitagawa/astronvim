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
2. **There is no MSVC on this machine, but zig stands in for it.** nvim-treesitter `main`
   compiles every parser on demand and expects `cl.exe`. A shim
   ([`scripts/zig-cl.c`](../scripts/zig-cl.c)) translates what the build system emits
   into something zig accepts, and `lua/plugins/treesitter-zig-cc.lua` points `CC` at it
   automatically. **`:TSInstall` and `:TSUpdate` work normally.**

The single most important consequence:

> **After `:Lazy update` moves nvim-treesitter, run `:TSUpdate`.**
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
| C compiler | no MSVC/gcc/clang. zig plus the `scripts/zig-cl.c` shim stand in — see below |

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

```vim
:TSUpdate
```

This rebuilds every installed parser at the revision the new nvim-treesitter pins and
reinstalls the matching queries. Budget roughly half a minute per language; 16 languages
took about seven minutes.

If `:TSUpdate` ever fails, [`scripts/build-ts-parser.ps1 -All`](../scripts/build-ts-parser.ps1)
does the same job without going through the tree-sitter CLI at all, and is kept as a fallback.

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

> ⚠️ `:checkhealth nvim-treesitter` does not check for a C compiler at all — only for the
> tree-sitter CLI, `tar` and `curl`. It reported **OK** even back when no parser could be
> built, so treat a green healthcheck as necessary but not sufficient.

---

## Treesitter parsers

### How parsers get compiled without MSVC

nvim-treesitter `main` installs a parser by running `tree-sitter build`, which compiles
through Rust's `cc` crate. On Windows that crate targets MSVC and looks for `cl.exe`.
This machine has no usable MSVC — Build Tools 18 is installed but the Windows SDK
component is missing, so `C:\Program Files (x86)\Windows Kits\10` has no `Include`
directory and `cl` cannot compile anything that includes a standard header. Without a
workaround, every install ends with:

```
Failed to execute the C compiler with the following command:
"cl.exe" "-nologo" "-MD" "-O2" ...
Error: program not found
```

**zig supplies the compiler instead.** It ships its own libc headers and a MinGW-w64
toolchain, so it needs no Windows SDK. It cannot simply be assigned to `CC` though: the
`cc` crate treats `CC` as a single executable, so `CC="zig cc"` runs `zig -O2 ...` and
zig replies `unknown command: -O2`.

[`scripts/zig-cl.c`](../scripts/zig-cl.c) is a small shim that *is* a single executable.
It rewrites the arguments and re-execs `zig cc`. Three things need translating:

| Problem | Fix |
| --- | --- |
| Rust target triple `x86_64-pc-windows-msvc` | zig has no vendor field and no MSVC libs here, so it becomes `x86_64-windows-gnu` and zig uses its bundled MinGW-w64 |
| Extended-length paths (`\\?\C:\...`) | clang cannot open that form; the prefix is stripped |
| MSVC flag spellings (`-nologo`, `-LD`, `/Fo`, `-link`, `-out:`) | dropped or mapped to their GNU equivalents |

The shim **passes unknown arguments through untouched**. That matters: once `CC` is set,
the `cc` crate switches to emitting GNU-style flags, so nearly everything is already
correct. An earlier version dropped unrecognised flags instead and silently ate `-o` and
`-shared`, which made zig treat the output path as an input file.

`lua/plugins/treesitter-zig-cc.lua` wires it up: it locates zig, builds the shim into
`stdpath("data")/bin/zig-cl.exe` on first use, and sets `CC` and `ZIG_EXE`. Nothing needs
to be on `PATH` and no environment variables need setting by hand.

### Adding a language

```vim
:TSInstall rust yaml typescript
```

That is all. AstroNvim's install-on-demand also works, so opening a file of a new type
installs its parser automatically.

### The fallback script

[`scripts/build-ts-parser.ps1`](../scripts/build-ts-parser.ps1) predates the shim and
bypasses the tree-sitter CLI entirely — it clones each grammar at the revision
nvim-treesitter pins and compiles it with zig directly. It is kept because it is a
completely independent path to the same result:

```powershell
.\scripts\build-ts-parser.ps1 rust yaml     # specific languages
.\scripts\build-ts-parser.ps1 -All          # rebuild everything installed
```

Use it if `:TSUpdate` ever breaks. If a grammar ships no pre-generated `src/parser.c` the
script reports it as failed — those need `tree-sitter generate` first.

### Windows-specific gotchas

`zig cc` emits linker byproducts next to its output, and both break things:

- **`<lang>.pdb`** — Neovim globs `parser/<lang>.*` and will try to `dlopen` the `.pdb`
  first, failing with `uv_dlopen: ... is not a valid Win32 application`.
- **`parser.lib`** — nvim-treesitter lists every basename in `site/parser` as an installed
  language, so this shows up as a phantom language called `parser`.

`:TSInstall` does not hit these, because the CLI writes only the parser. The build script
deletes them after each build. If you ever compile a parser by hand, do the same.

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
| `Query error ... Invalid field name "x"` | Parser and queries are from different nvim-treesitter revisions | `:TSUpdate` |
| `Failed to execute the C compiler ... cl.exe ... program not found` | `CC` is not pointing at the zig shim | Check `:lua =vim.env.CC`; it should be `…/nvim-data/bin/zig-cl.exe`. Delete that file to force a rebuild |
| `unknown command: -O2` from zig | `CC` was set to `"zig cc"` directly instead of the shim | Use the shim; the `cc` crate cannot take a multi-word `CC` |
| `unable to parse target query 'x86_64-pc-windows-msvc'` | Shim is missing or out of date; it maps Rust triples to zig ones | Rebuild it: delete `nvim-data/bin/zig-cl.exe` and restart |
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
