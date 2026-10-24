# Snapshot + contract tests for assemble-notebook.ps1. Same expected file as
# tests/assemble-notebook.test.sh, so a pass on both proves the two assemblers produce identical bytes.
# Usage: powershell -ExecutionPolicy Bypass -File tests/assemble-notebook.test.ps1

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$Fix = Join-Path $Root 'tests/fixtures/teach-notebook'
$Skill = Join-Path $Root 'templates/.claude/skills/teach-notebook'
$Assemble = Join-Path $Skill 'assemble-notebook.ps1'
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('assemble-test-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp | Out-Null

function Fail($msg) { throw "FAIL: $msg" }

function Invoke-Assembler([string[]]$argv) {
  # PS 5.1 turns redirected native stderr into ErrorRecords; don't let them become terminating.
  $ErrorActionPreference = 'Continue'
  & powershell -NoProfile -ExecutionPolicy Bypass -File $Assemble @argv 2>$null | Out-Null
  return $LASTEXITCODE
}

function Test-SameBytes($a, $b) {
  $x = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($a))
  $y = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($b))
  return $x -eq $y
}

try {
  $topic = Join-Path $Tmp 'demo-topic'
  Copy-Item -Recurse -LiteralPath (Join-Path $Fix 'demo-topic') -Destination $topic
  $crlf = [System.Text.Encoding]::ASCII.GetBytes("# 0003 - CRLF`r`n`r`nLinea.`r`n`r`n`r`n")
  # Array + array yields object[] in PS 5.1; cast the whole sum back to byte[].
  [System.IO.File]::WriteAllBytes((Join-Path $topic 'sessions/0003-crlf.md'), [byte[]]((0xEF, 0xBB, 0xBF) + $crlf))
  [System.IO.File]::WriteAllText((Join-Path $topic 'notebook.html'),
    "<meta name=`"artifact-url`" content=`"https://claude.ai/artifact/abc123`">`n")

  $tmpl = Join-Path $Fix 'template.html'
  $stub = Join-Path $Fix 'marked.stub.js'
  $expected = Join-Path $Fix 'expected-notebook.html'
  $out = Join-Path $topic 'notebook.html'

  $code = Invoke-Assembler @($topic, $tmpl, $stub)
  if ($code -ne 0) { Fail "assembler exited $code" }
  if (-not (Test-SameBytes $expected $out)) { Fail 'assembled notebook differs from expected-notebook.html' }
  Write-Host 'PASS: snapshot'

  $code = Invoke-Assembler @($topic, $tmpl, $stub)
  if ($code -ne 0 -or -not (Test-SameBytes $expected $out)) { Fail 'second run changed the output' }
  Write-Host 'PASS: idempotent'

  $bad = Join-Path $Tmp 'not-a-topic'
  New-Item -ItemType Directory -Path (Join-Path $bad 'sessions') | Out-Null
  if ((Invoke-Assembler @($bad, $tmpl, $stub)) -eq 0) { Fail 'folder without progress.md was accepted' }
  Set-Content -LiteralPath (Join-Path $bad 'progress.md') -Value '# Teach - x'
  if ((Invoke-Assembler @($bad, $tmpl, $stub)) -eq 0) { Fail 'topic without sessions was accepted' }
  Write-Host 'PASS: refuses non-topics'

  Write-Host 'PASS: assemble-notebook.ps1'
} finally {
  Remove-Item -Recurse -Force -LiteralPath $Tmp
}
