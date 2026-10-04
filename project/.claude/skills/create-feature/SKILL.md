---
name: create-feature
description: "Trigger: create feature, new feature, implement feature, HU. Run the SDD cycle for substantial work: explore, document, implement, close."
---

## Activation Contract

Load this skill when Change Size classifies the work as full cycle.

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
| Capability has no spec file | Agree its prefix in step 2 — create the file from `specs/current/spec-template.md` at the merge |
| RF is REMOVED | Add a task that deletes its tests |
| Human approves a range ("go up to ID-00N") | Run it as a batch — each task keeps its own gates, task line and commit |
| Inside a batch: gate fails, deviation, question, scope change, or `git log -1` lacks the previous task's commit | Stop the batch — back to per-task approval |
| Batch ends | Report tasks done / commits / next task — wait |
| Technical blocker | Report with options — NEVER assume a solution |
| No git repo or user said `no commit` | Skip branch and staging — report `no repo` |

## Execution Steps

1. Read `docs/architecture.md`, the `specs/current/` files the feature touches, and the related code — when the code spans more than one slice, explore it with a subagent and keep only its summary: files, public API, current behavior.
2. Confirm goal, scope IN/OUT, TDD ON/OFF, RF deltas (ADDED / MODIFIED / REMOVED — `<RF-ID> — The system MUST …` + GIVEN/WHEN/THEN) and constraints.
3. Design Approach from the RF deltas and the explored code: slices, types, state, logic placement, non-obvious decisions — every ADDED or MODIFIED RF maps to a line.
4. Derive the tasks from Approach — every task lists the RFs it `covers`, every ADDED or MODIFIED RF is covered by a task.
5. Create `specs/changes/<feature-name>.md` from `specs/changes/change-template.md` with deltas, Approach and tasks.
6. Stop and wait for approval of the change doc.
7. Create branch `feat/<feature-name>` before the first staged change, unless there is no repo.
8. Implement ONE task → run the Working Protocol close sequence.
9. Repeat step 8 only after explicit approval — per task or as a batch.
10. When every task is `[x]` and every ADDED or MODIFIED RF `test:` is `✅`: merge the deltas into `specs/current/` — ADDED: append and advance `Next ID` · MODIFIED: replace the RF and its scenarios · REMOVED: delete the RF.
11. Set Progress to `feature closed` and `Merged into specs: yes` → stage → propose `docs(specs): merge <feature-name> into specs` per Working Protocol.

## Output Contract

Per task:
```
[ID-00X done] — covers: <RF-ID>
Gates: lint ✅ · build ✅ · tests ✅ (X passing) · audit ⏭️
Staged: <files>
Commit message: feat(<scope>): description
```

Final:
```
[Feature closed] <feature-name>
Tasks: X/X · Commits: X · Files modified: X · RFs: X/X ✅
Specs merged: <files>
```
