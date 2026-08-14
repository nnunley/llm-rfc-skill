# draft-ndn-fsm-session-00: FSM Session State for RFC-Governed Skills

**Status:** DRAFT
**Category:** Experimental
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)
**Date:** 2026-08-14

## Abstract

A skill executing an RFC-specified process needs two things its context
window does not give it: durable knowledge of where it is in the process,
and protection from seeing more of the process than its current stage
permits. This document specifies session mode for the fsm executor: a
lightweight state file recording the walked path, validated as a path
witness on every read, with progressive disclosure — the executor reveals
only the current state's guidance and legal moves, never the whole
machine.

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

### Scope

The state file is per-execution scratch, not specification: it lives with
the work (a branch, a worktree, a task directory), is not committed to
the series, and MAY be deleted at any time — deleting it abandons the
session, never the process. Concurrent sessions of the same machine use
distinct files. Multi-agent handoff is the file handoff.

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

## Security Considerations

The state file is advisory process memory, not an authorization boundary:
an agent that ignores the executor ignores the file too — enforcement
comes from the humans and CI gates the process already has. Path-witness
validation prevents accidental corruption and history laundering, not a
hostile editor with write access to the file (who could equally edit the
machine; both are code-reviewed artifacts when they matter). Session
files MUST NOT contain secrets or PII — state names only.

## References

- The process BCP: draft-ndn-authoring-rfcs-00 — the fsm vocabulary,
  deadline handlers, and executor this extends.
- draft-ndn-evidence-adapters-00 — flow vocabularies with fsm binding;
  a session file is the executor-side dual of a flow's path witness.

## Changelog

- 2026-08-14: draft-00 created: session mode implemented in rfc-fsm-exec
  (--state FILE), state file as validated path witness, progressive
  disclosure of the current stage only, timeout advance via the deadline
  handler.
- 2026-08-14: the fsm vocabulary now reserves the state name `timeout`
  (process BCP), closing the shadowing the session executor's
  pseudo-target introduced: a machine can no longer declare a state the
  executor cannot reach.
