#!/bin/bash
# PreToolUse hook for Bash: blocks a command that names a secret — every path denied for Edit in .claude/settings.json (and settings.local.json); a `!` entry stays allowed.
# Covers what deny rules miss in a shell: python -c "open('.env')", node, cp, base64, find -exec, and other commands Claude Code does not parse.
# Limit: it reads the command text — a script file that opens a secret by itself is not caught; the sandbox covers that (readme → Security).
# Exit: 0 allowed · 2 blocked (the reason goes to Claude on stderr)
set -u

root=$(cd "$(dirname "$0")/../.." && pwd)

cmd=$(awk 'BEGIN { RS = "\001" }
{
  i = index($0, "\"command\":")
  if (!i) exit
  s = substr($0, i + 10)
  sub(/^[ \t\r\n]*"/, "", s)
  out = ""; esc = 0
  for (j = 1; j <= length(s); j++) {
    c = substr(s, j, 1)
    if (esc) { out = out c; esc = 0; continue }
    if (c == "\\") { esc = 1; out = out c; continue }
    if (c == "\"") break
    out = out c
  }
  print out
}')
test -n "$cmd" || exit 0

entries=$(cat "$root/.claude/settings.json" "$root/.claude/settings.local.json" 2>/dev/null | grep -oE '"Edit\([^)]+\)"' | sed -E 's/^"Edit\((.*)\)"$/\1/')
test -n "$entries" || exit 0

edge='[^A-Za-z0-9_.-]'
to_regex() {
  local p=$1 tail=""
  p=${p#\~/}
  p=${p#//}
  p=${p#/}
  case "$p" in */\*\*) p=${p%/\*\*}; tail="(/|$edge|\$)" ;; *) tail="($edge|\$)" ;; esac
  p=$(printf '%s' "$p" | sed -E 's/\./\\./g; s/\*\*/@@/g; s/\*/[^\/[:space:]"'"'"'`;|\&<>()]*/g; s/@@/.*/g')
  printf '(^|%s)%s%s' "$edge" "$p" "$tail"
}

for e in $entries; do
  case "$e" in '!'*) cmd=$(printf '%s' "$cmd" | sed -E "s#$(to_regex "${e#!}")#\\1 #g") ;; esac
done

for e in $entries; do
  case "$e" in '!'*) continue ;; esac
  if printf '%s' "$cmd" | grep -qE "$(to_regex "$e")"; then
    echo "Blocked: the command names $e — denied in .claude/settings.json. NEVER read, print or work around it — ask the human for the value." >&2
    exit 2
  fi
done
exit 0
