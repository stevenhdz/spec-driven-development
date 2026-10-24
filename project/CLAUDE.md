# Rules — Spec Driven Development
<!-- Spec Driven Development by stevenhdz · https://github.com/stevenhdz/spec-driven-development — framework rules: `install.sh --update` overwrites this file. Your project values live in `.claude/project.md`. -->

@.claude/project.md

## Change Size
Classify every request before touching code.

| Full cycle (`.claude/skills/create-feature/SKILL.md`) if ANY is true | Inline if ALL are true |
|----------------------------------------------------------------------|------------------------|
| Removes an FR | Adds or modifies at most one FR, in an existing spec file — or none |
| Adds or modifies more than one FR | Removes no FR |
| Needs a new spec file | Touches one module only |
| Touches more than one module | Creates no module |
| Creates a module | Adds no dependency |
| Adds a dependency | |

- Module: the unit `.claude/project.md` → Layer Structure defines (e.g. a slice, a layer, a package).
- The human's word wins: "as a feature" or "inline" overrides the table.
- If inline work grows past the table: stop, report, switch to the full cycle.
- No observable behavior change in code: skip the table — load `.claude/skills/refactor/SKILL.md`.
- Only `.md` files change: skip the table — follow Quality Gates → Docs-only change.
- State the classification before starting: `Size: inline — <reason>`, `Size: full cycle — <reason>`, `Size: refactor — <reason>`, `Size: optimize — <reason>` or `Size: docs — <reason>`.

## Working Protocol
The human approves every step, so these rules hold even when a shortcut looks safe.

- NEVER start a new task without explicit approval — per task ("yes" or "go") or as a batch ("go up to ID-00N" · "go all" = up to the last task) — silence is not approval
- Any reply about an active feature ("go", "yes", "fix: <what>", "go up to ID-00N", "go all") in a new session or after `/clear`: load `.claude/skills/create-feature/SKILL.md` first
- Commit message and branch name: `.claude/project.md` — commit types `feat | fix | refactor | perf | test | docs | chore` · branch types `feat` full cycle · `refactor` · `perf` — ask for the ticket ID when the format has one
- Commit each approved task — "go" commits it · inside a batch: each task commits when it passes, the batch approval covers it — full cycle: the description starts with the task ID · inline: on the current branch — NEVER push: the PR squash-merges the branch into one commit
- Run the task close sequence after every task and every inline change:
  ```
  1. Run Quality Gates
  2. Full cycle only: update the change folder — the implementer does it
  3. git add <files> — stop and wait — full cycle: the implementer stages and returns, the main session relays and waits — inside a batch: commit and continue, the human reviews the batch's commits when it ends
     The human reviews `git diff --staged` and replies "go" → commit, or "fix: <what>" (after a batch: "fix: <task-ID> <what>") → fix → back to step 1
  ```
- If something is unclear: ask ONE specific question — stop and wait

## Spec Rules — SDD
- `specs/current/<capability>/spec.md` is the source of truth for current behavior — one folder per capability, start from `.claude/templates/spec.md`.
- FR ID: `<PREFIX>-NN` (e.g. `ORDER-01`) — prefix unique per spec file, number taken from its `Next ID`.
- NEVER reuse or renumber an FR ID — tests and history point at it — except a duplicate the `frs` gate reports after a merge: renumber the FR your branch added, with its tests, from the file's `Next ID`.
- FRs describe behavior observable from outside: what a user sees, what an API returns, what a command prints.
- FRs cover everything the request makes visible — layout (e.g. "a list sorted by date"), messages and controls — not only the logic — and nothing it does not.
- A broad request (e.g. "any error", "invalid input") must become one scenario per input it names and per way that input can be wrong: wrong type, wrong shape, missing field, boundary value — never only the cases it lists as examples, never an input it does not name.
- NEVER change observable behavior before its FR is written — the FR is what the human approves:
  - Full cycle: the FR goes in the change folder's delta spec (`specs/<capability>/spec.md`) — approved before any code.
  - Inline: add or edit the FR in `specs/current/<capability>/spec.md` first — a new FR takes the file's `Next ID` and advances it — then test, then code — stage all three together.
- No observable behavior change (refactor, styling, docs, chore): NEVER edit FRs.
- Start the name of a test that covers an FR with its FR ID, in the form `.claude/project.md` → Test name gives.
- Check an FR with `bash .claude/scripts/gates.sh fr <FR-ID>` — mark `test: ✅` only when it passes and every GIVEN/WHEN/THEN has a test.

## Hard Rules

- Architecture, code and testing rules live in `.claude/rules/` — each loads when you read or edit a file its `paths:` match.

### Scope
- Build only what the request names — no feature, screen, field, option, setting or message it does not ask for — anything else goes in Scope OUT, or in ONE question
- Simple, never fragile — not extra: every input the requested behavior takes gets one error path, never a crash (one FR, one scenario per way the input can be wrong) · existing behavior and data keep working
- The simplest solution that works (KISS · YAGNI) — in FRs, Approach and code: no layer, file, type or abstraction no FR needs yet

### Dependencies and secrets
- NEVER add a dependency without explicit approval — supply-chain risk — first check it in its registry (`npm view` · `pip index versions`) and show name, version, publish date, weekly downloads, repo — flag one not found, under 30 days old, rarely downloaded or named like a popular one, and propose a known alternative
- NEVER hardcode a secret — read it from an environment variable and document its name in `.env.example`
- NEVER read, print or work around a file denied in `.claude/settings.json` — if a task needs a value from one, ask the human
- NEVER stage a denied file — it would commit a credential — except a lockfile: stage it by path, unread, together with its manifest

### Docs
- Every `.md` follows `.claude/doc-rules.md` — new docs start from their template

## Quality Gates — Run in every task close
Run gates only through `bash .claude/scripts/gates.sh`, from the repo root — except the single failing test while fixing it — commands live in `.claude/gates.conf` — it stops at the first failure and prints one line.

| Mode | Command | When |
|------|---------|------|
| Scoped | `bash .claude/scripts/gates.sh scoped <changed files>` | each task close |
| Full | `bash .claude/scripts/gates.sh full` — adds `frs`: every FR in `specs/current/` has a test and a unique ID · in a PR, `commits`: each subject matches `COMMIT_PATTERN` | feature close · inline change |

- A `git commit` runs `gates.sh scoped` on the files it commits through a hook (`.claude/hooks/gate-commit.sh`) — blocked on ❌.
- `❌`: stop, quote the lines the script printed, propose options — NEVER continue with a failing gate, NEVER self-fix silently.
- Docs-only change (`.md` files): re-read the edited files against `.claude/doc-rules.md` — `gates.sh scoped` prints `⏭️` for every gate.

## Chat Replies
- Reply in the fewest words that stay unambiguous — no greeting, no restating the request, no closing summary.
- When a skill has an Output Contract: emit it and add nothing around it.
- Do not shorten FRs, change folders, questions to the human, or the options after a failing gate.
## Compact instructions
When compacting, keep: the active change folder path, its Next step, the staged files, and the last line `gates.sh` printed with its failing lines.
