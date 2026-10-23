#!/bin/bash
# Spec Driven Development by stevenhdz · https://github.com/stevenhdz/spec-driven-development — framework file: `install.sh --update` overwrites it. Your commands live in .claude/gates.conf.
# Quality Gates: format (rewrites, silent) → lint (FORBIDDEN regex on added lines outside FORBIDDEN_EXCLUDE, TEST_FORBIDDEN on added test lines, then the linter) → build → tests → frs (full only: every FR in specs/current has a test and a unique ID) → commits (full with a base only: each subject since the base matches COMMIT_PATTERN) → audit, stops at the first failure, prints one line.
# Usage: bash .claude/scripts/gates.sh scoped <files…> | full [--no-format] | fr <FR-ID>
# `- Gates: OFF` in the active change's proposal.md (specs/changes/<feature>/): scoped and full print ⏭️ for every gate — fr still runs.
# Audit runs when a manifest changed: uncommitted, or since $GATES_BASE (in a GitHub PR: origin/<base branch>) in full mode.
# fr records RED: a failing run appends `- RED: <FR-ID>` to the active change's tasks.md (one active change only) — only while every unstaged or untracked code file is a test or a MANIFESTS file, so a failure after the code proves nothing.
# fr fails when it finds fewer tests than the FR's GIVEN lines — read from the active change's delta spec, else from specs/current — tests = the runner's output lines that name the FR, so a parametrized test counts each case — a lower bound, not proof: a suite header that names the FR also counts.
# Exit: 0 pass · 1 gate or test failed · 2 usage · 3 no test named <FR-ID>
set -u

root=$(cd "$(dirname "$0")/../.." && pwd)
conf="$root/.claude/gates.conf"
if ! test -f "$conf"; then echo "Gates: ❌ missing .claude/gates.conf"; exit 1; fi
if grep -qE '^[A-Z_]+="\[' "$conf"; then echo "Gates: ❌ .claude/gates.conf not configured — run /adopt or fill its [placeholders]"; exit 1; fi
. "$conf"

mode=${1:-}
shift || true
app_dir=${APP_DIR:-.}
app="$root/$app_dir"
log=$(mktemp)
trap 'rm -f "$log"' EXIT
test_path='(^|/)(__tests__|tests?|spec)/|(^|/)test_[^/]*$|[._](test|spec)\.[^/]*$'

files="" tests="" dirs="" file_list="" code=0
for f in "$@"; do
  f=${f#"$root"/}
  case "$f" in *.md) continue ;; esac
  code=1
  if test "$app_dir" != "."; then
    case "$f" in "$app_dir"/*) f=${f#"$app_dir"/} ;; *) continue ;; esac
  fi
  test -e "$app/$f" || continue
  file_list="$file_list$f
"
  q=$(printf '%q' "$f")
  files="$files $q"
  if [[ $f =~ $test_path ]]; then tests="$tests $q"; fi
  d=$(printf '%q' "$(dirname "$f")")
  case " $dirs " in *" $d "*) ;; *) dirs="$dirs $d" ;; esac
done

expand() {
  local cmd=$1
  case "$cmd" in *"{files}"*) test -n "$files" || return 1 ;; esac
  case "$cmd" in *"{tests}"*) test -n "$tests" || return 1 ;; esac
  case "$cmd" in *"{dirs}"*) test -n "$dirs" || return 1 ;; esac
  cmd=${cmd//\{files\}/"$files"}
  cmd=${cmd//\{tests\}/"$tests"}
  cmd=${cmd//\{dirs\}/"$dirs"}
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

only_tests_unstaged() {
  local f
  while IFS= read -r f; do
    test -n "$f" || continue
    case " ${MANIFESTS:-} " in *" ${f##*/} "*) continue ;; esac
    if ! [[ $f =~ $test_path ]]; then return 1; fi
  done < <( { git -C "$app" -c core.quotePath=false diff --name-only --relative; git -C "$app" -c core.quotePath=false ls-files --others --exclude-standard; } 2>/dev/null | grep -vE '\.md$|^\.claude/|^specs/')
}

has_test() {
  (cd "$app" && grep -rIliE "$(fr_pattern "$1")" . --exclude='*.md' \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=.venv --exclude-dir=target) | grep -qE "$test_path"
}

scenario_count() {
  local f n
  for f in "$root"/specs/changes/*/specs/*/spec.md "$root"/specs/current/*/spec.md; do
    test -f "$f" || continue
    n=$(awk -v id="$1" '/^#/ { on = 0 } $1 == "-" && $2 ~ /^[A-Z][A-Z0-9]*-[0-9]+$/ { on = ($2 == id); next } on && $1 == "-" && $2 == "GIVEN" { c++ } END { print c + 0 }' "$f")
    if test "$n" -gt 0; then echo "$n"; return; fi
  done
  echo 0
}

record_red() {
  local tasks
  tasks=$(ls "$root"/specs/changes/*/tasks.md 2>/dev/null)
  test -n "$tasks" && test "$(printf '%s\n' "$tasks" | wc -l)" -eq 1 || return 0
  if ! only_tests_unstaged; then echo "RED not recorded: unstaged code besides tests — run fr before writing the code"; return 0; fi
  grep -qxF -- "- RED: $1" "$tasks" || printf -- '- RED: %s\n' "$1" >>"$tasks"
}

if test "$mode" = fr; then
  fr=${1:-}
  if test -z "$fr"; then echo "usage: gates.sh fr <FR-ID>"; exit 2; fi
  fr_id=$(printf '%s' "$fr" | tr 'A-Z-' 'a-z_')
  pattern=$(fr_pattern "$fr")
  if ! has_test "$fr"; then echo "FR $fr: ❌ no test named $fr"; exit 3; fi
  if ! run "$(expand "$TEST_FR")"; then echo "FR $fr: ❌"; failing_lines; record_red "$fr"; exit 1; fi
  n=$(($(grep -iE "$pattern" "$log" | grep -viE 'test-name-pattern|-k |-t ' | awk '!seen[$0]++' | wc -l)))
  if test "$n" = 0; then echo "FR $fr: ❌ no test named $fr"; exit 3; fi
  s=$(scenario_count "$fr")
  if test "$n" -lt "$s"; then echo "FR $fr: ❌ $n tests < $s scenarios"; exit 1; fi
  echo "FR $fr: ✅ ($n tests)"
  exit 0
fi

if grep -qsE '^- Gates: OFF' "$root"/specs/changes/*/proposal.md; then
  case "$mode" in
    scoped) echo "Gates: lint ⏭️ · build ⏭️ · tests ⏭️ · audit ⏭️ (off)"; exit 0 ;;
    full) echo "Gates: lint ⏭️ · build ⏭️ · tests ⏭️ · frs ⏭️ · audit ⏭️ (off)"; exit 0 ;;
  esac
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

changed_paths() {
  git -C "$root" status --porcelain
  if test "$mode" = full && test -n "$base"; then
    git -C "$root" diff --name-only "$base...HEAD" 2>/dev/null || printf '%s\n' $MANIFESTS
  fi
}

base=${GATES_BASE:-${GITHUB_BASE_REF:+origin/$GITHUB_BASE_REF}}
if test "$mode" = full && test -n "$base" && ! git -C "$root" rev-parse -q --verify "$base^{commit}" >/dev/null; then
  echo "Gates: ❌ base $base not found — fetch it (CI: actions/checkout with fetch-depth: 0) or unset GATES_BASE"
  exit 1
fi
audit=""
paths=$(changed_paths)
for m in $MANIFESTS; do
  if printf '%s\n' "$paths" | grep -qE "(^|/)$m\$"; then audit=$AUDIT; break; fi
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

added_lines() {
  local ref f list=$file_list
  ref=HEAD
  if test "$mode" = full && test -n "$base"; then ref=$base; fi
  git -C "$app" rev-parse -q --verify "$ref" >/dev/null || ref=4b825dc642cb6eb9a060e54bf8d69288fbee4904
  if test "$mode" = full; then
    list=$( { git -C "$app" -c core.quotePath=false diff --name-only --relative "$ref"; git -C "$app" -c core.quotePath=false ls-files --others --exclude-standard; } | sort -u)
  fi
  printf '%s\n' "$list" | grep -vE '\.md$|^\.claude/' | while IFS= read -r f; do
    test -n "$f" && test -f "$app/$f" || continue
    if git -C "$app" ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
      git -C "$app" diff -U0 "$ref" -- "$f" | awk -v f="$f" '/^@@/ { split($3, a, /[+,]/); n = a[2]; next } /^\+\+\+/ { next } /^\+/ { print f ":" n ": " substr($0, 2); n++ }'
    else
      awk -v f="$f" '{ print f ":" NR ": " $0 }' "$app/$f"
    fi
  done
}

test_lines() {
  local l
  while IFS= read -r l; do
    if [[ ${l%%:*} =~ $test_path ]]; then printf '%s\n' "$l"; fi
  done
}

allowed_lines() {
  local l
  while IFS= read -r l; do
    if test -z "${FORBIDDEN_EXCLUDE:-}" || ! [[ ${l%%:*} =~ $FORBIDDEN_EXCLUDE ]]; then printf '%s\n' "$l"; fi
  done
}

commits_gate() {
  local subjects bad n
  subjects=$(git -C "$root" log --format='%h %s' "$base..HEAD" 2>/dev/null | grep -vE '^[0-9a-f]+ (Merge|Revert) ')
  n=$(printf '%s' "$subjects" | grep -c '')
  bad=$(printf '%s\n' "$subjects" | awk 'NF' | while read -r hash subject; do
    printf '%s\n' "$subject" | grep -qE "$COMMIT_PATTERN" || printf '%s %s\n' "$hash" "$subject"
  done)
  if test -n "$bad"; then echo "$line$sep commits ❌"; printf '%s\n' "$bad" | head -30; exit 1; fi
  line="$line$sep commits ✅ ($n)"
  sep=" ·"
}

if test -n "$format" && ! run "$format"; then echo "Gates: format ❌"; failing_lines; exit 1; fi
if test -n "${FORBIDDEN:-}${TEST_FORBIDDEN:-}"; then
  added=$(added_lines)
  if test -n "${FORBIDDEN:-}"; then
    hits=$(printf '%s\n' "$added" | allowed_lines | grep -E "^[^:]+:[0-9]+: .*(${FORBIDDEN})" | head -30)
    if test -n "$hits"; then echo "$line$sep lint ❌ (FORBIDDEN)"; printf '%s\n' "$hits"; exit 1; fi
  fi
  if test -n "${TEST_FORBIDDEN:-}"; then
    hits=$(printf '%s\n' "$added" | test_lines | grep -E "^[^:]+:[0-9]+: .*(${TEST_FORBIDDEN})" | head -30)
    if test -n "$hits"; then echo "$line$sep lint ❌ (TEST_FORBIDDEN)"; printf '%s\n' "$hits"; exit 1; fi
  fi
fi
gate lint "$lint"
gate build "$BUILD"
gate tests "$test_cmd"
if test "$mode" = full; then frs_gate; fi
if test "$mode" = full && test -n "${COMMIT_PATTERN:-}" && test -n "$base"; then commits_gate; fi
gate audit "$audit"
echo "$line"
