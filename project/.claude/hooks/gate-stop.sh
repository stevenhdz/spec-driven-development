#!/bin/bash
# Spec Driven Development by stevenhdz · https://github.com/stevenhdz/spec-driven-development — framework file: `install.sh --update` overwrites it.
# Stop and SubagentStop hook: ending a turn with code changed since the last gates run is blocked once — CLAUDE.md asks for gates at every close, this enforces the evidence, not a pass: a ❌ is reported, never fixed silently.
# Files: `gates.sh pending` — changed code files (.claude/ and .md skipped) whose content no scoped or full run checked. gates.conf not configured: nothing is pending.
# stop_hook_active (a block already sent Claude back this turn): allowed, so the hook never loops.
# Exit: 0 allowed · 2 blocked (the files and what to run go to Claude on stderr)
set -u

root=$(cd "$(dirname "$0")/../.." && pwd)

if grep -qE '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then exit 0; fi

pending=$(cd "$root" && bash .claude/scripts/gates.sh pending 2>/dev/null)
test -n "$pending" || exit 0
printf 'Blocked: code changed since the last gates run — run `bash .claude/scripts/gates.sh scoped <files>` on these files and report the line it prints · ❌: quote it and stop, do not fix it unasked.\n%s\n' "$pending" >&2
exit 2
