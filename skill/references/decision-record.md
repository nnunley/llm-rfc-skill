# Decision record

What this process deliberately leaves out, the evidence forms it rejected, and its sources.

## Omitted IETF machinery (deliberate)

Maturity ladder (one `PUBLISHED` level; RFC 6410 already cut three to two),
TS/AS applicability statements, variance procedure, multi-level appeals
(here: humans adjudicate), IPR notices (repo license governs), Secretariat
record-keeping (git history is the record).

## Rejected evidence forms (decision record)

- **Gherkin/Cucumber scenarios**: fails dual verifiability — the runner is
  a hand-maintained step-definition library (a shadow codebase needing its
  own tests). Its authoring familiarity doesn't buy verification. Same
  reasoning retired FitNesse-style fixture frameworks; their good idea
  (tables, sequence tables) survives as evidence tables with exit-code
  adapters.
- **LLM-as-judge**: circular for a corpus meant to constrain LLM agents.
- Upgrade path noted: fence extraction currently line-anchored awk; a
  CommonMark parser (cmark) hardens it when corpora grow. To become a real
  internet-draft, transliterate via kramdown-rfc or mmark.

## Sources

The compact fact/commitment protocol draws on
[Randal Schwartz's workflow](https://gist.github.com/RandalSchwartz/598a1f2b5760a23c1d70b57e9e85393f)
(read 2026-10-23) and his
[committed-speech explanation](https://dev.to/gde/requests-promises-assertions-and-declarations-rewriting-our-ai-agent-workflow-as-a-1986-4k4c).
Keep evidence states distinct from commitments and acceptance. Retraction
preserves history and invalidates dependent conclusions; it is a temporal
operation beyond a static four-valued truth table. Make notation names
dependencies, while the numbered checkpoint restores the relevant working
set. Ordinary facts need no RFC. Existing conformance tools remain useful
for adopted contracts; this experiment does not mechanically verify the
agent's epistemic judgments or establish token savings.

Modeled on: RFC 2026/6410 (process, categories), RFC 7282/8789 (rough
consensus), RFC 7322 (style), BCP 14 = RFC 2119 + 8174 (keywords), RFC
5234/7405 (ABNF), RFC 9000 as structural exemplar, and
https://www.ietf.org/process/informal/. The evidence layer's theory is
Jackson & Wing, "Lightweight Formal Methods" (IEEE Computer roundtable,
1996): partiality in language, modeling, analysis, and composition —
targeted, mechanically-checkable formalism over full verification.
