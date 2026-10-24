# assemble-notebook.ps1 -- build <topic-dir>/notebook.html from the template, progress.md and sessions/.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File assemble-notebook.ps1 <topic-dir> [<template.html> <marked.js>]
# Defaults: notebook.template.html and marked.min.js next to this script.
# Output mirrors assemble-notebook.sh byte for byte; tests/assemble-notebook.test.* keep them in parity.
# Keep this file ASCII-only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.

param(
  [Parameter(Mandatory=$true, Position=0)][string]$TopicDir,
  [Parameter(Position=1)][string]$Template,
  [Parameter(Position=2)][string]$Marked
)

$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $PSCommandPath
if (-not $Template) { $Template = Join-Path $here 'notebook.template.html' }
if (-not $Marked)   { $Marked   = Join-Path $here 'marked.min.js' }
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$LF = "`n"

foreach ($f in @($Template, $Marked)) {
  if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { throw "assemble-notebook.ps1: file not found: $f" }
}
if (-not (Test-Path -LiteralPath (Join-Path $TopicDir 'progress.md') -PathType Leaf)) {
  throw "assemble-notebook.ps1: not a /teach topic (missing progress.md): $TopicDir"
}

# .NET file APIs resolve relative paths against the process directory, not the PowerShell location.
$TopicDir = (Resolve-Path -LiteralPath $TopicDir).Path
$Template = (Resolve-Path -LiteralPath $Template).Path
$Marked   = (Resolve-Path -LiteralPath $Marked).Path
$progress = Join-Path $TopicDir 'progress.md'

$sessionsDir = Join-Path $TopicDir 'sessions'
$sessions = @()
if (Test-Path -LiteralPath $sessionsDir -PathType Container) {
  $sessions = @(Get-ChildItem -LiteralPath $sessionsDir -File |
    Where-Object { $_.Name -cmatch '^[0-9]{4}-.*\.md$' -and $_.Name -cnotmatch '\.answers\.md$' } |
    Sort-Object Name)
}
if ($sessions.Count -eq 0) { throw "assemble-notebook.ps1: not a /teach topic (no sessions/NNNN-*.md): $TopicDir" }

# File content with the BOM stripped, every CR removed, trailing newlines trimmed.
function Read-Clean([string]$Path) {
  $t = [System.IO.File]::ReadAllText($Path, $Utf8NoBom)
  if ($t.Length -gt 0 -and $t[0] -eq [char]0xFEFF) { $t = $t.Substring(1) }
  return $t.Replace("`r", '').TrimEnd([char]10)
}

function ConvertTo-HtmlText([string]$s) {
  return $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

# One embedded block. Escaping keeps text/markdown blocks from ending the <script> early or entering comment state.
function Get-Block([string]$Open, [string]$Close, [string]$Path, [bool]$Escape) {
  $c = Read-Clean $Path
  if ($Escape) {
    $c = [regex]::Replace($c, '</[sS][cC][rR][iI][pP][tT]', '<\/script')
    $c = $c.Replace('<!--', '<\!--')
  }
  return $Open + $LF + $c + $LF + $Close
}

$topic = Split-Path -Leaf $TopicDir
$title = ''
$h1 = [regex]::Match((Read-Clean $progress), '(?m)^# +(.*)$')
if ($h1.Success) {
  $dashes = [string][char]0x2014 + '|' + [string][char]0x2013
  $title = [regex]::Replace($h1.Groups[1].Value, '^Teach(?: |-|:|' + $dashes + ')+', '')
  $title = [regex]::Replace($title, '(?: |-|:|' + $dashes + ')+Progress$', '')
}
if (-not $title) { $title = $topic }

$url = ''
$old = Join-Path $TopicDir 'notebook.html'
if (Test-Path -LiteralPath $old -PathType Leaf) {
  $m = [regex]::Match((Read-Clean $old), '<meta name="artifact-url" content="([^"]*)">')
  if ($m.Success) { $url = $m.Groups[1].Value }
}

$sessionBlocks = New-Object System.Collections.Generic.List[string]
foreach ($f in $sessions) {
  $num = $f.Name.Substring(0, 4)
  $base = $f.FullName.Substring(0, $f.FullName.Length - 3)
  $sessionBlocks.Add((Get-Block ('<script type="text/markdown" data-session="' + $num + '" data-file="' + $f.Name + '">') '</script>' $f.FullName $true))
  $answers = $base + '.answers.md'
  if (Test-Path -LiteralPath $answers -PathType Leaf) {
    $sessionBlocks.Add((Get-Block ('<script type="text/markdown" data-answers="' + $num + '">') '</script>' $answers $true))
  }
  $widget = $base + '.widget.html'
  if (Test-Path -LiteralPath $widget -PathType Leaf) {
    $sessionBlocks.Add((Get-Block ('<template data-widget="' + $num + '">') '</template>' $widget $false))
  }
}
$progressBlock = Get-Block '<script type="text/markdown" id="progress">' '</script>' $progress $true
$markedBlock = Get-Block '<script>' '</script>' $Marked $false
$titleText = ConvertTo-HtmlText $title
$topicText = ConvertTo-HtmlText $topic

# Marker lines become their blocks; @@tokens@@ are replaced literally, in the same order as the bash side.
$out = New-Object System.Collections.Generic.List[string]
foreach ($line in ((Read-Clean $Template) -split $LF)) {
  if ($line -ceq '<!-- @@progress@@ -->') { $out.Add($progressBlock); continue }
  if ($line -ceq '<!-- @@sessions@@ -->') { $out.Add($sessionBlocks -join $LF); continue }
  if ($line -ceq '<!-- @@marked@@ -->') { $out.Add($markedBlock); continue }
  $out.Add($line.Replace('@@title@@', $titleText).Replace('@@topic@@', $topicText).Replace('@@artifact_url@@', $url))
}

$dest = Join-Path $TopicDir 'notebook.html'
$tmp = $dest + '.tmp'
[System.IO.File]::WriteAllText($tmp, (($out -join $LF) + $LF), $Utf8NoBom)
Move-Item -LiteralPath $tmp -Destination $dest -Force
Write-Output "[ok] notebook.html: $($sessions.Count) session(s) -> $dest"
