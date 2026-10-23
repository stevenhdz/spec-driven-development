---
name: refactor
description: "Trigger: refactor, optimize, clean up, speed up, no behavior change. Change code without changing observable behavior: plan, one step at a time, tests untouched."
---

## Activation Contract

Load this skill when Change Size finds no observable behavior change in code, or on "refactor: <what>" / "optimize: <what>".

Do not load it for styling, docs or chore changes, or when the change needs an FR.

## Hard Rules

- NEVER edit, delete or skip a test — only its import paths when a file moves.
- NEVER add a dependency, a feature or a behavior fix inside.
- NEVER claim an improvement without a measured before → after.

## Decision Gates

| Situation | Action |
|-----------|--------|
| Covering tests missing or failing | Propose adding them as an inline change first — wait |
| Step needs a behavior change | Stop — route it through Change Size |
| A test fails or the metric does not improve | Revert to the last step's commit — NEVER fix the test — report it |

## Execution Steps

1. Confirm the covering tests pass · optimize: agree the metric and its measure command, record the baseline before any code.
2. Propose the plan — goal, scope IN/OUT, numbered steps · optimize: metric and baseline — stop and wait — approval covers every step.
3. One step at a time → scoped Quality Gates · optimize: measure after each step — commit each passing step, so a failing later step reverts to the last commit.
4. Close with the close sequence and Quality Gates in Full mode — branch and commit type `refactor` · `perf`.

## Output Contract

```
Refactor done — <goal> | Optimize done — <metric>: <before> → <after>
<line printed by gates.sh full>
Commits: <N> — one per step, type refactor | perf
```
