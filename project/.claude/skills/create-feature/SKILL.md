---
name: create-feature
description: "Trigger: create feature, new feature, implement feature, HU, go, resume feature. Run the SDD cycle for substantial work: explore, document, implement, close."
---

## Activation Contract

Load this skill when Change Size classifies the work as full cycle, or on "go" / "go up to ID-00N" to resume the active feature.

Do not load it for inline work — follow Spec Rules and still run Quality Gates.

## Hard Rules

- NEVER write code before `specs/changes/<feature>/` exists and the user approves it — the request itself is NEVER approval, even when it pre-approves dependencies or says "go".
- NEVER edit `specs/current/` before the feature closes — deltas live in `specs/changes/<feature>/specs/` until the merge.
- NEVER write code in Approach — names, types and responsibilities only.
- NEVER expand scope without explicit user authorization.
- ALWAYS explore existing code before proposing anything.
- ALWAYS follow Working Protocol — NEVER restate or shorten it.

## Decision Gates

| Situation | Action |
|-----------|--------|
| Ambiguous goal | Ask ONE question at a time until the goal is concrete |
| Feature partially exists | Map what exists before writing RFs |
| Task has no acceptance criteria | Define it before implementing |
| Task names something Approach does not | Complete Approach before listing the task |
| Approach decision affects the whole project | Create an ADR from `docs/decisions/000-template.md` — link it in Approach |
| Scope grows mid-feature | Pause, report, request authorization |
| Accepted change mid-feature | Update the delta spec and `tasks.md` in the same change folder — wait for approval |
| Capability has no spec file | Agree its prefix in step 2 — create `specs/current/<capability>/spec.md` from `templates/spec.md` at the merge |
| RF is REMOVED | Add a task that deletes its tests |
| Human approves a range ("go up to ID-00N") | Dispatch one implementer per task, in order — each waits for the previous result |
| Implementer returns `blocked` | Stop — and stop the batch — relay its contract — back to per-task approval |
| Batch ends | Report tasks done — `Next: <Next step> — /clear → go` — wait |
| Any reply about an active feature in a new session or after `/clear` | Find the active change folder with `ls -d specs/changes/*/ | grep -v archive` — read only its `tasks.md` → "fix: <what>": dispatch it for the last task (step 8) · otherwise: continue from Progress → `Next step` (step 8 or 10) |
| Technical blocker | Report with options — NEVER assume a solution |
| No git repo | Skip branch and staging — report `no repo` — Next line: `/clear → go` |

## Execution Steps

1. Read `docs/architecture.md`, the `specs/current/<capability>/spec.md` files the feature touches, and the related code — when the code spans more than one slice, explore it with the `Explore` subagent (`.claude/agents/explore.md`) and keep only its summary.
2. Confirm goal, scope IN/OUT, TDD ON/OFF, RF deltas (ADDED / MODIFIED / REMOVED — `<RF-ID> — The system MUST …` + GIVEN/WHEN/THEN) and constraints.
3. Design Approach from the RF deltas and the explored code: slices, types, state, logic placement, non-obvious decisions — every ADDED or MODIFIED RF maps to a line.
4. Derive the tasks from Approach — every task lists the RFs it `covers`, every ADDED or MODIFIED RF is covered by a task — the fewest tasks that each leave a working, reviewable diff: group RFs owned by the same rule or component, NEVER one task per RF by default.
5. Create the folder `specs/changes/<feature-name>/` from `templates/change/`: `proposal.md` (Goal, Scope, Constraints) · `design.md` (Approach) · `tasks.md` (Tasks, Progress) · one `specs/<capability>/spec.md` with the RF deltas per capability touched.
6. End the turn: reply with the change folder path and `approve?` — NEVER dispatch a task in the same turn that wrote the change folder.
7. Create branch `feat/<feature-name>` before the first staged change, unless there is no repo.
8. Dispatch ONE task to the `implementer` subagent (`.claude/agents/implementer.md`) — message: the change folder path and the task ID, or `fix: <what>` and the last task ID — run it in the foreground and wait for its result — NEVER implement a task yourself.
   - Relay its contract verbatim, then `Next: <Next step> — /clear → go` — the implementer already ran the close sequence up to staging.
   - On the human's next message — inside an approved batch: dispatch the next task · "go": approves and dispatches Progress → `Next step` · "fix: <what>": dispatch it for the last task · anything else: reply `Next: <Next step> — /clear → go` — stop and wait.
9. Repeat step 8 only after explicit approval — per task or as a batch.
10. When every task is `[x]` and every ADDED or MODIFIED RF `test:` is `✅`: if Progress → `Next step` is `review gaps (<N>)`, "go" accepts them — NEVER dispatch the reviewer again — otherwise dispatch the `reviewer` subagent (`.claude/agents/reviewer.md`) once with the change folder path — gaps: set Progress → `Next step: review gaps (<N>)`, report its contract with options — stop and wait ("fix: <what>" → step 8 · "go" accepts the gaps) — no gaps or gaps accepted: run Quality Gates in Full mode — then merge each `specs/changes/<feature-name>/specs/<capability>/spec.md` into `specs/current/<capability>/spec.md` — ADDED: append and advance `Next ID` · MODIFIED: replace the RF and its scenarios · REMOVED: delete the RF.
11. In `tasks.md` set Progress to `feature closed` and `Merged into specs: yes` → `git mv specs/changes/<feature-name> specs/changes/archive/<YYYY-MM-DD>-<feature-name>` → stage → propose the feature's single commit message per Working Protocol — one body line per task ID.

## Output Contract

Per task: the implementer's contract, then:
```
Next: <Next step> — /clear → go
```

Final:
```
[Feature closed] <feature-name>
Tasks: X/X · Files modified: X · RFs: X/X ✅
Review: no gaps | <N> gaps accepted
<line printed by gates.sh full>
Specs merged: <files>
Archived: specs/changes/archive/<YYYY-MM-DD>-<feature-name>
Commit message: feat(<scope>): description
Next: commit → /clear
```
