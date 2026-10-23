---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs,py,go,rs,java,kt,kts,scala,rb,php,cs,swift,dart,vue,svelte,astro}"
---
# Code Rules
<!-- Spec Driven Development by stevenhdz · https://github.com/stevenhdz/spec-driven-development — framework file: `install.sh --update` overwrites it. Your own path rules go in other files of .claude/rules/. -->

- Do not over-engineer (KISS · YAGNI): the simplest solution that works — a function before a class, no abstraction or layer for a use case that does not exist yet
- Do not create a pass-through: a wrapper around a single call (e.g. a hook around one `useState`, a service around one query), a component that only renders another, a re-export other than the public API, a type used in one place — and do not write code no FR or caller can reach
- Export only what another file imports — types included
- Do not reimplement what the standard library, the framework or an approved dependency already does (e.g. argument parsing, date math, JSON schema checks) — configure it instead
- Do not signal an error with a sentinel value (`None`, `-1`, `""`) — raise or return the language's error type, with a message that names the bad input
- Model states that exclude each other as one tagged union — not separate fields that can contradict each other (e.g. `isLoading` next to `error` and `data`)
- Do not silence the type checker — no casts, non-null assertions or ignore comments: fix the type — scaffold files exempt
- Do not add comments to the code you write or change — names and small functions must explain the intent; leave existing comments as they are
