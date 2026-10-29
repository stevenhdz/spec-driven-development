#!/bin/bash
# Spec Driven Development by stevenhdz · https://github.com/stevenhdz/spec-driven-development — framework file: `install.sh --update` overwrites it. Your commands live in .claude/gates.conf.
# Quality Gates: format (rewrites, silent) → lint (FORBIDDEN regex on added lines outside FORBIDDEN_EXCLUDE, TEST_FORBIDDEN on added test lines, then the linter) → build → tests → frs (full only: every FR in specs/current has a test and a unique ID) → commits (full with a base only: each subject since the base matches COMMIT_PATTERN) → audit, stops at the first failure, prints one line.
# Usage: bash .claude/scripts/gates.sh scoped [--no-format] <files…> | full [--no-format] | fr <FR-ID> | pending | passed [--staged] <files…> | test-paths
# --no-format skips the format step — the commit hook uses it so staged content is what gets checked.
# scoped and full record each code file they check as `<hash> <ok:<gates.conf hash>|fail> <path>` in .git/sdd-gates — fr records the changed test files no run checked yet as `fr`, so a RED paused for a question is not pending, but never counts as passed — pending prints the changed code files (.claude/ and .md skipped) whose content no run checked since its last change, pass or fail — the stop hook uses it · gates.conf missing or not configured: pending prints nothing.
# test-paths: classifies the repo's files with the test path regex — ❌ lists test-like names it misses — /adopt uses it to check TEST_PATH.
# passed: exit 0 when every changed code file passed with its current content and the current gates.conf · --staged: each given file is also staged as checked — the commit hook uses it to skip a second run.
# `- Gates: OFF` in the active change's proposal.md (specs/changes/<feature>/): scoped and full print ⏭️ for every gate — fr still runs.
# Audit runs when a manifest changed: uncommitted, or since $GATES_BASE (in a GitHub PR: origin/<base branch>) in full mode.
# fr records RED: a failing run appends `- RED: <FR-ID>` to the active change's tasks.md (one active change only) — only while every unstaged or untracked code file is a test or a MANIFESTS file, so a failure after the code proves nothing.
# fr fails when it finds fewer tests than the FR's GIVEN lines — read from the active change's delta spec, else from specs/current — tests = the runner's output lines that name the FR, so a parametrized test counts each case — a lower bound, not proof: a suite header that names the FR also counts.
# Exit: 0 pass · 1 gate or test failed, or pending files · 2 usage · 3 no test named <FR-ID>
set -u

root=$(cd "$(dirname "$0")/../.." && pwd)
conf="$root/.claude/gates.conf"
if ! test -f "$conf"; then test "${1:-}" = pending && exit 0; echo "Gates: ❌ missing .claude/gates.conf"; exit 1; fi
if grep -qE '^[A-Z_]+="\[' "$conf"; then test "${1:-}" = pending && exit 0; echo "Gates: ❌ .claude/gates.conf not configured — run /adopt or fill its [placeholders]"; exit 1; fi
. "$conf"

mode=${1:-}
shift || true
no_format=""
if test "${1:-}" = --no-format; then no_format=1; shift; fi
staged=""
if test "${1:-}" = --staged; then staged=1; shift; fi
app_dir=${APP_DIR:-.}
app="$root/$app_dir"
log=$(mktemp)
stamp=$(git -C "$root" rev-parse --absolute-git-dir 2>/dev/null) && stamp="$stamp/sdd-gates"
conf_hash=$(git -C "$root" hash-object -- "$conf" 2>/dev/null)
trap 'st=$?; rm -f "$log"; record "$st"' EXIT
# TEST_PATH in gates.conf: the project's own test paths — empty or missing: these built-in ones.
test_path=${TEST_PATH:-'(^|/)(__tests__|tests?|spec)/|(^|/)test_[^/]*$|[._](test|spec)\.[^/]*$|(^|/)[^/]*\.[^/]*Tests?/|Tests?\.cs$'}
# TEST_PATH_EXCLUDE in gates.conf: paths never treated as tests — a source file a test path or the missed check matches (e.g. LoadTest.cs).
test_exclude=${TEST_PATH_EXCLUDE:-}
excluded() { test -n "$test_exclude" && [[ $1 =~ $test_exclude ]]; }
is_test() { [[ $1 =~ $test_path ]] && ! excluded "$1"; }
tests_only() { local f; while IFS= read -r f; do if is_test "$f"; then printf '%s\n' "$f"; fi; done; }

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
  if is_test "$f"; then tests="$tests $q"; fi
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
    if ! is_test "$f"; then return 1; fi
  done < <( { git -C "$app" -c core.quotePath=false diff --name-only --relative; git -C "$app" -c core.quotePath=false ls-files --others --exclude-standard; } 2>/dev/null | grep -vE '\.md$|^\.claude/|^specs/')
}

changed_code() {
  local f
  { git -C "$root" -c core.quotePath=false diff --name-only --relative
    git -C "$root" -c core.quotePath=false diff --staged --name-only --relative
    git -C "$root" -c core.quotePath=false ls-files --others --exclude-standard; } 2>/dev/null | grep -vE '\.md$|^\.claude/' | awk '!seen[$0]++' | while IFS= read -r f; do
    test -n "$f" && test -f "$root/$f" || continue
    if test "$app_dir" != "."; then case "$f" in "$app_dir"/*) ;; *) continue ;; esac; fi
    printf '%s\n' "$f"
  done
}

hashed() {
  local f
  while IFS= read -r f; do
    test -n "$f" && test -f "$root/$f" && printf '%s %s\n' "$(git -C "$root" hash-object -- "$f")" "$f"
  done
}

record() {
  local new f status=fail
  case "$mode" in scoped|full|fr) ;; *) return 0 ;; esac
  test -n "$stamp" || return 0
  if test "$1" = 0; then status="ok:$conf_hash"; fi
  if test "$mode" = fr; then
    status=fr
    new=$(unchecked "" | tests_only | hashed)
  elif test "$mode" = full; then
    new=$(changed_code | hashed)
  else
    new=$(printf '%s' "$file_list" | while IFS= read -r f; do
      test -n "$f" || continue
      if test "$app_dir" = "."; then printf '%s\n' "$f"; else printf '%s/%s\n' "$app_dir" "$f"; fi
    done | hashed)
  fi
  test -n "$new" || return 0
  new=$(printf '%s\n' "$new" | awk -v s="$status" '{ i = index($0, " "); print substr($0, 1, i) s " " substr($0, i + 1) }')
  { if test -f "$stamp"; then
      printf '%s\n' "$new" | cut -d' ' -f3- | awk 'NR == FNR { drop[$0]; next } { p = $0; sub(/^[^ ]+ [^ ]+ /, "", p) } !(p in drop)' - "$stamp"
    fi
    printf '%s\n' "$new"; } >"$stamp.tmp" && mv "$stamp.tmp" "$stamp"
}

# Changed code files with no record of their current content — with a status, no record with that status.
unchecked() {
  changed_code | hashed | awk -v stamp="$stamp" -v want="$1" '
    BEGIN {
      while (stamp != "" && (getline l < stamp) > 0) {
        h = l; sub(/ .*/, "", h)
        s = l; sub(/^[^ ]+ /, "", s); p = s; sub(/^[^ ]+ /, "", p); sub(/ .*/, "", s)
        if (want == "" || s == want) seen[h " " p]
      }
    }
    !($0 in seen) { print substr($0, index($0, " ") + 1) }'
}

has_test() {
  git -C "$app" -c core.quotePath=false grep --untracked -lIiE "$(fr_pattern "$1")" -- . ':(exclude)*.md' 2>/dev/null | tests_only | grep -q .
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

if test "$mode" = test-paths; then
  all=$(git -C "$app" -c core.quotePath=false ls-files --cached --others --exclude-standard 2>/dev/null | grep -vE '\.md$|(^|/)\.')
  found=$(printf '%s\n' "$all" | tests_only)
  # A test-like name the regex misses: a test/spec word between separators, or a CamelCase Test/Spec suffix — not pytest, vitest, latest.
  missed=$(printf '%s\n' "$all" | grep -E '(^|[/._-])([Tt]ests?|[Ss]pecs?)([/._-]|$)|[a-z0-9](Tests?|Specs?)([/._-]|$)' | while IFS= read -r f; do
    is_test "$f" || excluded "$f" || printf '%s\n' "$f"
  done)
  if test -n "$missed"; then
    echo "Test paths: ❌ $(printf '%s\n' "$missed" | grep -c .) missed — set TEST_PATH in .claude/gates.conf to match the tests, TEST_PATH_EXCLUDE for source files"
    printf '%s\n' "$missed" | head -10
    exit 1
  fi
  echo "Test paths: ✅ $(printf '%s' "$found" | grep -c .) test files"
  printf '%s\n' "$found" | head -5 | awk 'NF'
  exit 0
fi

if test "$mode" = pending; then
  pending=$(unchecked "")
  test -z "$pending" && exit 0
  printf '%s\n' "$pending"
  exit 1
fi

if test "$mode" = passed; then
  if test -n "$staged"; then
    while IFS= read -r f; do
      test -z "$f" || git -C "$app" diff --quiet -- "$f" || exit 1
    done <<<"$file_list"
  fi
  test -n "$conf_hash" && test -z "$(unchecked "ok:$conf_hash")"
  exit
fi

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
    lint=$LINT_FULL
    test_cmd=$TEST_FULL ;;
  *) echo "usage: gates.sh scoped [--no-format] <files…> | full [--no-format] | fr <FR-ID> | pending | passed [--staged] <files…> | test-paths"; exit 2 ;;
esac
if test -n "$no_format"; then format=""; fi

changed_paths() {
  git -C "$root" -c core.quotePath=false diff --name-only --relative
  git -C "$root" -c core.quotePath=false diff --staged --name-only --relative
  git -C "$root" -c core.quotePath=false ls-files --others --exclude-standard
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
    if is_test "${l%%:*}"; then printf '%s\n' "$l"; fi
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
