# [Project name]

## Product
- [What the product does, in one line — e.g. "REST API for orders", "Browser tic-tac-toe game"]
- Behavior lives as RFs in `specs/current/<capability>.md` — NEVER define it here.

## Stack
- Language: [e.g. TypeScript · Python · Go]
- Framework: [e.g. React + Vite · Express · FastAPI]
- App folder: [e.g. `app/` — run all commands from there]
- Testing: [e.g. Vitest + Testing Library · Jest · pytest]
- Lint: [e.g. oxlint · eslint · ruff]
- Run locally: [e.g. `npm run dev` · `uvicorn app.main:app --reload`]

## Layer Structure — Vertical Slice
```
[src]/
  [features]/
    [feature-name]/
      [entry]          ← entry layer: UI component · HTTP route · CLI command — no business rules
      [logic]          ← logic layer: business rules and state — hook · service · use case
      [types]          ← types, schemas, contracts — no runtime logic
      [tests]          ← tests of the slice
      [public API]     ← the only file other slices import (e.g. index.ts · __init__.py)
  [shared]/            ← only code used by 2+ slices — create when first needed
  [app entry]          ← app composition: wires slices together, no feature logic
```

## Conventions
- Naming: [e.g. PascalCase components, camelCase functions · snake_case modules and functions]
- One feature = one folder in `[features]/`
- NEVER import a slice's internal files — always through its public API
- Every `.md` follows `docs/doc-rules.md` — new docs start from their template

## Hard Rules
- NEVER use: [forbidden patterns — e.g. `any`, default exports, class components · global mutable state]
- NEVER put business rules in the entry layer — extract them to the logic layer
- NEVER add comments to the code you write or change — names and small functions must explain the intent; leave existing comments as they are
- NEVER over-engineer (KISS · YAGNI): the simplest solution that works — a function before a class, no abstraction or layer for a use case that does not exist yet
- NEVER add a dependency without explicit approval
- ALWAYS search (grep / glob) before opening a file — read only the line range the task needs
- NEVER read the internal files of a slice the task does not change — only its public API
- NEVER read, print or work around a file denied in `.claude/settings.json` — if a task needs a value from one, ask the human
- NEVER stage a denied file — except a lockfile: stage it by path, unread, together with its manifest
- NEVER hardcode a secret — read it from an environment variable and document its name in `.env.example`

## Testing Rules
- Test observable behavior only — what a user sees, what an API returns — NEVER implementation details.
- Mock only external boundaries (network, database, clock, file system) — use the real code everywhere else.
- One test = one behavior, structured Arrange / Act / Assert.
- TDD ON: NEVER keep a test that did not fail first.
- A test fails because of a bug in the code: fix the code, NEVER the test.

## Change Size
Classify every request before touching code.

| Full cycle (`.claude/skills/create-feature/SKILL.md`) if ANY is true | Inline if ALL are true |
|----------------------------------------------------------------------|------------------------|
| Removes an RF | Adds or modifies at most one RF, in an existing spec file — or none |
| Adds or modifies more than one RF | Removes no RF |
| Needs a new spec file | Touches one slice only |
| Touches more than one slice | Creates no slice |
| Creates a slice | Adds no dependency |
| Adds a dependency | |

- The human's word wins: "as a feature" or "inline" overrides the table.
- If inline work grows past the table: stop, report, switch to the full cycle.
- No observable behavior change in code: skip the table — refactor: load `.claude/skills/refactor/SKILL.md` · optimization: load `.claude/skills/optimize/SKILL.md`.
- ALWAYS state the classification before starting: `Size: inline — <reason>`, `Size: full cycle — <reason>`, `Size: refactor — <reason>` or `Size: optimize — <reason>`.

## Spec Rules — SDD
- `specs/current/<capability>.md` is the source of truth for current behavior — one file per capability, start from `templates/spec.md`.
- `specs/changes/<feature>.md` records one change: RF deltas, tasks, progress — start from `templates/change.md`.
- RF ID: `<PREFIX>-NN` (e.g. `ORDER-01`) — prefix unique per spec file, number taken from its `Next ID`.
- NEVER reuse or renumber an RF ID.
- RFs describe behavior observable from outside: what a user sees, what an API returns, what a command prints.
- NEVER change observable behavior before its RF is written:
  - Full cycle: the RF goes in Requirement Deltas of the change doc — approved before any code.
  - Inline: add or edit the RF in `specs/current/` first — a new RF takes the file's `Next ID` and advances it — then test, then code — stage all three together.
- No observable behavior change (refactor, styling, docs, chore): NEVER edit RFs.
- ALWAYS start the name of a test that covers an RF with its RF ID, in the form the test runner allows: [e.g. `ORDER-01 should <result> when <condition>` · `test_order_01_<result>_when_<condition>`].
- Check an RF with [test command filtered by name — e.g. `npm test -- -t "<RF-ID>"` · `pytest -k "<rf_id>"`] — mark `test: ✅` only when every GIVEN/WHEN/THEN has a passing test.

## Working Protocol — STRICT
These are Hard Rules. Any violation is a protocol breach.

- NEVER start a new task without explicit approval — per task ("yes" or "go") or as a batch ("go up to ID-00N")
- NEVER assume silence = approval — wait for a clear yes
- Any reply about an active feature ("go", "yes", "fix: <what>", "go up to ID-00N") in a new session or after `/clear`: load `.claude/skills/create-feature/SKILL.md` first
- Commit message format: `type(scope): description` — type is one of `feat | fix | refactor | perf | test | docs | chore`
- Commit once per change, never per task — full cycle: when the feature closes · inline: after its close sequence — propose the message, the human commits
- NEVER skip the task close sequence — it is mandatory after every task and every inline change:
  ```
  1. Run Quality Gates
  2. Full cycle only: update the change doc — create-feature step 8
  3. git add <files> — stop and wait
     The human reviews `git diff --staged` and replies "go", or "fix: <what>" → fix → back to step 1
  4. Full cycle only: handle the human's next message — create-feature step 8
  ```
- If something is unclear: ask ONE specific question — stop and wait

## Quality Gates — Run in every task close
Run in this exact order. If any fails: stop, report the exact error, propose options — NEVER continue with a failing gate, NEVER self-fix silently.

| Step | Scoped — each task close | Full — feature close · inline change · scoped not possible | Run when | Blocks if |
|------|-------------------------|-------------------------------------------------------------|----------|-----------|
| 1. Lint | [e.g. `npx oxlint <changed files>` · `ruff check <files>`] | [e.g. `npm run lint` · `ruff check .`] | always | any error or warning |
| 2. Build / type check | same as Full | [e.g. `npm run build` · `mypy .` · `go build ./...`] | always | build fails |
| 3. Tests | [e.g. `npx vitest related <changed files> --run` · `pytest <slice>`] | [e.g. `npm test -- --reporter=dot` · `pytest -q`] | always | any test fails |
| 4. Audit | same as Full | [e.g. `npm audit --audit-level=high` · `pip-audit`] | dependency manifest or lockfile changed | high or critical found |

- Status: `✅` pass · `❌ <gate>` fail · `⏭️` skipped · `-` pending
- Gates format: `lint ✅ · build ✅ · tests ✅ (X passing) · audit ⏭️`
- No build step in the stack: mark Build `⏭️`.
- Passing gate: report it in the Gates format only — NEVER paste its output.
- Failing gate: quote only the failing lines.
- Gate not run → mark it `⏭️` in the task line.
- Docs-only change (`.md` files): skip all gates, re-read the edited files against `docs/doc-rules.md`, mark Gates `⏭️`.

## Chat Replies
- Reply in the fewest words that stay unambiguous — no greeting, no restating the request, no closing summary.
- When a skill has an Output Contract: emit it and add nothing around it.
- NEVER shorten RFs, change docs, questions to the human, or the options after a failing gate.
