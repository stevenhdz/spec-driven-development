---
name: create-feature
description: "Trigger: create feature, new feature, implement feature, HU, go, resume feature. Run the SDD cycle for substantial work: explore, document, implement, close."
---

## Activation Contract

Load this skill when Change Size classifies the work as full cycle, or on "go" / "go up to ID-00N" / "go all" to resume the active feature.

Do not load it for inline work — follow Spec Rules and still run Quality Gates.

## Hard Rules

- NEVER write code before `specs/changes/<feature>/` exists and the user approves it — the request itself and the "yes" to `research ok?` are NEVER approval of the change folder, even when it pre-approves dependencies or says "go".
- NEVER edit `specs/current/` before the feature closes — deltas live in `specs/changes/<feature>/specs/` until the merge.
- NEVER write code in Approach — names, types and responsibilities only.
- NEVER expand scope without explicit user authorization.
- NEVER narrow the Request — anything it asks for goes in Scope IN and in an FR — when it conflicts with a rule, ask ONE question before creating the change folder.
- ALWAYS follow Working Protocol — NEVER restate or shorten it.

## Decision Gates

| Situation | Action |
|-----------|--------|
| Ambiguous goal | Ask ONE question at a time until the goal is concrete |
| Feature partially exists | Map what exists before writing FRs |
| Task has no acceptance criteria | Define it before implementing |
| Task names something Approach does not | Complete Approach before listing the task |
| Approach decision affects the whole project | Create an ADR from `.claude/templates/adr.md` — link it in Approach |
| Scope grows mid-feature | Pause, report, request authorization |
| Accepted change mid-feature | Update the delta spec and `tasks.md` in the same change folder — wait for approval |
| Capability has no spec file | Agree its prefix in step 2 — create `specs/current/<capability>/spec.md` from `.claude/templates/spec.md` at the merge |
| FR is REMOVED | Add a task that deletes its tests |
| Human approves a range ("go up to ID-00N" · "go all") | Dispatch one implementer per task, in order, in the same turn — each waits for the previous result — relay each contract without the `Next` line |
| Implementer returns `blocked`, a `Deviation:` line, or no Output Contract (stopped at maxTurns) | Stop — and stop the batch — relay what it returned — back to per-task approval |
| Batch ends | Report tasks done — the staged diff spans them: a fix names its task, `fix: <task-ID> <what>` — `Next: <Next step> — /clear → go` — wait |
| Any reply about an active feature in a new session or after `/clear` | Find the active change folder with `ls -d specs/changes/*/ | grep -v archive` — no `tasks.md` yet: read its `proposal.md` → Request and `design.md` → Research and handle the reply as in step 1 · otherwise read only its `tasks.md` → "fix: <what>": dispatch it for the last task · "fix: <task-ID> <what>": for that task (step 8) · otherwise: continue from Progress → `Next step` (step 8 or 10) |
| Technical blocker | Report with options — NEVER assume a solution |
| No git repo | Skip branch and staging — report `no repo` — Next line: `/clear → go` |

## Execution Steps

1. Read `docs/architecture.md`, the `specs/current/<capability>/spec.md` files the feature touches, and the related code — when the code spans more than one slice, explore it with the `Explore` subagent (`.claude/agents/explore.md`) and keep only its summary — from `.claude/templates/change/` write `specs/changes/<feature-name>/proposal.md` → Request verbatim only, and `design.md` → Research only, from what you found: the code as it is, with `path:line`, no proposals · Approach stays as the template — end the turn: reply with the file path and `research ok?` — NEVER start step 2 in the same turn — "yes": continue from step 2 · anything else: correct Research — stop and wait.
2. Confirm goal, scope IN/OUT, TDD ON/OFF, Gates ON/OFF, FR deltas (ADDED / MODIFIED / REMOVED — `<FR-ID> — The system MUST …` + GIVEN/WHEN/THEN) and constraints.
3. Design Approach from the FR deltas and the explored code: slices, types, state, logic placement, non-obvious decisions — every ADDED or MODIFIED FR maps to a line.
4. Derive the tasks from Approach — every task lists the FRs it `covers`, every ADDED or MODIFIED FR is covered by a task — the fewest tasks that each leave a working, reviewable diff: group FRs owned by the same rule or component, NEVER one task per FR by default.
5. Create the folder `specs/changes/<feature-name>/` from `.claude/templates/change/`: `proposal.md` (Goal, Scope, Constraints — Request is already written) · `design.md` (Approach — Research is already written) · `tasks.md` (Tasks, Progress) · one `specs/<capability>/spec.md` with the FR deltas per capability touched.
6. End the turn: reply with the change folder path, then `⚠️ Request not covered: <quote>` per part of the Request no FR covers, then `approve?` — NEVER dispatch a task in the same turn that wrote the change folder.
7. Create the branch per `CLAUDE.md` → Working Protocol → Branch name, type `feat`, before the first staged change, unless there is no repo.
8. Dispatch ONE task to the `implementer` subagent (`.claude/agents/implementer.md`) — message: the change folder path and the task ID, or `fix: <what>` and the task ID it names, else the last task ID — run it in the foreground and wait for its result — NEVER implement a task yourself.
   - Relay its contract verbatim, then — outside a batch — `Next: <Next step> — /clear → go` — the implementer already ran the close sequence up to staging.
   - On the human's next message — "go": approves and dispatches Progress → `Next step` · "fix: <what>": dispatch it for the last task · "fix: <task-ID> <what>": for that task · anything else: reply `Next: <Next step> — /clear → go` — stop and wait.
9. Repeat step 8 only after explicit approval — per task or as a batch.
10. When every task is `[x]` and every ADDED or MODIFIED FR `test:` is `✅`: if Progress → `Next step` is `review gaps (<N>)`, "go" accepts them — NEVER dispatch the reviewer again — otherwise dispatch the `reviewer` subagent (`.claude/agents/reviewer.md`) once with the change folder path — no Output Contract (stopped at maxTurns): report it — stop and wait — gaps: set Progress → `Next step: review gaps (<N>)`, report its contract with options — stop and wait ("fix: <what>" → step 8 · "go" accepts the gaps) — no gaps or gaps accepted: merge each `specs/changes/<feature-name>/specs/<capability>/spec.md` into `specs/current/<capability>/spec.md` — ADDED: append and advance `Next ID` · MODIFIED: replace the FR and its scenarios · REMOVED: delete the FR — then run Quality Gates in Full mode — then update `docs/architecture.md` only where the change made it stale: a created slice → §2 Slices · `design.md` → a Decision that binds future features → §5 Decisions.
11. In `tasks.md` set Progress to `feature closed` and `Merged into specs: yes` → `git mv specs/changes/<feature-name> specs/changes/archive/<YYYY-MM-DD>-<feature-name>` → stage → propose the feature's single commit message per Working Protocol — one body line per task ID.

## Output Contract

Per task: the implementer's contract, then — outside a batch or when it ends:
```
Next: <Next step> — /clear → go
```

Final:
```
[Feature closed] <feature-name>
Tasks: X/X · Files modified: X · FRs: X/X ✅
Review: no gaps | <N> gaps accepted
<line printed by gates.sh full>
Specs merged: <files>
Architecture: <§2 · §5 updated> | unchanged
Archived: specs/changes/archive/<YYYY-MM-DD>-<feature-name>
Commit message: <per Working Protocol, type feat>
Next: commit → /clear
```
