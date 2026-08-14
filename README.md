# llm-rfc-skill

An RFC process for **one or more humans and one or more LLM agents** to
co-author software specifications: numbered, immutable-once-published
documents with BCP 14 requirement language, embedded machine-verifiable
evidence (literate transcripts, tables, ABNF + witnesses), and a
cumulative conformance corpus that stops agents from regressing
previously established requirements.

- `skill/` — the agent skill: process (`SKILL.md`), document template,
  and deterministic tooling (`rfc-lint`, `rfc-tangle`, `rfc-run`,
  `rfc-search`).
- `rfc/` — this project's own RFC series. The process is self-hosting:
  `rfc/draft-ndn-authoring-rfcs-00.md` specifies it as a BCP whose
  evidence replays green against the tooling.

## Install

For Claude Code: `cp -r skill ~/.claude/skills/authoring-rfcs`

Other runtimes: any agent that reads `SKILL.md`-style instructions can use
it; the documents are plain markdown and outlive the tooling.

## Verify

```
skill/rfc-lint rfc/draft-ndn-authoring-rfcs-00.md   # structure: 0 errors
skill/rfc-run  rfc/draft-ndn-authoring-rfcs-00.md   # evidence: replays green
```
