#!/bin/bash
# Quality Gates: format (rewrites, silent) → lint → build → tests → audit, stops at the first failure, prints one line.
# Usage: bash .claude/scripts/gates.sh scoped <files…> | full [--no-format] | rf <RF-ID>
# Exit: 0 pass · 1 gate or test failed · 2 usage · 3 no test named <RF-ID>
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
  case "${f##*/}" in *test*|*spec*) tests="$tests $f" ;; esac
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
  cmd=${cmd//\{rf_id\}/${rf_id:-}}
  cmd=${cmd//\{rf\}/${rf:-}}
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

if test "$mode" = rf; then
  rf=${1:-}
  if test -z "$rf"; then echo "usage: gates.sh rf <RF-ID>"; exit 2; fi
  rf_id=$(printf '%s' "$rf" | tr 'A-Z-' 'a-z_')
  pattern="${rf//-/[-_]}([^0-9]|\$)"
  if ! grep -rIqiE "$pattern" "$app" --include='*test*' --include='*spec*' \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=.venv --exclude-dir=target; then
    echo "RF $rf: ❌ no test named $rf"; exit 3
  fi
  if ! run "$(expand "$TEST_RF")"; then echo "RF $rf: ❌"; failing_lines; exit 1; fi
  n=$(grep -iE "$pattern" "$log" | grep -viE 'test-name-pattern|-k |-t ' | awk '!seen[$0]++' | wc -l)
  if test "$n" = 0; then echo "RF $rf: ❌ no test named $rf"; exit 3; fi
  echo "RF $rf: ✅ ($n tests)"
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
  *) echo "usage: gates.sh scoped <files…> | full [--no-format] | rf <RF-ID>"; exit 2 ;;
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

if test -n "$format" && ! run "$format"; then echo "Gates: format ❌"; failing_lines; exit 1; fi
gate lint "$lint"
gate build "$BUILD"
gate tests "$test_cmd"
gate audit "$audit"
echo "$line"
