#!/bin/bash
# Tests for project/.claude/scripts/gates.sh — each case runs in a throwaway git repo.
# Usage: bash tests/gates.test.sh
# Exit: 0 all pass · 1 a case failed
set -u
unset GATES_BASE GITHUB_BASE_REF

framework="$(cd "$(dirname "$0")/.." && pwd)/project/.claude"
dirs=""
trap 'rm -rf $dirs' EXIT
passed=0 failed=0

git_() { git -C "$dir" -c user.name=test -c user.email=test@test -c commit.gpgsign=false "$@"; }
commit() { git_ add -A && git_ commit -qm "$1"; }

new_repo() {
  dir=$(mktemp -d)
  dirs="$dirs $dir"
  mkdir -p "$dir/.claude/scripts" "$dir/.claude/hooks" "$dir/src" "$dir/tests"
  cp "$framework/scripts/gates.sh" "$dir/.claude/scripts/gates.sh"
  cp "$framework/hooks/gate-commit.sh" "$dir/.claude/hooks/gate-commit.sh"
  cp "$framework/hooks/gate-stop.sh" "$dir/.claude/hooks/gate-stop.sh"
  cat >"$dir/.claude/gates.conf" <<'EOF'
APP_DIR="."
FORMAT_SCOPED=""
FORMAT_FULL=""
LINT_SCOPED="true"
LINT_FULL="true"
BUILD=""
TEST_SCOPED="true"
TEST_FULL="true"
TEST_FR='bash tests/run.sh {fr}'
AUDIT=""
FORBIDDEN='@ts-ignore'
COMMIT_PATTERN='^(feat|fix|chore): .+'
TEST_FORBIDDEN='getByTestId'
MANIFESTS="package.json"
EOF
  # Minimal runner: each line of tests/*.test.txt is `<name>|<shell command>`.
  cat >"$dir/tests/run.sh" <<'EOF'
status=0
for f in tests/*.test.txt; do
  test -f "$f" || continue
  while IFS='|' read -r name cmd; do
    case "$name" in "$1 "*) if bash -c "$cmd"; then echo "ok $name"; else echo "FAIL $name"; status=1; fi ;; esac
  done <"$f"
done
exit $status
EOF
  git_ init -q -b main
  commit "chore: init"
}

conf() {
  { grep -v "^$1=" "$dir/.claude/gates.conf"; printf '%s=%s\n' "$1" "$2"; } >"$dir/gates.conf.new"
  mv "$dir/gates.conf.new" "$dir/.claude/gates.conf"
}

gates() {
  out=$(cd "$dir" && bash .claude/scripts/gates.sh "$@" 2>&1)
  code=$?
}

hook() {
  out=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" | bash "$dir/.claude/hooks/gate-commit.sh" 2>&1)
  code=$?
}

stop_hook() {
  out=$(printf '{"hook_event_name":"Stop","stop_hook_active":%s}' "${1:-false}" | bash "$dir/.claude/hooks/gate-stop.sh" 2>&1)
  code=$?
}

expect() {
  local name=$1 want_code=$2 want_text=$3
  if test "$code" = "$want_code" && [[ $out == *"$want_text"* ]]; then
    passed=$((passed + 1)); echo "ok   $name"
  else
    failed=$((failed + 1)); echo "FAIL $name — want exit $want_code with \"$want_text\", got exit $code:"
    printf '%s\n' "$out" | sed 's/^/       /'
  fi
}

two_scenario_spec() {
  mkdir -p "$dir/specs/current/ord"
  cat >"$dir/specs/current/ord/spec.md" <<'EOF'
- ORD-01 — The system MUST total the order | test: -
  - GIVEN two items | WHEN totaled | THEN sums them
  - GIVEN no items | WHEN totaled | THEN returns 0
EOF
}

# Config
new_repo
conf APP_DIR '"[e.g. app]"'
gates full
expect "unfilled gates.conf fails" 1 "not configured"

# Base
new_repo
GATES_BASE=origin/main gates full
expect "missing base fails instead of scanning the whole repo" 1 "base origin/main not found"

new_repo
echo '// @ts-ignore' >"$dir/src/legacy.ts"
commit "chore: legacy"
git_ checkout -qb feat/x
echo 'export const b = 1' >"$dir/src/b.ts"
commit "feat: add b"
GATES_BASE=main gates full
expect "FORBIDDEN ignores lines already on the base" 0 "commits ✅ (1)"

echo '// @ts-ignore' >"$dir/src/c.ts"
GATES_BASE=main gates full
expect "FORBIDDEN fails an added line" 1 "lint ❌ (FORBIDDEN)"

new_repo
git_ checkout -qb feat/x
echo 'export const b = 1' >"$dir/src/b.ts"
commit "added b"
GATES_BASE=main gates full
expect "commits fails a subject off COMMIT_PATTERN" 1 "commits ❌"

new_repo
conf FORBIDDEN_EXCLUDE "'(^|/)[^/]*\.config\.ts$'"
echo '// @ts-ignore' >"$dir/vite.config.ts"
gates scoped vite.config.ts
expect "FORBIDDEN_EXCLUDE skips a matching path" 0 "lint ✅"

echo '// @ts-ignore' >"$dir/src/app.ts"
gates scoped src/app.ts
expect "FORBIDDEN_EXCLUDE keeps other paths" 1 "lint ❌ (FORBIDDEN)"

new_repo
echo "FORBIDDEN_DOC='@ts-ignore'" >"$dir/.claude/notes.conf"
gates scoped .claude/notes.conf
expect "scoped FORBIDDEN skips .claude/" 0 "lint ✅"

new_repo
conf FORBIDDEN "': any([^[:alnum:]_]|\$)'"
echo 'let anything: anything' >"$dir/src/a.ts"
gates scoped src/a.ts
expect "POSIX word boundary passes a longer word" 0 "lint ✅"

echo 'let x: any' >"$dir/src/b.ts"
gates scoped src/b.ts
expect "POSIX word boundary fails the bare word" 1 "lint ❌ (FORBIDDEN)"

# Paths with spaces
new_repo
conf LINT_SCOPED "'test -f {files}'"
echo 'export const a = 1' >"$dir/src/my file.ts"
gates scoped "src/my file.ts"
expect "a path with a space reaches the lint command as one file" 0 "lint ✅"

echo '// @ts-ignore' >"$dir/src/my file.ts"
gates scoped "src/my file.ts"
expect "FORBIDDEN checks a path with a space" 1 "src/my file.ts:1: // @ts-ignore"

# --no-format
new_repo
conf FORMAT_SCOPED "'printf x >> {files}'"
echo 'export const a = 1' >"$dir/src/a.ts"
gates scoped --no-format src/a.ts
if test "$(cat "$dir/src/a.ts")" = 'export const a = 1'; then code=0; else code=1; fi
out="src/a.ts: $(cat "$dir/src/a.ts")"
expect "scoped --no-format leaves files as they are" 0 "src/a.ts"

# Commit hook
new_repo
echo '// @ts-ignore' >"$dir/src/bad.ts"
git_ add src/bad.ts
hook 'git commit -m x'
expect "hook blocks a commit whose staged lines fail a gate" 2 "lint ❌ (FORBIDDEN)"

hook 'git status'
expect "hook ignores a command that does not commit" 0 ""

hook 'npm test && git -C . commit -m x'
expect "hook catches git -C <dir> commit after another command" 2 "Blocked"

hook 'npm test \u0026\u0026 git commit -m x'
expect "hook catches a commit after a JSON-escaped &&" 2 "Blocked"

hook 'sh -c \"git commit -m x\"'
expect "hook catches a commit wrapped in sh -c" 2 "Blocked"

hook "bash -c 'git commit -m x'"
expect "hook catches a commit in single quotes" 2 "Blocked"

hook 'GIT_AUTHOR_NAME=a git commit -m x'
expect "hook catches a commit after an env var" 2 "Blocked"

hook 'xargs git commit -m x'
expect "hook catches a commit run by xargs" 2 "Blocked"

new_repo
echo '// @ts-ignore' >"$dir/src/later.ts"
hook 'git add src/later.ts && git commit -m x'
expect "hook checks files added in the same command as the commit" 2 "lint ❌ (FORBIDDEN)"

git_ add src/later.ts
git_ commit -qm "chore: seed"
echo 'export const x = 1' >>"$dir/src/later.ts"
echo '// @ts-ignore' >"$dir/src/other.ts"
hook 'git commit -m x'
expect "hook ignores unstaged files when the command does not add them" 0 ""

new_repo
echo 'export const ok = 1' >"$dir/src/ok.ts"
git_ add src/ok.ts
hook 'git commit -m x'
expect "hook allows a commit whose gates pass" 0 ""

commit "feat: ok"
conf LINT_SCOPED "'false'"
git_ add .claude/gates.conf
hook 'git commit -m x'
expect "hook skips gates when only .claude/ files are committed" 0 ""

git_ reset -q
conf LINT_SCOPED '"true"'
echo '// @ts-ignore' >>"$dir/src/ok.ts"
hook 'git commit -am x'
expect "hook checks unstaged tracked files on commit -a" 2 "lint ❌ (FORBIDDEN)"

# Stop hook
new_repo
stop_hook
expect "stop hook allows a clean tree" 0 ""

echo 'export const a = 1' >"$dir/src/a.ts"
stop_hook
expect "stop hook blocks code no gates checked" 2 "src/a.ts"

stop_hook true
expect "stop hook allows a stop it already sent back" 0 ""

conf LINT_SCOPED "'false'"
gates scoped src/a.ts
stop_hook
expect "stop hook allows code whose gates ran and failed" 0 ""

echo 'export const b = 2' >>"$dir/src/a.ts"
stop_hook
expect "stop hook blocks code changed after its gates ran" 2 "src/a.ts"

conf LINT_SCOPED '"true"'
echo '# notes' >"$dir/notes.md"
mkdir -p "$dir/.claude/skills"
echo 'x' >"$dir/.claude/skills/x.sh"
gates full
stop_hook
expect "full records every changed code file · .md and .claude/ never pending" 0 ""

new_repo
two_scenario_spec
echo 'ORD-01 sums two items|false' >"$dir/tests/ord.test.txt"
gates fr ORD-01
stop_hook
expect "fr records the test files it ran: a paused RED is not pending" 0 ""

echo 'export const total = 0' >"$dir/src/total.ts"
gates fr ORD-01
stop_hook
expect "fr records only test files" 2 "src/total.ts"

new_repo
two_scenario_spec
cnt=$(mktemp -u); dirs="$dirs $cnt"
conf LINT_SCOPED "'echo run >>$cnt'"
echo 'ORD-01 sums two items|true' >"$dir/tests/ord.test.txt"
git_ add tests/ord.test.txt
gates fr ORD-01
hook 'git commit -m x'
out="$out runs=$(grep -c . "$cnt" 2>/dev/null)"
expect "an fr record never lets the commit hook skip its gates" 0 "runs=1"

new_repo
echo 'export const ok = 1' >"$dir/src/ok.ts"
git_ add src/ok.ts
hook 'git commit -m x'
stop_hook
expect "the commit hook's gates run counts" 0 ""

new_repo
conf APP_DIR '"app"'
mkdir -p "$dir/app"
echo 'export const a = 1' >"$dir/app/a.ts"
echo 'x' >"$dir/root.ts"
stop_hook
expect "stop hook blocks code inside APP_DIR" 2 "app/a.ts"
[[ $out != *root.ts* ]] || { code=1; out="root.ts listed: $out"; }
expect "stop hook lists only files inside APP_DIR" 2 "app/a.ts"

gates scoped app/a.ts
stop_hook
expect "scoped records a path inside APP_DIR" 0 ""

new_repo
conf APP_DIR '"[e.g. app]"'
echo 'export const a = 1' >"$dir/src/a.ts"
stop_hook
expect "stop hook allows when gates.conf is not configured" 0 ""

# Commit hook reuses a pass
runs() { if test -f "$cnt"; then grep -c . "$cnt"; else echo 0; fi; }
counting_repo() {
  new_repo
  cnt=$(mktemp -u)
  dirs="$dirs $cnt"
  conf LINT_SCOPED "'echo run >>$cnt'"
  echo 'export const a = 1' >"$dir/src/a.ts"
  git_ add src/a.ts
}

counting_repo
gates scoped src/a.ts
hook 'git commit -m x'
out="$out runs=$(runs)"
expect "hook skips gates the same content already passed" 0 "runs=1"

counting_repo
conf LINT_SCOPED "'echo run >>$cnt; false'"
gates scoped src/a.ts
hook 'git commit -m x'
expect "hook runs gates after a failed run" 2 "Blocked"

counting_repo
gates scoped src/a.ts
echo 'export const b = 2' >>"$dir/src/a.ts"
hook 'git commit -am x'
out="$out runs=$(runs)"
expect "hook runs gates on content changed after the pass" 0 "runs=2"

counting_repo
echo 'export const b = 2' >>"$dir/src/a.ts"
gates scoped src/a.ts
hook 'git commit -m x'
out="$out runs=$(runs)"
expect "hook runs gates when the staged content is not what passed" 0 "runs=2"

hook 'git commit -am x'
out="$out runs=$(runs)"
expect "hook skips gates on commit -a of the content that passed" 0 "runs=2"

counting_repo
gates scoped src/a.ts
conf BUILD '"true"'
hook 'git commit -m x'
out="$out runs=$(runs)"
expect "hook runs gates when gates.conf changed after the pass" 0 "runs=2"

counting_repo
gates scoped src/a.ts
echo 'export const c = 3' >"$dir/src/c.ts"
hook 'git commit -m x'
out="$out runs=$(runs)"
expect "hook runs gates while other code is unchecked" 0 "runs=2"

counting_repo
conf LINT_SCOPED "'false'"
gates scoped src/a.ts
stop_hook
expect "pending counts a failed run as checked" 0 ""

# Audit
new_repo
conf AUDIT '"echo audited"'
echo 'export const a = 1' >"$dir/src/a.ts"
gates scoped src/a.ts
expect "audit skips when no manifest changed" 0 "audit ⏭️"

echo '{}' >"$dir/package.json"
gates scoped src/a.ts
expect "audit runs on an untracked manifest" 0 "audit ✅"

commit "chore: manifest"
echo '{ "a": 1 }' >"$dir/package.json"
conf AUDIT '"false"'
gates scoped src/a.ts
expect "audit fails on a modified manifest" 1 "audit ❌"

git_ add package.json
gates full
expect "audit runs in full on a staged manifest" 1 "audit ❌"

# C# test projects
new_repo
two_scenario_spec
mkdir -p "$dir/Order.Tests" "$dir/Order"
echo 'public class OrderService { }' >"$dir/Order/OrderService.cs"
echo 'public class OrderTests { [Fact] public void ORD_01_sums() { } [Fact] public void ORD_01_empty() { } }' >"$dir/Order.Tests/OrderTests.cs"
conf TEST_FR "'printf \"ok ORD_01_sums\nok ORD_01_empty\n\"'"
gates fr ORD-01
expect "fr finds a test in a C# *.Tests project" 0 "FR ORD-01: ✅ (2 tests)"

echo 'getByTestId("x")' >>"$dir/Order.Tests/OrderTests.cs"
gates scoped Order.Tests/OrderTests.cs
expect "TEST_FORBIDDEN checks a C# test file" 1 "lint ❌ (TEST_FORBIDDEN)"

echo 'getByTestId("x")' >>"$dir/Order/OrderService.cs"
gates scoped Order/OrderService.cs
expect "a C# source file is not a test" 0 "lint ✅"

mkdir -p "$dir/Order.UnitTests"
echo 'ORD-01' >"$dir/Order.UnitTests/Extra.cs"
if [[ Order.UnitTests/Extra.cs =~ $(sed -n "s/^test_path='\(.*\)'$/\1/p" "$dir/.claude/scripts/gates.sh") ]]; then code=0; else code=1; fi
out="Order.UnitTests/Extra.cs"
expect "a *.UnitTests project folder holds tests" 0 "Order.UnitTests"

# TEST_PATH
new_repo
two_scenario_spec
mkdir -p "$dir/Tests/AppTests"
echo 'func test_ORD_01_sums() {} func test_ORD_01_empty() {}' >"$dir/Tests/AppTests/OrderSpecs.swift"
conf TEST_FR "'printf \"ok ORD_01_sums\nok ORD_01_empty\n\"'"
gates fr ORD-01
expect "a test outside the built-in paths is not found" 3 "no test named ORD-01"

conf TEST_PATH "'(^|/)Tests/'"
gates fr ORD-01
expect "TEST_PATH sets the project's test paths" 0 "FR ORD-01: ✅ (2 tests)"

echo 'getByTestId("x")' >"$dir/Tests/AppTests/OrderSpecs.swift"
gates scoped Tests/AppTests/OrderSpecs.swift
expect "TEST_FORBIDDEN follows TEST_PATH" 1 "lint ❌ (TEST_FORBIDDEN)"

echo 'getByTestId("x")' >"$dir/tests/page.test.ts"
gates scoped tests/page.test.ts
expect "TEST_PATH replaces the built-in paths" 0 "lint ✅"

# test-paths
new_repo
echo 'x' >"$dir/src/cart.test.ts"
printf '%s\n' 'x' >"$dir/vitest.config.ts"
printf '%s\n' 'x' >"$dir/src/latest.ts"
gates test-paths
expect "test-paths passes built-in tests and ignores vitest, latest" 0 "Test paths: ✅"
[[ $out == *src/cart.test.ts* ]] || code=9
expect "test-paths lists the test files it found" 0 "src/cart.test.ts"

mkdir -p "$dir/Tests/AppTests" "$dir/.github/workflows"
echo 'x' >"$dir/Tests/AppTests/OrderServiceTests.swift"
echo 'x' >"$dir/.github/workflows/test.yml"
gates test-paths
expect "test-paths fails on a test-like file the regex misses" 1 "Tests/AppTests/OrderServiceTests.swift"
[[ $out != *test.yml* ]] || code=9
expect "test-paths skips hidden folders" 1 "❌ 1 missed"

conf TEST_PATH "'(^|/)Tests/|\.test\.ts\$'"
gates test-paths
expect "test-paths catches what a narrow TEST_PATH drops" 1 "tests/run.sh"

conf TEST_PATH "'(^|/)[Tt]ests/|\.test\.ts\$'"
gates test-paths
expect "test-paths passes once TEST_PATH matches" 0 "Test paths: ✅ 3 test files"

new_repo
mkdir -p "$dir/Order" "$dir/Order.Tests"
echo 'x' >"$dir/Order/LoadTest.cs"
echo 'x' >"$dir/Order.Tests/OrderTests.cs"
conf TEST_PATH "'(^|/)Order\.Tests/|(^|/)tests/'"
gates test-paths
expect "test-paths reports a source file named like a test" 1 "Order/LoadTest.cs"

conf TEST_PATH_EXCLUDE "'(^|/)LoadTest\.cs\$'"
gates test-paths
expect "TEST_PATH_EXCLUDE silences it" 0 "Test paths: ✅"

conf TEST_PATH '""'
gates test-paths
[[ $out != *LoadTest* ]] || code=9
expect "TEST_PATH_EXCLUDE drops a built-in match" 0 "Order.Tests/OrderTests.cs"

echo 'getByTestId("x")' >"$dir/Order/LoadTest.cs"
gates scoped Order/LoadTest.cs
expect "an excluded file skips TEST_FORBIDDEN" 0 "lint ✅"

# has_test follows .gitignore
new_repo
two_scenario_spec
conf TEST_FR "'printf \"ok ORD_01_sums\nok ORD_01_empty\n\"'"
mkdir -p "$dir/vendor/lib/tests"
echo 'ORD_01' >"$dir/vendor/lib/tests/x_test.go"
echo 'vendor/' >"$dir/.gitignore"
gates fr ORD-01
expect "has_test ignores a test in a gitignored folder" 3 "no test named ORD-01"

echo 'ORD_01 sums · ORD_01 empty' >"$dir/tests/ord_test.go"
gates fr ORD-01
expect "has_test finds an untracked test" 0 "FR ORD-01: ✅ (2 tests)"

# TEST_FORBIDDEN
new_repo
echo 'getByTestId("x")' >"$dir/src/page.ts"
gates scoped src/page.ts
expect "TEST_FORBIDDEN skips source files" 0 "lint ✅"

echo 'getByTestId("x")' >"$dir/tests/page.test.ts"
gates scoped tests/page.test.ts
expect "TEST_FORBIDDEN fails an added test line" 1 "lint ❌ (TEST_FORBIDDEN)"

# fr
new_repo
two_scenario_spec
gates fr ORD-01
expect "fr without a named test exits 3" 3 "no test named ORD-01"

new_repo
two_scenario_spec
mkdir -p "$dir/specs/changes/order"
echo '# Tasks' >"$dir/specs/changes/order/tasks.md"
echo 'ORD-01 sums two items|false' >"$dir/tests/ord.test.txt"
gates fr ORD-01
expect "fr fails a failing test" 1 "FR ORD-01: ❌"
if grep -qxF -- '- RED: ORD-01' "$dir/specs/changes/order/tasks.md"; then code=0; else code=1; fi
out="tasks.md: $(cat "$dir/specs/changes/order/tasks.md")"
expect "fr records RED in the active tasks.md" 0 "- RED: ORD-01"

new_repo
two_scenario_spec
mkdir -p "$dir/specs/changes/order"
echo '# Tasks' >"$dir/specs/changes/order/tasks.md"
echo 'export const total = 0' >"$dir/src/total.ts"
echo 'ORD-01 sums two items|false' >"$dir/tests/ord.test.txt"
gates fr ORD-01
expect "fr skips RED when code is unstaged besides tests" 1 "RED not recorded"
if grep -qF -- '- RED:' "$dir/specs/changes/order/tasks.md"; then code=1; else code=0; fi
out="tasks.md: $(cat "$dir/specs/changes/order/tasks.md")"
expect "fr leaves tasks.md without RED" 0 "tasks.md"

git_ add src/total.ts
echo '{}' >"$dir/package.json"
gates fr ORD-01
if grep -qxF -- '- RED: ORD-01' "$dir/specs/changes/order/tasks.md"; then code=0; else code=1; fi
out="tasks.md: $(cat "$dir/specs/changes/order/tasks.md")"
expect "fr records RED with earlier code staged and a manifest unstaged" 0 "- RED: ORD-01"

new_repo
two_scenario_spec
echo 'ORD-01 sums two items|true' >"$dir/tests/ord.test.txt"
gates fr ORD-01
expect "fr fails with fewer tests than scenarios" 1 "1 tests < 2 scenarios"

echo 'ORD-01 sums items|printf "ok ORD-%s case 2\n" 01' >"$dir/tests/ord.test.txt"
gates fr ORD-01
expect "fr counts each case a parametrized test prints" 0 "FR ORD-01: ✅ (2 tests)"

printf '%s\n' 'ORD-01 sums two items|true' 'ORD-01 returns 0 when empty|true' >"$dir/tests/ord.test.txt"
gates fr ORD-01
expect "fr passes one test per scenario" 0 "FR ORD-01: ✅ (2 tests)"

echo
echo "$passed passed · $failed failed"
test "$failed" = 0
