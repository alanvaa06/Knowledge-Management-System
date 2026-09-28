# Snapshot tests for the PowerShell renderer. Same fixtures as tests/render-template.test.sh,
# so a pass on both proves the two renderers produce byte-identical output.
# Usage: powershell -ExecutionPolicy Bypass -File tests/render-template.test.ps1

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$Fix = Join-Path $Root 'tests/fixtures'
$Render = Join-Path $Root 'templates/.claude/lib/render-template.ps1'
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('render-test-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp | Out-Null

$failed = $false

function Invoke-Renderer($template, $answers, $output) {
  # PS 5.1 turns redirected native stderr into ErrorRecords; don't let them become terminating.
  $ErrorActionPreference = 'Continue'
  & powershell -NoProfile -ExecutionPolicy Bypass -File $Render $template $answers $output 2>$null | Out-Null
  return $LASTEXITCODE
}

function Test-Case($name, $template, $answers, $expected) {
  $out = Join-Path $Tmp "$name.md"
  $code = Invoke-Renderer $template $answers $out
  if ($code -ne 0) {
    Write-Host "FAIL: $name (renderer exit $code)"
    return $false
  }
  $want = [System.IO.File]::ReadAllBytes($expected)
  $got = [System.IO.File]::ReadAllBytes($out)
  if ([System.Convert]::ToBase64String($want) -ne [System.Convert]::ToBase64String($got)) {
    Write-Host "FAIL: $name (output differs from $expected)"
    return $false
  }
  Write-Host "PASS: $name"
  return $true
}

try {
  $tmpl = Join-Path $Root 'templates/CLAUDE.md.tmpl'
  if (-not (Test-Case 'all-yes' $tmpl (Join-Path $Fix 'answers.json') (Join-Path $Fix 'expected-CLAUDE.md'))) { $failed = $true }
  if (-not (Test-Case 'all-no' $tmpl (Join-Path $Fix 'answers-no.json') (Join-Path $Fix 'expected-CLAUDE-no.md'))) { $failed = $true }
  if (-not (Test-Case 'edge' (Join-Path $Fix 'edge.tmpl') (Join-Path $Fix 'edge.json') (Join-Path $Fix 'expected-edge.md'))) { $failed = $true }
  if (-not (Test-Case 'private-only' $tmpl (Join-Path $Fix 'answers-private-only.json') (Join-Path $Fix 'expected-CLAUDE-private-only.md'))) { $failed = $true }

  # Unresolved placeholders must fail and must not write the output file.
  $badTmpl = Join-Path $Tmp 'bad.tmpl'
  $badJson = Join-Path $Tmp 'bad.json'
  $badOut = Join-Path $Tmp 'bad.md'
  [System.IO.File]::WriteAllText($badTmpl, "a {{missing}} b`n")
  [System.IO.File]::WriteAllText($badJson, '{"other":"x"}')
  $code = Invoke-Renderer $badTmpl $badJson $badOut
  if ($code -eq 0) {
    Write-Host 'FAIL: unresolved placeholder should exit non-zero'
    $failed = $true
  } elseif (Test-Path -LiteralPath $badOut) {
    Write-Host 'FAIL: unresolved placeholder should not write output'
    $failed = $true
  } else {
    Write-Host 'PASS: unresolved placeholder rejected'
  }
} finally {
  Remove-Item -Recurse -Force -LiteralPath $Tmp
}

if ($failed) { exit 1 }
