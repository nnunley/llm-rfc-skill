# draft-claude-xp-entropy-00: The Entropy Sweep

**Status:** DRAFT
**Category:** Experimental
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-20

## Abstract

Every other guard in this series constrains what enters a codebase; none
forces anything out, and a project obeying all of them can still grow
without bound. This document adds the missing direction: a sweep over the
whole system, every session, reporting code unreachable from any entry
point, code the design has no card for, cards no code implements, code no
test covers, tests that assert nothing, and code whose originating story
serves a target the customer has retired. Findings block integration until
dispositioned, and a finding may be excepted only with a **dated** expiry —
so that suppression cannot quietly become the new accumulator.

## Motivation

Old projects drift to slop, and continuous development by agents accelerates
it for a specific reason: an agent asked to change something adds. Adding is
the locally correct move almost every time — it is smaller, safer, and
easier to justify than deleting code whose purpose is unclear. Across two
hundred sessions the local optimum is accretion, and nothing in a
per-session review notices, because every individual session looks fine.
Entropy is invisible per-change and only visible in aggregate.

The second mechanism is worse: **code becomes its own justification.** An
agent opens a session, reads the codebase to work out what to do, and
everything present looks intentional. It will faithfully extend a dead
abstraction, write a test for a function nobody calls, and preserve a
special case whose reason expired a year ago — because from inside the
repository there is no way to distinguish live code from residue. Intent
has to live somewhere the code cannot overwrite, and code has to justify
itself against it, rather than the reverse.

This series already applies exactly that rule at three layers: a requirement
must have evidence, a card must be reachable from a root, and a story must
serve a live target. Each is the same property — everything must be
reachable from something currently wanted — and each is mechanically
checked. The layer where it was missing is the one that actually grows.
Slop is the unreachable stuff nobody deletes.

The sweep runs over the whole system rather than over changed files, for
the same reason the conformance corpus does: a check scoped to the diff can
only find what this session broke, and entropy is what every session left
behind.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **inventory** — the declared description of the code: units, entry points,
  call edges, the cards units implement, test coverage, assertion counts,
  and each unit's originating story. It is the seam; a project produces it
  however its language allows.
- **unit** — one element of code at the project's chosen grain: a module, a
  file, a function. The sweep does not care which, only that it is
  consistent.
- **entry** — a unit reached from outside: a process entry point, a public
  API surface, a plugin hook. Reachability is measured from entries.
- **orphan** — a non-test unit unreachable from any entry.
- **uncarded** — a unit implementing no card: code the design has no record
  of.
- **unrealized** — a card no unit implements: design the code never grew.
- **hollow test** — a test asserting nothing, or one whose assertion count
  is undeclared and therefore unprovable.
- **expired unit** — one whose originating story serves a retired target:
  code whose reason is gone, traceable rather than guessed.
- **disposition** — what closes a finding: deleting the code, or an
  exception.
- **exception** — a dated, reasoned suppression of one finding. Exceptions
  expire; they are never open-ended.

## Specification

### Everything must be reachable from something wanted

The sweep MUST report, over the whole system, every orphan, uncarded unit,
unrealized card, untested unit, hollow test, and expired unit. It MUST NOT
limit itself to units touched by the current change: the findings it exists
to surface were left by earlier sessions, and a diff-scoped sweep would
report none of them. [R-xp-sweep-whole]

```sweep @R-xp-sweep-whole
today 2026-08-20
target T-CASH accept cash payments
retired T-LOYALTY
story RCP-1 priority 1
story LOY-1 priority 3
serves RCP-1 T-CASH
serves LOY-1 T-LOYALTY
card Receipt
card LineItem
card Refund
entry Checkout
unit Receipt
unit LineItem
unit PointsLedger
unit LegacyRounder
calls Checkout Receipt
calls Receipt LineItem
implements Checkout Receipt
implements Receipt Receipt
implements LineItem LineItem
implements PointsLedger Receipt
covers TestCheckout Checkout
covers TestReceipt Receipt
covers TestLineItem LineItem
asserts TestCheckout 3
asserts TestReceipt 0
asserts TestLineItem 2
origin PointsLedger LOY-1
orphan PointsLedger
orphan LegacyRounder
uncarded LegacyRounder
unrealized Refund
untested PointsLedger
hollow TestReceipt
expired PointsLedger
```

### Expired code is traceable, not guessed

A unit's `origin` names the story that produced it, and a story serves a
target. When that target is retired, the unit MUST be reported as expired.
This is the sweep's strongest claim, because it does not rest on judgement
about whether code "looks used": it states that the reason this code was
written was withdrawn on a date, by the person who withdrew it. Deletion
arguments elsewhere are guesses; this one is a citation. The chain is
already recorded — the run record anchors each commit to its story, and
draft-claude-xp-backlog-00 binds stories to targets — so the sweep reads
provenance rather than inventing it. [R-xp-expired-traceable]

An expired unit MUST NOT be deleted by the sweep itself. Like a drifted
story, it is held for a decision: the code may belong to a new target.

Here the unit is reachable, carded, and tested — nothing about the code
looks wrong. The only finding is that its reason was withdrawn.

```sweep @R-xp-expired-traceable
today 2026-08-20
target T-CASH accept cash payments
retired T-LOYALTY
story LOY-1 priority 3
serves LOY-1 T-LOYALTY
card Loyalty
entry PointsLedger
unit PointsLedger
implements PointsLedger Loyalty
covers TestPoints PointsLedger
asserts TestPoints 4
origin PointsLedger LOY-1
expired PointsLedger
```

### Findings block integration

The sweep's result MUST be attached at `INTEGRATE`, and a sweep with
undispositioned findings MUST refuse the advance. Reporting alone was
considered and rejected: a report nobody must act on is a report nobody acts
on, and slop accumulates at exactly the rate at which findings are ignored.
Blocking makes the accumulation impossible rather than visible.
[R-xp-sweep-blocks]

```xp-run @R-xp-sweep-blocks
machine initial INTEGRATE
machine INTEGRATE -> SESSION_END
machine terminal SESSION_END
machine guard INTEGRATE -> SESSION_END: suite commit diffstat sweep
refuse SESSION_END missing suite commit diffstat sweep
suite 41 passed, 0 failed, gate green
diffstat 2 files 74 lines
attach sweep: clean — LegacyRounder deleted, PointsLedger excepted until 2026-09-30
work implement RCP-1 and delete the orphan it replaced
advance SESSION_END why: nothing unaccounted for
at SESSION_END
audit ok
```

### Exceptions expire, because suppression is where ratchets die

An exception MUST name a finding, MUST carry an expiry date, and MUST give a
reason. A sweep MUST fail when an exception is past its expiry, and the
remedy MUST be a fresh decision rather than a renewed date by habit. An
exception naming no current finding MUST also be reported: a suppression
outliving its finding is itself accumulation, of exactly the kind this
document exists to prevent. [R-xp-exception-ages]

Without this rule the sweep would work once. Every long-lived quality gate
that lacks it ends the same way — the findings move into the suppression
file, the file grows monotonically, and the check reports green over a
codebase nobody has cleaned in years. An undated exception is a deletion of
the rule, written as configuration.

```sweep @R-xp-exception-ages
today 2026-08-20
entry Checkout
unit Checkout
unit PointsLedger
card Checkout
implements Checkout Checkout
implements PointsLedger Checkout
covers TestCheckout Checkout
asserts TestCheckout 2
except orphan PointsLedger until 2026-01-01 because kept for the loyalty pilot
blocked expired on 2026-01-01
```

### Deletion is the default disposition

When a finding has no live exception, the disposition SHOULD be deletion.
The sweep names things nothing wants: unreachable code, code the design does
not describe, tests that assert nothing, code whose purpose was withdrawn.
Keeping such a thing requires an argument, and the exception is where the
argument goes — dated, so that the argument is made again rather than
inherited. A pair that finds itself excepting the same finding repeatedly
SHOULD conclude that the inventory is wrong, not that the rule is.

## Formal Grammar

```abnf
inventory   = *( statement LF )
statement   = entry-s / unit-s / calls-s / impl-s / card-s / covers-s
            / asserts-s / origin-s / except-s
entry-s     = %s"entry" 1*WSP name
unit-s      = %s"unit" 1*WSP name
calls-s     = %s"calls" 1*WSP name 1*WSP name
impl-s      = %s"implements" 1*WSP name 1*WSP name
card-s      = %s"card" 1*WSP name
covers-s    = %s"covers" 1*WSP name 1*WSP name
asserts-s   = %s"asserts" 1*WSP name 1*WSP 1*4DIGIT
origin-s    = %s"origin" 1*WSP name 1*WSP name
except-s    = %s"except" 1*WSP kind 1*WSP name 1*WSP %s"until" 1*WSP date
              1*WSP %s"because" 1*WSP text
kind        = %s"orphan" / %s"uncarded" / %s"unrealized" / %s"untested"
            / %s"hollow" / %s"expired"
date        = 4DIGIT "-" 2DIGIT "-" 2DIGIT
name        = ALPHA *( ALPHA / DIGIT / "_" / "-" )
text        = VCHAR *( WSP / VCHAR )
```

Target, story, `serves`, `retired`, and `today` statements are shared with
draft-claude-xp-backlog-00 and carry the same meaning here.

## Alternatives Considered

### Computing reachability from source directly

Parse the code and build a real call graph instead of reading a declared
inventory. Rejected as the specification's job: it would bind this document
to one language's toolchain, and the adapter doctrine puts engine concerns
behind a seam. A project that can generate its inventory from a real call
graph SHOULD do exactly that — the inventory is the interface, and a
higher-fidelity producer is strictly better.

### Reporting without blocking

Produce the sweep and let the pair judge. Rejected on the evidence of every
warning-only quality gate ever shipped: findings accumulate at the rate they
are ignored, and an agent under instruction to finish a story will ignore
them completely.

### Deleting orphans automatically

Let the sweep remove what nothing references. Rejected: reachability is
computed from a declared inventory that can be wrong or incomplete, and an
automatic delete on a wrong inventory destroys working code. Holding costs a
decision; deleting costs a recovery.

### Undated exceptions with periodic review

The conventional arrangement — a suppression file plus an intention to
revisit. Rejected because the intention is never kept, and the file becomes
the place slop lives. A date makes the review happen or makes the sweep
fail, and either outcome is better than the file.

### Age-based deletion of code

Delete code untouched for N months. Rejected for the reason age-based
escalation was rejected in draft-claude-xp-backlog-00: age is not value.
Stable code is often the best code in a repository, and its stability is
evidence of correctness rather than of abandonment.

## Security Considerations

The sweep reads a declared inventory and does graph reachability; it
executes no code and follows no paths out of the file.

Its security-relevant hazard is the same one it exists to manage, pointed
the other way. The sweep is a mechanism for justifying deletion, and a wrong
inventory makes a live unit look orphaned — an authorization check invoked
only through a framework hook, reflection, or a plugin registry has no
`calls` edge and will be reported as unreachable every session. Deleting it
removes a control while every test still passes, because the tests exercise
the paths the inventory knows about. This is why the sweep MUST NOT delete
anything itself, why entries include plugin hooks and API surfaces, and why
a security-relevant orphan MUST be investigated rather than dispositioned by
deletion on the strength of the report.

The exception mechanism is the other exposure: an exception is a
pair-authored suppression of a finding, so a long-dated exception over a
security-relevant unit hides it for the life of the date. Dates SHOULD be
short enough that the argument is re-made while the reason is still known,
and an exception over a unit implementing authentication, authorization,
input validation, or secret handling SHOULD carry the shortest date the pair
can work with.

Finally, `expired` findings deserve care in the opposite direction: code
tracing to a retired target may still be the only implementation of a
control that a live target silently depends on. Retiring a target does not
retire the obligation, and the held disposition exists so that a person
decides which it was.

## Compatibility

This document adds one evidence type, `sweep`, and one evidence key,
`sweep:`, to draft-claude-xp-pairing-00's `INTEGRATE` guard. Projects that
produce no inventory cannot sweep and therefore cannot integrate under this
document, which is deliberate but abrupt: adopting it means writing an
inventory producer first, as its own story.

The inventory format is new. Projects with existing call-graph or coverage
tooling SHOULD generate the inventory from it rather than maintain it by
hand; a hand-maintained inventory drifts from the code, which would make the
sweep report fiction.

## References

- draft-claude-xp-pairing-00 — the session machine whose `INTEGRATE` guard
  the sweep blocks, and the corpus rule this document mirrors at the code
  layer.
- draft-claude-xp-backlog-00 — targets, retirement, and the story→target
  binding the `expired` finding reads.
- draft-claude-xp-design-00 — the cards `implements` names, and the
  reachability rule this document generalises.
- draft-claude-xp-slop-00 — the textual signatures that complement this
  structural sweep.
- draft-ndn-authoring-rfcs-00 — the conformance corpus, the whole-system
  check this document imitates.
- RFC 5234 (ABNF), RFC 2119, RFC 8174 (BCP 14).

## Changelog

- 2026-08-20: DRAFT created from the author's goal of groundwork for
  continuous development with LLM agents that resists older projects
  drifting to slop. Supplies the direction the rest of the series lacked:
  every prior guard constrains intake, and this one forces egress. Applies
  the series' reachability rule at the code layer, reads provenance through
  the commit→story→target chain already recorded in the run record, blocks
  integration on undispositioned findings, and requires every exception to
  carry an expiry date so suppression cannot become the new accumulator.
