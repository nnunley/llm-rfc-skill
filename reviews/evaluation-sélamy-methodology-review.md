# Fairness Review: Norman RFC Workflow Evaluation Methodology

**Reviewer**: Norman Nunley (fairness reviewer), drafted with Claude Code
**Date**: 2026-08-27
**Document reviewed**: Norman RFC Workflow Evaluation Methodology (Patrick Sélamy), protocol revision Aug 26, 2026 (NORMAN-RFC-P1-20260826)
**Document URL**: https://docs.google.com/document/d/1qBAqBA3wvpv4wdWuwsGre_7yyapsL4b8sfh4YcDcEUQ/edit
**Status**: Seven findings delivered as inline comments anchored in the document

---

## Executive Summary

The protocol is unusually careful for an informal peer evaluation: it explicitly
disclaims statistical claims (one observation per cell supports qualitative
findings only), seals the answer key behind a digest, freezes a protocol
manifest, defines a failure taxonomy that closes the selective-repair loophole,
and makes the post-mortem the evaluation endpoint rather than a score table.

Against that baseline, the review found **three blocking issues** worth settling
before the freeze is exercised, **three fairness notes**, and **one clarity
gap**. None are fatal; the fairness notes are Patrick's to accept or explicitly
decline.

---

## Findings

### 1. The pinned treatment commit ships a known sandbox-containment bug

**Severity**: Blocking
**Location**: "Compared Treatments" — the Norman RFC pin `80ad6020a8b2…fbc98437`

The pin is one commit behind HEAD. The missing commit (`2029b0c`, "fix(sandbox):
scrub every XDG base directory, not just the config one") fixes a leak where the
transcript adapter, env-scrub provider, and rfc-flow preamble redirect `HOME`
and `XDG_CONFIG_HOME` but not `XDG_DATA_HOME`/`XDG_STATE_HOME`/`XDG_CACHE_HOME`
— an XDG-following subject writes through the sandbox onto the host while
reporting green.

This matters twice, both within the Norman RFC cells (no cross-treatment
"infrastructure bias" is implied — the other treatments do not use these
sandboxes):

- the disposable-workspace isolation can be pierced by the treatment's own
  adapters if the jump-box isolation is environment-variable based, so evidence
  sealed as hermetic may not be; and
- the rubric records adapter defects as *framework defects*, so a bug already
  fixed one commit past the pin would be reported as a live flaw.

**Suggested fix**: Re-pin to `2029b0c` before runs start (regenerating the
protocol digest), or pre-register this as a known fixed-post-pin defect.

### 2. Open research conflicts with the competing-repo exclusion

**Severity**: Blocking
**Location**: "Isolation and Execution" — "Read-only public technical research
is allowed and logged" vs. "Competing workflow repositories … are unavailable"

Spec Kit and OpenSpec documentation is public web content, so allowed research
includes the competing workflows' own docs unless something enforces the
exclusion. The protocol names no mechanism and no classification for a breach
(contamination requiring rerun, infrastructure failure, or observed result).

**Suggested fix**: One sentence naming the enforcement mechanism (domain
blocklist, or post-hoc transcript audit) and the breach classification.

### 3. Oracle behavior for out-of-key questions is unspecified

**Severity**: Blocking
**Location**: "Scripted Stakeholder Oracle" — "answers only the question asked"

The oracle answers from a frozen key, but nothing says what it does when asked
something the key does not cover. A stateless oracle improvising out-of-key
answers can hand different cells inconsistent facts, silently breaking the
"same stakeholder-answer policy" guarantee.

**Suggested fix**: Specify a fixed fallback (e.g., "the stakeholder has no
requirement on that; use your judgment and record the assumption") and log
key-miss questions as a fixture-coverage signal.

### 4. The rubric's evidence-and-adapters dimension encodes the RFC workflow's values

**Severity**: Fairness note
**Location**: Rubric table under "Independent blind review" — "Evidence,
testability, traceability, vocabulary, and adapters — 15"

Evidence vocabulary and executable adapters are a quality theory the RFC
workflow claims to serve; Spec Kit and OpenSpec never promise them. Scoring all
three treatments on this dimension is defensible for a study whose purpose is
feedback to Norman, but without an acknowledgment the headline risks reading as
"the RFC workflow wins the dimension it invented," and baseline scores here
measure a gap the baselines never claimed to close.

**Suggested fix**: A sentence declaring that this dimension weights the RFC
workflow's own theory of quality.

### 5. Deleting openspec/ affects the OpenSpec treatment specifically

**Severity**: Fairness note
**Location**: "Brownfield Fixture" — "removes the existing openspec/ directory"

Removal is necessary (the directory contains prior workflow-generated answers),
but OpenSpec's model is proposing changes against living project truth; deleting
its truth store forces it to bootstrap greenfield inside a brownfield repo, a
cost the other two treatments do not pay in kind.

**Suggested fix**: Pre-register this as a known fixture effect on the OpenSpec
cells rather than leaving it to be rediscovered as a finding.

### 6. The 12-question cap binds asymmetrically

**Severity**: Fairness note
**Location**: "Isolation and Execution" — "Shared per-cell limits are 60
minutes and 12 stakeholder questions"

The hidden answer key spans roughly ten fact areas; the RFC workflow's
interview phase is one question per message until convergence, while Spec Kit's
clarify step is bounded by design. The cap therefore weighs most heavily on the
treatment whose core mechanism is questioning — and the failure classification
counts budget exhaustion as an observed workflow failure.

**Suggested fix**: Raise the cap, or reclassify budget exhaustion as a recorded
design property (questions asked, fact-area coverage achieved) rather than a
failure mode.

### 7. The reviewer pool is unspecified

**Severity**: Clarity
**Location**: "Independent blind review" — "Two reviewers score each artifact
independently"

Human or LLM, who they are, and whether the owner is one of them (a conflict,
given the owner also authored the protocol) are unstated. Blinding will also
largely fail — an IETF-style draft, a Spec Kit constitution bundle, and an
OpenSpec proposal tree are identifiable at a glance. The confidence-guess
mechanism honestly measures that failure; the protocol should say whether
confidently broken blinding triggers anything (sensitivity note, discount, or
nothing).

**Suggested fix**: Name the reviewer pool and state the consequence of recorded
broken blinding.

---

## Also noted (not filed as an inline comment)

The 60-minute cell cap falls unevenly across ceremony counts — four RFC phases
versus seven Spec Kit stages versus three OpenSpec stages. That asymmetry is
arguably the ceremony cost the study wants to measure, but stating the
interpretation explicitly would keep a Spec Kit timeout from being read as a
harness problem.

---

## Strengths worth keeping

- Refuses the usual overclaims: qualitative-only findings, harness results
  never pooled, every claim cites its supporting cells.
- Sealed answer key with digest, frozen protocol manifest, and the rule that
  later changes require a new protocol digest.
- Failure taxonomy (infrastructure failure with one clean rerun vs. observed
  workflow result with no favorable reruns) closes the selective-repair
  loophole.
- Post-mortem as the evaluation endpoint is the right deliverable for a study
  whose purpose is actionable peer feedback.

---

## Appendix: Inline comment anchors in the Google Doc

1. "Compared Treatments" — anchored on `80ad6020a8b2…fbc98437` (finding 1)
2. "Brownfield Fixture" — anchored on "openspec" (finding 5)
3. "Scripted Stakeholder Oracle" — anchored on "question" in "answers only the
   question asked" (finding 3)
4. "Isolation and Execution" — anchored on "research" in "Read-only public
   technical research is allowed and logged" (finding 2)
5. "Isolation and Execution" — anchored on "stakeholder" in "12 stakeholder
   questions" (finding 6)
6. Rubric table — anchored on "adapters" in "Evidence, testability,
   traceability, vocabulary, and adapters — 15" (finding 4)
7. "Independent blind review" — anchored on "reviewers" in "Two reviewers
   score each artifact independently" (finding 7)

A standalone rendering of this review is published (private) at
https://claude.ai/code/artifact/c9b9cf17-6616-4d41-8f76-f456e600eac7

---

**Correction note (2026-08-27)**: This file replaces an earlier draft that
inflated all seven findings to "critical," attributed a goal statement to the
methodology that it does not contain, misplaced the pinned-commit finding in
"Brownfield Fixture," framed the stale pin as a cross-treatment infrastructure
bias, and paraphrased document text as direct quotes. This revision matches the
comments actually delivered in the document.
