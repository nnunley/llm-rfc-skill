# draft-claude-adversarial-review-00: Adversarial Review as RFC Practice

**Status:** DRAFT
**Category:** Experimental
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-14

## Abstract

Adversarial review is a pre-publication review phase for RFC drafts that uses agent judgment to find design flaws before publication gates them. This specification codifies the practice as adoptable process machinery: reality-check-first protocol, severity-ranked findings presented one at a time, resolution recorded in the draft's Changelog. The practice is derived from PAAD (Curtis "Ovid" Poe, v1.11.0). This document specifies the protocol for human and agent reviewers, clarifies the distinction between discovery (agent judgment) and conformance (deterministic verification), and gates publication on the RFC process's evidence requirements, not on adversarial review findings.

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

## Specification

### Adversarial Review Protocol

Every RFC draft MUST receive at least one adversarial review pass before entering LAST-CALL. Fast-track publications SHOULD receive a review pass scaled to the change's stakes and scope — a single-line fix might warrant a lightweight pass, while a normative redesign deserves a full protocol run.

The protocol proceeds through the following state machine:

```fsm
initial INTAKE
INTAKE -> REALITY_CHECK
REALITY_CHECK -> SCOPE_SHAPE
SCOPE_SHAPE -> DETAILED_FINDINGS
DETAILED_FINDINGS -> PRESENTATION
PRESENTATION -> REVIEW_LOOP
REVIEW_LOOP -> RESOLUTION
REVIEW_LOOP -> SCOPE_SHAPE
REVIEW_LOOP -> PRESENTATION
RESOLUTION -> DONE
terminal DONE
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

#### Phase 4: Issue Presentation

Present findings one at a time to the document author, in severity order.

For each finding:
1. State the problem clearly.
2. Present concrete options from best to worst.
3. Include a recommendation and brief explanation for each option.
4. Wait for the author's response before presenting the next finding.

The author can say "good enough" or "stop" at any point to end the review.

#### Phase 5: Resolution

For each addressed finding, record the author's decision in the draft's Changelog. This creates a durable record of what was reviewed and what the author chose to do about it.

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

- Curtis "Ovid" Poe, **PAAD** (Practical Architecture and Development) — the source repository is https://github.com/Ovid/paad (reviewed at commit 149926aa231e, v1.11.0). The pushback skill in PAAD implements the adversarial review protocol specified in this document.
- draft-ndn-authoring-rfcs-00, "The RFC Process for Human–LLM Specification Authoring" — the parent process BCP that this practice complements. Discovery (adversarial review) and conformance (evidence verification) are complementary gates, not redundant.
- RFC 7282, "On Consensus and Humming in the IETF" — adversarial review is one instrument in the consensus-building process; rough consensus and running code remain the arbiter.
- RFC 2026, RFC 6410 — RFC categories and process maturity stages; Experimental category permits provisional adoption of new practices.

## Changelog

- 2026-08-14: draft-00 created. Codified adversarial review protocol as adoptable practice (discovery instrument for RFC drafting, distinct from deterministic conformance verification). Specified phases: reality check (upfront showstopper detection), scope shape (cohesion and size), detailed findings (six categories ranked by severity), one-at-a-time presentation with options, resolution recorded in Changelog. Placed in lifecycle: MUST complete before LAST-CALL; SHOULD complete for fast-track. Clarified discovery/conformance doctrine: agent judgment is discovery; determinism is conformance; both required; neither substitutes; LLMs never sit in verification loop. Derived from PAAD (Curtis "Ovid" Poe, v1.11.0), pushback skill. Field evidence: protocol ran twice on RFC drafts 2026-08-14, surfaced critical findings each time (non-replayable evidence syntax; unspecified state transitions). Specified FSM for protocol phases with realistic state transitions (loop-back for continue, early-stop, restart-on-split, terminal done). Addressed security (reviewer access to sensitive repository content; bad-faith findings). Rejected alternatives: direct BCP amendment (practices join as RFCs, promoted by decision) and review-as-documentation (provides guidance but no machinery). Experimental status: provisional adoption pending evidence at scale; future decision will promote to BCP if durable.
