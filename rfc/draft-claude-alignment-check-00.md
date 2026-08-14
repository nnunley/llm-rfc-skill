# draft-claude-alignment-check-00: Requirements-Design-Plan Alignment Verification

**Status:** DRAFT  
**Category:** Informational  
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>  
**Date:** 2026-08-14

## Abstract

The alignment-check process verifies that intent documents (requirements, specifications, PRDs) and action documents (implementation plans, task lists) are aligned in both directions: every requirement has corresponding tasks, and every task traces to a stated requirement. The process detects coverage gaps, scope creep, and design mismatches, then rewrites all tasks in TDD red/green/refactor format. This document specifies the four phases (source control reality check, alignment analysis, dependency-ordered issue presentation, and mandatory resolution) and relates alignment checking to the RFC series' own plan-breakdown rule.

## Motivation

Development projects lose track of requirements through three common failure modes:

1. **Missing coverage** — Explicit requirements addressed by no tasks (what's unfinished).
2. **Scope creep** — Tasks with no corresponding requirement (gold-plating or implicit assumptions).
3. **Design drift** — Plans that bypass or contradict stated design decisions.

Alignment checking addresses this by treating requirements/design/plan triples as durable artifacts, checking coverage in both directions, and rewriting tasks in TDD format to ensure implementation discipline.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174) when, and only when, they appear in all capitals, as shown here.

- **Intent document** — specification, requirements, PRD, user stories; defines *what* we want.
- **Action document** — implementation plan, task list, step-by-step plan; defines *what we'll do*.
- **Design document** — optional intermediate document; specifies *how*.
- **Coverage gap** — requirement with no corresponding task.
- **Scope creep** — task with no corresponding requirement.
- **Proof obligation** — behavioral evidence required to confirm a requirement is met.

## Specification

### Alignment Check Lifecycle

The alignment-check process executes four mandatory phases:

```fsm
initial start
start -> phase1_reality_check
phase1_reality_check -> phase2_analysis
phase2_analysis -> phase3_issue_review
phase3_issue_review -> phase3_issue_review     ; user-response loop
phase3_issue_review -> phase4_resolution       ; all issues discussed
phase4_resolution -> phase4_resolve_docs
phase4_resolve_docs -> phase4_tdd_rewrite      ; document updates applied
phase4_tdd_rewrite -> complete
terminal complete

note start: Begin with conversation history or file paths
note phase1_reality_check: Check git log for conflicts with document assumptions
note phase2_analysis: Coverage (req→task), scope (task→req), design alignment
note phase3_issue_review: Present issues dependency-ordered; gather user decisions
note phase4_resolution: Update documents, apply user decisions to documents
note phase4_tdd_rewrite: Rewrite all tasks in red/green/refactor TDD format
note complete: Alignment verified, tasks rewritten, ready for implementation
```

### Phase 1: Reality Check

MUST scan recent git history (50 commits, 2 weeks) to find conflicts between what documents assume and what recently changed. For each conflict found, present: what documents assume, what changed (commit SHA, date), why it matters, and ask user for resolution.

### Phase 2: Alignment Analysis

MUST perform three checks:

1. **Requirements coverage** — For every item in intent documents, check whether at least one action item addresses it. Flag missing tasks, partial coverage (happy path only, no error handling).
2. **Scope compliance** — For every item in action documents, check whether it traces back to a stated requirement. Flag orphaned tasks and out-of-scope work.
3. **Design alignment** — If design documents exist, verify design addresses all requirements AND tasks implement the design (not bypass it).

### Phase 3: Issue Presentation

MUST present issues in dependency order (missing requirements first, design gaps second, orphaned tasks last). For each issue: identify affected documents, state the misalignment, assign severity (Critical/Important/Minor), offer concrete options, and wait for user response before presenting next issue.

### Phase 4: Resolution and Mandatory TDD Rewrite

After alignment decisions are confirmed, MUST rewrite all action items in TDD red/green/refactor format:

- **RED** — Write a failing test first, defining expected behavior.
- **GREEN** — Write minimal code to pass; no anticipatory abstractions.
- **REFACTOR** — Extract duplication, move hard-coded values to config, consolidate patterns.

### Relationship to RFC Plan-Breakdown Rule

The RFC series' plan-breakdown rule requires every task to name a requirement ID, and every requirement ID to appear in at least one task (coverage check). Alignment checking applies the same coverage discipline to requirements/design/plan triples: it is the RFC series' static requirement verification translated into dynamic project scope management.

## Alternatives Considered

**Document-only review** — Comparing requirements and plans by human inspection is error-prone and does not catch implicit assumptions. Alignment checking automates the comparison and forces explicit curation of mismatches.

**TDD without scope audit** — Writing tests first ensures correctness but does not verify that the right features are being built. Alignment checking pairs TDD with continuous coverage audits, ensuring both correctness and completeness.

## Security Considerations

Alignment checking does not execute code; it analyzes documents. The sole risky artifact produced is the TDD task list (which will later be executed). Task lists generated by alignment checking are generated by the same agent as the original plan analysis and SHOULD be subject to the same code review and authorization controls as any agent-authored task.

## References

- Curtis "Ovid" Poe, PAAD alignment skill: https://github.com/Ovid/paad/tree/149926aa231e/skills/alignment (v1.11.0)
- draft-ndn-authoring-rfcs-00 — Plan-breakdown rule and requirement coverage verification
- draft-claude-iterative-development-00 — TDD task format and evidence corpus management
- draft-claude-adversarial-review-00 — Parallel reviewer patterns for scope and design audits
- RFC 2119, RFC 8174 (BCP 14) — Requirement language conventions

## Changelog

- **2026-08-14**: draft-00 created incorporating PAAD's alignment-check process. Specifies four-phase lifecycle (reality check, analysis, issue presentation, resolution), design-document coverage checking, dependency-ordered issue presentation, mandatory TDD red/green/refactor rewrite. Pinned to PAAD v1.11.0 at commit 149926aa231e. Relates alignment checking to RFC series' plan-breakdown rule as equivalent coverage discipline for project scope.
