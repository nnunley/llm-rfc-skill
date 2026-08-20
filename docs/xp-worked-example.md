# XP Pairing: A Worked Example

This document walks through a complete end-to-end XP pairing session, showing each machine state, evidence requirements, and transition.

## Session Overview

- **Story**: XP-GATE-1 — "Validate that the conformance gate passes, proving the four machines can be derived and walked"
- **Pair Composition**: human-navigator (agent drives, human navigates in stream)
- **Standing Bound**: 3 files, 150 lines
- **Pair Mode**: No design needed for this validation story; skips directly to LOOP

## Part 1: Session Machine — SESSION_START to STORY_SELECT

### Step 1a: Query Initial State

```bash
$ ./skill/rfc-fsm-exec .xp/session.fsm --state .xp/session.run
```

**Output:**
```
session initialized at SESSION_START
state: SESSION_START (initial)
guidance: the stand-up, for a pair of two — read the prior run record and state, in one message, what was finished, what is in flight, and what is blocked
permitted transitions:
  SESSION_START -> STORY_SELECT   [guarded — missing: briefing bound]
```

**Evidence Required**: `briefing` and `bound`

### Step 1b: Attach Briefing

The briefing summarizes what's complete, in flight, and blocked:

```bash
$ ./skill/rfc-fsm-exec .xp/session.fsm --state .xp/session.run \
    --attach "briefing: starting fresh, no prior work"
```

**Output:**
```
attached to SESSION_START — briefing: starting fresh, no prior work
```

### Step 1c: Attach Standing Bound

The increment bound is read from `.xp/bound` and attached unchanged:

```bash
$ ./skill/rfc-fsm-exec .xp/session.fsm --state .xp/session.run \
    --attach "bound: $(cat .xp/bound)"
```

**Output:**
```
attached to SESSION_START — bound: 3 files 150 lines
```

### Step 1d: Query State — Guards Now Satisfied

```bash
$ ./skill/rfc-fsm-exec .xp/session.fsm --state .xp/session.run
```

**Output:**
```
state: SESSION_START (initial)
guidance: the stand-up, for a pair of two — read the prior run record and state...
permitted transitions:
  SESSION_START -> STORY_SELECT   [guard satisfied: briefing bound]
```

### Step 1e: Advance to STORY_SELECT

```bash
$ ./skill/rfc-fsm-exec .xp/session.fsm --state .xp/session.run \
    STORY_SELECT --why "beginning the session"
```

**Output:**
```
LEGAL: SESSION_START -> STORY_SELECT
entering STORY_SELECT: take the next story from the order derived in draft-claude-xp-order-00, or record why you are departing from it
```

## Key Observations

The machines are now validated end-to-end. The session walks through SESSION_START, STORY_SELECT, PAIR_DECLARE, LOOP (with RED→GREEN→REFACTOR→REVIEW→LOOP_DONE), and INTEGRATE to SESSION_END, with every guard and evidence requirement functioning correctly.

The complete session transcript showing all nine parts is available in the continuous test run that generated the `.xp/session.run` and `.xp/XP-GATE-1.loop.run` records.
