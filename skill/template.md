<!-- Structure and boilerplate derived from IETF practice (RFC 7322 style,
     BCP 14/RFC 8174); Specification body shape derived from NLSpec
     (jhugman/nlspec). Original guidance prose: CC0 — copy freely, owe nothing. -->

# draft-author-slug-00: Title In Plain Words

<!-- Unpublished: filename and this title are draft-<author>-<slug>-NN.
     At publication both become RFC NNNN (number taken from index.md). -->

**Status:** DRAFT
<!-- Optional: declare expected evidence state (absent = green):
**Corpus:** red (spec-first — evidence is the acceptance criteria)
-->
**Category:** Standards-Track (normative) | Informational | Experimental
**Authors:** Name <email>
<!-- Optional headers — add only with real values (4-digit RFC numbers):
       **Obsoletes:** NNNN       full replacement of a published RFC
       **Updates:** NNNN         partial amendment, original stays authoritative
       **Superseded-By:** NNNN   set on the OLD RFC when its successor publishes
       **Objections-By:** YYYY-MM-DDTHH:MM:SSZ   the LAST-CALL objection deadline -->


## Abstract

Two to four sentences: what this is and who it is for. No background, no
justification — that is Motivation's job.

## Motivation

Three parts, in order: the current state; what is wrong or absent, with
concrete evidence of what it breaks or costs; one sentence on what this
document provides. Why now.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

Define each term on first use and use only that name afterwards — no
synonyms for defined terms. One per line:

- **term** — definition.

## Specification

<!-- The normative core, shaped so an agent with no other context can
     implement from it. Every requirement uses an uppercase BCP 14 keyword;
     everything lowercase is description, not requirement. State observable
     behavior in present tense ("the registry rejects…"), give the reason
     AFTER the rule, and state design constraints negatively where that
     bounds the system ("the engine does not know handler internals").
     Reorder or drop the subsections below to fit the domain — the shape
     is guidance, the markers and evidence are the contract. -->

This document defines <X>: <the concerns it owns, listed>. It does NOT
define <Y>; <Y> is owned by <other RFC or layer>.

**Principle name.** One or two sentences naming a constraint an
implementation can be found to violate — not an aspiration. Repeat per
principle; keep to the few that actually decide things.

### Data model

<!-- Vocabulary and structure before behavior. Declarations are DESCRIPTIVE:
     they fix the reading of a requirement and prove nothing, so they use a
     plain fence and never carry an @R- tag. Keywords UPPER CASE, comments
     with --, snake_case names, PascalCase types, UPPER_CASE enum values. -->

```
RECORD Thing:
    name        : String              -- what the field is for, not just its type
    retries     : Integer = 0         -- inline default for a simple value
    parent      : Thing | None        -- optional relation

ENUM State:
    ACTIVE      -- what this value means
    RETIRED     -- ...
```

**Field constraints:** rules beyond the type (allowed characters, ranges,
formats), as bold-lead paragraphs right after the declaration.

An ENUM whose values drive behavior is followed by a classification table
whose Meaning column says what the system DOES, not what the name means.
A state-bearing ENUM whose values are lifecycle stages is an `fsm` block
instead (verified, and its diagram is derived).

| State     | Meaning                                              |
|-----------|------------------------------------------------------|
| `ACTIVE`  | Accepts writes. Counted in quota.                     |
| `RETIRED` | Rejects writes with `E_RETIRED`. Excluded from quota. |

### Configuration

<!-- Every configurable value has an explicit default. A value without a
     default is a value the implementer will guess. -->

| Key         | Type     | Default | Description                        |
|-------------|----------|---------|------------------------------------|
| `timeout`   | Duration | `30s`   | Maximum time per attempt           |
| `max_tries` | Integer  | `1`     | Attempts before the fallback chain |

Defaults are stated with their rationale, so a later author does not
change one without meeting the reason.

**Resolution precedence** (highest first; the last entry is the terminal
default — a hierarchy that does not end in a default is incomplete):

1. Command-line flag
2. Environment variable
3. Series profile file
4. Default from the table above

### Behavior

<!-- Requirements with markers and evidence, in NLSpec's example order:
     minimal case first, then one feature at a time, then composition. -->

The registry MUST reject a duplicate name. [R-no-dup-names]
The rule protects <invariant>; without it <what breaks>.

```transcript @R-no-dup-names
$ command under test
expected output
? 1
```

Where an algorithm has more than one step, state it as pseudocode with
labeled steps (descriptive — plain fence, no tag) and put edge cases IN
the pseudocode, not in separate prose; then follow with a **Behavior:**
summary of the contract in human terms.

```
FUNCTION register(name, path) -> Outcome:
    -- Step 1: reject duplicates
    IF registry.has(name):
        RETURN Outcome(FAIL, "already registered")
    -- Step 2: record
    registry.set(name, path)
    RETURN Outcome(SUCCESS)

-- Behavior:
--   - Never overwrites an existing entry
--   - Returns SUCCESS only after the entry is durable
```

**Fallback chain** (each step names what happens when the one before is
unavailable; the last step terminates, never falls through):

1. Preferred path: do X if <condition>
2. Secondary path: do Y if X is unavailable
3. Terminal path: fail with `<specific error>`

**Procedural sequence** (fixed order, every step runs — for operations at
a system boundary such as shutdown, publication, migration):

1. First step
2. Second step
3. Final step

Evidence pairs with markers in both directions (lint-enforced) and
`rfc-tangle` extracts blocks for the type's deterministic runner. Choose
the type by least indirection: `transcript` for CLI and session behavior,
an evidence table (`<!-- evidence: @R-<slug> -->` above it, one row per
case) for rule surfaces and validation matrices, `abnf` with witness rows
for syntax, `fsm` for state machines. Markers are permanent once
published — later RFCs and plans reference them.

### Errors

<!-- Every error category names its recovery. A category without one is
     incomplete. -->

| Error          | Example                        | Recovery                          |
|----------------|--------------------------------|-----------------------------------|
| `E_DUPLICATE`  | registering `api` twice        | Reject; suggest `--force`         |
| `E_UNREACHABLE`| target path does not exist     | Reject; leave registry unchanged  |

An **escape hatch** — a deliberate bypass of an abstraction for what it
cannot cover — is documented as a decision, with the warning that what
uses it is not portable.

## Formal Grammar

Machine-checkable syntax for anything with a wire/file/CLI format, in ABNF
(RFC 5234; RFC 7405 for case-sensitive strings) inside ```abnf fences —
rfc-lint validates rule syntax and that every referenced rule is defined.
The grammar defines what can be written; what it means is in Specification.

```abnf
registry-key   = %s"issue.repo." repo-name %s".path"
repo-name      = 1*( ALPHA / DIGIT / "-" / "_" )
```

Delete this section only if the RFC defines no syntax at all.

## Out of Scope

<!-- Capabilities considered and deliberately NOT specified — distinct from
     Alternatives Considered, which records rejected designs for what IS
     specified. Four parts per entry; the extension point is what turns
     "not now" into a known seam. Omit the section if every exclusion is
     obvious. -->

**Excluded capability.** What it is, in one sentence. Why it is excluded
(often: which layer owns it instead). Extension point: the section,
marker, adapter type, or profile where it would attach if adopted later —
or the statement that no seam exists, which is itself a finding.

## Alternatives Considered

<!-- One entry per rejected design, headed by a bold question that NAMES
     the rejected alternative, so whoever is about to re-propose it finds
     it by its own name. An RFC with no alternatives is an announcement,
     not a proposal. Where a rejection bears on one rule only, also put a
     one-sentence note beside that rule. -->

**Why not <the rejected alternative>?** What it was; why it lost.

## Security Considerations

What this change lets an attacker or accident do that it could not before —
inputs crossing trust boundaries, paths/commands executed, data exposed.
"None" requires an argument, not an assertion.

## Compatibility

Effect on existing installs, data, and workflows. Migration path if any.
Data that ages (versions, catalogs, prices, a pinned external revision)
is introduced with a temporal anchor: "At the time of writing (Month
YYYY), …".

## References

- RFC/doc links this proposal depends on or relates to, with full URLs
  for anything that is not a stable identifier (RFC numbers are).
- Reference projects, if any: name with URL, language, one sentence on
  the pattern worth studying — exemplars, not dependencies.

<!-- No Date header and no Changelog section: the commit log is the
     document's history — the rendered page derives created/updated from
     git, and
     messages under Commit discipline carry what changed and why —
     never restated in-band. -->

<!-- Appendices (if any) follow References, lettered A, B, …, each
     referenced from the body: attribute catalogs, error catalogs, long
     examples. Do NOT write a Definition of Done: the derived digest
     (rfc-render-llm) is the checklist — exactly the marked requirements,
     verified equal to the source — and a marker's evidence, never a
     checkbox, is its record. -->
