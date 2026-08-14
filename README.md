# llm-rfc-skill

An RFC process for **one or more humans and one or more LLM agents** to
co-author software specifications: numbered, immutable-once-published
documents with BCP 14 requirement language, embedded machine-verifiable
evidence (literate transcripts, tables, ABNF + witnesses), and a
cumulative conformance corpus that stops agents from regressing
previously established requirements.

This repository hosts the **process and skill itself** — process-scoped
BCPs and practice documents are published in its `rfc/` series.
Project-specific RFCs (features, formats, interfaces of a codebase)
belong in each project's own `docs/rfc/` or `rfc/` series; they are
never centralized here.

- `skill/` — the agent skill: process (`SKILL.md`), document template,
  and deterministic tooling (`rfc-lint`, `rfc-tangle`, `rfc-run`,
  `rfc-search`).
- `rfc/` — this project's process/skill RFC series. The process is
  self-hosting: `rfc/draft-ndn-authoring-rfcs-00.md` specifies it as a
  BCP whose evidence replays green against the tooling.

## Install

For Claude Code: `cp -r skill ~/.claude/skills/authoring-rfcs`

Other runtimes: any agent that reads `SKILL.md`-style instructions can use
it; the documents are plain markdown and outlive the tooling.

## Verify

```
skill/rfc-lint rfc/draft-ndn-authoring-rfcs-00.md   # structure: 0 errors
skill/rfc-run  rfc/draft-ndn-authoring-rfcs-00.md   # evidence: replays green
```

## License and attribution

Three grants, by function:

- **Process text** — the RFC series (`rfc/`), `skill/SKILL.md`, and this
  README: [CC BY 4.0](LICENSE-CC-BY-4.0). Reuse and adapt freely **with
  attribution** (see Citing below). Per-document attribution belongs to
  each RFC's own `Authors:` line — contributors publishing here are
  credited as themselves.
- **Template** — `skill/template.md`: [CC0 / public domain](LICENSE-CC0).
  The template is itself derived from IETF practice — RFC 7322 document
  structure, BCP 14 boilerplate, conventions long predating this repo —
  so most of it was never ours to license; CC0 dedicates the little that
  is.
  The template exists to be copied into your documents; instantiating it
  creates **no derivative-work obligation, no attribution requirement, and
  no license carried into your RFC**.
- **Tooling** — `skill/rfc-lint`, `skill/rfc-tangle`, `skill/rfc-run`,
  `skill/rfc-search`, `skill/rfc-fsm-render`: [MIT](LICENSE-MIT).

**No claim on outputs.** Documents produced using this process — including
those instantiated from the template and validated by the tooling — belong
entirely to their authors, under whatever license their home repository
chooses. Nothing here reaches into them.

Portions of the RFC texts quote IETF RFCs (e.g. the BCP 14 boilerplate of
RFC 8174) under the IETF Trust's provisions; those sentences remain the
Trust's and are not relicensed here.

### Citing

See [CITATION.cff](CITATION.cff) (GitHub's "Cite this repository" uses
it). Short form: *Nunley, N. — llm-rfc-skill: an RFC process for
human-LLM co-authored software specifications, formalized in
collaboration with Claude (Anthropic), 2026.*
