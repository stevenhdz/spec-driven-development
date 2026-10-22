# Documentation Rules
<!-- Spec Driven Development by stevenhdz · https://github.com/stevenhdz/spec-driven-development — framework file: `install.sh --update` overwrites it. -->

Applies to every `.md` in this project.

- English, imperative, one idea per line. Delete anything that does not change behavior.
- `NEVER` / `ALWAYS` / `MUST` in uppercase only for a rule whose violation is costly or hard to undo (approval, credentials, tests, FR IDs) — give its reason when it is not obvious · plain imperative for the rest — no "should", "try to", "ideally" · FRs keep RFC 2119 `MUST`.
- `CLAUDE.md` owns global rules · `.claude/project.md` owns project values and project rules. Other docs name their section (e.g. Quality Gates) — NEVER restate it.
- Every path or layer named in a doc MUST exist in `.claude/project.md` → Layer Structure or on disk.
- A rule that applies only to some paths goes in `.claude/rules/<topic>.md` with a `paths:` frontmatter — NEVER in `CLAUDE.md`.
- Notes for humans inside `CLAUDE.md` go in `<!-- -->` — Claude Code strips them before loading.

## Status legend
`CLAUDE.md` → Quality Gates.

## Templates
`.claude/templates/` — `spec.md` · `change/` (`proposal.md` · `design.md` · `spec.md` · `tasks.md`) · `skill.md` · `adr.md` (ADRs, saved in `docs/decisions/`).
Skill sections follow `.claude/templates/skill.md` in its order — omit References if empty.
