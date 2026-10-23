# Changelog

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
