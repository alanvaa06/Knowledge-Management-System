#!/usr/bin/env bash
set -euo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

cd "$SCRATCH"
bash "$KIT/install.sh"

# Required files
test -f CLAUDE.md || { echo "FAIL: CLAUDE.md not created"; exit 1; }
test -f README.md || { echo "FAIL: README.md not created"; exit 1; }
test -f wiki/_master-index.md || { echo "FAIL: wiki/_master-index.md not created"; exit 1; }
test -f .claude/.vault-init-template.md || { echo "FAIL: .vault-init-template.md not cached"; exit 1; }
test -f .claude/commands/vault-init.md || { echo "FAIL: vault-init command not copied"; exit 1; }
test -f .claude/commands/compile.md || { echo "FAIL: compile command not copied"; exit 1; }
test -f .claude/commands/audit.md || { echo "FAIL: audit command not copied"; exit 1; }
test -f .claude/commands/refine.md || { echo "FAIL: refine command not copied"; exit 1; }
test -f .claude/commands/refresh-index.md || { echo "FAIL: refresh-index command not copied"; exit 1; }
test -f .claude/skills/vault-query/SKILL.md || { echo "FAIL: vault-query skill not copied"; exit 1; }
test -f .claude/lib/render-template.sh || { echo "FAIL: renderer not copied"; exit 1; }
test -f .claude/lib/render-template.ps1 || { echo "FAIL: PS renderer not copied"; exit 1; }

# Required directories
for d in raw wiki notes output; do
  test -d "$d" || { echo "FAIL: $d/ not created"; exit 1; }
done

# CLAUDE.md still has placeholders (wizard runs in Claude Code, not installer)
grep -q '{{owner_name}}' CLAUDE.md || { echo "FAIL: CLAUDE.md should still contain {{owner_name}} placeholder"; exit 1; }

# Re-run without --force should fail
if bash "$KIT/install.sh" 2>/dev/null; then
  echo "FAIL: re-run without --force should have failed"
  exit 1
fi

# Re-run with --force should succeed
bash "$KIT/install.sh" --force

# User content sacred — drop a sentinel file in raw/ and notes/, re-run with --force, verify untouched
echo "sentinel" > raw/sentinel.txt
echo "sentinel" > notes/sentinel.txt
echo "sentinel" > output/sentinel.txt
echo "user wiki article" > wiki/foo.md
bash "$KIT/install.sh" --force
test "$(cat raw/sentinel.txt)" = "sentinel" || { echo "FAIL: --force touched raw/"; exit 1; }
test "$(cat notes/sentinel.txt)" = "sentinel" || { echo "FAIL: --force touched notes/"; exit 1; }
test "$(cat output/sentinel.txt)" = "sentinel" || { echo "FAIL: --force touched output/"; exit 1; }
test "$(cat wiki/foo.md)" = "user wiki article" || { echo "FAIL: --force touched wiki/foo.md (non-template wiki content)"; exit 1; }

echo "PASS: installer behaves correctly"
