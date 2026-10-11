# Methodologies
Every method this setup applies, where it lives, and what it buys. Summary: the Principles section in [readme.md](readme.md).

## Development
| Method | Origin | Where | Effect |
|--------|--------|-------|--------|
| Spec-Driven Development with delta specs | OpenSpec style | `specs/current/` · `specs/changes/` · `specs/changes/archive/` | The spec, not the chat, is the source of truth; a change lists only ADDED / MODIFIED / REMOVED FRs |
| BDD scenarios in Gherkin style | Behavior-Driven Development · Gherkin `Given / When / Then` | `GIVEN \| WHEN \| THEN` inline under each FR | Each scenario becomes one test — one line instead of a `.feature` file, so no Cucumber runner needed |
| Arrange / Act / Assert | xUnit test pattern | `CLAUDE.md` → Testing Rules | One behavior per test, same shape everywhere |
| Query like a user | Testing Library guiding principles | `CLAUDE.md` → Testing Rules | Tests find elements by role + accessible name — they survive markup changes and enforce accessibility |
| One test per THEN variant | Equivalence partitioning | `CLAUDE.md` → Testing Rules | "Pays by card, PayPal or bank transfer" = 3 tests — no variant left untested |
| Test behavior, mock only boundaries | Classic (Detroit) TDD | `CLAUDE.md` → Testing Rules | Tests survive refactors; only network, database, clock and file system are mocked |
| Test name starts with its FR ID | FR ↔ task ↔ test traceability | Spec Rules · `gates.sh fr` | Every FR is checkable by name |
| TDD with RED evidence | Test-Driven Development | `implementer` · `gates.sh fr` | A test must fail before the code exists; the task line reports it |
| RFC 2119 keywords | IETF RFC 2119 | FRs and every `.md` | `MUST` / `NEVER` leave no room for "should" |
| English, imperative, one idea per line | Anthropic prompt guidance · `docs/doc-rules.md` | every `.md` and skill | Direct orders the model follows literally — fewer words, no ambiguity |
| Single owner per rule | DRY for docs | `docs/doc-rules.md` | `CLAUDE.md` owns global rules; other docs name its section instead of restating it |
| Fixed skill layout | `templates/skill.md` | every skill | Activation Contract → Hard Rules → Decision Gates → Execution Steps → Output Contract |
| Output contracts | — | every skill and agent | Fixed reply shape — short, and easy for the human to scan |
| Vertical slices | Vertical Slice Architecture | `CLAUDE.md` → Layer Structure | A feature changes inside one folder |
| ADRs | Architecture Decision Records | `docs/decisions/` | Project-wide choices keep their reason |
| KISS · YAGNI | — | `CLAUDE.md` → Hard Rules | No abstraction for a use case that does not exist |
| Make illegal states unrepresentable | Typed functional design | `CLAUDE.md` → Hard Rules | Exclusive states are one tagged union — no `isLoading` next to `error` and `data` |
| Minimal public surface | Information hiding | `CLAUDE.md` → Hard Rules | Export only what another file imports, types included — no dead exports |
| Explore → plan → approve → code | Anthropic best practices | `create-feature` steps 1–6 | No code before the human approves the change folder |
| Conventional Commits | conventionalcommits.org | Working Protocol | One readable commit per feature |

## Low verbosity, low bureaucracy
| Method | Origin | Where | Effect |
|--------|--------|-------|--------|
| Process sized to the change | Right-sized ceremony (Lean) | `CLAUDE.md` → Change Size | A one-FR change goes inline: no change folder, no approval round, one commit — the full cycle only when the change needs it |
| No ceremony for no behavior change | — | `refactor` · `optimize` skills | FRs and specs stay untouched; one plan approval covers every step |
| Batch approval | — | `go up to ID-00N` | One "yes" runs several tasks; per-task approval returns only on a failure or a question |
| Delete what does not change behavior | `docs/doc-rules.md` | every `.md` | A line that changes nothing the agent does gets cut |
| No hedging words | `docs/doc-rules.md` · RFC 2119 | every `.md` | No "should", "try to", "ideally" — a rule is `MUST` or it is gone |
| Fewest unambiguous words | `CLAUDE.md` → Chat Replies | every reply | No greeting, no restating the request, no closing summary |
| Output contract, nothing around it | `CLAUDE.md` → Chat Replies | every skill | The agent emits the contract and adds no prose |
| Quote only failing lines | `gates.sh` | every gate run | A passing gate is one line; a failing gate shows only its failing lines |
| ONE question at a time | `CLAUDE.md` → Working Protocol | any unclear point | No questionnaires — ask, wait, continue |
| Detail on demand | `explain` command | any reply | Replies are short by default; `explain` asks for depth |
| Never shorten what matters | `CLAUDE.md` → Chat Replies | FRs · change folders · questions · failure options | Brevity never removes a rule, a scenario or a choice the human needs |
| Minimal human steps | — | Setup · `/adopt` | One confirmation by the agent instead of backups, scripts or extra warnings |

## Quality
| Method | Origin | Where | Effect |
|--------|--------|-------|--------|
| Deterministic gates | Anthropic: "hooks and scripts are deterministic, instructions are advisory" | `.claude/scripts/gates.sh` | Fixed order, stop at the first failure — the model cannot skip or reorder a gate |
| Formatter in the gates, not in the prompt | Deterministic tooling over instructions | `FORMAT_*` in `gates.conf` | The script rewrites style in place — uniform code with no style rule to read and no failing gate for style |
| Living spec stays true | Spec-as-source-of-truth, enforced | `gates.sh full` → `frs` | Every FR in `specs/current/` must still have a test and a unique ID at each feature close and in CI — a deleted test or a duplicate ID from parallel branches fails the gate instead of leaving the spec lying |
| Evidence, not claims | Anthropic: "have Claude show evidence" | `Gates:` and `RED:` lines | The script prints the result; the agent copies it |
| Fresh-context review against the spec | Anthropic adversarial review · Superpowers spec-compliance review | `reviewer` subagent | A model that did not write the code checks it against the FRs |
| Gaps only, never style | Anthropic: reviewers that chase every finding cause over-engineering | `reviewer` rules | Findings must break an FR, the scope, a Hard Rule or a Testing Rule |
| Stop after 3 failed fixes | Anthropic: "correcting over and over" failure pattern | `implementer` → blocked | A looping fix returns to the human instead of burning tokens |
| Prompt audit | Claude Code `/doctor prompt-audit` | after editing rules, skills or agents | Finds contradictions and stale instructions |

## Tokens
Measured on the benchmark feature before the senior-quality rules: Opus for the change folder, then Sonnet for the tasks cost $1.11 vs $1.39 all-Opus (−20%), same quality — not re-measured since. `/clear → go` per task instead of `go up to` cost −15%.

| Method | Origin | Where | Effect |
|--------|--------|-------|--------|
| Fresh context per task | Anthropic context management | `/clear → go` | Each task starts from the change folder, not from the chat |
| Subagent per task on a cheaper model | Superpowers subagent-driven development · opusplan / model routing | `implementer` (Sonnet) | Opus plans, Sonnet implements; the main session never switches model, so its prompt cache survives |
| Filtered tool output | Anthropic hook preprocessing · RTK idea | `gates.sh` | A gate run adds one line to the context instead of its full output |
| Progressive disclosure | Claude Code skills | `.claude/skills/` | Only descriptions load at start; a skill body loads when used |
| Description out of context | `disable-model-invocation: true` | `/adopt` | A once-per-project skill costs nothing in later sessions |
| Short `CLAUDE.md` | Anthropic: under 200 lines | `CLAUDE.md` | Fewer always-loaded tokens and better adherence |
| Path-scoped rules | `.claude/rules/` with `paths:` | `docs/doc-rules.md` | A rule for one area loads only when Claude touches that area |
| Zero-cost notes | `<!-- -->` in `CLAUDE.md` | `docs/doc-rules.md` | Comments are stripped before loading |
| Cheap explorer | Built-in `Explore` override · `omitClaudeMd` · effort per agent | `.claude/agents/explore.md` | Exploration runs on Sonnet at low effort instead of Opus |
| Compaction anchors | Claude Code `Compact instructions` | `CLAUDE.md` | A compacted session keeps the active task, staged files and gate result |
| Search before reading | — | Hard Rules | Reads only the line ranges a task needs |
| Denied bulky files | Permission `deny` rules | `.claude/settings.json` | Lockfiles, build output and secrets never enter the context |
| Short replies | — | `CLAUDE.md` → Chat Replies | No greeting, restating or closing summary |
| Measure before → after | The `optimize` skill, applied to this setup | `/usage` · `/context` | A change stays only if it lowers tokens without failing gates |

## Evaluated and not adopted
| Method | Why not |
|--------|---------|
| One session for the whole feature, no `/clear` | Measured +65% tokens: the Opus session re-read the whole planning context on every turn |
| Explore on Haiku | 16% cheaper, but its summary had a factual error and claimed unrun tests passed |
| caveman (compressed prose) | Near 0% on agentic work in public tests; conflicts with "NEVER shorten FRs" |
| BMAD · Spec Kit | Heavier workflows for the same result |
| MCP code indexers (token-savior, claude-context, code-review-graph) | Tool manifest costs more than it saves on small and medium repos — use a code intelligence plugin instead |
| TDD Guard / Probity | Validates every edit with a model call; `gates.sh fr` covers RED for free |
| `Stop` hook forcing gates | Also blocks when the agent stops to ask a question |
| `MAX_THINKING_TOKENS` | Ignored by adaptive-reasoning models — effort per agent is the control |
