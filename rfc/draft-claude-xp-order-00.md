# draft-claude-xp-order-00: Implementation Order Derived from the Deck

**Status:** DRAFT
**Category:** Experimental
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-19

## Abstract

Implementation order for a pair is computed, not negotiated. This document
specifies the derivation: the CRC deck's collaboration edges are a hard
partial order over the cards, the current story set scopes which cards
matter at all, and story priority resolves only what the graph leaves free.
The derivation is deterministic and reports each position as **forced** — the
graph admitted one candidate — or **chosen** — several were ready and
priority decided. A story set the graph cannot satisfy is reported as
blocked rather than silently reordered.

## Motivation

Ordering work is the part of planning that survives the loss of a team. The
ceremony around it does not: draft-claude-xp-pairing-00 rejects release
planning, iteration planning, and velocity because they coordinate parties a
pair does not have. What remains is a real question asked several times a
session — what can we build next — and it has a real answer that nobody
needs to meet about, because the design already contains it.

A CRC deck is a dependency graph that pairs habitually read as documentation.
`Receipt uses LineItem` says Receipt cannot be finished before LineItem
exists in some form, and a deck of twenty cards holds dozens of such facts.
Left implicit, they are rediscovered the expensive way: a story is started,
runs into a collaborator that does not exist, and either stalls or grows a
stub nobody tracks. Read out loud, they answer the ordering question
directly and remove it from discussion.

The remaining freedom is real and belongs to the customer. Most decks leave
many valid orders, and choosing among them is a value judgement — which is
exactly the judgement the human in the pair is present to make. The
derivation therefore separates the two: it enforces what the design requires
and defers what it does not, and it says which was which at every step so
that a choice is never mistaken for a constraint.

This is deliberately not the ordering strategy of the iterative-development
skill (draft-claude-iterative-development-00). That process orders by risk
and user journey, building a walking skeleton end to end and growing it.
This one orders by the design graph over a fixed story set. They answer
different questions — "what is the thinnest thing that proves the system
works" versus "given these stories and this design, what can we build now" —
and a project may reasonably use either.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **order problem** — the input to a derivation: a deck, a story set with
  priorities and the cards each story realizes, and the cards already built.
- **realizes** — the relation between a story and the cards it implements. A
  card is realized by at most one story in a given problem.
- **dependency of a story** — the cards its realized cards `use`, minus the
  cards it realizes itself. A story is not blocked by its own internals.
- **ready** — every dependency of the story is built, external, or realized
  by an already-ordered story.
- **forced** — a position at which exactly one story was ready; the graph
  determined it.
- **chosen** — a position at which several stories were ready and priority
  selected among them.
- **blocked** — no story is ready and stories remain, or a dependency is a
  card no story realizes.
- **in scope** — reachable through `uses` from a card some current story
  realizes. Cards outside scope are excluded from the derivation.

## Specification

### The graph constrains, priority chooses

The order MUST be derived from the deck and the story set, and MUST NOT be
asserted independently of them. A story MUST NOT be ordered before any story
realizing a card it depends on. Where several stories are ready at a
position, the derivation MUST select the one with the lowest priority
number, breaking remaining ties by story ID so that the same problem always
yields the same order. [R-xp-order-derived]

The example below is the whole mechanism in one problem: the highest-priority
story is ordered last, because the design says so.

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

### A choice is never presented as a constraint

Every position in the derived order MUST be reported as forced or chosen,
and a chosen position MUST name the candidates it was chosen over. The
distinction is the point of separating the two inputs: a pair that cannot
see which positions were free cannot exercise the freedom it has, and an
agent reporting a priority preference as a design requirement has
manufactured authority the design did not give it. [R-xp-order-disclosed]

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

The derivation MUST restrict the graph to cards reachable through `uses`
from a card some current story realizes, and MUST report the excluded cards
rather than dropping them silently. A deck outlives any one story set, so it
will contain cards for work not currently in flight; ordering against the
whole deck would reintroduce exactly the anticipatory planning the parent
document rejects. The excluded cards are reported because an exclusion is
occasionally a surprise — a card the pair believed was needed. [R-xp-order-scope]

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

If a card in scope is realized by no story, or if stories remain and none is
ready, the derivation MUST fail with the reason and MUST NOT emit a partial
or reordered result. Both conditions are findings about the story set, not
errors to be routed around: a dependency no story realizes is missing work
the customer has not been asked for, and a mutual dependency across stories
means the split does not match the design. [R-xp-order-blocked]

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

Mutual dependency across stories is the second form, and it is a design
signal rather than a scheduling problem. Cards that collaborate in a cycle
are legal — the deck checker permits them deliberately — but two stories
each realizing one side of a cycle cannot be sequenced, and the remedy is to
merge the stories or break the cycle in the design, never to pick one and
stub the other silently. [R-xp-order-cycle]

```order @R-xp-order-cycle
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

### Where the order is consumed

The derived order is consumed at the parent machine's `STORY_SELECT`, whose
guard requires an `order:` attachment alongside the story contract. The
attachment records the derivation the selection followed. A pair MAY select
a story other than the derived next one — the derivation is advice about
sequence, not authority over what the customer wants today — but the
departure MUST be recorded in the advance's rationale, so the run record
shows a decision rather than a drift. A story set with no deck records
`order: no deck`, which is the honest value for the first stories of a
system. [R-xp-order-consumed]

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

### The deck persists

Ordering requires a deck spanning more than the story in hand, so the deck
is a property of the system rather than of a design session: one deck,
extended by each design session, carried across sessions. Cards are added
when a story needs them and removed when nothing does — the checker's
reachability rule makes an orphaned card visible, and an orphan is a card to
delete, not to keep for later.

## Formal Grammar

```abnf
problem      = *( statement LF )
statement    = deck-line / story-line / built-line / assertion
deck-line    = %s"deck" 1*WSP text          ; a line of crc syntax
story-line   = %s"story" 1*WSP story-id 1*WSP %s"priority" 1*WSP priority
               1*WSP %s"realizes" 1*( 1*WSP card-name )
built-line   = %s"built" 1*WSP card-name
assertion    = expect-a / blocked-a / forced-a / chosen-a / unscoped-a
expect-a     = %s"expect" 1*( 1*WSP story-id )
blocked-a    = %s"blocked" 1*WSP text
forced-a     = %s"forced" 1*WSP story-id
chosen-a     = %s"chosen" 1*WSP story-id
unscoped-a   = %s"unscoped" 1*WSP card-name
story-id     = ALPHA *( ALPHA / DIGIT / "-" / "_" )
card-name    = ALPHA *( ALPHA / DIGIT / "_" )
priority     = 1*3DIGIT
text         = VCHAR *( WSP / VCHAR )
```

Lower priority numbers are more urgent. The assertions are what make a
problem evidence rather than a worked example; a problem file stating none
is rejected.

## Alternatives Considered

### Pure topological order, no priority input

Order determined entirely by the graph, leaves first. Rejected: it is
deterministic but builds foundations ahead of anything demonstrable, and
most decks admit many topological orders, so the tool would be picking among
them by an arbitrary rule while appearing to derive them. Making the
arbitrary part explicit — and giving it to the customer — is the whole
improvement.

### Priority alone, with stubs for missing collaborators

Work in the customer's order and stub whatever does not exist yet. Rejected
as the default because untracked stubs are how a design silently diverges
from its deck; the stub is real work nobody has agreed to. It remains
available deliberately: a pair MAY depart from the derived order, and the
departure is recorded.

### Ordering by cheapest-next

Break ties toward the story with the fewest unbuilt dependencies. Rejected:
it optimizes for a fast green suite and systematically defers what the
customer cares about, and the pair already sees the ready set and can choose
cheapness when it wants it.

### Automatic cycle breaking

Condense mutually-collaborating cards into one unit and order the
condensation. Rejected for this draft: it would silently merge two stories
the customer wrote separately, and the merge is a decision worth making
explicitly. Reporting the cycle costs one round trip and leaves the choice
where it belongs.

### Deriving `realizes` from the code

Infer which story implements which card by watching what gets committed.
Rejected as circular — the order is needed before the code exists — and as
unreliable across languages where a card is not a class.

## Security Considerations

The derivation reads two artifacts the pair wrote and executes nothing from
them: the problem file is parsed, not evaluated, and it has no include,
interpolation, or path syntax, so a problem cannot reach outside itself.
Card and story identifiers are constrained by the grammar to alphanumerics
with separators, which keeps derived text out of command position in any
caller that prints it.

The security-relevant effect is on sequencing rather than on execution. An
ordering that defers a card carrying an authorization or validation
responsibility leaves the stories ahead of it running without that
protection, and each of those stories will pass its own tests. The
derivation surfaces this — the deferred card is visible in the order, and
the stories depending on it are ordered after it — but a pair that departs
from the derived order MUST NOT move a security-relevant card later without
recording why, because that departure changes which code runs unprotected
and for how long. A `blocked` result naming an unrealized card deserves the
same attention: an unrealized dependency is work the customer has not been
asked for, and when the missing card is the one that checks permissions,
building around it is precisely the wrong response.

## Compatibility

This document adds one evidence type, `order`, whose adapter is also the
tool the pair runs interactively (`order --print <problem>`). It adds one
evidence key, `order:`, to the parent machine's `STORY_SELECT` guard, which
is a change to draft-claude-xp-pairing-00's machine; sessions in flight
under the previous machine record no `order:` and their run records remain
valid path witnesses, since the guard is checked at advance time rather than
retroactively.

The deck moves from a per-session artifact to a persistent one, which is a
change in convention rather than in format: an existing deck is already a
valid persistent deck.

## References

- draft-claude-xp-pairing-00 — the session machine whose `STORY_SELECT`
  consumes the derived order.
- draft-claude-xp-design-00 — the deck this document reads, and the `crc`
  checker every order problem's deck must pass.
- draft-claude-iterative-development-00 — the risk-and-journey ordering
  strategy this one deliberately differs from.
- Extreme Programming rules: http://www.extremeprogramming.org/rules.html —
  "user stories", whose ordering question this answers without the planning
  ceremony the parent document rejects.
- RFC 5234 (ABNF), RFC 2119, RFC 8174 (BCP 14).

## Changelog

- 2026-08-19: DRAFT created from the author's requirement that implementation
  order be determined by CRC dependency analysis over the current story set,
  as a process distinct from iterative-development's risk-and-journey
  ordering. The deck's `uses` edges are a hard partial order, the story set
  scopes the graph, and priority resolves only the remaining freedom; every
  position is reported as forced or chosen, and unsatisfiable sets are
  reported as blocked rather than reordered. The deck becomes a persistent
  system artifact, and `order:` joins the parent's `STORY_SELECT` guard.
