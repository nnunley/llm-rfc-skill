# draft-claude-architecture-analysis-00: Multi-Agent Architecture Analysis Process

**Status:** DRAFT
**Category:** Informational
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-14

## Abstract

Multi-agent architecture analysis systematically diagnoses codebase structure,
coupling patterns, resilience, and security through parallel specialist dispatch,
verification, and consolidated reporting. Five specialist agents examine distinct
architectural domains — structure and boundaries, coupling and dependencies,
integration and data, error handling and observability, and security and code quality —
in parallel. A verification pass filters false positives and validates confidence
before final report composition. This document specifies the four-phase process.

## Motivation

Single-agent architecture analysis is incomplete: one agent cannot simultaneously
think like a domain expert, a coupling analyst, a resilience engineer, and a
security reviewer. Generalist assessments miss domain-specific concerns and produce
low-confidence findings reported with equal weight to high-confidence flaws. Parallel
specialist dispatch ensures each architectural concern receives dedicated expert
attention. Verification gates false positives and validates evidence before reporting,
preventing noisy or contradictory output. The process produces actionable, evidence-backed
findings organized by impact level and architectural domain.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **Specialist agent** — an autonomous LLM instance focused on one architectural
  domain, dispatched in parallel with peers. Each MUST read code, identify strengths
  and flaws, and report findings with evidence anchoring (file:line, symbol, excerpt).
- **Proof obligation** — a finding's grounding requirement: file path, line range,
  symbol name, and concrete code excerpt. All findings MUST include proof obligations.
- **Verification** — a filtering and confirmation pass: the verifier reads actual
  code at each finding's location, confirms the flaw or strength exists, validates
  impact level and confidence, and drops findings below confidence threshold (≥60%).
- **Architecture domain** — a specialized concern: structure and boundaries, coupling
  and dependencies, integration and data, error handling and observability, or
  security and code quality. Each domain has assigned flaw types and strength categories.

## Specification

### Process Overview

Architecture analysis MUST proceed through four sequential phases: reconnaissance,
specialist analysis (parallel), verification (serial), and reporting.

```fsm
initial RECONNAISSANCE
RECONNAISSANCE -> SPECIALIST_DISPATCH
SPECIALIST_DISPATCH -> SPECIALIST_DISPATCH    ; parallel execution
SPECIALIST_DISPATCH -> VERIFICATION           ; all specialists complete
VERIFICATION -> VERIFICATION                  ; finding-by-finding confirmation
VERIFICATION -> REPORTING                     ; verification complete
REPORTING -> REPORTING                        ; consolidation, deduplication
REPORTING -> COMPLETE                         ; report written
terminal COMPLETE
```

### Phase 1: Reconnaissance

Reconnaissance agents MUST collect:

1. **Repository identification** — git remote URL, repo name, top-level directory
   structure.
2. **Codebase overview** — primary languages/frameworks, key directories, estimated
   size (files/modules), module/service count.
3. **Dependency and structure snapshot** — top-level modules and relationships,
   import patterns, layering indicators.
4. **Steering files** — scan for `CLAUDE.md`, `AGENTS.md`, architecture documents,
   ADRs. Include staleness caveat: steering files describe conventions but MAY be
   outdated; flag contradictions between steering files and actual code.
5. **Scope estimate** — small (<50 files), medium (50–500), or large (500+ files).
6. **Manifest construction** — group source files by module/package for specialist
   assignment.

### Phase 2: Specialist Analysis

After reconnaissance, dispatch FIVE specialist agents in parallel. Each MUST receive:
the file manifest for their scope, repository overview, steering file contents with
staleness caveat, their assigned architectural domain, flaw types, and strength categories.

**Specialist roles:**

- **Structure & Boundaries** — module organization, responsibility distribution, domain
  modeling. Examine for: global mutable state, god objects, inconsistent boundaries,
  low cohesion, feature envy, shotgun surgery.
- **Coupling & Dependencies** — component connectivity, abstraction quality, dependency
  direction. Examine for: tight coupling, circular dependencies, leaky abstractions,
  dependency injection misuse, temporal coupling.
- **Integration & Data** — service communication, data ownership, API contracts, resilience.
  Examine for: distributed monolith patterns, chatty calls, synchronous-only integration,
  shared data ownership, lack of idempotency.
- **Error Handling & Observability** — error strategies, logging, configuration,
  side effects. Examine for: hidden side effects, weak error handling, no observability,
  configuration sprawl, magic numbers/strings, inconsistent error formats.
- **Security & Code Quality** — authentication, secrets, dead code, test coverage.
  Examine for: auth bolted on late, hard-coded credentials, missing test coverage,
  unused dependencies, dead code.

Each specialist MUST:
- Read actual code for every candidate finding (do not infer from file names).
- Report both strengths and flaws with evidence anchoring (file:line, symbol, excerpt).
- Assign confidence (0–100); only report findings with confidence ≥60%.
- Check git history to distinguish intentional design from neglected problems.

### Phase 3: Verification

A single **Verifier** agent MUST:

1. For each finding, read the actual current code at the referenced file:line.
2. Confirm the flaw or strength exists and is accurately described.
3. Validate impact level (High/Medium/Low) is appropriate.
4. Check that flaw type or strength category is correctly assigned.
5. Cross-specialist agreement increases confidence.
6. Drop findings below 60% confidence or lacking concrete evidence.

Verifier MUST be skeptical: large files alone do not prove god objects; many imports
do not necessarily prove tight coupling. Every finding MUST have file path, symbol,
and excerpt — unanchored findings are dropped.

### Phase 4: Reporting

Write verified findings to a markdown report at a deployment-defined path, organized as:

- **Repo Overview** — what the codebase does, structure, size.
- **Strengths** (ranked by impact) — 5–15 items with category, impact, explanation,
  evidence, and finding sources.
- **Flaws/Risks** (ranked by impact) — 10–25 items with same structure.
- **Coverage Checklist** — table showing all 34 flaw types and 14 strength categories,
  marking observed/not observed/not applicable.
- **Hotspots** — top 3 files/directories for review.
- **Next Questions** — 5 follow-up investigation questions (no proposed solutions).
- **Analysis Metadata** — agents dispatched, raw vs. verified finding counts, findings
  by impact, steering files consulted.

## Alternatives Considered

### Single generalist agent analysis

A single LLM could analyze all architectural concerns sequentially. This approach is
incomplete: no individual LLM can simultaneously hold expertise across five architectural
domains, and sequential analysis loses the ability to cross-correlate findings across
concerns. Rejected because the output is uneven in quality and misses domain-specific patterns.

### No verification gate

Specialists could report findings directly without a verification pass. This reduces
latency but produces false positives, contradictory findings, and reports without evidence
grounding. Rejected because unverified findings are not actionable and signal low confidence
in the analysis. Verification gates false positives and ensures evidence quality.

### LLM-as-judge on finding truth

A secondary LLM could judge whether reported findings are real. This is circular for
a system whose purpose is auditing code; LLM judgment is not evidence. Verification
must be code-grounded (reading actual files at reported locations) and confidence-based,
not LLM secondaries.

## Security Considerations

Architecture analysis reads source code and produces findings about structure, coupling,
and quality. No credentials, secrets, or PII are extracted or stored in findings.

1. **Steering file contents** — If steering files (`CLAUDE.md`, etc.) contain secrets
   or PII, those materials flow into specialist agent prompts. Mitigation: do not store
   secrets in steering files (use environment or vault systems instead).

2. **Findings are advisory** — Architecture findings are observations and recommendations
   for internal team review. They are not execution-level access and carry no risk to
   runtime systems. Mitigation: findings may be shared within development teams; external
   distribution should apply the same policy as source code access.

3. **Scope limitation** — Analysis is scoped to a repository or directory tree. Attacking
   the scope boundary (providing links outside the repo) does not change the security posture
   because specialists explicitly focus on their assigned manifest.

## References

- Curtis "Ovid" Poe, **PAAD** (Perl-based Agentic Architecture Diagnosis),
  https://github.com/Ovid/paad, reviewed at commit 149926aa231e (v1.11.0),
  agentic-architecture skill.
- draft-ndn-authoring-rfcs-00 — The RFC process for human–LLM specification authoring
  and evidence-based conformance.
- draft-claude-adversarial-review-00 — the review loop (specialist
  dispatch, consolidation, adjudication) this analysis instrument feeds:
  agentic-architecture is a specialist-dispatch form, distinct from
  same-prompt PAR.
- RFC 2119, RFC 8174 (BCP 14) — Requirement language conventions.

## Changelog

- 2026-08-14: draft-00 created, documenting PAAD's agentic-architecture process
  (commit 149926aa231e, v1.11.0). Covers four-phase lifecycle: reconnaissance,
  specialist dispatch across five architectural domains, verification gate for
  false-positive filtering and confidence validation, and consolidated reporting
  with evidence anchoring. Includes process FSM and security/alternative considerations.
