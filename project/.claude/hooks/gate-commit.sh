#!/bin/bash
# Spec Driven Development by stevenhdz · https://github.com/stevenhdz/spec-driven-development — framework file: `install.sh --update` overwrites it. Your gate commands live in .claude/gates.conf.
# PreToolUse hook for Bash: a `git commit` runs scoped Quality Gates on the files it commits and is blocked on ❌ — CLAUDE.md asks for gates, this enforces them.
# Detects git commit anywhere in the command — wrapped in sh -c, after env vars or xargs, with -C / -c options; a false match only runs the gates.
# Files: the staged ones, plus every uncommitted change when the same command runs git add / git stage or commit -a / --all (the hook runs before the command, so those are not staged yet) — .claude/ and .md files skipped; none left: the commit passes. Gates run with --no-format, so they check what gets committed.
# Skips the run when every changed code file already passed with its current content and the same gates.conf (`gates.sh passed`) — and, without add / -a, each committed file is staged as checked.
# Exit: 0 allowed · 2 blocked (the gates output goes to Claude on stderr)
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
printf '%s' "$cmd" | grep -qE '(^|[^[:alnum:]_.-])git[[:space:]]([^;&|]*[[:space:]])?commit([^[:alnum:]_-]|$)' || exit 0

files=() seen=" "
add_files() {
  local f
  while IFS= read -r -d '' f; do
    case "$f" in .claude/*|*.md) continue ;; esac
    case "$seen" in *" $f "*) continue ;; esac
    files+=("$f"); seen="$seen$f "
  done
}
add_files < <(git -C "$root" diff --staged --name-only -z)
staged=--staged
if printf '%s' "$cmd" | grep -qE '(^|[^[:alnum:]_.-])git[[:space:]]([^;&|]*[[:space:]])?(add|stage)([^[:alnum:]_-]|$)|[[:space:]](-[A-Za-z]*a[A-Za-z]*|--all)([[:space:]]|$)'; then
  staged=""
  add_files < <(git -C "$root" diff --name-only -z)
  add_files < <(git -C "$root" ls-files --others --exclude-standard -z)
fi
test "${#files[@]}" -gt 0 || exit 0
if (cd "$root" && bash .claude/scripts/gates.sh passed $staged "${files[@]}") >/dev/null 2>&1; then exit 0; fi

out=$(cd "$root" && bash .claude/scripts/gates.sh scoped --no-format "${files[@]}" 2>&1)
status=$?
if test "$status" != 0; then
  printf 'Blocked: Quality Gates failed on the files this commit includes — fix them, stage, commit again.\n%s\n' "$out" >&2
  exit 2
fi
exit 0
