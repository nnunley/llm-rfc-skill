# draft-ndn-cross-repo-00: Cross-Repository RFCs and Dependencies

**Status:** DRAFT
**Category:** Experimental
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)
**Date:** 2026-08-14

## Abstract

A draft may live in its author's own repository and be accepted into
another repository's series: the repository becomes the author's
identity, acceptance copies the text into the accepting series (which
assigns the number and freezes its own self-contained copy), and the
origin draft becomes a forwarding pointer — superseded, never deleted.
Series declare their foreign dependencies pinned, and cross-repository
citations get a compact forge reference form with the pin the doctrine
already requires.

## Motivation

The author token in draft names exists to make concurrent drafting
collision-free inside one shared repository. When a draft lives in its
author's own repository, the repository IS the namespace: git history is
the authorship record — signed, dated, and richer than a masthead line —
and the token becomes redundant. This is the IETF's individual-draft /
working-group-adoption split and the Rust RFC model at once: Rust drafts
live in the author's fork until the pull request merges, and the PR is
the review venue. Meanwhile real series already depend on each other
(one series pins another's tooling and cites its process BCP) with no
declared form; this document gives that practice its machinery.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **origin draft** — a draft in its author's repository, offered to
  another repository's series.
- **accepting series** — the series that reviews, publishes, and numbers
  the document.
- **repo identity** — the naming profile in which the repository carries
  authorship and draft names omit the author token.
- **acceptance** — the accepting series' publication of the offered
  text: its copy is canonical and self-contained from that moment.

## Specification

### Decentralization

The system is peer-to-peer and points outward only. No central index of
series exists, the tooling holds no knowledge of other repositories, and
adopting the process requires no registration anywhere — any repository
can run a series without any other repository knowing. Every
cross-repository relationship in this document is declared by the
repository that depends on it: citations, dependencies, and tracked
offers all live in the consumer. Nothing in this specification requires
a repository to enumerate, host, or aggregate the series of others.

Decentralization does not dilute the core. The core's final contents
are not yet fixed, but its center of gravity is the validation
meta-process under development in this series — RFC validation: lint,
evidence tangling and replay, declared corpus states, digest
verification, machine validation. Whatever the finalized core contains,
validation is in it: what makes a series a series is that its claims
are checked, and that machinery is REQUIRED wherever a series runs,
typically as its first pinned dependency. The asymmetry is the design:
the validation core is universal, the practices layered above it are
candidates each series adopts or declines on its own judgment.

### Cross-repository citations

A published RFC in another repository is cited compactly on the same
forge as `owner/repo#NNNN`, pinned with the commit the citing document
was verified against (`owner/repo#NNNN @ <sha>`); rendered links resolve
against the forge top level as absolute URLs. Across forges the longer
full-URL form is permitted. The supersession and amendment headers
(`Superseded-By:`, `Updates:`, `Obsoletes:`) accept cross-repository
references wherever they accept a bare number. [R-xrepo-citation]

```abnf
xrepo-ref   = same-forge / cross-forge
same-forge  = owner "/" repo-name "#" 4DIGIT [ pin ]
cross-forge = "https://" 1*VCHAR "#" 4DIGIT [ pin ]  ; longer, cross-forge only
pin         = " @ " 7*40HEXDIG
owner       = 1*( ALPHA / DIGIT / "-" )
repo-name   = 1*( ALPHA / DIGIT / "-" / "_" / "." )
```

```transcript @R-xrepo-citation
$ printf '# RFC 0001: X\n**Status:** SUPERSEDED\n**Superseded-By:** example/rfc-series#0003 @ 6571eae\n' > 0001-x.md
$ rfc-lint 0001-x.md 2>&1 | grep -c "Superseded-By"
0
? 1
$ printf '# RFC 0002: Y\n**Status:** SUPERSEDED\n**Superseded-By:** somewhere else entirely\n' > 0002-y.md
$ rfc-lint 0002-y.md 2>&1 | grep -c "Superseded-By"
1
$ printf '# draft-a-x-00: X\n**Status:** DRAFT\n**Updates:** example/rfc-series#0002 @ 1234abc\n' > draft-a-x-00.md
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "must list"
0
? 1
```

### Repo identity (coexisting naming profile)

A series whose repository carries authorship MAY declare the repo
identity profile: the file `identity` beside the RFCs, first effective
line `repo`. Under it, draft names omit the author token —
`draft-<slug>-NN.md` — because the repository is the collision scope and
git history is the authorship record. The author-token forms remain the
default and the two profiles coexist across the ecosystem; no series is
forced to rename. [R-repo-identity]

```transcript @R-repo-identity
$ mkdir solo
$ printf 'repo\n' > solo/identity
$ printf '# draft-widget-00: W\n**Status:** DRAFT\n' > solo/draft-widget-00.md
$ rfc-lint solo/draft-widget-00.md 2>&1 | grep -c "filename must be"
0
? 1
$ printf '# draft-widget-00: W\n**Status:** DRAFT\n' > draft-widget-00.md
$ rfc-lint draft-widget-00.md 2>&1 | grep -c "filename must be"
1
```

### Submission and acceptance

Where the forge supports it, submission is a pull request from the
author's repository into the accepting series — the PR is the review
venue and its thread the consensus record; merge is acceptance. A series
MAY instead (or additionally) track offered drafts as pinned remote
references; the PR form is RECOMMENDED where available.

Acceptance is publication in the accepting series: the text is copied
in, numbered from the accepting index, retitled, and frozen — the
accepted copy MUST be self-contained, depending on nothing in the origin
repository. The origin draft then becomes a forwarding pointer: status
`SUPERSEDED` with a cross-repository `Superseded-By:` naming the
accepted RFC. Deletion of the origin is tolerated (it is the author's
repository, and the canonical copy no longer needs it) but supersession
is RECOMMENDED — citations to the origin keep resolving to a forwarding
address. A draft-named document with `SUPERSEDED` status is exactly this
case, and is legal only with its `Superseded-By:` present.
[R-xrepo-supersede]

```transcript @R-xrepo-supersede
$ mkdir origin series
$ printf 'repo\n' > origin/identity
$ printf '# RFC 0007: W\n**Status:** PUBLISHED\n' > series/0007-widget.md
$ printf '# draft-widget-00: W\n**Status:** SUPERSEDED\n**Superseded-By:** example/series#0007 @ 6571eae\n' > origin/draft-widget-00.md
$ rfc-lint origin/draft-widget-00.md 2>&1 | grep -c "publishing assigns the number"
0
? 1
$ rfc-lint origin/draft-widget-00.md 2>&1 | grep -c "Superseded-By"
0
? 1
```

### Declared dependencies

A series depending on another repository's RFCs or tooling declares it:
the file `dependencies` beside the RFCs, one line per dependency —
`<name> <absolute-forge-url> <sha>` — comments and blank lines ignored.
The pin is REQUIRED: a conformance verdict produced against moving
dependencies is no verdict. Lint validates the file's form when present;
CI SHOULD resolve the pins when foreign citations or foreign tooling are
exercised. [R-xrepo-deps]

```transcript @R-xrepo-deps
$ printf '# pinned foreign series\nprocess https://github.com/example/rfc-skill 6571eae\n' > dependencies
$ printf '# draft-a-x-00: X\n**Status:** DRAFT\n' > draft-a-x-00.md
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "malformed"
0
? 1
$ printf 'unpinned https://github.com/example/rfc-skill\n' > dependencies
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "malformed"
1
```

### Foreign adapters: dependencies carry executable vocabulary

Adapters are this system's general extension surface, and dependencies
carry them: a declared dependency MAY supply evidence adapters, sandbox
providers, and vocabularies, which consumers resolve through the seams
that already exist (`RFC_ADAPTER_PATH`, `RFC_SANDBOX_PATH` pointed at
the pinned checkout's directories). The pin governs what executes; the
hard-error resolution gates apply unchanged — a foreign adapter that
fails to resolve is a loud failure, never a silent skip. A series
SHOULD consume a foreign vocabulary through its home series' adapter
rather than reimplementing it: one vocabulary, one adapter, many
consumers. [R-xrepo-adapters]

```transcript @R-xrepo-adapters
$ mkdir -p dep/adapters
$ printf '#!/bin/sh\ngrep -q "^ok" "$1"\n' > dep/adapters/foreign-vocab
$ chmod +x dep/adapters/foreign-vocab
$ printf 'ok\n' > sample.foreign-vocab
$ RFC_ADAPTER_PATH=$PWD/dep/adapters rfc-run --type foreign-vocab sample.foreign-vocab
? 0
$ rfc-run --type foreign-vocab sample.foreign-vocab
rfc-run: no adapter found for type foreign-vocab
? 1
```

## Alternatives Considered

### Deletion of the origin draft on acceptance

Simpler housekeeping. Rejected as the recommended path: deletion breaks
every plan, commit, and conversation that cited the draft and buys
nothing, since the accepted copy is already canonical. The design
tolerates deletion (no one can force retention in another's repository)
precisely because acceptance copies the text — a dead origin link
degrades provenance, never the published record. IETF precedent:
replaced drafts remain in the archive, marked Replaced.

### Repo identity replaces author tokens everywhere

Cleaner future, rejected for forcing renames and conventions on
shared-repository workflows — the profiles coexist, each correct for its
collision scope.

### A central registry of series

A cross-repository index mapping names to repositories. Rejected as
premature coordination: forge references are already resolvable, pins
already carry the verification point, and a registry can be layered on
later without changing the citation form.

## Security Considerations

Acceptance imports text authored outside the accepting repository's
review history: the accepting series' adversarial review and evidence
gates apply to the imported text in full — provenance is not a
substitute for review. Pinned dependencies are trusted code and trusted
citations; changing a pin is reviewed as an evidence change, and CI
resolving unpinned or tag-mutable references would let a foreign push
alter a local verdict — hence the REQUIRED sha. A malicious origin
repository can rewrite its history after acceptance; the accepting
copy's self-containment is the defense, and the pin records what was
actually reviewed.

## References

- The process BCP: draft-ndn-authoring-rfcs-00 — identity, supersession,
  and pinning doctrine this document extends; its status-form rule is
  relaxed by exactly one combination (draft + SUPERSEDED with a
  cross-repository forwarding pointer).
- Rust RFC process — fork-resident drafts, PR-as-review-venue,
  merge-as-acceptance. https://github.com/rust-lang/rfcs
- IETF individual drafts vs working-group adoption; replaced drafts
  remain archived (RFC 2026).

## Changelog

- 2026-08-14: draft-00 created from the design conversation: repository
  as authorship identity (coexisting profile, `identity` file),
  fork+PR-preferred submission with tracked-remote fallback,
  acceptance-copies-then-supersedes (never deletes) with draft-named
  SUPERSEDED legalized as the cross-repo forwarding signature,
  `owner/repo#NNNN @ sha` citations with absolute forge-top-level links
  (full-URL form across forges), and pinned `dependencies` declarations.
  Evidence is red until rfc-lint gains the four extensions (spec-first).
- 2026-08-14: decentralization stated as a design invariant on author
  review — the system points outward only: no central index, no
  registration, no repository required to know about any other; all
  cross-repo relationships live in the consumer. The home series is a
  canonical exploration core, open, not exclusive, not a global catalog.
- 2026-08-14: the core/practice asymmetry stated on author review —
  decentralization governs who knows about whom, not what conformance
  means. The core is not yet finalized; its named center of gravity is
  the validation meta-process (RFC validation: lint, evidence replay,
  declared corpus states, digest and machine verification), required
  everywhere a series runs (typically the first pinned dependency),
  while practices remain per-series choices.
