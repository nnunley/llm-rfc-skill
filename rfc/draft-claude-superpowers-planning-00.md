# draft-claude-superpowers-planning-00: The Superpowers Planning Pipeline

**Status:** DRAFT
**Category:** Informational
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-14

## Abstract

The superpowers planning pipeline is a unified workflow for collaborative
human–LLM architectural design, implementation planning, and execution,
spanning three complementary skills: brainstorming (context acquisition,
design approval), writing-plans (task decomposition, no-placeholder discipline),
and executing-plans or subagent-driven-development (execution with review
gates). This document records the pipeline as a third-party Informational
specification, faithfully documenting its process flows, design philosophy,
and integration with the RFC series as a higher-level requirements vessel.

## Motivation

Complex feature work requires bridging discovery (what does the user really
want?), design (how does this fit?), and implementation (what are the
concrete steps?). Session-scoped planning pipelines produce artifacts without
durable identity, making it difficult for later work to cite, build on, or
verify conformance to established requirements. The superpowers pipeline is
designed to operate in tandem with the RFC series: an RFC captures
architectural decisions and requirements durably; brainstorming and
writing-plans refine those requirements into implementation steps; execution
with review gates and a ledger produces evidence of what was built. This
document records the pipeline so that future work can understand how RFC
requirements flow into implementation plans, and how execution decisions get
recorded.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **Superpowers** — a unified skill library authored by Jesse Vincent
  (obra, https://github.com/obra/superpowers) for collaborative human–LLM
  architectural work. Skills are invoked by name within Claude Code sessions.
- **Brainstorming** — a superpowers skill that classifies incoming requests
  and guides discovery through questions, design proposals, and approval gates.
- **Writing-plans** — a superpowers skill that takes an approved design and
  decomposes it into bite-sized implementation tasks with exact code, test
  cases, and no placeholders.
- **Executing-plans** — a superpowers skill that executes an implementation
  plan in a separate session, task by task, with verification and ledger
  tracking.
- **Subagent-driven-development** — a superpowers skill that executes an
  implementation plan by dispatching fresh subagents per task, with review
  gates and fix loops after each.
- **Ledger** — a persistent progress file tracking completed tasks, rulings
  made, findings parked, and commits per task (survives session compaction).
- **Ruling** — a decision made on behalf of the human partner when the plan
  and spec leave ambiguity unresolved; recorded in the ledger with cost/risk
  assessment.

## Specification

The superpowers planning pipeline consists of three stages, each a distinct
superpowers skill, connected by handoffs and design approval gates.

### Stage 1: Brainstorming (Discovery and Design)

Brainstorming takes an incoming idea and classifies it into one of three paths:

- **Spike:** a feasibility question whose output is an answer, not kept code.
  Present the probe in 2-3 sentences, get approval, investigate, report findings.
  No design document.
- **Bounded:** a well-scoped change to existing code (a new flag, a small
  endpoint, a one-file fix). Ask clarifying questions, present a short design
  in chat, get approval. No spec document, no implementation plan — just the
  normal development workflow after approval.
- **Architectural:** new projects, new subsystems, interface changes, or
  anything restructuring how components fit. Full process: questions →
  approaches (2-3 options with trade-offs) → sectioned design proposals →
  approval per section → write design document → spec self-review → user
  reviews spec → invoke writing-plans skill.

Process flow for the Architectural path:

```fsm
initial Classify
Classify -> Explore
Explore -> Ask
Ask -> Propose
Propose -> DesignSection
DesignSection -> Approve
Approve -> DesignSection ; revise if not approved
Approve -> WriteSpec ; all sections approved
WriteSpec -> SelfReview
SelfReview -> UserReview
UserReview -> WritingPlans ; approved
UserReview -> WriteSpec ; request changes
terminal WritingPlans
```

The classification happens at the start of every request. When in doubt between
paths, the heavier one is taken. Hidden complexity discovered mid-task upgrades
the path upward — stop, communicate the upgrade, and proceed with the heavier
process.

All three paths enforce a hard gate: no implementation proceeds until the human
partner has approved the stated intent. For spike and bounded work, the gate is
approval before investigation/implementation. For architectural work, it is
written approval of the design document.

### Stage 2: Writing-Plans (Task Decomposition)

Writing-plans consumes an approved design document and produces an implementation
plan: a list of bite-sized tasks with exact code, test cases, file paths, and
step-by-step instructions. The plan assumes the engineer has zero context and
questionable judgment about testing.

Process flow:

```fsm
initial ReadSpec
ReadSpec -> ScopeCheck
ScopeCheck -> MapFiles ; single subsystem
ScopeCheck -> Decompose ; multiple subsystems
Decompose -> Subproject
Subproject -> MapFiles
MapFiles -> RightSizeTask
RightSizeTask -> WriteTask
WriteTask -> Task
Task -> SelfReview
SelfReview -> Execute ; issues fixed
terminal Execute
```

Core discipline of writing-plans: no placeholders. Every code step contains
exact, runnable code. Every test case is complete. Every file path is exact.
There are no "TBD," "TODO," "add appropriate error handling," or "similar to
Task N" directives. When the plan references an earlier task's interface,
it repeats the exact signature (function name, parameters, return types), not a
link.

Each task is right-sized: small enough to carry its own test cycle (2–5 minutes
per step), but large enough to be worth a reviewer's gate. Tasks are organized
with:
- **Files:** what to create or modify, with line ranges for existing files.
- **Interfaces:** exact signatures for what this task consumes from earlier
  tasks and produces for later ones.
- **Steps:** checkbox-tracked (`- [ ]`) implementation steps following TDD:
  write failing test, verify failure, implement minimal code, verify passing,
  commit.

The plan concludes with a self-review: spec coverage (every requirement gets a
task), placeholder scan (no stragglers), type consistency (function names and
signatures match across tasks).

### Stage 3: Execution (Two Flavors)

After the plan is written and approved by the human partner, execution happens
in one of two ways.

#### Executing-Plans (Parallel Session)

Process flow:

```fsm
initial LoadPlan
LoadPlan -> CriticalReview
CriticalReview -> ExecuteTask
ExecuteTask -> Task
Task -> VerifyTask
VerifyTask -> NextTask
NextTask -> ExecuteTask ; more remain
NextTask -> FinishingSkill ; all done
terminal FinishingSkill
```

Executing-plans is used when implementation happens in a separate session. It
loads the plan, reviews it for critical gaps, creates todos for each task, and
executes the plan step by step. Each task's steps are followed exactly; each
verification (a test run, a command output check) is confirmed before moving on.
When all tasks complete, the skill invokes finishing-a-development-branch to
present options for the branch (rebase, squash, merge, abandon).

#### Subagent-Driven-Development (Same-Session Batch Execution)

Process flow for each task:

```fsm
initial Dispatch
Dispatch -> Questions ; implementer has questions
Questions -> Answer
Answer -> Implement
Dispatch -> Implement ; no questions
Implement -> Report
Report -> Review
Review -> Approved ; spec and quality green
Review -> Finding ; need fixes
Finding -> FixRound
FixRound -> ReReview
ReReview -> AllFixed ; all findings addressed
ReReview -> OpenFindings ; findings remain
AllFixed -> Complete
OpenFindings -> Breaker ; round 5
OpenFindings -> FixRound ; round less than 5
Breaker -> Adjudicate
Adjudicate -> Complete
Approved -> Complete
terminal Complete
```

Subagent-driven-development is used when implementation stays in the same
session and independent tasks can be dispatched to fresh subagents. For each
task:

1. Dispatch a fresh implementer subagent with the task brief (extracted from
   the plan), report-file path, and context on interfaces touched.
2. If the implementer asks questions before starting, answer them completely.
3. The implementer implements, runs tests, and self-reviews; commits are made.
4. Dispatch a task reviewer (scoped to this task) with the diff, the brief, and
   the report file.
5. If the review is clean (spec compliance ✓, no critical/important findings),
   mark the task complete.
6. If findings are reported, enter the fix loop: resume the implementer (rounds
   1–3) or dispatch a fresh, more-capable implementer (rounds 4–5) with the
   findings, re-review the fix diff (scoped, not full re-review), and repeat.
7. When round 5's re-review still has open findings, stop dispatching and
   adjudicate: park the finding with a ruling if it is real but not
   load-bearing, or rule on it and carry the ruling into the next task if
   it blocks progress. Only the four hard stops (irreversible action, security
   decision, merge/push to shared branch, every path forward is a guess) halt
   execution to ask the human partner.

A ledger (progress.md) is created per plan and tracks: tasks completed, fix
rounds entered and exited, rulings made, parked findings, and commit ranges.
The ledger survives session compaction and is the source of truth for recovery
if the session is interrupted.

After all tasks complete, a final whole-branch review is dispatched on the most
capable model, reading a diff from merge-base to HEAD. If findings are returned,
one fix dispatch addresses all findings together, followed by a scoped
re-review. Residual findings are adjudicated as in the task loop's breaker.

When all reviews are clean, the workspace is deleted and finishing-a-development-branch
is invoked.

### Relation to the RFC Process

The superpowers pipeline and the RFC process are complementary, not competitive.

**Brainstorming's interview phase** maps to the RFC's early design stage. An
RFC sometimes begins with an existing brainstorming session's approved design, or vice
versa: a brainstorming session sometimes concludes with the decision to write an RFC
for cross-project requirements.

**The design document** (produced by brainstorming, approved by the user) maps
to an unpublished draft RFC. A well-formed design document already contains
architecture, constraints, rationale, and alternatives — the exact components
of an RFC Specification section. A design document can be promoted to a draft
RFC by adding the standard RFC structure (Abstract, Motivation, Terminology,
Formal Grammar if syntax is defined, Security Considerations, References,
Changelog, embedded evidence).

**Writing-plans' task decomposition** takes the approved design and produces
implementation work. Each task in the plan can be annotated with the RFC
requirement ID(s) it fulfills (for example, a requirement marker from a published RFC);
the plan then becomes a conformance ledger, binding the implementation to specific
approved requirements.

**Execution's review gates** and ledger serve as supplementary walls to the
RFC's embedded evidence. An RFC's evidence blocks replay deterministically to
verify claims; a plan's per-task review gates verify that implementation
decisions (not just claims) hold up to scrutiny. Together, they create two
interlocking safety walls: the RFC verifies what was promised; the plan's
ledger verifies what was built.

The key difference: RFCs are immutable once published and carry durable identity
for cross-project citation; superpowers artifacts (design documents, plans,
ledgers) are session-scoped and not meant for citation across projects. When a
requirement needs to be permanent and cross-cutting, it lives in an RFC. When a
feature is scoped to one project and its implementation is the artifact of
interest, it lives in a design document and plan.

## Alternatives Considered

### Three Separate RFCs (One Per Skill)

Writing three normative RFCs (one for brainstorming, one for writing-plans,
one for executing-plans/subagent-driven-development) would allow each skill
to carry its own embedded evidence (transcripts showing the process working).
Rejected in favor of a single Informational RFC because: (1) the three skills
are not interchangeable — brainstorming always precedes writing-plans, and
writing-plans always precedes execution; (2) an Informational record of the
pipeline as a whole is more useful than three separate normative processes
that would require coordinators to cross-reference; (3) the pipeline's evidence
is primarily implementation projects that use it, not transcripts of the skills
themselves.

### Normative Interoperability BCP Rather Than Informational Record

The pipeline could be specified as a BCP (Best Current Practice) with
normative language about how the three skills MUST interact. Rejected because:
(1) the pipeline's main value is to document what the superpowers library
already does, not to prescribe new interoperability requirements; (2) an
Informational record allows readers to understand the pipeline without
committing to it; (3) variations in execution (parallel vs. same-session,
single pass vs. fix loops) are features, not defects, and should not be
constrained by a normative BCP.

### Embedding This Specification in Project Documentation Rather Than RFC

The superpowers library already has documentation (SKILL.md files for each
skill). Rejected in favor of an RFC because: (1) RFC documentation carries
durable identity and can be cited by other work; (2) the RFC format enforces
structure (Abstract, Motivation, alternatives) that makes the pipeline's
design philosophy explicit; (3) RFCs accumulate in a version-controlled
series, whereas project docs drift or are deleted; (4) future work on
human–LLM planning workflows can cite this RFC directly.

### Layered Pipeline (Feedback Loops Back to Brainstorming)

The pipeline could allow tasks to be reassigned to brainstorming during
execution if hidden complexity is discovered (feeding back from writing-plans
or execution). Rejected in favor of the present one-way flow because:
(1) upgrade-at-discovery (stopping and reclassifying within brainstorming) is
already supported; (2) feeding execution findings back to brainstorming risks
scope creep and context loss mid-plan; (3) the plan's self-review gate catches
most decomposition defects before execution starts. If execution reveals a
fundamental design flaw, it is human work to decide whether to fork a
subagent-driven branch, pause and issue a ruling, or halt entirely.

## Security Considerations

The superpowers planning pipeline is a vehicle for directing agents to execute
code. Security properties depend on which agents are involved and what trust
boundaries they cross.

**Plans direct execution without human in-loop between tasks:** The
subagent-driven-development skill can execute many tasks continuously without
pausing to ask the human partner, using rulings to resolve ambiguities. This is
efficient but means a malicious or corrupted plan could direct subagents to
execute arbitrary code without further approval. Mitigation: (1) the plan is
authored in the same session as brainstorming and subject to user approval; (2)
the final human partner decision happens during writing-plans' execution
handoff (they choose subagent-driven vs. inline); (3) the ledger records all
rulings, so decisions made on the human partner's behalf are visible and
auditable after the session.

**Subagent dispatch trust:** Dispatching fresh subagents per task is efficient
but assumes those subagents will follow the plan and the brief faithfully.
A subagent that deviates from the plan, skips verification, or silently
applies its own judgment (rather than asking for clarification) becomes a
trust boundary. Mitigation: (1) the brief extracted from the plan is the single
source of requirements, not drift-prone narrative; (2) the implementer subagent
template explicitly forbids spawning subagents itself (no recursive dispatch);
(3) the task reviewer's template is designed to catch deviation from both the
plan's requirements and the implemented code's correctness.

**Prompts as injection surface:** The superpowers skills communicate via
prompts (the brainstorming questions, the plan text passed to writing-plans,
the brief and findings passed to implementers). A hostile actor with write
access to a plan file could inject instructions that override the human
partner's intent. Mitigation: (1) the plan is committed to git, so changes are
auditable; (2) the ledger records decisions and approvals, making it visible
if a later prompt contradicts them; (3) review gates (task reviewer, final
reviewer) are designed to flag unexpected code or behavior, catching drifts
that prompt injection might cause.

**Session compaction and recovery:** Ledger files are persisted to survive
session compaction, but the ledger is a plain-text file in git-ignored
scratch space. If the workspace is deleted or corrupted, the ledger vanishes
unless committed to git. Mitigation: (1) subagent-driven-development
instructs users to check the ledger and commit it if recovery matters; (2)
all work (commits) is in git proper, recoverable from `git log` even if the
workspace is lost; (3) the ledger is a convenience for resuming execution, not
the source of truth for what was built.

## References

- **Superpowers** library by Jesse Vincent:
  https://github.com/obra/superpowers
  (reviewed as installed from obra/superpowers-marketplace at commit
  1ab7b8eeef70, skill version 6.3.0)
- **Brainstorming skill:** `superpowers-dev/6.3.0/skills/brainstorming/SKILL.md`
- **Writing-plans skill:** `superpowers-dev/6.3.0/skills/writing-plans/SKILL.md`
- **Executing-plans skill:** `superpowers-dev/6.3.0/skills/executing-plans/SKILL.md`
- **Subagent-driven-development skill:**
  `superpowers-dev/6.3.0/skills/subagent-driven-development/SKILL.md`
- **The RFC Process for Human–LLM Specification Authoring:**
  `draft-ndn-authoring-rfcs-00` (the process BCP that the pipeline
  interoperates with)
- RFC 2026, RFC 6410 (process, categories); RFC 7322 (style); BCP 14 = RFC
  2119 + RFC 8174.

## Changelog

- 2026-08-14: draft-00 created. Documented the superpowers planning pipeline
  as a unified workflow spanning brainstorming (discovery), writing-plans (task
  decomposition), and executing-plans/subagent-driven-development (execution).
  FSM blocks derived from each skill's documented flow. Relation to RFC process
  documented: design docs map to draft RFCs, tasks can cite RFC requirement
  IDs, execution reviews and ledgers complement RFC evidence blocks.
  Security considerations address plan-directed execution, subagent trust,
  prompt injection, and session recovery. Alternatives considered: three
  separate RFCs (rejected; pipeline requires cross-referencing), normative
  BCP (rejected; Informational better fits documented practice), project docs
  (rejected; RFC durability and citeability matter), layered feedback (rejected;
  one-way flow with upgrade-at-discovery is sufficient). No embedded evidence:
  this is an Informational record of existing superpowers practices, not a
  normative specification with testable requirements.
