#!/usr/bin/env bash
# render-template.sh — substitute {{key}} and strip {{#if key}}…{{/if}} blocks (block + inline forms).
# Usage: render-template.sh <template> <answers.json> <output>
# answers.json must be a flat object of string values. Conditional keys must be "yes" or "no".
#
# Portability: runs on bash 3.2 (stock macOS) and any POSIX awk (BSD/macOS awk, mawk, gawk).
# No associative bash arrays, no `sed -i`, no NUL-delimited data, no python.
# Semantics mirror render-template.ps1; tests/render-template.test.* keep the two in parity.

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: render-template.sh <template> <answers.json> <output>" >&2
  exit 2
fi

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

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# ARGV[1] = answers.json (read in BEGIN via getline, then removed from the input list),
# ARGV[2] = template (processed line by line by the main rule).
if ! awk '
  # Decode JSON string escapes: \n \t \r \" \\ \/. Anything else is kept verbatim.
  function unescape(s,    out, i, c, n) {
    out = ""
    n = length(s)
    for (i = 1; i <= n; i++) {
      c = substr(s, i, 1)
      if (c == "\\" && i < n) {
        i++
        c = substr(s, i, 1)
        if (c == "n") out = out "\n"
        else if (c == "t") out = out "\t"
        else if (c == "r") out = out "\r"
        else if (c == "\"" || c == "\\" || c == "/") out = out c
        else out = out "\\" c
      } else {
        out = out c
      }
    }
    return out
  }

  # Replace every literal occurrence of `needle` in `s` with `repl` (no regex).
  function replace_all(s, needle, repl,    out, idx, nlen) {
    out = ""
    nlen = length(needle)
    while ((idx = index(s, needle)) > 0) {
      out = out substr(s, 1, idx - 1) repl
      s = substr(s, idx + nlen)
    }
    return out s
  }

  # Inline form on one line: {{#if key}}content{{/if}}. Non-greedy: each opener pairs
  # with the first {{/if}} after it. yes -> keep content, anything else -> drop it.
  function inline_if(s, key, keep,    opener, closer, out, idx, rest, cidx) {
    opener = "{{#if " key "}}"
    closer = "{{/if}}"
    out = ""
    while ((idx = index(s, opener)) > 0) {
      rest = substr(s, idx + length(opener))
      cidx = index(rest, closer)
      if (cidx == 0) break
      out = out substr(s, 1, idx - 1)
      if (keep) out = out substr(rest, 1, cidx - 1)
      s = substr(rest, cidx + length(closer))
    }
    return out s
  }

  BEGIN {
    answers = ARGV[1]
    ARGV[1] = ""
    json = ""
    while ((getline line < answers) > 0) {
      sub(/\r$/, "", line)
      json = json line "\n"
    }
    close(answers)

    nkeys = 0
    pat = "\"[A-Za-z_][A-Za-z0-9_]*\"[ \t\n]*:[ \t\n]*\"([^\"\\\\]|\\\\.)*\""
    while (match(json, pat)) {
      pair = substr(json, RSTART, RLENGTH)
      json = substr(json, RSTART + RLENGTH)
      k = pair
      sub(/^"/, "", k)
      sub(/".*/, "", k)
      v = pair
      sub(/^"[A-Za-z_][A-Za-z0-9_]*"[ \t\n]*:[ \t\n]*"/, "", v)
      sub(/"$/, "", v)
      if (!(k in vars)) keys[++nkeys] = k
      vars[k] = unescape(v)
    }

    depth = 0
    skip_depth = 0
    bad = 0
  }

  {
    line = $0
    sub(/\r$/, "", line)

    # Pass 1: inline conditionals.
    for (i = 1; i <= nkeys; i++) {
      if (index(line, "{{#if " keys[i] "}}") > 0) {
        line = inline_if(line, keys[i], vars[keys[i]] == "yes")
      }
    }

    # Pass 2: block markers, each alone on its own line. Nesting tracked by depth.
    if (line ~ /^[ \t]*[{][{]#if[ \t]+[A-Za-z_][A-Za-z0-9_]*[}][}][ \t]*$/) {
      key = line
      sub(/^[ \t]*[{][{]#if[ \t]+/, "", key)
      sub(/[}][}][ \t]*$/, "", key)
      depth++
      if (skip_depth == 0 && !((key in vars) && vars[key] == "yes")) skip_depth = depth
      next
    }
    if (line ~ /^[ \t]*[{][{]\/if[}][}][ \t]*$/) {
      if (skip_depth == depth) skip_depth = 0
      depth--
      next
    }
    if (skip_depth != 0) next

    # Pass 3: placeholder substitution.
    for (i = 1; i <= nkeys; i++) {
      ph = "{{" keys[i] "}}"
      if (index(line, ph) > 0) line = replace_all(line, ph, vars[keys[i]])
    }

    if (index(line, "{{") > 0) {
      bad++
      badlines[bad] = FNR ": " line
    }
    print line
  }

  END {
    if (bad > 0) {
      print "render-template.sh: unresolved markers remain in output:" > "/dev/stderr"
      for (i = 1; i <= bad; i++) print badlines[i] > "/dev/stderr"
      exit 1
    }
  }
' "$ANSWERS" "$TEMPLATE" > "$TMP"; then
  exit 1
fi

mv "$TMP" "$OUTPUT"
trap - EXIT
