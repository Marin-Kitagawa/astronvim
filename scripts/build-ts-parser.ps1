<#
.SYNOPSIS
    Build nvim-treesitter parsers with zig, bypassing the tree-sitter CLI entirely.

.DESCRIPTION
    A fallback for `:TSInstall` / `:TSUpdate`, which normally handle this themselves.

    nvim-treesitter `main` compiles parsers via `tree-sitter build`, which shells out to
    MSVC (`cl.exe`) on Windows. There is no usable MSVC here, so the config points `CC`
    at a shim (scripts/zig-cl.c) that re-execs `zig cc`, and the normal commands work.

    This script is an independent path to the same result: it skips the tree-sitter CLI
    entirely. Use it if `:TSUpdate` ever breaks.

    It reads the grammar URL and pinned revision straight out of nvim-treesitter's own
    `parsers.lua`, clones the grammar at that exact revision, compiles it with zig into a
    shared object, and installs it alongside its queries where nvim-treesitter expects
    them (`stdpath('data')/site/{parser,queries}`).

    Because the revision comes from nvim-treesitter, the built parser always matches the
    queries shipped for it -- mismatches show up as "Query error ... Invalid field name".

.PARAMETER Languages
    Language names as nvim-treesitter knows them, e.g. json, typescript, rust.

.PARAMETER All
    Rebuild every language already present in site/parser. This is the post-`:Lazy update`
    command: when nvim-treesitter moves, its queries move with it, and parsers built
    against the previous revisions start failing with
    "Query error ... Invalid field name".

.EXAMPLE
    .\build-ts-parser.ps1 json yaml rust
    Install three new languages.

.EXAMPLE
    .\build-ts-parser.ps1 -All
    Rebuild everything after `:Lazy update` bumped nvim-treesitter.

.NOTES
    Verify afterwards with `:checkhealth nvim-treesitter`. Note that the healthcheck does
    not check for a C compiler at all -- only for the tree-sitter CLI, tar and curl. It
    reports OK regardless, so it cannot tell you whether builds will succeed.
#>
[CmdletBinding(DefaultParameterSetName = "Named")]
param(
    [Parameter(ParameterSetName = "Named", Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
    [string[]] $Languages,

    # Rebuild every language currently installed. Use this after `:Lazy update`
    # bumps nvim-treesitter, so parsers track the revisions its queries expect.
    [Parameter(ParameterSetName = "All", Mandatory = $true)]
    [switch] $All,

    [string] $Zig = "C:\Users\Ahri\Software\Ziglang\zig.exe"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Zig)) { throw "zig not found at $Zig - pass -Zig <path>" }

$site  = Join-Path $env:LOCALAPPDATA "nvim-data\site"
$plug  = Join-Path $env:LOCALAPPDATA "nvim-data\lazy\nvim-treesitter"
$work  = Join-Path $env:TEMP "ts-parser-build"
$specF = Join-Path $work "specs.json"
$luaF  = Join-Path $work "dump.lua"

New-Item -ItemType Directory -Force -Path $work, "$site\parser", "$site\queries" | Out-Null

if ($All) {
    $Languages = Get-ChildItem "$site\parser" -Filter *.so -ErrorAction SilentlyContinue |
        ForEach-Object { $_.BaseName } | Sort-Object
    if (-not $Languages) { throw "no parsers installed in $site\parser - name languages explicitly instead" }
    Write-Host "rebuilding $($Languages.Count) installed languages: $($Languages -join ', ')`n"
}

# --- ask nvim-treesitter for each grammar's url + pinned revision ---------------
$want = ($Languages | ForEach-Object { "'$_'" }) -join ", "
@"
local parsers = require('nvim-treesitter.parsers')
local res = {}
for _, lang in ipairs({ $want }) do
  local p = parsers[lang]
  if p then
    local i = p.install_info or p
    res[lang] = { url = i.url, revision = i.revision, location = i.location }
  end
end
local f = assert(io.open(vim.env.DUMPOUT, 'w'))
f:write(vim.json.encode(res))
f:close()
"@ | Set-Content $luaF

$env:DUMPOUT = $specF
& nvim --headless -c "lua dofile('$($luaF -replace '\\','/')')" -c "qa!" 2>&1 | Out-Null
if (-not (Test-Path $specF)) { throw "could not read parser metadata from nvim-treesitter" }

$specs = Get-Content $specF | ConvertFrom-Json
$built = @(); $failed = @()

foreach ($lang in $Languages) {
    $s = $specs.$lang
    if (-not $s) { $failed += "$lang (unknown to nvim-treesitter)"; continue }

    $repo = Join-Path $work ($s.url -replace '.*/', '')
    if (-not (Test-Path "$repo\.git")) {
        New-Item -ItemType Directory -Force -Path $repo | Out-Null
        git -C $repo init -q
        git -C $repo remote add origin $s.url
    }

    # fetch the pinned revision; fall back to a tag ref when it is not a raw sha
    git -C $repo fetch -q --depth 1 origin $s.revision 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { git -C $repo fetch -q --depth 1 origin "refs/tags/$($s.revision)" 2>&1 | Out-Null }
    git -C $repo checkout -q FETCH_HEAD

    $src = if ($s.location) { Join-Path $repo "$($s.location)\src" } else { Join-Path $repo "src" }
    if (-not (Test-Path "$src\parser.c")) { $failed += "$lang (no pre-generated src/parser.c)"; continue }

    # scanner is optional and may be C or C++
    $sources = @("$src\parser.c")
    $driver  = "cc"
    if     (Test-Path "$src\scanner.c")  { $sources += "$src\scanner.c" }
    elseif (Test-Path "$src\scanner.cc") { $sources += "$src\scanner.cc"; $driver = "c++" }

    $out = Join-Path $site "parser\$lang.so"
    & $Zig @($driver, "-shared", "-O2", "-fPIC", "-I", $src, "-o", $out) @sources
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $out)) { $failed += $lang; continue }

    # zig also drops linker byproducts (.pdb debug symbols, .lib import library) next to
    # the output. Neovim globs `parser/<lang>.*` and would try to dlopen the .pdb, and
    # nvim-treesitter lists every basename in the dir as an installed language -- so both
    # have to go.
    Remove-Item (Join-Path $site "parser\*.pdb"), (Join-Path $site "parser\*.lib") -Force -ErrorAction SilentlyContinue

    # queries must come from the same nvim-treesitter checkout as the revision above
    $q = Join-Path $plug "runtime\queries\$lang"
    if (Test-Path $q) { Copy-Item $q (Join-Path $site "queries\$lang") -Recurse -Force }

    $built += $lang
    Write-Host ("built {0,-18} {1:n0} bytes" -f $lang, (Get-Item $out).Length)
}

Write-Host ""
Write-Host "built : $(if ($built)  { $built  -join ', ' } else { 'none' })"
Write-Host "failed: $(if ($failed) { $failed -join ', ' } else { 'none' })"
if ($failed) { exit 1 }
