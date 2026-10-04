# [Project name]

## Product
- [What the product does, in one line — e.g. "REST API for orders", "Browser tic-tac-toe game"]
- Behavior lives as RFs in `specs/current/<capability>.md` — NEVER define it here.

## Stack
- Language: [e.g. TypeScript · Python · Go]
- Framework: [e.g. React + Vite · Express · FastAPI]
- App folder: [e.g. `app/` — run all commands from there]
- Testing: [e.g. Vitest · Jest · pytest]
- Lint: [e.g. oxlint · eslint · ruff]
- Run locally: [e.g. `npm run dev` · `uvicorn app.main:app --reload`]

## Layer Structure — Vertical Slice
```
[src]/
  [features]/
    [feature-name]/
      [entry]          ← entry layer: UI component · HTTP route · CLI command
      [logic]          ← business rules and state: hook · service · use case
      [types]          ← types, schemas, contracts — no runtime logic
      [tests]          ← tests of the slice
      [public API]     ← the only file other slices import (e.g. index.ts · __init__.py)
  [shared]/            ← only code used by 2+ slices — create when first needed
```

## Conventions
- Naming: [e.g. PascalCase components, camelCase functions · snake_case modules and functions]
- One feature = one folder in `[features]/`
- NEVER import a slice's internal files — always through its public API
- Every `.md` follows `docs/doc-rules.md`

## Hard Rules
- NEVER use: [forbidden patterns — e.g. `any`, default exports, class components · global mutable state]
- NEVER put business rules in the entry layer — extract them to the logic layer
- NEVER read, print, stage or work around a file denied in `.claude/settings.json` — if a task needs a value from one, ask the human
- NEVER hardcode a secret — read it from an environment variable and document its name in `.env.example`

## Change Size
Classify every request before touching code.

| Full cycle (`.claude/skills/create-feature/SKILL.md`) if ANY is true | Inline if ALL are true |
|----------------------------------------------------------------------|------------------------|
| Adds or removes an RF | Modifies at most one existing RF, or none |
| Modifies more than one RF | Touches one slice only |
| Touches more than one slice | Creates no slice |
| Creates a slice | Adds no dependency |
| Adds a dependency | |

- The human's word wins: "as a feature" or "inline" overrides the table.
- If the request cannot be classified: ask ONE question — stop and wait.
- If inline work grows past the table: stop, report, switch to the full cycle.
- ALWAYS state the classification before starting: `Size: inline — <reason>` or `Size: full cycle — <reason>`.

## Spec Rules — SDD
- `specs/current/<capability>.md` is the source of truth for current behavior — one file per capability, start from `specs/current/spec-template.md`.
- `specs/changes/<feature>.md` records one change: RF deltas, tasks, progress — start from `specs/changes/change-template.md`.
- RF ID: `<PREFIX>-NN` (e.g. `ORDER-01`) — prefix unique per spec file, number taken from its `Next ID`.
- NEVER reuse or renumber an RF ID.
- RFs describe behavior observable from outside: what a user sees, what an API returns, what a command prints.
- NEVER change observable behavior before its RF is written:
  - Full cycle: the RF goes in Requirement Deltas of the change doc — approved before any code.
  - Inline: edit the RF in `specs/current/` first, then test, then code — stage all three together.
- No observable behavior change (refactor, styling, docs, chore): NEVER edit RFs.
- ALWAYS start the name of a test that covers an RF with its RF ID, in the form the test runner allows: [e.g. `ORDER-01 should [result] when [condition]` · `test_order_01_[result]_when_[condition]`].
- Check an RF with [test command filtered by name — e.g. `npm test -- -t "<RF-ID>"` · `pytest -k "<rf_id>"`] — mark `test: ✅` only when every GIVEN/WHEN/THEN has a passing test.

## Testing Rules
- Test observable behavior only — what a user sees, what an API returns — NEVER implementation details.
- Mock only external boundaries (network, database, clock, file system) — use the real code everywhere else.
- One test = one behavior, structured Arrange / Act / Assert.
- TDD ON: NEVER keep a test that did not fail first.
- A test fails because of a bug in the code: fix the code, NEVER the test.

## Chat Replies
- Reply in the fewest words that stay unambiguous — no greeting, no restating the request, no closing summary.
- When a skill has an Output Contract: emit it and add nothing around it.
- NEVER shorten RFs, change docs, questions to the human, or the options after a failing gate.

## Working Protocol — STRICT
These are Hard Rules. Any violation is a protocol breach.

- NEVER start a new task without explicit approval — per task ("yes") or as a batch ("go up to ID-00N")
- NEVER assume silence = approval — wait for a clear yes
- Commit message format: `type(scope): description` — type is one of `feat | fix | refactor | test | docs | chore`
- NEVER skip the task close sequence — it is mandatory after every task:
  ```
  1. Run Quality Gates
  2. Update the task line in specs/changes/<feature>.md: [x] + gates
     - Covered RFs: set `test: ✅` in Requirement Deltas per Spec Rules
     - Only if the plan changed: add a sub-bullet `deviation: <what>`
  3. git add <files> → propose the commit message — stop and wait
     The human reviews `git diff --staged` and commits, or replies "fix: <what>" → fix → back to step 1
  4. After the commit: confirm it with `git log -1`
     - Inside an approved batch: continue with the next task
     - Otherwise ask: "ID-00X done. Move to ID-00X+1?" — stop and wait
  ```
- Active feature = the `specs/changes/*.md` (not the template) whose Progress is not `feature closed`
- If something is unclear: ask ONE specific question — stop and wait

## Code Philosophy — KISS
- NEVER over-engineer: the simplest solution that works — no abstraction, class or layer for a use case that does not exist yet (YAGNI)

## Quality Gates — Run in every task close
Run in this exact order. If any fails: stop, report the exact error, propose options — NEVER continue with a failing gate, NEVER self-fix silently.

| Step | Command | Run when | Blocks if |
|------|---------|----------|-----------|
| 1. Lint | [e.g. `npm run lint` · `ruff check .`] | always | any error or warning |
| 2. Build / type check | [e.g. `npm run build` · `mypy .` · `go build ./...`] | always | build fails |
| 3. Tests | [e.g. `npm test -- --reporter=dot` · `pytest -q`] | always | any test fails |
| 4. Audit | [e.g. `npm audit --audit-level=high` · `pip-audit`] | dependency manifest or lockfile changed | high or critical found |

- Status: `✅` pass · `❌ <gate>` fail · `⏭️` skipped · `-` pending
- Gates format: `lint ✅ · build ✅ · tests ✅ (X passing) · audit ⏭️`
- No build step in the stack: mark Build `⏭️`.
- Passing gate: report it in the Gates format only — NEVER paste its output.
- Failing gate: quote only the failing lines.
- Gate not run → mark it `⏭️` in the task line.
- Docs-only change (`.md` files, comments): skip all gates, re-read the edited files against `docs/doc-rules.md`, mark Gates `⏭️`.
