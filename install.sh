#!/bin/bash
# Installs project/ into the current directory: copies every file that does not exist yet, never overwrites one.
# --update also overwrites the framework files listed in this repo's sdd-core and deletes the old ones listed in sdd-removed — your files (project.md, gates.conf, settings.json, specs/, docs/) stay untouched.
# Usage: curl -fsSL https://raw.githubusercontent.com/stevenhdz/spec-driven-development/main/install.sh | bash [-s -- [--update] [<tag|branch>]]
# Exit: 0 installed · 1 download failed
set -u

update=0
if test "${1:-}" = --update; then update=1; shift; fi
ref=${1:-main}
repo=stevenhdz/spec-driven-development
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if ! curl -fsSL "https://codeload.github.com/$repo/tar.gz/$ref" | tar -xz -C "$tmp" 2>/dev/null; then
  echo "SDD: ❌ could not download $repo@$ref"
  exit 1
fi
src=$(echo "$tmp"/*/project)
root=${src%/project}
core_file=$root/sdd-core
test -f "$core_file" || core_file=$src/.claude/sdd-core
core=$(grep -vE '^(#|$)' "$core_file" 2>/dev/null)
removed=$(grep -vE '^(#|$)' "$root/sdd-removed" 2>/dev/null)

is_core() {
  local p
  for p in $core; do
    case "$p" in
      */) case "$1" in "$p"*) return 0 ;; esac ;;
      *) test "$1" = "$p" && return 0 ;;
    esac
  done
  return 1
}

legacy=0 overwrite=$update
if test "$update" = 1 && test -e CLAUDE.md && ! test -e .claude/project.md && ! grep -qxF '@.claude/project.md' CLAUDE.md; then
  legacy=1 overwrite=0
fi

added=0 updated=0 kept=""
while IFS= read -r f; do
  f=${f#"$src"/}
  if test -e "$f"; then
    if cmp -s "$src/$f" "$f"; then continue; fi
    if test "$overwrite" = 1 && is_core "$f"; then
      cp "$src/$f" "$f"
      updated=$((updated + 1))
    else
      kept="$kept $f"
    fi
    continue
  fi
  mkdir -p "$(dirname "$f")"
  cp "$src/$f" "$f"
  added=$((added + 1))
done < <(find "$src" -type f)
chmod +x .claude/scripts/gates.sh

deleted=0
if test "$overwrite" = 1; then
  for f in $removed; do
    test -f "$f" || continue
    rm "$f"
    rmdir -p "$(dirname "$f")" 2>/dev/null
    deleted=$((deleted + 1))
  done
fi

echo "SDD $ref: ✅ $added files added · $updated updated · $deleted removed"
if test -n "$kept"; then
  echo "Kept yours, differs from $ref:"
  for f in $kept; do echo "  $f"; done
  echo "Compare with $ref: https://github.com/$repo/tree/$ref/project"
fi
if test "$legacy" = 1; then
  echo "CLAUDE.md predates v1.6: nothing updated — move your values into .claude/project.md, then rerun with --update"
fi
if test "$update" = 1; then
  echo "Next: review git diff"
else
  echo "Next: existing code → open Claude Code and run /adopt · new project → fill the [placeholders] (readme → Setup)"
fi
