# Changelog

## v1.2.0 — 2026-10-12
### Added
- `install.sh`: installs `project/` into the current repo with one `curl … | bash` — never overwrites an existing file, lists the ones it kept, makes `gates.sh` executable · `-s <tag>` pins a version.

## v1.1.2 — 2026-10-12
### Changed
- readme: version, license, Claude Code and methodology badges · GitHub alerts for the core flow, the cheapest run, the diff review and duplicate FR IDs · Phases diagram colors agent steps blue and the inline path gray.

## v1.1.1 — 2026-10-12
### Fixed
- `gates.sh` detects test files by path (`__tests__/`, `tests/`, `spec/`, `test_*`, `*.test.*`, `*.spec.*`, `*_test.*`, `*_spec.*`) — Jest tests in `__tests__/` without a `.test` suffix no longer fail `frs`, and source files like `latest.ts` or `special.ts` no longer count as tests.

## v1.1.0 — 2026-10-11
### Added
- `frs` gate in `gates.sh full`: every FR in `specs/current/` must have a test and a unique ID — catches deleted tests and duplicate IDs from parallel branches.
- readme → In a team: CI workflow running the full gates on every PR, and how to fix a duplicate FR ID.
- Branch name and commit message formats are `CLAUDE.md` placeholders — fit them to your team's convention, ticket ID included.
- `reviewer` flags tests named with an FR ID that check another behavior or assert nothing.

### Changed
- RF renamed to FR everywhere: `gates.sh fr`, `TEST_FR`, `{fr}`, `{fr_id}`. Upgrade: rename `TEST_RF` to `TEST_FR` and `{rf}` / `{rf_id}` to `{fr}` / `{fr_id}` in your `gates.conf`, and RF to FR in your `CLAUDE.md`.
- Feature close merges the FRs into the living spec before the full gates, so a REMOVED FR no longer fails `frs`.
- Methodologies moved from the readme to `METHODOLOGIES.md`; readme trimmed.

### Fixed
- `gates.conf` documents single quotes for commands with `$` — double quotes expanded them when the script sourced the file.

## v1.0.0 — 2026-10-11
- First release.
