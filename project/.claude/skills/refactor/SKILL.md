---
name: refactor
description: "Trigger: refactor, clean up, restructure, rename, extract, simplify. Change code structure without changing observable behavior: RFs and tests stay untouched, tests stay green."
---

## Activation Contract

Load this skill when the human asks to change code structure with no observable behavior change, or says "refactor: <what>".

Do not load it when the request changes what a user sees, what an API returns or what a command prints — use Change Size. Do not load it to improve performance — use `.claude/skills/optimize/SKILL.md`.

## Hard Rules

- NEVER change observable behavior — NEVER edit `specs/`.
- NEVER edit, delete or skip an existing test — only its import paths when the refactor moves a file.
- NEVER refactor code whose covering tests do not pass first.
- NEVER add a dependency, a feature or a behavior fix inside a refactor.
- ALWAYS apply one move per step (rename, extract, inline, move) and run scoped Quality Gates after each step.
- ALWAYS follow Working Protocol — NEVER restate or shorten it.

## Decision Gates

| Situation | Action |
|-----------|--------|
| Code to refactor has no covering tests | Stop — propose adding tests first as an inline change — wait |
| Covering tests fail before starting | Stop — report the failing lines — NEVER refactor on red |
| A test fails after a step | Revert the step — NEVER fix the test — report with options |
| Refactor needs a behavior change | Stop — report — route that change through Change Size |
| Code spans more than one slice | Map it with the `Explore` subagent (`.claude/agents/explore.md`) — keep only its summary |
| Decision affects the whole project | Create an ADR from `docs/decisions/000-template.md` |
| Scope grows mid-refactor | Pause, report, request authorization |
| No git repo | Skip branch and staging — report `no repo` |

## Execution Steps

1. Read the code to refactor and the tests that cover it.
2. Run the Tests gate scoped to that code — it MUST pass.
3. Propose the plan: goal, scope IN/OUT, numbered steps — stop and wait for approval. Approval covers every step in the plan.
4. Create branch `refactor/<name>` before the first staged change, unless there is no repo.
5. Apply ONE step → run Quality Gates in Scoped mode → repeat until every step is done.
6. Run the Working Protocol close sequence with Quality Gates in Full mode — propose the commit message `refactor(<scope>): description`.

## Output Contract

Plan:
```
Refactor plan — <goal>
Scope IN: <what> · OUT: <what>
Steps: 1. <move> · 2. <move> · …
```

Final:
```
[Refactor done] <name>
Steps: X/X · Files modified: X · RFs: untouched · Tests: untouched
Gates (full): lint ✅ · build ✅ · tests ✅ (X passing) · audit ⏭️
Staged: <files>
Commit message: refactor(<scope>): description
Next: commit → /clear
```
