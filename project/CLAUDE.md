# Tres en raya

## Product
- Browser tic-tac-toe game for two players on one device.
- Behavior lives as RFs in `specs/current/<capability>.md` — NEVER define it here.

## Stack
- Language: TypeScript
- Framework: React + Vite
- App folder: `app/` — run all commands from there
- Testing: Vitest + Testing Library (jsdom)
- Lint: oxlint
- Run locally: `npm run dev`

## Layer Structure — Vertical Slice
```
app/src/
  features/
    <feature-name>/
      <Feature>.tsx        ← entry layer: UI component
      use<Feature>.ts      ← logic layer: state hook
      <rules>.ts           ← logic layer: pure business rules
      types.ts             ← types — no runtime logic
      <Feature>.test.tsx   ← tests of the slice
      index.ts             ← public API: the only file other slices import
  shared/                  ← only code used by 2+ slices — create when first needed
  App.tsx                  ← app composition: wires slices together, no feature logic
```

## Conventions
- Naming: PascalCase components and their files, camelCase functions, hooks and other files
- One feature = one folder in `features/`
- NEVER import a slice's internal files — always through its public API
- Every `.md` follows `docs/doc-rules.md` — new docs start from their template

## Hard Rules
- NEVER use: `any`, default exports (except config files that require them), class components
- NEVER put business rules in the entry layer — extract them to the logic layer
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
- If the request cannot be classified: ask ONE question — stop and wait.
- If inline work grows past the table: stop, report, switch to the full cycle.
- ALWAYS state the classification before starting: `Size: inline — <reason>` or `Size: full cycle — <reason>`.

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
- ALWAYS start the name of a test that covers an RF with its RF ID, in the form the test runner allows: `GAME-01 should <result> when <condition>`.
- Check an RF with `npm test -- -t "<RF-ID>"` — mark `test: ✅` only when every GIVEN/WHEN/THEN has a passing test.

## Working Protocol — STRICT
These are Hard Rules. Any violation is a protocol breach.

- NEVER start a new task without explicit approval — per task ("yes" or "go") or as a batch ("go up to ID-00N")
- NEVER assume silence = approval — wait for a clear yes
- "go" = approval of the active feature's Progress → `Next step`
- "go" or "go up to ID-00N" in a new session or after `/clear`: load `.claude/skills/create-feature/SKILL.md` first
- Commit message format: `type(scope): description` — type is one of `feat | fix | refactor | test | docs | chore`
- Commit once per change, never per task — full cycle: when the feature closes · inline: after its close sequence — propose the message, the human commits
- NEVER skip the task close sequence — it is mandatory after every task and every inline change (inline: steps 1 and 3 only):
  ```
  1. Run Quality Gates
  2. Update the task line in specs/changes/<feature>.md: [x] + gates
     - Covered RFs: set `test: ✅` in Requirement Deltas per Spec Rules
     - Only if the plan changed: add a sub-bullet `deviation: <what>`
     - Progress → `Next step:` the next task ID, or `merge specs` after the last task
  3. git add <files> — stop and wait
     The human reviews `git diff --staged` and replies "go", or "fix: <what>" → fix → back to step 1
  4. On the human's next message:
     - Inside an approved batch: continue with the next task
     - "go": start Progress → `Next step`
     - Anything else: reply `Next: <Next step> — /clear → go` — stop and wait
  ```
- Active feature = the `specs/changes/*.md` whose Progress is not `feature closed`
- If something is unclear: ask ONE specific question — stop and wait

## Quality Gates — Run in every task close
Run in this exact order. If any fails: stop, report the exact error, propose options — NEVER continue with a failing gate, NEVER self-fix silently.

| Step | Scoped — each task close | Full — feature close · inline change · scoped not possible | Run when | Blocks if |
|------|-------------------------|-------------------------------------------------------------|----------|-----------|
| 1. Lint | `npx oxlint <changed files>` | `npm run lint` | always | any error or warning |
| 2. Build / type check | same as Full | `npm run build` | always | build fails |
| 3. Tests | `npx vitest related <changed files> --run` | `npm test -- --reporter=dot` | always | any test fails |
| 4. Audit | same as Full | `npm audit --audit-level=high` | dependency manifest or lockfile changed | high or critical found |

- Status: `✅` pass · `❌ <gate>` fail · `⏭️` skipped · `-` pending
- Gates format: `lint ✅ · build ✅ · tests ✅ (X passing) · audit ⏭️`
- No build step in the stack: mark Build `⏭️`.
- Passing gate: report it in the Gates format only — NEVER paste its output.
- Failing gate: quote only the failing lines.
- Gate not run → mark it `⏭️` in the task line.
- Docs-only change (`.md` files, comments): skip all gates, re-read the edited files against `docs/doc-rules.md`, mark Gates `⏭️`.

## Chat Replies
- Reply in the fewest words that stay unambiguous — no greeting, no restating the request, no closing summary.
- When a skill has an Output Contract: emit it and add nothing around it.
- NEVER shorten RFs, change docs, questions to the human, or the options after a failing gate.
