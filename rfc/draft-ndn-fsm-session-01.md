# draft-ndn-fsm-session-01: FSM Session State for RFC-Governed Skills

**Status:** DRAFT
**Corpus:** red (spec-first — the -01 requirements are the acceptance criteria for the executor change)
**Category:** Experimental
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)

## Abstract

A skill executing an RFC-specified process needs two things its context
window does not give it: durable knowledge of where it is in the process,
and protection from seeing more of the process than its current stage
permits. This document specifies session mode for the fsm executor: a
lightweight state file recording the walked path, validated as a path
witness on every read, with progressive disclosure — the executor reveals
only the current state's guidance and legal moves, never the whole
machine.

Revision -01 adds two things to -00, which it replaces: evidence that only
the executor can produce, by running a configured check and recording a
re-checkable claim, and a record-store interface with two backends — the
run-record file of -00, and the `ledger` tool where it is installed.

## Motivation

An agent mid-skill loses its place at every compaction and context reset;
re-reading the whole process document to re-derive position both wastes
tokens and invites the agent to act on stages it has not reached. The
remedy pairs the two prior fsm results: the executor already answers
"what may I do here" from the verified machine, and flows already bind to
machines as path witnesses. A session is simply a persisted path witness
that the executor extends one guarded transition at a time — the state
file is the skill's memory, the machine is its law, and disclosure is
scoped to the line where the agent stands.

Two gaps showed in use. A guard checks that an evidence key is attached,
not that what it says is true: an agent can attach `verify: pass` without
running anything, and `--audit` checks commits and anchors, not test
results. And a run record kept with the work is lost with it — a
per-PR record inside a worktree disappears when the worktree is cleaned
up, which is exactly when the run's history is wanted.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **session** — one execution of an RFC-governed process by one or more
  agents, identified by its state file.
- **state file** — a text file, one state name per line, oldest first;
  the last line is the current state and the whole file is the walked
  path.
- **progressive disclosure** — revealing only the current state's
  guidance, deadline, and legal moves; the rest of the machine stays in
  the document.
- **check key** — an evidence key the machine declares with `check <key>`;
  only the executor can attach it, by running a check.
- **check** — a command named by a check ID and resolved through
  configuration the operator controls, never through the run record.
- **claim** — the value the executor attaches for a check key: what ran,
  against which tree, and with what result, in a form `--recheck` can
  repeat.
- **record store** — where a run's path and evidence are kept: a run-record
  file, or a key in a `ledger` tool ledger.

## Specification

### Initialization

`rfc-fsm-exec <machine> --state FILE` with an absent or empty FILE MUST
initialize the session at the machine's initial state, record it, and
say so. [R-session-init]

```transcript @R-session-init
$ printf 'initial A\nA -> B\nterminal B\nnote A: gather requirements\n' > m.fsm
$ rfc-fsm-exec m.fsm --state sess | grep -c "session initialized at A"
1
$ cat sess
A
```

### Progressive disclosure

A session query MUST disclose only the current state: its guidance note,
its deadline if any, and its outgoing transitions. Notes attached to
states not reachable in one move MUST NOT appear. [R-session-disclose]

```transcript @R-session-disclose
$ printf 'initial A\nA -> B\nB -> C\nterminal C\nnote A: do the interview\nnote C: publish only when green\n' > m.fsm
$ rfc-fsm-exec m.fsm --state sess | grep -c "do the interview"
1
$ rfc-fsm-exec m.fsm --state sess | grep -c "publish only when green"
0
? 1
```

### Guarded advance

`rfc-fsm-exec <machine> --state FILE <target>` MUST refuse an illegal
transition (exit 1, file untouched) and MUST record a legal one by
appending the entered state. The pseudo-target `timeout` resolves the
current state's deadline handler and records the handler state.
[R-session-advance]

```transcript @R-session-advance
$ printf 'initial A\nA -> B\nB -> C\nterminal C\ndeadline B -> C\n' > m.fsm
$ rfc-fsm-exec m.fsm --state sess >/dev/null
$ rfc-fsm-exec m.fsm --state sess C >/dev/null 2>&1
? 1
$ cat sess
A
$ rfc-fsm-exec m.fsm --state sess B | grep -c "LEGAL"
1
$ rfc-fsm-exec m.fsm --state sess timeout | grep -c "timeout handler"
1
$ cat sess
A
B
C
```

### The state file is a path witness

On every invocation the executor MUST validate the recorded path before
trusting it: the first line MUST be the machine's initial state and every
consecutive pair MUST be a declared transition. A file failing either
check is rejected (exit 2) — a corrupted or hand-edited session cannot
silently launder an illegal history. [R-session-path]

```transcript @R-session-path
$ printf 'initial A\nA -> B\nterminal B\n' > m.fsm
$ printf 'A\nB\nA\n' > sess
$ rfc-fsm-exec m.fsm --state sess
state file records an illegal path: B -> A
? 2
```

### Run records: executing a process document as a workflow

A process-style RFC is a workflow definition; launching an execution of
it creates a **run record** — the session file grown into structured
state. Design and other point-requirement RFCs prove behavior through
their corpus; a process RFC's executions are witnessed by their runs.

The record's structure stays line-oriented and glanceable: flush-left
lines are the walked path (the witness, exactly as above); indented
`key: value` lines beneath a state attach evidence gathered there —
commits, decision summaries, artifact references — appended via
`--attach` and validated for form; `#` lines are metadata, at minimum
the machine pin (`# machine: <doc> @R-<tag> @ <sha>`). The executor
walks only the flush-left path. [R-run-record]

The record is SEMI-verifiable by construction, one band per line kind:
the path is deterministically validated against the machine on every
read; `commit:` attachments are resolvable against the repository when
one is present; summaries are for the human glance. A run record is
execution state, NOT an artifact by default — it lives with the work and
MAY be deleted, committed, or cited (a consensus row or a commit
message MAY reference a run) as the process outcome warrants; nothing in this
document requires committing it.

An RFC's LIFECYCLE TRAJECTORY is derivable as a run-record path — the
masthead `Status:` as current state, the Status-changing commits as the
walked path — and MAY be validated with the same witness machinery.
That narrow derivability is the whole claim: an earlier revision
asserted the document itself as a subset of run-record functionality,
withdrawn on adversarial review (the record models the lifecycle
envelope, not the normative content; a document's defining affordances
— immutability, markers, corpus — are outside the record's model, and a
run's defining affordances — disposability, concurrency — are denied to
documents).

```transcript @R-run-record
$ printf 'initial RESEARCH\nRESEARCH -> INTERVIEW\nINTERVIEW -> SYNTHESIS\nterminal SYNTHESIS\n' > w.fsm
$ printf '# machine: draft-a-process-00 @R-authoring @ 1234abcd\n' > run
$ rfc-fsm-exec w.fsm --state run | grep -c "session initialized at RESEARCH"
1
$ rfc-fsm-exec w.fsm --state run --attach "commit: 1234abcd"
attached to RESEARCH — commit: 1234abcd
$ rfc-fsm-exec w.fsm --state run INTERVIEW >/dev/null
$ rfc-fsm-exec w.fsm --state run --attach "note: substrate and scope settled"
attached to INTERVIEW — note: substrate and scope settled
$ cat run
# machine: draft-a-process-00 @R-authoring @ 1234abcd
RESEARCH
  commit: 1234abcd
INTERVIEW
  note: substrate and scope settled
$ rfc-fsm-exec w.fsm --state run | grep -c "state: INTERVIEW"
1
$ rfc-fsm-exec w.fsm --state run --attach "no colon here"
! rfc-fsm-exec: evidence must be 'key: value'
? 2
```

### The run record resists forgery

A run record is designed to be hard to forge WITHOUT DOING THE WORK. Three
mechanisms make its claims point at artifacts that only exist if the
work happened. Guarded transitions (the fsm `guard` statement) make the
executor REFUSE to advance until the evidence keys the guard names are attached
to the current state — advance is withheld, not warned. On every legal
advance inside a repository the executor auto-attaches
`anchor: <HEAD sha>`, lacing the run into real history. And
`--audit` MUST re-verify everything the ledger claims: the path against
the machine, every guard retroactively satisfied from the recorded
attachments, every `commit:` and `anchor:` value resolvable in the
repository, and anchors ordered by ancestry — fabricating that sequence
means fabricating git history. Branch rationale rides the same rails:
advancing with `--why "<rationale>"` records `why:` under the entered
state, so which alternative was taken is the path and why is the
ledger. [R-run-audit]

```transcript @R-run-audit
$ git init -q .
$ git commit -q --allow-empty -m seed
$ cat > plan.fsm <<'EOF'
> initial DESIGN
> DESIGN -> BUILD
> BUILD -> DONE
> terminal DONE
> guard DESIGN -> BUILD: decision
> EOF
$ rfc-fsm-exec plan.fsm --state run >/dev/null
$ rfc-fsm-exec plan.fsm --state run BUILD
GUARD: DESIGN -> BUILD requires evidence: decision — missing: decision
? 1
$ rfc-fsm-exec plan.fsm --state run --attach "decision: chose the simple path" >/dev/null
$ rfc-fsm-exec plan.fsm --state run BUILD --why "guard met" >/dev/null
$ rfc-fsm-exec plan.fsm --state run --audit
audit: ok (2 step(s), 1 anchor(s) verified)
$ cat > forged <<'EOF'
> DESIGN
> BUILD
> EOF
$ rfc-fsm-exec plan.fsm --state forged --audit
audit: guard DESIGN -> BUILD unmet in ledger — missing decision:
audit: FAIL
? 1
```

### Executor-produced evidence

A guard checks that a key is attached, not that its value is true. For
evidence whose truth is a command's exit status, the machine declares the
key a check key, and the executor attaches it only by running the check.

A machine MAY declare `check <key>` (one key per statement). The executor
MUST refuse `--attach` of a check key (exit 1, record untouched), and
attaches it only through `--record <key> <check-id>`, which resolves the
check ID, runs the check at the current tree, and attaches a claim when,
and only when, the check exits 0. A nonzero exit attaches nothing and
exits 1 with the check's exit status in the message. [R-check-keys]

```transcript @R-check-keys
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.unit "true"
$ git config --local fsm.check.broken "false"
$ cat > m.fsm <<'EOF'
> initial FIX
> FIX -> PUSH
> terminal PUSH
> check verify
> guard FIX -> PUSH: verify
> EOF
$ rfc-fsm-exec m.fsm --state run >/dev/null
$ rfc-fsm-exec m.fsm --state run --attach "verify: pass"
! rfc-fsm-exec: verify is a check key; record it with --record verify <check-id>
? 1
$ rfc-fsm-exec m.fsm --state run --record verify broken
! rfc-fsm-exec: check broken exited 1; nothing recorded
? 1
$ rfc-fsm-exec m.fsm --state run --record verify unit | grep -c "recorded verify"
1
$ rfc-fsm-exec m.fsm --state run PUSH | grep -c "LEGAL"
1
```

A claim has this form, so that one token carries everything a recheck
needs and no output of the check enters the record:

```abnf
claim    = "check:" check-id "@" tree-sha "/exit=" 1*DIGIT "/log=" 64HEXDIG
check-id = 1*(ALPHA / DIGIT / "-")
tree-sha = 40HEXDIG / 64HEXDIG
```

The log is the check's combined output, kept as a local file named by its
SHA-256; only the hash enters the record. [R-claim-form]

```transcript @R-claim-form
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.unit "true"
$ printf 'initial A\nA -> B\nterminal B\ncheck verify\n' > m.fsm
$ rfc-fsm-exec m.fsm --state run >/dev/null
$ rfc-fsm-exec m.fsm --state run --record verify unit >/dev/null
$ sed -n 's/^  verify: //p' run | rfc-abnf "$RFC_DOC" claim; echo $?
0
```

The grammar is tested against the prose's intent with witnesses, decided
by the grammar itself (draft-ndn-abnf-conformance-00):

```transcript @R-claim-form
$ a40=$(printf 'a%.0s' $(seq 40)); a39=$(printf 'a%.0s' $(seq 39)); f64=$(printf 'f%.0s' $(seq 64))
$ printf 'check:unit@%s/exit=0/log=%s\n' "$a40" "$f64" > valid
$ printf 'check:unit@%s/exit=0/log=%s\n' "$a39" "$f64" > short-tree
$ printf 'check:@%s/exit=0/log=%s\n' "$a40" "$f64" > empty-id
$ rfc-abnf "$RFC_DOC" claim < valid; echo $?
0
$ rfc-abnf "$RFC_DOC" claim < short-tree >/dev/null 2>&1; echo $?
1
$ rfc-abnf "$RFC_DOC" claim < empty-id >/dev/null 2>&1; echo $?
1
```

**Check environment.** The executor runs a check from the repository root
with `FSM_RUN` set to the record's key on the ledger store, or the
record's path on the file store, and `FSM_TREE` set to the tree under
check, so one configured check serves every run of a machine (a check
for "this PR's checks are green" reads its PR from `FSM_RUN`).
[R-check-env]

```transcript @R-check-env
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.who 'test "$FSM_RUN" = run'
$ printf 'initial A\nA -> B\nterminal B\ncheck seen\n' > m.fsm
$ rfc-fsm-exec m.fsm --state run >/dev/null
$ rfc-fsm-exec m.fsm --state run --record seen who | grep -c "recorded seen"
1
```

**Check resolution.** The executor MUST resolve a check ID through
operator configuration only (see Configuration), and MUST NOT execute a
command string found in a run record, a machine, or any file the work
under review can change. The run record names checks; it never contains
them. [R-check-resolution]

```transcript @R-check-resolution
$ git init -q . && git commit -q --allow-empty -m seed
$ printf 'initial A\nA -> B\nterminal B\ncheck verify\n' > m.fsm
$ rfc-fsm-exec m.fsm --state run >/dev/null
$ rfc-fsm-exec m.fsm --state run --record verify "rm -rf /"
! rfc-fsm-exec: unknown check 'rm -rf /' (configure fsm.check.<id>)
? 2
```

**Recheck.** `--audit --recheck` MUST, for every claim in the record,
re-run the named check against the claim's tree in a temporary worktree
and compare exit statuses; a mismatch, an unknown check ID, or an
unresolvable tree fails the audit. Without `--recheck`, the audit checks
claims for form only. [R-recheck]

```transcript @R-recheck
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.unit "test -f ok"
$ touch ok && git add ok && git commit -q -m ok
$ printf 'initial A\nA -> B\nterminal B\ncheck verify\nguard A -> B: verify\n' > m.fsm
$ rfc-fsm-exec m.fsm --state run >/dev/null
$ rfc-fsm-exec m.fsm --state run --record verify unit >/dev/null
$ rfc-fsm-exec m.fsm --state run B >/dev/null
$ rfc-fsm-exec m.fsm --state run --audit --recheck | tail -1
audit: ok (1 step(s), 1 anchor(s), 1 claim(s) rechecked)
$ git config --local fsm.check.unit "false"
$ rfc-fsm-exec m.fsm --state run --audit --recheck | tail -1
audit: FAIL
? 1
```

Forgery is made detectable, not impossible. The agent and the executor
run as the same user; a hand-edited record can contain any claim, and
`--recheck` is what exposes one that does not reproduce.

### Record stores

The executor MUST keep a run's path and evidence in exactly one record
store, chosen per invocation. `--state FILE` selects the run-record file
of -00, unchanged. `--store ledger:<slug>/<key>` selects a key in a
`ledger` tool ledger. Every requirement above holds identically on both
stores; only the encoding differs.

On the ledger store:

| Run-record operation | `ledger` tool encoding |
|---|---|
| initialize | `ledger set <key> state=<initial>` |
| legal advance | `ledger set <key> state=<target> -m "<why>" --evidence anchor:<sha>` |
| `--attach "k: v"` | `ledger set <key> attach=<k> -m "<v>"` |
| `--record` | `ledger set <key> attach=<key> --evidence <claim>` |
| read the path | the key's `state` events, oldest first, from `ledger export` |

The ledger MUST declare `state` with the machine's states as its
vocabulary, so a raw `ledger set` outside the executor cannot name a
state the machine lacks, and the executor MUST validate the path it
reads back exactly as it validates a file; every requirement of this
document holds on the ledger store as on a file. [R-ledger-store]

```transcript @R-ledger-store
$ git init -q . && git commit -q --allow-empty -m seed && ledger init >/dev/null
$ printf 'initial A\nA -> B\nterminal B\n' > m.fsm
$ rfc-fsm-exec m.fsm --store ledger:runs/r1 | grep -c "session initialized at A"
1
$ rfc-fsm-exec m.fsm --store ledger:runs/r1 B | grep -c "LEGAL"
1
$ ledger status r1 --ledger runs | grep -c "state.*B"
1
$ rfc-fsm-exec m.fsm --store ledger:runs/r1 --audit | tail -1
audit: ok (1 step(s), 1 anchor(s) verified)
```

**Open questions for review:** whether a `ledger` evidence ref accepts the
claim's `/` and `=` characters unescaped, and whether `ledger export` is
the right read for one key's history (versus `since` filtered by key).
Both are implementation facts this draft has not verified.

### Configuration

| Key | Type | Default | Description |
|---|---|---|---|
| `fsm.check.<id>` (git config, `--local`) | String | none | The command a check ID runs. No default: an unconfigured check is an unknown check. |
| `fsm.check-log-dir` (git config) | Path | `.git/fsm-logs` | Where check logs are kept, named by SHA-256. Inside `.git` so they are never committed. |
| `--store` / `--state` | Store | none | The record store; session mode takes exactly one. |

Check commands live in local git config because that is the one place the
work under review cannot change: it is not committed, and a branch cannot
carry it.

**Resolution precedence** for a check ID: (1) `git config --local
fsm.check.<id>`; (2) none — an unknown check, exit 2. There is no
fallback to a committed file or to the run record.

### Errors

| Condition | Exit | Recovery |
|---|---|---|
| `--attach` of a check key | 1 | Record it with `--record <key> <check-id>`. |
| Unknown check ID | 2 | Configure `fsm.check.<id>` in local git config. |
| Check exits nonzero | 1 | Fix the work and record again; nothing was recorded. |
| Recheck mismatch | 1 (audit FAIL) | Investigate the claim; the record is not trustworthy past it. |
| Ledger store requested, `ledger` tool absent | 2 | Use `--state FILE`. |
| Ledger path names a state outside the machine | 2 | Same as an illegal file path: the record is rejected. |

### Scope

The run record is per-execution state: it lives with the work (a
branch, a worktree, a task directory) and MAY be deleted at any time —
deleting it abandons the run, never the process. Concurrent runs of the
same machine use distinct files or distinct ledger keys. Multi-agent
handoff is the file handoff; on the ledger store it is a `ledger` handoff
note on the key, and the record survives the cleanup of the work it
describes.

## Alternatives Considered

### Position tracked in conversation context

The status quo this replaces: position evaporates at compaction, and the
whole machine must sit in context for the agent to know its moves.
Rejected — that is the failure this series exists to prevent.

### A richer state store (JSON, timestamps, actor IDs)

Attractive and premature. One state per line is glanceable, diffable,
appendable with no parser, and already a path witness. Metadata can ride
in a sibling file when a real need appears; the witness format stays
minimal.

### Enforcing state via lint on the RFC document

Lint governs documents, not executions; a session is per-run scratch. The
document's `**Status:**` line tracks the document's own lifecycle — the
two are deliberately different layers.

### Agent-attached evidence for everything

The -00 behavior. Rejected for command results: "verify: pass" is only as
true as the agent's word, and the audit cannot check it.

### A separate evidence file only scripts write

Rejected: the agent can write that file as easily as a script can. It is
a convention, not a check.

### A per-session secret and an HMAC over each attachment

Rejected: the agent runs as the same user and can read the secret. It
adds ceremony, not assurance.

### Command strings in the run record

Rejected: whoever can edit the record gains arbitrary execution the next
time anyone audits it.

### Commands from committed repository files

Rejected: the work under review could change the command that verifies
it.

### The `ledger` tool as the only store

Rejected: it ties every skill built on this executor to a tool most
users do not have. The file store remains the portable baseline.

## Security Considerations

The state file is advisory process memory, not an authorization boundary:
an agent that ignores the executor ignores the file too — enforcement
comes from the humans and CI gates the process already has. Path-witness
validation prevents accidental corruption and history laundering, not a
hostile editor with write access to the file (who could equally edit the
machine; both are code-reviewed artifacts when they matter). Session
files MUST NOT contain secrets or PII — state names only.

-01 adds command execution. The trust boundary is check resolution:
checks resolve only through local git config the operator sets, and the
record names check IDs, never commands, so a tampered record can run only
checks the operator configured. Running the work under review under a
configured check is inherent to verifying it, and is the operator's
choice of command. Forgery of claims is detectable by `--recheck`, not
prevented: the executor and the agent share a user, and this document
does not pretend otherwise. Author identity on the ledger store (`--as`)
is self-declared and carries no weight in the audit.

On the ledger store, events are permanent and propagate to every clone
once pushed. Records MUST contain only state names, check IDs, tree and
commit IDs, log hashes, and short rationale; check logs and other output
stay in local files referenced by hash.

## References

- The process BCP: draft-ndn-authoring-rfcs-00 — the fsm vocabulary,
  deadline handlers, and executor this extends.
- draft-ndn-evidence-adapters-00 — flow vocabularies with fsm binding;
  a session file is the executor-side dual of a flow's path witness.
- draft-ndn-fsm-session-00 — the revision this replaces.
- draft-ndn-abnf-conformance-00 — how the claim grammar is tested.
- The `ledger` tool (`ledger quickstart`) — durable working state in git
  phantom refs; the second record store.

