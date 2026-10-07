---
name: create-feature
description: "Trigger: create feature, new feature, implement feature, HU, go, resume feature. Run the SDD cycle for substantial work: explore, document, implement, close."
---

## Activation Contract

Load this skill when Change Size classifies the work as full cycle, or on "go" / "go up to ID-00N" to resume the active feature.

Do not load it for inline work — follow Spec Rules and still run Quality Gates.

## Hard Rules

- NEVER write code before `specs/changes/<feature>.md` exists and the user approves it.
- NEVER edit `specs/current/` before the feature closes — deltas live in the change doc until the merge.
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
| Accepted change mid-feature | Update deltas and tasks in the same change doc — wait for approval |
| Capability has no spec file | Agree its prefix in step 2 — create the file from `templates/spec.md` at the merge |
| RF is REMOVED | Add a task that deletes its tests |
| Human approves a range ("go up to ID-00N") | Run it as a batch — each task keeps its own gates, task line and staging — no `/clear` inside the batch |
| Inside a batch: gate fails, deviation, question or scope change | Stop the batch — back to per-task approval |
| Batch ends | Report tasks done — `Next: <Next step> — /clear → go` — wait |
| Any reply about an active feature in a new session or after `/clear` | Read the active change doc (the `specs/changes/*.md` whose Progress is not `feature closed`) — its Approach replaces `docs/architecture.md`; open that only for a question Approach does not answer → "fix: <what>": fix the last task, back to close step 1 · otherwise: continue from Progress → `Next step` (step 8 or 10) |
| Technical blocker | Report with options — NEVER assume a solution |
| No git repo | Skip branch and staging — report `no repo` — Next line: `/clear → go` |

## Execution Steps

1. Read `docs/architecture.md`, the `specs/current/` files the feature touches, and the related code — when the code spans more than one slice, explore it with the `explorer` subagent (`.claude/agents/explorer.md`) and keep only its summary.
2. Confirm goal, scope IN/OUT, TDD ON/OFF, RF deltas (ADDED / MODIFIED / REMOVED — `<RF-ID> — The system MUST …` + GIVEN/WHEN/THEN) and constraints.
3. Design Approach from the RF deltas and the explored code: slices, types, state, logic placement, non-obvious decisions — every ADDED or MODIFIED RF maps to a line.
4. Derive the tasks from Approach — every task lists the RFs it `covers`, every ADDED or MODIFIED RF is covered by a task.
5. Create `specs/changes/<feature-name>.md` from `templates/change.md` with deltas, Approach and tasks.
6. Stop and wait for approval of the change doc.
7. Create branch `feat/<feature-name>` before the first staged change, unless there is no repo.
8. Implement ONE task → run the Working Protocol close sequence, with:
   - Step 2: update the task line in the change doc: `[x]` + gates · covered RFs: set `test: ✅` in Requirement Deltas per Spec Rules · only if the plan changed: add a sub-bullet `deviation: <what>` · Progress → `Next step:` the next task ID, or `merge specs` after the last task.
   - Step 4: on the human's next message — inside an approved batch: continue with the next task · "go": approves and starts Progress → `Next step` · anything else: reply `Next: <Next step> — /clear → go` — stop and wait.
9. Repeat step 8 only after explicit approval — per task or as a batch.
10. When every task is `[x]` and every ADDED or MODIFIED RF `test:` is `✅`: run Quality Gates in Full mode — then merge the deltas into `specs/current/` — ADDED: append and advance `Next ID` · MODIFIED: replace the RF and its scenarios · REMOVED: delete the RF.
11. Set Progress to `feature closed` and `Merged into specs: yes` → stage → propose the feature's single commit message per Working Protocol — one body line per task ID.

## Output Contract

Per task:
```
[ID-00X done] — covers: <RF-ID>
Gates: lint ✅ · build ✅ · tests ✅ (X passing) · audit ⏭️
Staged: <files>
Next: <Next step> — /clear → go
```

Final:
```
[Feature closed] <feature-name>
Tasks: X/X · Files modified: X · RFs: X/X ✅
Gates (full): lint ✅ · build ✅ · tests ✅ (X passing) · audit ⏭️
Specs merged: <files>
Commit message: feat(<scope>): description
Next: commit → /clear
```
