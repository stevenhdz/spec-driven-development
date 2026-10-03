---
name: skill-name
description: "Trigger: [words the user will say]. [What the skill does in one line]."
---

## Activation Contract

Load this skill when [exact situation or words].

Do not load it when [situation that looks similar but is not].

## Hard Rules

- NEVER [critical restriction]
- ALWAYS [critical obligation]

## Decision Gates

| Situation | Action |
|-----------|--------|
| [case A] | [do X] |
| [case B] | Ask the user |

## Execution Steps

1. [Verify condition]
2. [Execute action]
3. Run Quality Gates.

## Output Contract

```
[Result title] — [key data]
Gates: lint ✅ · build ✅ · tests ✅ (X passing) · audit ⏭️
```

## References

- [file other than CLAUDE.md] — [why]
