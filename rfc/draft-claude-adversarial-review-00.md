# draft-claude-adversarial-review-00: Adversarial Review as RFC Practice

**Status:** DRAFT
**Category:** Experimental
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-14

## Abstract

Adversarial review is a pre-publication review phase for RFC drafts that uses agent judgment to find design flaws before publication gates them. This specification codifies the practice as adoptable process machinery: reality-check-first protocol, severity-ranked findings presented one at a time, resolution recorded in the draft's Changelog. The practice draws on two lineages: PAAD (Curtis "Ovid" Poe, v1.11.0) — a collection of processes, of which the pushback skill sources the per-reviewer protocol and the agentic-* skills define specialist dispatch — and Jesse Vincent's PAR (prime-radiant), the same-prompt redundant-dispatch form. This document specifies the protocol for human and agent reviewers, clarifies the distinction between discovery (agent judgment) and conformance (deterministic verification), and gates publication on the RFC process's evidence requirements, not on adversarial review findings.

## Motivation

Adversarial review fills a gap between spec authoring and publication: specifications can be internally inconsistent, assume infrastructure that no longer exists, or hide security issues that deterministic linting cannot reach. Evidence verification (rfc-run and rfc-lint) checks whether a published specification's claims are true; adversarial review checks whether the claims themselves are sound *before* publication. The two are complementary, not redundant.

Field evidence for adoption: on 2026-08-14, adversarial review was conducted twice against drafts in this repository using the protocol described below (reality check, findings ranked by severity, presented one at a time). Both reviews surfaced critical findings:
- Finding 1: Non-replayable evidence transcripts — expected-output lines beginning with `$ ` cannot be expressed literally in the evidence block syntax.
- Finding 2: Unspecified state transitions — LAST-CALL had no specified outbound paths, making the draft's lifecycle machine incomplete.

Both findings were addressed by the authors before publication. Without adversarial review, these gaps would have entered published specification, requiring either retroactive amendment or errata. The protocol's one-at-a-time presentation and severity ranking ensure high-impact issues surface first, when fixes are cheapest.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **Adversarial review** — a pre-publication review of an RFC draft that hunts for inconsistencies, infeasibility, and design flaws.
- **Reality check** — verification that a draft's references to repositories, artifacts, APIs, infrastructure, or patterns still exist and have not been recently changed.
- **Discovery** — the process of finding what is wrong (the domain of agent judgment and adversarial review).
- **Conformance** — the process of verifying that artifacts keep their promises (the domain of deterministic verification and evidence replay).
- **Reviewer** — a human or agent conducting adversarial review; may be the document author or a third party.
- **Parallel adversarial review (PAR)** — Jesse Vincent's design
  (prime-radiant): a one-shot quality GATE, not a loop — two or more
  independent reviewers dispatched once with the SAME prompt, no shared
  context, competitive framing, findings aggregated by union. Redundancy
  is the instrument: the same finding from identically-tasked reviewers
  is the high-confidence signal. Any looping (re-review after revision)
  belongs to the process that invokes the gate.
- **Specialist dispatch** — PAAD's design (the agentic-* skills):
  parallel reviewers with DIFFERENT specialized prompts, one per
  dimension (structure, coupling, security, ...). Diversity is the
  instrument: specialists surface failure modes no shared prompt would
  reach, and their findings are largely disjoint by design.
- **Review loop** — the larger process specified here, which dispatches
  either form (or both) and consolidates and adjudicates their findings
  before any reach the author. The per-reviewer phase protocol is a tool
  used inside it.
- **Consolidation** — the union of all reviewers' findings, severity
  taken as the worst assigned. Duplicate handling follows the dispatch
  form: under PAR (same prompt) a duplicate is the confidence signal;
  under specialist dispatch (different prompts) duplicates across
  specialists are incidental and overlap signals a boundary-crossing
  finding worth extra scrutiny.
- **Adjudication** — per-claim validation against the artifact itself:
  each consolidated finding is checked for reproducibility and
  substantiation, and a claim that cannot be validated is dropped, never
  presented. Disagreement between reviewers is resolved by evidence, not
  authority.

## Specification

### The Review Loop

Every RFC draft MUST receive at least one adversarial review pass before entering LAST-CALL. Fast-track publications SHOULD receive a review pass scaled to the change's stakes and scope — a single-line fix might warrant a lightweight pass, while a normative redesign deserves a full protocol run.

The larger loop dispatches independent reviewers, consolidates their
findings, and adjudicates every claim before the author sees any of it.
The dispatch form is chosen at intake: PAR (same prompt, redundancy as
confidence — Jesse Vincent's design) or specialist dispatch (different
prompts per dimension, diversity as reach — PAAD's design), or both when
stakes warrant. With a single reviewer (lightweight pass) consolidation
is the identity, but adjudication is REQUIRED regardless of reviewer
count — plausible but unsubstantiated claims die there, not in front of
the author.

```fsm
initial INTAKE
INTAKE -> PARALLEL_REVIEW
PARALLEL_REVIEW -> CONSOLIDATION
CONSOLIDATION -> ADJUDICATION
ADJUDICATION -> PRESENTATION
PRESENTATION -> REVIEW_LOOP
REVIEW_LOOP -> RESOLUTION
REVIEW_LOOP -> PARALLEL_REVIEW    ; substantive revision triggers re-review
REVIEW_LOOP -> PRESENTATION       ; next finding
RESOLUTION -> DONE
terminal DONE
note INTAKE: identify the artifact and stakes — choose dispatch form (PAR same-prompt, specialist different-prompts, or both) and reviewer count
note PARALLEL_REVIEW: independent reviewers, no shared context — each runs the phase protocol under its assigned prompt
note CONSOLIDATION: union of findings — severity = worst assigned — duplicates read per dispatch form (PAR: confidence, specialist: boundary-crossing)
note ADJUDICATION: validate each claim against the artifact — unsubstantiated claims are dropped, never presented
note PRESENTATION: one adjudicated finding at a time, severity order — the author may stop at any point
note REVIEW_LOOP: record the disposition, then next finding, re-review, or resolve
note RESOLUTION: decisions recorded in the Changelog
```

### The Per-Reviewer Phase Protocol

Each reviewer dispatched in PARALLEL_REVIEW independently runs this
protocol (derived from PAAD's pushback flow) and ends by REPORTING its
findings into consolidation — a reviewer never presents to the author:

```fsm
initial INTAKE
INTAKE -> REALITY_CHECK
REALITY_CHECK -> SCOPE_SHAPE
SCOPE_SHAPE -> DETAILED_FINDINGS
DETAILED_FINDINGS -> REPORT
terminal REPORT
note REALITY_CHECK: verify the draft's assumptions against current repository state
note SCOPE_SHAPE: cohesion and size before detail
note DETAILED_FINDINGS: categorized, severity-ranked findings
note REPORT: findings handed to consolidation, nothing withheld, nothing presented
```

#### Phase 1: Reality Check

Reality check verifies that the draft's assumptions about repository state are current.

1. For each reference in the draft to infrastructure, APIs, code patterns, tables, workflows, or artifacts:
   - Check whether the reference still exists in the current state.
   - For recent references (commits in the last 2 weeks), check the actual diff to understand what changed.
2. Compile a list of conflicts: (a) what the draft assumes, (b) what actually changed, (c) why it matters.
3. If conflicts are found, surface them to the document author upfront as showstoppers, before proceeding to detailed critique. Author addresses each conflict (option: update draft; option: note it as intentional) before review continues.
4. If no conflicts are found, proceed to Phase 2.

#### Phase 2: Scope Shape Check

Scope shape check identifies structural problems before detailed critique begins.

1. **Feature cohesion:** Do the features in this draft serve different user goals or business objectives? If unrelated features are bundled together (features meant to be independent PRs or documents), flag cohesion as a finding.
2. **Document size:** Apply heuristics (8+ requirements, multiple distinct system areas, very long document, estimated implementation touches many modules). When large, assess decomposition feasibility: are features independent (each delivers standalone value) or architecturally intertwined? Flag size when decomposition is practical and advised.
3. Present findings if any; author can choose to split or proceed as-is. If split is chosen, restart review on each piece.

#### Phase 3: Detailed Findings

Analyze the draft across these categories, ranked by impact on publication success:

| Category | What to look for |
|----------|-----------------|
| **Contradictions** | Requirements that conflict with each other or with current codebase state |
| **Feasibility** | Requirements technically difficult or impossible given current state — missing infrastructure, incompatible architecture, unsupported dependencies |
| **Scope imbalance** | Requirements whose effort is wildly disproportionate (one section requires a 2-week project; others are 2-hour tasks) |
| **Omissions** | Missing requirements implied or necessary given context — error handling, edge cases, migration paths, monitoring, permissions |
| **Ambiguity** | Requirements interpretable multiple ways — vague success criteria, undefined terms, unclear scope boundaries |
| **Security concerns** | Requirements that introduce or ignore security risks — auth gaps, data exposure, injection surfaces, hard-coded credentials, missing rate limits |

Rank all findings by severity (most impactful first).

### Consolidation and Adjudication

Consolidation merges the reviewers' reports: identical findings collapse
to one carrying high confidence; unique findings survive on their own;
severity is the worst any reviewer assigned. No finding is discarded at
this stage — consolidation organizes, it does not judge.

Adjudication judges. Each consolidated claim is validated against the
artifact itself: does the cited text say what the claim says it says,
does the conflict reproduce, does the missing thing actually not exist?
A claim that cannot be substantiated is dropped and the drop is logged
with its reason (the verification pass of PAAD's agentic-review is the
prior art: findings verified to filter false positives before anyone
acts on them). The adjudicator MUST be distinct from the reviewers
whose claims it judges (fresh context — a reviewer adjudicating its own
finding inherits its own framing). Only adjudicated findings proceed.

### Presentation and Resolution

Present adjudicated findings one at a time to the document author, in
severity order: state the problem, offer concrete options best to worst
with a recommendation, and wait for the author's response before the
next finding. The author can say "good enough" or "stop" at any point.

For each addressed finding, record the author's decision in the draft's
Changelog — a durable record of what was reviewed, what was dropped in
adjudication and why, and what the author chose to do.

### Placement in the RFC Lifecycle

A document in DRAFT status MUST complete at least one adversarial review pass before entering LAST-CALL. The Changelog MUST record that the review occurred, which reviewer(s) conducted it, and the date.

Fast-track publications (DRAFT → PUBLISHED without LAST-CALL) SHOULD receive an adversarial review pass. The decision to skip review for fast-track (scaled by stakes) is the author's, not mandatory.

### Discovery vs. Conformance

Adversarial review is a discovery instrument: it finds what is wrong with a draft through agent judgment, reasoning, and design critique. Deterministic verification (evidence replay and rfc-lint) is a conformance instrument: it verifies that the published RFC keeps its promises.

The distinction is normative:

- **Discovery (adversarial review):** hunts for inconsistencies, infeasibility, security gaps, missing requirements, and design issues. Findings are based on agent judgment and vary between reviews. Findings feed the author's revision process before publication.
- **Conformance (deterministic verification):** checks whether evidence blocks replay without error, whether requirement markers have corresponding evidence, whether FSM blocks are syntactically valid, and whether the document structure obeys the RFC format. Conformance is reproducible, auditable, and automated in CI.

Both MUST be satisfied before publication. Adversarial review feeds drafting; deterministic verification gates publication. Neither replaces the other. The RFC process law "LLMs never sit in the verification loop" is unchanged: agent judgment is discovery for identifying issues; determinism is conformance for verifying promises are kept.

## Alternatives Considered

### Amendment to the process BCP itself

Rejected. Process practices evolve, and the RFC process BCP (draft-ndn-authoring-rfcs-00) is foundational across projects. Adversarial review is provisional — adopted on evidence from this repository but not yet proven at scale. This document is Experimental, not BCP. If the practice proves durable across multiple projects and evidence builds, a future RFC can promote it to BCP by updating the parent process document. Until then, adversarial review lives as an adoptable practice that projects can choose to implement.

### Review-as-documentation instead of adoptable machinery

Rejected. Documenting adversarial review as an informational technique (e.g., in a skill README) provides guidance but creates no machinery and no obligation. Codifying as a practice specification — with uppercase BCP 14 keywords, with Changelog recording, with clear phase flow — makes adoption explicit and auditable. Projects that adopt this RFC can cite it in their own RFC series and enforce the practice via lint rules.

## Security Considerations

**Reviewers read repository content.** Adversarial review requires the reviewer (human or agent) to examine the draft's references against actual repository state, examining commit histories, code, and infrastructure. A compromised reviewer could extract sensitive information or steer the review toward unfavorable findings. Mitigation: conduct review on trusted infrastructure only; for agent reviewers, do not use adversarial review on untrusted networks or in untrusted cloud environments; do not invoke agent reviewers in contexts where the provider's terms of service forbid sharing of proprietary code.

**Findings influence what merges.** Adversarial review findings, if acted upon, shape what gets published. A bad-faith reviewer could hide legitimate design issues or fabricate false ones. Mitigation: record the reviewer identity and date in the Changelog; encourage multi-reviewer passes; the RFC process's consensus gate (Consent is registered, never inferred) provides human adjudication as the final check.

## References

- Curtis "Ovid" Poe, **PAAD** (Practical Architecture and Development) — the source repository is https://github.com/Ovid/paad (reviewed at commit 149926aa231e, v1.11.0). PAAD is a collection of processes, two of which this document draws on: the **pushback** skill is the source of the per-reviewer phase protocol, and the **agentic-review** subskill — parallel SPECIALIST reviewers with different prompts per dimension, findings verified to filter false positives, severity-ranked reporting — is the specialist-dispatch form and the prior art for the adjudication stage.
- Jesse Vincent, **PAR** (parallel adversarial review) — the same-prompt redundant-dispatch form, as designed in prime-radiant's iterative-development methodology. https://github.com/prime-radiant-inc/iterative-development (reviewed as installed from prime-radiant-inc/prime-radiant-marketplace at commit 49a45efb72af); see also draft-claude-iterative-development-00.
- draft-ndn-authoring-rfcs-00, "The RFC Process for Human–LLM Specification Authoring" — the parent process BCP that this practice complements. Discovery (adversarial review) and conformance (evidence verification) are complementary gates, not redundant.
- RFC 7282, "On Consensus and Humming in the IETF" — adversarial review is one instrument in the consensus-building process; rough consensus and running code remain the arbiter.
- RFC 2026, RFC 6410 — RFC categories and process maturity stages; Experimental category permits provisional adoption of new practices.

## Changelog

- 2026-08-14: draft-00 created. Codified adversarial review protocol as adoptable practice (discovery instrument for RFC drafting, distinct from deterministic conformance verification). Specified phases: reality check (upfront showstopper detection), scope shape (cohesion and size), detailed findings (six categories ranked by severity), one-at-a-time presentation with options, resolution recorded in Changelog. Placed in lifecycle: MUST complete before LAST-CALL; SHOULD complete for fast-track. Clarified discovery/conformance doctrine: agent judgment is discovery; determinism is conformance; both required; neither substitutes; LLMs never sit in verification loop. Derived from PAAD (Curtis "Ovid" Poe, v1.11.0), pushback skill. Field evidence: protocol ran twice on RFC drafts 2026-08-14, surfaced critical findings each time (non-replayable evidence syntax; unspecified state transitions). Specified FSM for protocol phases with realistic state transitions (loop-back for continue, early-stop, restart-on-split, terminal done). Addressed security (reviewer access to sensitive repository content; bad-faith findings). Rejected alternatives: direct BCP amendment (practices join as RFCs, promoted by decision) and review-as-documentation (provides guidance but no machinery). Experimental status: provisional adoption pending evidence at scale; future decision will promote to BCP if durable.
- 2026-08-14: restructured on review — the review loop separated from
  the PAAD-derived phase protocol, which is one reviewer's tool inside
  it. The loop machine gains CONSOLIDATION (union, worst
  severity) and ADJUDICATION (per-claim validation by a fresh-context
  adjudicator; unsubstantiated claims dropped and logged) between the
  parallel reviewers and the author; the per-reviewer machine ends at
  REPORT and never presents. Both machines carry stage notes for the
  executor.
- 2026-08-14: attribution corrected on author review — PAAD is a
  collection of processes, not one protocol: pushback sources the
  per-reviewer phase protocol, and the agentic-review subskill (parallel
  specialists, verification filtering false positives) is prior art for
  the loop's verification stage.
- 2026-08-14: second correction on author review — PAR and specialist
  dispatch are DIFFERENT parallelism designs, previously conflated: PAR
  (Jesse Vincent, prime-radiant) dispatches the SAME prompt and reads
  redundant agreement as confidence; PAAD's agentic-* skills dispatch
  DIFFERENT specialized prompts and buy reach through diversity. The
  review loop now names both as intake-selectable dispatch forms with
  form-dependent duplicate semantics in consolidation.
