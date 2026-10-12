#!/bin/bash
# Installs project/ into the current directory: copies every file that does not exist yet, never overwrites one.
# Usage: curl -fsSL https://raw.githubusercontent.com/stevenhdz/spec-driven-development/main/install.sh | bash [-s <tag|branch>]
# Exit: 0 installed · 1 download failed
set -u

ref=${1:-main}
repo=stevenhdz/spec-driven-development
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if ! curl -fsSL "https://codeload.github.com/$repo/tar.gz/$ref" | tar -xz -C "$tmp" 2>/dev/null; then
  echo "SDD: ❌ could not download $repo@$ref"
  exit 1
fi
src=$(echo "$tmp"/*/project)

added=0 kept=""
while IFS= read -r f; do
  f=${f#"$src"/}
  if test -e "$f"; then
    kept="$kept $f"
    continue
  fi
  mkdir -p "$(dirname "$f")"
  cp "$src/$f" "$f"
  added=$((added + 1))
done < <(find "$src" -type f)
chmod +x .claude/scripts/gates.sh

echo "SDD $ref: ✅ $added files added"
if test -n "$kept"; then
  echo "Kept existing, not overwritten:"
  for f in $kept; do echo "  $f"; done
  echo "Merge them by hand with $ref: https://github.com/$repo/tree/$ref/project"
fi
echo "Next: existing code → open Claude Code and run /adopt · new project → fill the [placeholders] (readme → Setup)"
