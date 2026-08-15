# llm-rfc-skill

**A process for humans and LLM agents to design software together with
less slop** — specifications with durable identity, formal requirement
language, and machine-verifiable evidence, so that what was decided stays
decided and what was promised stays checkable.

**📖 Read the RFC series rendered:** https://nnunley.github.io/llm-rfc-skill/
— every document with derived state-machine diagrams and a token-minimal
`.llm.md` digest beside it, regenerated from source on every push.

## The problem

LLM-assisted design fails in characteristic ways. Agents produce confident,
plausible prose that verifies nothing. Requirements agreed in one
conversation are invisible to the next context window, so agents quietly
regress decisions that were already made. Design documents drift from
implementations with no alarm attached. And "looks done" — the natural
stopping point for a language model — is not the same thing as *is done*.

This repo is a countermeasure: an RFC process adapted from fifty years of
standards practice (IETF lifecycle and style, W3C implementation gating,
Rust's mechanized consensus, TC39 staging) and rebuilt for mixed
human/LLM authorship around one law:

> **Dual verifiability.** Every conformance artifact must be checkable by
> a person at a glance AND by a deterministic tool. LLMs author; they
> never verify.

## How it works

1. **Draft under your own name.** `rfc/draft-<author>-<slug>-00.md` —
   author-scoped names need no coordination, so any number of humans and
   agents draft concurrently without collisions. Numbers are assigned
   only at publication (the series `index.md` is the allocation lock).
2. **Interview before writing.** The process forbids drafting from
   unasked questions: research prior art, then elicit requirements from
   the humans who hold them, one question at a time, until answers stop
   changing the design.
3. **Requirements are formal and provable.** Normative sentences use
   BCP 14 keywords (MUST/SHOULD/MAY — lowercase lookalikes are flagged).
   A provable requirement carries a stable marker, proven by evidence
   embedded right beside it:

   ~~~markdown
   The registry MUST reject duplicate names. [R-no-dup-names]

   ```transcript @R-no-dup-names
   $ git issue repo add api /elsewhere
   Error: 'api' is already registered; use --force to replace
   ? 1
   ```
   ~~~

   Evidence types by least indirection: session **transcripts** (replayed
   byte-exact in a sandbox), **tables** for rule surfaces, **ABNF** with
   valid/invalid witnesses for syntax, **fsm** state machines validated
   for reachability and dead ends, with allowed/forbidden transition
   witnesses cross-checked against the machine. Mermaid/D2 diagrams are
   derived from verified sources, never drawn by hand.
4. **Lint is a gate, not a suggestion.** `rfc-lint` enforces identity,
   lifecycle, structure, keyword discipline, and marker⇄evidence pairing
   both directions — and enumerates what it checked, so a clean run is an
   auditable claim, not silence.
5. **Two publication tracks.** Fast track (the default): draft → lint →
   publish under lazy consensus — same-day for routine decisions. Full
   track (multiple veto-holders, changed published behavior, security
   boundaries, cross-project standards): a LAST-CALL window with a
   deadline and a **registered consensus table** — consent is recorded
   per reviewer, never inferred from silence, and concerns block.
6. **Publication requires green evidence.** A spec-first draft keeps its
   red corpus while DRAFT (the transcripts *are* the acceptance
   criteria); it publishes only once implementation turns them green.
   Published RFCs are frozen — change means a superseding draft, so
   history is never rewritten.
7. **The corpus is the anti-slop wall.** CI replays the evidence of ALL
   published RFCs on every change. An agent heads-down on today's feature
   cannot silently regress last month's promise — the wall goes red.

## Usage patterns

- **Solo + agent (most common).** Day-to-day design decisions go fast
  track: the agent interviews you, drafts, lints, you read, it publishes.
  Ten minutes for a decision that stays decided.
- **Spec-first features.** Draft the RFC with deliberately red evidence,
  then hand implementation to any agent with "make the corpus green" as
  the finish line — acceptance criteria that cannot be argued with.
- **Team + agents.** Full track: reviewers (human or agent) land in the
  consensus table; a real objection becomes a competing draft under the
  objector's own name rather than a comment thread.
- **Cross-project conventions.** Practice documents take the BCP
  category. An RFC lives in the repository whose behavior it governs —
  project RFCs stay in their projects; this repo's series carries only
  process documents (its own BCP is the first).
- **Retrofit.** Adopt in an existing repo by writing the RFC for the next
  contested decision — not by back-filling history.

## Standalone or supplemental

This process is **standalone by design** — nothing in it depends on any
other skill, framework, or harness; the documents are plain markdown and
the tooling is portable shell. But it is also built to **supplement
skill-based workflows** such as
[superpowers](https://github.com/obra/superpowers): a brainstorming or
interview phase can feed the RFC's requirements; an implementation-planning
skill can consume the RFC's `[R-]` requirement IDs as its task coverage
contract (every task names the IDs it implements; done = its evidence
green plus the rest of the corpus staying green); and the conformance
corpus serves as the regression wall no matter which workflow does the
implementing. Use it as the whole process, or as the durable-decision
layer under the process you already have.

## Installation

**The skill (Claude Code):**

```
git clone https://github.com/nnunley/llm-rfc-skill
cp -r llm-rfc-skill/skill ~/.claude/skills/authoring-rfcs
```

Other runtimes: any agent that follows `SKILL.md`-style instructions can
run the process; the tooling is dependency-free bash + awk (BSD and GNU),
and the documents are plain markdown that outlive the tooling.

**A repo adopting the process:**

```
mkdir -p docs/rfc          # or rfc/ — either is blessed
printf '# RFC Index\n\n## Published\n\n(none — next: 0001)\n\n## Drafts\n' > docs/rfc/index.md
```

CI (the anti-backsliding wall — a series MUST run it):

One command runs the whole gate — lint over every document, published
evidence (blocking), draft corpus declarations (red only by
declaration), and digest invariants — and prints a per-document summary:

```sh
skill/rfc-check rfc          # or: make check
```

CI is a thin caller of the same command, so local runs and CI cannot
drift:

```yaml
rfc-conformance:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    # pin the tooling to a reviewed commit — a verdict produced by moving
    # tools is no verdict (update the SHA deliberately, as a reviewed change)
    - run: |
        git clone https://github.com/nnunley/llm-rfc-skill /tmp/rfc
        git -C /tmp/rfc checkout 7f16bb8
    - run: /tmp/rfc/skill/rfc-check docs/rfc
```

## Tooling

| Tool | Purpose |
|---|---|
| `rfc-lint` | Structure, lifecycle, formal language, evidence pairing; enumerates checked vs n/a |
| `rfc-run` | Tangle + replay transcript evidence in a hygiene sandbox (not a security boundary — isolate foreign corpora yourself) |
| `rfc-tangle` | Extract evidence blocks verbatim for any runner |
| `rfc-search` | Prior-art search over the internet RFC index — cite standards, don't re-derive them |
| `rfc-fsm-render` | Derive mermaid/D2 diagrams from verified fsm blocks |

## Status

The process is specified by its own BCP —
[`rfc/draft-ndn-authoring-rfcs-00.md`](rfc/draft-ndn-authoring-rfcs-00.md)
— written in its own format, linted by its own tooling, with its own
evidence replaying green (`skill/rfc-run rfc/draft-*.md`). It is a
**DRAFT**: review and objections are welcome
([#1](https://github.com/nnunley/llm-rfc-skill/issues/1)), and the honest
way to object is a competing draft.

## Layout

```
rfc/      the process's own RFC series (process/practice documents only)
skill/    the agent skill: SKILL.md, template.md, and the five tools
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
