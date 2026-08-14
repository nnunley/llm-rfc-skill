# draft-ndn-llm-digest-00: Token-Aware LLM Digests of RFCs

**Status:** DRAFT
**Category:** Experimental
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)
**Date:** 2026-08-14

## Abstract

Every RFC is renderable as a token-minimal digest for LLM context: a
deterministic projection keeping only the normative surface — identity
and state, marked requirement paragraphs, keyword sentences, grammars,
machines, witness tables — with everything discursive dropped. Because a
lossy projection of normative text is dangerous exactly when it is
convenient, the projector carries a verify mode whose invariants are
checked against every document in the series on every change: the live
corpus is the projector's test suite.

## Motivation

Full RFCs are written for humans deciding; agents implementing need the
obligations, not the deliberation. Ad-hoc summarization by an LLM would
put an LLM in the verification loop — forbidden by the process BCP — so
the digest must be a deterministic tool with testable guarantees.
Golden-output tests alone are anecdotes about fixtures; the adequate test
is invariants that hold for ANY document, enforced continuously against
the real series so every new RFC becomes a new test case.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **digest** — the output of `rfc-render-llm <rfc.md>`: markdown, named
  `<name>.llm.md` when published beside a rendered page.
- **kept sections** — all sections except Abstract, Motivation,
  Alternatives Considered, References, and Changelog.
- **marker set** — the set of `[R-<slug>]` markers appearing in prose
  (outside fences) of the kept sections.

## Specification

### The projection

The digest MUST contain: the title line; the `Status`, `Category`,
`Corpus`, and supersession-relation masthead lines with bold markup
stripped; every kept-section paragraph bearing an `[R-]` marker, whole;
sentences bearing BCP 14 keywords from other kept-section paragraphs;
`abnf` and `fsm` blocks verbatim; and evidence tables. The digest MUST
NOT contain: dropped sections, the BCP 14 boilerplate, authorship and
date lines, evidence transcript blocks, or section headers with no
surviving content. [R-digest-shape]

```transcript @R-digest-shape
$ printf '# draft-a-x-00: X\n\n**Status:** DRAFT\n**Authors:** A B\n\n## Motivation\n\nProse only here.\n\n## Specification\n\nIt MUST work. [R-alpha]\n\nPlain unmarked prose.\n\n\140\140\140transcript @R-alpha\n$ true\n\140\140\140\n\n## Changelog\n\n- added [R-alpha]\n' > d.md
$ rfc-render-llm d.md | grep -c "Status: DRAFT"
1
$ rfc-render-llm d.md | grep -c "R-alpha"
1
$ rfc-render-llm d.md | grep -c "Authors"
0
? 1
$ rfc-render-llm d.md | grep -c "transcript"
0
? 1
$ rfc-render-llm d.md | grep -c "Motivation"
0
? 1
```

### Determinism

The projection MUST be deterministic: the same source yields the same
digest, byte for byte. [R-digest-determinism]

```transcript @R-digest-determinism
$ printf '# draft-a-x-00: X\n\n**Status:** DRAFT\n\n## Specification\n\nIt MUST work. [R-alpha]\n' > d.md
$ rfc-render-llm d.md > a.out
$ rfc-render-llm d.md > b.out
$ cmp a.out b.out
? 0
```

### Verified invariants

`rfc-render-llm --verify <rfc> [digest]` MUST check, exiting nonzero on
any violation (digest freshly generated when not supplied): the digest's
marker set equals the source's kept-section marker set — no requirement
lost, none invented; every kept-section sentence bearing a BCP 14
keyword survives, whitespace-normalized (extracted by the same sentence
algorithm the generator uses, so the invariant tracks the generator's
own unit of work); every kept-section evidence-table row survives
verbatim; the digest opens only `abnf`/`fsm` fences; every line inside
those fences exists verbatim in the source; and the digest does not
exceed the source in size. Success is silent. [R-digest-verify]

```transcript @R-digest-verify
$ printf '# draft-a-x-00: X\n\n**Status:** DRAFT\n\n## Specification\n\nIt MUST work. [R-alpha]\n' > d.md
$ rfc-render-llm --verify d.md
? 0
$ rfc-render-llm d.md > dig.md
$ grep -v "R-alpha" dig.md > bad.md
$ rfc-render-llm --verify d.md bad.md
digest missing marker: [R-alpha]
digest missing keyword sentence: It MUST work
? 1
$ printf '# draft-a-y-00: Y\n\n**Status:** DRAFT\n\n## Specification\n\nServers MUST obey.\n\nClients omit the header as they MAY.\n\n<!-- evidence: @R-t -->\n| case | ok |\n|---|---|\n| a | yes |\nThe table MUST hold. [R-t]\n' > e.md
$ rfc-render-llm e.md > edig.md
$ grep -c "they MAY" edig.md
1
$ grep -v "^| a" edig.md > ebad.md
$ rfc-render-llm --verify e.md ebad.md
digest missing evidence row: | a | yes |
? 1
```

### Grammar fidelity

Machines and grammars are the highest-density normative content and MUST
survive line-faithfully — the verify invariant rejects any grammar line
absent from the source. [R-digest-grammar]

```transcript @R-digest-grammar
$ printf '# draft-a-x-00: X\n\n**Status:** DRAFT\n\n## Specification\n\nThe machine MUST hold. [R-m]\n\n\140\140\140fsm @R-m\ninitial A\nA -> B\nterminal B\n\140\140\140\n' > e.md
$ rfc-render-llm e.md | grep -c "A -> B"
1
$ rfc-render-llm --verify e.md
? 0
```

### The series is the test corpus

A series publishing digests SHALL run `--verify` over every RFC and
draft in CI: every document is a standing test case for the projector,
and a projector regression fails the build before a stale digest can be
served. The digest is a companion citation — agents resolving a marker
to its full requirement text MUST consult the source document.

## Alternatives Considered

### LLM-authored summaries

Rejected outright: puts an LLM in the verification loop and makes the
summary unreproducible; the process BCP forbids both.

### Golden-file tests only

Fixtures test the fixture. Rejected as sole strategy: the marker-set and
grammar-fidelity invariants quantify over all documents, and running them
against the live series in CI means coverage grows with the series.

### Hand-maintained digests

A second normative surface that drifts. Rejected; digests are derived
artifacts, regenerated at render time, never edited.

## Security Considerations

A digest is a lossy view of normative text; the risk is an agent acting
on the digest where the omitted context mattered. Mitigations: the
marker-set invariant guarantees no obligation disappears silently; the
published digest carries the "cite the full document" caveat; and
digests are generated from source at build time, so a served digest
cannot drift from its document. Tampering with a served digest is
detectable by `--verify` against the source.

## References

- The process BCP: draft-ndn-authoring-rfcs-00 — dual verifiability and
  the LLMs-never-verify rule this design serves.
- draft-ndn-evidence-adapters-00 — the deterministic-runner doctrine the
  verify mode follows.

## Changelog

- 2026-08-14: draft-00 created with the projector and verify mode
  implemented against it; all six series documents pass `--verify`,
  establishing the live-corpus-as-test-suite practice.
- 2026-08-14: external-review fixes — verify gains the two invariants
  the review demonstrated missing (keyword-sentence survival via the
  generator's own sentence algorithm, and verbatim evidence-table-row
  survival), and the keyword matcher takes MAY at a word boundary so a
  sentence-final "MAY." is no longer dropped.
