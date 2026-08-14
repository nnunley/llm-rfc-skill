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

## Lifecycle — two tracks

**Fast track (the default).** `DRAFT` → lint → **publish**, under lazy
consensus: publishing IS the review request, and the remedy for a late
objection is an updating or superseding draft, not an argument about
history. Most day-to-day decisions take this path the same day.

**Full track.** Insert `LAST-CALL` before publishing when ANY of: more than
one party holds a veto; it changes published normative behavior
(`Obsoletes:`/`Updates:` a Standards-Track or BCP RFC); it crosses a
security boundary; it standardizes across projects. Deadline stated in the
Changelog ("objections by YYYY-MM-DD", lint-enforced) — scale the window to
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

## Conformance corpus (anti-backsliding)

**Dual verifiability governs evidence:** every conformance artifact must be
checkable by a person at a glance AND by a deterministic tool. LLMs may
author artifacts; they never sit in the verification loop.

The RFC is literate: provable requirements carry `[R-<slug>]` markers, and
the evidence lives IN the document beside them — typed fenced blocks whose
info string carries the tag (` ```transcript @R-<slug> `), or tables
preceded by `<!-- evidence: @R-<slug> -->`. Pairing is lint-enforced both
directions; `rfc-tangle <rfc.md> [outdir]` extracts each block verbatim
into the type's native file for its runner. An evidence *type* is just a
name plus a **runner contract**: a deterministic command that takes the
tangled file and exits 0/1. Choose types by least indirection:

- Evidence dispatches through **adapters** (draft-ndn-evidence-adapters-00):
  `rfc-run` resolves each tangled block's type via RFC_ADAPTER_PATH ->
  series-local `adapters/` -> built-ins, and the adapter owns all engine
  and environment concerns. Built-ins: `transcript` (bootstrap: shell
  replay in the hygiene sandbox) and `fsm` (structural validation).
  Prefer thin declarative vocabularies over raw shell once a domain
  accumulates evidence.
- Isolation is a separate seam (draft-ndn-sandbox-providers-00): a
  **sandbox provider** wraps any adapter run (`provider [flags] -- adapter
  file`), selected by `--sandbox NAME` > `RFC_SANDBOX` > the series
  profile file `sandbox`; a selected-but-unresolvable provider is a hard
  error, never a silent bare run. Built-in: `env-scrub` (hygiene floor).
- Project session formats (e.g. mooR's `moot`) — register the existing
  runner; the fenced block is the file, no transliteration.
- Evidence tables — one row per case for rule surfaces (validity matrices,
  state transitions); runner = thin row adapter.
- `abnf` — the ∀ statement of syntax; pair it with witness rows (concrete
  valid/invalid strings) as its checkable shadow.
- `fsm` — state machines (`initial` / `A -> B` / `terminal ...`, plus
  optional `deadline <state> [<instant>] -> <target>` where the timeout
  handler is REQUIRED and must be a declared transition; instants are
  second-resolution — bare date = midnight UTC, date+offset = midnight in
  that zone), validated
  for single initial, reachability, terminal closure, and dead ends;
  allowed/forbidden transition witness tables are cross-checked against the
  machine; mermaid/D2 displays are derived via `rfc-fsm-render`, never
  authored. Per-state `note <STATE>: <guidance>` lines carry stage
  permissions; `rfc-fsm-exec <file.fsm> <state> [target]` executes the
  machine as a process governor — query mode prints the stage guidance and
  permitted transitions, guard mode exits nonzero on an illegal move —
  so an agent derives what is and is not permitted from the document,
  never from memory. Session mode (`--state FILE`) persists the walked
  path as a validated witness across context resets and discloses ONLY
  the current stage — use it when executing an RFC-governed process.
  `rfc-render-llm <rfc.md>` emits a token-minimal normative digest
  (`--verify` checks its invariants); prefer the digest when loading an
  RFC into context, and resolve markers to the full document as needed.

The tangled evidence of ALL published RFCs is the conformance corpus: CI
runs the WHOLE corpus, never just the newest RFC's — work on one RFC cannot
silently regress another's requirements. Supersession retires an RFC's
evidence; an `Updates:` RFC replaces only the requirement IDs it names.
IDs are permanent once published: plans, commits, and later RFCs cite them,
so obligations accumulate instead of resetting with each conversation.

Drafts declare their expected corpus state with an optional masthead
header `**Corpus:** green|red (note)` (absent = green); `rfc-run --expect`
verifies the declaration in both directions and CI gates drafts on it —
red only by declaration, never by surprise. Published RFCs must be green.

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
| LAST-CALL states "objections by YYYY-MM-DD" | rfc-lint ERROR |
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

Modeled on: RFC 2026/6410 (process, categories), RFC 7282/8789 (rough
consensus), RFC 7322 (style), BCP 14 = RFC 2119 + 8174 (keywords), RFC
5234/7405 (ABNF), RFC 9000 as structural exemplar, and
https://www.ietf.org/process/informal/. The evidence layer's theory is
Jackson & Wing, "Lightweight Formal Methods" (IEEE Computer roundtable,
1996): partiality in language, modeling, analysis, and composition —
targeted, mechanically-checkable formalism over full verification.
