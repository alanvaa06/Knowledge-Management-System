# Installer behavior tests for install.ps1. Mirrors the key checks of tests/install.test.sh.
# Usage: powershell -ExecutionPolicy Bypass -File tests/install.test.ps1

$ErrorActionPreference = 'Stop'

$Kit = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$Installer = Join-Path $Kit 'install.ps1'
$Scratch = Join-Path ([System.IO.Path]::GetTempPath()) ('install-test-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Scratch | Out-Null

function Fail($msg) { throw "FAIL: $msg" }

function Invoke-Installer([string[]]$extra) {
  $ErrorActionPreference = 'Continue'
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Installer @extra 2>$null
  return @{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

Push-Location $Scratch
try {
  $r = Invoke-Installer @()
  if ($r.Code -ne 0) { Fail "fresh install exited $($r.Code)" }

  foreach ($f in @('CLAUDE.md', 'README.md', 'wiki/_master-index.md', 'wiki/_log.md',
                   '.claude/.vault-init-template.md', '.claude/settings.json',
                   '.claude/commands/compile.md', '.claude/commands/audit.md',
                   '.claude/commands/refine.md', '.claude/commands/refresh-index.md',
                   '.claude/commands/teach.md', '.claude/commands/vault-init.md',
                   '.claude/skills/vault-query/SKILL.md',
                   '.claude/lib/render-template.sh', '.claude/lib/render-template.ps1')) {
    if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { Fail "$f not created" }
  }
  foreach ($d in @('raw', 'wiki', 'notes', 'output')) {
    if (-not (Test-Path -LiteralPath $d -PathType Container)) { Fail "$d/ not created" }
  }
  if (-not (Get-Content -Raw -LiteralPath '.claude/settings.json').Contains('Edit(/raw/**)')) { Fail 'settings.json missing raw/ deny rule' }
  if ((Get-Content -Raw -LiteralPath 'README.md').Contains('{{')) { Fail 'vault README.md ships with unrendered placeholders' }
  if (-not (Get-Content -Raw -LiteralPath 'CLAUDE.md').Contains('{{owner_name}}')) { Fail 'CLAUDE.md should still contain {{owner_name}}' }

  $r = Invoke-Installer @()
  if ($r.Code -eq 0) { Fail 're-run without -Force should have failed' }

  # User content survives -Force.
  Set-Content -LiteralPath 'raw/sentinel.txt' -Value 'sentinel'
  Set-Content -LiteralPath 'notes/sentinel.txt' -Value 'sentinel'
  Set-Content -LiteralPath 'output/sentinel.txt' -Value 'sentinel'
  Set-Content -LiteralPath 'wiki/foo.md' -Value 'user wiki article'
  Add-Content -LiteralPath 'wiki/_log.md' -Value '## [2026-01-01] compile | sentinel entry'
  Set-Content -LiteralPath '.claude/settings.json' -Value '{"custom": true}'

  $r = Invoke-Installer @('-Force')
  if ($r.Code -ne 0) { Fail "-Force re-run exited $($r.Code)" }
  foreach ($f in @('raw/sentinel.txt', 'notes/sentinel.txt', 'output/sentinel.txt')) {
    if ((Get-Content -Raw -LiteralPath $f).Trim() -ne 'sentinel') { Fail "-Force touched $f" }
  }
  if ((Get-Content -Raw -LiteralPath 'wiki/foo.md').Trim() -ne 'user wiki article') { Fail '-Force touched wiki/foo.md' }
  if (-not (Get-Content -Raw -LiteralPath 'wiki/_log.md').Contains('sentinel entry')) { Fail '-Force overwrote wiki/_log.md' }
  if ((Get-Content -Raw -LiteralPath '.claude/settings.json').Trim() -ne '{"custom": true}') { Fail '-Force overwrote user .claude/settings.json' }
  if (-not $r.Out.Contains('Kept existing .claude/settings.json')) { Fail 'no hint printed when settings.json lacks the raw/ deny rule' }

  # -Force must not nest copied folders (Copy-Item quirk: .claude/commands/commands).
  if (Test-Path -LiteralPath '.claude/commands/commands') { Fail '-Force nested .claude/commands/commands' }

  Write-Host 'PASS: installer behaves correctly'
} catch {
  Write-Host $_.Exception.Message
  $failed = $true
} finally {
  Pop-Location
  Remove-Item -Recurse -Force -LiteralPath $Scratch
}

if ($failed) { exit 1 }
