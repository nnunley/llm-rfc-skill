# draft-ndn-conformance-execution-00: Executing Conformance — the Full Gate and Spot Tests

**Status:** DRAFT
**Category:** Experimental
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)
**Date:** 2026-08-14

## Abstract

How conformance is actually run: one command executes the whole gate,
and targeted spot tests exercise a single document, requirement, or
block during authoring. The two serve different moments — spot tests
give the author a seconds-long loop, the full gate gives the series its
verdict — and only the full gate has standing: spot results are
advisory, and a merge is gated by the whole corpus, never by the piece
that was just worked on.

## Motivation

Field feedback from an external reader: conformance testing was unclear
because the gate existed only as scattered tool invocations across CI
configuration, documentation prose, and session habit. A newcomer
asking "how do I test conformance?" — or "would a make target exist?" —
had no single answer. The gate needs one body that CI, make targets,
and adopters all call; authors separately need cheap targeted runs
while iterating, without those runs being mistaken for the verdict.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **the full gate** — the four-stage conformance run over an entire
  series directory: lint every document, replay published evidence
  (blocking), verify draft corpus declarations, verify digest
  invariants.
- **spot test** — a targeted conformance run during authoring: one
  document's corpus, one tangled block, or one file through one adapter.
- **standing** — what may gate a merge; spot tests have none.

## Specification

### The full gate is one command

`rfc-check <rfc-dir>` MUST run the four stages in order — lint over
every draft and published document, published evidence blocking, draft
corpus declarations (red only by declaration), digest invariants — then
print a per-document summary (lint, actual corpus state, declared state
with staleness called out, digest verdict) and exit 0 if and only if
every stage passed. Continuous integration, make targets, and adopter
documentation MUST be thin callers of this command — the gate has one
body, so local runs and CI cannot drift. [R-gate-one-body]

```transcript @R-gate-one-body
$ mkdir s
$ cat > s/draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> **Status:** DRAFT
> ## Abstract
> A minimal conforming document.
> ## Motivation
> To be checked.
> ## Terminology
> None.
> ## Specification
> It exists.
> ## Alternatives Considered
> Not existing.
> ## Security Considerations
> None beyond existing.
> ## References
> None.
> ## Changelog
> - created
> EOF
$ rfc-check s 2>&1 | grep -c "rfc-check: PASS"
1
$ mkdir s2
$ printf '# draft-a-y-00: Y\n**Status:** DRAFT\n' > s2/draft-a-y-00.md
$ rfc-check s2 2>&1 | grep -c "rfc-check: FAIL"
1
$ rfc-check s2 >/dev/null 2>&1
? 1
$ rfc-check s/draft-a-x-00.md 2>&1 | grep -c "no merge standing"
2
```

### Spot tests

While authoring, targeted runs keep the loop tight; each is a normal
tool invocation, not special machinery. One document's corpus:
`rfc-run <rfc.md>` (with `--expect` to check its declaration). One
document's static checks: `rfc-lint <rfc.md>`,
`rfc-render-llm --verify <rfc.md>`. One requirement's block: tangle the
document and run the one extracted file through its adapter —
`rfc-tangle <rfc.md> <dir>` then `rfc-run --type <t> <dir>/<file>`.
One machine, one stage: `rfc-fsm-exec`. And the gate itself takes file
arguments for one-off runs: `rfc-check <rfc.md>...` runs the same four
stages scoped to the named documents, labels its output as a spot run
with no merge standing, and a make target passes files through
(`make check FILES="rfc/x.md"`). Spot invocations MUST behave
identically to the same checks inside the full gate — the gate composes
the tools, it does not reinterpret them. [R-spot-block]

```transcript @R-spot-block
$ mkdir -p adapters
$ printf '#!/bin/sh\ngrep -q ok "$1"\n' > adapters/probe
$ chmod +x adapters/probe
$ cat > draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> **Status:** DRAFT
> Works. [R-w]
> ```probe @R-w
> ok
> ```
> Also works. [R-v]
> ```probe @R-v
> ok
> ```
> EOF
$ rfc-tangle draft-a-x-00.md out
out/draft-a-x-00.w.probe
out/draft-a-x-00.v.probe
$ rfc-run --adapter-dir adapters --type probe out/draft-a-x-00.w.probe
? 0
```

### Spot results have no standing

A spot test answers "is the piece I am holding right?"; it MUST NOT
gate a merge. The verdict is the whole corpus's — the process BCP's
anti-backsliding rule demands a showing that work on one RFC does not
regress any other's requirements, and only the full gate shows that.
The RECOMMENDED authoring rhythm: spot-test while iterating, run
`rfc-check` before offering the change, and let CI run the identical
command as the gate of record.

## Alternatives Considered

### Logic in the make target

`make check` as the implementation rather than an alias. Rejected: make
is a per-repository convention, and logic living there would fork the
gate between repositories and CI. The Makefile stays one line deep;
the command is the contract.

### Spot results counting toward the gate

Caching spot passes so CI skips re-running them. Rejected for now: the
corpus is cheap to run whole, and a cache is a second source of truth
about conformance — the exact class of drift this document exists to
remove. Revisit only if corpus scale forces it, by supersession.

### A separate CI-only entry point

CI calling the tools directly while humans use a wrapper. Rejected —
that is the status quo this document replaces, and it is how the gate
became unclear in the first place.

## Security Considerations

`rfc-check` executes the same adapter and provider code paths as its
constituent tools; it adds no new execution surface, and the standing
guidance applies unchanged — isolate foreign corpora at the deployment
layer, pin foreign tooling and adapters. The no-standing rule for spot
tests is itself a control: a merge gated on a hand-picked subset is a
merge gated on the author's optimism.

## References

- The process BCP: draft-ndn-authoring-rfcs-00 — the corpus-CI MUST and
  anti-backsliding rule this document gives an execution surface.
- draft-ndn-llm-digest-00 — the digest invariants stage.
- draft-ndn-sandbox-providers-00, draft-ndn-evidence-adapters-00 — the
  execution seams the gate composes.

## Changelog

- 2026-08-14: draft-00 created from external-reader feedback ("how do I
  test conformance — would a make target exist?"): the gate gets one
  body (rfc-check), make/CI/docs become thin callers, spot tests are
  named and specified as identical-behavior tool invocations with no
  merge standing.
