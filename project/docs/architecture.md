# Architecture

## Layers
```
input ─► [entry layer] ─► [logic layer] ─► result ─► [entry layer] returns it
                               │
                               └─ shapes from [types]

slice = [the unit that holds one feature in the chosen architecture — e.g. feature folder · module · package]
slice ── [public API] ──► other slices · app composition
[shared] ◄── imported by 2+ slices
```

| Layer | Frontend | Backend | CLI |
|-------|----------|---------|-----|
| Entry | UI component | HTTP route / controller | command handler |
| Logic | hook / store | service / use case | function / use case |
| Types | interfaces | DTOs / schemas | types |

## Rules per layer
| Layer | Responsibility | CANNOT |
|-------|---------------|--------|
| Entry | Receive input, call the logic layer, return or render its result | Hold business rules or state logic |
| Logic | Own the slice state and its business rules | Know about the transport (DOM, HTTP, terminal) |
| Types | Shapes and contracts of the slice | Contain runtime logic |
| Public API | The only door into the slice | Be bypassed by another slice |
| `[shared]` | Code used by 2+ slices | Import from a slice |
| App composition | Wire slices together | Hold feature logic |

## Decisions made
| Decision | Why | Discarded alternative |
|----------|-----|-----------------------|
| [Architecture — e.g. Vertical Slice per feature] | [why it fits this project] | [discarded alternative and why] |
| Business rules in the logic layer | Each rule has one home and is testable without the transport | Logic inside components, routes or handlers |

- Project-specific decisions: add a row here, or an ADR from `docs/decisions/000-template.md` when it needs context and options.
