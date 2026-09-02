# Review: NLSpec, and What the RFC Process Takes From It

**Reviewer**: Norman Nunley (process owner), drafted with Claude Code
**Date**: 2026-09-01
**Document reviewed**: `nlspec.nlspec.md`, jhugman/nlspec at commit
`eae0052c948f` (2026-02-13, Apache-2.0) —
https://github.com/jhugman/nlspec/blob/eae0052c948f/nlspec.nlspec.md
**Outcome**: converted into a candidate-practice draft,
[`rfc/draft-claude-nlspec-conventions-00.md`](../rfc/draft-claude-nlspec-conventions-00.md)
(lint clean, three evidence blocks green)

---

## What NLSpec is

A format for specifications whose reader is a coding agent, not a person
with context. The claim: an agent given only the NLSpec and a project
description produces a conforming implementation. The instrument is
"minimum sufficient formalism" — prose for motivation, and pseudocode,
`RECORD`/`ENUM`/`INTERFACE` declarations, normative tables, and grammars
wherever prose would leave a gap. The document is organized as a
Why → What → How → Done arc and closed by a Definition of Done (DoD): a
checklist that mirrors the body section-by-section so that gaps in either
direction are visible.

NLSpec explicitly does **not** cover lifecycle, consent, requirement
gathering, decomposition, tooling, or version control (its §16). Those
are precisely the concerns this series specifies. The two formats occupy
different layers: NLSpec is about the body of a specification; the RFC
process is about the identity and obligations of one.

## What it gets right

- **The precision devices are the best part.** Attribute tables with a
  mandatory Default column; classification tables whose Meaning column
  says what the system *does*; error tables with a mandatory Recovery
  column; precedence hierarchies that end in a default; fallback chains
  that terminate; escape hatches marked non-portable. Each one names a
  specific way agents guess, and removes it. None of this exists in the
  BCP or the template today, and an author can follow the BCP exactly
  and still leave every one of these gaps open — they are not
  requirements, so they carry no markers.
- **Out of Scope with an extension point** (§4). Exclusions that name
  where the excluded thing would attach turn "not now" into a known
  integration path. This is strictly better than our current practice,
  where exclusions live in Alternatives Considered or in SKILL.md's
  "Omitted IETF machinery" list with no seam named.
- **Design rationale as a bold question naming the rejected alternative**
  (§5). An implementer about to re-propose the rejected thing finds it
  by its own name. Our Alternatives Considered headings are noun phrases;
  the question form is a cheap, real improvement.
- **Temporal anchors** (§5.2). "At the time of writing (Month YYYY)" on
  perishable data. We pin commits in References for the same reason but
  have no convention for anchoring data inside the body.
- **Requirement density** (§6.3) as a review heuristic: many lines and
  few checkable items means the section has not yet said anything
  provable. Transfers directly to marker density.

## Where it conflicts with this process

1. **The DoD checkbox is self-reported verification.** `[x]` means
   "implemented and verified" — by the implementing agent. The BCP's
   first law is that LLMs author and never verify. NLSpec's closed loop
   (body ↔ DoD) is a real idea, but this series already has the same
   loop mechanically: marker ⇄ evidence pairing, lint-enforced in both
   directions, and the digest as the derived requirement list. The draft
   keeps the DoD as an optional reader's index whose items cite markers,
   and the marker's evidence is the record — never the checkbox.
2. **Pseudocode is normative but unexecutable.** NLSpec makes pseudocode
   and tables normative and examples illustrative (§12.4). In this
   process the only normative *evidence* is what a deterministic runner
   replays; a tagged transcript is a normative example. Pseudocode has
   no runner, so it cannot be evidence. The draft rules it *descriptive*
   — it fixes the reading of a requirement; a runnable block beside it
   proves the requirement — and forbids tagging it.
3. **Decimal numbering and "(see Section 4.2)"**. Numbers move when a
   section is inserted, and our digest drops discursive sections, so a
   numbered reference can dangle. `[R-<slug>]` IDs are permanent once
   published and survive the digest. Rejected.
4. **The (Critical) marker** duplicates BCP 14 strength grading with an
   unenforced second scale. Rejected.

## Defects in NLSpec itself

These are findings about the document as a specification, offered in the
spirit its own §6.2 asks for.

- **§16 violates §4.** The Out of Scope rule demands a four-part entry
  ending in an extension point. Of NLSpec's four Out of Scope items,
  only the first (authoring tooling → the §18 smoke test) names one.
  Requirement gathering, system decomposition, and version control end
  at "outside format specification" — exactly the "sounds permanently
  excluded" failure §4 warns against.
- **The validator omits a mandated section.** §5 says an NLSpec
  *collects* design justifications in a dedicated section or appendix;
  the §18.15 `validate_nlspec` pseudocode checks for TOC, opening
  paragraph, problem statement, DoD, and Out of Scope — not Design
  Decision Rationale. Either §5 is softer than it reads or the validator
  is incomplete.
- **The final DoD item is unfalsifiable.** "A coding agent supplied with
  this spec and a project description produces a conforming NLSpec
  document" — conforming according to whom, checked how? By the format's
  own standard (§6.4: a smoke test an agent can translate directly into
  a real test) this item does not qualify; the pseudocode beneath it is
  the actual test and should be the item.
- **The three exemplar documents (§1.4) are named but not linked.**
  §15.3 requires full URLs for external references. Readers cannot study
  the patterns the format is derived from.
- **§6.1's `[x]` semantics conflate two states.** "Implemented" and
  "verified" are one checkbox; a reader cannot tell a claim from a
  record. The format has no place for evidence at all — the HTML comment
  in §6.6 links to *how* it was satisfied, not to *proof* that it was.

## The authoring BCP, scored against NLSpec's own DoD

Where `draft-ndn-authoring-rfcs-00` stands on the NLSpec checklist,
restricted to items that apply to a process document.

| NLSpec DoD item | BCP today | Note |
|---|---|---|
| Four-phase arc | yes | Motivation → Terminology → Specification → evidence |
| Opening paragraph: what it is, who it is for | yes | Abstract |
| Problem statement: state → problem → solution | yes | Motivation |
| Design principles as bold-lead named constraints | partial | dual verifiability is stated in README, not named in the BCP |
| Layering statement (defines X, not Y) | partial | locality rule under Practice; no "does NOT define" list |
| Out of Scope with extension points | **no** | omissions live in Alternatives (Full IETF machinery) and SKILL.md |
| Design rationale, bold-question form | partial | Alternatives Considered, noun-phrase headings |
| Temporal anchors | n/a | pinned commits in References serve the role |
| DoD mirrors body / items trace to body | yes, stronger | marker ⇄ evidence pairing; digest verified |
| Integration smoke test | yes | every transcript is one; `rfc-check` is the end-to-end |
| Attribute tables with Default column | **no** | sandbox environment (§Evidence conventions) is prose; a `Variable | Value | Note` table would remove guessing |
| Classification tables with behavioral Meaning | partial | lifecycle notes in the fsm; status vocabulary has no consequence column |
| Error categories with Recovery | **no** | `rfc-lint` errors/warnings are not catalogued anywhere |
| Precedence hierarchies numbered with terminal default | yes (SKILL.md) | adapter and sandbox resolution orders; not in the BCP body |
| Formal grammar where syntax exists; syntax ≠ semantics | yes | ABNF with witnesses |
| Established notations | yes | fsm → derived mermaid/D2 |
| Present tense, imperative, negative constraints, why-after-what | yes | consistently |
| Terms defined on first use | yes | Terminology |
| Internal references stable | yes | `[R-]` IDs |
| External references with URLs | partial | RFC numbers without URLs (acceptable: they are stable identifiers) |

## Recommendations

Done in this change:

1. **Candidate-practice draft** `rfc/draft-claude-nlspec-conventions-00.md`
   — the disposition table for every NLSpec convention, the adopted forms
   (Out of Scope, question-form rationale, temporal anchors, precision
   devices, parallel structure, descriptive pseudocode, DoD as index),
   and three proven rules: added sections lint clean; a DoD item naming
   a marker inherits its evidence obligation; a tagged pseudocode block
   is rejected at replay.
2. Index entry under candidate practices.

3. **`skill/template.md`** rewritten with an NLSpec-shaped Specification
   body: layering statement and named principles; Data model
   (descriptive RECORD/ENUM, plain fence, never tagged; ENUM +
   classification table; lifecycle ENUMs become `fsm`); Configuration
   (attribute table with Default; resolution precedence ending in a
   default); Behavior (marker + evidence first, pseudocode with labeled
   steps and a Behavior summary, fallback chain, procedural sequence);
   Errors (table with Recovery; escape hatches marked non-portable);
   `## Out of Scope` with the four-part entry; Alternatives Considered
   in bold-question form; temporal anchors under Compatibility;
   appendices after the Changelog; an explicit "no Definition of Done —
   the digest is the checklist" note. `SKILL.md` step 4 summarizes the
   shape.
4. **BCP body** (`draft-ndn-authoring-rfcs-00`) reshaped, no rule
   changed, corpus green (23 ⇄ 23 markers): a "Scope and principles"
   opener (layering statement naming what each companion draft owns;
   five bold-lead principles); transcript notation as a line-form table;
   sandbox provisions as a witness table of `[R-sandbox-env]`; a status
   consequence table as a witness of `[R-status-vocab]`; a new Masthead
   attribute table with defaults, its value sets proven by a new
   `[R-masthead]` transcript (invalid Category, Corpus, Updates each
   rejected); `## Out of Scope` with four entries and their extension
   points; Alternatives Considered in question form; Appendix A — every
   `rfc-lint` diagnostic with level and recovery.

Still your call:

5. **Lint gap found while proving the draft**: `rfc-lint` pairs an `@R-`
   tag on *any* fence type — `pseudocode @R-x` reports `evidence(1⇄1)`
   and only `rfc-run` rejects it ("no adapter found"). `--expect` catches
   it for a draft declaring green; a lint-time check consulting the
   adapter resolution order would fail faster. The draft's Out of Scope
   names the extension point.
6. **Promotion of the nlspec draft itself.** The template and BCP now
   embody it, so the draft's role is the disposition record and the
   three proven rules. Publish it with the BCP, or fold its Specification
   into the BCP and withdraw it — either is consistent; the first keeps
   the disposition table citable.
