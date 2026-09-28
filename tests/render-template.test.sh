#!/usr/bin/env bash
# Snapshot tests for the bash renderer. tests/render-template.test.ps1 runs the same
# cases against the PowerShell renderer, so both stay in parity with one set of fixtures.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIX="$ROOT/tests/fixtures"
RENDER="$ROOT/templates/.claude/lib/render-template.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILED=0

# case: <name> <template> <answers> <expected>
check() {
  local name="$1" template="$2" answers="$3" expected="$4"
  bash "$RENDER" "$template" "$answers" "$TMP/$name.md"
  if diff -u "$expected" "$TMP/$name.md"; then
    echo "PASS: $name"
  else
    echo "FAIL: $name"
    FAILED=1
  fi
}

check all-yes "$ROOT/templates/CLAUDE.md.tmpl" "$FIX/answers.json"    "$FIX/expected-CLAUDE.md"
check all-no  "$ROOT/templates/CLAUDE.md.tmpl" "$FIX/answers-no.json" "$FIX/expected-CLAUDE-no.md"
check edge    "$FIX/edge.tmpl"                 "$FIX/edge.json"       "$FIX/expected-edge.md"
check private-only "$ROOT/templates/CLAUDE.md.tmpl" "$FIX/answers-private-only.json" "$FIX/expected-CLAUDE-private-only.md"

# Semantic guard, independent of the snapshots: the notes/private/ rules must render whenever
# private_notes is yes, whatever notes_sacred says (they used to be nested inside notes_sacred).
if [[ -f "$TMP/private-only.md" ]] && grep -q 'completely invisible to `compile` and `audit`' "$TMP/private-only.md"; then
  echo "PASS: private rules render without sacred notes"
else
  echo "FAIL: private rules missing when notes_sacred=no, private_notes=yes"
  FAILED=1
fi

# Unresolved placeholders must fail and must not write the output file.
printf 'a {{missing}} b\n' > "$TMP/bad.tmpl"
printf '{"other":"x"}\n' > "$TMP/bad.json"
if bash "$RENDER" "$TMP/bad.tmpl" "$TMP/bad.json" "$TMP/bad.md" 2>/dev/null; then
  echo "FAIL: unresolved placeholder should exit non-zero"
  FAILED=1
elif [[ -e "$TMP/bad.md" ]]; then
  echo "FAIL: unresolved placeholder should not write output"
  FAILED=1
else
  echo "PASS: unresolved placeholder rejected"
fi

exit $FAILED
