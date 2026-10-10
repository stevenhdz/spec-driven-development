# [Project name]

## Product
- [What the product does, in one line — e.g. "REST API for orders", "CLI that imports CSV files"]
- Behavior lives as RFs in `specs/current/<capability>/spec.md` — NEVER define it here.

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
      [entry]          ← entry layer: UI component · HTTP route · CLI command — holds simple state, no business rules — always
      [rules]          ← logic layer: pure business rules — always when there is a rule
      [tests]          ← tests of the slice — always
      [public API]     ← the only file other slices import (e.g. index.ts · __init__.py) — always
      [stateful logic] ← logic layer: hook · service · use case — only when state or I/O outgrows the entry layer, or is reused
      [types]          ← types, schemas, contracts, no runtime logic — only when 2+ files share them
  [shared]/            ← only code used by 2+ slices — create when first needed
  [app entry]          ← app composition: wires slices together, no feature logic
```
- Layers are responsibilities, not files — create an optional file only when its condition is true.

## Conventions
- Naming: [e.g. PascalCase components, camelCase functions · snake_case modules and functions]
- One feature = one folder in `[features]/`
- NEVER import a slice's internal files — always through its public API
- Every `.md` follows `docs/doc-rules.md` — new docs start from their template

## Hard Rules
- NEVER use: [forbidden patterns — e.g. `any`, default exports, class components, inline `style` · global mutable state]
- NEVER put business rules in the entry layer — extract them to the logic layer
- NEVER add comments to the code you write or change — names and small functions must explain the intent; leave existing comments as they are
- NEVER over-engineer (KISS · YAGNI): the simplest solution that works — a function before a class, no abstraction or layer for a use case that does not exist yet
- NEVER create a pass-through: a wrapper around a single call (e.g. a hook around one `useState`, a service around one query), a component that only renders another, a re-export other than the public API, a type used in one place — and NEVER write code no RF or caller can reach
- NEVER export what no other file imports — types included
- Model states that exclude each other as one tagged union — NEVER separate fields that can contradict each other (e.g. `isLoading` next to `error` and `data`)
- NEVER silence the type checker — no casts, non-null assertions or ignore comments: fix the type — scaffold files exempt
- UI: native semantic elements first — every control has an accessible name — an ARIA role only with the children its pattern requires
- NEVER add a dependency without explicit approval
- ALWAYS search (grep / glob) before opening a file — read only the line range the task needs
- NEVER read the internal files of a slice the task does not change — only its public API
- NEVER read, print or work around a file denied in `.claude/settings.json` — if a task needs a value from one, ask the human
- NEVER stage a denied file — except a lockfile: stage it by path, unread, together with its manifest
- NEVER hardcode a secret — read it from an environment variable and document its name in `.env.example`

## Testing Rules
- Test observable behavior only — what a user sees, what an API returns — NEVER implementation details.
- Find elements as a user does: role + accessible name, then visible text — NEVER by index, CSS class or test id.
- Mock only external boundaries (network, database, clock, file system) — use the real code everywhere else.
- One test = one behavior, structured Arrange / Act / Assert.
- Every variant a THEN names gets its own test — e.g. "pays by card, PayPal or bank transfer" = 3 tests.
- When TDD is ON — full cycle: the change's `proposal.md` → Scope · inline: always ON — NEVER keep a test that did not fail first.
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
- `specs/current/<capability>/spec.md` is the source of truth for current behavior — one folder per capability, start from `templates/spec.md`.
- `specs/changes/<feature>/` records one change — start from `templates/change/`: `proposal.md` (goal, scope, constraints) · `design.md` (approach) · `specs/<capability>/spec.md` (RF deltas) · `tasks.md` (tasks, progress) — closed changes move to `specs/changes/archive/<YYYY-MM-DD>-<feature>/`.
- RF ID: `<PREFIX>-NN` (e.g. `ORDER-01`) — prefix unique per spec file, number taken from its `Next ID`.
- NEVER reuse or renumber an RF ID.
- RFs describe behavior observable from outside: what a user sees, what an API returns, what a command prints.
- RFs cover everything the request makes visible — layout (e.g. "a list sorted by date"), messages and controls — not only the logic.
- NEVER change observable behavior before its RF is written:
  - Full cycle: the RF goes in the change folder's delta spec (`specs/<capability>/spec.md`) — approved before any code.
  - Inline: add or edit the RF in `specs/current/<capability>/spec.md` first — a new RF takes the file's `Next ID` and advances it — then test, then code — stage all three together.
- No observable behavior change (refactor, styling, docs, chore): NEVER edit RFs.
- ALWAYS start the name of a test that covers an RF with its RF ID, in the form the test runner allows: [e.g. `ORDER-01 should <result> when <condition>` · `test_order_01_<result>_when_<condition>`].
- Check an RF with `bash .claude/scripts/gates.sh rf <RF-ID>` — mark `test: ✅` only when it passes and every GIVEN/WHEN/THEN has a test.

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
  2. Full cycle only: update the change folder — the implementer does it
  3. git add <files> — stop and wait — full cycle: the implementer stages and returns, the main session relays and waits
     The human reviews `git diff --staged` and replies "go", or "fix: <what>" → fix → back to step 1
  4. Full cycle only: handle the human's next message — create-feature step 8
  ```
- Full cycle: a change-doc task runs only in the `implementer` subagent — NEVER in the main session
- If something is unclear: ask ONE specific question — stop and wait

## Quality Gates — Run in every task close
Commands live in `.claude/gates.conf`. Run them only through `bash .claude/scripts/gates.sh`, from the repo root — it formats the files in place, then runs lint → build → tests → audit in this order, stops at the first failure and prints one line.

| Mode | Command | When |
|------|---------|------|
| Scoped | `bash .claude/scripts/gates.sh scoped <changed files>` | each task close |
| Full | `bash .claude/scripts/gates.sh full` | feature close · inline change |
| RF | `bash .claude/scripts/gates.sh rf <RF-ID>` | RED check · before setting `test: ✅` |

- Report the line the script prints exactly as printed — NEVER paraphrase it.
- NEVER run a gate command outside the script — except the single failing test while fixing it.
- `❌`: stop, quote the lines the script printed, propose options — NEVER continue with a failing gate, NEVER self-fix silently.
- Status: `✅` pass · `❌ <gate>` fail · `⏭️` skipped · `-` pending
- Gates format: `lint ✅ · build ✅ · tests ✅ (X passing) · audit ⏭️` — the script prints it.
- Docs-only change (`.md` files): re-read the edited files against `docs/doc-rules.md` — the script prints `⏭️` for every gate.

## Compact instructions
When compacting, keep: the active change folder path, its Next step, the staged files, and the last line `gates.sh` printed with its failing lines.

## Chat Replies
- Reply in the fewest words that stay unambiguous — no greeting, no restating the request, no closing summary.
- When a skill has an Output Contract: emit it and add nothing around it.
- NEVER shorten RFs, change folders, questions to the human, or the options after a failing gate.
