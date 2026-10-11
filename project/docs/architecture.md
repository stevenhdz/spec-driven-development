# Architecture — [Project name]

Project-wide map and the *why*. Behavior (RFs): `specs/current/`. Rules and folder pattern: `CLAUDE.md`. Per-change design: `specs/changes/<feature>/design.md`.
Updated at each feature close — a new slice goes in §2, a project-wide decision in §5.

## 1. Context
| Item | Value |
|------|-------|
| Users | [Who uses it — e.g. "shoppers on a web store" · "mobile app clients" · "developers in a terminal"] |
| Runs in | [e.g. browser · Node server in Docker · CLI on the user's machine] |
| Inbound | [How requests arrive — e.g. user clicks · HTTP REST · CLI arguments] |
| Outbound | [External systems it calls — e.g. none · PostgreSQL · Stripe API] |
| Persistence | [e.g. none — memory only · PostgreSQL · local JSON file] |

## 2. Slices
| Slice | Responsibility | Public API |
|-------|----------------|------------|
| [slice-name — or "none yet"] | [What it owns, in one line] | [What it exports — e.g. `OrderList` · `ordersRouter` · `runImport`] |

## 3. Layers in this stack
| Layer | This stack |
|-------|------------|
| Entry | [e.g. component · route / controller · command handler] |
| Logic | [e.g. pure rules · a hook only when state outgrows one `useState` · service / use case] |
| Types | [e.g. `types.ts` only when 2+ files share them · DTOs · `schemas.py`] |
| Public API | [e.g. `index.ts` · `__init__.py` · exported package] |
| App composition | [e.g. `App.tsx` · `server.ts` · `main.py`] |

## 4. Quality attributes
| Attribute | Target | How the architecture meets it |
|-----------|--------|-------------------------------|
| [e.g. Testability · Latency · Offline] | [e.g. rules tested without I/O · p95 < 200 ms] | [e.g. pure rules, outbound systems mocked at the boundary] |

## 5. Decisions
| Decision | Why | Discarded alternative |
|----------|-----|-----------------------|
| Vertical Slice per feature | A feature changes inside one folder | Folders per type (`components/`, `controllers/`, `services/`) |
| Business rules in the logic layer | One home per rule, testable without the transport | Rules inside components, routes or handlers |
| [Project decision] | [Why] | [Alternative and why not] |

A decision that needs context and options: write an ADR from `docs/decisions/000-template.md` and link it here.
