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

Revision -01 adds to -00, which it replaces: evidence that only the
executor can record, by running the command the operator configured for
a key — checks, which can be re-run against their revision, and
observations, which cannot; subprocess runs, so a state can delegate to
another document's machine at run time; and a record-store interface
with two backends — the run-record file of -00, and the `ledger` tool
where it is installed.

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
- **check** — an evidence key declared `check <key>`: recorded only by
  the executor, by running the key's configured command against a
  committed revision; repeatable at that revision.
- **observation** — an evidence key declared `observe <key>`: recorded
  only by the executor, by running the key's configured command; a fact
  about a moment, never re-run at audit. A later visit to its state
  records a new observation.
- **claim** — what the executor records for a check or observation: the
  key, the revision or time, and the hash of the command's output.
- **child run** — the record of a subprocess state's machine, started
  when the parent enters that state.
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
its deadline if any, and its outgoing transitions, each with the guard
keys it still lacks. Notes attached to
states not reachable in one move MUST NOT appear. [R-session-disclose]

```transcript @R-session-disclose
$ printf 'initial A\nA -> B\nB -> C\nterminal C\nnote A: do the interview\nnote C: publish only when green\n' > m.fsm
$ rfc-fsm-exec m.fsm --state sess | grep -c "do the interview"
1
$ rfc-fsm-exec m.fsm --state sess | grep -c "publish only when green"
0
? 1
```

```transcript @R-session-disclose
$ printf 'initial A\nA -> B\nterminal B\nguard A -> B: swept\n' > m.fsm
$ rfc-fsm-exec m.fsm --state sess | grep -c "missing: swept"
1
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
key, and only the executor records it, by running the command configured
for that key. There are two kinds, because some results can be repeated
later and some cannot:

- `check <key>` — a **check**: a pure function of a revision (tests,
  linters, a diff inspection). It can be re-run against the same revision
  at any later time and gives the same result.
- `observe <key>` — an **observation**: a fact about the world at a
  moment (a forge's CI status, whether a workspace exists, whether a PR
  merged). It cannot be repeated later; its record is the output it saw.

The executor MUST refuse `--attach` of a check or observation key (exit
1, record untouched) and MUST record one only through `--record <key>`,
which runs the command configured for that key (see Check resolution) and
records a claim when, and only when, the command exits 0. A nonzero exit
records nothing and exits 1, naming the command's exit status. A claim
never records a nonzero exit. [R-check-keys]

```transcript @R-check-keys
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.verify "true"
$ git config --local fsm.check.broken "false"
$ cat > m.fsm <<'EOF'
> initial FIX
> FIX -> PUSH
> terminal PUSH
> check verify
> check broken
> guard FIX -> PUSH: verify
> EOF
$ git add m.fsm && git commit -q -m machine
$ rfc-fsm-exec m.fsm --state .git/run >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --attach "verify: pass"
! rfc-fsm-exec: verify is a check key; record it with --record verify
? 1
$ rfc-fsm-exec m.fsm --state .git/run --record broken
! rfc-fsm-exec: check broken exited 1; nothing recorded
? 1
$ rfc-fsm-exec m.fsm --state .git/run --record verify | grep -c "recorded verify"
1
$ rfc-fsm-exec m.fsm --state .git/run PUSH | grep -c "LEGAL"
1
```

**The revision a check runs against.** A check MUST run against a
committed revision, never an unrecorded working tree, so that what the
claim names is what ran. In a jj repository the working copy is itself a
commit: the executor snapshots it (any `jj` command does) and uses the
working-copy commit. The claim records the commit ID, and the check runs
in a temporary worktree at that commit, so the revision under check is
fixed. The worktree is not a sandbox: the command runs as the operator's
user, with that user's access to the original checkout, its
configuration, its records, and anything else the user can reach.
Confinement, where wanted, comes from a sandbox provider
(draft-ndn-sandbox-providers-00) wrapping the command. Observations run
in the repository root and name no revision. [R-check-revision]

```transcript @R-check-revision
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.verify 'test "$(git rev-parse HEAD)" = "$FSM_COMMIT"'
$ printf 'initial A\nA -> B\nterminal B\ncheck verify\n' > m.fsm
$ git add m.fsm && git commit -q -m machine
$ rfc-fsm-exec m.fsm --state .git/run >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --record verify >/dev/null
$ grep -c "verify: check:verify@$(git rev-parse HEAD)/" .git/run
1
```

**A dirty tree is outstanding work.** In a plain git repository, a
working tree with uncommitted or untracked changes almost always holds
the run's own work, left behind when the agent lost context. The
executor therefore MUST NOT record a check, or take an advance whose
guard names a check, while the tree is dirty; it MUST stop (exit 2),
list the changed and untracked files, and name the two recoveries. The
agent inspects the changes and resolves them with one of:

- `--commit-wip` — commit every change with a message naming the run
  and state; a check recorded next covers the work. The preferred
  recovery, since the work is most likely the run's own.
- `--stash` — stash every change, including untracked files, and attach
  `stash: <ref>` to the current state, so work that does not belong to
  this step stays findable.

The executor MUST NOT discard working-tree changes by any path.
[R-dirty-tree]

```transcript @R-dirty-tree
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.verify "test -f built"
$ printf 'initial A\nA -> B\nterminal B\ncheck verify\n' > m.fsm
$ git add m.fsm && git commit -q -m machine
$ rfc-fsm-exec m.fsm --state .git/run >/dev/null
$ touch built
$ rfc-fsm-exec m.fsm --state .git/run --record verify 2> err; echo $?
2
$ grep -c 'built' err
1
$ grep -c -- '--commit-wip' err
1
$ rfc-fsm-exec m.fsm --state .git/run --commit-wip > /dev/null; echo $?
0
$ git status --porcelain | grep -c .
0
$ git log -1 --format=%s | grep -c 'wip'
1
$ rfc-fsm-exec m.fsm --state .git/run --record verify | grep -c "recorded verify"
1
$ touch stray
$ rfc-fsm-exec m.fsm --state .git/run --stash > /dev/null; echo $?
0
$ grep -cE '^  stash: stash@' .git/run
1
$ test -e stray; echo $?
1
$ git stash list | grep -c .
1
```

**Checks describe the current revision.** A check claim satisfies a
guard only while it describes what is there now. A check is
*history-independent* by default: its result depends only on the tree,
so a claim is current when its commit's tree equals the current
revision's tree, and a rewrite that leaves the content unchanged
(`jj describe`, a conflict-free rebase) does not withdraw it. A machine
declares a check whose result depends on history — a diff against a
base, a commit-message check — with `check <key> history`; its claim
also records the base it ran against (`/base=<commit>`, from the
operator-configured `fsm.base.<key>` command, exposed to the check as
`FSM_BASE`), and it is current only when its commit is the current
revision and the base still resolves to the same commit. The executor
MUST refuse an advance whose guard names a check unless the latest claim
for that key in the current state visit is current. [R-check-current]

```transcript @R-check-current
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.verify "true"
$ printf 'initial FIX\nFIX -> PUSH\nterminal PUSH\ncheck verify\nguard FIX -> PUSH: verify\n' > m.fsm
$ git add m.fsm && git commit -q -m machine
$ rfc-fsm-exec m.fsm --state .git/run >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --record verify >/dev/null
$ echo edit > f && git add f && git commit -q -m edit
$ rfc-fsm-exec m.fsm --state .git/run PUSH
! rfc-fsm-exec: verify describes an earlier revision; record it again
? 1
$ rfc-fsm-exec m.fsm --state .git/run --record verify >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run PUSH | grep -c "LEGAL"
1
```

```transcript @R-check-current
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.touched 'git diff --name-only "$FSM_BASE" "$FSM_COMMIT" | grep -q test'
$ git config --local fsm.base.touched 'git rev-parse main'
$ printf 'initial A\nA -> B\nterminal B\ncheck touched history\nguard A -> B: touched\n' > m.fsm
$ git add m.fsm && git commit -q -m machine && git branch -M main && git checkout -q -b work
$ echo t > test.txt && git add test.txt && git commit -q -m test
$ rfc-fsm-exec m.fsm --state .git/run >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --record touched >/dev/null
$ grep -cE '/base=[0-9a-f]{40}/' .git/run
1
$ git checkout -q main && git commit -q --allow-empty -m moved && git checkout -q work
$ rfc-fsm-exec m.fsm --state .git/run B 2>&1 | grep -c "base"
1
```

**Querying currency.** `rfc-fsm-exec --current <key>...` MUST exit 0 when
the latest claim for every named key in the current state visit is
current, and 1 otherwise, naming the first that is not, so that a
command acting on the world (a push, a merge) checks the record itself
immediately before acting. The executor validates evidence at
transitions; it does not mediate the commands an agent runs between
them, so freshness at the moment of an action belongs to that action's
own wrapper. [R-current-query]

```transcript @R-current-query
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.verify "true"
$ printf 'initial A\nA -> B\nterminal B\ncheck verify\n' > m.fsm
$ git add m.fsm && git commit -q -m machine
$ rfc-fsm-exec m.fsm --state .git/run >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --record verify >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --current verify; echo $?
0
$ echo x > f && git add f && git commit -q -m more
$ rfc-fsm-exec m.fsm --state .git/run --current verify >/dev/null 2>&1; echo $?
1
```

**Claims.** A claim is one token, so it fits a run-record line and a
`ledger` evidence ref unchanged:

```abnf
claim       = check-claim / observation
check-claim = "check:" key "@" commit [ "/base=" commit ] "/exit=0/log=" sha256
observation = "observe:" key "@" timestamp "/exit=0/receipt=" sha256
key         = %x61-7A *( %x61-7A / DIGIT / "-" )
commit      = 40HEXDIG / 64HEXDIG
timestamp   = 8DIGIT "T" 6DIGIT "Z"
sha256      = 64HEXDIG
```

The log of a check, and the receipt of an observation, is the command's
combined output, kept as a local file named by its SHA-256; only the hash
enters the record. A recorded claim MUST match `claim` in this
document's grammar. [R-claim-form]

```transcript @R-claim-form
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.verify "true"
$ printf 'initial A\nA -> B\nterminal B\ncheck verify\n' > m.fsm
$ git add m.fsm && git commit -q -m machine
$ rfc-fsm-exec m.fsm --state .git/run >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --record verify >/dev/null
$ sed -n 's/^  verify: //p' .git/run > claims
$ rfc-abnf "$RFC_DOC" claim < claims; echo $?
0
```

The grammar is held to the prose with witnesses decided by the grammar
itself (draft-ndn-abnf-conformance-00):

```transcript @R-claim-form
$ a40=$(printf 'a%.0s' $(seq 40)); a39=$(printf 'a%.0s' $(seq 39)); f64=$(printf 'f%.0s' $(seq 64))
$ printf 'check:verify@%s/exit=0/log=%s\n' "$a40" "$f64" > valid
$ printf 'check:touched@%s/base=%s/exit=0/log=%s\n' "$a40" "$a40" "$f64" > with-base
$ printf 'check:verify@%s/exit=0/log=%s\n' "$a39" "$f64" > short-commit
$ printf 'check:verify@%s/exit=1/log=%s\n' "$a40" "$f64" > failed-run
$ printf 'observe:ci@20261003T120000Z/exit=0/receipt=%s\n' "$f64" > observation
$ rfc-abnf "$RFC_DOC" claim < valid; echo $?
0
$ rfc-abnf "$RFC_DOC" claim < with-base; echo $?
0
$ rfc-abnf "$RFC_DOC" claim < observation; echo $?
0
$ rfc-abnf "$RFC_DOC" claim < short-commit >/dev/null 2>&1; echo $?
1
$ rfc-abnf "$RFC_DOC" claim < failed-run >/dev/null 2>&1; echo $?
1
```

**Check resolution.** The command for a key MUST be resolved from
operator configuration only, by the key itself: `fsm.check.<key>` (and,
for a history check, `fsm.base.<key>`) in the repository's jj repo
config when the repository is a jj repository (so every jj workspace of
it resolves the same commands, including secondary workspaces that have
no `.git` directory), otherwise in `git config --local`. The executor
MUST NOT execute a command string found in a run record, a machine, or
any committed file. Binding the command to the key, not to an argument,
means `--record verify` cannot be satisfied by an unrelated command.
[R-check-resolution]

```transcript @R-check-resolution
$ git init -q . && git commit -q --allow-empty -m seed
$ printf 'initial A\nA -> B\nterminal B\ncheck verify\n' > m.fsm
$ git add m.fsm && git commit -q -m machine
$ rfc-fsm-exec m.fsm --state .git/run >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --record verify
! rfc-fsm-exec: no command configured for verify (set fsm.check.verify)
? 2
```

```transcript @R-check-resolution
$ jj git init -q main 2>/dev/null
$ cd main && printf 'initial A\nA -> B\nterminal B\ncheck verify\n' > m.fsm
$ jj config set --repo fsm.check.verify true && jj describe -q -m machine && jj new -q
$ jj workspace add -q ../second 2>/dev/null && cd ../second
$ test -e .git; echo $?
1
$ rfc-fsm-exec ../main/m.fsm --state ../run >/dev/null
$ rfc-fsm-exec ../main/m.fsm --state ../run --record verify | grep -c "recorded verify"
1
```

**Check environment.** The executor runs a key's command with `FSM_RUN`
set to the active run's key (ledger store) or path (file store),
`FSM_KEY` to the key, and, for a check, `FSM_COMMIT` to the revision
under check and, for a history check, `FSM_BASE` to its base, so one
configured command serves every run of a machine. [R-check-env]

```transcript @R-check-env
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.seen 'test "$FSM_KEY" = seen'
$ printf 'initial A\nA -> B\nterminal B\nobserve seen\n' > m.fsm
$ rfc-fsm-exec m.fsm --state .git/run >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --record seen | grep -c "recorded seen"
1
```

**Recheck.** `--audit` MUST verify, for every claim, that its log or
receipt file exists and hashes to the recorded value. `--audit --recheck`
MUST additionally re-run every *check* at its recorded commit (and base)
in a temporary worktree and fail the audit unless it exits 0 again;
observations are never re-run, because the world they observed has
moved on — their receipts are what the audit checks. [R-recheck]

```transcript @R-recheck
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.verify "test -f ok"
$ git config --local fsm.check.seen "echo observed"
$ touch ok && printf 'initial A\nA -> B\nterminal B\ncheck verify\nobserve seen\nguard A -> B: verify\n' > m.fsm
$ git add ok m.fsm && git commit -q -m ok
$ rfc-fsm-exec m.fsm --state .git/run >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --record verify >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --record seen >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run B >/dev/null
$ rfc-fsm-exec m.fsm --state .git/run --audit --recheck >/dev/null; echo $?
0
$ git config --local fsm.check.verify "false"
$ rfc-fsm-exec m.fsm --state .git/run --audit --recheck >/dev/null 2>&1; echo $?
1
$ git config --local fsm.check.verify "test -f ok"
$ git config --local fsm.check.seen "false"
$ rfc-fsm-exec m.fsm --state .git/run --audit --recheck >/dev/null; echo $?
0
$ receipt=$(sed -n 's|^  seen: observe:seen@[0-9TZ]*/exit=0/receipt=||p' .git/run)
$ echo tampered >> ".git/fsm-logs/$receipt"
$ rfc-fsm-exec m.fsm --state .git/run --audit >/dev/null 2>&1; echo $?
1
```

The third audit passes although the observation's command now fails:
observations are never re-run. The last fails because a receipt no
longer matches its hash.

**What this proves, and what it does not.** A claim proves that the
configured command exited 0 at the recorded revision, and `--recheck`
proves the result still reproduces there. It does not prove who ran it or
that it ran at the recorded time: the agent and the executor run as the
same user, the agent can edit the record and the local configuration
like any other file, and a reproducible fabricated claim is
indistinguishable from a real one. Nor does the executor stand between
the agent and the shell: an agent can run any command between two
transitions. What the mechanism removes is the cheap failure — an agent
attaching `verify: pass` for work it did not do, or acting on evidence
about code it has since changed — by making the honest path the only one
that does not require deliberately editing records or configuration.
Stronger assurance needs an executor and configuration the agent cannot
write, which is out of scope.

### Subprocess runs

A machine MAY delegate a state to another document's machine with
`subprocess <STATE>: <doc> @R-<tag>` and map each of the child's terminals
back with `return <STATE> <CHILD_TERMINAL> -> <TARGET>`; `rfc-fsm-compile`
validates the composed process structurally. This section defines how
the executor runs one.

Advancing into a subprocess state MUST start a **child run**: a separate
record for the child machine, keyed by the parent state's lowercased name
and the value of the parent's attachment of that name — entering `PR`
with `pr: 1015` attached starts a run under the key `pr-1015`. The
executor MUST refuse to enter a subprocess state without that
attachment, and resolves the child machine as `rfc-fsm-compile` does.

**Identity.** Child runs are numbered per key across the whole
repository, not per parent, so `pr-1015/r3` names one run no matter which
session started it. On the file store, records live at
`<log dir>/runs/<child-key>/r<n>` (the log directory of Configuration,
shared by every workspace); on the ledger store, at the key
`<child-key>/r<n>` of the parent's ledger.

**Entry is one step.** Entering a subprocess state MUST allocate the
run number, enter the parent state, and bind the child as a single
operation: the parent's new state line and its `child: <child-key>/r<n>
@ <child machine pin>` attachment are written in one write — one append
on the file store, one `ledger set` event carrying both fields on the
ledger store. Allocation MUST be exclusive: on the file store under an
exclusive lock on `<log dir>/runs/<child-key>.lock`; on the ledger store
by writing the binding and reading back the key's bindings in ledger
order, where the earliest binding of a number keeps it and a later one
re-allocates. The child's first state is written after the binding. An
executor that stops after the binding finds, on its next invocation, a
binding whose run has no record, and creates it; an executor that stops
before the binding has changed nothing. Every crash point is therefore
either nothing done or a binding to complete.

**Addressing.** The agent addresses only the parent record; the executor
routes to the **active run**, the innermost run whose parent is in a
subprocess state (recursively, for nested subprocesses). A query
discloses the active run's state. An advance whose target is a state of
the active run's machine moves the active run; one whose target is a
state of its parent's machine is a return. `--attach`, `--record`, and
`--current` act on the active run, and the `FSM_RUN` a recorded command
sees is the active run's key. `--parent` directs any of these at the
parent instead, and a target naming a state in both machines MUST be
refused (exit 2) unless qualified with `--child` or `--parent`.

**Return.** The executor MUST refuse every move out of a subprocess state
except a `return` whose child terminal the bound child run has reached;
that move ends the child run. A later entry for the same key starts a new
run; a finished run is never reopened. `--audit` of a parent MUST audit
every bound child run and fail when a binding names a run that does not
exist or a return names a terminal its child did not reach.
[R-subprocess-runs]

```transcript @R-subprocess-runs
$ git init -q . && git commit -q --allow-empty -m seed
$ git config --local fsm.check.ready "true"
$ cat > draft-a-child-00.md <<'EOF'
> # draft-a-child-00: Child
> ```fsm @R-child
> initial WORK
> WORK -> DONE
> terminal DONE
> check ready
> guard WORK -> DONE: ready
> ```
> EOF
$ cat > parent.fsm <<'EOF'
> initial START
> START -> JOB
> JOB -> END
> terminal END
> subprocess JOB: draft-a-child-00 @R-child
> return JOB DONE -> END
> EOF
$ git add draft-a-child-00.md parent.fsm && git commit -q -m machines
$ rfc-fsm-exec parent.fsm --state .git/run >/dev/null
$ rfc-fsm-exec parent.fsm --state .git/run JOB
! rfc-fsm-exec: entering subprocess JOB needs an attachment 'job: <name>'
? 1
$ rfc-fsm-exec parent.fsm --state .git/run --attach "job: 1" >/dev/null
$ rfc-fsm-exec parent.fsm --state .git/run JOB | grep -c "child run job-1/r1 started"
1
$ grep -c '^  child: job-1/r1 @' .git/run
1
$ rfc-fsm-exec parent.fsm --state .git/run | grep -c "state: WORK"
1
$ rfc-fsm-exec parent.fsm --state .git/run END
! rfc-fsm-exec: child run job-1/r1 is at WORK; JOB returns only from DONE
? 1
$ rfc-fsm-exec parent.fsm --state .git/run DONE
! rfc-fsm-exec: GUARD: WORK -> DONE requires evidence: ready — missing: ready
? 1
$ rfc-fsm-exec parent.fsm --state .git/run --record ready >/dev/null
$ grep -c 'ready: check:ready@' .git/fsm-logs/runs/job-1/r1
1
$ rfc-fsm-exec parent.fsm --state .git/run DONE | grep -c "LEGAL"
1
$ rfc-fsm-exec parent.fsm --state .git/run END | grep -c "LEGAL"
1
$ rfc-fsm-exec parent.fsm --state .git/run --audit >/dev/null; echo $?
0
$ rm .git/fsm-logs/runs/job-1/r1
$ rfc-fsm-exec parent.fsm --state .git/run --audit >/dev/null 2>&1; echo $?
1
```

Recovery from a crash between the binding and the child's first state:

```transcript @R-subprocess-runs
$ git init -q . && git commit -q --allow-empty -m seed
$ cat > draft-a-child-00.md <<'EOF'
> # draft-a-child-00: Child
> ```fsm @R-child
> initial WORK
> WORK -> DONE
> terminal DONE
> ```
> EOF
$ printf 'initial START\nSTART -> JOB\nJOB -> END\nterminal END\nsubprocess JOB: draft-a-child-00 @R-child\nreturn JOB DONE -> END\n' > parent.fsm
$ printf 'START\n  job: 2\nJOB\n  child: job-2/r1 @ draft-a-child-00\n' > .git/run
$ rfc-fsm-exec parent.fsm --state .git/run | grep -c "state: WORK"
1
$ test -f .git/fsm-logs/runs/job-2/r1; echo $?
0
```

### Record stores

The executor MUST keep a run's path and evidence in exactly one record
store, chosen per invocation: `--state FILE` selects the run-record file
of -00, unchanged; `--store ledger:<slug>/<key>` selects a key in a
`ledger` tool ledger. Every requirement of this document holds on both
stores; only the encoding differs.

The ledger used as a store MUST declare the fields `state` (vocabulary:
the machine's states, and those of every machine it runs as a
subprocess), `attach` (free text), and `pin` (free text, the machine pin
of -00); it MAY declare other fields, which the executor ignores. When
the ledger does not exist the executor MUST create it with those fields.
When it exists, the executor MUST refuse (exit 2) rather than change a
schema another process depends on, naming the fix: for a missing
*value* in the `state` vocabulary, `ledger vocab add <slug> state
<value>`; for a missing *field*, which `vocab add` cannot create, a
successor ledger, `ledger create <new-slug> --supersedes <slug>` with the
full set of fields, and `--store ledger:<new-slug>/…` from then on.
Every write targets the selected ledger explicitly. Encoding:

| Run-record operation | `ledger` tool encoding |
|---|---|
| initialize | `ledger set <key> pin=<machine pin> --ledger <slug>`, then `state=<initial>` |
| legal advance | `ledger set <key> state=<target> -m "<why>" --evidence anchor:<commit> --ledger <slug>` |
| entering a subprocess state | one `ledger set <key> state=<target> attach=child --evidence child:<child-key>/r<n>@<pin> --ledger <slug>` |
| `--attach "k: v"` | `ledger set <key> attach=<k> -m "<v>" --ledger <slug>` |
| `--record <key>` | `ledger set <key> attach=<key> --evidence <claim> --ledger <slug>` |

**Replay.** The executor reads a run back as `ledger export <slug>`,
skipping the export header line, keeping the events whose key is the
run's key, in their recorded (chronological) order. Each `state` event
extends the path; each `attach` event attaches to the most recent `state`
event before it, so a state visited twice keeps each visit's evidence
separate. The `ledger` tool stores evidence strings verbatim, so claims
need no escaping. The executor MUST validate the replayed path exactly
as it validates a file. [R-ledger-store]

```transcript @R-ledger-store
$ git init -q . && git commit -q --allow-empty -m seed && ledger init >/dev/null
$ printf 'initial A\nA -> B\nB -> A\nB -> C\nterminal C\n' > m.fsm
$ rfc-fsm-exec m.fsm --store ledger:runs/r1 | grep -c "session initialized at A"
1
$ rfc-fsm-exec m.fsm --store ledger:runs/r1 --attach "first: visit" >/dev/null
$ rfc-fsm-exec m.fsm --store ledger:runs/r1 B >/dev/null
$ rfc-fsm-exec m.fsm --store ledger:runs/r1 A >/dev/null
$ rfc-fsm-exec m.fsm --store ledger:runs/r1 --attach "second: visit" >/dev/null
$ rfc-fsm-exec m.fsm --store ledger:runs/r1 --audit >/dev/null; echo $?
0
$ rfc-fsm-exec m.fsm --store ledger:runs/r1 | grep -c "second: visit"
1
$ rfc-fsm-exec m.fsm --store ledger:runs/r1 | grep -c "first: visit"
0
? 1
```

The two refusals, a missing vocabulary value and a missing field:

```transcript @R-ledger-store
$ git init -q . && git commit -q --allow-empty -m seed && ledger init >/dev/null
$ ledger create narrow --field state=A --field attach= --field pin= -m fixture >/dev/null
$ printf 'initial A\nA -> B\nterminal B\n' > m.fsm
$ rfc-fsm-exec m.fsm --store ledger:narrow/r1 2> err; echo $?
2
$ grep -c 'ledger vocab add narrow state B' err
1
$ ledger create nofields --field state=A,B -m fixture >/dev/null
$ rfc-fsm-exec m.fsm --store ledger:nofields/r1 2> err; echo $?
2
$ grep -c -- '--supersedes nofields' err
1
```

**Anchors under jj.** -00's audit orders anchors by git ancestry. jj
rewrites commits (rebase, squash, absorb), so on a jj repository the
audit MUST instead require every anchor to resolve to a commit jj still
knows (including hidden, rewritten ones) and take the order from the
record, not from ancestry. [R-jj-anchors]

```transcript @R-jj-anchors
$ jj git init -q . 2>/dev/null; jj describe -q -m one 2>/dev/null
$ printf 'initial A\nA -> B\nterminal B\n' > m.fsm
$ rfc-fsm-exec m.fsm --state run >/dev/null
$ rfc-fsm-exec m.fsm --state run B >/dev/null
$ jj describe -q -m rewritten 2>/dev/null
$ rfc-fsm-exec m.fsm --state run --audit >/dev/null; echo $?
0
```

### Configuration

| Key | Type | Default | Description |
|---|---|---|---|
| `fsm.check.<key>` | Command | none | The command a check or observation key runs. jj repo config in a jj repository, otherwise `git config --local`. No default: an unconfigured key cannot be recorded. |
| `fsm.base.<key>` | Command | none | For a `history` check, the command that prints the base commit it runs against. Required for history checks. |
| `fsm.log-dir` | Path | `<git common dir>/fsm-logs` | Where logs, receipts, and file-store child runs are kept. Resolved from the backing git repository: `jj git root` in a jj repository (which works from a secondary workspace with no `.git`), otherwise `git rev-parse --git-common-dir` (which works when `.git` is a file). Never committed. |
| `--state` / `--store` | Store | none | The record store; session mode takes exactly one. |

**Resolution precedence** for a key's command: (1) jj repo config
`fsm.check.<key>`, in a jj repository; (2) `git config --local
fsm.check.<key>`, otherwise; (3) none — exit 2. There is no fallback to a
committed file or to the run record.

**Options.**

| Option | Effect |
|---|---|
| `--record <key>` | Run the key's configured command and record a claim. |
| `--current <key>...` | Exit 0 when every named key's latest claim is current. |
| `--commit-wip` / `--stash` | Resolve a dirty plain-git tree (see "A dirty tree is outstanding work"). |
| `--child` / `--parent` | Direct a query, advance, attachment, or record at the active child run or its parent. |
| `--audit [--recheck]` | Verify the record; with `--recheck`, re-run every check. |

### Errors

| Condition | Exit | Recovery |
|---|---|---|
| `--attach` of a check or observation key | 1 | Record it with `--record <key>`. |
| `--record` of a key declared neither `check` nor `observe` | 2 | Declare it in the machine, or `--attach` it as judgment. |
| A guard's check is not current | 1 | Record the check again at the current revision (and base). |
| Dirty plain-git tree at a check or check-guarded advance | 2 | Inspect, then `--commit-wip` or `--stash`. |
| A target names a state in both parent and child | 2 | Qualify it with `--child` or `--parent`. |
| Ledger lacks a `state` value the machine declares | 2 | `ledger vocab add <slug> state <value>`. |
| Ledger lacks a field the store needs | 2 | Create a successor with `ledger create <new> --supersedes <slug>`. |
| No command configured for a key (or base, for a history check) | 2 | Set `fsm.check.<key>` / `fsm.base.<key>`. |
| Command exits nonzero | 1 | Fix the work and record again; nothing was recorded. |
| Log or receipt missing or not matching its hash | 1 (audit FAIL) | The claim's evidence is gone or altered; the record is not trustworthy past it. |
| Recheck exits nonzero | 1 (audit FAIL) | The claim no longer reproduces at its commit. |
| Entering a subprocess state without its attachment | 1 | Attach `<state>: <name>` first. |
| Leaving a subprocess state other than by a reached return | 1 | Walk the child run to a mapped terminal. |
| Ledger store requested, `ledger` tool absent | 2 | Use `--state FILE`. |
| Replayed path names a state outside the machine | 2 | As an illegal file path: the record is rejected. |

### Scope

The run record is per-execution state: it lives with the work (a
branch, a worktree, a task directory) and MAY be deleted at any time —
deleting it abandons the run, never the process. Concurrent runs of the
same machine use distinct files or distinct ledger keys; child runs are
numbered across the repository, so concurrent sessions never share one.
Multi-agent handoff is the file handoff; on the ledger store it is a
`ledger` handoff note on the key, and the record survives the cleanup of
the work it describes.

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

### Re-running observations at audit time

Rejected: an observation is a fact about a moment — a PR's checks were
red, a workspace existed. Re-running it later answers a different
question, and some observations' commands have effects. Its receipt is
what the audit can check.

### Checks against the uncommitted working tree

Rejected: a claim would name a revision that does not contain what ran,
and later edits would silently change what the evidence means. In jj the
working copy is already a commit; in plain git a dirty tree is treated
as the run's own outstanding work and committed or stashed, never
discarded.

### Refusing a dirty tree and leaving it to the agent

Rejected: a dirty tree is almost always work the agent itself started
and lost track of across a context reset. A bare refusal invites the
cheapest way past it — discarding the changes — which loses that work.
Naming the two preserving recoveries makes keeping the work the easy
path.

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
commands resolve only from operator configuration, by key, and the record
never names a command, so a tampered record can run only commands the
operator configured. That configuration is local and writable by the
same user as the agent; it keeps commands out of reach of the work under
review (a branch cannot carry it), not out of reach of the agent. The temporary
worktree a check runs in fixes the revision; it does not confine the
command. Running the work under review under a
configured check is inherent to verifying it, and is the operator's
choice of command. `--recheck` makes a fabricated check claim fail unless it
reproduces; it cannot detect a fabricated claim that does reproduce, nor
any fabricated observation, and this document does not pretend
otherwise. Author identity on the ledger store (`--as`)
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

