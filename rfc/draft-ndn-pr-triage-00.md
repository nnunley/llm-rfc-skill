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
is confined to three states, and every rule a command can decide is a
guard. This document is for maintainers of the
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
  the session machine under a key unique to the session.
- **PR run** — one walk of one PR through the PR machine: a child run of
  the session (draft-ndn-fsm-session-01), keyed `pr-<N>/r<k>`. A PR may
  have many runs over time; each ends at `DONE`, `PARKED`, or `CANCELLED`.
- **snapshot** — one reading of one PR's state, recorded as an
  observation on each visit to `CLASSIFY`: the forge's state, the PR's
  ownership in the ledger, and its activity cursor (the newest comment or
  review its earlier runs have seen), in one receipt.
- **class** — exactly one of `already-merged`, `closed`, `parked`,
  `dirty`, `red`, `review`, `mergeable`, decided from a snapshot.
- **instance** — one running triage agent, named by a role and a unique
  suffix (`claude-pr-triage/7f3a`); two sessions of the same role are two
  instances.
- **judgment state** — a state whose work is the agent's to decide: `FIX`,
  `RESPOND`, and `ISSUES`.
- **operator** — the person who configures the repository's commands and
  merge policy and approves posts and merges.

## Specification

This document defines the triage process: the session and PR machines,
classification, ownership, merge policy, waiting on the operator and the
forge, and the shape of the skill that drives it. It does NOT define the
executor, checks, observations, claims, subprocess runs, or record stores;
those are owned by draft-ndn-fsm-session-01. It does NOT redefine the
`pr-ws` and `pr-poll` scripts; the configured commands call them.

**The machine refuses; it does not remind.** Every rule this process can
check is a guard. A rule that survives only as prose in the skill is a
rule this document failed to encode.

**Commands decide facts; the agent decides judgment.** Evidence whose
truth is a command's result is a check or an observation, recorded by
the executor; the agent attaches only its judgment (`pr`, `issues`,
`hand-merge`, `change`, `test-reason`, `blocked`, `requested`, `draft`,
`declined`).

### The session machine

A triage session MUST walk this machine. Entering `PR` starts a PR run as
a subprocess for the PR named by the `pr` attachment; the session leaves
`PR` only through a return the run has reached. Leaving for `IDLE` needs
both that no PR needs action and that this session has done its issue
round. [R-pr-session]

```fsm @R-pr-session
initial SWEEP
SWEEP -> POLL
POLL -> PR
POLL -> ISSUES
POLL -> IDLE
PR -> POLL
ISSUES -> POLL
terminal IDLE
observe swept
observe polled
observe quiet
observe issue-round
guard SWEEP -> POLL: swept
guard POLL -> PR: polled pr
guard POLL -> ISSUES: polled
guard POLL -> IDLE: polled quiet issue-round
guard ISSUES -> POLL: issues
subprocess PR: draft-ndn-pr-triage-00 @R-pr-machine
return PR DONE -> POLL
return PR PARKED -> POLL
return PR CANCELLED -> POLL
note SWEEP: record swept — it removes workspaces of merged or closed PRs and flags stale ones; nothing else happens first
note POLL: record polled; attach pr: <N> and enter PR for one PR with new activity, a red check, or a mergeable state; enter ISSUES for the issue round; leave for IDLE only when quiet (no PR needs action) and issue-round (this session has been through ISSUES since its last PR run) both record
note ISSUES: for each PR this session touched, decide which open issues it fully resolves (Fixes) and which it only touches (Refs); the issue scans are commands, the decision is yours; attach issues with the decisions, which the operator confirms before any PR text changes
note IDLE: stop; the record says what was done
```

### The PR machine

Each PR run MUST walk this machine. The whole process — this machine
inlined into the session machine — MUST compile with `rfc-fsm-compile`
and validate as one machine, so a seam between the two cannot dead-end
unnoticed. [R-pr-machine]

```fsm @R-pr-machine
initial CLASSIFY
CLASSIFY -> PROBE
CLASSIFY -> FIX
CLASSIFY -> RESPOND
CLASSIFY -> MERGE
CLASSIFY -> PARKED
CLASSIFY -> CANCELLED
CLASSIFY -> MERGED
PROBE -> REGEN
PROBE -> FIX
REGEN -> VERIFY
REGEN -> FIX
FIX -> VERIFY
FIX -> TEST_CHANGE
FIX -> RESPOND
FIX -> PARKED
TEST_CHANGE -> VERIFY
VERIFY -> FIX
VERIFY -> PUSH
PUSH -> CLASSIFY
RESPOND -> AWAIT_APPROVAL
RESPOND -> FIX
AWAIT_APPROVAL -> RESPOND
AWAIT_APPROVAL -> DONE
AWAIT_APPROVAL -> PARKED
MERGE -> MERGED
MERGE -> AWAIT_HUMAN
AWAIT_HUMAN -> MERGED
AWAIT_HUMAN -> DONE
AWAIT_HUMAN -> PARKED
MERGED -> DONE
terminal DONE PARKED CANCELLED
observe snapshot
observe owned
observe already-merged
observe closed
observe parked
observe dirty
observe red
observe review
observe mergeable
observe isolated
observe generated-only
observe base-fails
observe pushed
observe posted
observe merge-allowed
observe merged
observe cleaned
observe issues-settled
observe wait-expired
check regenerated
check artifacts-clean
check tests-untouched
check tests-touched
check verify
guard CLASSIFY -> MERGED: snapshot already-merged
guard CLASSIFY -> CANCELLED: snapshot closed
guard CLASSIFY -> PARKED: snapshot parked
guard CLASSIFY -> PROBE: snapshot owned dirty isolated
guard CLASSIFY -> FIX: snapshot owned red isolated
guard CLASSIFY -> RESPOND: snapshot owned review
guard CLASSIFY -> MERGE: snapshot owned mergeable
guard PROBE -> REGEN: generated-only
guard PROBE -> FIX: hand-merge
guard REGEN -> VERIFY: change regenerated artifacts-clean
guard REGEN -> FIX: hand-merge
guard FIX -> VERIFY: change artifacts-clean tests-untouched
guard FIX -> TEST_CHANGE: change tests-touched
guard FIX -> RESPOND: base-fails
guard FIX -> PARKED: blocked
guard TEST_CHANGE -> VERIFY: test-reason artifacts-clean
guard VERIFY -> PUSH: verify
guard PUSH -> CLASSIFY: pushed
guard RESPOND -> AWAIT_APPROVAL: draft
guard RESPOND -> FIX: requested isolated
guard AWAIT_APPROVAL -> DONE: posted
guard AWAIT_APPROVAL -> PARKED: wait-expired
guard MERGE -> MERGED: merge-allowed merged
guard AWAIT_HUMAN -> MERGED: merged
guard AWAIT_HUMAN -> DONE: declined
guard AWAIT_HUMAN -> PARKED: wait-expired
guard MERGED -> DONE: cleaned issues-settled
note CLASSIFY: record snapshot, then the one class it decides (already-merged, closed, parked, dirty, red, review, mergeable) and owned; for dirty or red also record isolated — the PR's workspace exists, is at the PR head, and is not the main checkout; the snapshot decides the branch, you do not
note PROBE: record generated-only when every conflict on trunk is in a generated file, and REGEN resolves it; otherwise attach hand-merge describing the conflict and resolve it in FIX
note REGEN: run the repository's regeneration in the PR's workspace and commit the result, attaching change: <commit>; then record regenerated (the freshness check at that commit) and artifacts-clean; if regeneration cannot resolve the conflict, attach hand-merge and go to FIX
note FIX: the work is yours: change the code in the PR's workspace and attach change: <commit>; record artifacts-clean (no binaries, no untracked or scratch files in the diff) and tests-untouched (the diff edits no test file) to go to VERIFY; a diff that edits a test file records tests-touched instead and goes through TEST_CHANGE; if the failure is not the PR's, record base-fails and answer on the PR; if you cannot proceed, attach blocked with the reason and park
note TEST_CHANGE: a test file is edited; attach test-reason citing where the behavior change was intended, in writing, by someone other than you (an issue, a review, the PR description), and record artifacts-clean
note VERIFY: record verify — the configured test command at this commit; a failure goes back to FIX, and a hook that fails under load is a failed verify, not a flaky one
note PUSH: push through the repository's push wrapper and record pushed (the forge head equals the local bookmark); the next CLASSIFY usually finds CI pending and parks until a later poll
note RESPOND: read every comment and thread critically before acting (critical-reading); if the review asks for changes, attach requested summarizing them, record isolated, and go to FIX; otherwise draft the reply as the operator speaking (posting-as-the-user), attach draft: <path> sha256 <hash>, and never post from this state
note AWAIT_APPROVAL: wait for the operator; the post happens only through comment-post --approved, and posted records once it is on the forge, ending the run; a requested revision goes back to RESPOND; record wait-expired when the wait runs out, and the run parks
note MERGE: record merge-allowed immediately before merging — policy when-approved, every required check green at the snapshot's head commit, no outstanding change request from any reviewer, an approval at that head, and no comment newer than it — then merge with the head pinned (gh pr merge --match-head-commit) and record merged; under policy never, go to AWAIT_HUMAN
note AWAIT_HUMAN: wait for the operator's merge decision; record merged once they merge; attach declined with their reason if they decline, which ends the run and holds until the PR's head changes; record wait-expired when the wait runs out, and the run parks
note MERGED: record cleaned (the PR's workspace removed) and issues-settled (every issue the PR claims to fix is closed, or, for a PR merged into a stacked parent, a follow-up is recorded on the parent)
note DONE: the run is complete — merged, answered, or declined; roll up its record into one summary line
note PARKED: nothing to do in this run — CI pending, nothing to act on, another instance owns the PR, or you were blocked; a later session starts a new run
note CANCELLED: the PR was closed without merging; nothing further
```

### Classification

A run's branch is decided by the PR's state, through a snapshot. On every
visit to `CLASSIFY`, the `snapshot` observation MUST record one receipt
holding the forge's state (the `pr-poll` JSON for the PR named by the
run), the PR's ownership as the ledger shows it, and its activity
cursor. Each class observation MUST decide from that visit's receipt only
— never from a fresh poll or a receipt from an earlier visit — so a class
is judged against one consistent state, and a return to `CLASSIFY` after
a push judges the new head. The classes
MUST partition: exactly one class observation exits 0 for a given
snapshot, by this precedence, first match wins: [R-pr-classify]

| Precedence | Class | Holds when |
|---|---|---|
| 1 | `already-merged` | The PR is merged on the forge (by anyone). Its run goes straight to `MERGED`, so cleanup and issue settlement still happen. |
| 2 | `closed` | The PR is closed without merging. |
| 3 | `parked` | Another live instance owns the PR; or gating checks are pending or queued; or the forge returned an error or an incomplete state; or nothing below holds (no activity since this PR's last run, nothing to merge). The receipt names which. |
| 4 | `dirty` | The PR conflicts with its base. |
| 5 | `red` | A gating check failed at the head commit. |
| 6 | `review` | A comment, review, or thread is newer than the activity cursor, excluding comments whose IDs an earlier run recorded in a `posted` receipt. |
| 7 | `mergeable` | Every gating check is green and the PR is approved at the head commit, and no earlier run recorded `declined` at that head. |

Draft PRs are `parked` unless the operator has configured otherwise. A **gating check** is one the
forge's branch protection requires for merging.

```transcript @R-pr-classify
$ printf '{"number":7,"state":"OPEN","mergeable":"CONFLICTING","checks":"FAILURE"}\n' > snap.json
$ pr-class --snapshot snap.json dirty; echo $?
0
$ pr-class --snapshot snap.json red; echo $?
1
$ printf '{"number":7,"state":"OPEN","mergeable":"MERGEABLE","checks":"PENDING"}\n' > pending.json
$ pr-class --snapshot pending.json parked; echo $?
0
$ printf '{"number":7,"state":"MERGED","mergeable":"UNKNOWN","checks":"SUCCESS"}\n' > merged.json
$ pr-class --snapshot merged.json already-merged; echo $?
0
$ for c in already-merged closed parked dirty red review mergeable; do pr-class --snapshot snap.json $c && echo $c; done | wc -l
1
```

### Ownership

The `owned` observation MUST exit 0 only when no other instance holds a
live lease on the PR, and recording it gives the current instance the
lease. A lease is an owner event on the PR's key in the ledger; it is
live until it expires (`pr-triage.lease`), is released, or its run
reaches a terminal, and the holder renews it with every record it
writes. Acquisition writes a claim event, then reads the PR's owner
events back in ledger order: the earliest live claim wins, and a losing
instance MUST release its own claim at once, so a lost race leaves no
stale claim behind. A crashed holder's lease simply expires. A PR whose
lease another instance holds classifies `parked`. [R-pr-owner]

Arbitration needs one ordered record: it holds among instances writing
the same ledger in one repository's git directory. Instances in clones
that have not exchanged ledger events are not coordinated, and this
document does not claim they are. On the file store, which has no shared
order, `pr-init` MUST refuse to start a second live instance (an
exclusive lock file under the repository's git directory).

```transcript @R-pr-owner
$ export PR_TRIAGE_LEASE=2s
$ PR_TRIAGE_INSTANCE=claude-pr-triage/a pr-owned --pr 7; echo $?
0
$ PR_TRIAGE_INSTANCE=claude-pr-triage/b pr-owned --pr 7; echo $?
1
$ ledger status pr-7 --ledger pr-triage | grep -c "claude-pr-triage/b"
0
$ sleep 3
$ PR_TRIAGE_INSTANCE=claude-pr-triage/b pr-owned --pr 7; echo $?
0
```

### Merge policy

| Key | Type | Default | Description |
|---|---|---|---|
| `pr-triage.merge` | `never` \| `when-approved` | `never` | Whether the machine merges on its own. |

Under `never`, `merge-allowed` MUST exit nonzero, so `MERGE` proceeds only
through `AWAIT_HUMAN`. Under `when-approved` it MUST fetch the PR's
review and check state from the forge afresh — not from the snapshot —
and exit 0 only when: the head is the snapshot's head; every check
branch protection requires is green at that head; no reviewer's latest
review requests changes; at least one approval is at that head; and no
comment or review is newer than that approval. The merge that follows
MUST pin the head (`gh pr merge --match-head-commit <sha>`), so a push
between authorization and merge fails the merge. A comment or review
posted at the same head in that interval is not detected; the window is
the time between two commands, and this document names it rather than
claim it closed. The default is `never` because a condition nobody
thought of becomes an unattended merge. [R-pr-merge-policy]

```transcript @R-pr-merge-policy
$ jj git init -q . 2>/dev/null
$ printf '{"number":7,"state":"OPEN","head":"abc","checks":"SUCCESS","reviews":[{"state":"APPROVED","commit":"abc","at":"2026-10-03T10:00:00Z"}],"comments":[]}\n' > ok.json
$ printf '{"number":7,"state":"OPEN","head":"abc","checks":"SUCCESS","reviews":[{"state":"APPROVED","commit":"abc","at":"2026-10-03T10:00:00Z"}],"comments":[{"at":"2026-10-03T11:00:00Z","body":"hold on"}]}\n' > objection.json
$ jj config set --repo pr-triage.merge never
$ PR_FORGE_FIXTURE=ok.json pr-merge-allowed --head abc; echo $?
1
$ jj config set --repo pr-triage.merge when-approved
$ PR_FORGE_FIXTURE=ok.json pr-merge-allowed --head abc; echo $?
0
$ PR_FORGE_FIXTURE=objection.json pr-merge-allowed --head abc; echo $?
1
$ PR_FORGE_FIXTURE=ok.json pr-merge-allowed --head def; echo $?
1
```

### Waiting

`AWAIT_APPROVAL` and `AWAIT_HUMAN` wait on the operator, and what they
wait for happens on the forge: a comment posted, a PR merged. The agent
MUST poll for the leaving observation (`posted`, `merged`) every
`pr-triage.poll-interval`; after `pr-triage.poll-limit` polls it records
`wait-expired` and the run parks, ending its lease, so a wait never holds
a PR or a session without bound. Where the operator's decision is written
to the ledger (approving a draft, declining a merge), the agent SHOULD
block on `ledger watch` for the run's key instead of polling. The
revision edge (`AWAIT_APPROVAL -> RESPOND`) and the decline edge
(`AWAIT_HUMAN -> DONE`) are always available. [R-pr-await]

```transcript @R-pr-await
$ ledger init >/dev/null 2>&1; cursor=$(ledger watch --timeout 1 2>/dev/null | sed -n 's/.*"starting_cursor":"\([^"]*\)".*/\1/p' | head -1)
$ ledger watch --since "$cursor" --timeout 1 >/dev/null 2>&1; echo $?
2
```

### Closing a run

On reaching `DONE`, the run's ledger thread MUST be rolled up into one
summary line naming the PR and what the run did — merged and the issues
it settled, answered, or declined — so the ledger shows one line per
finished run. [R-pr-rollup]

```transcript @R-pr-rollup
$ ledger tail -n 1 | grep -c "pr-7/r1: merged"
1
```

### Derivation and setup

The machines are derived artifacts. `bin/pr-init` MUST tangle both fsm
blocks from this document with `rfc-tangle`, compile the session machine
with `rfc-fsm-compile` and validate the result with `rfc-run --type fsm`,
list every check and observation key whose command is not configured,
and, on the ledger store, create the repository's `pr-triage` ledger with
the fields `state` (the union of both machines' states), `attach`, `pin`,
and `owner`. The `.fsm` files MUST NOT be edited; a change to the process
is a change to this document, re-tangled. [R-pr-init]

```transcript @R-pr-init
$ rfc-fsm-compile "$RFC_DOC" --tag @R-pr-session > process.fsm; echo $?
0
$ rfc-run --type fsm process.fsm >/dev/null; echo $?
0
$ pr-init .pr-triage | grep -c "machines in .pr-triage"
1
```

### Configuration

| Key | Type | Default | Description |
|---|---|---|---|
| `pr-triage.repo` | `OWNER/NAME` | none | The forge repository `gh` targets. |
| `pr-triage.workspace-root` | Path | `.workspaces` | Where PR workspaces are made. |
| `pr-triage.generated` / `regen` / `regen-check` | Glob / Command / Command | none | What `regen` resolves, and how. |
| `pr-triage.push-wrap` | Command | none | Wrapper for pushes (e.g. a benchmark lock). |
| `pr-triage.merge` | `never` \| `when-approved` | `never` | Merge policy (above). |
| `pr-triage.drafts` | `park` \| `triage` | `park` | Whether draft PRs are triaged. |
| `pr-triage.poll-interval` | Duration | `60s` | Spacing of forge polls while waiting. |
| `pr-triage.poll-limit` | Integer | `30` | Polls before a wait records `wait-expired` and parks the run. |
| `pr-triage.lease` | Duration | `30m` | How long an ownership lease lives without renewal. |
| `pr-triage.store` | `file` \| `ledger` | `ledger` when the `ledger` tool is installed, else `file` | The record store. |
| `fsm.check.<key>` | Command | none | The command for each check and observation key, per draft-ndn-fsm-session-01. |

All keys are jj repository config, never committed. The `store` default
prefers the ledger because its records survive the workspace and travel
with the ledger's pushes; a file record also survives the workspace,
since it lives under the repository's git directory, but not a move to
another clone. Snapshots, receipts, logs, and drafts live in the
repository's fsm log directory (draft-ndn-fsm-session-01), shared by
every workspace and never pushed: a handoff to another clone carries the
ledger's history but not these files, so the receiving instance starts a
new run rather than resuming one. `PR_TRIAGE_INSTANCE` names the instance; when it
is unset, `pr-init` derives one from the agent role and a random suffix.

### Errors

| Condition | Exit | Recovery |
|---|---|---|
| No class holds for a snapshot | 2 | A bug: the classes do not partition; `parked` covers every remaining state. |
| More than one class holds for a snapshot | 2 | A bug: the class commands disagree on precedence. |
| The forge errors during a snapshot | — | The snapshot classifies `parked`, with the error in its receipt. |
| A key's command is not configured | 2 | Configure `fsm.check.<key>`; `pr-init` lists the missing ones. |
| `pr-init` finds an invalid or non-compiling process | 2 | Fix this document and re-tangle. |
| Waiting exceeds `poll-limit` | — | The session parks; a later session resumes with a new run. |

### The skill

The pr-triage skill MUST teach only: setting up (`pr-init`), the executor
verbs (query, `--attach`, `--record`, advance with `--why`, `--audit
--recheck`), and how to work inside the three judgment states. Stage
guidance lives in the machines' `note` lines, disclosed one state at a
time, and MUST NOT be restated in the skill. The skill's `SKILL.md`
SHOULD stay within 60 lines and under 500 words; the acceptance test is
not the count but recovery — an agent given only the skill and a run
interrupted mid-state finds its state, the evidence it is missing, and
its legal moves from the executor alone. [R-pr-skill]

```transcript @R-pr-skill
$ rfc-fsm-compile "$RFC_DOC" --tag @R-pr-session > process.fsm
$ printf 'SWEEP\n' > run
$ rfc-fsm-exec process.fsm --state run | grep -c "missing: swept"
1
$ rfc-tangle "$RFC_DOC" t > /dev/null
$ printf 'CLASSIFY\nFIX\n  change: abc123\n' > mid-fix
$ rfc-fsm-exec t/*.pr-machine.fsm --state mid-fix | grep -c "missing: artifacts-clean tests-untouched"
1
```

## Alternatives Considered

### Why not keep the procedure as prose in the skill?

It is the status quo, and the failures in Motivation are its record: a
rule an agent must remember is a rule it can skip under pressure.

### Why not flatten the session and PR machines into one?

PRs proceed independently; one machine would interleave their states.
The subprocess keeps each PR's run separate — which ownership, rollup,
and resumption key on — while `rfc-fsm-compile` still validates the
composed process as one machine, so the seam between them is checked.

### Why not resume a parked run instead of starting a new one?

A run's record would then span sessions, owners, and forge states it was
not classified against. A new run per entry starts from a fresh
snapshot, and the PR's earlier runs stay readable under the same key.

### Why not let the agent choose the PR's branch?

A branch chosen by the agent is the rationalization the old red-flags
list warned against. The snapshot and its classes make the forge's state
the decider.

### Why not merge whenever the guards hold?

A condition nobody thought of becomes an unattended merge. Policy
defaults to `never`; a repository opts in, and even then the merge pins
the head it checked.

### Why not decide "the diff weakens a test" with a command?

Whether a change weakens a test is a judgment about intent. A command
can tell that a test file changed; the justification is the agent's,
tied to a written intent by someone else.

## Security Considerations

The configured commands execute repository code — running a PR's tests
is the point of verifying it — and they resolve only from operator
configuration, never from a run record or committed files
(draft-ndn-fsm-session-01). Posting as the operator happens only through
`comment-post --approved`, after the operator has seen the exact text; no
state posts. Merging defaults to the operator, and an automatic merge
pins the head commit it checked. Ownership coordinates cooperating
instances and is not a lock against a hostile one. The ledger's events
propagate to every clone once pushed, so records carry PR and issue
numbers, commit IDs, keys, and hashes only; snapshots, drafts, and logs
stay in local files referenced by hash.

## References

- draft-ndn-fsm-session-01 — the executor, checks, observations, claims,
  subprocess runs, record stores; normative.
- draft-claude-xp-pairing-00 — the precedent for a guarded process with a
  derived skill and a subprocess machine.
- The pr-triage skill (`skills/pr-triage/`), its `pr-ws` and `pr-poll`
  scripts, and the critical-reading and posting-as-the-user skills its
  judgment states require.
