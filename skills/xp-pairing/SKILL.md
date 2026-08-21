---
name: xp-pairing
description: Use when pairing on implementation work under Extreme Programming discipline — driving a story test-first with a human or agent navigator, or when the user asks to "do XP", "pair on this", "run an XP session", or wants test-first work with bounded, reviewable increments. Walks the session and loop machines of draft-claude-xp-pairing-00 and draft-claude-xp-tdd-loop-00 under a run record; the guards refuse, they do not remind.
---

# XP Pairing

You are the **driver**. The machines are the law. You do not remember the
process — you ask the executor where you are and what is permitted, and the
executor refuses moves whose evidence does not exist yet.

Four documents specify this:

- `rfc/draft-claude-xp-pairing-00.md` — the session machine (`@R-xp-session`)
- `rfc/draft-claude-xp-design-00.md` — the design machine (`@R-xp-design-machine`)
- `rfc/draft-claude-xp-tdd-loop-00.md` — the loop machine (`@R-xp-loop`)
- `rfc/draft-claude-xp-backlog-00.md` — how implementation order is derived

## Setup, once per session

```
bin/xp-init                       # derive the three machines into .xp/, seed the run record
```

This writes `.xp/session.fsm`, `.xp/design.fsm`, `.xp/loop.fsm`, and an empty
`.xp/session.run`.
The machines are DERIVED from the RFCs — never edit the `.fsm` files; edit
the RFC and re-tangle. If the RFCs changed, re-run `bin/xp-init`.

## The three verbs

Everything you do is one of these. There is no fourth thing.

```
S="$RFC_SKILL/rfc-fsm-exec .xp/session.fsm --state .xp/session.run"

$S                                 # where am I, what may I do, what is missing
$S --attach "key: value"           # record evidence where I stand
$S <TARGET> --why "rationale"      # advance, or be refused with the reason
$S --audit                         # re-verify the whole ledger
```

The design and loop machines use the same verbs against `.xp/design.fsm` and
`.xp/loop.fsm`, each with its own per-story run record
(`.xp/<story-id>.design.run`, `.xp/<story-id>.loop.run`).

## How a session goes

1. **Query first, always.** Start every turn — and every turn after a
   context reset — with the bare query. It tells you your stage, that
   stage's guidance, and the legal moves with their missing evidence. Do not
   reconstruct your position from the conversation; the conversation is
   exactly what a reset destroys.

2. **Do the stage's work, attach what it produced, then advance.** Never
   attach evidence for work you did not do. The attachment is a claim the
   audit will test against the repository.

3. **At `STORY_SELECT`, derive the order — do not propose one.** Keep the
   deck and story set in `.xp/order.problem` and run:

   ```
   bin/xp-order                   # prints the order, marking each position
   ```

   Every position comes back `forced` (the deck left one candidate) or
   `chosen` (several were ready, priority decided). Report it that way. Never
   present a priority choice as a design constraint — that is manufacturing
   authority the deck did not give you. Attach the result as `order:`. If a
   `blocked` result comes back, that is a finding for the customer (a card no
   story realizes, or two stories in a dependency cycle), not an obstacle to
   route around.

4. **When refused, the refusal is the instruction.** A refusal names the
   missing keys. Produce them by working, not by attaching a plausible
   value.

5. **At `DESIGN`** (optional per story), switch to the design machine, walk
   it to `DESIGN_DONE`, and bring back `deck:`. The deck must pass the
   checker — `$RFC_SKILL/rfc-run --type crc <deck.crc>` — before the design
   run may leave `DECK`. Three responsibilities per card is the budget; if a
   card will not fit, split it. That refusal IS the design feedback.

6. **At `LOOP`**, switch to the loop machine and walk it to `LOOP_DONE`, then
   come back and attach `loop-complete:` to the session run.

## Rules that are yours to hold, because no guard can

- **The bound is a standing constant, and you never estimate a story.**
  It lives in `.xp/bound`, is attached unchanged at `SESSION_START`, and does
  not vary per story. Do not offer size estimates, points, or a per-story
  budget — estimates converge on one value, so the only real signal is
  fits/doesn't-fit. If the diff outgrows the bound, take `STORY_SPLIT`
  (session) or `ROLLBACK` (loop). Raising it to fit work already written is
  the one move that voids the whole scheme.
- **Never edit a surprising test until it fails the way you wanted.** A test
  that passes before you wrote anything, or fails for a reason you did not
  predict, is a discovery. Take `SURPRISE` and report it.
- **In `agent-navigator` mode, dispatch the navigator with fresh context** —
  a subagent, not this session. A navigator carrying your assumptions is a
  rubber stamp.
- **The deck is the system's, not the session's.** One `.xp/deck.crc`,
  extended per story. An orphaned card is a card to delete, not to keep for
  a future that may not arrive.
- **Do not write a metaphor you will not use.** Every declared term must
  become a card name; the checker enforces it, and a decorative metaphor is
  worse than none.
- **Keep the stream readable.** The human is navigating over the diff as it
  is written. Narrate what you are about to change before changing it, in
  one or two lines, and stop at every leg boundary so they can interrupt.

## Announcing

Say what stage you are entering and why, in one line, every time you
advance. The user should never have to ask where you are.
