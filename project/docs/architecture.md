# Architecture

## Layers
```
input ─► component ─► hook / rules ─► result ─► component renders it
                         │
                         └─ shapes from types.ts

slice = one feature folder in `app/src/features/`
slice ── index.ts ──► other slices · App.tsx
shared/ ◄── imported by 2+ slices
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
| `shared/` | Code used by 2+ slices | Import from a slice |
| App composition | Wire slices together | Hold feature logic |

## Decisions made
| Decision | Why | Discarded alternative |
|----------|-----|-----------------------|
| Vertical Slice per feature | Each feature's UI, logic and tests live together and change together | Layered folders (`components/`, `hooks/`) — one feature spread across many folders |
| Business rules in the logic layer | Each rule has one home and is testable without the transport | Logic inside components, routes or handlers |

- Project-specific decisions: add a row here, or an ADR from `docs/decisions/000-template.md` when it needs context and options.
