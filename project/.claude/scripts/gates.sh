#!/bin/bash
# Quality Gates: format (rewrites, silent) → lint → build → tests → frs (full only: every FR in specs/current has a test and a unique ID) → audit, stops at the first failure, prints one line.
# Usage: bash .claude/scripts/gates.sh scoped <files…> | full [--no-format] | fr <FR-ID>
# Exit: 0 pass · 1 gate or test failed · 2 usage · 3 no test named <FR-ID>
set -u

root=$(cd "$(dirname "$0")/../.." && pwd)
conf="$root/.claude/gates.conf"
if ! test -f "$conf"; then echo "Gates: ❌ missing .claude/gates.conf"; exit 1; fi
. "$conf"

mode=${1:-}
shift || true
app_dir=${APP_DIR:-.}
app="$root/$app_dir"
log=$(mktemp)
trap 'rm -f "$log"' EXIT
test_path='(^|/)(__tests__|tests?|spec)/|(^|/)test_[^/]*$|[._](test|spec)\.[^/]*$'

files="" tests="" dirs="" code=0
for f in "$@"; do
  f=${f#"$root"/}
  case "$f" in *.md) continue ;; esac
  code=1
  if test "$app_dir" != "."; then
    case "$f" in "$app_dir"/*) f=${f#"$app_dir"/} ;; *) continue ;; esac
  fi
  test -e "$app/$f" || continue
  files="$files $f"
  if [[ $f =~ $test_path ]]; then tests="$tests $f"; fi
  d=$(dirname "$f")
  case " $dirs " in *" $d "*) ;; *) dirs="$dirs $d" ;; esac
done

expand() {
  local cmd=$1
  case "$cmd" in *"{files}"*) test -n "$files" || return 1 ;; esac
  case "$cmd" in *"{tests}"*) test -n "$tests" || return 1 ;; esac
  case "$cmd" in *"{dirs}"*) test -n "$dirs" || return 1 ;; esac
  cmd=${cmd//\{files\}/$files}
  cmd=${cmd//\{tests\}/$tests}
  cmd=${cmd//\{dirs\}/$dirs}
  cmd=${cmd//\{fr_id\}/${fr_id:-}}
  cmd=${cmd//\{fr\}/${fr:-}}
  printf '%s' "$cmd"
}

failing_lines() {
  local hits
  hits=$(grep -iE 'error|fail|✖|✗|×|not ok|assert|expected' "$log" | grep -viE '(#|ℹ) fail 0' | awk '!seen[$0]++' | head -30)
  if test -n "$hits"; then printf '%s\n' "$hits"; else tail -30 "$log"; fi
}

passing_count() {
  grep -oE '(#|ℹ) pass [0-9]+|[0-9]+ (passed|passing)' "$log" | grep -oE '[0-9]+' | tail -1
}

run() {
  (cd "$app" && bash -c "$1") >"$log" 2>&1
}

fr_pattern() {
  printf '%s([^0-9]|$)' "${1//-/[-_]}"
}

has_test() {
  (cd "$app" && grep -rIliE "$(fr_pattern "$1")" . --exclude='*.md' \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=.venv --exclude-dir=target) | grep -qE "$test_path"
}

if test "$mode" = fr; then
  fr=${1:-}
  if test -z "$fr"; then echo "usage: gates.sh fr <FR-ID>"; exit 2; fi
  fr_id=$(printf '%s' "$fr" | tr 'A-Z-' 'a-z_')
  pattern=$(fr_pattern "$fr")
  if ! has_test "$fr"; then echo "FR $fr: ❌ no test named $fr"; exit 3; fi
  if ! run "$(expand "$TEST_FR")"; then echo "FR $fr: ❌"; failing_lines; exit 1; fi
  n=$(grep -iE "$pattern" "$log" | grep -viE 'test-name-pattern|-k |-t ' | awk '!seen[$0]++' | wc -l)
  if test "$n" = 0; then echo "FR $fr: ❌ no test named $fr"; exit 3; fi
  echo "FR $fr: ✅ ($n tests)"
  exit 0
fi

case "$mode" in
  scoped)
    if test "$code" = 0; then echo "Gates: lint ⏭️ · build ⏭️ · tests ⏭️ · audit ⏭️ (docs only)"; exit 0; fi
    format=$(expand "${FORMAT_SCOPED:-}") || format=${FORMAT_FULL:-}
    lint=$(expand "$LINT_SCOPED") || lint=$LINT_FULL
    test_cmd=$(expand "$TEST_SCOPED") || test_cmd=$TEST_FULL ;;
  full)
    format=${FORMAT_FULL:-}
    if test "${1:-}" = --no-format; then format=""; fi
    lint=$LINT_FULL
    test_cmd=$TEST_FULL ;;
  *) echo "usage: gates.sh scoped <files…> | full [--no-format] | fr <FR-ID>"; exit 2 ;;
esac

audit=""
for m in $MANIFESTS; do
  if git -C "$root" status --porcelain | grep -qE "(^|/)$m\$"; then audit=$AUDIT; break; fi
done

line="Gates:"
sep=""
gate() {
  local name=$1 cmd=$2 extra=""
  if test -z "$cmd"; then line="$line$sep $name ⏭️"; sep=" ·"; return 0; fi
  if ! run "$cmd"; then
    echo "$line$sep $name ❌"
    failing_lines
    exit 1
  fi
  if test "$name" = tests; then
    n=$(passing_count)
    extra=${n:+ ($n passing)}
  fi
  line="$line$sep $name ✅$extra"
  sep=" ·"
}

frs_gate() {
  local ids id errors="" n=0
  ids=$(grep -hoE '^- [A-Z][A-Z0-9]*-[0-9]+ ' "$root"/specs/current/*/spec.md 2>/dev/null | grep -oE '[A-Z][A-Z0-9]*-[0-9]+')
  if test -z "$ids"; then line="$line$sep frs ⏭️"; sep=" ·"; return 0; fi
  for id in $(printf '%s\n' "$ids" | sort | uniq -d); do
    errors="$errors
FR $id: ❌ duplicate ID"
  done
  for id in $ids; do
    n=$((n + 1))
    has_test "$id" || errors="$errors
FR $id: ❌ no test named $id"
  done
  if test -n "$errors"; then
    echo "$line$sep frs ❌"
    printf '%s\n' "$errors" | awk 'NF && !seen[$0]++'
    exit 1
  fi
  line="$line$sep frs ✅ ($n)"
  sep=" ·"
}

if test -n "$format" && ! run "$format"; then echo "Gates: format ❌"; failing_lines; exit 1; fi
gate lint "$lint"
gate build "$BUILD"
gate tests "$test_cmd"
if test "$mode" = full; then frs_gate; fi
gate audit "$audit"
echo "$line"
