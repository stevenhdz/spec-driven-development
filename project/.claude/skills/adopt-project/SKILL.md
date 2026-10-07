---
name: adopt-project
description: "Trigger: adopt, adopt project, existing project, onboard this repo. Adapt this setup to existing code after the human confirms: fill CLAUDE.md and architecture from the code, deny secrets."
---

## Activation Contract

Load this skill when the human says "adopt" in a repo that already has code and still has `[placeholders]` in `CLAUDE.md` or `docs/architecture.md`.

Do not load it for a new, empty project — the human fills the placeholders by hand. Do not load it to build or change features — use Change Size.

## Hard Rules

- NEVER edit source code, tests or tool config — write only `CLAUDE.md`, `docs/architecture.md` and `.claude/settings.json`.
- NEVER invent a value — every filled placeholder comes from a file on disk or from the human's answer.
- NEVER propose restructuring the code — describe the structure that exists.

## Decision Gates

| Situation | Action |
|-----------|--------|
| A placeholder has no evidence on disk | Ask ONE question — stop and wait |
| Code spans more than one slice or module | Map it with the `explorer` subagent (`.claude/agents/explorer.md`) — keep only its summary |
| Structure is not vertical slice | Rename the Layer Structure heading to the real pattern — describe it as is — add an "Existing structure kept" row to architecture Decisions |
| A path looks secret or bulky (env files, keys, build output, lockfiles, caches) | Add it to `deny` in `.claude/settings.json` by name — NEVER open it |

## Execution Steps

1. Ask "Adapt `CLAUDE.md`, `docs/architecture.md` and `.claude/settings.json` to this code? yes / no" — stop and wait. Anything but "yes": stop.
2. Read only manifests and tool config: scripts, dependencies, lint, test and build settings.
3. Map the code structure: folders, entry points, slices or modules, outbound systems, persistence.
4. Fill every `[placeholder]` in `CLAUDE.md` — commands in Quality Gates and Spec Rules MUST exist in the repo.
5. Fill every `[placeholder]` in `docs/architecture.md`.
6. Update `deny` in `.claude/settings.json`.
7. Run `grep -nE '\[[^]]{2,}\]' CLAUDE.md docs/architecture.md` — it MUST print nothing — re-read the edited files against `docs/doc-rules.md`.
8. Stage the edited files — propose `chore: adopt spec-driven development` — stop and wait.

## Output Contract

```
[Adopted] <project name>
Stack: <language · framework · test runner · lint>
Structure: <pattern> — slices: <names>
Denied: <paths added>
Staged: <files>
Commit message: chore: adopt spec-driven development
Next: commit → request a change
```

## References

- `docs/architecture.md` — sections to fill
