# draft-claude-xp-slop-00: Slop Signatures in Source

**Status:** DRAFT
**Category:** Experimental
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-20

## Abstract

Three textual signatures of agent-written slop, detected in real source
rather than in declared artifacts: comments that narrate change history
instead of explaining code, runs of source that are more comment than code,
and near-duplicate chunks detected structurally so that a copy with every
identifier renamed still matches. The detectors are deterministic, run over
the whole tree, and are language-agnostic by construction.

## Motivation

The entropy sweep of draft-claude-xp-entropy-00 finds what nothing wants any
more. It cannot find slop that is fully wired in — reachable, carded,
tested, serving a live target, and still bad. Three kinds of that are
characteristic enough of agent authorship to detect mechanically.

**Comments as engineering logs.** An agent that changes code frequently
records the change in a comment: *previously this used floating point*,
*updated to handle the new case as requested*, *we no longer need the
fallback*. The information is real but the location is wrong — it belongs in
version control, where it is attached to the change and to the diff that
made it. Left in source it decays immediately: the next edit invalidates it,
nobody deletes it, and after a year the comments describe a version of the
code that no longer exists. Then they are worse than nothing, because a
reader — human or agent — trusts them and is misled. A comment should
explain why the code is as it is, not narrate how it got that way.

**Comment volume standing in for clarity.** The same impulse produces
paragraphs restating what the line below does. It reads as diligence and
functions as noise, and it inflates the surface a future reader must
process to find the one comment that matters.

**Near-duplicates.** It is cheaper for an agent to write a helper than to
find the helper that already exists, understand it, and decide it fits. The
result is a repository with four functions that total a list, differing only
in the names of their variables. This is the single most reliable structural
tell of accumulated agent authorship, and it is invisible to every check
that reads names rather than shapes — which is why detection here normalises
identifiers away and compares structure.

None of the three is a judgement call, and that matters: an LLM asked to
assess its own output for slop will report cleanliness, in the same way it
reports test-first work it did not do.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **chunk** — a maximal run of non-blank lines. The unit of comparison,
  chosen because it needs no parser and survives any language.
- **log-comment** — a comment whose content is the history of the code
  rather than an explanation of it.
- **structural token stream** — a chunk with identifiers replaced by `V`,
  numbers by `N`, string contents removed, and punctuation preserved.
- **similarity** — the percentage overlap of two chunks' structural token
  3-grams, by Jaccard index.
- **verbose chunk** — one whose comment lines are at least the density
  threshold of its lines, with more than three comment lines.

## Specification

### A comment explains the code; it does not narrate the change

A comment whose content is change history MUST be reported. The detector
matches temporal and process language — what the code used to do, what was
updated or fixed, what was done as requested or per review — because that is
what distinguishes a log entry from an explanation. [R-xp-log-comment]

Version control already records history, attached to the diff that made it
and to the reasoning in the commit message. A comment repeating it is a copy
that cannot be kept correct, and the fact that it will not be updated is not
a risk but a certainty.

```slop-check @R-xp-log-comment
expect log-comment 2
---
// Receipt totals the line items.
// Previously this used floating point but now it uses decimal.
function totalReceipt(items) {
  let total = 0
  for (const item of items) {
    total = total + item.price * item.qty
  }
  return round(total)
}
```

### Comment volume is not clarity

A chunk that is at least the density threshold comment lines, with more than
three of them, MUST be reported as verbose. The threshold is deliberately
generous — the target is the paragraph restating a one-line function, not
the carefully explained tricky passage, and a genuinely subtle piece of code
that trips the check is exactly the kind that SHOULD be split so its
explanation attaches to something smaller. [R-xp-verbose]

```slop-check @R-xp-verbose
expect verbose 1
expect log-comment 3
---
// Increment the counter.
// This adds one to the counter.
// We now do this because the counter needs to go up.
// Updated to handle the new case as requested.
// The counter is a number.
function bump(c) { return c + 1 }
```

### Duplicates are compared by shape, not by name

Near-duplicate detection MUST compare structural token streams, with
identifiers normalised to a single placeholder and numbers to another, so
that a copy differing only in naming is still detected. Comparing names
would miss the entire case the check exists for: an agent writing a fresh
helper names it and its variables after the new context, and a name-sensitive
comparison scores that near zero while the two functions are the same
function. [R-xp-duplicate-structural]

```slop-check @R-xp-duplicate-structural
expect duplicate 1 9
---
function totalReceipt(items) {
  let total = 0
  for (const item of items) {
    total = total + item.price * item.qty
  }
  return round(total)
}

function totalInvoice(entries) {
  let total = 0
  for (const entry of entries) {
    total = total + entry.price * entry.qty
  }
  return round(total)
}
```

Structural comparison risks the opposite error — two unrelated pieces of
code that happen to share a shape — so a minimum chunk size applies and the
similarity threshold is high by default. Code of similar shape but different
substance MUST NOT be reported. [R-xp-duplicate-precise]

```slop-check @R-xp-duplicate-precise
expect clean
---
function parseHeader(buf) {
  const magic = buf.readUInt32(0)
  if (magic !== 0x4d5a) {
    throw new Error(badMagic)
  }
  return { magic: magic, size: buf.length }
}

function renderRow(cells, width) {
  let out = padStart(cells[0], width)
  for (let i = 1; i < cells.length; i++) {
    out = out + separator + padStart(cells[i], width)
  }
  return out
}
```

### Findings are the pair's, and the thresholds are the system's

Detected slop SHOULD be resolved in the `REFACTOR` leg of
draft-claude-xp-tdd-loop-00, where the tests are green and the change is
safe. A duplicate finding is resolved by using the existing code, not by
adjusting the threshold until the finding disappears; a system MAY set its
thresholds once, as a property of its language and style, and MUST NOT
retune them in response to a finding in flight. That is the same rule the
increment bound carries, for the same reason.

These detectors are heuristics and are stated as such: they report a
signature, not a verdict. They are placed where a person sees them rather
than behind a blocking guard, because a false positive that blocks
integration teaches a pair to disable the check — and a disabled check is
how this whole class of tooling dies.

## Formal Grammar

A slop-check fixture is assertions, a separator, then source verbatim:

```abnf
fixture     = *( assertion LF ) sep LF source
assertion   = %s"expect" 1*WSP finding
finding     = ( %s"log-comment" 1*WSP line )
            / ( %s"verbose" 1*WSP line )
            / ( %s"duplicate" 1*WSP line 1*WSP line )
            / %s"clean"
sep         = "---"
line        = 1*5DIGIT
source      = *OCTET
```

Source is taken verbatim to end of file, unescaped and unquoted, because
blank lines delimit chunks and any transformation of the fixture would
change what is being detected.

## Alternatives Considered

### An LLM judging its own output for slop

Ask the agent whether its code is sloppy. Rejected on the same grounds the
whole series rejects LLM-as-judge: it is circular for a corpus meant to
constrain agents, and the specific failure is well attested — an agent
reports clean code for the same reason it reports test-first work it did not
do.

### Language-aware parsing for duplicate detection

Use per-language ASTs for accurate clone detection. Rejected for the first
draft as disproportionate: a structural token stream over blank-line chunks
catches renamed copies with no parser and no dependency, and works on every
language in a polyglot repository at once. A project wanting AST-grade
detection SHOULD run a real clone detector; this document's contribution is
that the check exists at all and is checkable.

### Blocking integration on slop findings

Gate `INTEGRATE` the way the entropy sweep does. Rejected because these are
heuristics with real false-positive rates, and a blocking heuristic gets
disabled. The entropy sweep blocks because its findings are derived from
declarations and are true by construction; these are pattern matches over
prose and shape, and they are advisory for exactly that reason.

### Banning comments about change entirely by convention

Write it in a style guide. Rejected: it is the same class of unenforceable
virtue as "refactor mercilessly", and the series' pattern is to convert
those into checks.

## Security Considerations

The detectors read source as text, execute nothing, and follow no
references, so scanning hostile input is safe. They do not interpret the
code they scan, and a file crafted to trip a pattern produces a false
finding, not an execution.

Two hazards are worth stating. First, findings quote matched source lines,
so a detector run over a file containing secrets will print those secrets
into a report or a run record — output SHOULD be treated with the same care
as the source. Second, and more consequential: these detectors create
pressure to delete comments, and a comment explaining why a check exists
("this bound is enforced because the upstream field is attacker-controlled")
is precisely the comment worth keeping. Such a comment explains the code
rather than narrating its history and MUST NOT be reported by a correct
detector; a pair that finds itself deleting security rationale to satisfy
this document has misread it, and the rationale SHOULD move into the
requirement it implements rather than being discarded.

## Compatibility

This document adds two evidence types, `slop` (the detector, also the tool a
pair runs) and `slop-check` (fixtures asserting what it finds). It adds no
guard and changes no machine, so adopting it is optional and reversible.

Thresholds default to 70% similarity and 50% comment density, overridable
per system by flag or environment. Changing a threshold changes what is
reported and SHOULD be done once rather than per finding.

## References

- draft-claude-xp-entropy-00 — the structural sweep this complements; that
  one finds what nothing wants, this one finds what is wanted and bad.
- draft-claude-xp-tdd-loop-00 — the `REFACTOR` leg where findings are
  resolved.
- draft-claude-xp-design-00 — simple design's no-duplication rule, of which
  the duplicate detector is the mechanical shadow.
- superpowers `finding-duplicate-functions` — prior art on semantic
  duplication in agent-written codebases.
- RFC 5234 (ABNF), RFC 2119, RFC 8174 (BCP 14).

## Changelog

- 2026-08-20: DRAFT created from the author's requirement for tools that
  detect slop directly — verbose comments containing engineering logs, and
  close duplicates. Comments are held to explaining the code rather than
  narrating its history, on the grounds that history in source cannot be
  kept correct; duplicates are compared structurally with identifiers
  normalised, because the renamed copy is the case that matters. Advisory
  rather than blocking, since heuristics that block get disabled.
