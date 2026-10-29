---
name: adopt
description: "Adapt this setup to existing code after the human confirms: fill project.md, architecture and gates from the code, deny secrets."
disable-model-invocation: true
---

## Activation Contract

Run when the human types `/adopt` in a repo that already has code and still has `[placeholders]` in `.claude/project.md`, `docs/architecture.md` or `.claude/gates.conf`.

Do not load it for a new, empty project — the human fills the placeholders by hand. Do not load it to build or change features — use Change Size.

## Hard Rules

- NEVER edit source code, tests or tool config — write only `.claude/project.md`, `docs/architecture.md`, `.claude/gates.conf` and `.claude/settings.json`.
- NEVER invent a value — every filled placeholder comes from a file on disk or from the human's answer.
- NEVER propose restructuring the code — describe the structure that exists.

## Decision Gates

| Situation | Action |
|-----------|--------|
| A placeholder has no evidence on disk | Ask ONE question — stop and wait |
| Code spans more than one module | Map it with the `Explore` subagent (`.claude/agents/explore.md`) — keep only its summary |
| Structure is not vertical slice | Replace `.claude/project.md` → Layer Structure and its heading with the real pattern — describe it as is, with its Module line — add an "Existing structure kept" row to architecture Decisions |
| A path looks secret (env files, keys, credentials) | Add it to `deny` in `.claude/settings.json` as both `Read(<path>)` and `Edit(<path>)` — the `protect-secrets` hook blocks every shell command that names an `Edit` entry — NEVER open it |
| A path looks bulky (build output, lockfiles, caches) | Add it to `deny` as `Read(<path>)` only — NEVER as `Edit`, or the hook blocks staging it |

## Execution Steps

1. Ask "Adapt `.claude/project.md`, `docs/architecture.md`, `.claude/gates.conf` and `.claude/settings.json` to this code? yes / no" — stop and wait. Anything but "yes": stop.
2. Read only manifests and tool config: scripts, dependencies, lint, test and build settings.
3. Map the code structure: folders, entry points, modules, outbound systems, persistence.
4. Fill every `[placeholder]` in `.claude/project.md` and `.claude/gates.conf` — every command in `gates.conf` MUST exist in the repo — no formatter in the repo: leave `FORMAT_*` empty, NEVER add one — `FORBIDDEN` from `.claude/project.md` → Forbidden plus the stack's ignore comments — `FORBIDDEN_EXCLUDE` from the scaffold and tool config files that need a forbidden form — `COMMIT_PATTERN` from `.claude/project.md` → Commit message — `TEST_FORBIDDEN` from the test runner and `.claude/rules/testing.md` — `TEST_PATH` from the repo's own test file paths — no test files yet: from the test runner's default naming.
5. Fill every `[placeholder]` in `docs/architecture.md`.
6. Update `deny` in `.claude/settings.json`.
7. Run `grep -nE '\[[^]]{2,}\]' .claude/project.md docs/architecture.md .claude/gates.conf` — it MUST print nothing — re-read the edited files against `.claude/doc-rules.md`. Then run `bash .claude/scripts/gates.sh test-paths` — it MUST print `✅` and list only test files — `❌` or a source file listed: a test file → fix `TEST_PATH` · a source file → add it to `TEST_PATH_EXCLUDE` — rerun.
8. Run `bash .claude/scripts/gates.sh full --no-format` — report the line it prints — a failing gate is reported, NEVER fixed.
9. Stage the edited files — stop and wait — "go": commit them as `chore: adopt spec-driven development`.

## Output Contract

```
[Adopted] <project name>
Stack: <language · framework · test runner · lint>
Gates: <line printed by gates.sh full>
Tests: <first line printed by gates.sh test-paths> — TEST_PATH: <value, or built-in> · TEST_PATH_EXCLUDE: <value, or none>
Structure: <pattern> — modules: <names>
Denied: <paths added>
Staged: <files>
Next: go → commit `chore: adopt spec-driven development` → if `FORMAT_*` is filled: `bash .claude/scripts/gates.sh full` once, commit it as `style: format codebase` → request a change
```

## References

- `docs/architecture.md` — sections to fill
