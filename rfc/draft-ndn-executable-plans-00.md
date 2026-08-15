# draft-ndn-executable-plans-00: Executable Plans

**Status:** DRAFT
**Category:** Experimental
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)
**Date:** 2026-08-14

## Abstract

A plan derived from RFCs is a state machine document, and executing it
is walking that machine under a run record: the executor provides the
next step, refuses to advance until guards are satisfied by attached
evidence, records which alternative was taken and why, and the finished
run audits against the machine and the repository — a ledger hard to
forge without doing the work. The whole interaction surface is three
verbs over two files, encapsulated enough to wrap as a skill or an MCP
server one-to-one.

## Motivation

The goal, stated as its use case: "create a plan to implement a fully
self-hosted, bootstrapped system from the relevant RFCs, and come out
with a state machine document that can be executed and then validated
with evidence of each step in the flow being executed — and when an
alternative path is taken, which one, and why." Prose plans cannot do
this: they do not know where execution stands, cannot refuse a step
whose prerequisites are unmet, and record decisions only if someone
remembers to. The series already has every part — machines with
guidance, deadlines, and guards; run records with evidence attachments;
audit against machine and repository; the plan-breakdown coverage rule —
and this document composes them into the plan form.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **executable plan** — a plan document whose Specification is an fsm:
  states are steps, branches are the plan's alternative paths, and step
  guidance (including the requirement IDs the step implements) rides the
  machine's `note` lines.
- **step evidence** — run-record attachments under a step's state:
  `commit:`, test results, decision summaries.
- **branch rationale** — the `why:` attachment recorded on entering a
  state via an alternative edge.
- **plan run** — one execution of the plan: a run record over the plan's
  machine.

## Specification

### The plan is a machine

An executable plan's Specification MUST contain the plan as an fsm
block: one state per step or phase, alternative paths as branches,
completion as a terminal state, and each implementing step's `note`
naming the requirement IDs it implements. The BCP's plan-breakdown rule
applies unchanged and mechanically: every `[R-]` ID from the source RFCs
appears in the plan, every plan step names the IDs it implements, and
the coverage check is the same marker-set comparison. Because the plan
is an fsm block in a document, it is validated by the same machinery as
every machine in the corpus — single initial, reachability, terminal
closure, guard legality — before any execution.

### Execution is guarded

A plan run advances only through the executor: query discloses the
current step's guidance and legal moves (with each guarded edge's
satisfied or missing evidence), and advance REFUSES a guarded edge until
the guard-named evidence keys are attached — the next step is withheld
until the work's evidence exists, not merely warned about. Alternative
paths are ordinary branches: taking one records the entered state (which
alternative — the path itself) and SHOULD record the rationale (`why`).
[R-plan-guarded]

Plan evidence is written in the **plan-run vocabulary** — statements
mirroring the executor's verbs, with the adapter owning every engine
mechanic (workspace, repository, invocation), per the evidence-adapters
doctrine: this document's blocks carry intent only.

```
machine <fsm-statement>          build the plan's machine, line by line
refuse <TARGET> missing <keys>   advancing must be refused for these keys
attach <key>: <value>            attach evidence to the current state
advance <TARGET> [why: <text>]   advance must succeed
at <STATE>                       assert the current state
work <message>                   do work: a real commit, attached as commit:
audit ok | audit fail <text>     the ledger must audit clean / must not
```

```plan-run @R-plan-guarded
machine initial DESIGN
machine DESIGN -> BUILD
machine BUILD -> VERIFY
machine BUILD -> DESIGN
machine VERIFY -> DONE
machine terminal DONE
machine guard DESIGN -> BUILD: decision
machine guard BUILD -> VERIFY: commit test
machine note BUILD: implement the step's named requirement IDs
refuse BUILD missing decision
attach decision: single-file layout per interview
advance BUILD why: layout decided, guard met
at BUILD
refuse VERIFY missing commit test
```

### Completion and audit

A plan run is COMPLETE when it reaches a terminal state by a legal path;
alternatives not taken are visibly absent from the path — nothing
pretends unvisited branches were executed. A completion claim MUST be
accompanied by a clean `--audit`, which re-verifies the ledger end to
end: path legality, every guard retroactively satisfied, every `commit:`
and `anchor:` resolvable in the repository, anchors in ancestry order.
The audit is what makes the plan's ledger hard to forge without doing
the work: its claims point at artifacts that only exist if the work
happened. [R-plan-complete]

```plan-run @R-plan-complete
machine initial BUILD
machine BUILD -> DONE
machine terminal DONE
machine guard BUILD -> DONE: commit
refuse DONE missing commit
work implement the step against its requirement IDs
advance DONE why: evidence complete
at DONE
audit ok
```

### Encapsulation: three verbs, two files

The entire interaction surface is three verbs over two files — the
machine and the run:

| verb    | invocation                                   | answers            |
|---------|----------------------------------------------|--------------------|
| status  | `rfc-fsm-exec <plan> --state <run>`          | where am I, what is permitted, what is missing |
| advance | `rfc-fsm-exec <plan> --state <run> <target> [--why ...]` | move, or be refused with the reason |
| attach  | `rfc-fsm-exec <plan> --state <run> --attach "k: v"` | record evidence where I stand |

(`--audit` is the fourth, offline verb: re-verify the whole ledger.)
There is no other state, no daemon, no registry — text in, text out.
An implementation wrapping this as a skill instructs the agent to call
the verbs; an MCP implementation maps them to tools one-to-one; both
inherit the guards, the disclosure scoping, and the audit unchanged. An
implementation MUST NOT add advance paths that bypass the executor —
the encapsulation is the enforcement.

## Alternatives Considered

### Plans as prose task lists

The existing form. Retained for what it is good at (human reading), but
it cannot know where execution stands, cannot refuse an unready step,
and records rationale only by discipline. The machine form adds
exactly those properties and loses nothing — prose guidance rides the
`note` lines.

### A plan-specific runtime

A dedicated plan engine with richer step semantics (parallel steps,
retries, timers). Rejected as a start: the fsm executor already provides
guarded, disclosed, auditable walks, and every capability added to the
general machinery accrues to every machine in the corpus. Parallelism
and retries can be modeled as states and branches until proven
insufficient.

### Trusting the agent's own progress reporting

The status quo this replaces, and the forgery the audit exists to catch:
self-reported progress costs nothing to fabricate. Here the guard
withholds the step, the anchor laces the ledger into history, and the
audit re-derives the whole claim from artifacts.

## Security Considerations

The executor is advisory process governance, not an authorization
boundary — an agent editing the run file directly bypasses the guards;
the audit exists exactly for that, re-deriving every claim from the
machine and the repository, and a completion claim without a clean audit
has no standing. Anchors and commit evidence tie the ledger to
repository history; an agent could still commit low-value artifacts to
satisfy guards mechanically, which is why guard evidence is REVIEWABLE
by construction (commits are diffs, summaries are prose) and plan
completion feeds human gates — the audit narrows the forgery space to
"artifacts a reviewer would reject," it does not replace review.

## References

- The process BCP: draft-ndn-authoring-rfcs-00 — fsm vocabulary
  (including guards), plan-breakdown coverage rule.
- draft-ndn-fsm-session-00 — run records, evidence attachments,
  anchoring, and the audit this document requires for completion.
- draft-ndn-conformance-execution-00 — the gate the plan's corpus
  obligations still run through; a plan run never substitutes for it.

## Changelog

- 2026-08-14: draft-00 created from the author's requirement: plans
  derived from RFCs as executable state machine documents — next step
  provided, advance refused without guard evidence, alternatives
  recorded as path plus why, ledgers audited against machine and
  repository so they are hard to forge without doing the work, and the
  whole surface encapsulated as three verbs over two files for skill or
  MCP wrapping.
- 2026-08-14: evidence rewritten from raw shell transcripts to the
  plan-run vocabulary after author corrections — documents carry intent
  in the domain's language; the vocabulary is data executed by the
  generic flow runner, per the evidence-adapters doctrine.
