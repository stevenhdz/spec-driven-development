---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/*_test.*"
  - "**/*_spec.*"
  - "**/test_*"
  - "**/{test,tests,spec,__tests__}/**"
  - "**/Tests/**"
  - "**/*.*Tests/**"
  - "**/*Tests.*"
  - "**/*Test.*"
---
# Testing Rules
<!-- Spec Driven Development by stevenhdz · https://github.com/stevenhdz/spec-driven-development — framework file: `install.sh --update` overwrites it. Your own path rules go in other files of .claude/rules/. -->

- Test observable behavior only — what a user sees, what an API returns — not implementation details.
- UI tests: find elements as a user does: role + accessible name, then visible text — not by index, CSS class or test id.
- Mock only external boundaries (network, database, clock, file system) — use the real code everywhere else.
- One test = one behavior, structured Arrange / Act / Assert.
- Every variant a THEN names gets its own test — e.g. "pays by card, PayPal or bank transfer" = 3 tests.
- When TDD is ON — full cycle: the change's `proposal.md` → Scope · inline: always ON — NEVER keep a test that did not fail first — it proves nothing.
- A test fails because of a bug in the code: fix the code, NEVER the test.
