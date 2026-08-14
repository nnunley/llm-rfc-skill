<!-- Structure and boilerplate derived from IETF practice (RFC 7322 style,
     BCP 14/RFC 8174). Original guidance prose: CC0 — copy freely, owe nothing. -->

# draft-author-slug-00: Title In Plain Words

<!-- Unpublished: filename and this title are draft-<author>-<slug>-NN.
     At publication both become RFC NNNN (number taken from index.md). -->

**Status:** DRAFT
**Category:** Standards-Track (normative) | Informational | Experimental
**Authors:** Name <email>
**Date:** YYYY-MM-DD
<!-- Optional headers — add only with real values (4-digit RFC numbers):
       **Obsoletes:** NNNN       full replacement of a published RFC
       **Updates:** NNNN         partial amendment, original stays authoritative
       **Superseded-By:** NNNN   set on the OLD RFC when its successor publishes -->


## Abstract

Two to four sentences: what this proposes and why a reader should care. No
background, no justification — that is Motivation's job.

## Motivation

The problem as it exists today, with concrete evidence. What breaks or costs
without this change. Why now.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

Define project-specific terms here, one per line:

- **term** — definition.

## Specification

The normative core. Every requirement uses an uppercase BCP 14 keyword;
everything lowercase is description, not requirement. Structure freely with
`###` subsections (storage, commands, wire format, error behavior, ...).
State observable behavior, not implementation steps.

Give each provable requirement a stable ID at the end of its sentence, of
the form `[R-<your-slug>]` (lowercase, hyphens). Prove it with an evidence
block embedded right beside it — a fenced block whose info string names an
evidence type and carries the tag:

    ```transcript @R-<your-slug>
    $ command under test
    expected output
    ```

Pairing is lint-enforced both directions; `rfc-tangle` extracts blocks for
the type's deterministic runner. IDs are permanent once published — later
RFCs and plans reference them.

## Formal Grammar

Machine-checkable syntax for anything with a wire/file/CLI format, in ABNF
(RFC 5234; RFC 7405 for case-sensitive strings) inside ```abnf fences —
rfc-lint validates rule syntax and that every referenced rule is defined:

```abnf
registry-key   = %s"issue.repo." repo-name %s".path"
repo-name      = 1*( ALPHA / DIGIT / "-" / "_" )
```

Delete this section only if the RFC defines no syntax at all.

## Alternatives Considered

Each rejected design, one `###` per alternative: what it was, why it lost.
An RFC with no alternatives considered is a decision announcement, not a
proposal.

## Security Considerations

What this change lets an attacker or accident do that it could not before —
inputs crossing trust boundaries, paths/commands executed, data exposed.
"None" requires an argument, not an assertion.

## Compatibility

Effect on existing installs, data, and workflows. Migration path if any.

## References

- RFC/doc links this proposal depends on or relates to.

## Changelog

- YYYY-MM-DD: DRAFT created.
