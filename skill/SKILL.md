---
name: authoring-rfcs
description: Use when a design decision needs a durable written proposal — "write an RFC", "draft a spec", a protocol/interface/storage-format change with competing options, a convention worth standardizing, or when humans and LLM agents co-author software specifications.
---

# Authoring RFCs

## Overview

A complete, self-contained process for **one or more humans and one or more
LLM agents** to collaboratively produce software specifications. The unit of
work is an RFC: a **numbered, immutable-once-published** design memo modeled
on the IETF process (BCP 9) and style (RFC 7322, BCP 14). Decisions get
durable identity; changes happen by superseding, never by editing history.
Any participant — human or agent — may author, review, or object; each
authors under their own name (`draft-<author>-...`), which is what makes
concurrent multi-party drafting collision-free.

## Authoring process

Do NOT write the RFC first. A spec written from unasked questions documents
your assumptions, not the requirements. Four phases, in order:

Phases scale with stakes: on the fast track (below) research may take
minutes and the interview may be a single confirming question — but no
phase is skipped outright.

1. **Research** — before writing anything: read prior RFCs in `docs/rfc/` or
   `rfc/` (and the index), the code the proposal touches, and any prior
   design docs or recorded decisions. Search published internet RFCs for
   prior art (`<this skill dir>/rfc-search <terms>`): prefer citing an
   existing standard (HTTP semantics, JSON, URIs, timestamps...) in
   References over redefining it. Output is a short findings list:
   constraints discovered, prior art, open questions.
2. **Interview** — refine with whichever humans hold the requirements: one
   question per message, multiple-choice preferred. Cover at minimum: the
   problem's evidence, hard constraints, category
   (Standards-Track/Informational/Experimental), alternatives already
   rejected, and what crosses a trust boundary. Continue until an answer
   stops changing the design; then stop — don't interview past convergence.
3. **Synthesis** — present the design in brief: chosen approach, the
   alternatives with one-line rejection reasons, security posture, and any
   grammar sketched in ABNF. Get explicit approval before formalizing.
4. **Formalize** — only now instantiate [template.md](template.md) as
   `draft-<author>-<slug>-NN.md` (author-scoped: no number, no coordination,
   no collisions), write the Specification with BCP 14 keywords, and lint to
   exit 0 (`<this skill dir>/rfc-lint <file>`) before showing anyone.
   The template's Specification body is shaped for an implementing agent
   (NLSpec-derived — draft-claude-nlspec-conventions-00): a layering
   statement, data model as descriptive RECORD/ENUM declarations (plain
   fence, never `@R-` tagged — they fix a reading, they prove nothing),
   every configurable value in a table with a Default column, precedence
   and fallback lists that end in a default, an error table with a
   Recovery column, Out of Scope entries that name their extension point,
   and Alternatives Considered headed by the question that names the
   rejected alternative. No Definition of Done: the digest is the
   checklist and a marker's evidence is its record.

## Lifecycle — two tracks

**Fast track (the default).** `DRAFT` → lint → **publish**, under lazy
consensus: publishing IS the review request, and the remedy for a late
objection is an updating or superseding draft, not an argument about
history. Most day-to-day decisions take this path the same day.

**Full track.** Insert `LAST-CALL` before publishing when ANY of: more than
one party holds a veto; it changes published normative behavior
(`Obsoletes:`/`Updates:` a Standards-Track or BCP RFC); it crosses a
security boundary; it standardizes across projects. Deadline stated in the
masthead (`**Objections-By:** YYYY-MM-DD`, lint-enforced) — scale the window to
the audience (a day for a team, longer for strangers). Resolution is rough
consensus (RFC 7282): objections addressed, not necessarily withdrawn;
humans adjudicate when contested.

**Publishing** (either track): the number is assigned only here — take next
from `index.md`, rename to `NNNN-slug.md`, retitle `# RFC NNNN:`, status
`PUBLISHED`, commit; concurrent publishes collide on `index.md`, and that
merge conflict is the allocation lock. Published files are frozen
(lint-enforced). Endings: full replacement = new draft with `Obsoletes:`
(old RFC → `SUPERSEDED` + `Superseded-By:`, the one permitted edit);
partial amendment = `Updates:`, original stays authoritative; retired
without successor = `HISTORIC`; dead drafts = `WITHDRAWN`.

**Commit discipline.** When a human collaborator accepts a change, its
commit message MUST be Conventional Commits v1.0.0 (check:
`<this skill dir>/rfc-commit-lint`, also usable as a commit-msg hook),
attribute only humans unless the repo mandates LLM disclosure
(`--require-llm` inverts the check), and pass a two-key read: an LLM
with FRESH context (never the authoring session — dispatch a subagent
with only the changeset and the message) reports whether the message
narrates what happened — the decision and effect, not the hunks — and
the human reads the message plus that report. Both keys must concur.

## Conformance corpus (anti-backsliding)

**Dual verifiability governs evidence:** every conformance artifact must be
checkable by a person at a glance AND by a deterministic tool. LLMs may
author artifacts; they never sit in the verification loop.

Provable requirements carry `[R-<slug>]` markers with typed evidence beside
them (` ```transcript @R-<slug> `, or a table after
`<!-- evidence: @R-<slug> -->`); `rfc-tangle` extracts each block and
`rfc-run` runs it through its adapter. CI runs the evidence of ALL published
RFCs, never just the newest. Drafts declare `**Corpus:** green|red` in the
masthead; published RFCs must be green. When executing an RFC-governed
process, take permitted moves from `rfc-fsm-exec --state FILE`, never from
memory; load an RFC into context through its `rfc-render-llm` digest.

Before writing or changing evidence, read `references/conformance-corpus.md`:
snippet attributes, adapters, sandbox providers, evidence tables, `abnf`,
`fsm` rules, and the corpus declaration.

## Plan breakdown

An implementation plan derived from an RFC is rigorous when: every task
names the requirement IDs it implements; every `[R-]` ID in the RFC appears
in at least one task; and a task's exit criterion is its scenarios passing
**plus the rest of the corpus staying green**. Coverage check:
`grep -o '\[R-[a-z-]*\]'` over RFC and plan must yield the same set.
This contract is workflow-agnostic: it works standalone or as the
durable-decision layer under a skill-based pipeline (e.g. superpowers
brainstorming feeding the interview, writing-plans consuming the IDs).

## Formal language

Requirements use **uppercase BCP 14 keywords** (MUST/SHOULD/MAY...); lowercase
"must/should/may" in the Specification is ambiguous and the linter flags every
instance. The Terminology section carries the BCP 14 boilerplate (in the
template) whenever keywords appear.

## Quick reference

| Check | Enforced by |
|---|---|
| Identity: `draft-<author>-<slug>-NN.md` (unpublished) or `NNNN-slug.md` (published), title matches | rfc-lint ERROR |
| Status matches form (numbers only exist once published) | rfc-lint ERROR |
| Status ∈ DRAFT, LAST-CALL, POSTPONED, PUBLISHED, SUPERSEDED, WITHDRAWN, HISTORIC | rfc-lint ERROR |
| LAST-CALL carries a consensus table (pending/consent/concern) | rfc-lint ERROR |
| Category (optional) ∈ Standards-Track, Informational, Experimental, BCP | rfc-lint ERROR |
| LAST-CALL carries a masthead `**Objections-By:**` deadline | rfc-lint ERROR |
| Updates:/Obsoletes: are 4-digit RFC numbers | rfc-lint ERROR |
| ABNF blocks: rule syntax, undefined refs, duplicates | rfc-lint ERROR |
| All template sections present | rfc-lint ERROR |
| BCP 14 boilerplate when keywords used | rfc-lint ERROR |
| Lowercase normative words in Specification | rfc-lint WARNING |
| SUPERSEDED needs Superseded-By | rfc-lint ERROR |
| PUBLISHED file modified in working tree | rfc-lint ERROR |

## Common mistakes

- **Writing the RFC before the interview** — producing a complete draft from
  the task description alone. If you haven't asked a question, you're
  transcribing assumptions.
- **Freeform status** ("Approved pending implementation") — use the four
  lifecycle values; approval is `PUBLISHED`.
- **No Security Considerations** because "it's just a CLI feature" — a
  registry that `cd`s and executes from config-controlled paths is a trust
  boundary. "None" takes an argument.
- **No Alternatives Considered** — that's an announcement, not a proposal.
- **Editing a PUBLISHED RFC** "because it's a small fix" — supersede it.
- **Design doc habits**: implementation task lists belong in a plan document
  the RFC links from References, not in the Specification.

## Decision record

What this process omits from IETF, the evidence forms it rejected (Gherkin,
LLM-as-judge) and why, and its sources: `references/decision-record.md`.
