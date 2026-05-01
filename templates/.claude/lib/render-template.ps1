# render-template.ps1 — substitute {{key}} and strip {{#if key}}…{{/if}} blocks (inline + block).
# Usage: pwsh render-template.ps1 <template> <answers.json> <output>
#    or: powershell -ExecutionPolicy Bypass -File render-template.ps1 <template> <answers.json> <output>

param(
  [Parameter(Mandatory=$true, Position=0)][string]$Template,
  [Parameter(Mandatory=$true, Position=1)][string]$Answers,
  [Parameter(Mandatory=$true, Position=2)][string]$Output
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Template)) { throw "render-template.ps1: template not found: $Template" }
if (-not (Test-Path -LiteralPath $Answers))  { throw "render-template.ps1: answers not found: $Answers" }

# Parse JSON — flat object, string values. ConvertFrom-Json handles \n decoding.
$json = Get-Content -Raw -LiteralPath $Answers -Encoding UTF8
$obj = $json | ConvertFrom-Json
$vars = @{}
foreach ($prop in $obj.PSObject.Properties) {
  $vars[$prop.Name] = [string]$prop.Value
}

# Read template lines (Get-Content automatically splits on LF and CRLF).
$lines = Get-Content -LiteralPath $Template -Encoding UTF8

# --- Pass 1: inline single-line {{#if key}}...{{/if}} ---
# For each key: if value=="yes", strip the markers but keep content.
#               if value!="yes", strip markers+content entirely.
$processed = New-Object System.Collections.Generic.List[string]
foreach ($line in $lines) {
  $work = $line
  foreach ($k in $vars.Keys) {
    $isYes = ($vars[$k] -eq 'yes')
    # Pattern: {{#if KEY}}<content>{{/if}} on a single line (non-greedy)
    $pattern = '\{\{#if\s+' + [regex]::Escape($k) + '\}\}(.*?)\{\{/if\}\}'
    if ($isYes) {
      $work = [regex]::Replace($work, $pattern, '$1')
    } else {
      $work = [regex]::Replace($work, $pattern, '')
    }
  }
  $processed.Add($work)
}

# --- Pass 2: block {{#if key}} / {{/if}} markers each on own line ---
# Supports nesting up to 1 level (depth tracking).
$kept = New-Object System.Collections.Generic.List[string]
$skipDepth = 0
$depth = 0
foreach ($line in $processed) {
  if ($line -match '^\s*\{\{#if\s+([a-zA-Z_][a-zA-Z0-9_]*)\}\}\s*$') {
    $key = $Matches[1]
    $depth++
    if ($skipDepth -eq 0 -and $vars[$key] -ne 'yes') {
      $skipDepth = $depth
    }
    continue
  }
  if ($line -match '^\s*\{\{/if\}\}\s*$') {
    if ($skipDepth -eq $depth) { $skipDepth = 0 }
    $depth--
    continue
  }
  if ($skipDepth -eq 0) { $kept.Add($line) }
}

# --- Pass 3: substitute {{key}} placeholders ---
# Join with LF, do string replacement (values may contain embedded newlines from JSON \n).
$rendered = ($kept -join "`n")
foreach ($k in $vars.Keys) {
  $rendered = $rendered.Replace('{{' + $k + '}}', $vars[$k])
}

# Final check: no remaining {{…}} markers.
if ($rendered -match '\{\{') {
  Write-Error "render-template.ps1: unresolved markers remain"
  ($rendered -split "`n") | ForEach-Object {
    if ($_ -match '\{\{[^}]*\}\}') { Write-Error $_ }
  }
  exit 1
}

# Ensure output ends with a single newline (POSIX text-file convention; matches bash renderer).
if (-not $rendered.EndsWith("`n")) {
  $rendered += "`n"
}

# Write output: UTF-8 without BOM, LF line endings.
[System.IO.File]::WriteAllText($Output, $rendered, [System.Text.UTF8Encoding]::new($false))
