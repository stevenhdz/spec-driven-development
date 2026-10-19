# Rules — Spec Driven Development
<!-- Framework rules — `install.sh --update` overwrites this file. Your project values live in `.claude/project.md`. -->

@.claude/project.md

## Change Size
Classify every request before touching code.

| Full cycle (`.claude/skills/create-feature/SKILL.md`) if ANY is true | Inline if ALL are true |
|----------------------------------------------------------------------|------------------------|
| Removes an FR | Adds or modifies at most one FR, in an existing spec file — or none |
| Adds or modifies more than one FR | Removes no FR |
| Needs a new spec file | Touches one slice only |
| Touches more than one slice | Creates no slice |
| Creates a slice | Adds no dependency |
| Adds a dependency | |

- The human's word wins: "as a feature" or "inline" overrides the table.
- If inline work grows past the table: stop, report, switch to the full cycle.
- No observable behavior change in code: skip the table — refactor: load `.claude/skills/refactor/SKILL.md` · optimization: load `.claude/skills/optimize/SKILL.md`.
- ALWAYS state the classification before starting: `Size: inline — <reason>`, `Size: full cycle — <reason>`, `Size: refactor — <reason>` or `Size: optimize — <reason>`.

## Working Protocol — STRICT
These are Hard Rules. Any violation is a protocol breach.

- NEVER start a new task without explicit approval — per task ("yes" or "go") or as a batch ("go up to ID-00N")
- NEVER assume silence = approval — wait for a clear yes
- Any reply about an active feature ("go", "yes", "fix: <what>", "go up to ID-00N") in a new session or after `/clear`: load `.claude/skills/create-feature/SKILL.md` first
- Commit message: `.claude/project.md` → Commit message — type is one of `feat | fix | refactor | perf | test | docs | chore`
- Branch name: `.claude/project.md` → Branch name — type: `feat` full cycle · `refactor` · `perf` — ask for the ticket ID when the format has one
- Commit once per change, never per task — full cycle: when the feature closes · inline: after its close sequence — propose the message, the human commits
- NEVER skip the task close sequence — it is mandatory after every task and every inline change:
  ```
  1. Run Quality Gates
  2. Full cycle only: update the change folder — the implementer does it
  3. git add <files> — stop and wait — full cycle: the implementer stages and returns, the main session relays and waits
     The human reviews `git diff --staged` and replies "go", or "fix: <what>" → fix → back to step 1
  4. Full cycle only: handle the human's next message — create-feature step 8
  ```
- Full cycle: a change-folder task runs only in the `implementer` subagent — NEVER in the main session
- If something is unclear: ask ONE specific question — stop and wait

## Spec Rules — SDD
- `specs/current/<capability>/spec.md` is the source of truth for current behavior — one folder per capability, start from `.claude/sdd/templates/spec.md`.
- `specs/changes/<feature>/` records one change — start from `.claude/sdd/templates/change/`: `proposal.md` (goal, scope, constraints) · `design.md` (approach) · `specs/<capability>/spec.md` (FR deltas) · `tasks.md` (tasks, progress) — closed changes move to `specs/changes/archive/<YYYY-MM-DD>-<feature>/`.
- FR ID: `<PREFIX>-NN` (e.g. `ORDER-01`) — prefix unique per spec file, number taken from its `Next ID`.
- NEVER reuse or renumber an FR ID — except a duplicate the `frs` gate reports after a merge: renumber the FR your branch added, with its tests, from the file's `Next ID`.
- FRs describe behavior observable from outside: what a user sees, what an API returns, what a command prints.
- FRs cover everything the request makes visible — layout (e.g. "a list sorted by date"), messages and controls — not only the logic.
- A broad request (e.g. "any error", "invalid input") MUST become one scenario per input it names and per way that input can be wrong: wrong type, wrong shape, missing field, boundary value — NEVER only the cases it lists as examples.
- NEVER change observable behavior before its FR is written:
  - Full cycle: the FR goes in the change folder's delta spec (`specs/<capability>/spec.md`) — approved before any code.
  - Inline: add or edit the FR in `specs/current/<capability>/spec.md` first — a new FR takes the file's `Next ID` and advances it — then test, then code — stage all three together.
- No observable behavior change (refactor, styling, docs, chore): NEVER edit FRs.
- ALWAYS start the name of a test that covers an FR with its FR ID, in the form `.claude/project.md` → Test name gives.
- Check an FR with `bash .claude/scripts/gates.sh fr <FR-ID>` — mark `test: ✅` only when it passes and every GIVEN/WHEN/THEN has a test.

## Hard Rules

### Architecture
- NEVER import a slice's internal files — always through its public API
- NEVER put business rules in the entry layer — extract them to the logic layer
- NEVER let the logic layer know the transport (DOM, HTTP, terminal) — it takes and returns plain data
- ALWAYS check the shape of external data (parsed JSON, request body, file content) in the entry layer — data of the wrong shape becomes the error path, NEVER an unhandled exception

### Code
- NEVER use the patterns in `.claude/project.md` → Forbidden
- NEVER over-engineer (KISS · YAGNI): the simplest solution that works — a function before a class, no abstraction or layer for a use case that does not exist yet
- NEVER create a pass-through: a wrapper around a single call (e.g. a hook around one `useState`, a service around one query), a component that only renders another, a re-export other than the public API, a type used in one place — and NEVER write code no FR or caller can reach
- NEVER export what no other file imports — types included
- NEVER reimplement what the standard library, the framework or an approved dependency already does (e.g. argument parsing, date math, JSON schema checks) — configure it instead (e.g. override the parser's error handler, not a hand-written parser)
- NEVER signal an error with a sentinel value (`None`, `-1`, `""`) — raise or return the language's error type, with a message that names the bad input
- Model states that exclude each other as one tagged union — NEVER separate fields that can contradict each other (e.g. `isLoading` next to `error` and `data`)
- NEVER silence the type checker — no casts, non-null assertions or ignore comments: fix the type — scaffold files exempt
- UI: native semantic elements first — every control has an accessible name — an ARIA role only with the children its pattern requires
- NEVER add comments to the code you write or change — names and small functions must explain the intent; leave existing comments as they are

### Dependencies and secrets
- NEVER add a dependency without explicit approval — before asking, check it in its registry (e.g. `npm view <pkg>` · `pip index versions <pkg>`) and show: exact name, version, publish date, weekly downloads, source repo — a package not found, published in the last 30 days, with few downloads or a name close to a popular one: say so and propose a known alternative
- NEVER hardcode a secret — read it from an environment variable and document its name in `.env.example`
- NEVER read, print or work around a file denied in `.claude/settings.json` — if a task needs a value from one, ask the human
- NEVER stage a denied file — except a lockfile: stage it by path, unread, together with its manifest

### Context
- ALWAYS search (grep / glob) before opening a file — read only the line range the task needs
- NEVER read the internal files of a slice the task does not change — only its public API

### Docs
- Every `.md` follows `.claude/sdd/doc-rules.md` — new docs start from their template

## Testing Rules
- Test observable behavior only — what a user sees, what an API returns — NEVER implementation details.
- UI tests: find elements as a user does: role + accessible name, then visible text — NEVER by index, CSS class or test id.
- Mock only external boundaries (network, database, clock, file system) — use the real code everywhere else.
- One test = one behavior, structured Arrange / Act / Assert.
- Every variant a THEN names gets its own test — e.g. "pays by card, PayPal or bank transfer" = 3 tests.
- When TDD is ON — full cycle: the change's `proposal.md` → Scope · inline: always ON — NEVER keep a test that did not fail first.
- A test fails because of a bug in the code: fix the code, NEVER the test.

## Quality Gates — Run in every task close
Commands live in `.claude/gates.conf`. Run them only through `bash .claude/scripts/gates.sh`, from the repo root — it formats the files in place, then runs lint → build → tests → frs → audit in this order, stops at the first failure and prints one line.

| Mode | Command | When |
|------|---------|------|
| Scoped | `bash .claude/scripts/gates.sh scoped <changed files>` | each task close |
| Full | `bash .claude/scripts/gates.sh full` — adds `frs`: every FR in `specs/current/` has a test and a unique ID | feature close · inline change |
| FR | `bash .claude/scripts/gates.sh fr <FR-ID>` | RED check · before setting `test: ✅` |

- Report the line the script prints exactly as printed — NEVER paraphrase it.
- NEVER run a gate command outside the script — except the single failing test while fixing it.
- `❌`: stop, quote the lines the script printed, propose options — NEVER continue with a failing gate, NEVER self-fix silently.
- Status: `✅` pass · `❌ <gate>` fail · `⏭️` skipped · `-` pending
- Gates format: `lint ✅ · build ✅ · tests ✅ (X passing) · frs ✅ (N) · audit ⏭️` — `frs` only in Full mode — the script prints it.
- Docs-only change (`.md` files): re-read the edited files against `.claude/sdd/doc-rules.md` — the script prints `⏭️` for every gate.

## Chat Replies
- Reply in the fewest words that stay unambiguous — no greeting, no restating the request, no closing summary.
- When a skill has an Output Contract: emit it and add nothing around it.
- NEVER shorten FRs, change folders, questions to the human, or the options after a failing gate.
## Compact instructions
When compacting, keep: the active change folder path, its Next step, the staged files, and the last line `gates.sh` printed with its failing lines.
