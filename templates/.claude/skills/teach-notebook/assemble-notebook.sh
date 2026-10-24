#!/usr/bin/env bash
# assemble-notebook.sh -- build <topic-dir>/notebook.html from the template, progress.md and sessions/.
# Usage: assemble-notebook.sh <topic-dir> [<template.html> <marked.js>]
# Defaults: notebook.template.html and marked.min.js next to this script.
#
# Portability: bash 3.2 (stock macOS) and BSD or GNU sed/awk/tr. No python, no sed -i.
# Output mirrors assemble-notebook.ps1 byte for byte; tests/assemble-notebook.test.* keep them in parity.

set -euo pipefail

if [[ $# -ne 1 && $# -ne 3 ]]; then
  echo "usage: assemble-notebook.sh <topic-dir> [<template.html> <marked.js>]" >&2
  exit 2
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
TOPIC_DIR="$1"
TEMPLATE="${2:-$HERE/notebook.template.html}"
MARKED="${3:-$HERE/marked.min.js}"

for f in "$TEMPLATE" "$MARKED"; do
  [[ -f "$f" ]] || { echo "assemble-notebook.sh: file not found: $f" >&2; exit 1; }
done
if [[ ! -f "$TOPIC_DIR/progress.md" ]]; then
  echo "assemble-notebook.sh: not a /teach topic (missing progress.md): $TOPIC_DIR" >&2
  exit 1
fi

shopt -s nullglob
SESSIONS=()
for f in "$TOPIC_DIR"/sessions/[0-9][0-9][0-9][0-9]-*.md; do
  case "$f" in *.answers.md) continue ;; esac
  SESSIONS+=("$f")
done
if [[ ${#SESSIONS[@]} -eq 0 ]]; then
  echo "assemble-notebook.sh: not a /teach topic (no sessions/NNNN-*.md): $TOPIC_DIR" >&2
  exit 1
fi

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

BOM="$(printf '\357\273\277')"

# File content with the BOM stripped, every CR removed, trailing newlines trimmed (by $()).
clean() {
  local content
  content="$(LC_ALL=C sed "1s/^$BOM//" "$1" | LC_ALL=C tr -d '\r')"
  printf '%s' "$content"
}

# block <open-tag> <close-tag> <file> <escape: 1|0> -- print one embedded block.
# Escaping keeps text/markdown blocks from ending the <script> early or entering comment state.
block() {
  local content
  content="$(clean "$3")"
  if [[ "$4" == 1 ]]; then
    content="$(printf '%s' "$content" | LC_ALL=C sed -e 's#</[sS][cC][rR][iI][pP][tT]#<\\/script#g' -e 's#<!--#<\\!--#g')"
  fi
  printf '%s\n%s\n%s\n' "$1" "$content" "$2"
}

html_escape() {
  printf '%s' "$1" | LC_ALL=C sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'
}

TOPIC="$(basename "$(cd "$TOPIC_DIR" && pwd)")"
TITLE="$(clean "$TOPIC_DIR/progress.md" \
  | LC_ALL=C awk 'f == 0 && /^# / { sub(/^# +/, ""); print; f = 1 }' \
  | LC_ALL=C sed -E 's/^Teach( |-|:|—|–)+//')"
[[ -n "$TITLE" ]] || TITLE="$TOPIC"

URL=""
if [[ -f "$TOPIC_DIR/notebook.html" ]]; then
  URL="$(clean "$TOPIC_DIR/notebook.html" | LC_ALL=C awk '
    f == 0 && match($0, /<meta name="artifact-url" content="[^"]*">/) {
      s = substr($0, RSTART, RLENGTH)
      sub(/^<meta name="artifact-url" content="/, "", s)
      sub(/">$/, "", s)
      print s
      f = 1
    }')"
fi

block '<script type="text/markdown" id="progress">' '</script>' "$TOPIC_DIR/progress.md" 1 > "$TMPD/progress.part"
: > "$TMPD/sessions.part"
for f in "${SESSIONS[@]}"; do
  name="$(basename "$f")"
  num="${name:0:4}"
  base="${f%.md}"
  block "<script type=\"text/markdown\" data-session=\"$num\" data-file=\"$name\">" '</script>' "$f" 1 >> "$TMPD/sessions.part"
  if [[ -f "$base.answers.md" ]]; then
    block "<script type=\"text/markdown\" data-answers=\"$num\">" '</script>' "$base.answers.md" 1 >> "$TMPD/sessions.part"
  fi
  if [[ -f "$base.widget.html" ]]; then
    block "<template data-widget=\"$num\">" '</template>' "$base.widget.html" 0 >> "$TMPD/sessions.part"
  fi
done
block '<script>' '</script>' "$MARKED" 0 > "$TMPD/marked.part"

# Marker lines become their part files; @@tokens@@ are replaced literally (no regex, no & quirks).
clean "$TEMPLATE" | TN_TITLE="$(html_escape "$TITLE")" TN_TOPIC="$(html_escape "$TOPIC")" \
  TN_URL="$URL" TN_PARTS="$TMPD" LC_ALL=C awk '
  function replace_all(s, needle, repl,    out, idx, nlen) {
    out = ""
    nlen = length(needle)
    while ((idx = index(s, needle)) > 0) {
      out = out substr(s, 1, idx - 1) repl
      s = substr(s, idx + nlen)
    }
    return out s
  }
  function cat_part(name,    f, l) {
    f = ENVIRON["TN_PARTS"] "/" name ".part"
    while ((getline l < f) > 0) print l
    close(f)
  }
  $0 == "<!-- @@progress@@ -->" { cat_part("progress"); next }
  $0 == "<!-- @@sessions@@ -->" { cat_part("sessions"); next }
  $0 == "<!-- @@marked@@ -->" { cat_part("marked"); next }
  {
    line = replace_all($0, "@@title@@", ENVIRON["TN_TITLE"])
    line = replace_all(line, "@@topic@@", ENVIRON["TN_TOPIC"])
    line = replace_all(line, "@@artifact_url@@", ENVIRON["TN_URL"])
    print line
  }
' > "$TMPD/notebook.html"

mv "$TMPD/notebook.html" "$TOPIC_DIR/notebook.html"
echo "[ok] notebook.html: ${#SESSIONS[@]} session(s) -> $TOPIC_DIR/notebook.html"
