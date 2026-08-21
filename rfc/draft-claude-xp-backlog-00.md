# draft-claude-xp-backlog-00: The Backlog Derivation

**Status:** DRAFT
**Category:** Experimental
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-21

## Abstract

Three questions a pair asks constantly — what do we want, what still serves
it, and what can we build next — answered by derivation over one declared
file rather than by a meeting. Targets are declared and retired explicitly;
a story serving no live target is **held** out of the order pending a
decision; a target nothing serves is reported; age is reported and never
acts. Ordering is then the design graph as a hard partial order with story
priority resolving only what the graph leaves free, and every position is
reported as forced or chosen so a preference is never mistaken for a
constraint.

## Motivation

The planning practices this series rejected — release planning, iteration
planning, velocity — were coordination machinery for parties a pair does not
have. What survived the rejection is the part that was never really a
meeting: prioritization, aging, and drift from current targets are all
observable. Priority is declared, age is arithmetic on dates, and drift is a
comparison between what the backlog serves and what the customer currently
wants. None needs an estimate, and estimates would not help, since they
converge on one value across a backlog and carry no information beyond
"split this."

Drift is the expensive one. Targets move — a quarter ends, a bet does not
pay off — and the backlog does not move with them. What remains is work
justified by a goal nobody holds, indistinguishable in the list from work
that still matters, and an agent will happily build it: it is
well-specified, it has an acceptance criterion, and nothing in it says its
reason expired. The second direction is asked about less and matters more: a
target nothing is being done about is invisible in a list of well-formed
work.

Ordering is separable from all of that and is not a matter of opinion. A CRC
deck is a dependency graph pairs habitually read as documentation:
`Receipt uses LineItem` says Receipt cannot be finished before LineItem
exists. Left implicit, those facts are rediscovered the expensive way — a
story starts, hits a collaborator that does not exist, and stalls or grows
an untracked stub. Read out, they answer the ordering question and remove it
from discussion, leaving only the genuinely contested part for the customer.

This derivation works inside an iteration. Choosing the iteration itself is
project scale and belongs to draft-claude-iterative-development-00, whose
walking skeleton orders by risk and user journey. The two compose: the
skeleton selects what to work on, this document sequences the work within
it.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **backlog problem** — the declared input: targets, stories with priorities
  and the cards they realize, the `serves` relation, dates, and the deck.
  One file, read by two lenses.
- **target** — something the customer currently wants. Retired explicitly;
  targets do not expire.
- **serves** — the relation between a story and the target justifying it.
- **drifted story** — one serving a retired, undeclared, or absent target.
  Drifted stories are **held**: excluded from the order, retained in the
  record.
- **unserved target** — a live target no live story serves.
- **age** — whole days between a story's `since` date and a declared
  `today`. Both are inputs, so a derivation is reproducible.
- **realizes** — the relation between a story and the cards it implements.
- **dependency of a story** — the cards its realized cards `use`, minus
  those it realizes itself.
- **ready** — every dependency is built, external, or realized by an
  already-ordered story.
- **forced** / **chosen** — a position where exactly one story was ready, or
  where several were and priority selected among them.

## Specification

### Grooming is a derivation, not a meeting

Grooming MUST be computed from declared facts and MUST NOT require a
scheduled session. The declared `today` is what makes it reproducible: the
same file yields the same report on any machine at any wall-clock time, so a
grooming report is evidence rather than a snapshot of a mood.
[R-xp-groom-derived]

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
excluded from the derived order, and MUST NOT be deleted by the derivation.
Holding is the whole design: ordering it would build work whose
justification expired, and dropping it would discard work the customer might
still want under another target. [R-xp-drift-held]

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

The order lens enforces the same fact, so a held story cannot reach the loop
by another route — it leaves the set before the graph is walked — and when a
card a live story needs is realized only by a held story, the report names
the held story, because the remedy is a decision about the target rather
than new work.

```order @R-xp-drift-held
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

A live target served by no live story MUST be reported. Ordering cannot
reveal this: every story can be current and correctly sequenced while the
customer's actual aim has nothing pointed at it. [R-xp-target-unserved]

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

Age MUST be reported in whole days and MUST NOT reorder, escalate, or expire
anything. Escalation by age builds work because it is old rather than
wanted, which is how backlogs become undead. The derivation MUST raise a
contradiction when a story is both stale and of the best priority among live
stories, naming the two resolutions: the priority is wrong, or something
unnamed is blocking it. [R-xp-aging-reported]

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

### The graph constrains, priority chooses

The order MUST be derived from the deck and the story set and MUST NOT be
asserted independently of them. A story MUST NOT be ordered before any story
realizing a card it depends on. Where several are ready, the derivation MUST
select the lowest priority number, breaking ties by story ID so the same
problem always yields the same order. [R-xp-order-derived]

```order @R-xp-order-derived
deck root Receipt
deck card Receipt
deck   does hold the line items rung up
deck   uses LineItem
deck   uses Rounding
deck card LineItem
deck   does report its extended price
deck card Rounding
deck   does round an amount half up
story RCP-3 priority 1 realizes Receipt
story RCP-1 priority 3 realizes LineItem
story RCP-2 priority 2 realizes Rounding
expect RCP-2 RCP-1 RCP-3
```

The highest-priority story is ordered last there, because the design says
so.

### A choice is never presented as a constraint

Every position MUST be reported as forced or chosen, and a chosen position
MUST name the candidates it was chosen over. A pair that cannot see which
positions were free cannot exercise the freedom it has, and an agent
reporting a preference as a design requirement has manufactured authority
the design did not give it. [R-xp-order-disclosed]

```order @R-xp-order-disclosed
deck root Receipt
deck root Refund
deck card Receipt
deck   does hold the line items rung up
deck   uses LineItem
deck   uses Rounding
deck card LineItem
deck   does report its extended price
deck card Rounding
deck   does round an amount half up
deck card Refund
deck   does reverse a completed sale
deck   uses Receipt
story RCP-3 priority 1 realizes Receipt
story RCP-1 priority 3 realizes LineItem
story RCP-2 priority 2 realizes Rounding
chosen RCP-2
forced RCP-1
forced RCP-3
expect RCP-2 RCP-1 RCP-3
```

### Only what the stories need is in scope

The derivation MUST restrict the graph to cards reachable from a card some
current story realizes, and MUST report the excluded cards rather than
dropping them silently. A deck outlives any story set; ordering against the
whole deck would reintroduce anticipatory planning. [R-xp-order-scope]

```order @R-xp-order-scope
deck root Receipt
deck root Refund
deck card Receipt
deck   does hold the line items rung up
deck   uses LineItem
deck card LineItem
deck   does report its extended price
deck card Refund
deck   does reverse a completed sale
deck   uses Receipt
story RCP-3 priority 1 realizes Receipt
story RCP-1 priority 2 realizes LineItem
unscoped Refund
expect RCP-1 RCP-3
```

### An unsatisfiable set is reported, not worked around

If a card in scope is realized by no story, or stories remain and none is
ready, the derivation MUST fail with the reason and MUST NOT emit a partial
or reordered result. Both are findings about the story set: a dependency no
story realizes is work the customer has not been asked for, and a mutual
dependency across stories means the split does not match the design — the
remedy is to merge the stories or break the cycle, never to pick one and
stub the other silently. [R-xp-order-blocked]

```order @R-xp-order-blocked
deck root Order
deck card Order
deck   does list what was bought
deck   uses Pricing
deck card Pricing
deck   does price a line
story ORD-1 priority 1 realizes Order
blocked no story realizes card Pricing
```

```order @R-xp-order-blocked
deck root Basket
deck card Basket
deck   does hold what is being bought
deck   uses Promotion
deck card Promotion
deck   does discount a basket
deck   uses Basket
story BSK-1 priority 1 realizes Basket
story PRM-1 priority 2 realizes Promotion
blocked depend on each other in a cycle
```

### Where the derivations are consumed

The grooming report is the substance of the session-opening briefing:
draft-claude-xp-pairing-00's `SESSION_START` guard requires `groom:`, so a
session cannot begin without the pair having seen what drifted, what is
unserved, and what has aged. A problem with no targets records
`groom: no targets`. [R-xp-groom-briefed]

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

The order is consumed at `STORY_SELECT`, whose guard requires `order:`. The
human arrives with a priority; the derivation advises and the customer
decides, so a pair MAY select a story other than the derived next one, but
the departure MUST be recorded in the advance's rationale so the record
shows a decision rather than a drift. [R-xp-order-consumed]

```xp-run @R-xp-order-consumed
machine initial STORY_SELECT
machine STORY_SELECT -> PAIR_DECLARE
machine PAIR_DECLARE -> DONE
machine terminal DONE
machine guard STORY_SELECT -> PAIR_DECLARE: story acceptance order
machine guard PAIR_DECLARE -> DONE: mode
refuse PAIR_DECLARE missing story acceptance order
story RCP-2
accept amounts round half up in receipts
attach order: RCP-2 RCP-1 RCP-3 — RCP-2 chosen over RCP-1 by priority
advance PAIR_DECLARE why: taking the derived next story
at PAIR_DECLARE
audit ok
```

## Formal Grammar

One file, two lenses; each ignores the other's statements.

```abnf
problem      = *( statement LF )
statement    = target-d / retired-d / serves-d / since-d / today-d / stale-d
             / deck-line / story-line / built-line
target-d     = %s"target" 1*WSP target-id 1*WSP text
retired-d    = %s"retired" 1*WSP target-id
serves-d     = %s"serves" 1*WSP story-id 1*WSP target-id
since-d      = %s"since" 1*WSP story-id 1*WSP date
today-d      = %s"today" 1*WSP date
stale-d      = %s"stale" 1*WSP 1*3DIGIT
deck-line    = %s"deck" 1*WSP text
story-line   = %s"story" 1*WSP story-id 1*WSP %s"priority" 1*WSP priority
               1*WSP %s"realizes" 1*( 1*WSP card-name )
built-line   = %s"built" 1*WSP card-name
date         = 4DIGIT "-" 2DIGIT "-" 2DIGIT
target-id    = ALPHA *( ALPHA / DIGIT / "-" / "_" )
story-id     = ALPHA *( ALPHA / DIGIT / "-" / "_" )
card-name    = ALPHA *( ALPHA / DIGIT / "_" )
priority     = 1*3DIGIT
text         = VCHAR *( WSP / VCHAR )
```

Lower priority numbers are more urgent. Dates are whole days at UTC
resolution, and `today` is REQUIRED whenever any `since` is declared: a
derivation MUST fail rather than read the system clock, because a report
that varies with wall-clock time can never be evidence.

## Alternatives Considered

### Automatic escalation or expiry by age

Old stories climb the order, or are dropped past a threshold. Rejected: the
first converts age into value, overriding someone who repeatedly
deprioritized with information; the second makes silence destructive, losing
stories through inattention rather than decision. Drift already supplies a
non-arbitrary removal reason — the target is gone — and that reason is the
customer's, not the clock's.

### Dropping drifted stories automatically

Rejected: a story often survives its original justification and belongs to a
new target, and the derivation cannot know which. Holding forces the
question without pre-empting the answer.

### Pure topological order, or cheapest-next

Order by the graph alone, or break ties toward the fewest unbuilt
dependencies. Rejected: the first builds foundations ahead of anything
demonstrable and still picks arbitrarily among many valid orders while
appearing to derive them; the second systematically defers what the customer
cares about. Making the arbitrary part explicit and giving it to the
customer is the improvement.

### Automatic cycle breaking

Condense mutually-collaborating cards and order the condensation. Rejected:
it silently merges two stories the customer wrote separately. Reporting the
cycle costs one round trip and leaves the choice where it belongs.

### Reading the system clock

Rejected outright: it makes every derivation unreproducible, so a report
could never be evidence and a corpus could never check one.

### Story points, estimates, or velocity as inputs

The conventional grooming inputs. Rejected upstream in
draft-claude-xp-pairing-00 — estimates converge on a single size — and
nothing here needs them: drift, aging, and priority are all facts.

## Security Considerations

The derivations parse declarations and do arithmetic on dates; they execute
nothing, have no include or path syntax, and constrain identifiers to
alphanumerics with separators.

The security-relevant risk is that this document creates a mechanism for
removing work from the order — holding a drifted story — driven by retiring
a target. Retiring the wrong target silently withdraws every story serving
it, including security-relevant work whose justification was that target: a
hardening story serving a retired compliance goal is held exactly like a
cosmetic one. Findings are reported rather than silent, which is the
mitigation, but a pair that stops reading the drift list loses it. A held
story with security-relevant content SHOULD be re-served to a current target
rather than left held, and a `groom:` attachment reporting drift without a
disposition SHOULD be treated as an open item rather than a completed
briefing.

Aging carries the opposite risk: a security story that is stale and
top-priority is exactly the contradiction this document raises, and the
resolution "the priority is wrong" MUST NOT be chosen merely because it
closes the finding.

Ordering has a sequencing hazard: deferring a card carrying an authorization
or validation responsibility leaves the stories ahead of it running without
that protection, and each will pass its own tests. A pair departing from the
derived order MUST NOT move a security-relevant card later without recording
why.

## Compatibility

Absorbs draft-claude-xp-backlog-00 and draft-claude-xp-backlog-00, which are
deleted rather than retained: both were drafts, nothing external cites them,
and git history holds their reasoning. Requirement IDs are carried forward
unchanged, so commits and plans citing them remain valid.
`R-xp-drift-unordered` and `R-xp-drift-blocking` are folded into
`R-xp-drift-held`, and `R-xp-order-cycle` into `R-xp-order-blocked`, each
now carrying more than one evidence block.

The `order` and `groom` adapters are unchanged, as are the evidence keys
`order:` and `groom:` in draft-claude-xp-pairing-00's guards.

## References

- draft-claude-xp-pairing-00 — the session machine consuming both
  derivations.
- draft-claude-xp-design-00 — the deck the order lens reads.
- draft-claude-iterative-development-00 (Jesse Vincent, prime-radiant) — the
  project scale above this one: requirement extraction, proof obligations,
  and the walking skeleton that selects the iteration this document orders
  within.
- draft-claude-xp-drift-00 — the integration-time checks that resist the
  same decay in code that this document resists in the backlog.
- RFC 5234 (ABNF), RFC 2119, RFC 8174 (BCP 14), RFC 3339 (dates).

## Changelog

- 2026-08-21: DRAFT created, absorbing draft-claude-xp-backlog-00 and
  draft-claude-xp-backlog-00. The two were always one derivation over one
  file — what we want, what still serves it, what we can build next — and
  splitting them produced two documents that could only be understood
  together. Requirement IDs carried forward; four IDs folded into two.
  Ordering is restated as composing with prime-radiant's project-scale
  walking skeleton rather than competing with it.
