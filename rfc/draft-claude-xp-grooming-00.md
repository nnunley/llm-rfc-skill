# draft-claude-xp-grooming-00: Targets, Drift, and Aging

**Status:** DRAFT
**Category:** Experimental
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-20

## Abstract

Backlog grooming, without the meeting. This document makes targets a
declared artifact, requires each story to name the target it serves, and
derives three findings from dates and declarations alone: **drift** — a story
serving a target you have retired, which is held out of the derived order
rather than silently worked or silently deleted; **unserved targets** — a
target no live story points at; and **aging** — how long each story has
waited, with an explicit contradiction raised when your best-priority story
is also your oldest. Nothing is estimated and nothing is auto-escalated; the
derivation reports facts and holds decisions for the customer.

## Motivation

The three things a pair actually needs from the planning practices it
rejected are prioritization, aging, and drift from current targets. All
three are observable: priority is declared, age is arithmetic on dates, and
drift is a comparison between what the backlog serves and what the customer
currently wants. None of them requires an estimate, and none requires a
recurring meeting — which is fortunate, because grooming as normally
practiced is a meeting whose output is a reordered list nobody can audit.

Drift is the expensive one and the least visible. Targets move — a quarter
ends, a customer changes their mind, a bet does not pay off — and the
backlog does not move with them. What remains is work that was justified by
a goal nobody holds any more, indistinguishable in the list from work that
still matters. An agent will happily build it: it is well-specified, it has
an acceptance criterion, and nothing in the story says its reason expired.
Making the target explicit and the link mandatory turns that from a judgement
call into a comparison.

The second direction of drift matters more and is asked about less: a target
nothing is being done about. A backlog can be entirely free of stale work
and still not point where the customer is aiming, and no amount of ordering
the existing stories reveals it — the finding only exists if targets are
first-class enough to be counted against.

Aging is included for one specific signal rather than as a metric. A story
that is both the highest priority and the oldest is a contradiction: either
the priority is wrong, or something is blocking it that nobody has named.
That pair of facts is worth surfacing every session. The age by itself is
not worth acting on automatically, which is why it never moves anything.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **target** — something the customer currently wants, declared with an ID.
  Targets are retired explicitly; they do not expire.
- **serves** — the relation between a story and the target that justifies
  it. A story serves at most one target.
- **live story** — one serving a declared, unretired target.
- **drifted story** — one serving a retired, undeclared, or absent target.
  Drifted stories are **held**: excluded from the derived order, retained in
  the record.
- **unserved target** — a live target no live story serves.
- **age** — whole days between a story's `since` date and the declared
  `today`. Both are inputs, so a derivation is reproducible.
- **stale** — aged at or past the threshold, default 14 days.
- **contradiction** — a story that is both stale and of the best priority
  among live stories.

## Specification

### Grooming is a derivation, not a meeting

Grooming under this document MUST be computed from declared facts — targets,
the `serves` relation, `since` dates, and a declared `today` — and MUST NOT
require a scheduled session to produce its findings. The declared `today`
is what makes a derivation reproducible: the same problem file yields the
same report on any machine at any wall-clock time, so a grooming report is
evidence rather than a snapshot of a mood. [R-xp-groom-derived]

```groom @R-xp-groom-derived
target T-CASH accept cash payments this quarter
today 2026-08-20
story RCP-1 priority 1 realizes LineItem
serves RCP-1 T-CASH
since RCP-1 2026-08-18
groomed
```

### A drifted story is held, never silently worked or dropped

Once any target is declared, every story MUST serve a declared, unretired
target. A story that does not MUST be reported as drifted and MUST be
excluded from the derived implementation order, and it MUST NOT be deleted
by the derivation. Holding is the whole design: silently ordering the story
would build work whose justification expired, and silently dropping it would
discard work the customer may still want under a different target. The
disposition — re-serve it or drop it — belongs to the customer.
[R-xp-drift-held]

```groom @R-xp-drift-held
target T-CASH accept cash payments this quarter
retired T-LOYALTY
today 2026-08-20
story RCP-1 priority 1 realizes LineItem
story LOY-1 priority 2 realizes Points
serves RCP-1 T-CASH
serves LOY-1 T-LOYALTY
drifted LOY-1
```

The order lens enforces the same fact, so a held story cannot reach the
loop by a different route: it is dropped from the story set before the
graph is walked. [R-xp-drift-unordered]

```order @R-xp-drift-unordered
deck root Receipt
deck card Receipt
deck   does hold the line items rung up
deck   uses LineItem
deck card LineItem
deck   does report its extended price
deck card Points
deck   does track loyalty points
deck root Points
target T-CASH accept cash payments this quarter
retired T-LOYALTY
story RCP-2 priority 1 realizes Receipt
story RCP-1 priority 2 realizes LineItem
story LOY-1 priority 3 realizes Points
serves RCP-2 T-CASH
serves RCP-1 T-CASH
serves LOY-1 T-LOYALTY
unscoped Points
expect RCP-1 RCP-2
```

Drift that blocks live work MUST be reported as such rather than as a
generic missing dependency: when a card a live story needs is realized only
by a held story, the report names the held story, because the remedy is a
decision about the target rather than new work. [R-xp-drift-blocking]

```order @R-xp-drift-blocking
deck root Receipt
deck card Receipt
deck   does hold the line items rung up
deck   uses Points
deck card Points
deck   does track loyalty points
target T-CASH accept cash payments this quarter
retired T-LOYALTY
story RCP-2 priority 1 realizes Receipt
story LOY-1 priority 3 realizes Points
serves RCP-2 T-CASH
serves LOY-1 T-LOYALTY
blocked realized only by LOY-1, which has drifted
```

### A target nothing serves is the other drift

A live target served by no live story MUST be reported. This is the
direction that ordering cannot reveal — every story may be current and
correctly sequenced while the customer's actual aim has nothing pointed at
it — and it is usually the more consequential of the two, because unstaffed
intent is invisible in a list of well-formed work. [R-xp-target-unserved]

```groom @R-xp-target-unserved
target T-CASH accept cash payments this quarter
target T-CARD accept card payments
retired T-LOYALTY
today 2026-08-20
story RCP-1 priority 1 realizes LineItem
story LOY-1 priority 2 realizes Points
serves RCP-1 T-CASH
serves LOY-1 T-LOYALTY
drifted LOY-1
unserved T-CARD
```

### Age is reported and never acts

The derivation MUST report each story's age in whole days and MUST NOT
reorder, escalate, or expire anything on account of it. Automatic
escalation by age builds work because it is old rather than because it is
wanted, which is the mechanism by which backlogs become undead. The
derivation MUST, however, raise a contradiction when a story is both stale
and of the best priority among live stories, naming the two possible
resolutions: the priority is wrong, or something unnamed is blocking it.
[R-xp-aging-reported]

```groom @R-xp-aging-reported
target T-CASH accept cash payments this quarter
today 2026-08-20
stale 14
story RCP-1 priority 1 realizes LineItem
story RCP-2 priority 2 realizes Rounding
serves RCP-1 T-CASH
serves RCP-2 T-CASH
since RCP-1 2026-07-02
since RCP-2 2026-08-18
aged RCP-1 49
aged RCP-2 2
contradiction RCP-1
```

### Where the report is consumed

The grooming report is the substance of the session-opening briefing. The
parent machine's `SESSION_START` guard requires `groom:`, so a session
cannot begin without the pair having looked at what drifted, what is
unserved, and what has aged — which is where a grooming meeting's value
actually lay, minus the meeting. A problem file with no targets declared
records `groom: no targets`, the honest value before a customer has stated
any. [R-xp-groom-briefed]

```xp-run @R-xp-groom-briefed
machine initial SESSION_START
machine SESSION_START -> STORY_SELECT
machine terminal STORY_SELECT
machine guard SESSION_START -> STORY_SELECT: briefing bound groom
refuse STORY_SELECT missing briefing bound groom
attach briefing: RCP-1 in flight, corpus green
bound 3 files 150 lines
attach groom: LOY-1 drifted from retired T-LOYALTY, T-CARD unserved
advance STORY_SELECT why: the pair has seen the drift before choosing work
at STORY_SELECT
audit ok
```

## Formal Grammar

The grooming statements extend the order problem of
draft-claude-xp-order-00; the two lenses ignore each other's statements, so
one file describes the whole backlog.

```abnf
groom-stmt   = target-d / retired-d / serves-d / since-d / today-d / stale-d
target-d     = %s"target" 1*WSP target-id 1*WSP text
retired-d    = %s"retired" 1*WSP target-id
serves-d     = %s"serves" 1*WSP story-id 1*WSP target-id
since-d      = %s"since" 1*WSP story-id 1*WSP date
today-d      = %s"today" 1*WSP date
stale-d      = %s"stale" 1*WSP 1*3DIGIT
date         = 4DIGIT "-" 2DIGIT "-" 2DIGIT
target-id    = ALPHA *( ALPHA / DIGIT / "-" / "_" )
story-id     = ALPHA *( ALPHA / DIGIT / "-" / "_" )
text         = VCHAR *( WSP / VCHAR )
```

Dates are whole days at UTC resolution; `today` is REQUIRED whenever any
`since` is declared, and a derivation MUST fail rather than read the system
clock.

## Alternatives Considered

### Automatic escalation by age

Old stories climb the order until they get built. Rejected: it converts age
into value, which is precisely backwards — a story nobody has wanted for
seven weeks has been repeatedly deprioritized by someone with information,
and overriding that with arithmetic builds the least-wanted work first. The
contradiction finding extracts the one genuinely informative case without
moving anything.

### Expiry by age

A story past a threshold is dropped unless renewed. Rejected as the default
because it makes silence destructive: the record would lose stories through
inattention rather than decision, and inattention is not a judgement about
value. Drift already provides a non-arbitrary reason to remove work — the
target is gone — and that reason is the customer's, not the clock's.

### Dropping drifted stories automatically

No current target, no story. Rejected: a story often survives its original
justification and belongs to a new target, and the derivation cannot know
which. Holding forces the question without pre-empting the answer.

### Keeping drifted stories orderable and reporting drift as a number

Lowest friction: surface a percentage and let the pair decide. Rejected
because a number nobody must act on is a number nobody acts on; the story
stays buildable, and an agent looking for work will find it well-formed and
build it.

### Reading the system clock

Compute age from the current time rather than a declared `today`. Rejected
outright: it makes every grooming derivation unreproducible, so a report
could never be evidence and a corpus could never check one. Declaring
`today` costs a line and buys determinism.

### Story points, estimates, or velocity as grooming inputs

The conventional grooming inputs. Rejected upstream in
draft-claude-xp-pairing-00 — estimates converge on a single size, so they
carry no information beyond a split signal — and nothing in this document
needs them: drift, aging, and priority are all facts.

## Security Considerations

The derivation parses declarations and does arithmetic on dates; it executes
nothing, has no include or path syntax, and constrains identifiers to
alphanumerics with separators, so a problem file cannot reach outside
itself.

The security-relevant risk is that this document creates a mechanism for
removing work from the derived order — holding a drifted story — and that
mechanism can be driven by retiring a target. Retiring the wrong target
silently withdraws every story serving it from the order, including
security-relevant work whose justification was that target: a hardening
story serving a retired compliance goal is held exactly like a cosmetic one.
The findings are reported rather than silent, which is the mitigation, but a
pair that stops reading the drift list loses the protection. For that reason
a held story with security-relevant content SHOULD be re-served to a current
target rather than left held, and a `groom:` attachment that reports drift
without a disposition SHOULD be treated as an open item at the next session
rather than as a completed briefing.

Aging carries the opposite risk: a security story that is stale and
top-priority is precisely the contradiction this document raises, and the
resolution "the priority is wrong" MUST NOT be chosen merely because it
closes the finding.

## Compatibility

This document adds one evidence type, `groom`, and extends the order problem
with six statements. Both are backward compatible: an order problem with no
`target` statements is ungroomed and unchanged — the order lens applies no
drift check when no targets are declared — so existing problems and the
existing corpus are unaffected.

It adds `groom` to draft-claude-xp-pairing-00's `SESSION_START` guard, which
changes that machine. Run records already in flight are unaffected, since
guards are evaluated at advance time.

## References

- draft-claude-xp-order-00 — the order lens over the same problem file, and
  the prioritization half of what this document completes.
- draft-claude-xp-pairing-00 — the session machine whose `SESSION_START`
  guard consumes the report, and the estimate rejection this document
  inherits.
- draft-claude-xp-design-00 — the deck the order lens reads.
- RFC 5234 (ABNF), RFC 2119, RFC 8174 (BCP 14), RFC 3339 (date format).

## Changelog

- 2026-08-20: DRAFT created from the author's statement that what matters is
  prioritization, aging, and drift from current targets — the grooming
  function without the grooming meeting. Targets become declared artifacts,
  drifted stories are held out of the derived order pending a customer
  decision, unserved targets are reported as the second and more
  consequential direction of drift, and age is reported without ever moving
  anything except to raise the stale-top-priority contradiction. Aging's
  report-only disposition was inferred from the author's choice to hold
  drifted stories for decision rather than act on them automatically.
