# Documentation Rules
<!-- Framework file — `install.sh --update` overwrites it. -->

Applies to every `.md` in this project.

- English, imperative, one idea per line. Delete anything that does not change behavior.
- `NEVER` / `ALWAYS` / `MUST` in uppercase for mandatory rules only — no "should", "try to", "ideally".
- `CLAUDE.md` owns global rules · `.claude/project.md` owns project values and project rules. Other docs name their section (e.g. Quality Gates) — NEVER restate it.
- Every path or layer named in a doc MUST exist in `.claude/project.md` → Layer Structure or on disk.
- A rule that applies only to some paths goes in `.claude/rules/<topic>.md` with a `paths:` frontmatter — NEVER in `CLAUDE.md`.
- Notes for humans inside `CLAUDE.md` go in `<!-- -->` — Claude Code strips them before loading.

## Status legend and Gates format
`CLAUDE.md` → Quality Gates.

## Templates
`.claude/sdd/templates/` — `spec.md` · `change/` (`proposal.md` · `design.md` · `spec.md` · `tasks.md`) · `skill.md` · `adr.md` (ADRs, saved in `docs/decisions/`).
Skill sections follow `.claude/sdd/templates/skill.md` in its order — omit References if empty.
