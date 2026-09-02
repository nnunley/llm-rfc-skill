# Methodology Review Summary

## Overview

This directory contains formal evaluation reviews of RFC workflow evaluation methodologies and related documents.

## Current Reviews

### NLSpec Review and Conversion
**File**: `nlspec-review.md`  
**Author**: James Hugman (NLSpec), Norman Nunley / Claude (review)  
**Date**: 2026-09-01  
**Status**: Complete — converted into `rfc/draft-claude-nlspec-conventions-00.md`; applied to `skill/template.md` and the body of `rfc/draft-ndn-authoring-rfcs-00.md` (gate green, 22 documents)

#### Summary

Review of NLSpec (jhugman/nlspec @ `eae0052c948f`), a specification format
for coding-agent implementers, and its conversion into a candidate-practice
draft for this series.

**Key Findings**:
- **Complementary layers**: NLSpec specifies the body of a spec; the RFC process specifies identity, lifecycle, consent, and evidence — no overlap in scope
- **Adopted**: attribute tables with defaults, precedence/fallback/recovery devices, Out of Scope with extension points, bold-question design rationale, temporal anchors
- **Transformed**: the Definition of Done checkbox (self-reported) becomes the existing marker ⇄ evidence loop; pseudocode ruled descriptive, never evidence
- **Rejected**: decimal numbering, TOC, (Critical) marker, `[x]` as verification
- **5 defects in NLSpec itself** (its Out of Scope violates its own §4 rule; validator omits a mandated section; unfalsifiable final DoD item; unlinked exemplars; implemented/verified conflated)
- **1 lint gap found in this series**: `rfc-lint` pairs `@R-` on any fence type; only `rfc-run` rejects an unrunnable one

### Norman RFC Workflow Evaluation Methodology Review
**File**: `evaluation-sélamy-methodology-review.md`  
**Author**: Patrick Sélamy (methodology), Claude (Anthropic) (review)  
**Date**: 2026-08-27  
**Status**: Complete

#### Summary

A comprehensive formal evaluation of the three-way experimental comparison methodology for Norman RFC, Spec Kit, and OpenSpec workflows.

**Key Findings**:
- **7 structural issues identified** (2 HIGH severity, 5 MEDIUM severity)
- **Issues affect**: fairness, clarity, internal consistency, and experimental validity
- **None are fatal**, but collectively undermine reproducibility and comparability
- **All issues include specific remediation recommendations**

#### Issues Identified

1. **Infrastructure bias** (HIGH): Pinned commit contains documented bug; current HEAD has fix
2. **Fixture bias** (HIGH): Brownfield constraint disproportionately disadvantages OpenSpec
3. **Specification gap** (MEDIUM): Undefined Oracle behavior for out-of-scope questions
4. **Policy contradiction** (MEDIUM): "Public research allowed" vs. "competing frameworks banned" tension
5. **Asymmetric constraints** (MEDIUM): Interaction budget may favor documentation-heavy workflows
6. **Rubric bias** (MEDIUM): Evaluation dimensions reflect RFC workflow's quality theory, not workflow-neutral
7. **Process ambiguity** (MEDIUM): Reviewer pool, blinding procedures, and failure handling unspecified

#### Deliverables

1. **Formal evaluation document** (this file: `evaluation-sélamy-methodology-review.md`)
   - Executive summary
   - Detailed analysis of each issue
   - Severity assessment and evidence
   - Specific, actionable recommendations
   - Positive observations about methodology strengths
   - Next steps and sign-off requirements

2. **Inline comments** on Google Doc
   - Seven substantive technical comments added to original document
   - Comments map 1:1 to issues identified in formal review
   - Locations: https://docs.google.com/document/d/1qBAqBA3wvpv4wdWuwsGre_7yyapsL4b8sfh4YcDcEUQ/edit

#### Recommendations for Proceeding

**Before Starting Trials (Required)**:
- Resolve pinned commit decision
- Clarify OpenSpec fixture constraint or redesign for neutrality
- Specify Oracle behavior for out-of-scope questions
- Resolve public research vs. banned workflows policy contradiction

**Before Blind Review (Strongly Recommended)**:
- Document interaction budget and justify across treatments
- Audit and justify rubric dimensions
- Specify reviewer procedures (selection, blinding, failure handling)

**After Remediation**:
- Patrick Sélamy or designated stakeholder to confirm issue resolution
- Issues triage: classify as blocking, high-priority, or acceptable
- Formal sign-off before trials proceed

---

## Process Notes

### Review Methodology
- Document review of methodology document
- Infrastructure verification (git commit state, code examination)
- Fairness audit across three treatments
- Consistency checks within methodology
- Clarity assessment of specifications

### Reviewer Expertise
- Deep knowledge of RFC workflow design and implementation
- Experience with experimental design and methodology auditing
- Familiarity with multi-treatment comparison frameworks
- Understanding of sandbox isolation and reproducibility constraints

### Quality Assurance
- All issues verified against source document
- Evidence provided for each claim
- Recommendations are specific and actionable
- Comments cross-reference formal review
- Status tracking in summary table

---

## Contact & Follow-Up

**Review completed by**: Claude (Anthropic)  
**Date**: 2026-08-27  
**For questions about this review**: See formal evaluation document

**To respond to findings**:
1. Review issues in formal evaluation document
2. Classify each as blocking, high-priority, or acceptable
3. Provide resolution plan or justification for each issue
4. Request formal sign-off when resolved
