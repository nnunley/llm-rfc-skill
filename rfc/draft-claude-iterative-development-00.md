# draft-claude-iterative-development-00: The Iterative Development Methodology for LLM-Driven Implementation

**Status:** DRAFT
**Category:** Informational
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-14
**Original Design:** Jesse Vincent (prime-radiant-inc)

## Abstract

The iterative-development methodology is an autonomous, audited loop for implementing
projects from large, comprehensive, or ambiguous specifications. It pairs requirement
extraction with proof obligations, walking-skeleton scoping, TDD-disciplined iteration,
and continuous three-tier auditing to ensure the product has executable behavior
evidence for every externally observable requirement — not merely completed stories.
This document describes the methodology's lifecycle, artifact structures, quality gates,
and relationship to the RFC specification process.

## Motivation

Existing development workflows face a common failure mode: with large or ambiguous
specifications, upfront planning loses the plot, stories marked "done" do not produce
working products, and agent-authored implementation resets its obligations with each
new context window. Session-scoped planning produces artifacts without durable identity;
mutable living-spec trees record current behavior but not rationale; test suites verify
behavior but are unreadable as specification.

The iterative-development methodology addresses this by:

1. Extracting requirements as stories with proof obligations and behavior scenarios, creating
   durable, researchable artifacts.
2. Defining a walking skeleton that is small, cohesive, and closes at least one real
   journey scenario — forcing early validation that the product shape is correct.
3. Executing iterations through a TDD discipline that interleaves code tasks with evidence
   tasks, treating scenario evidence as a first-class deliverable.
4. Running continuous three-tier audits (deep evidence, impacted behavior, sentinel
   regression detection) using parallel adversarial review to catch gaps before they
   propagate.
5. Defining completion as "every externally observable requirement has passing behavior
   evidence at the correct seam" rather than "all stories marked done."

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **Proof obligation** — a requirement that some observable behavior MUST be witnessed.
  Each acceptance criterion (AC) of a story carries one or more proof obligations that
  specify which seam (unit, integration, E2E) the evidence MUST inhabit.
- **Behavior scenario** — a reusable, runnable description of an observable system behavior,
  assigned a stable ID (e.g., SCENARIO-0001, JOURNEY-0001). Scenarios are organized in
  `behavior-scenarios.md` and indexed in the behavior corpus.
- **Walking skeleton** — the ITER-0000 iteration: a small, cohesive set of stories from
  distinct epics that proves the end-to-end shape of the product works and MUST close
  at least one journey scenario as an automated or reproducibly executable test.
- **Journey scenario** — a behavior scenario that traces a complete user journey or system
  flow, spanning multiple surfaces or components. Assigned stable ID JOURNEY-NNNN and
  run on every iteration (sentinel cadence).
- **Proof seam** — the architectural boundary where a proof obligation is satisfied:
  unit (isolated component), integration (multi-component), or E2E (user-visible end-to-end).
- **Sentinel corpus** — the set of all scenarios with run cadence `sentinel` (primarily
  journey scenarios). Run before, during, and after each iteration to detect regressions
  in previously-working behavior.
- **Behavior evidence corpus** — the executable index of all behavior scenarios, including
  their execution commands, run cadence (sentinel or iteration-level), and current status.
- **Story** — a requirement card with title, acceptance criteria (ACs), proof obligations
  per AC, and sources in the original specification. Assigned stable ID STORY-NNNN and
  organized in per-epic files under `docs/superpowers/iterations/requirements/`.
- **Epic** — a grouping of related stories. Assigned stable ID EPIC-NNN.
- **Parallel adversarial review (PAR)** — a quality gate where two independent reviewer
  subagents evaluate the same work with competitive framing, findings aggregated by union
  (same finding from both = high confidence; unique finding = still actionable; severity =
  take worst).
- **Scope review** — a PAR-based evaluation that checks whether an iteration's story
  selection is minimal, whether stories with heterogeneous-dependency ACs should be split,
  whether the walking skeleton closes a journey scenario, and whether the design boxes in
  follow-on iterations.
- **Spec-compliance review** — a PAR-based evaluation that verifies implemented code
  satisfies every proof obligation for every AC, with evidence at the correct seam.
- **Code-quality review** — a PAR-based evaluation (Stage 2) that checks for reuse,
  simplification, efficiency, and whether the code contributes cleanly to the behavior
  corpus without boxing in future iterations.

## Specification

### Process Lifecycle

The iterative-development orchestrator drives an autonomous loop that MUST follow this
overall structure:

1. **Bootstrap** (first invocation only)
   - Invoke `extracting-requirements` on human spec collateral
   - Invoke `scoping-the-simplest-core` on the resulting backlog
2. **Main loop** (repeats until completion)
   - Check for human interrupts
   - If roadmap has pending iterations, run next iteration (via `running-an-iteration`)
   - Run post-iteration audit (via `auditing-progress`)
   - If gaps found, append to backlog and revise roadmap; loop continues
   - If audit clean and no pending iterations, run final behavior-evidence audit
3. **Termination**
   - Final behavior-evidence audit verifies all surfaces have coverage
   - If gaps remain, create new stories and continue loop
   - If complete, declare product done

An orchestrator implementation MUST NOT poll the filesystem for spec changes and MUST
NOT ask "anything to change?" between iterations. Human changes are injected mid-loop
by interrupting the chat session at an iteration boundary.

### Artifact Structure

All iterative-development artifacts MUST be stored in `docs/superpowers/iterations/`.
The human's original specification collateral MUST NEVER be modified.

The artifact set MUST include:

| File | Purpose | Format |
|---|---|---|
| `requirements/` | Per-epic story cards with ACs, proof obligations, and status | Markdown; one `.md` file per epic |
| `behavior-scenarios.md` | All behavior scenarios with stable IDs and owning-story links | Markdown; single file with SCENARIO/JOURNEY index |
| `behavior-corpus.md` | Execution index mapping scenario → seam → cadence → command | Markdown; table format |
| `roadmap.md` | Sprint plan with ITER-0000 (walking skeleton) and ordered follow-on iterations | Markdown; iteration blocks with status |
| `iteration-log.md` | Completed iteration history: delivered stories, scenarios added, sentinel results | Markdown; chronological log |
| `progress.md` | Live snapshot of current phase, task count, iteration counts, sentinel status | Markdown; overwritten (not appended) at each phase transition |

An orchestrator implementation MUST maintain these files in git and MUST commit after
each phase transition (extraction, scoping, iteration completion, audit completion).

### Requirement Extraction

The `extracting-requirements` skill MUST produce stories and behavior scenarios from
human spec collateral via this pipeline:

1. **Chunk the spec** — Enumerate spec files without reading full contents; classify each
   chunk by spec taxonomy (journeys → E2E, contracts → integration, domains → integration
   or app-level, test-vectors → unit). Small files kept whole; larger files split by
   headings.

2. **Dispatch extraction subagents in waves** — For each chunk or batch of small chunks,
   dispatch an extraction subagent using the appropriate prompt template. Subagents MUST
   produce stories with proof obligations and behavior scenarios. Subagent results MUST
   be persisted immediately (not held in conversation state).

3. **Run PAR omission review** — Before aggregation, dispatch two paired reviewer subagents
   to compare source text against extracted stories and scenarios. Reviewers MUST find
   every requirement, AC, behavioral constraint, or observable behavior not represented
   in the extractions.

4. **Aggregate stories** — Combine extracted stories, deduplicate by title, group into
   epics, assign stable STORY-IDs and EPIC-IDs, and output per-epic `.md` files in
   `docs/superpowers/iterations/requirements/` with proof obligations preserved.

5. **Aggregate scenarios** — Combine extracted scenarios, deduplicate by title, assign
   stable SCENARIO-IDs and JOURNEY-IDs, resolve story-title references to STORY-IDs,
   and output `docs/superpowers/iterations/behavior-scenarios.md`.

6. **Back-link scenarios to stories** — Update per-epic story files to append scenario
   references (`scenario:SCENARIO-NNNN` or `scenario:JOURNEY-NNNN`) to AC lines with
   observable behavioral impact.

7. **Build coverage ledger** — Map every spec chunk to its extracted stories and scenarios,
   classifying each chunk as covered, story-only, non-normative, duplicate, or gap.
   Chunks classified as gap or story-only (with observable behavior) MUST trigger
   re-extraction.

8. **Initialize behavior corpus** — Create `docs/superpowers/iterations/behavior-corpus.md`
   with all scenarios indexed. Set run cadence: journey scenarios → `sentinel`; surface
   scenarios → `iteration` (refined during scoping). Set execution command to `TBD`.

9. **Validate** — Run mechanical validators on requirements and scenarios for format and
   cross-reference consistency.

### Walking Skeleton Scoping

The `scoping-the-simplest-core` skill MUST produce a roadmap with ITER-0000 and
ordered follow-on iterations:

1. **Select walking skeleton (ITER-0000)** — Choose a small, cohesive set of stories from
   distinct epics that proves the end-to-end shape works. ITER-0000 MUST close at least
   one journey scenario as an automated or reproducibly executable test. Selection rule:
   "If someone ran just these stories, they SHALL see a working demo AND have at least
   one passing journey scenario that proves the demo works."

2. **Design E2E test harness first** — ITER-0000's FIRST task MUST be designing and building
   the E2E test infrastructure. The harness is a first-class deliverable, not an afterthought.
   Every subsequent iteration extends it.

3. **Apply story splitting** — When assigning stories to iterations, check each story's ACs
   for dependency profiles. If a story has ACs where some can be satisfied in iteration N
   and others require subsystems from iteration N+M, SPLIT the story into versions for
   each iteration and update the requirements index accordingly.

4. **Order remaining iterations** — Group follow-on stories into sprints of cohesive work.
   Iteration granularity is judgment-based; each iteration MUST satisfy a specific theme
   or architectural concern.

5. **Run citation check** — Verify that every iteration cites only valid STORY-IDs from
   the index.

6. **Run scope review via PAR** — Dispatch paired scope reviewers to verify:
   - Is ITER-0000 really the thinnest possible walking skeleton?
   - Does ITER-0000 close at least one journey scenario?
   - Could anything be deferred from ITER-0000 to a follow-on?
   - Does ITER-0000's design box in any follow-on iteration?
   - Are any stories over-broad (mixing skeleton-level concerns with later integrations)?
   - Are there stories with heterogeneous-dependency ACs that MUST be split?
   - Does any iteration leave observable behavior without planned scenario coverage?
   Reviewers MUST reach consensus (APPROVE or REVISE); if REVISE, adjust and re-review.

7. **Write and validate roadmap** — Output `docs/superpowers/iterations/roadmap.md` with
   ITER-0000 and ordered follow-on iterations, including intent, rationale, journey
   scenario, committed stories, and status fields. Validate format.

### Iteration Execution

The `running-an-iteration` skill MUST execute a single iteration end-to-end:

1. **Pick next iteration** — Read `roadmap.md`, find the first iteration with status
   `pending`.

2. **Load scope context** — Read relevant epic files from `requirements/`, load next 3
   pending iterations for look-ahead, read `behavior-scenarios.md` and `behavior-corpus.md`
   to identify impacted and sentinel scenarios.

3. **Run sentinel corpus baseline** — Before code changes, run every scenario with run
   cadence `sentinel`. Record pre-iteration state (pass or fail). If failures exist,
   create gap stories but proceed.

4. **Pre-iteration consistency audit** — Verify artifact state: run citation check,
   reconcile story status (stories in roadmap not already marked done unless code exists),
   verify epic progress counters.

5. **Pre-iteration scope review (PAR)** — Dispatch paired scope reviewers using the same
   criteria as roadmap scoping. If REVISE is the verdict, adjust scope and re-review until
   APPROVE is reached.

6. **Decompose into tasks** — Break the iteration into TDD-sized code tasks and evidence
   tasks. Evidence tasks identify impacted scenarios, new scenarios to add, harness
   extensions, and corpus index updates. Evidence tasks are first-class, interleaved with
   code tasks (feature implementation, then scenario update).

7. **Dispatch `implementing-tasks`** — Pass the task list and context to `implementing-tasks`
   for execution.

8. **Post-iteration scenario runs** — After all tasks complete, run impacted scenarios
   (whose owning stories were touched) and sentinel scenarios. Any failure that passed at
   baseline indicates a regression; create a fix task and re-dispatch.

9. **Resolve cross-iteration TODOs** — Grep for `TODO(ITER-<current>)` markers (interface
   stubs from earlier iterations). Verify real implementations exist; if not, add fix tasks.
   An iteration that leaves its own TODO markers is incomplete.

10. **Wrap up** — Verify all ACs pass, verify proof obligations have scenario evidence,
    verify no remaining TODOs, mark stories `done:ITER-NNNN`, update scenario automation
    status and execution commands, update behavior corpus index, update roadmap status to
    `done`, append entry to iteration log, validate artifacts.

### Task Implementation

The `implementing-tasks` skill MUST execute a batch of TDD-sized tasks, each through
this per-task cycle:

1. **Dispatch implementer** — Send task description, proof obligations, and existing
   impacted scenarios to an implementer subagent. Implementer MUST complete a pre-flight
   mapping (AC → proof seam → scenario) before writing code.

2. **Handle implementer status** — If DONE or DONE_WITH_CONCERNS, proceed to spec-compliance
   review. If NEEDS_CONTEXT, provide context and re-dispatch. If BLOCKED, assess and
   either re-dispatch with more context/capability or escalate.

3. **PAR spec-compliance review (Stage 1)** — Dispatch two spec-compliance reviewers in
   parallel to verify every proof obligation is satisfied with evidence at the correct
   seam. If issues found, send to implementer for fixes and re-dispatch fresh PAR pair.
   Repeat until Stage 1 is ✅.

4. **PAR code-quality review (Stage 2)** — Dispatch two code-quality reviewers in parallel
   to check for reuse, simplification, efficiency, boxing-in against next 3 pending
   iterations, and clean corpus contribution. If issues found, re-dispatch after fixes.
   Repeat until Stage 2 is ✅.

5. **Mark task complete** — Record task as done, move to next task. After all tasks
   complete, return per-task results (status, scenarios added/updated, evidence commands).

### Progress Auditing

The `auditing-progress` skill MUST run after every iteration to verify behavior evidence
quality. Auditing MUST be partitioned into three tiers:

**Tier 1 — Deep evidence:** Stories marked `done:ITER-<current>` and scenarios added or
updated in this iteration. Audit every AC and its proof obligation thoroughly.

**Tier 2 — Impacted behavior:** All existing scenarios whose owning stories had code
changes in this iteration (even if completed in earlier iterations). Verify scenarios
still pass.

**Tier 3 — Sentinel corpus:** All scenarios with run cadence `sentinel`. Compare current
results against pre-iteration baseline. Any regression is a critical gap.

Auditing MUST dispatch two paired auditor subagents in parallel following PAR methodology.
Findings MUST be aggregated: same finding from both = high confidence; unique = still
actionable; severity = take worst.

If gaps are found (any AC fails, evidence too weak, sentinel regression), auditors MUST:
- For AC failures: append gap stories or flip existing stories back to pending
- For weak evidence: create evidence-improvement stories
- For sentinel regressions: create CRITICAL-priority regression-fix stories
- Revise roadmap to add a follow-up iteration

If all tiers pass, return clean signal to orchestrator.

### Iteration Lifecycle State Machine

The overall iteration lifecycle state machine is:

```fsm
initial pending
pending -> in_progress
in_progress -> scope_review
scope_review -> scope_review   ; PAR revision loop
scope_review -> decompose      ; APPROVE → proceed
decompose -> implementing
implementing -> implementing   ; task-by-task completion
implementing -> post_run
post_run -> auditing
auditing -> auditing           ; PAR revision loop
auditing -> complete           ; APPROVE → iteration done
auditing -> pending            ; gaps found → new stories added, back to pending
terminal complete
```

### Relation to the RFC Process

The iterative-development methodology and the RFC specification process (per
draft-ndn-authoring-rfcs-00) share deep structural parallels:

1. **Proof obligations and behavioral evidence** — Both systems center on durable,
   checkable evidence. The RFC process embeds machine-verifiable evidence blocks
   (transcripts, tables, ABNF witnesses) that replay deterministically to prove
   requirements. The iterative-development process builds a behavior evidence corpus
   with reusable scenario cards and execution commands, run continuously to catch
   regressions. Both reject LLM-as-judge verification; both require deterministic checkers.

2. **Stable IDs and artifact identity** — RFCs assign permanent requirement markers
   with slug identifiers once published, preventing silent obligation drift. Iterative development
   assigns stable STORY-IDs and SCENARIO-IDs during extraction, preserved across re-extraction
   and roadmap revisions, so that later work can cite and be held to them. Both systems
   make obligations durable within their scope (RFCs across series, iterative development
   across iterations).

3. **Incremental evidence accumulation** — The RFC process maintains a cumulative
   conformance corpus of all published RFCs' evidence, run whole by CI to prevent
   regressions in previously established requirements. The iterative-development process
   maintains a sentinel corpus of high-value journey scenarios, run before, during, and
   after each iteration, preventing regressions in product behavior. Both systems answer:
   "What behavior do we know is true and can't regress?"

4. **Scope review and consensus gates** — RFCs use rough consensus and LAST-CALL windows
   to vet design decisions. Iterative development uses PAR (parallel adversarial review)
   at every scope boundary (roadmap scoping, iteration scoping, task spec-compliance and
   code quality) to catch scope creep, boxing-in, and uncovered surfaces before they
   propagate. Both systems make design intent and objections visible, not silent.

**Key differences:**

- **Execution context** — RFC evidence is document-embedded and survives the project's
  planning artifacts permanently. Iterative-development evidence is harness-executed test
  scenarios tied to an active roadmap, tied to the product's own versioning and lifecycle.
- **Scope** — RFCs standardize across projects, carrying cross-project obligations. Iterative
  development is project-scoped, extracting requirements from a single project's specification.
- **Feedback loop** — RFC evidence is checked at publication time (MUST replay green). Iterative
  development checks evidence continuously (every iteration, every audit) and uses failures
  to generate new work.

**How they can compose:**

RFC process outputs (published requirement markers and conformance corpus) can feed iterative
development: RFC requirement IDs can be extraction inputs (e.g., "extract stories for
`R-auth-flow` and `R-audit-logging` from these journey specs"). Conversely, iterative
development outputs (behavior scenarios and sentinel corpus) can contribute to an RFC's
evidence base — scenarios that prove a feature's end-to-end behavior become evidence for
a "Feature: X Implemented" RFC section, providing machine-verifiable proof that claimed
features work.

### Completion Criteria

A project is complete when ALL of the following hold:

1. Roadmap has no pending iterations.
2. Final behavior-evidence audit is ✅.
3. For every major user-facing surface from the original spec:
   - Corresponding stories exist AND are implemented
   - Corresponding scenarios exist AND have passing evidence at the correct seam
   - Journey scenarios that cross multiple surfaces pass E2E
4. Behavior corpus index is complete:
   - Every journey spec file has ≥1 JOURNEY-NNNN scenario
   - Every scenario has a non-TBD execution command
   - All sentinel scenarios pass
5. No surface has gaps:
   - Every surface has a corresponding story (extraction complete)
   - Every surface has corresponding scenarios (evidence gap)
   - Every scenario's evidence is at the correct seam (proof obligation met)
   - No manual-residual scenarios that could be automated remain

The final question is: "Can the system point to passing behavior evidence for every
externally observable requirement the spec describes?" NOT: "Are the stories done?"

## Alternatives Considered

### Single upfront planning followed by implementation

The `superpowers:writing-plans → superpowers:subagent-driven-development` workflow
produces a detailed plan upfront and implements it in one pass. This works well for
small, bounded projects with clear scope. Rejected for large or ambiguous specs because
the upfront plan often loses track of requirements-coverage interactions; stories marked
done do not produce a working product. Iterative development addresses this by validating
the product shape early (walking skeleton closes a journey) and checking evidence coverage
continuously (audits catch gaps before they propagate).

### Test-driven development without specification scope management

Writing tests first (TDD) ensures implementation correctness but does not solve the
problem of whether the right features are being built. Iterative development pairs TDD
at the task level with continuous scope and coverage audits at the iteration level,
ensuring both correctness AND completeness.

### Manual iteration planning

A human could manually break a large spec into iterations, then dispatch agents to
implement. This is not fundamentally wrong, but it loses the durable artifact trail
(humans forget scope decisions, agents restart their context). Iterative development
makes the roadmap, requirements, and scenario corpus permanent artifacts, researchable
and auditable; human decisions are recorded in git history.

### LLM-as-judge on behavior evidence

Circular for a system whose purpose is constraining LLM agents' work. Rejected outright.
Execution-based evidence (running scenarios) and human auditors only.

### Mutable living-spec trees (OpenSpec-style)

A current-truth tree with delta migrations answers "what is the behavior now?" Rejected
as insufficient because it records neither rationale for design decisions, nor rejected
alternatives, nor the evidence trail that supports the current behavior. Iterative
development outputs can feed into a living-spec tree, but the tree alone cannot replace
the durable journey-to-story-to-evidence linkage.

## Security Considerations

Behavior evidence transcripts are arbitrary shell commands, Python scripts, or system
invocations executed by scenario runners: running a behavior corpus is running the
system's own test harness code. This is no more or less risky than running the project's
existing test suite.

The key security considerations:

1. **Scenario injection** — Scenario-writing subagents (during extraction and iteration)
   compose commands based on task context. An attacker or malicious actor could influence
   scenario content by injecting commands into task descriptions or proof obligations.
   This is not a new attack surface; it is the same risk as any agent-authored code.
   Mitigation: code review and authorization controls on task dispatch, standard to any
   agent-driven development workflow.

2. **Evidence corpus trust** — The behavior corpus is the ground truth for "what behavior
   do we know is true?" If corpus scenarios are compromised (commands altered, execution
   results forged), the audit layer is defeated. Mitigation: corpus lives in version
   control with full commit history; any alteration is auditable. Running the corpus
   should be treated as executing the project's own code (git-backed, reviewed).

3. **Third-party narrative injection** — The extraction process reads spec collateral
   provided by humans. If spec sources are untrusted or under attacker control, extracted
   stories and scenarios reflect the attacker's narrative. This is by design (specifications
   describe the desired behavior); it is not unique to this methodology. Mitigation: spec
   review and sign-off, standard to any requirements process.

4. **Subagent model compromise** — Extraction, scoping, iteration, and audit subagents are
   dispatched to LLM inference APIs. If the model is compromised, subagents can be
   manipulated. This is orthogonal to the methodology; it is a deployment-layer concern.
   Mitigation: use trusted model providers, enable prompt injection detection and logging,
   audit subagent outputs before committing.

## References

- draft-ndn-authoring-rfcs-00 — The RFC process for human–LLM specification authoring
- **iterative-development** by Jesse Vincent (prime-radiant-inc):
  https://github.com/prime-radiant-inc/iterative-development
  (reviewed as installed from prime-radiant-inc/prime-radiant-marketplace
  at commit 49a45efb72af)
- W3C Candidate Recommendation process — implementation-gated publication model
- TC39 process document — staged advancement, completion defined by implementation evidence
- RFC 2119, RFC 8174 (BCP 14) — formal requirement language conventions

## Changelog

- 2026-08-14: draft-00 created, documenting the iterative-development methodology as
  implemented by Jesse Vincent's prime-radiant-marketplace plugin. Covers extraction
  pipeline, walking skeleton scoping, TDD-disciplined iteration, three-tier auditing,
  sentinel corpus for regression detection, and completion criteria centered on behavior
  evidence rather than finished stories. Includes FSM for iteration lifecycle and
  relationship to the RFC specification process.
