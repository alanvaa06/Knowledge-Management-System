# install.ps1 — bootstrap an obsidian-vault-kit scaffold into the current directory.
# Usage: pwsh install.ps1 [-Force] [-KitRoot <path>]
#    or: powershell -ExecutionPolicy Bypass -File install.ps1 [-Force] [-KitRoot <path>]

param(
  [switch]$Force,
  [string]$KitRoot
)

$ErrorActionPreference = 'Stop'

if (-not $KitRoot) {
  $KitRoot = Split-Path -Parent $PSCommandPath
}

$Templates = Join-Path $KitRoot 'templates'
if (-not (Test-Path -LiteralPath $Templates)) {
  throw "install.ps1: kit templates dir not found at $Templates"
}

$Cwd = (Get-Location).Path

# Pre-flight refusal
if (-not $Force) {
  if (Test-Path -LiteralPath (Join-Path $Cwd '.claude')) {
    throw "install.ps1: refusing to overwrite existing .claude (pass -Force to override)"
  }
  if (Test-Path -LiteralPath (Join-Path $Cwd 'CLAUDE.md')) {
    throw "install.ps1: refusing to overwrite existing CLAUDE.md (pass -Force to override)"
  }
}

# Copy .claude/ tree
$DotClaude = Join-Path $Cwd '.claude'
if (-not (Test-Path -LiteralPath $DotClaude)) {
  New-Item -ItemType Directory -Path $DotClaude | Out-Null
}
# Copy contents of templates/.claude/ INTO .claude/ (not the dir itself).
# Use Get-ChildItem -Force to include hidden items, then Copy-Item -Recurse.
Get-ChildItem -Force -LiteralPath (Join-Path $Templates '.claude') | ForEach-Object {
  Copy-Item -Recurse -Force -LiteralPath $_.FullName -Destination $DotClaude
}

# Copy CLAUDE.md (still containing placeholders — wizard will substitute later)
Copy-Item -Force -LiteralPath (Join-Path $Templates 'CLAUDE.md.tmpl') -Destination (Join-Path $Cwd 'CLAUDE.md')

# Cache pristine template for /vault-init force re-runs
Copy-Item -Force -LiteralPath (Join-Path $Templates 'CLAUDE.md.tmpl') -Destination (Join-Path $DotClaude '.vault-init-template.md')

# Master index: only overwrite if missing OR (-Force AND existing file still has {{ markers).
$WikiDir = Join-Path $Cwd 'wiki'
if (-not (Test-Path -LiteralPath $WikiDir)) {
  New-Item -ItemType Directory -Path $WikiDir | Out-Null
}
$IndexPath = Join-Path $WikiDir '_master-index.md'
$ShouldCopyIndex = $false
if (-not (Test-Path -LiteralPath $IndexPath)) {
  $ShouldCopyIndex = $true
} elseif ($Force) {
  $existing = Get-Content -Raw -LiteralPath $IndexPath
  if ($existing -match '\{\{') { $ShouldCopyIndex = $true }
}
if ($ShouldCopyIndex) {
  Copy-Item -Force -LiteralPath (Join-Path $Templates '_master-index.md.tmpl') -Destination $IndexPath
}

# Vault-level README — overwrite only if -Force or missing
$ReadmePath = Join-Path $Cwd 'README.md'
if (-not (Test-Path -LiteralPath $ReadmePath) -or $Force) {
  Copy-Item -Force -LiteralPath (Join-Path $Templates 'README.md.tmpl') -Destination $ReadmePath
}

# Create canonical empty dirs (idempotent — preserves existing content)
foreach ($d in @('raw', 'wiki', 'notes', 'output')) {
  $p = Join-Path $Cwd $d
  if (-not (Test-Path -LiteralPath $p)) {
    New-Item -ItemType Directory -Path $p | Out-Null
  }
}

Write-Output "Vault scaffold installed at: $Cwd"
Write-Output ""
Write-Output "Next:"
Write-Output "  1. Open this folder in Claude Code."
Write-Output "  2. Run: /vault-init"
