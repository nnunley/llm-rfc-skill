# draft-claude-xp-drift-00: Resisting Drift at the Gate

**Status:** DRAFT
**Category:** Experimental
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-21

## Abstract

Every other guard in this series constrains what enters a codebase; none
forces anything out, and a project obeying all of them can still grow
without bound. This document supplies the missing direction at three
surfaces where decay shows: **structure** — code unreachable from any entry,
code the design has no card for, tests that assert nothing, and code whose
originating story serves a retired target; **supply** — packages imported but
never declared, or declared but never resolved, which is what a fabricated
name does; and **text** — comments narrating change history, comment volume
standing in for clarity, and near-duplicates compared structurally so a copy
with every identifier renamed still matches. The first two block integration
until dispositioned. The third is advisory, because it is heuristic, and a
heuristic that blocks gets disabled.

## Motivation

Old projects drift, and continuous development by agents accelerates it for
a specific reason: an agent asked to change something adds. Adding is the
locally correct move nearly every time — smaller, safer, easier to justify
than deleting code whose purpose is unclear. Across two hundred sessions the
local optimum is accretion, and no per-session review notices, because every
individual session looks fine. Decay is invisible per-change and only
visible in aggregate.

The second mechanism is worse: **code becomes its own justification.** An
agent opens a session, reads the codebase to work out what to do, and
everything present looks intentional. It will faithfully extend a dead
abstraction, test a function nobody calls, and preserve a special case whose
reason expired a year ago, because from inside the repository there is no
way to distinguish live code from residue. Intent has to live somewhere the
code cannot overwrite, and code has to justify itself against it rather than
the reverse.

This series already applies that rule at three layers: a requirement must
have evidence, a card must be reachable from a root, and a story must serve a
live target. Each is the same property — everything must be reachable from
something currently wanted — mechanically checked. The layer where it was
missing is the one that actually grows.

Dependencies are the sharpest case, because there accretion is directly
exploitable. Code-generating models recommend packages that do not exist —
19.7% across sixteen models in the USENIX Security 2025 study, more than
205,000 unique fabricated names — and attackers pre-register those names, so
a hallucinated dependency resolves to code an adversary controls.

The textual signatures are a different kind of finding. The structural and
supply checks derive from declarations and are true by construction; the
textual ones are pattern matches over prose and shape, with real
false-positive rates. Both belong here — they resist the same decay — but
they cannot carry the same enforcement, and pretending otherwise is how the
whole category of tooling gets switched off.

All of it runs over the whole system rather than the changed files, for the
same reason the conformance corpus does: a check scoped to the diff finds
only what this session broke, and drift is what every session left behind.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **inventory** — the declared description of the code: units, entry points,
  call edges, the cards units implement, test coverage, assertion counts,
  and each unit's originating story. A seam; a project produces it however
  its language allows.
- **unit** — one element of code at the project's chosen grain.
- **entry** — a unit reached from outside: a process entry point, a public
  API surface, a plugin hook.
- **orphan** — a non-test unit unreachable from any entry.
- **uncarded** — a unit implementing no card.
- **unrealized** — a card no unit implements.
- **hollow test** — a test asserting nothing, or whose assertion count is
  undeclared and therefore unprovable.
- **expired** — a unit or dependency whose originating story serves a
  retired target.
- **exception** — a dated, reasoned suppression of one finding. Exceptions
  expire; they are never open-ended.
- **undeclared** / **unresolved** / **unused** / **unattributed** — a
  dependency imported but in no manifest; declared but in no lockfile;
  declared but imported by nothing; declared with no originating story.
- **chunk** — a maximal run of non-blank lines; the unit of textual
  comparison, chosen because it needs no parser.
- **log-comment** — a comment whose content is the history of the code
  rather than an explanation of it.
- **structural token stream** — a chunk with identifiers replaced by `V`,
  numbers by `N`, string contents removed, punctuation preserved.

## Specification

### Reachable from something wanted, or reported

The sweep MUST report, over the whole system, every orphan, uncarded unit,
unrealized card, untested unit, hollow test, and expired unit. It MUST NOT
limit itself to units touched by the current change: the findings it exists
to surface were left by earlier sessions, and a diff-scoped sweep reports
none of them. [R-xp-sweep-whole]

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
This is the strongest claim here, because it does not rest on judgement
about whether code "looks used": it states that the reason this code was
written was withdrawn on a date, by the person who withdrew it. Deletion
arguments elsewhere are guesses; this one is a citation. An expired unit
MUST NOT be deleted by the sweep — like a drifted story it is held, because
the code might belong to a new target. [R-xp-expired-traceable]

Below, the unit is reachable, carded, and tested. Nothing about the code
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

The structural and supply results MUST be attached at `INTEGRATE` as
`drift:`, and undispositioned findings MUST refuse the advance. Reporting
alone was considered and rejected: a report nobody is obliged to act on is a report
nobody acts on, and decay accumulates at exactly the rate findings are
ignored. Blocking makes the accumulation impossible rather than visible.
[R-xp-sweep-blocks]

```xp-run @R-xp-sweep-blocks
machine initial INTEGRATE
machine INTEGRATE -> SESSION_END
machine terminal SESSION_END
machine guard INTEGRATE -> SESSION_END: suite commit diffstat drift
refuse SESSION_END missing suite commit diffstat drift
suite 41 passed, 0 failed, gate green
diffstat 2 files 74 lines
attach drift: clean — LegacyRounder deleted, PointsLedger excepted until 2026-09-30
work implement RCP-1 and delete the orphan it replaced
advance SESSION_END why: nothing unaccounted for
at SESSION_END
audit ok
```

### Exceptions expire, because suppression is where ratchets die

An exception MUST name a finding, carry an expiry date, and give a reason. A
sweep MUST fail when an exception is past its expiry, and the remedy MUST be
a fresh decision rather than a renewed date by habit. An exception naming no
current finding MUST also be reported: a suppression outliving its finding
is itself accumulation. [R-xp-exception-ages]

Without this rule the sweep works once. Every long-lived quality gate
lacking it ends the same way — findings move into the suppression file, the
file grows monotonically, and the check reports green over a codebase nobody
has cleaned in years. An undated exception is a deletion of the rule,
written as configuration.

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

### Imports are declared

A package imported by code MUST appear in a manifest, unless declared
standard library or vendored. An undeclared import is the signature of a
fabricated name: the agent wrote the import from its own expectation of what
exists, and no resolver ever confirmed it. [R-deps-declared]

```deps @R-deps-declared
stdlib json
manifest requests 2.31.0
locked requests 2.31.0
imports Checkout json
imports Checkout requests
imports Checkout fastapi-utils-toolkit
origin requests RCP-1
undeclared fastapi-utils-toolkit
```

### Declarations resolve

A package present in a manifest MUST resolve in a lockfile. A name that does
not exist cannot be locked, so an unresolved declaration is a fabricated
name that reached the manifest — the state immediately before an attacker's
registration turns it into a live supply-chain compromise. [R-deps-resolved]

```deps @R-deps-resolved
manifest requests 2.31.0
manifest rich-console-helper 0.1.0
locked requests 2.31.0
imports Checkout requests
imports Checkout rich-console-helper
origin requests RCP-1
origin rich-console-helper RCP-1
unresolved rich-console-helper
```

A fabricated package usually trips more than one finding at once — declared
but unresolved, imported by nothing, attributable to no story — and that
redundancy is the point: the checks are cheap and independent, so a name has
to survive all of them to pass unnoticed.

### Dependencies are attributable

Every declared dependency MUST name the story that introduced it, and one
whose story serves a retired target MUST be reported as expired. A
dependency is the most consequential thing an agent can add — code the
project did not write, executing with the project's privileges — and
currently the easiest thing to add without anyone deciding to. Provenance
makes adding one a recorded decision rather than a side effect.
[R-deps-attributed]

```deps @R-deps-attributed
target T-CASH accept cash payments
retired T-LOYALTY
story RCP-1 priority 1
story LOY-1 priority 3
serves RCP-1 T-CASH
serves LOY-1 T-LOYALTY
manifest requests 2.31.0
manifest points-sdk 3.0.0
manifest leftpad 1.0.0
locked requests 2.31.0
locked points-sdk 3.0.0
locked leftpad 1.0.0
imports Checkout requests
imports Points points-sdk
origin requests RCP-1
origin points-sdk LOY-1
unattributed leftpad
unused leftpad
expired points-sdk
```

### Registry existence is checked, but not here

Confirming that a package exists in a real registry — and when it was first
published, the slopsquatting signature offline checks cannot see — requires
the network. Such a check MUST run in CI against the real registry and MUST
NOT be represented as corpus evidence. A transcript simulating a registry
response proves only that the simulation was written to agree with the
assertion; it is manufactured proof, and more dangerous than no check at all
because it reports green.

This requirement carries no `[R-]` marker deliberately: it prohibits a
category of evidence rather than describing a behaviour a block can
demonstrate, and marking it would invite the fabricated block it forbids.

A CI check SHOULD additionally flag a package whose first publication
postdates the code importing it, since a name invented by a model and
registered by an attacker is necessarily younger than the suggestion that
named it.

### A comment explains the code; it does not narrate the change

A comment whose content is change history MUST be reported. Version control
already records history, attached to the diff that made it; a comment
repeating it is a copy that cannot be kept correct, and the fact that it
will not be updated is not a risk but a certainty. [R-xp-log-comment]

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
generous — the target is the paragraph restating a one-line function, and a
genuinely subtle passage that trips it is exactly the kind that SHOULD be
split so its explanation attaches to something smaller. [R-xp-verbose]

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
identifiers normalised to a single placeholder, so a copy differing only in
naming is still detected. Comparing names would miss the entire case the
check exists for: an agent writing a fresh helper names it after the new
context, and a name-sensitive comparison scores that near zero while the two
functions are the same function. Code of similar shape but different
substance MUST NOT be reported, so a minimum chunk size applies and the
threshold is high by default. [R-xp-duplicate-structural]

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

```slop-check @R-xp-duplicate-structural
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

### Why one document carries two enforcement levels

The structural and supply findings derive from declarations: a unit either
is or is not reachable, a manifest entry either does or does not resolve.
They are true by construction, so they block. The textual findings are
pattern matches with genuine false-positive rates, so they are surfaced
where a person sees them and resolved in the `REFACTOR` leg of
draft-claude-xp-tdd-loop-00, where the tests are green and the change is
safe. The distinction is about confidence, not importance, and separating
the documents obscured that both resist the same decay.

A duplicate finding is resolved by using the existing code, never by
adjusting the threshold until the finding disappears. A system MAY set its
thresholds once, as a property of its language and style, and MUST NOT
retune them in response to a finding in flight — the same rule the increment
bound carries, for the same reason.

## Formal Grammar

```abnf
inventory   = *( inv-stmt LF )
inv-stmt    = entry-s / unit-s / calls-s / impl-s / card-s / covers-s
            / asserts-s / origin-s / except-s / dep-stmt
entry-s     = %s"entry" 1*WSP name
unit-s      = %s"unit" 1*WSP name
calls-s     = %s"calls" 1*WSP name 1*WSP name
impl-s      = %s"implements" 1*WSP name 1*WSP name
card-s      = %s"card" 1*WSP name
covers-s    = %s"covers" 1*WSP name 1*WSP name
asserts-s   = %s"asserts" 1*WSP name 1*WSP 1*4DIGIT
origin-s    = %s"origin" 1*WSP name 1*WSP story-id
except-s    = %s"except" 1*WSP kind 1*WSP name 1*WSP %s"until" 1*WSP date
              1*WSP %s"because" 1*WSP text
kind        = %s"orphan" / %s"uncarded" / %s"unrealized" / %s"untested"
            / %s"hollow" / %s"expired"
dep-stmt    = manifest-s / locked-s / imports-s / stdlib-s / vendored-s
manifest-s  = %s"manifest" 1*WSP pkg [ 1*WSP version ]
locked-s    = %s"locked" 1*WSP pkg 1*WSP version
imports-s   = %s"imports" 1*WSP name 1*WSP pkg
stdlib-s    = %s"stdlib" 1*WSP pkg
vendored-s  = %s"vendored" 1*WSP pkg
fixture     = *( assertion LF ) sep LF source
assertion   = %s"expect" 1*WSP finding
finding     = ( %s"log-comment" 1*WSP line ) / ( %s"verbose" 1*WSP line )
            / ( %s"duplicate" 1*WSP line 1*WSP line ) / %s"clean"
sep         = "---"
line        = 1*5DIGIT
source      = *OCTET
pkg         = ALPHA *( ALPHA / DIGIT / "-" / "_" / "." / "/" / "@" )
version     = 1*( DIGIT / ALPHA / "." / "-" / "+" )
name        = ALPHA *( ALPHA / DIGIT / "_" / "-" )
story-id    = ALPHA *( ALPHA / DIGIT / "-" / "_" )
date        = 4DIGIT "-" 2DIGIT "-" 2DIGIT
text        = VCHAR *( WSP / VCHAR )
```

Target, story, `serves`, `retired`, and `today` are shared with
draft-claude-xp-backlog-00. Slop fixture source is taken verbatim to end of
file, unescaped, because blank lines delimit chunks and any transformation
would change what is being detected.

## Alternatives Considered

### Computing reachability or imports from source directly

Parse the code rather than read a declared inventory. Rejected as the
specification's job: it would bind this document to one language's
toolchain, and the adapter doctrine puts engine concerns behind a seam. A
project that can generate its inventory from a real call graph or import
analysis SHOULD do exactly that — the inventory is the interface, and a
higher-fidelity producer is strictly better. A hand-maintained inventory
drifts from the code, and a drifted inventory reports fiction.

### Reporting without blocking

Produce the findings and let the pair judge. Rejected for the structural and
supply checks on the evidence of every warning-only gate ever shipped:
findings accumulate at the rate they are ignored, and an agent under
instruction to finish a story ignores them completely. Retained
deliberately for the textual checks, where the false-positive rate makes
blocking self-defeating.

### Deleting orphans or unused dependencies automatically

Rejected: reachability is computed from a declared inventory that can be
wrong, and a plugin hook, entry point, or reflective call has no edge.
Holding costs a decision; deleting costs a recovery.

### Undated exceptions with periodic review

The conventional arrangement. Rejected because the intention is never kept
and the file becomes where the decay lives. A date makes the review happen
or makes the sweep fail, and either is better than the file.

### Age-based deletion of code

Delete code untouched for N months. Rejected for the reason age-based
escalation is rejected in draft-claude-xp-backlog-00: age is not value.
Stable code is often the best code in a repository.

### Checking the registry inside the corpus

Rejected: the corpus must be deterministic and runnable offline, and the
obvious workaround — recording a response and replaying it — produces a
block that passes because it was written to.

### An LLM judging its own output for slop

Rejected on the same grounds the series rejects LLM-as-judge: circular for a
corpus meant to constrain agents, and an agent reports clean code for the
same reason it reports test-first work it did not do.

### Language-aware parsing for duplicate detection

Per-language ASTs would be more accurate. Rejected for a first draft as
disproportionate: a structural token stream over blank-line chunks catches
renamed copies with no parser and works across a polyglot repository at
once. A project wanting AST-grade detection SHOULD run a real clone
detector.

## Security Considerations

The checks parse declarations and text, execute nothing, follow no paths out
of their files, and constrain identifiers to alphanumerics with separators.

The structural sweep's hazard is the one it exists to manage, pointed the
other way: it is a mechanism for justifying deletion, and a wrong inventory
makes a live unit look orphaned. An authorization check invoked only through
a framework hook, reflection, or a plugin registry has no `calls` edge and
will be reported unreachable every session; deleting it removes a control
while every test still passes. This is why the sweep MUST NOT delete
anything itself, why entries include plugin hooks and API surfaces, and why
a security-relevant orphan MUST be investigated rather than dispositioned by
deletion on the strength of the report.

Exceptions are pair-authored suppressions, so a long-dated exception over a
security-relevant unit hides it for the life of the date. Dates SHOULD be
short enough that the argument is re-made while the reason is still known,
and an exception over authentication, authorization, input validation, or
secret handling SHOULD carry the shortest date the pair can work with.

`expired` findings deserve care in the opposite direction: code tracing to a
retired target may still be the only implementation of a control a live
target silently depends on. Retiring a target does not retire the
obligation.

On the supply side, an inventory omitting an import hides exactly the
dependency an attacker wants hidden, and one generated by the same agent
that wrote the imports inherits that agent's blind spots. The offline checks
close the window between invention and registration but not the case where
the attacker registered first — that case has no in-repository signature,
which is why the CI registry check is REQUIRED rather than optional despite
this document being unable to prove it in its own corpus.

The textual checks create pressure to delete comments, and a comment
explaining why a check exists ("this bound is enforced because the upstream
field is attacker-controlled") is precisely the comment worth keeping. Such
a comment explains the code rather than narrating its history and MUST NOT
be reported by a correct detector; a pair deleting security rationale to
satisfy this document has misread it. Findings also quote matched source
lines, so a run over a file containing secrets prints them into a report —
output SHOULD be treated with the same care as the source.

## Compatibility

Absorbs draft-claude-xp-drift-00, draft-claude-xp-drift-00, and
draft-claude-xp-drift-00, which are deleted rather than retained: all
three were drafts, nothing external cites them, and git history holds their
reasoning. Requirement IDs carry forward unchanged, with
`R-xp-duplicate-precise` folded into `R-xp-duplicate-structural`, which now
carries two evidence blocks.

The `sweep`, `deps`, `slop`, and `slop-check` adapters are unchanged. The
`sweep:` and `deps:` evidence keys collapse into a single `drift:` key in
draft-claude-xp-pairing-00's `INTEGRATE` guards: the two are attached at the
same moment by the same pair for the same reason, and one attachment is one
less thing for a process driver to sequence.

Projects producing no inventory cannot satisfy the guard, which is
deliberate but abrupt: adopting this document means writing an inventory
generator first, as its own story.

## References

- draft-claude-xp-pairing-00 — the session machine whose `INTEGRATE` guard
  this blocks, and the corpus rule it mirrors at the code layer.
- draft-claude-xp-backlog-00 — targets and retirement, which `expired`
  reads, and the same resistance applied to the backlog.
- draft-claude-xp-design-00 — the cards `implements` names, and the
  reachability rule generalised here.
- draft-claude-xp-tdd-loop-00 — the `REFACTOR` leg where textual findings
  are resolved.
- Spracklen et al., "We Have a Package for You! A Comprehensive Analysis of
  Package Hallucinations by Code Generating LLMs", USENIX Security 2025.
- Slopsquatting, named by Seth Larson (Python Software Foundation).
- superpowers `finding-duplicate-functions` — prior art on semantic
  duplication in agent-written codebases.
- RFC 5234 (ABNF), RFC 2119, RFC 8174 (BCP 14).

## Changelog

- 2026-08-21: DRAFT created, absorbing draft-claude-xp-drift-00,
  draft-claude-xp-drift-00, and draft-claude-xp-drift-00. The three
  were one concern at one gate — what must not be allowed to accumulate —
  split across documents that shared a motivation and referenced each other
  to be understood. Requirement IDs carry forward; `sweep:` and `deps:`
  collapse into one `drift:` attachment. The difference in enforcement
  (structural and supply block, textual advises) is now stated as a
  confidence distinction rather than implied by living in separate
  documents.
