# Documentation Rules

Applies to every `.md` in this project.

- English, imperative, one idea per line. Delete anything that does not change behavior.
- `NEVER` / `ALWAYS` / `MUST` in uppercase for mandatory rules only — no "should", "try to", "ideally".
- `CLAUDE.md` owns global rules. Other docs name its section (e.g. Quality Gates) — NEVER restate it.
- Every path or layer named in a doc MUST exist in Layer Structure or on disk.

## Status legend
`✅` pass · `❌ <gate>` fail · `⏭️` skipped · `-` pending

Gates format: `lint ✅ · build ✅ · tests ✅ (X passing) · audit ⏭️`

## Skill sections — in this order
Frontmatter (`name`, `description: "Trigger: …"`) → Activation Contract (Load / Do not load) → Hard Rules → Decision Gates → Execution Steps → Output Contract (code block) → References (omit if empty)
