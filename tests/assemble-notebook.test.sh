#!/usr/bin/env bash
# Snapshot + contract tests for assemble-notebook.sh. tests/assemble-notebook.test.ps1 checks the
# PowerShell assembler against the same expected file, so a pass on both means identical bytes.
# Usage: bash tests/assemble-notebook.test.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIX="$ROOT/tests/fixtures/teach-notebook"
SKILL="$ROOT/templates/.claude/skills/teach-notebook"
ASSEMBLE="$SKILL/assemble-notebook.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $1"; exit 1; }

# Fixture copy, plus what git can't hold: a BOM + CRLF session and an old notebook carrying a URL.
cp -R "$FIX/demo-topic" "$TMP/demo-topic"
printf '\357\273\277# 0003 - CRLF\r\n\r\nLinea.\r\n\r\n\r\n' > "$TMP/demo-topic/sessions/0003-crlf.md"
printf '<meta name="artifact-url" content="https://claude.ai/artifact/abc123">\n' > "$TMP/demo-topic/notebook.html"

bash "$ASSEMBLE" "$TMP/demo-topic" "$FIX/template.html" "$FIX/marked.stub.js" > /dev/null
if ! cmp -s "$FIX/expected-notebook.html" "$TMP/demo-topic/notebook.html"; then
  diff "$FIX/expected-notebook.html" "$TMP/demo-topic/notebook.html" | head -40 || true
  fail "assembled notebook differs from expected-notebook.html"
fi
echo "PASS: snapshot"

bash "$ASSEMBLE" "$TMP/demo-topic" "$FIX/template.html" "$FIX/marked.stub.js" > /dev/null
cmp -s "$FIX/expected-notebook.html" "$TMP/demo-topic/notebook.html" || fail "second run changed the output"
echo "PASS: idempotent"

mkdir -p "$TMP/not-a-topic/sessions"
if bash "$ASSEMBLE" "$TMP/not-a-topic" "$FIX/template.html" "$FIX/marked.stub.js" > /dev/null 2>&1; then
  fail "folder without progress.md was accepted"
fi
printf '# Teach - x\n' > "$TMP/not-a-topic/progress.md"
if bash "$ASSEMBLE" "$TMP/not-a-topic" "$FIX/template.html" "$FIX/marked.stub.js" > /dev/null 2>&1; then
  fail "topic without sessions was accepted"
fi
echo "PASS: refuses non-topics"

MARKED_HEAD="$(head -c 300 "$SKILL/marked.min.js")"
[[ "$MARKED_HEAD" == *'marked v12.0.2'* ]] || fail "marked.min.js is not marked v12.0.2"
! grep -qi '</script' "$SKILL/marked.min.js" || fail "marked.min.js contains </script"
echo "PASS: vendored marked"

echo "PASS: assemble-notebook.sh"
