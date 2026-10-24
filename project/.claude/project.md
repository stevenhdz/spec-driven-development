# [Project name]
<!-- Project values — yours to fill and edit. `install.sh --update` never overwrites this file. -->

## Product
- [What the product does, in one line — e.g. "REST API for orders", "CLI that imports CSV files"]
- Behavior lives as FRs in `specs/current/<capability>/spec.md` — NEVER define it here.

## Stack
- Language: [e.g. TypeScript · Python · Go]
- Framework: [e.g. React + Vite · Express · FastAPI]
- App folder: [e.g. `app/` — run all commands from there]
- Testing: [e.g. Vitest + Testing Library · Jest · pytest]
- Lint: [e.g. oxlint · eslint · ruff]
- Run locally: [e.g. `npm run dev` · `uvicorn app.main:app --reload`]

## Layer Structure — Vertical Slice
<!-- Suggested structure — replace it with your project's architecture (layered, hexagonal, MVC, …) and rename the heading. Keep the Module line: Change Size, Approach and the rules count modules. -->
```
[src]/
  [features]/          ← create with the second slice — until then the only slice folder lives in [src]/
    [feature-name]/
      [entry]          ← entry layer: UI component · HTTP route · CLI command — holds simple state, no business rules — always
      [rules]          ← logic layer: pure business rules — always when there is a rule
      [tests]          ← tests of the slice — always
      [public API]     ← the only file other slices import (e.g. index.ts · __init__.py) — always
      [stateful logic] ← logic layer: hook · service · use case — only when state or I/O outgrows the entry layer, or is reused
      [types]          ← types, schemas, contracts, no runtime logic — only when 2+ files share them
  [shared]/            ← only code used by 2+ slices — create when first needed
  [app entry]          ← app composition: wires slices together, no feature logic
```
- Layers are responsibilities, not files — create an optional file only when its condition is true.
- One feature = one folder in `[features]/` — in `[src]/` while there is only one slice
- Module: one `[feature-name]/` folder

## Conventions
- Naming: [e.g. PascalCase components, camelCase functions · snake_case modules and functions]
- Forbidden: [patterns — e.g. `any`, default exports, class components, inline `style` · global mutable state]
- Test name: [e.g. `ORDER-01 should <result> when <condition>` · `test_order_01_<result>_when_<condition>`]
- Commit message: [e.g. `type(scope): description` · `type(PROJ-123): description`]
- Branch name: [e.g. `type/<name>` · `type/PROJ-123-<name>`]

## Project Rules
<!-- Rules only this project needs — same style as CLAUDE.md: imperative, uppercase NEVER / ALWAYS / MUST only for costly rules. -->
