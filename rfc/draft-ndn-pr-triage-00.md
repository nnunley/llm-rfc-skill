# draft-ndn-pr-triage-00: PR Triage as a Guarded Machine

**Status:** DRAFT
**Corpus:** red (spec-first — the evidence is the acceptance criteria for the driver and the slimmed skill)
**Category:** Experimental
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)

## Abstract

Pull-request triage in a jj repository — polling open PRs, fixing red
checks, answering review, merging, and following up the issues they close
— specified as two guarded machines executed by the fsm executor of
draft-ndn-fsm-session-01. The machines decide what a triage agent may do
next and refuse moves whose evidence does not exist; the agent's judgment
is confined to three states. This document is for maintainers of the
pr-triage skill and for agents that run it.

## Motivation

The pr-triage skill is a prose procedure: 108 lines and 1,275 words of
loop steps, evidence bars, a rationalization table, and red flags, all of
which an agent must hold in context and remember to obey. In practice the
rules fail where the prose cannot reach: a PR was merged over a sign-off
request posted after the approval; failures were called "flaky" or
"pre-existing" without a base-branch run; a per-PR run record kept in a
workspace would vanish when that workspace is cleaned up. Each of these is
a move a machine can refuse rather than a rule an agent must recall. This
document moves the procedure into two machines whose guards demand
evidence the executor produces itself, and reduces the skill to the verbs
that drive them and the three states where judgment is the work.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **triage session** — one pass over a repository's open PRs, walked on
  the session machine under the record key `session`.
- **PR run** — the walk of one PR through the PR machine, under the record
  key `pr-<N>`; it outlives any workspace made for the PR.
- **class** — exactly one of `dirty`, `red`, `review`, `mergeable`, `idle`,
  describing a PR's state on the forge at the moment it is classified.
- **judgment state** — a state whose work is the agent's to decide:
  `FIX`, `RESPOND`, and `ISSUES`.
- **operator** — the person who configures the repository's checks and
  merge policy and approves posts.

## Specification

This document defines the triage process: the session and PR machines,
how a PR is classified, merge policy, ownership, waiting on the operator,
and the shape of the skill that drives it. It does NOT define the
executor, check keys, claims, or record stores; those are owned by
draft-ndn-fsm-session-01. It does NOT redefine the existing `pr-ws` and
`pr-poll` scripts; checks call them.

**The machine refuses; it does not remind.** Every rule this process can
check is a guard. A rule that survives only as prose in the skill is a
rule this document failed to encode.

**Command results are check keys.** Any evidence whose truth is a
command's exit status is a check key, recorded by the executor; the agent
attaches only judgment.

### The session machine

A triage session MUST walk this machine under the record key `session`;
entering `PR` runs the PR machine as a subprocess for the PR named by the
`pr` attachment. [R-pr-session]

```fsm @R-pr-session
initial SWEEP
SWEEP -> POLL
POLL -> PR
POLL -> ISSUES
POLL -> IDLE
PR -> POLL
ISSUES -> POLL
terminal IDLE
check swept
check polled
guard SWEEP -> POLL: swept
guard POLL -> PR: polled
guard POLL -> ISSUES: polled
guard POLL -> IDLE: polled
guard ISSUES -> POLL: issues
subprocess PR: draft-ndn-pr-triage-00 @R-pr-machine
return PR DONE -> POLL
return PR PARKED -> POLL
note SWEEP: record swept with the sweep check — it drops workspaces of merged or closed PRs and flags stale ones; nothing else happens first
note POLL: record polled; then enter PR for one PR with new activity, a red check, or a mergeable state, or ISSUES for the issue round, or IDLE when neither has work; attach pr: N before entering PR
note ISSUES: decide for each PR touched this session which open issues it fully resolves (Fixes) and which it only touches (Refs); the poll and linked scans are checks, the decision is yours; attach issues with the decisions, which the operator confirms before any PR text changes
note IDLE: stop; the record says what was done
```

### The PR machine

Each PR run MUST walk this machine under the record key `pr-<N>`. Every
check it names is resolved per draft-ndn-fsm-session-01; `change`,
`test-reason`, and `draft` are the only keys the agent attaches.
[R-pr-machine]

```fsm @R-pr-machine
initial CLASSIFY
CLASSIFY -> PROBE
CLASSIFY -> FIX
CLASSIFY -> RESPOND
CLASSIFY -> MERGE
CLASSIFY -> PARKED
PROBE -> REGEN
PROBE -> FIX
REGEN -> VERIFY
FIX -> VERIFY
FIX -> TEST_CHANGE
FIX -> RESPOND
TEST_CHANGE -> VERIFY
VERIFY -> FIX
VERIFY -> PUSH
PUSH -> CLASSIFY
RESPOND -> AWAIT_APPROVAL
AWAIT_APPROVAL -> RESPOND
AWAIT_APPROVAL -> CLASSIFY
MERGE -> MERGED
MERGE -> AWAIT_HUMAN
AWAIT_HUMAN -> MERGED
AWAIT_HUMAN -> CLASSIFY
MERGED -> DONE
terminal DONE
terminal PARKED
check owned
check dirty
check red
check review
check mergeable
check idle
check generated-only
check hand-merge
check regenerated
check diff-clean
check base-fails
check verify
check pushed
check posted
check merge-allowed
check merged
check cleaned
check issues-closed
guard CLASSIFY -> PROBE: owned dirty
guard CLASSIFY -> FIX: owned red
guard CLASSIFY -> RESPOND: owned review
guard CLASSIFY -> MERGE: owned mergeable
guard CLASSIFY -> PARKED: idle
guard PROBE -> REGEN: generated-only
guard PROBE -> FIX: hand-merge
guard REGEN -> VERIFY: regenerated
guard FIX -> VERIFY: change diff-clean
guard FIX -> TEST_CHANGE: change test-reason
guard FIX -> RESPOND: base-fails
guard TEST_CHANGE -> VERIFY: change
guard VERIFY -> PUSH: verify
guard PUSH -> CLASSIFY: pushed
guard RESPOND -> AWAIT_APPROVAL: draft
guard AWAIT_APPROVAL -> CLASSIFY: posted
guard MERGE -> MERGED: merge-allowed merged
guard AWAIT_HUMAN -> MERGED: merged
guard MERGED -> DONE: cleaned issues-closed
note CLASSIFY: record owned, then the one class check that holds; the checks decide the branch, you do not — a PR another agent owns parks until a handoff note transfers it
note PROBE: generated-only means every conflict on trunk is in a generated file and REGEN resolves it; hand-merge means a person-shaped conflict and you resolve it in FIX
note REGEN: record regenerated — it runs the repository's regeneration and its freshness check
note FIX: the work is yours: change the code in the PR's workspace and attach change: <commit>; record diff-clean when the diff adds no binaries, no stray files, and weakens no test; a diff that weakens a test goes through TEST_CHANGE with test-reason naming the issue, review, or PR text that intends the behavior change; if the failure is not yours, record base-fails (the check fails on the base commit too) and answer on the PR instead of fixing
note TEST_CHANGE: a test assertion is weakened or removed; test-reason must cite where the behavior change was intended, in writing, by someone other than you
note VERIFY: record verify — the configured test command at this tree; a hook that fails under load is a failed verify, not a flaky one
note PUSH: push through the repository's push wrapper and record pushed (the forge head equals the local bookmark)
note RESPOND: read every comment and thread critically before acting (critical-reading); draft the reply as the operator speaking (posting-as-the-user); attach draft: <path> sha256 <hash>; never post from this state
note AWAIT_APPROVAL: wait on the operator; the post happens only through comment-post --approved, which the posted check confirms; revisions go back to RESPOND
note MERGE: record merge-allowed only under merge policy when-approved with checks green, a deciding approval, and no comment newer than that approval; then merge and record merged; under policy never, go to AWAIT_HUMAN
note AWAIT_HUMAN: wait for the operator's merge decision; record merged once they have merged, or return to CLASSIFY if they decline
note MERGED: record cleaned (the PR's workspace removed) and issues-closed (every issue the PR claims to fix is closed on the forge — a stacked PR merged into its parent leaves them open)
note DONE: roll up the PR's record into one summary line
note PARKED: nothing to do now, or another agent owns the PR
```

### Classification

A PR is classified by checks, never by the agent. For each class there is
a check that exits 0 if and only if the PR is in that class, evaluated
from `pr-poll` output for the PR named by `FSM_RUN`. The classes MUST
partition the open PRs: at most one class check exits 0 for a PR at a
time, so the machine's branch is decided by the forge's state. Precedence
when several conditions hold: `dirty`, then `red`, then `review`, then
`mergeable`, then `idle`. [R-pr-classify]

```transcript @R-pr-classify
$ export FSM_RUN=pr-7
$ printf '{"number":7,"mergeable":"CONFLICTING","checks":"FAILURE"}\n' > poll.json
$ PR_POLL_FIXTURE=poll.json pr-class dirty; echo $?
0
$ PR_POLL_FIXTURE=poll.json pr-class red; echo $?
1
```

### Ownership

The `owned` check MUST exit 0 only when the PR run's owner is the current
agent role or unset, and recording it MUST set the owner to the current
role when unset. A PR owned by another role is classified `idle` and
parks; ownership moves only through a ledger handoff note on the run's
key. The rule exists so that two agents — two Claude sessions, or Claude
and Codex — never triage the same PR. [R-pr-owner]

```transcript @R-pr-owner
$ export FSM_RUN=pr-7 PR_TRIAGE_ROLE=claude-pr-triage
$ pr-owned; echo $?
0
$ PR_TRIAGE_ROLE=codex-pr-triage pr-owned; echo $?
1
```

### Merge policy

| Key | Type | Default | Description |
|---|---|---|---|
| `pr-triage.merge` (jj repo config) | `never` \| `when-approved` | `never` | Whether the machine merges on its own. |

Under `never`, the `merge-allowed` check MUST exit nonzero, so `MERGE`
can only proceed through `AWAIT_HUMAN`. Under `when-approved` it exits 0
only when the PR's gating checks are green, a reviewer's latest
deciding review is an approval, and no comment or review on the PR is
newer than that approval. The default is `never` because a guard nobody
thought of becomes an unattended merge; a repository opts in.
[R-pr-merge-policy]

```transcript @R-pr-merge-policy
$ export FSM_RUN=pr-7
$ jj config set --repo pr-triage.merge never
$ pr-merge-allowed; echo $?
1
```

### Waiting on the operator

In `AWAIT_APPROVAL` and `AWAIT_HUMAN`, a triage agent on the ledger store
SHOULD block on `ledger watch --since <cursor>` for the run's key rather
than poll, and MUST NOT advance until the check that leaves the state
(`posted`, `merged`) records. The operator's action is the event that
wakes the agent. [R-pr-await]

```transcript @R-pr-await
$ ledger watch --since 0 --timeout 1 >/dev/null; echo $?
2
```

### Closing a run

On entering `DONE`, the run's ledger thread MUST be rolled up into one
summary line naming the PR number, its merge, and the issues it closed,
so the ledger's history shows one line per finished PR. [R-pr-rollup]

```transcript @R-pr-rollup
$ ledger tail -n 1 | grep -c "pr-7: merged"
1
```

### Derivation and setup

The machines are derived artifacts. `bin/pr-init` MUST tangle both fsm
blocks from this document with `rfc-tangle`, validate each with `rfc-run
--type fsm`, and, on the ledger store, create the repository's
`pr-triage` ledger with the field `state` whose vocabulary is the union
of both machines' states, and the field `owner`. The `.fsm` files MUST
NOT be edited; a change to the process is a change to this document,
re-tangled. [R-pr-init]

```transcript @R-pr-init
$ pr-init .pr-triage | grep -c "machines in .pr-triage"
1
$ ls .pr-triage
pr.fsm
session.fsm
```

### Configuration

| Key | Type | Default | Description |
|---|---|---|---|
| `pr-triage.repo` | `OWNER/NAME` | none | The forge repository `gh` targets. |
| `pr-triage.workspace-root` | Path | `.workspaces` | Where PR workspaces are made. |
| `pr-triage.generated` / `regen` / `regen-check` | Glob / Command / Command | none | What `regen` resolves, and how. |
| `pr-triage.push-wrap` | Command | none | Wrapper for pushes (e.g. a benchmark lock). |
| `pr-triage.merge` | `never` \| `when-approved` | `never` | Merge policy (above). |
| `pr-triage.store` | `file` \| `ledger` | `ledger` when the `ledger` tool is installed, else `file` | The record store. |
| `fsm.check.<id>` (git config `--local`) | Command | none | Each check the machines name, per draft-ndn-fsm-session-01. |

All keys are jj repository config (never committed), except the checks,
which are local git config as draft-ndn-fsm-session-01 requires. The
`store` default prefers the ledger because only there does the record
outlive the workspace it describes.

### Errors

| Condition | Exit | Recovery |
|---|---|---|
| No class check holds | 1 | Re-poll; the forge's state changed between poll and classify. |
| More than one class check holds | 2 | A bug: the class checks do not partition. |
| PR owned by another role | parks | Request a handoff note on the run's key. |
| A check the machines name is not configured | 2 | Configure `fsm.check.<id>`; `pr-init` lists the IDs. |
| `pr-init` finds an invalid machine | 2 | Fix this document and re-tangle. |

### The skill

The pr-triage skill MUST teach only: setting up (`pr-init`), the executor
verbs (query, `--attach`, `--record`, advance with `--why`, `--audit
--recheck`), and how to work inside the three judgment states. Stage
guidance lives in the machines' `note` lines, disclosed one state at a
time, and MUST NOT be restated in the skill. The skill's `SKILL.md` MUST
stay within 60 lines and under 500 words. [R-pr-skill-bound]

```transcript @R-pr-skill-bound
$ test "$(wc -l < "$PR_TRIAGE_SKILL/SKILL.md")" -le 60; echo $?
0
$ test "$(wc -w < "$PR_TRIAGE_SKILL/SKILL.md")" -lt 500; echo $?
0
```

## Alternatives Considered

### Why not keep the procedure as prose in the skill?

It is the status quo, and the failures in Motivation are its record: a
rule an agent must remember is a rule it can skip under pressure.

### Why not one machine for the whole session?

PRs proceed independently and in parallel; one machine would interleave
their states. A session machine with a per-PR subprocess keeps each PR's
record separate, which is also what ownership and rollup key on.

### Why not let the agent choose the PR's branch?

A branch chosen by the agent is the rationalization the old red-flags
list warned against. Class checks make the forge's state the decider.

### Why not merge whenever the guards hold?

A guard nobody thought of becomes an unattended merge. Policy defaults to
`never`; a repository opts in.

### Why not keep the run record in the PR's workspace?

The workspace is removed when the PR finishes, which is exactly when its
history is wanted.

## Security Considerations

Checks execute repository code — running the PR's tests is the point of
verifying it — and they are resolved only through local configuration
the operator sets, never through the run record or committed files
(draft-ndn-fsm-session-01). Posting as the operator happens only through
`comment-post --approved`, after the operator has seen the exact text; no
state posts. Merging defaults to the operator. Ownership rests on
self-declared roles and prevents accidental collisions between
cooperating agents, not a hostile one. The ledger's events propagate
to every clone once pushed, so records carry PR and issue numbers,
commit and tree IDs, check IDs, and hashes only; drafts and logs stay in
local files.

## References

- draft-ndn-fsm-session-01 — the executor, check keys, claims, record
  stores; normative.
- draft-claude-xp-pairing-00 — the precedent for a guarded process with a
  derived skill and a subprocess machine.
- The pr-triage skill (`skills/pr-triage/`), its `pr-ws` and `pr-poll`
  scripts, and the critical-reading and posting-as-the-user skills its
  judgment states require.
