#!/usr/bin/env bash
# render-template.sh — substitute {{key}} and strip {{#if key}}…{{/if}} blocks (block + inline forms).
# Usage: render-template.sh <template> <answers.json> <output>
# answers.json must be a flat object of string values. Conditional keys must be "yes" or "no".

set -euo pipefail

TEMPLATE="$1"
ANSWERS="$2"
OUTPUT="$3"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "render-template.sh: template not found: $TEMPLATE" >&2
  exit 1
fi
if [[ ! -f "$ANSWERS" ]]; then
  echo "render-template.sh: answers not found: $ANSWERS" >&2
  exit 1
fi

# Check if python3 is actually functional (Windows has a stub that exits non-zero).
HAS_PYTHON=0
if python3 -c "import sys; sys.exit(0)" >/dev/null 2>&1; then
  HAS_PYTHON=1
fi

# Parse JSON answers into a NUL-delimited file: KEY\tVALUE\0 per record.
# Handles \n, \", \\ escape sequences in values.
# We write directly to a temp file to avoid the bash `read` loop splitting on embedded newlines.
VARS_FILE="$(mktemp)"
TRAP_FILES="$VARS_FILE"

awk '
  BEGIN { RS=""; FS="" }
  {
    s = $0
    while (match(s, /"[a-zA-Z_][a-zA-Z0-9_]*"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"/)) {
      pair = substr(s, RSTART, RLENGTH)
      s = substr(s, RSTART + RLENGTH)
      kstart = index(pair, "\"") + 1
      kend = index(substr(pair, kstart), "\"")
      key = substr(pair, kstart, kend - 1)
      vstart = index(pair, ":")
      rest = substr(pair, vstart + 1)
      sub(/^[[:space:]]*"/, "", rest)
      sub(/"[[:space:]]*$/, "", rest)
      gsub(/\\n/, "\n", rest)
      gsub(/\\"/, "\"", rest)
      gsub(/\\\\/, "\\", rest)
      printf "%s\t%s\0", key, rest
    }
  }
' "$ANSWERS" > "$VARS_FILE"

# Read key-value pairs from VARS_FILE into a bash associative array.
# We use NUL as the record delimiter to handle multiline values.
# Note: "read -d $'\0'" reads up to the next NUL byte.
declare -A VARS
while IFS=$'\t' read -r -d $'\0' KEY VALUE; do
  [[ -z "$KEY" ]] && continue
  VARS["$KEY"]="$VALUE"
done < "$VARS_FILE"

# --- Pass 1: inline single-line {{#if key}}...{{/if}} ---
# For each key: if value=="yes", strip the markers but keep content.
#               if value!="yes", strip markers+content entirely from single-line occurrences.
inline_pass() {
  local infile="$1"
  local outfile="$2"
  cp "$infile" "$outfile"
  for k in "${!VARS[@]}"; do
    v="${VARS[$k]}"
    if [[ "$v" == "yes" ]]; then
      # Keep content: remove {{#if key}} and {{/if}} markers on lines where they appear together.
      sed -i "s/{{#if ${k}}}\(.*\){{\/if}}/\1/g" "$outfile"
    else
      # Strip content: remove the entire {{#if key}}...{{/if}} span on a single line.
      sed -i "s/{{#if ${k}}}[^{]*{{\/if}}//g" "$outfile"
    fi
  done
}

# --- Pass 2: multi-line block {{#if key}} / {{/if}} markers each on own line ---
block_pass() {
  local infile="$1"
  local outfile="$2"
  # Build a space-separated list of keys whose value == "yes"
  local yes_keys=""
  for k in "${!VARS[@]}"; do
    if [[ "${VARS[$k]}" == "yes" ]]; then
      yes_keys="$yes_keys $k"
    fi
  done
  awk -v yes_keys="$yes_keys" '
    BEGIN {
      n = split(yes_keys, arr, " ")
      for (i = 1; i <= n; i++) {
        if (arr[i] != "") yes[arr[i]] = 1
      }
      depth = 0
      skip_depth = 0
    }
    {
      line = $0
      if (match(line, /^[[:space:]]*\{\{#if[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*\}\}[[:space:]]*$/)) {
        m = substr(line, RSTART, RLENGTH)
        gsub(/^[[:space:]]*\{\{#if[[:space:]]+/, "", m)
        gsub(/\}\}[[:space:]]*$/, "", m)
        key = m
        depth++
        if (skip_depth == 0 && !(key in yes)) {
          skip_depth = depth
        }
        next
      }
      if (match(line, /^[[:space:]]*\{\{\/if\}\}[[:space:]]*$/)) {
        if (skip_depth == depth) skip_depth = 0
        depth--
        next
      }
      if (skip_depth == 0) print line
    }
  ' "$infile" > "$outfile"
}

# --- Pass 3: substitute {{key}} placeholders ---
# Read values from VARS_FILE (NUL-delimited KEY\tVALUE\0 records).
# Use python3 if functional, else awk with per-key val_file approach.
substitute_keys() {
  local infile="$1"
  local outfile="$2"
  if [[ "$HAS_PYTHON" -eq 1 ]]; then
    cp "$infile" "$outfile"
    python3 - "$outfile" "$VARS_FILE" <<'PYEOF'
import sys

outfile = sys.argv[1]
vars_file = sys.argv[2]

with open(vars_file, 'rb') as f:
    raw = f.read()

vars_map = {}
for record in raw.split(b'\x00'):
    if not record:
        continue
    tab = record.find(b'\t')
    if tab < 0:
        continue
    key = record[:tab].decode('utf-8')
    value = record[tab+1:].decode('utf-8')
    vars_map[key] = value

with open(outfile, 'r', encoding='utf-8') as f:
    content = f.read()

for key, value in vars_map.items():
    content = content.replace('{{' + key + '}}', value)

with open(outfile, 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF
  else
    # Awk-based substitution: process one key at a time using per-key value files.
    # VARS already has the correct multiline values (loaded via NUL-delimited read).
    cp "$infile" "$outfile"
    for k in "${!VARS[@]}"; do
      local val_file
      val_file="$(mktemp)"
      # Write the value bytes; printf '%s' preserves embedded newlines.
      printf '%s' "${VARS[$k]}" > "$val_file"
      awk -v key="{{${k}}}" -v val_file="$val_file" '
        BEGIN {
          # Read the full replacement value from file, preserving embedded newlines.
          val = ""
          while ((getline vline < val_file) > 0) {
            if (val != "") val = val "\n"
            val = val vline
          }
          close(val_file)
          klen = length(key)
        }
        {
          line = $0
          out = ""
          while ((idx = index(line, key)) > 0) {
            out = out substr(line, 1, idx - 1) val
            line = substr(line, idx + klen)
          }
          print out line
        }
      ' "$outfile" > "${outfile}.tmp" && mv "${outfile}.tmp" "$outfile"
      rm -f "$val_file"
    done
  fi
}

TMP1="$(mktemp)"
TMP2="$(mktemp)"
TMP3="$(mktemp)"
trap 'rm -f "$TMP1" "$TMP2" "$TMP3" '"$TRAP_FILES" EXIT

inline_pass "$TEMPLATE" "$TMP1"
block_pass "$TMP1" "$TMP2"
substitute_keys "$TMP2" "$TMP3"

if grep -qE '\{\{' "$TMP3"; then
  echo "render-template.sh: unresolved markers remain in output:" >&2
  grep -nE '\{\{[^}]*\}\}' "$TMP3" >&2
  exit 1
fi

mv "$TMP3" "$OUTPUT"
