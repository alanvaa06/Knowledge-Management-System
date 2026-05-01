#!/usr/bin/env bash
# install.sh — bootstrap an obsidian-vault-kit scaffold into the current directory.
# Usage: bash /path/to/obsidian-vault-kit/install.sh [--force] [--kit-root <path>]

set -euo pipefail

FORCE=0
KIT_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --kit-root) KIT_ROOT="$2"; shift 2 ;;
    *) echo "install.sh: unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$KIT_ROOT" ]]; then
  KIT_ROOT="$(cd "$(dirname "$0")" && pwd)"
fi

TEMPLATES="$KIT_ROOT/templates"
if [[ ! -d "$TEMPLATES" ]]; then
  echo "install.sh: kit templates dir not found at $TEMPLATES" >&2
  exit 1
fi

CWD="$(pwd)"

# Pre-flight refusal
if [[ $FORCE -eq 0 ]]; then
  if [[ -d "$CWD/.claude" ]]; then
    echo "install.sh: refusing to overwrite existing $CWD/.claude (pass --force to override)" >&2
    exit 1
  fi
  if [[ -f "$CWD/CLAUDE.md" ]]; then
    echo "install.sh: refusing to overwrite existing $CWD/CLAUDE.md (pass --force to override)" >&2
    exit 1
  fi
fi

# Copy .claude/ tree (the trailing /. ensures hidden files and dir contents are copied, not the dir itself)
mkdir -p "$CWD/.claude"
cp -R "$TEMPLATES/.claude/." "$CWD/.claude/"

# Copy CLAUDE.md (still containing placeholders — wizard will substitute later)
cp "$TEMPLATES/CLAUDE.md.tmpl" "$CWD/CLAUDE.md"

# Cache pristine template for /vault-init force re-runs
cp "$TEMPLATES/CLAUDE.md.tmpl" "$CWD/.claude/.vault-init-template.md"

# Copy master index stub. With --force, only overwrite if the existing file still has {{ markers
# (i.e., user hasn't substituted/edited it yet). This protects user wiki content.
mkdir -p "$CWD/wiki"
INDEX_DST="$CWD/wiki/_master-index.md"
if [[ ! -f "$INDEX_DST" ]]; then
  cp "$TEMPLATES/_master-index.md.tmpl" "$INDEX_DST"
elif [[ $FORCE -eq 1 ]] && grep -q '{{' "$INDEX_DST"; then
  cp "$TEMPLATES/_master-index.md.tmpl" "$INDEX_DST"
fi
# Note: any other files in wiki/ (like wiki/foo.md user articles) are NEVER touched.

# Copy vault-level README — overwrite only if missing or --force
if [[ ! -f "$CWD/README.md" ]] || [[ $FORCE -eq 1 ]]; then
  cp "$TEMPLATES/README.md.tmpl" "$CWD/README.md"
fi

# Create canonical empty dirs (mkdir -p is idempotent and preserves existing content)
for d in raw wiki notes output; do
  mkdir -p "$CWD/$d"
done

cat <<EOF
Vault scaffold installed at: $CWD

Next:
  1. Open this folder in Claude Code.
  2. Run: /vault-init
EOF
