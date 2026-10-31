---
name: evidence-review
description: Use when reviewing code, a design, a plan, or a claim; resolving conflicting evidence; or resuming an interrupted review.
---

# Review from evidence

Keep only what changes the next decision. Start or resume a small review
container using [session.md](references/session.md). A fact or finding needs
a witness, not an RFC. This works with one human and one agent; there is
no publication ladder, mandatory panel, or fixed number of review rounds.

## Facts

Record relevant claims as:
`ID | claim | state | evidence for / against | depends on | scope/revision; observed-at`.
Distinguish when a claim held from when it was learned. Link evidence;
do not copy logs.

| State | Meaning | Next action |
|---|---|---|
| UNKNOWN | Insufficient current evidence | Inspect the deciding source |
| ESTABLISHED | Supported within its recorded scope | Use while support remains current |
| CONTRADICTED | Unresolved evidence for and against | Preserve both; resolve the conflict |
| RETRACTED | A previously accepted claim withdrawn on evidence | Record why; revisit its dependents |

A missing search result is not proof of absence. Retraction needs the probe's
scope, observation, and reason it defeats the claim. Changed inputs without
a counter-witness make support UNKNOWN, not false. Retraction is a historical
operation, not merely another spelling of Boolean false.
Keep conflicting evidence CONTRADICTED until the conflict is resolved;
retract only when the deciding evidence defeats the accepted claim.

When a premise is retracted or disputed, mark dependent conclusions UNKNOWN
transitively and reopen affected commitments. Keep the conflict/retraction
and its provenance; do not silently rewrite history or patch around it.
Fresh independent evidence can re-establish a conclusion.

## Review

Establish the requested outcome and what would settle it. Inspect the work
and record only actionable findings: claim, fact IDs, consequence, deciding
check. Resolve each as addressed, dismissed, or explicitly deferred, with
evidence or rationale. Reviewer assertions are claims to examine, not orders.
Changes reopen affected findings and checks. Stop when the agreed criterion
is met or a concrete unresolved decision needs the user; do not invent
another review round. Report remaining uncertainty rather than forcing green.

## Commitments

Separate the requested outcome, our promise to deliver it, assertions of
observed results, and acceptance by the party authorized to judge it.
Record only the outcome, deciding premises, acceptance condition, consuming
stage, and authority already granted. A claim of completion is not acceptance.

The review itself is governed by `state/05_workflow.md`:

```makefile
review-complete: scope-known findings-assessed findings-resolved checks-current outcome-accepted
```

Each target's claim and witnesses live in `15_facts.md`; additional premise
dependencies live there too. A target is fulfilled only when its claim and
all prerequisites are currently ESTABLISHED. The aggregate goal needs no
separate completion flag. This is agent-readable notation, not shell code.
Recompute from facts at every resume; an ESTABLISHED row with an invalid
dependency is UNKNOWN. Unsupported or conflicted premises block dependent
work; renegotiate an affected promise.
Continue independent authorized work. Existing authorization survives
resume within its scope.

## Resume

Read the private session's numbered state files before acting, including
after compaction; setup is in [session.md](references/session.md).
Restore the request, graph, relevant facts, open commitment, and next dependency.
Check evidence currency; an old next-action pointer cannot establish truth.
Load only the source or procedure needed there. Update state when facts or
commitments change; keep history and logs outside the boot view.

Use tools to test claims; a recorded assertion is not verification. Load
[conformance-corpus.md](references/conformance-corpus.md) only when working
on RFC evidence; existing contracts still apply where actually adopted.
The helper stores state; fact judgments and dependency updates remain
agent-interpreted, not mechanically enforced.
