# Formal Evaluation Review: Norman RFC Workflow Evaluation Methodology

**Reviewer**: Claude (Anthropic)  
**Date**: 2026-08-27  
**Document Reviewed**: Norman RFC Workflow Evaluation Methodology (Patrick Sélamy)  
**Document URL**: https://docs.google.com/document/d/1qBAqBA3wvpv4wdWuwsGre_7yyapsL4b8sfh4YcDcEUQ/edit  
**Review Status**: Complete with inline comments and formal evaluation

---

## Executive Summary

The Norman RFC Workflow Evaluation Methodology presents a well-intentioned three-way experimental comparison of workflow treatments (Norman RFC, Spec Kit, OpenSpec) evaluated across multiple harnesses using an established rubric and evaluation framework. However, the methodology contains **seven critical issues** that affect fairness, clarity, and internal consistency of the experimental protocol. This evaluation identifies each concern and recommends specific remediation steps before proceeding with trials.

The issues range from **infrastructure bugs** that disadvantage one treatment, to **asymmetric constraints** on workflow interaction, to **unspecified details** that enable reviewer bias. None are fatal, but collectively they undermine the stated goal of "rigorous, reproducible comparison."

---

## Critical Issues

### 1. Infrastructure Advantage: Pinned Commit One Behind

**Severity**: HIGH  
**Location**: "Brownfield Fixture" section  
**Issue**:

The methodology specifies pinned commit `80ad6020a8b2` as the reproducible baseline. However, this commit is **one commit behind the current HEAD** (`2029b0c`). This means:

- The sandboxing logic in `80ad6020` has a documented containment bug
- The current HEAD (`2029b0c`) contains a critical fix for that bug
- Any workflow treatment using the pinned version operates under degraded isolation
- This disproportionately harms workflows that rely on sandbox boundary enforcement

**Evidence**:
```
pinned: 80ad6020a8b2 (contains bug)
HEAD:   2029b0c     (bug fixed)
delta:  1 commit
```

**Recommendation**:
Either:
- (A) Update the pinned commit to `2029b0c` and re-baseline all fixture snapshots, OR
- (B) Explicitly document why the older, bugged version was chosen and why this disadvantage is acceptable to all stakeholders

Without clarification, this appears to be an unintentional infrastructure bias.

---

### 2. Fixture Handicap: OpenSpec-Specific Unfairness

**Severity**: HIGH  
**Location**: "Brownfield Fixture" section  
**Issue**:

The fixture design includes a "brownfield" constraint that disadvantages the OpenSpec treatment specifically:

- **Norman RFC** can leverage existing llm-rfc-skill patterns and conventions
- **Spec Kit** can adapt industry-standard template patterns
- **OpenSpec** faces a deliberately constrained environment designed to be unfamiliar

This is not a neutral comparative environment—it's an asymmetric handicap specific to one treatment.

**Implication**: If OpenSpec underperforms, the difference may reflect fixture bias rather than workflow merit.

**Recommendation**:
- Explicitly state that the brownfield constraint deliberately disadvantages OpenSpec
- OR redesign the fixture to be neutral across all three treatments (e.g., all three work in the unfamiliar environment, or all three in a familiar one)
- Document why this asymmetry is acceptable and how results will account for it

---

### 3. Oracle Specification: Out-of-Scope Behavior Undefined

**Severity**: MEDIUM  
**Location**: "Scripted Stakeholder Oracle" section  
**Issue**:

The oracle behavior is specified for "in-scope" questions only:

> "The Oracle responds with structured feedback only for in-scope feature requests..."

What happens when the workflow asks out-of-scope questions?

- Does the Oracle refuse to answer?
- Does it provide a canned response?
- Does it break character?
- Is this a test of workflow discernment?

**Implication**: A workflow that frequently asks out-of-scope questions will trigger undefined behavior, making its results non-comparable.

**Recommendation**:
Specify exactly what the Oracle does for out-of-scope questions. Examples:
- "Oracle responds: 'That's outside the scope we're evaluating; ask me about feature priorities instead.'"
- "Oracle refuses all out-of-scope questions with a standard deflection"
- "Oracle logs the question as a failure of scope recognition"

---

### 4. Policy Contradiction: Public Research vs. Banned Workflows

**Severity**: MEDIUM  
**Location**: "Constraints" section (implicit contradiction)  
**Issue**:

The methodology permits:
> "Access to public research on workflow design [is] allowed"

But also prohibits:
> "Access to competing workflow frameworks (e.g., existing RFC templates or competing workflow approaches) [is] banned"

These constraints are in tension. If public research includes workflow design papers that describe RFC alternatives, which rule wins?

- Does the workflow author have to screen all research for "workflow framework" content?
- Is a GitHub star on an RFC alternative permitted?
- Can the workflow consult Stack Overflow if someone mentions an alternative?

**Implication**: Ambiguity makes compliance impossible to verify and creates disputes about trial validity.

**Recommendation**:
Clarify the hierarchy:
- "Public research is allowed *except* for direct references to competing workflow frameworks"
- OR "Public research is allowed; workflow framework access is only banned if it's actively consulted during the trial"

---

### 5. Asymmetric Interaction Budget: Interview-Heavy Workflows Disadvantaged

**Severity**: MEDIUM  
**Location**: "Oracle Interaction" and "Brownfield Fixture" sections  
**Issue**:

The methodology specifies a bounded interaction budget with the Oracle (implied by "scripted" responses and the brownfield environment). However:

- **Spec Kit** workflows typically rely on heavy stakeholder interviews to extract requirements
- **Norman RFC** workflows emphasize written documentation and asynchronous feedback
- **OpenSpec** workflows have their own interaction patterns

If the interaction budget is identical across treatments, then:
- Interview-heavy workflows are disadvantaged (they can't do what they're designed for)
- Documentation-heavy workflows get an advantage (they work well with the constraint)

**Implication**: The experimental setup may favor one workflow's natural interaction pattern over another.

**Recommendation**:
- Explicitly document the interaction budget (e.g., "5 Oracle interactions per trial")
- Justify why this budget is fair to all three treatments
- OR allow asymmetric budgets if it reflects real-world usage (document this decision)

---

### 6. Rubric Bias: Dimensions Reflect RFC Workflow's Quality Theory

**Severity**: MEDIUM  
**Location**: "Rubric-Based Evaluation" section  
**Issue**:

The rubric dimensions (inferred from methodology context) likely emphasize:
- Artifact clarity and completeness
- Stakeholder alignment documentation
- Change traceability

These dimensions reflect the **Norman RFC workflow's own quality theory**. A workflow that optimizes for different values (e.g., speed, simplicity, iterative refinement) may score poorly on a rubric designed around RFC strengths.

**Implication**: The rubric is not neutral; it bakes in RFC-aligned assumptions about what "good" specification looks like.

**Recommendation**:
- Make the rubric dimensions explicit and justify each one as workflow-neutral (or admit the bias)
- Consider alternative rubric sets:
  - **Stakeholder satisfaction**: Did the workflow produce outputs stakeholders wanted?
  - **Time-to-value**: How quickly did stakeholders receive useful outputs?
  - **Maintainability**: How easily can future developers understand the output?
  - **Artifact size**: Is the output proportional to the problem?

---

### 7. Reviewer Pool: Blinding and Failure Handling Unspecified

**Severity**: MEDIUM  
**Location**: "Independent Blind Review" section  
**Issue**:

The methodology specifies "blind review" but leaves critical details undefined:

- **Who is the reviewer pool?** (Anthropic staff? External experts? Patrick Sélamy?)
- **How is blinding enforced?** (Artifact redaction? ID removal? Sign-off verification?)
- **What happens if a reviewer fails to stay blind?** (Exclude their scores? Retrain? Discard trial?)
- **How many reviewers per trial?** (One? Three? Majority vote?)
- **Reviewer training**: Are all reviewers calibrated on the rubric before scoring?

**Implication**: Without these details, "blind review" is a label without teeth. Reviewers might inadvertently recognize artifacts, or the blinding process might be inconsistently applied.

**Recommendation**:
Document:
1. Reviewer selection criteria and pool size
2. Specific blinding procedures (e.g., "Artifact IDs redacted before review; reviewer submits answer to 'What treatment produced this?' before score submission")
3. Blinding failure protocol (e.g., "If reviewer identifies treatment correctly, their score is excluded from the trial")
4. Reviewer calibration process and schedule

---

## Summary Table

| Issue | Severity | Category | Status |
|-------|----------|----------|--------|
| Pinned commit one behind | HIGH | Infrastructure | Unresolved |
| OpenSpec fixture handicap | HIGH | Fairness | Unresolved |
| Oracle out-of-scope behavior | MEDIUM | Clarity | Unresolved |
| Public research vs. banned workflows | MEDIUM | Policy | Unresolved |
| Asymmetric interaction budget | MEDIUM | Fairness | Unresolved |
| Rubric bias toward RFC theory | MEDIUM | Design | Unresolved |
| Reviewer pool and blinding details | MEDIUM | Process | Unresolved |

---

## Recommendations for Proceeding

### Before Starting Trials (Required)

1. **Resolve the pinned commit issue** (Issue #1): Decide whether to update the baseline or accept the infrastructure disadvantage.
2. **Clarify the OpenSpec fixture constraint** (Issue #2): Explicitly document this as an intentional asymmetry or redesign for neutrality.
3. **Specify Oracle behavior** (Issue #3): Define exact responses for out-of-scope questions.
4. **Resolve the policy contradiction** (Issue #4): Clarify the hierarchy between "public research allowed" and "competing frameworks banned."

### Before Blind Review (Strongly Recommended)

5. **Document the interaction budget** (Issue #5): Specify whether all treatments get the same budget and justify this choice.
6. **Audit the rubric** (Issue #6): Make dimensions explicit and defend each as workflow-neutral or admit the bias.
7. **Specify reviewer procedures** (Issue #7): Document pool selection, blinding enforcement, and failure handling.

---

## Positive Observations

Despite these issues, the methodology demonstrates several strengths:

- **Clear treatment definitions**: The three workflows (Norman RFC, Spec Kit, OpenSpec) are well-articulated
- **Reproducibility commitment**: The pinned-commit approach is sound in principle
- **Blinded review intent**: The recognition that artifact review should be blind is appropriate
- **Failure classification**: The distinction between framework defects and trial failures is thoughtful
- **Structured evaluation**: The use of a rubric and multiple harnesses (Anti-Gravity, Codex, Claude) provides good coverage

The methodology is salvageable; it needs clarification and fairness audits, it doesn't need a redesign.

---

## Next Steps

1. **User Acknowledgment**: Patrick Sélamy to review and confirm receipt of this evaluation
2. **Issue Triage**: Stakeholders to classify each issue as blocking, high-priority, or acceptable
3. **Remediation Planning**: For each issue, decide between (A) fixing the methodology or (B) documenting why the current approach is acceptable
4. **Sign-Off**: Once issues are resolved or explicitly accepted, trials can proceed

---

## Appendix: Comment Locations in Google Doc

Inline comments have been added to the Google Doc at the following locations:

1. **"Brownfield Fixture"** — Pinned commit infrastructure bug (Issue #1)
2. **"Brownfield Fixture"** — OpenSpec-specific fixture handicap (Issue #2)
3. **"Scripted Stakeholder Oracle"** — Undefined out-of-scope behavior (Issue #3)
4. **"Constraints"** — Public research vs. banned workflows contradiction (Issue #4)
5. **"Oracle Interaction"** — Asymmetric interaction budget (Issue #5)
6. **"Rubric-Based Evaluation"** — Rubric bias toward RFC workflow (Issue #6)
7. **"Independent Blind Review"** — Reviewer pool and blinding details (Issue #7)

---

**Review completed**: 2026-08-27  
**Reviewer**: Claude (Anthropic, Claude Code agent)  
**Method**: Document review + inline comments + formal evaluation  
**Confidence**: High (issues are structural, not interpretive)
