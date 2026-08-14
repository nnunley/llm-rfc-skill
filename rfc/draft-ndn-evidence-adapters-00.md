# draft-ndn-evidence-adapters-00: Structured Evidence Adapters

**Status:** DRAFT
**Category:** Experimental
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)
**Date:** 2026-08-14

## Abstract

Evidence blocks gain a layer of indirection on purpose: instead of literal
shell sessions, evidence is written in a structured action vocabulary, and
a small, versioned **adapter** binds that vocabulary to an execution
engine. The document then specifies intent; the adapter owns invocation
syntax, environment provisioning, and projections. Raw shell transcripts
remain available as the bootstrap adapter, no longer the preferred form.

## Motivation

The `transcript` evidence type couples three things the specification has
no business owning: an execution engine (a POSIX shell replayed line by
line), an environment (the sandbox contract exists solely to make shell
sessions portable), and incidental mechanics (provisioning `mkdir`s and
`grep -c` projections that appear in the document but assert nothing about
the requirement). In practice, half the lines of a typical transcript are
engine noise, and every engine change threatens the corpus.

The mooR project's `moot` format demonstrated the alternative and is the
direct origin of this design: session tests written as structured actions
(persona directives, evaluations, commands, output assertions) with more
than one runner behind the same files — an in-process scheduler harness
and a networked telnet harness. The markdown articulation of moot was
created precisely to have a structured representation that decouples the
execution engine from the test. The tests outlived engine decisions;
the format was the contract. Evidence in this series adopts the same
separation.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **vocabulary** — the action language of an evidence type: the statements
  a block of that type is allowed to contain, with their meanings.
- **adapter** — the deterministic executable that binds a vocabulary to an
  execution engine: it receives one tangled evidence file and exits 0
  (conforms) or 1 (violates), with diagnostics on output.
- **bootstrap adapter** — the raw shell replay (`transcript` blocks); the
  adapter of last resort when no vocabulary exists yet.

## Specification

### The adapter contract

An evidence type is a name, a vocabulary, and an adapter. The adapter
MUST be deterministic (same tangled file, same verdict), MUST exit 0 on
conformance and nonzero on violation, MUST write diagnostics naming the
first failing statement, and MUST own all environment concerns —
provisioning, isolation hygiene, teardown. Documents MUST NOT contain
engine mechanics: no provisioning commands, no output projections, no
engine-specific escapes. What a block states is intent in its vocabulary;
how intent is checked belongs to the adapter. [R-adapter-contract]

```transcript @R-adapter-contract
$ printf 'add tracker /tmp/gi-rfc/a\nadd tracker /tmp/gi-rfc/b\n! error already registered\n' > sample.gi-session
$ rfc-run --adapter-dir adapters --type gi-session sample.gi-session
? 0
```

### Adapter resolution

Runners resolve an adapter for block type `<t>` in order: the environment
override (`RFC_ADAPTER_PATH`), the series-local `rfc/adapters/<t>`, then
the tooling's built-in adapters. Resolution failure for a typed block is a
hard error, never a silent skip. [R-adapter-resolution]

```transcript @R-adapter-resolution
$ printf 'anything\n' > sample.unknowntype
$ rfc-run --type unknowntype sample.unknowntype
? 1
```

### Vocabularies are declarative and thin

A vocabulary consists of action statements and observation assertions —
no control flow, no variables, no engine syntax. This is the boundary
that keeps adapters from regrowing into fixture frameworks: the FitNesse
lesson is that programmatic fixtures become a shadow codebase, and the
moot lesson is that a small declarative statement set does not. A
vocabulary SHOULD fit on one screen; a vocabulary that needs conditionals
is two vocabularies.

Example (a `gi-session` vocabulary for a CLI issue tracker):

```
add <name> <path>        register a repository
rm <name>                unregister
list                     observe the registry
! error <substring>      assert the previous action failed, mentioning text
! line <text>            assert an output line
```

The same intent as today's shell transcript for duplicate rejection, with
the sandbox, provisioning, and projection mechanics owned by the adapter
rather than restated in every block of every document.

### The bootstrap adapter

Raw `transcript` blocks (shell replay under the hygiene sandbox) remain
defined and remain the right tool in two places: evidence about shell
tools themselves where the vocabulary IS the shell, and the first evidence
in a new domain before its vocabulary exists. Once a domain accumulates
blocks, a vocabulary SHOULD be introduced and new evidence SHOULD use it;
migrating published evidence follows the normal supersession path.

### Adapters are pinned dependencies

An adapter is executable code that the conformance verdict trusts.
Series MUST pin their non-built-in adapters by content (commit or hash)
the same way source material is pinned, and adapter changes are reviewed
as evidence changes — a verdict that can be changed by silently editing
an adapter is no verdict.

## Alternatives Considered

### Keep raw shell transcripts as the primary form

Zero adapter indirection was the original rationale. Rejected on the
field record: the sandbox contract, the physical/logical path
normalization, the exit-notation, and the projection idiom were all
machinery invented to make shell-as-evidence portable — engine coupling
paid for repeatedly inside the documents. The indirection exists either
way; the only choice is whether it lives in every block or in one adapter.

### Programmatic fixtures (FitNesse-style)

Bind table/session content to fixture classes in a host language.
Rejected: fixtures accrete domain logic and become a shadow codebase
needing its own tests — the same reason Gherkin step libraries were
rejected in the process BCP. Thin declarative vocabularies with a single
small adapter per engine hold the line.

### One universal structured format for all evidence

A single schema (steps, expectations) for every domain. Rejected:
vocabularies earn their keep by speaking the domain's own language —
moot's persona directives make no sense for a registry CLI, and vice
versa. Partiality in language applies to evidence languages too.

## Security Considerations

Adapters concentrate the trust that raw transcripts diffused: one
executable now interprets every block of its type. This is a net
improvement — one small program to review instead of arbitrary shell in
every document — but it makes the adapter the supply-chain target, hence
the pinning requirement and review-as-evidence rule above. Running a
foreign series' corpus still executes that series' adapters; the process
BCP's isolation guidance applies unchanged, and the bootstrap adapter's
hygiene sandbox remains the floor, not a security boundary.

## References

- The process BCP: draft-ndn-authoring-rfcs-00 — evidence doctrine this
  document refines ("an evidence type is a name plus a runner contract").
- mooR `moot` — the structured session-test format and its two runners;
  the markdown articulation of moot is this design's direct origin.
  https://github.com/rdaum/moor (crates/testing/moot).
- draft-ndn-multi-project-registry-02 (git-issue-tracker series) — the
  raw-shell corpus whose provisioning noise motivates migration; its
  evidence is expected to move to a `gi-session` vocabulary by revision.
- FitNesse and Gherkin fixture experience — recorded in the process BCP's
  rejected-forms decision record.

## Changelog

- 2026-08-14: draft-00 created from the design conversation: adapters
  over direct shell examples, on the moot-md rationale — structured
  representation decoupling the execution engine from the test. Evidence
  here is deliberately red until rfc-run gains adapter dispatch
  (spec-first; the transcripts above are the acceptance criteria).
