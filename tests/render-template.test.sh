#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

bash "$ROOT/templates/.claude/lib/render-template.sh" \
  "$ROOT/templates/CLAUDE.md.tmpl" \
  "$ROOT/tests/fixtures/answers.json" \
  "$TMP/actual.md"

if diff -u "$ROOT/tests/fixtures/expected-CLAUDE.md" "$TMP/actual.md"; then
  echo "PASS: render matches fixture"
else
  echo "FAIL: render differs from fixture"
  exit 1
fi
