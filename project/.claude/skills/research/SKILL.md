---
name: research
description: "Research a question with the inverted Feynman method: the human explains, the agent asks and points to the sources — never the answer first."
disable-model-invocation: true
---

## Activation Contract

Run when the human types `/research <question>` — about this code, its specs or a topic outside the repo.

Do not load it to build or change anything — use Change Size. Do not load it for a plain question without `/research` — answer it.

## Hard Rules

- NEVER give the answer, a summary or an explanation before the human has explained it in their own words.
- NEVER edit, create or stage a file — research only.
- NEVER judge from memory — every gap you report comes from a source: a file on disk or a source the human names.
- ALWAYS point to where the answer is (`path:line`, a section, a link) — NEVER what it says.
- ALWAYS act as the student: questions a newcomer would ask, at most 3 per round.

## Decision Gates

| Situation | Action |
|-----------|--------|
| The question is vague | Ask ONE question until it names one thing to understand — stop and wait |
| The question spans more than one slice | Map it with the `Explore` subagent (`.claude/agents/explore.md`) — keep only its summary — NEVER show it to the human |
| Topic outside the repo and no source on disk | Ask the human for a source (doc, link, file) — stop and wait |
| The human says "I don't know" | Give the smallest pointer: one `path:line` or one section to read — stop and wait |
| The human asks for the answer after explaining at least once | Give it — mark the parts the human never explained as `Gaps left` in the Output Contract |
| The explanation uses jargon it does not define | Ask what the term means, in plain words |
| The explanation is wrong | Quote the wrong claim and point to the source that contradicts it — NEVER correct it yourself |

## Execution Steps

1. Read the sources the question needs — search before opening, line ranges only — keep what you find to yourself.
2. Ask: `Explain <question> as if to a newcomer: what it does, how it works, why it is this way.` — stop and wait.
3. Compare the explanation with the sources — reply with the round format — stop and wait.
4. Repeat step 3 until no gap is left or the human says "stop".
5. Ask: `Now explain it in 3 lines, no jargon.` — stop and wait — a gap in it: back to step 3.
6. Emit the Output Contract.

Round format:
```
Right: <claims that match the sources, one line each>
Questions:
1. <newcomer question> → look at <path:line | section | link>
```

## Output Contract

```
[Researched] <question>
Your explanation: <the human's 3 lines, verbatim>
Sources: <path:line | section | link, one per line>
Rounds: <N>
Gaps left: none | <one per line>
```
