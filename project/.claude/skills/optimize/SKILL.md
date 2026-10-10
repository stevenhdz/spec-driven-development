---
name: optimize
description: "Trigger: optimize, performance, faster, slow, reduce size, memory. Improve a measured metric without changing observable behavior: baseline first, keep only steps that improve it, RFs and tests stay untouched."
---

## Activation Contract

Load this skill when the human asks to improve performance, size or resource use with no observable behavior change, or says "optimize: <what>".

Do not load it when the request changes what a user sees, what an API returns or what a command prints — use Change Size. Do not load it to restructure code with no metric to improve — use `.claude/skills/refactor/SKILL.md`.

## Hard Rules

- NEVER change observable behavior — NEVER edit `specs/`.
- NEVER edit, delete or skip an existing test — only its import paths when the optimization moves a file.
- NEVER optimize code whose covering tests do not pass first.
- NEVER touch code before the metric, its measure command and its baseline are recorded.
- NEVER keep a step that does not improve the metric.
- NEVER claim an improvement without a measured before → after.
- NEVER add a dependency, a feature or a behavior fix inside an optimization.
- ALWAYS apply one change per step, run scoped Quality Gates and measure after each step.
- ALWAYS follow Working Protocol — NEVER restate or shorten it.

## Decision Gates

| Situation | Action |
|-----------|--------|
| No metric or no command to measure it | Ask ONE question — stop and wait |
| Measurement varies between runs | Run it several times — use the median — report the run count |
| Code to optimize has no covering tests | Stop — propose adding tests first as an inline change — wait |
| Covering tests fail before starting | Stop — report the failing lines — NEVER optimize on red |
| A test fails after a step | Revert the step — NEVER fix the test — report with options |
| A step does not improve the metric | Revert the step — report it as dropped |
| Optimization needs a behavior change | Stop — report — route that change through Change Size |
| Code spans more than one slice | Map it with the `Explore` subagent (`.claude/agents/explore.md`) — keep only its summary |
| Decision affects the whole project | Create an ADR from `docs/decisions/000-template.md` |
| Scope grows mid-optimization | Pause, report, request authorization |
| No git repo | Skip branch and staging — report `no repo` |

## Execution Steps

1. Read the code to optimize and the tests that cover it.
2. Run the Tests gate scoped to that code — it MUST pass.
3. Agree the metric and its measure command — run it and record the baseline.
4. Propose the plan: goal, scope IN/OUT, metric, baseline, numbered steps — stop and wait for approval. Approval covers every step in the plan.
5. Create branch `perf/<name>` before the first staged change, unless there is no repo.
6. Apply ONE step → run Quality Gates in Scoped mode → measure → keep the step only if the metric improves → repeat until every step is done.
7. Run the Working Protocol close sequence with Quality Gates in Full mode — propose the commit message `perf(<scope>): description`.

## Output Contract

Plan:
```
Optimize plan — <goal>
Scope IN: <what> · OUT: <what>
Metric: <name> — baseline <value> — measured with `<command>`
Steps: 1. <change> · 2. <change> · …
```

Final:
```
[Optimize done] <name>
Steps: X kept · X dropped · Files modified: X · RFs: untouched · Tests: untouched
Metric: <name> <before> → <after>
Gates (full): lint ✅ · build ✅ · tests ✅ (X passing) · audit ⏭️
Staged: <files>
Commit message: perf(<scope>): description
Next: commit → /clear
```
