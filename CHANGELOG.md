# Changelog

## v1.32.0 — 2026-10-28
### Added
- `.claude/hooks/gate-stop.sh`: a `Stop` hook, and a `SubagentStop` hook for `implementer` — ending a turn with code changed since the last gates run is blocked once, listing the files to run `gates.sh scoped` on · it asks for the evidence, not a pass: a ❌ is quoted and the agent stops, as before · `stop_hook_active` lets the next stop through, so it never loops · `.claude/` and `.md` skipped · gates.conf not configured: never blocks.
- `gates.sh pending`: prints the changed code files whose content no `scoped` or `full` run checked — `scoped` and `full` now record each file they check as `<hash> <ok:<gates.conf hash>|fail> <path>` in `.git/sdd-gates` (untracked, inside `.git`) · the commit hook's run counts.
- `gates.sh passed [--staged] <files…>`: exit 0 when every changed code file passed with its current content and the current `gates.conf` — `--staged`: each given file is also staged as checked.
- The commit hook skips its gates run when `gates.sh passed` holds — the task's `scoped` run already checked that content, so each task runs the gates once instead of twice (a 2 s test suite: 4.1 s → 2.1 s per task) · a failed run, content changed after the pass, partial staging, a changed `gates.conf` or other unchecked code: it runs them as before.
- `gates.sh fr` records the changed test files no run checked yet as `fr` — a RED paused for a question is not pending, so the stop hook does not force a `scoped` run that can only fail · an `fr` record never counts as passed.
- C# tests: `gates.sh` and `.claude/rules/testing.md` treat `*.Tests/` · `*.UnitTests/` (any `<name>.<…>Tests/` project folder) and `*Tests.cs` · `*Test.cs` as test files — `fr`, `frs`, RED, `TEST_FORBIDDEN` and `{tests}` work for xUnit, NUnit and MSTest projects · the FR search skips `bin/` and `obj/`.
- `gates.conf` → `TEST_PATH`: extended regex for this project's test files — it replaces the built-in paths, so each project sets its own (e.g. Swift `'(^|/)Tests/'`, a .NET solution `'(^|/)Order\.Tests/'`) · empty or missing: the built-in paths · `/adopt` fills it from the repo's test files and checks that `git ls-files | grep -E` lists every test file and no source file.
- `gates.sh test-paths`: classifies the repo's files with the test path regex — `Test paths: ✅ <N> test files` and the first five, or `❌ <M> missed` with the test-like names it does not match (a `test`/`spec` word between separators or a CamelCase `Test`/`Spec` suffix — not `pytest`, `vitest`, `latest`; hidden folders skipped).
- `gates.conf` → `TEST_PATH_EXCLUDE`: extended regex for source files that look like tests and are not (e.g. `LoadTest.cs`) — never treated as tests, never reported by `test-paths` · empty: none.
- `/adopt` step 7 runs `gates.sh test-paths` until it prints ✅ and lists only test files — a missed test → `TEST_PATH`, a source file → `TEST_PATH_EXCLUDE` — its Output Contract adds `Tests: <that line> — TEST_PATH: <value, or built-in>`.
- `.claude/rules/testing.md` also loads for `Tests/`, `*.*Tests/`, `*Tests.*` and `*Test.*` files.
- `tests/gates.test.sh`: 45 cases for C# test paths, `TEST_PATH`, `TEST_PATH_EXCLUDE`, `test-paths`, `.gitignore` in the FR search, the stop hook, `pending`, `fr` records, the commit hook's reuse and audit.
- CI runs `tests/gates.test.sh` on Windows too, in Git Bash — the shell the README names · a root `.gitattributes` keeps `*.sh` with LF endings, so the test script runs there.

### Fixed
- `audit` never ran outside CI: changed paths came from `git status --porcelain`, whose `?? ` / ` M ` prefix kept every manifest from matching — now read from `git diff --name-only` (unstaged and staged) and untracked files · `scoped`, `full` and the commit hook run `AUDIT` when a manifest changed, as documented.

### Changed
- `CLAUDE.md` → Quality Gates names the stop hook.
- `fr` and `frs` find an FR's test with `git grep` over tracked and untracked files — each project's `.gitignore` decides what is skipped (`vendor/`, `.build/`, `build/`, `Pods/`…) instead of a fixed list of six folders.

### Migration from v1.31
- `--update` never touches your `.claude/gates.conf`: `TEST_PATH` missing works as empty (the built-in paths) — set it when your test files sit outside them, or to drop a source file they match.
- `--update` never touches your `.claude/settings.json`: add next to `hooks.PreToolUse`:
  `"Stop": [{ "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/gate-stop.sh\"" }] }],`
  `"SubagentStop": [{ "matcher": "^implementer$", "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/gate-stop.sh\"" }] }]`

## v1.31.2 — 2026-10-24
### Changed
- README names RPI (Research → Plan → Implement) as a methodology: badge `RPI · SDD · BDD · TDD` · Why → It guesses what to build · Methodologies → RPI row, first.

## v1.31.1 — 2026-10-24
### Changed
- README → Use it: the flow diagrams show who runs each step — a box per actor inside each phase: plain = main session · dashed = a subagent in its own context — `Explore` (Haiku) in Research when the code spans 2+ modules · `implementer` (Sonnet) around RED → GREEN → checks → stage · `reviewer` (Opus) around the review · Other sizes: main session.
- Plan diagram adds what was missing: ONE question when the goal is unclear · scope IN / OUT · requirements only for what the request names · the simplest design · the `⚠️ Request not covered` / `⚠️ Not in the Request` flags before `approve?`.
- Build and close diagram adds: the main session relays the implementer's result · `/clear → go` before the next task · the commit hook named · review gaps go to you — fix (back to GREEN) or accept (on to the specs merge).
- Build and close and Other sizes read left to right: each phase or size is a column, side by side.
- README → Methodologies 984 → 595 words, 20 → 18 rows: Refactoring and Measured optimization in one row · Measure folded into Context engineering · details the flow, Say table and Files already give are cut · the stale `CLAUDE.md` word count dropped.

## v1.31.0 — 2026-10-24
### Changed
- Any architecture, Vertical Slice suggested: the framework counts **modules** — the unit `.claude/project.md` → Layer Structure defines (a slice, a layer, a package) — instead of slices · `CLAUDE.md` → Change Size: touches one module, creates no module · `create-feature`, `explore`, `adopt` and `templates/change/design.md` → Modules.
- `.claude/project.md` → Layer Structure: Vertical Slice stays as the suggested structure — a comment says to replace it with yours and keep its `Module:` line.
- `.claude/rules/architecture.md`: `.claude/project.md` → Layer Structure wins where it differs from a rule · public API between modules.
- `docs/architecture.md`: §2 Modules · §5 Decisions → the structure row is a placeholder — the suggested Vertical Slice, or yours.
- README: Size, flow diagrams, Files and Methodologies say module · Methodologies → Your architecture (Vertical Slice suggested).

### Migration from v1.30
- `--update` overwrites the framework files · `.claude/project.md` and `docs/architecture.md` are yours: add `- Module: <your unit>` under Layer Structure, and rename §2 Slices to Modules if you want.

## v1.30.2 — 2026-10-24
### Fixed
- Scope crept unless the request said "keep it simple": since v1.30.0 KISS · YAGNI lived only in `.claude/rules/code.md`, loaded for source files — FRs, Scope IN and Approach are written before any source file is read, and the always-loaded Spec Rules only pushed to widen.
- `CLAUDE.md` → Hard Rules → Scope: build only what the request names · simple, never fragile: every input the requested behavior takes gets one error path, existing behavior and data keep working — not extra · the simplest solution in FRs, Approach and code · Spec Rules: FRs cover what the request makes visible and nothing it does not · a broad request never adds an input it does not name.
- `create-feature`: NEVER narrow or widen the Request — the rest goes in Scope OUT · Approach is the simplest design, every file, type and layer maps to an FR · step 6 flags `⚠️ Not in the Request: <FR-ID | Scope IN item>` — only for an error path or existing behavior kept working, anything else goes in Scope OUT.
- `reviewer`: reports an FR, Scope IN item, file or abstraction the Request does not ask for — checked against the Request, not Scope IN — and an input of the requested behavior with no error path.
- `templates/change/design.md` → Approach: Files, Types, State and Decision accept `none`.
- README: Why and Methodologies → Clean code.

## v1.30.1 — 2026-10-22
### Changed
- README → Use it: the three flow diagrams show every side path, and each size route names its criterion and the words that force it (`as a feature` · `inline`) · connectors A and B show where each diagram continues: the plan → Build and close, a small change → Other sizes. Full cycle · plan: research corrected, plan changed. Full cycle · build and close: a task that fails its checks, fails 3 fixes, grows in scope, deviates or needs your decision; the commit hook blocking a commit; Verify failing; review gaps. Other sizes: refactor without covering tests (add them first as an inline change), the optimize metric, a failing step reverted, inline that grows into a full cycle — and it reads top to bottom.

## v1.30.0 — 2026-10-22
### Changed
- `CLAUDE.md` 1643 → 1198 words: Architecture, Code and Testing Rules move to `.claude/rules/architecture.md`, `code.md` and `testing.md`, each with a `paths:` frontmatter for source or test files — sessions that plan, research or edit docs no longer carry them · one line in Hard Rules says where they live · "Do not use the patterns in Forbidden" dropped: the `FORBIDDEN` gate and `.claude/project.md` → Forbidden cover it.
- `implementer` follows the `.claude/rules/*.md` whose `paths:` match the files it reads or writes · `reviewer` reads each matching rules file and names it in a gap · `/adopt` and `gates.conf` point `TEST_FORBIDDEN` at `.claude/rules/testing.md`.
- `sdd-core`: `.claude/rules/` — `--update` overwrites the framework's rule files and keeps yours.
- README: Files, Methodologies and Context engineering name the rule files.

Tested live with `claude -p`, a canary line in each rule file: inline (main session) and full cycle (implementer subagent) both wrote it into new source and test files; the main session, the implementer and the reviewer each read the rule files before writing or reviewing.

### Migration from v1.29
- `--update` adds the three rule files and the shorter `CLAUDE.md` — a rule you added to `CLAUDE.md` → Hard Rules or Testing Rules moves to your own file in `.claude/rules/`.

## v1.29.1 — 2026-10-22
### Fixed
- `create-feature` step 7 named the branch format at `CLAUDE.md` → Working Protocol → Branch name, an anchor gone since v1.26 — it now points at `.claude/project.md` → Branch name.

### Changed
- `explore` agent: `tools: Read, Grep, Glob` — read-only by its tools, not only by its prompt (it used no Bash in 6 live runs) · dropped "NEVER paste file contents", which its Output Contract already covers (no pasted code in live runs without it).

## v1.29.0 — 2026-10-22
Aligned with Anthropic's [Claude Code best practices](https://code.claude.com/docs/en/best-practices): commit after verified work, hooks for rules with zero exceptions, a short `CLAUDE.md`, specs that end with an end-to-end check.

### Added
- Commit per task: the human's `go` commits the staged task — inline changes commit on the current branch — inside a batch each task commits when it passes · the description starts with the task ID · `git push` stays denied — the PR squash-merges the branch into one commit · a failing later task reverts to the last task's commit.
- `tasks.md` → Progress → `Base:` — the commit the branch started from, written when create-feature creates the branch · the reviewer reads `git diff <Base>...HEAD` · the implementer reads a task's commit for `fix: <task-ID> <what>`.
- `.claude/hooks/gate-commit.sh`: a `PreToolUse` hook — a `git commit` runs `gates.sh scoped --no-format` on the files it commits (staged, plus tracked changes with `-a`; `.claude/` and `.md` skipped) and is blocked on ❌ · it finds the commit wrapped in `sh -c`, quotes or `$( )`, after env vars or `xargs`, with `-C` / `-c` — a false match only runs the gates · the PR's `gates.sh full` stays the backstop.
- `gates.sh scoped --no-format`: checks files as staged — the hook uses it.
- `proposal.md` → `## Verify`: one end-to-end check — a command, a request or steps in the running app — confirmed in create-feature step 2, run after full gates at the close (a command: quoted output · human steps: `verified?`) · the reviewer reports it empty.
- `.claude/rules/ui.md`: the UI rule, loaded only for `*.tsx · *.jsx · *.vue · *.svelte · *.astro · *.html`.
- `refactor`: commits each passing step.
- README → Setup: allow only squash merging in GitHub.

### Changed
- `CLAUDE.md` 1689 → 1643 words: Working Protocol commits per task · removed "search before reading" and "do not read other slices' internals" (default behavior, Explore and the public-API rule cover them), the status legend and "report the line as printed" (Output Contracts require it) · the UI rule moved to `.claude/rules/ui.md` · Quality Gates names the commit hook.
- create-feature step 11: commits the close (`chore: close <feature>`) and replies with the PR title and body — the human pushes.
- `/adopt` commits its files on `go`.
- README: the flow as three diagrams in plain words — Full cycle · plan (request → size → 1 Research, RPI → 2 Plan, SDD + BDD) · Full cycle · build and close (3 Implement, TDD, with the batch note and the fix / next-task loops → 4 Close, SDD living spec, with the gaps loop) · Other sizes (inline, refactor, docs) — one step per box, your decisions as orange capsules, loops dashed, a legend for colors and terms, and a table that says what RPI, SDD, BDD and TDD mean here · Files, Methodologies.

### Migration from v1.28
- `--update` never touches your `.claude/settings.json`: remove `"Bash(git commit *)"` from `deny` and add the hook next to `protect-secrets.sh` in `hooks.PreToolUse`:
  `{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/gate-commit.sh\"" }`
- An active change folder: add `- Base: <commit the branch started from>` to its `tasks.md` → Progress and a `## Verify` to its `proposal.md`.
- GitHub: allow only squash merging.

## v1.28.0 — 2026-10-22
### Added
- `gates.conf` → `FORBIDDEN_EXCLUDE`: extended regex for paths `FORBIDDEN` skips — scaffold and tool config that need a forbidden form (e.g. `export default` in `vite.config.ts`) · `/adopt` fills it.
- `tests/gates.test.sh`: 23 regression tests for `gates.sh`, each in a throwaway git repo — run `bash tests/gates.test.sh` · `.github/workflows/test.yml` runs them on Linux and on macOS with the system bash 3.2, for every PR and push to main.
- `fix: <task-ID> <what>`: after a batch the staged diff spans several tasks — the fix names its task · `CLAUDE.md`, create-feature, implementer, README.

### Changed
- README → Use it: the flow becomes two horizontal diagrams — full cycle (Research, approvals, one task's RED → GREEN → gates → stage, review, fix, reviewer, merge) and the other sizes (inline, refactor · optimize, docs).

### Fixed
- `gates.sh full` with a base (`$GATES_BASE`, or the PR base in CI) that does not resolve fails with `Gates: ❌ base <ref> not found` — before, `FORBIDDEN` / `TEST_FORBIDDEN` scanned every line of the repo as added and `commits` passed as `✅ (0)` without checking a subject.
- `gates.sh fr` records `- RED` only while every unstaged or untracked code file is a test or a `MANIFESTS` file — a failure after the code was written proved nothing · otherwise it prints `RED not recorded` and the implementer returns blocked.
- `gates.sh fr` on macOS: `wc -l` pads its count with spaces — RED was never recorded, and a run whose output named no test skipped the `no test named` check.
- `gates.sh scoped` ran `FORBIDDEN` on `.claude/` files — now skipped, as in full.
- Paths with spaces: `{files}`, `{tests}` and `{dirs}` are shell-quoted, and `FORBIDDEN` reads each path whole.
- `gates.conf` → `FORBIDDEN` example: `: any([^[:alnum:]_]|$)` instead of `\b`, which BSD grep on macOS lacks.

### Migration from v1.27.1
- CI with `GITHUB_BASE_REF`: `actions/checkout` MUST fetch the base — `fetch-depth: 0` — or `gates.sh full` now fails. README → CI says so.
- `--update` never touches your `gates.conf`: add a `FORBIDDEN_EXCLUDE='…'` line (single quotes, empty = off) when `FORBIDDEN` blocks a scaffold file · replace `\b` in your `FORBIDDEN` with `([^[:alnum:]_]|$)` on macOS.

## v1.27.1 — 2026-10-21
### Changed
- `CLAUDE.md` → Working Protocol: the task close sequence rule is a plain imperative.
- `create-feature` → Hard Rules: drop "explore existing code before proposing" — step 1 already requires it.

## v1.27.0 — 2026-10-21
### Added
- `gates.conf` → `TEST_FORBIDDEN`: extended regex — an added line in a test file that matches fails the lint gate (`lint ❌ (TEST_FORBIDDEN)`), in scoped and full, inline changes too — e.g. queries by test id, CSS class or index.
- `/adopt` fills `TEST_FORBIDDEN` from the test runner and the Testing Rules.

### Changed
- `gates.conf` → LINT comment: the linter MUST also use the stack's test plugin when one exists.
- README → Testing practices names what enforces it.

### Migration from v1.26
- `--update` never touches your `gates.conf`: add a `TEST_FORBIDDEN='…'` line (single quotes, empty = off) — see the template's example.

## v1.26.0 — 2026-10-21
### Added
- `.claude/settings.json` → `"sandbox": {"enabled": true}`: shell commands run in Claude Code's sandbox — every `Read` deny becomes an OS-level read block, so a script that opens a denied file by itself fails too. Linux and WSL2 need `bubblewrap` and `socat`; without them Claude Code runs commands unsandboxed and `/sandbox` lists what is missing. A command's first new network host asks for approval.

### Changed
- `CLAUDE.md` 1756 → 1688 words, same rules: approval and silence in one line · commit and branch in one line · close sequence step 4 removed (create-feature step 8 owns it) · dependency check shortened · one example less in "Do not reimplement" · Quality Gates intro merged with the "only through the script" rule.
- README → Security and the `protect-secrets` hook name the sandbox as on · Context engineering states the new size.

### Migration from v1.25
- `--update` never touches your `.claude/settings.json`: add `"sandbox": { "enabled": true }` at its top level · Linux/WSL2: `sudo apt-get install bubblewrap socat` (or your distro's equivalent).

## v1.25.0 — 2026-10-21
### Added
- `gates.sh fr`: a failing run appends `- RED: <FR-ID>` to the active change's `tasks.md` — the script writes the evidence, not the agent · once per FR · only when one change is active · inline changes have no change folder: no record.
- `reviewer`: with TDD ON, an ADDED or MODIFIED FR with no `- RED:` line is a gap · reads `tasks.md` → Progress.

### Changed
- README → TDD names the record.

### Migration from v1.24
- None — run `--update`. Open changes started before v1.25 have no `RED:` lines: accept the reviewer's gaps with "go", or rerun `gates.sh fr` on a reverted test.

## v1.24.0 — 2026-10-21
### Added
- `gates.conf` → `COMMIT_PATTERN`: extended regex for commit subjects. `gates.sh full` with a base (`$GATES_BASE`, or the PR base in CI) checks every subject since the base — `commits ❌` lists the ones that do not match · Merge and Revert commits skipped · empty or no base: no check.
- `/adopt` fills `COMMIT_PATTERN` from `.claude/project.md` → Commit message.

### Changed
- `CLAUDE.md` → Quality Gates and README → Gates, Conventional Commits: name the check.

### Migration from v1.23
- `--update` never touches your `gates.conf`: add a `COMMIT_PATTERN='…'` line (single quotes, empty = off) — see the template's example.

## v1.23.0 — 2026-10-21
### Changed
- `CLAUDE.md` (from `/doctor prompt-audit`): uppercase `NEVER` / `ALWAYS` / `MUST` 41 → 13 — kept only where a violation is costly or hard to undo (approval, close sequence, FR IDs, dependencies, credentials, tests, failing gates), with the reason when it is not obvious · the rest is plain imperative, same meaning.
- `CLAUDE.md` → Working Protocol: "STRICT — any violation is a protocol breach" becomes the reason the rules hold.
- `CLAUDE.md` → Change Size: a change to `.md` files only skips the table and is classified `Size: docs`.
- `.claude/doc-rules.md`: the uppercase convention above — FRs keep RFC 2119 `MUST`.
- README → English, imperative prompts: names the convention.

### Fixed
- `CLAUDE.md` → Quality Gates: a docs-only change prints `⏭️` for every gate in `gates.sh scoped` — `full` still runs them.

### Migration from v1.22
- None — run `--update`. Rules in your `.claude/project.md` → Project Rules may follow the new uppercase convention.

## v1.22.0 — 2026-10-21
### Changed
- `gates.sh fr`: fails with `FR <ID>: ❌ <n> tests < <s> scenarios` when the FR has fewer tests than GIVEN lines — read from the active change's delta spec, else from `specs/current/` — so `test: ✅` can no longer hide an untested scenario.
- README → BDD and the Gates table name the check.

### Migration from v1.21
- None — run `--update`. An FR already marked `test: ✅` with fewer tests than scenarios now fails `gates.sh fr`.

## v1.21.0 — 2026-10-21
### Added
- `.claude/skills/refactor/` — the No Behavior Change rules (refactor · optimize), loaded on demand instead of in every session.

### Changed
- `CLAUDE.md` 1925 → 1700 words: No Behavior Change moves to the `refactor` skill · removed the full-cycle lines `create-feature` already owns (implementer-only tasks, change folder lifecycle) and the duplicate FR row in Quality Gates.
- README → Context engineering: states the real `CLAUDE.md` size instead of "short" · skills tree lists `refactor`.

### Fixed
- `gates.sh`: a `gates.conf` with `[placeholders]` prints `Gates: ❌ .claude/gates.conf not configured — run /adopt or fill its [placeholders]` instead of shell errors.

### Migration from v1.20
- None — run `--update`.

## v1.20.0 — 2026-10-21
### Added
- `gates.conf` → `FORBIDDEN`: an extended regex — an added line that matches fails the lint gate, in scoped and full, so inline changes get it too. Only added lines count: existing code never breaks.
- `/adopt` fills `FORBIDDEN` from `.claude/project.md` → Forbidden plus the stack's ignore comments.

### Changed
- `gates.conf` → LINT comment: the linter MUST also block unused exports.
- README → Clean code: names what enforces it · Multi-agent: the reviewer checks FRs, Hard Rules and Testing Rules.

### Migration from v1.19
- `--update` never touches your `gates.conf`: add a `FORBIDDEN="…"` line (empty = off) — see the template's example.

## v1.19.0 — 2026-10-21
### Added
- `go all` — approves every remaining task as one batch (= `go up to <last task>`).
- `implementer` Output Contract: `Deviation: <what>` line when the task changed the plan.

### Changed
- Batch runs back to back: `create-feature` dispatches the next task in the same turn — no message from the human between tasks — and prints `Next` only when the batch ends.
- Batch also stops on a `Deviation:` line, not only on `blocked` or `maxTurns`.
- Close sequence step 3: inside a batch, no wait — the human reviews `git diff --staged` once when the batch ends.
- README → Say table, Low bureaucracy, Human in the loop, Context engineering: per task or batch.

### Migration from v1.18
- None — run `--update`.

## v1.18.0 — 2026-10-21
### Added
- `.claude/templates/change/design.md` → `## Research`: the code as it is — `path:line` files, current behavior, gaps — no proposals. The human approves it on its own, before the plan exists.

### Changed
- `create-feature` step 1: what the exploration finds becomes `design.md` → Research, instead of being discarded — the agent stops with `research ok?` and writes the plan only after `yes`. A resumed feature with no `tasks.md` yet goes back to that stop.
- `Explore` agent: `Files:` lines carry `path:line`.
- `implementer` step 1: reads `design.md` → Research too.
- README → Full cycle: the Research stop is steps 2–3 — the later steps move down by two · flowchart and `yes` row updated.

### Migration from v1.17
- None — run `--update`. Open change folders keep working without a Research section.

## v1.17.0 — 2026-10-20
### Removed
- `.claude/skills/research/` — `/research` and its README entries. Listed in `sdd-removed`.
- `.claude/skills/master/` — the task note template and its README entry. Listed in `sdd-removed`.

### Migration from v1.16
- None — run `--update`: it deletes both skill folders.

## v1.16.0 — 2026-10-20
### Added
- `.claude/skills/master/` — example task note template: Feynman summary, 5 Ws, How + ADR, risks, GTD next action, quick reply, Zettelkasten links. Every value is a placeholder.
- README → Files: `master/SKILL.md`.

### Migration from v1.15
- None — run `--update`.

## v1.15.0 — 2026-10-19
### Added
- `.claude/skills/research/` — `/research <question>`: inverted Feynman. The human explains in their own words, the agent asks up to 3 newcomer questions per round and points to the sources (`path:line`, section, link) — never the answer first. Ends with a 3-line explanation by the human and the gaps left.
- README → Commands and Files: `/research`.

### Migration from v1.14
- None — run `--update`.

## v1.14.0 — 2026-10-19
### Added
- README → Files: the folder tree the install adds, with the owner and purpose of each file.

### Changed
- `.claude/skills/adopt-project/` → `.claude/skills/adopt/` — the folder matches the skill's `name: adopt`, like `create-feature/`.
- `readme.md` → `README.md`.

### Removed
- `.claude/skills/adopt-project/` — listed in `sdd-removed`.

### Migration from v1.13
- Run `--update`: it copies `.claude/skills/adopt/` and deletes `.claude/skills/adopt-project/`. A rule you added to that skill: move it to `.claude/project.md` → Project Rules.

## v1.13.0 — 2026-10-19
### Added
- Origin marker `Spec Driven Development by stevenhdz · https://github.com/stevenhdz/spec-driven-development` on the framework-file line of `CLAUDE.md`, `.claude/doc-rules.md`, `gates.sh` and `protect-secrets.sh`.
- readme: `by stevenhdz` badge.
- `install.sh` / `install.ps1`: the summary line reads `SDD <ref> by stevenhdz: ✅ …`.

### Migration from v1.12
- None — run `--update`.

## v1.12.0 — 2026-10-18
### Changed
- `.claude/sdd/templates/` → `.claude/templates/` · `.claude/sdd/doc-rules.md` → `.claude/doc-rules.md` — the `sdd/` folder is gone. `CLAUDE.md`, skills, `docs/architecture.md`, readme and `sdd-core` point to the new paths.

### Removed
- `.claude/sdd/` — its files are listed in `sdd-removed`.

### Migration from v1.11
- Run `--update`: it copies the new paths and deletes `.claude/sdd/`. A template you edited there: copy your changes to `.claude/templates/` before updating.

## v1.11.1 — 2026-10-18
### Changed
- `CLAUDE.md` → Quality Gates: the `Gates format` line is gone — `gates.sh` prints it and the agent copies it as printed.
- `CLAUDE.md` → Spec Rules: the change-folder line points to create-feature step 5 instead of restating its files.
- `doc-rules.md`: `## Status legend and Gates format` → `## Status legend`.

### Migration from v1.11
- None — run `--update`.

## v1.11.0 — 2026-10-18
### Changed
- `implementer` → `maxTurns: 60` · `reviewer` → `maxTurns: 30` — `Explore` already had 25, so every agent has a turn cap that stops a run stuck in a loop.
- create-feature: an implementer that returns no Output Contract (stopped at maxTurns) is handled like `blocked` — stop the batch, relay what it returned · a reviewer with no contract: report it, stop and wait.
- readme → Methodologies: Multi-agent lists the turn caps · Context engineering notes `Explore` runs without `CLAUDE.md`.

### Migration from v1.10
- None — run `--update`.

## v1.10.0 — 2026-10-18
### Changed
- `refactor` and `optimize` skills folded into `CLAUDE.md` → No Behavior Change: seven rules — green tests first, tests untouched, one step at a time with scoped gates, revert a step that breaks a test, optimize measures a baseline and keeps only steps that improve it. Branch, ADR, Explore and close rules they restated are already in `CLAUDE.md` and `create-feature`.

### Removed
- `.claude/skills/refactor/` · `.claude/skills/optimize/` — listed in `sdd-removed`.

### Migration from v1.9
- Run `--update`: it deletes both skills. A rule you added to either one: move it to `.claude/project.md` → Project Rules.

## v1.9.0 — 2026-10-18
### Added
- `proposal.md` → Scope → `- Gates: ON | OFF`, next to `TDD` — confirmed in create-feature step 2 · inline: always ON. `OFF` makes `gates.sh scoped` and `full` print `⏭️` for every gate, ending in `(off)` — `gates.sh fr` still runs `TEST_FR`, so TDD RED checks and `test: ✅` keep working.

### Migration from v1.8
- None — a change folder without the `Gates` line runs the gates.

## v1.8.1 — 2026-10-18
### Changed
- readme → Setup: what `/adopt` does — asks once, never touches source code, reports failing gates without fixing them, stages its files, you commit — and that existing behavior has no FR until a change touches it.
- readme → Use it: the command table lists every command — `yes` · `go` · `fix: <what>` · `/adopt` · `/clear` — plus a Gates table with the `scoped` · `full` · `fr` modes of `gates.sh`.
- readme → Use it: the flow diagram is back, with the `yes` · `go` · `fix:` steps.

## v1.8.0 — 2026-10-18
### Changed
- Framework files live in one folder, `.claude/sdd/`: `templates/` → `.claude/sdd/templates/` · `docs/doc-rules.md` → `.claude/sdd/doc-rules.md` · `docs/decisions/000-template.md` → `.claude/sdd/templates/adr.md` . `docs/` and `specs/` now hold only your files.
- `.claude/sdd-core` → `sdd-core` at this repo's root, listing folders only — only the installer reads it, so it is no longer installed.
- `specs/changes/.gitkeep` removed — `specs/changes/archive/.gitkeep` already keeps the folder.
- `CLAUDE.md`: Hard Rules grouped by topic — Architecture · Code · Dependencies and secrets · Context · Docs — and Conventions folded into them. Sections follow the workflow: Change Size → Working Protocol → Spec Rules → Hard Rules → Testing Rules → Quality Gates. No rule changed.
- `gates.conf`, `docs/architecture.md`, `gates.sh`, `protect-secrets.sh` and `doc-rules.md` say in their first lines whether they are yours or the framework's.
- readme: Use it is a short walkthrough — terms, full cycle step by step, inline, extra commands — replacing the command table and the How it works diagram · new Files section (who owns each path) · Update and CI get their own sections.

### Added
- `sdd-removed` at this repo's root: paths the framework no longer ships — `--update` deletes them and the folders they leave empty.

### Migration from v1.7
- Run `--update`: it adds `.claude/sdd/` and deletes the old paths. A template you edited under `templates/` is deleted too — copy it into `.claude/sdd/templates/` first.
- A rule of yours in `.claude/project.md` that names an old path: point it to the new one.

## v1.7.0 — 2026-10-18
### Added
- `.claude/hooks/protect-secrets.sh`: `PreToolUse` hook on Bash — blocks a command that names a path denied for `Edit` in `settings.json` (`python -c "open('.env')"`, `node`, `cp`, `base64`, `find -exec`…), which deny rules miss in a shell · `!` entries stay allowed · `settings.json` registers it · `~/.ssh` and `~/.aws` are now denied for `Edit` too.
- `--update` installs `.claude/hooks/` — listed in `.claude/sdd-core`.

### Changed
- `/adopt` puts a secret in `deny` as `Read` and `Edit`, a bulky path as `Read` only — an `Edit` entry would make the hook block staging it.

### Migration from v1.6
- `settings.json` is yours, so `--update` never adds the hook to it: copy the `hooks` block and the `Edit(~/.ssh/**)` · `Edit(~/.aws/**)` lines from `project/.claude/settings.json`.

## v1.6.0 — 2026-10-18
### Added
- `.claude/project.md`: your project values — Product, Stack, Layer Structure, Naming, Forbidden, Test name, Commit message, Branch name — plus a Project Rules section. Never overwritten.
- `install.sh --update` · `install.ps1 -Update`: overwrites only the framework files listed in `.claude/sdd-core` — never your `project.md`, `gates.conf`, `settings.json`, `specs/` or `docs/`, never a skill or agent you added.
- `.claude/sdd-core`: the list of framework-owned paths.

### Changed
- `CLAUDE.md` holds only framework rules and imports `.claude/project.md` with `@.claude/project.md` — rules that used a project value now name it (e.g. `project.md` → Forbidden).
- `/adopt` fills `.claude/project.md` instead of `CLAUDE.md`.
- Installers list only the existing files that differ from the version installed.

### Migration from v1.5
- Run `--update` once: it adds `.claude/project.md` and updates nothing else. Move your values from `CLAUDE.md` into it, then run `--update` again — it replaces `CLAUDE.md` with the framework version.

## v1.5.1 — 2026-10-18
### Changed
- `Explore` runs on Haiku — read-only mapping with a fixed summary, cheaper and faster.
- `reviewer` runs on Opus — it runs once per feature and is the last check before the specs merge.
- `implementer` and `reviewer` drop "NEVER load a skill" — neither has the `Skill` tool · `implementer` drops "NEVER commit" — `settings.json` already denies `git commit`.

## v1.5.0 — 2026-10-18
### Added
- `install.ps1`: installs `project/` from Windows PowerShell with `irm … | iex` — same behavior as `install.sh`: never overwrites an existing file, lists the ones it kept · `-Ref <tag>` pins a version.
- readme → Setup: install commands for macOS · Linux · WSL and for Windows, which needs Git for Windows to run the gates.
- `.gitattributes`: `*.sh` always checks out with LF — on Windows `core.autocrlf` no longer breaks `gates.sh` with CRLF.

## v1.4.0 — 2026-10-18
### Added
- `proposal.md` → Request: the human's request verbatim, never summarized — `create-feature` NEVER narrows it, asks ONE question when it conflicts with a rule, and flags `⚠️ Request not covered: <quote>` before `approve?`.
- `reviewer` reports a Request statement that no FR covers, that an FR narrows or that Scope OUT excludes.
- Hard Rules: check the shape of external data in the entry layer · NEVER reimplement what the standard library, the framework or an approved dependency already does · NEVER signal an error with a sentinel value.
- Spec Rule: a broad request ("any error", "invalid input") becomes one scenario per input and per way it can be wrong — wrong type, wrong shape, missing field, boundary value.

### Changed
- `gates.conf`: `LINT_*` examples block technical debt — complexity, magic numbers, unused code, bug patterns — not only errors · `BUILD` type-checks in strict mode.
- Layer Structure: `[features]/` is created with the second slice — until then the only slice lives in `[src]/`.

## v1.3.0 — 2026-10-12
### Added
- Hard Rule: before asking to add a dependency, the agent checks it in its registry and shows name, version, publish date, downloads and repo — it flags a missing, brand-new, little-used or look-alike package and proposes a known alternative.
- `gates.conf`: `AUDIT` and `MANIFESTS` examples for Go (`govulncheck`) and Rust (`cargo audit`).

### Fixed
- `audit` never ran in CI: the checkout is clean, so no manifest looked changed. `gates.sh full` now also compares against `$GATES_BASE`, or `origin/<base branch>` in a GitHub PR — if the base is not fetched, `audit` runs.

## v1.2.2 — 2026-10-12
### Changed
- readme → Why: the problem this setup solves — bugs, unrequested layers, security holes and technical debt from AI-written code — and which methodology answers each one.

## v1.2.1 — 2026-10-12
### Changed
- readme rewritten for usage: Setup, Use it, How it works and Methodologies only — example session, phase table, stack adaptation, glossary and file list removed.
- `METHODOLOGIES.md` merged into the readme as one table: each methodology and how this setup applies it.

## v1.2.0 — 2026-10-12
### Added
- `install.sh`: installs `project/` into the current repo with one `curl … | bash` — never overwrites an existing file, lists the ones it kept, makes `gates.sh` executable · `-s <tag>` pins a version.

## v1.1.2 — 2026-10-12
### Changed
- readme: version, license, Claude Code and methodology badges · GitHub alerts for the core flow, the cheapest run, the diff review and duplicate FR IDs · Phases diagram colors agent steps blue and the inline path gray.

## v1.1.1 — 2026-10-12
### Fixed
- `gates.sh` detects test files by path (`__tests__/`, `tests/`, `spec/`, `test_*`, `*.test.*`, `*.spec.*`, `*_test.*`, `*_spec.*`) — Jest tests in `__tests__/` without a `.test` suffix no longer fail `frs`, and source files like `latest.ts` or `special.ts` no longer count as tests.

## v1.1.0 — 2026-10-11
### Added
- `frs` gate in `gates.sh full`: every FR in `specs/current/` must have a test and a unique ID — catches deleted tests and duplicate IDs from parallel branches.
- readme → In a team: CI workflow running the full gates on every PR, and how to fix a duplicate FR ID.
- Branch name and commit message formats are `CLAUDE.md` placeholders — fit them to your team's convention, ticket ID included.
- `reviewer` flags tests named with an FR ID that check another behavior or assert nothing.

### Changed
- RF renamed to FR everywhere: `gates.sh fr`, `TEST_FR`, `{fr}`, `{fr_id}`. Upgrade: rename `TEST_RF` to `TEST_FR` and `{rf}` / `{rf_id}` to `{fr}` / `{fr_id}` in your `gates.conf`, and RF to FR in your `CLAUDE.md`.
- Feature close merges the FRs into the living spec before the full gates, so a REMOVED FR no longer fails `frs`.
- Methodologies moved from the readme to `METHODOLOGIES.md`; readme trimmed.

### Fixed
- `gates.conf` documents single quotes for commands with `$` — double quotes expanded them when the script sourced the file.

## v1.0.0 — 2026-10-11
- First release.
