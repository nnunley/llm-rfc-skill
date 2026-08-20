# draft-claude-xp-dependencies-00: Dependency Existence and Provenance

**Status:** DRAFT
**Category:** Experimental
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-20

## Abstract

Agents recommend packages that do not exist, and attackers register the
names they invent. This document specifies an offline, deterministic check
over a declared dependency inventory: a package imported by code MUST be
declared, a package declared MUST resolve in a lockfile, and every
dependency MUST trace to the story that introduced it. Registry existence is
deliberately excluded from the conformance corpus — it needs the network, so
it belongs in CI, and simulating it in a transcript would manufacture proof
rather than obtain it.

## Motivation

The USENIX Security 2025 study of package hallucination generated 2.23
million code samples across sixteen code-generating models and found that
**19.7% of recommended packages do not exist**, yielding more than 205,000
unique fabricated names. Attackers pre-register those names — the practice
is called slopsquatting — and a hallucinated dependency then resolves to
code an adversary controls. One such package has been observed propagating
through hundreds of repositories via agent-authored skills, with downloads
driven by agents executing their own generated output rather than by people
copying code.

This is the sharpest form of the accretion problem the rest of this series
addresses, because it is the one where accretion is directly exploitable. It
is also the one an agent is least equipped to catch in itself: the
hallucinated name is plausible by construction, it appears in an import
statement that looks like every other import statement, and the agent that
wrote it has no memory of inventing it.

The useful observation is that the two loudest signals need no network at
all. A fabricated name is **imported but declared nowhere**, because the
agent wrote the import and never updated the manifest; or it is **declared
but resolves to nothing**, because a name that does not exist cannot be
locked. Both are answerable from files already in the repository, which
means they can be deterministic corpus evidence rather than a network call
whose result varies with the weather.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **dependency inventory** — the declared description of what the project
  depends on: manifest entries, lockfile resolutions, imports, and the story
  each dependency came from. The seam; a project generates it however its
  ecosystem allows.
- **undeclared** — imported by code, present in no manifest, and neither
  standard library nor vendored.
- **unresolved** — present in a manifest, resolved in no lockfile.
- **unused** — declared, imported by nothing.
- **unattributed** — declared with no originating story.
- **expired** — its originating story serves a retired target.

## Specification

### An import must be declared

A package imported by code MUST appear in a manifest, unless declared
standard library or vendored. An undeclared import is the signature of a
fabricated name: the agent wrote the import from its own expectation of what
exists, and no human or resolver ever confirmed it. [R-deps-declared]

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

### A declaration must resolve

A package present in a manifest MUST resolve in a lockfile. A name that does
not exist cannot be locked, so an unresolved declaration is a fabricated
name that reached the manifest — the state immediately before an attacker's
registration turns it into a live supply-chain compromise.
[R-deps-resolved]

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

### A dependency must be attributable

Every declared dependency MUST name the story that introduced it, and a
dependency whose story serves a retired target MUST be reported as expired.
A dependency is the most consequential thing an agent can add — it is code
the project did not write, executing with the project's privileges — and it
is currently the easiest thing to add without anyone deciding to. Requiring
provenance makes adding one a recorded decision rather than a side effect,
and makes removing one an argument from the record rather than a guess.
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
published, which is the slopsquatting signature that offline checks cannot
see — requires the network. Such a check MUST run in CI against the real
registry and MUST NOT be represented as corpus evidence. A transcript that
simulates a registry response proves only that the simulation was written to
agree with the assertion; it is manufactured proof, and it is more dangerous
than no check at all because it reports green.

This requirement carries no `[R-]` marker deliberately. It is a prohibition
on a category of evidence rather than a behaviour a block can demonstrate,
and marking it would invite exactly the fabricated block it forbids.

A CI dependency check SHOULD additionally flag a package whose first
publication postdates the code that imports it, since a name invented by a
model and registered by an attacker is necessarily younger than the
suggestion that named it.

## Formal Grammar

```abnf
inventory  = *( statement LF )
statement  = manifest-s / locked-s / imports-s / stdlib-s / vendored-s / origin-s
manifest-s = %s"manifest" 1*WSP pkg [ 1*WSP version ]
locked-s   = %s"locked" 1*WSP pkg 1*WSP version
imports-s  = %s"imports" 1*WSP unit 1*WSP pkg
stdlib-s   = %s"stdlib" 1*WSP pkg
vendored-s = %s"vendored" 1*WSP pkg
origin-s   = %s"origin" 1*WSP pkg 1*WSP story-id
pkg        = ALPHA *( ALPHA / DIGIT / "-" / "_" / "." / "/" / "@" )
version    = 1*( DIGIT / ALPHA / "." / "-" / "+" )
unit       = ALPHA *( ALPHA / DIGIT / "_" / "-" )
story-id   = ALPHA *( ALPHA / DIGIT / "-" / "_" )
```

Target, story, `serves`, and `retired` statements are shared with
draft-claude-xp-grooming-00.

## Alternatives Considered

### Checking the registry inside the corpus

Query npm or PyPI during conformance. Rejected: the corpus must be
deterministic and runnable offline, and a check whose result depends on
network reachability turns every disconnected run into a false failure.
Worse, the obvious workaround — recording a response and replaying it —
produces a block that passes because it was written to.

### Trusting the resolver

Argue that a hallucinated package simply fails to install, so no check is
needed. Rejected: that is true only until someone registers the name, which
is precisely the attack. The window between an agent inventing a name and an
attacker claiming it is the whole exposure, and an unresolved manifest entry
is the only in-repository evidence that the window is open.

### Allowlisting dependencies

Maintain an approved list. Rejected as a heavier mechanism that answers a
different question: an allowlist says what is permitted, not whether what is
present exists or why it was added. The provenance requirement gets the
"why" at lower cost, and the existence checks get the "whether".

### Scanning source directly for imports

Parse the code rather than read a declared inventory. Rejected here for the
same reason as in draft-claude-xp-entropy-00 — it binds the specification to
one language's toolchain — but a project generating its inventory from real
import analysis SHOULD do so, since a hand-maintained inventory drifts from
the code and a drifted inventory reports fiction.

## Security Considerations

This document is a security control, and its failure modes matter more than
most in this series.

An inventory that omits an import hides exactly the dependency an attacker
wants hidden. A hand-maintained inventory therefore weakens the control in
proportion to how stale it is, and one generated by the same agent that
wrote the imports inherits that agent's blind spots. Generating it from the
resolver or the import graph is the difference between a control and a
comment.

The `unused` finding creates pressure to delete dependencies, and a
dependency invoked only through a plugin registry, an entry point, or
reflection appears unused every run. Deleting one on that evidence removes
working code and possibly a control; as with the entropy sweep, findings are
reported and never acted on automatically.

The offline checks close the window between invention and registration but
not the case where the attacker registered first. That case has no
in-repository signature — the name resolves, the lockfile is satisfied, and
every check here passes — which is why the CI registry check and its
publication-date heuristic are REQUIRED rather than optional, and why this
document says so despite not being able to prove it in its own corpus.

## Compatibility

Adds one evidence type, `deps`, and one evidence key to
draft-claude-xp-pairing-00's `INTEGRATE` guard. Projects that produce no
dependency inventory cannot satisfy the guard, which means adopting this
document means writing an inventory generator first, as its own story.

## References

- Spracklen et al., "We Have a Package for You! A Comprehensive Analysis of
  Package Hallucinations by Code Generating LLMs", USENIX Security 2025 —
  2.23M samples, 16 models, 19.7% non-existent packages.
- Slopsquatting, named by Seth Larson (Python Software Foundation).
- draft-claude-xp-entropy-00 — the code-layer sweep this parallels at the
  dependency layer.
- draft-claude-xp-grooming-00 — targets and retirement, which `expired`
  reads.
- RFC 5234 (ABNF), RFC 2119, RFC 8174 (BCP 14).

## Changelog

- 2026-08-20: DRAFT created. Offline dependency existence and provenance:
  imports must be declared, declarations must resolve, dependencies must
  trace to a story. Registry existence is placed in CI and explicitly
  excluded from corpus evidence, with the prohibition left unmarked because
  marking it would invite the fabricated block it forbids.
