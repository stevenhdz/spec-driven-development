# Documentation Rules

Applies to every `.md` in this project.

- English, imperative, one idea per line. Delete anything that does not change behavior.
- `NEVER` / `ALWAYS` / `MUST` in uppercase for mandatory rules only — no "should", "try to", "ideally".
- `CLAUDE.md` owns global rules. Other docs name its section (e.g. Quality Gates) — NEVER restate it.
- Every path or layer named in a doc MUST exist in Layer Structure or on disk.

## Status legend and Gates format
`CLAUDE.md` → Quality Gates.

## Templates
`templates/` — `spec.md` · `change.md` · `skill.md`.
ADRs — `docs/decisions/000-template.md`.
Skill sections follow `templates/skill.md` in its order — omit References if empty.
