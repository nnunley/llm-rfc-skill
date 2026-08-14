# draft-ndn-authoring-rfcs-00: The RFC Process for Human–LLM Specification Authoring

**Status:** LAST-CALL
**Category:** BCP
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)
**Date:** 2026-08-14

## Abstract

A process for one or more humans and one or more LLM agents to
collaboratively produce software specifications as an RFC series: numbered,
immutable-once-published documents with formal requirement language,
embedded machine-verifiable evidence, and a cumulative conformance corpus
that prevents agents from regressing previously established requirements.
This document specifies the mechanical rules (verified by `rfc-lint`
against this document's own evidence) and the practice around them.

## Motivation

Prose specifications drift, and agent-authored work resets its obligations
with every fresh context: what was promised last week is invisible to the
model implementing this week. Existing remedies each miss a piece —
session-scoped planning pipelines produce artifacts without durable
identity; mutable living-spec trees record current behavior but not
decisions, alternatives, or consent; test suites verify behavior but are
unreadable as specification. The gap is a process whose artifacts carry
decisions permanently, whose requirements are stated formally, and whose
evidence is checkable both by a person at a glance and by a deterministic
tool — with obligations that accumulate across contexts, authors, and
years rather than resetting.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **RFC** — a published, numbered, frozen specification document.
- **draft** — an unpublished document named `draft-<author>-<slug>-NN.md`;
  the unit of proposal and revision.
- **requirement marker** — a stable ID of the form `[R-<slug>]` attached to
  a provable requirement sentence.
- **evidence block** — a typed fenced block (or tagged table) embedded in
  the document, tagged `@R-<slug>`, proving its marked requirement.
- **conformance corpus** — the tangled evidence of all published RFCs in a
  series, run whole by CI.
- **fast track / full track** — publication with lazy consensus versus
  publication gated by a LAST-CALL window.

## Specification

### Evidence conventions

Transcripts in this document follow the sandbox conventions established in
the registry RFC's evidence contract, with one addition: the runner
provides `rfc-lint` and `rfc-tangle` on `PATH`. The sandbox neutralizes
system-level git configuration as well as global (`GIT_CONFIG_NOSYSTEM=1`);
host excludes files and system options never reach a transcript. Fixture
documents are created inline; assertions project deterministic output with
`grep -c` and assert exit status with `? N` (absent means 0). One notation
limit is normative: an expected-output line beginning `$ ` cannot be
expressed literally (it reads as a command) — such output is asserted
through a projection instead.

### Document identity

Unpublished documents MUST be named `draft-<author>-<slug>-NN.md` and
published documents `NNNN-slug.md`, per the Formal Grammar; the document
title line MUST repeat the identity (`# draft-...:` or `# RFC NNNN:`).
Author-scoped draft names require no coordination between concurrent
authors, human or agent. [R-identity]

```transcript @R-identity
$ printf '# RFC 0001: X\n' > bad-name.md
$ rfc-lint bad-name.md 2>&1 | grep -c "filename must be"
1
$ rfc-lint bad-name.md >/dev/null 2>&1
? 1
```

<!-- evidence: @R-identity -->
| filename                     | valid |
|------------------------------|-------|
| draft-ndn-registry-00.md     | yes   |
| draft-claude-registry-03.md  | yes   |
| 0001-registry.md             | yes   |
| registry-design.md           | no    |
| draft-Ndn-registry-00.md     | no    |

### Status machine

Every document MUST carry a `**Status:**` line whose value is one of
`DRAFT`, `LAST-CALL`, `PUBLISHED`, `SUPERSEDED`, `WITHDRAWN`, or
`HISTORIC`. [R-status-vocab] Status MUST agree with the filename form:
draft-named documents are unpublished (`DRAFT`, `LAST-CALL`, `WITHDRAWN`)
and numbered documents are published (`PUBLISHED`, `SUPERSEDED`,
`HISTORIC`) — numbers do not exist before publication. [R-status-form]

```transcript @R-status-vocab
$ printf '# draft-a-x-00: X\n**Status:** APPROVED\n' > draft-a-x-00.md
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "invalid status"
1
```

```transcript @R-status-form
$ printf '# RFC 0001: X\n**Status:** DRAFT\n' > 0001-x.md
$ rfc-lint 0001-x.md 2>&1 | grep -c "numbered RFCs are published by definition"
1
$ printf '# draft-a-y-00: Y\n**Status:** PUBLISHED\n' > draft-a-y-00.md
$ rfc-lint draft-a-y-00.md 2>&1 | grep -c "publishing assigns the number"
1
```

### Required structure

Every document MUST contain the sections Abstract, Motivation, Terminology,
Specification, Alternatives Considered, Security Considerations,
References, and Changelog. [R-sections] An RFC without alternatives is an
announcement, not a proposal; a Security Considerations of "none" takes an
argument, not an assertion.

```transcript @R-sections
$ printf '# draft-a-x-00: X\n**Status:** DRAFT\n' > draft-a-x-00.md
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "missing required section"
8
```

### Formal language

Requirements are stated with uppercase BCP 14 keywords; a document using
them MUST carry the BCP 14 boilerplate in Terminology. [R-bcp14] Lowercase
keyword lookalikes inside the Specification are flagged as ambiguity
warnings — inside evidence fences they are exempt, so evidence content is
never policed as prose. Syntax defined by the document is expressed in
ABNF (RFC 5234), which the linter validates for rule-definition syntax,
undefined references, and duplicate definitions [R-abnf]; grammars carry
concrete valid/invalid witnesses as their checkable shadow.

```transcript @R-bcp14
$ printf '# draft-a-x-00: X\n**Status:** DRAFT\n## Specification\nIt MUST work.\n' > draft-a-x-00.md
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "lacks the BCP 14 boilerplate"
1
```

```transcript @R-abnf
$ printf '# draft-a-x-00: X\n**Status:** DRAFT\n```abnf\nfoo = bar\n```\n' > draft-a-x-00.md
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "undefined rule bar"
1
```

### Embedded evidence

A provable requirement carries a `[R-<slug>]` marker; its evidence is
embedded in the same document as a typed fenced block tagged `@R-<slug>`
or a table preceded by `<!-- evidence: @R-<slug> -->`. Pairing MUST be
bidirectional — a marker without evidence and evidence without a marker
are both errors — and evidence blocks MUST be non-empty. [R-evidence-pair]
`rfc-tangle` extracts each block verbatim into its type's native file for
the type's deterministic runner. [R-tangle] Evidence types are chosen by
least indirection: session transcripts for CLI and interactive behavior,
row tables for rule surfaces, ABNF witnesses for syntax. Every artifact
is checkable by a person at a glance AND by a deterministic tool; LLM
agents author artifacts and are never the verifier.

```transcript @R-evidence-pair
$ printf '# draft-a-x-00: X\n**Status:** DRAFT\nIt MUST work. [R-works]\n' > draft-a-x-00.md
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "no embedded evidence block tagged @R-works"
1
```

```transcript @R-tangle
$ printf '# draft-a-x-00: X\n**Status:** DRAFT\nWorks. [R-w]\n```transcript @R-w\n$ true\n```\n' > draft-a-x-00.md
$ rfc-tangle draft-a-x-00.md out
out/draft-a-x-00.w.transcript
$ grep -c '^\$ true$' out/draft-a-x-00.w.transcript
1
```

### Lifecycle

Publication assigns the number: the next number is taken from the series
`index.md`, the file is renamed and retitled, status becomes `PUBLISHED`,
and the index entry is committed — concurrent publications collide on the
index, and that merge conflict is the allocation lock. A published RFC is
frozen: modification in the working tree is a lint error, and the sole
permitted edit is setting `SUPERSEDED` with its `**Superseded-By:**` link
when a successor publishes. [R-immutable] A document in `SUPERSEDED`
status MUST name its successor. [R-supersede] A document in `LAST-CALL`
MUST state its objection deadline in the Changelog. [R-lastcall]
Full replacement uses `Obsoletes:`; partial amendment uses `Updates:` and
replaces only the requirement IDs it names; retirement without a successor
is `HISTORIC`; dead drafts are `WITHDRAWN`. Requirement IDs are permanent
once published, and the tangled evidence of every published RFC runs as
one corpus in CI — work on one RFC cannot silently regress another's
requirements.

```transcript @R-immutable
$ git init -q .
$ printf '# RFC 0001: X\n**Status:** PUBLISHED\n' > 0001-x.md
$ git add 0001-x.md
$ git commit -q -m publish
$ printf 'edit\n' >> 0001-x.md
$ rfc-lint 0001-x.md 2>&1 | grep -c "uncommitted modifications"
1
```

```transcript @R-supersede
$ printf '# RFC 0001: X\n**Status:** SUPERSEDED\n' > 0001-x.md
$ rfc-lint 0001-x.md 2>&1 | grep -c "requires '\*\*Superseded-By:\*\*"
1
```

```transcript @R-lastcall
$ printf '# draft-a-x-00: X\n**Status:** LAST-CALL\n' > draft-a-x-00.md
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "objections by YYYY-MM-DD"
1
```

### Practice (normative prose)

The authoring path is research, interview, synthesis, formalize — in that
order, scaled to stakes but never skipped: prior art is searched (including
the internet RFC index) before writing; requirements are elicited from the
humans who hold them one question at a time; the design is approved in
brief before formal drafting begins. Publication defaults to the fast
track — draft, lint clean, publish under lazy consensus, where publishing
is the review request and late objections are met with updating or
superseding drafts. The full track inserts a LAST-CALL window when more
than one party holds a veto, when published normative behavior changes,
when a trust boundary is crossed, or when the document standardizes across
projects. Consensus is rough (RFC 7282): objections are addressed, not
necessarily withdrawn, and humans adjudicate when contested. Any
participant, human or agent, is welcome as author, reviewer, or objector.

## Formal Grammar

```abnf
draft-file = %s"draft-" author "-" slug "-" 2DIGIT %s".md"
rfc-file   = 4DIGIT "-" slug %s".md"
author     = 1*( lower / DIGIT )
slug       = 1*( lower / DIGIT / "-" )
lower      = %x61-7A
```

Witnesses are the filename table under Document identity.

## Alternatives Considered

### Session-scoped planning pipelines

Brainstorm/plan/execute flows produce good specifications with no durable
identity: the artifacts are inputs to one implementation run, not a series
that later work can cite or be held to. Rejected as the sole process;
this process is designed to coexist with any implementation workflow.

### Mutable living-spec trees (OpenSpec-style)

A current-truth tree with delta migrations answers "what is the behavior
now?" in one read — genuinely better for that question — but records
neither rationale, nor rejected alternatives, nor consent, and offers no
multi-author or objection mechanism. The two compose: published RFCs are
the decision layer; a derived current-state view can sit above them.

### Gherkin/Cucumber as the evidence form

Readable and widely known, but its runner is a hand-maintained
step-definition library — a shadow codebase that itself needs tests —
failing the deterministic half of dual verifiability. The same reasoning
retired FitNesse-style fixture frameworks, whose genuinely good ideas
(decision and sequence tables; version-controlled executable documents)
survive here as evidence tables and repo-native literate transcripts.

### LLM-as-judge verification

Circular for a corpus whose purpose is constraining LLM agents; rejected
outright. Deterministic checkers only.

### Full IETF machinery

Maturity ladders, TS/AS applicability statements, variance procedures, and
multi-level appeals serve a global standards body with adversarial
stakeholders; at team scale they are ceremony. Deliberately omitted, with
humans-adjudicate as the entire appeals process.

## Security Considerations

Evidence transcripts are arbitrary shell commands executed by conformance
runners: running a series' corpus is running its authors' code. Runners
MUST execute evidence only in disposable sandboxes (fresh working
directory, isolated `HOME`, no ambient credentials), and adopting another
party's RFC series into CI is a supply-chain decision — review its
evidence blocks as you would its build scripts. Requirement markers and
evidence tags influence what CI enforces; because pairing is bidirectional
and lint-checked, silently dropping an obligation requires a visible
document edit, which review and the frozen-once-published rule are
designed to catch. The prohibition on LLM verification is a security
property as much as a methodological one: the class of system being
constrained is excluded from judging its own conformance.

## References

- RFC 2026, RFC 6410 (process, categories); RFC 7282, RFC 8789 (rough
  consensus); RFC 7322 (style); BCP 14 = RFC 2119 + RFC 8174; RFC 5234,
  RFC 7405 (ABNF); https://www.ietf.org/process/informal/.
- Jackson & Wing, "Lightweight Formal Methods," IEEE Computer roundtable,
  1996 — the evidence layer's theory (partiality in language, modeling,
  analysis, composition).
- Knuth, "Literate Programming," 1984 — weave/tangle; Python doctest as
  the nearest executable ancestor.
- TC39 Process Document (staged advancement, implementation-gated); COSS
  (Consensus-Oriented Specification System) — lightweight lineage.
- First artifact of this process: git-issue-tracker
  `docs/rfc/draft-ndn-multi-project-registry-02.md`, whose evidence
  conventions this document inherits.

## Changelog

- 2026-08-13/14: process designed and iterated in working session —
  dual verifiability, literate evidence, Gherkin rejection, fast/full
  tracks, draft naming, fidelity reservation — each decision exercised
  against a real specification (the registry RFC) before being recorded
  here.
- 2026-08-14: draft-00 created in the dedicated cross-project rfcs
  repository.
- 2026-08-14: full evidence replay (rfc-run) went green after two
  discoveries fed back into the conventions: sandboxes neutralize system
  git config AND redirect XDG_CONFIG_HOME (host excludes had leaked), and
  expected-output lines beginning "$ " are inexpressible — asserted via
  projection (recorded as a normative notation limit).
- 2026-08-14: entered LAST-CALL (full track: this document standardizes
  across projects) — objections by 2026-08-21. Reviewers invited: chazu,
  mparrett, rdaum.
