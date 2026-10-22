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
| Code spans more than one slice or module | Map it with the `Explore` subagent (`.claude/agents/explore.md`) — keep only its summary |
| Structure is not vertical slice | Rename the `.claude/project.md` → Layer Structure heading to the real pattern — describe it as is — add an "Existing structure kept" row to architecture Decisions |
| A path looks secret (env files, keys, credentials) | Add it to `deny` in `.claude/settings.json` as both `Read(<path>)` and `Edit(<path>)` — the `protect-secrets` hook blocks every shell command that names an `Edit` entry — NEVER open it |
| A path looks bulky (build output, lockfiles, caches) | Add it to `deny` as `Read(<path>)` only — NEVER as `Edit`, or the hook blocks staging it |

## Execution Steps

1. Ask "Adapt `.claude/project.md`, `docs/architecture.md`, `.claude/gates.conf` and `.claude/settings.json` to this code? yes / no" — stop and wait. Anything but "yes": stop.
2. Read only manifests and tool config: scripts, dependencies, lint, test and build settings.
3. Map the code structure: folders, entry points, slices or modules, outbound systems, persistence.
4. Fill every `[placeholder]` in `.claude/project.md` and `.claude/gates.conf` — every command in `gates.conf` MUST exist in the repo — no formatter in the repo: leave `FORMAT_*` empty, NEVER add one — `FORBIDDEN` from `.claude/project.md` → Forbidden plus the stack's ignore comments — `COMMIT_PATTERN` from `.claude/project.md` → Commit message — `TEST_FORBIDDEN` from the test runner and `CLAUDE.md` → Testing Rules.
5. Fill every `[placeholder]` in `docs/architecture.md`.
6. Update `deny` in `.claude/settings.json`.
7. Run `grep -nE '\[[^]]{2,}\]' .claude/project.md docs/architecture.md .claude/gates.conf` — it MUST print nothing — re-read the edited files against `.claude/doc-rules.md`.
8. Run `bash .claude/scripts/gates.sh full --no-format` — report the line it prints — a failing gate is reported, NEVER fixed.
9. Stage the edited files — propose `chore: adopt spec-driven development` — stop and wait.

## Output Contract

```
[Adopted] <project name>
Stack: <language · framework · test runner · lint>
Gates: <line printed by gates.sh full>
Structure: <pattern> — slices: <names>
Denied: <paths added>
Staged: <files>
Commit message: chore: adopt spec-driven development
Next: commit → if `FORMAT_*` is filled: `bash .claude/scripts/gates.sh full` once, commit it as `style: format codebase` → request a change
```

## References

- `docs/architecture.md` — sections to fill
