# draft-ndn-evidence-adapters-00: Structured Evidence Adapters

**Status:** DRAFT
**Category:** Experimental
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)
**Date:** 2026-08-14

## Abstract

Evidence blocks gain a layer of indirection on purpose: instead of literal
shell sessions, evidence is written in a structured action vocabulary, and
a small, versioned **adapter** binds that vocabulary to an execution
engine. The document then specifies intent; the adapter owns invocation
syntax, environment provisioning, and projections. Raw shell transcripts
remain available as the bootstrap adapter, no longer the preferred form.

## Motivation

The `transcript` evidence type couples three things the specification has
no business owning: an execution engine (a POSIX shell replayed line by
line), an environment (the sandbox contract exists solely to make shell
sessions portable), and incidental mechanics (provisioning `mkdir`s and
`grep -c` projections that appear in the document but assert nothing about
the requirement). In practice, half the lines of a typical transcript are
engine noise, and every engine change threatens the corpus.

The mooR project's `moot` format demonstrated the alternative and is the
direct origin of this design: session tests written as structured actions
(persona directives, evaluations, commands, output assertions) with more
than one runner behind the same files — an in-process scheduler harness
and a networked telnet harness. The markdown articulation of moot was
created precisely to have a structured representation that decouples the
execution engine from the test. The tests outlived engine decisions;
the format was the contract. Evidence in this series adopts the same
separation. What is adopted is the separation alone: moot's surface
syntax (the `@`-prefixed persona directives echo MOO's own command
idiom) is domain vernacular, and each vocabulary here speaks its own
domain's idiom rather than inheriting another's.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **vocabulary** — the action language of an evidence type: the statements
  a block of that type is allowed to contain, with their meanings.
- **adapter** — the deterministic executable that binds a vocabulary to an
  execution engine: it receives one tangled evidence file and exits 0
  (conforms) or 1 (violates), with diagnostics on output.
- **bootstrap adapter** — the raw shell replay (`transcript` blocks); the
  adapter of last resort when no vocabulary exists yet.

## Specification

### The adapter contract

An evidence type is a name, a vocabulary, and an adapter. The adapter
MUST be deterministic (same tangled file, same verdict), MUST exit 0 on
conformance and nonzero on violation, MUST write diagnostics naming the
first failing statement, and MUST own all environment concerns —
provisioning, isolation hygiene, teardown. Documents MUST NOT contain
engine mechanics: no provisioning commands, no output projections, no
engine-specific escapes. What a block states is intent in its vocabulary;
how intent is checked belongs to the adapter. [R-adapter-contract]

```transcript @R-adapter-contract
$ mkdir -p adapters
$ printf '#!/bin/sh\ngrep -q "^! error" "$1"\n' > adapters/demo-session
$ chmod +x adapters/demo-session
$ printf 'add tracker /tmp/gi-rfc/a\nadd tracker /tmp/gi-rfc/b\n! error already registered\n' > sample.demo-session
$ rfc-run --adapter-dir adapters --type demo-session sample.demo-session
? 0
$ printf 'add tracker /tmp/gi-rfc/a\n' > sample2.demo-session
$ rfc-run --adapter-dir adapters --type demo-session sample2.demo-session
? 1
```

### Adapter resolution

Runners resolve an adapter for block type `<t>` in order: the environment
override (`RFC_ADAPTER_PATH`), the series-local `rfc/adapters/<t>`, then
the tooling's built-in adapters. Resolution failure for a typed block is a
hard error, never a silent skip. [R-adapter-resolution]

```transcript @R-adapter-resolution
$ printf 'anything\n' > sample.unknowntype
$ rfc-run --type unknowntype sample.unknowntype
rfc-run: no adapter found for type unknowntype
? 1
```

### Vocabularies are declarative and thin

A vocabulary consists of action statements and observation assertions —
no control flow, no variables, no engine syntax. This is the boundary
that keeps adapters from regrowing into fixture frameworks: the FitNesse
lesson is that programmatic fixtures become a shadow codebase, and the
moot lesson is that a small declarative statement set does not. A
vocabulary SHOULD fit on one screen; a vocabulary that needs conditionals
is two vocabularies.

Example (a `demo-session` vocabulary for a CLI issue tracker):

```
add <name> <path>        register a repository
rm <name>                unregister
list                     observe the registry
! error <substring>      assert the previous action failed, mentioning text
! line <text>            assert an output line
```

The same intent as today's shell transcript for duplicate rejection, with
the sandbox, provisioning, and projection mechanics owned by the adapter
rather than restated in every block of every document.

### Flow vocabularies (script style)

The most broadly useful vocabulary shape is the **flow**: an ordered
sequence of actions against a stateful engine with observation
assertions interleaved — a session as structured statements. The
provenance is twofold: moot sessions, and FitNesse's SLIM script tables,
where a table compiles to a plain instruction list exactly so that a
small server in any language can execute it — engine decoupling as the
format's founding purpose. A flow vocabulary defines its action
statements, its assertion statements, and nothing else.

A flow MAY additionally be bound to a declared state machine: the block
names the machine's requirement tag, each step names the transition it
exercises, and the walked path is validated against the machine before
the adapter ever runs — a path witness, generalizing the single-edge
transition witnesses of the fsm type. A flow that walks an illegal path
fails structurally, engine untouched.

### The flow runner: vocabularies are data

A flow vocabulary MUST NOT require a per-domain adapter program — that
is the fixture pattern this document rejects, and early practice showed
it regrowing one bespoke executable at a time. Instead, ONE generic
runner (`rfc-flow <vocab> <flow>`) executes any vocabulary declared as
DATA: rule lines map a statement pattern to a command template and an
expectation (`<pattern> => <template> [! exit N] [! out <text>]`, with
`{x}` capturing one word and `{x*}` the rest), plus three directives —
`env repo` (isolated workspace with a seeded repository), `set`
(template variables), `collect` (statements that assemble a file, e.g. a
machine), and `boot` (run once before the first mapped statement). The
runner compiles vocab plus flow into a checked instruction list and
executes it — the SLIM shape honestly: a fixed, tiny instruction model,
one small runner, vocabularies as declarations. A type registration
shrinks to a one-line adapter delegating to the runner; genuinely
domain-specific side effects live in the vocabulary's templates, as
data, pinned and reviewed like all evidence machinery. Tool-native flow
consumption (a tool executing its own vocabulary directly) is a
sanctioned equivalent where a vocabulary mirrors one tool's verbs.
[R-vocab-data]

```transcript @R-vocab-data
$ cat > demo.vocab <<'EOF'
> set F data.txt
> put {w*} => sh -c 'printf "%s\n" "$1" >> {F}' _ "{w*}" ! exit 0
> has {w*} => grep -q "{w*}" {F} ! exit 0
> lacks {w*} => grep -q "{w*}" {F} ! exit 1
> EOF
$ cat > good.flow <<'EOF'
> put alpha
> has alpha
> lacks beta
> EOF
$ rfc-flow demo.vocab good.flow
? 0
$ cat > bad.flow <<'EOF'
> put alpha
> lacks alpha
> EOF
$ rfc-flow demo.vocab bad.flow 2>&1 | grep -c "flow: line 2: lacks alpha"
1
$ rfc-flow demo.vocab bad.flow >/dev/null 2>&1
? 1
```

Raw `transcript` blocks (shell replay under the hygiene sandbox) remain
defined and remain the right tool in two places: evidence about shell
tools themselves where the vocabulary IS the shell, and the first evidence
in a new domain before its vocabulary exists. Once a domain accumulates
blocks, a vocabulary SHOULD be introduced and new evidence SHOULD use it;
migrating published evidence follows the normal supersession path.

### Adapters are pinned dependencies

An adapter is executable code that the conformance verdict trusts.
Series MUST pin their non-built-in adapters by content (commit or hash)
the same way source material is pinned, and adapter changes are reviewed
as evidence changes — a verdict that can be changed by silently editing
an adapter is no verdict.

## Alternatives Considered

### Keep raw shell transcripts as the primary form

Zero adapter indirection was the original rationale. Rejected on the
field record: the sandbox contract, the physical/logical path
normalization, the exit-notation, and the projection idiom were all
machinery invented to make shell-as-evidence portable — engine coupling
paid for repeatedly inside the documents. The indirection exists either
way; the only choice is whether it lives in every block or in one adapter.

### Programmatic fixtures (FitNesse-style)

Bind table/session content to fixture classes in a host language.
Rejected: fixtures accrete domain logic and become a shadow codebase
needing its own tests — the same reason Gherkin step libraries were
rejected in the process BCP. Thin declarative vocabularies with a single
small adapter per engine hold the line.

### One universal structured format for all evidence

A single schema (steps, expectations) for every domain. Rejected:
vocabularies earn their keep by speaking the domain's own language —
moot's persona directives make no sense for a registry CLI, and vice
versa. Partiality in language applies to evidence languages too.

## Security Considerations

Adapters concentrate the trust that raw transcripts diffused: one
executable now interprets every block of its type. This is a net
improvement — one small program to review instead of arbitrary shell in
every document — but it makes the adapter the supply-chain target, hence
the pinning requirement and review-as-evidence rule above. Running a
foreign series' corpus still executes that series' adapters; the process
BCP's isolation guidance applies unchanged, and the bootstrap adapter's
hygiene sandbox remains the floor, not a security boundary.

## References

- The process BCP: draft-ndn-authoring-rfcs-00 — evidence doctrine this
  document refines ("an evidence type is a name plus a runner contract").
- mooR `moot` — the structured session-test format and its two runners;
  the markdown articulation of moot is this design's direct origin.
  https://github.com/rdaum/moor (crates/testing/moot).
- **mdmoot** (Norman Nunley, Jr, 2026-01) — the markdown articulation
  of moot. The line-intent notation is Zoltán Nagy's, created in mooR
  (commit 2eaa9225d, 2024-05-30, "simple text-based test definitions",
  replacing paired test.in/test.out files; extracted to crates/moot in
  eb36c67ad): `@persona` directives, `;` eval, `%` command, `&`
  eval-without-expected-output, `>` multiline continuation, other lines
  expected output. The markdown form carrying that notation, over a
  corpus of ~48 `.spec.md` files, is the contribution recovered here.
  The transcript notation's `$` / `>` / `?` family is the
  shell-vernacular sibling of the same design — and its PS2 `>`
  continuation is moot's own continuation character, converged on
  independently. The mdmoot corpus is not yet pinned — cite by
  repository and commit when it lands in a public tree.
- draft-ndn-multi-project-registry-02 (git-issue-tracker series) — the
  raw-shell corpus whose provisioning noise motivates migration; its
  evidence is expected to move to a `gi-session` vocabulary by revision.
- FitNesse and Gherkin fixture experience — recorded in the process BCP's
  rejected-forms decision record.
- draft-ndn-sandbox-providers-00 — refines this document's "adapters own
  all environment concerns": adapters own engine mechanics; isolation is
  a configurable provider seam wrapped outside the adapter by the runner.
- FitNesse SLIM (Simple List Invocation Method) — script tables compiled
  to plain instruction lists for language-agnostic execution; the
  flow-vocabulary precedent. http://fitnesse.org/FitNesse.UserGuide.WritingAcceptanceTests.SliM

## Changelog

- 2026-08-14: draft-00 created from the design conversation: adapters
  over direct shell examples, on the moot-md rationale — structured
  representation decoupling the execution engine from the test. Evidence
  here is deliberately red until rfc-run gains adapter dispatch
  (spec-first; the transcripts above are the acceptance criteria).
- 2026-08-14: clarified on review — moot's @-prefix is MOO-style command
  idiom, not part of the adopted pattern; vocabularies use their own
  domain's vernacular.
- 2026-08-14: flow vocabularies recognized as the primary shape (moot
  sessions; FitNesse SLIM script tables as the engine-decoupling
  precedent), with optional fsm binding: a flow as a path witness walked
  through a declared machine.
- 2026-08-14: evidence corrected during implementation — the contract
  transcript now self-provisions its demonstration adapter (the original
  referenced an unprovisioned directory, caught by implementing against
  it), asserts both verdict directions, and the resolution transcript
  asserts the error message. Corpus green with rfc-run adapter dispatch.
- 2026-08-14: environment ownership refined by
  draft-ndn-sandbox-providers-00 — isolation moves to a configurable
  provider seam; adapters keep engine mechanics (see References).
- 2026-08-14: mdmoot provenance recovered from the conversation record
  and cited: its line-intent annotation vocabulary with continuation
  lines is the direct ancestor of the transcript notation family, per
  the each-vocabulary-its-own-vernacular rule.
- 2026-08-14: notation authorship established from mooR's own history
  rather than recollection — git blame places the format's birth at
  Zoltán Nagy's 2eaa9225d (2024-05-30, in mooR, not upstream of it),
  and the annotation list is corrected against the moot README (% is
  command, & is eval-without-output, > is moot's own continuation).
- 2026-08-14: the worked example vocabulary renamed gi-session ->
  demo-session — the locality rule applied to examples: a
  project-specific vocabulary name belongs to its project's series, and
  this document's demonstration is project-free. gi-session remains
  cited in References as the expected first real adopter, in the
  git-issue-tracker series.
- 2026-08-14: fixture regression corrected on author review — a bespoke
  bash adapter per vocabulary is FitNesse's fixture pattern re-derived,
  which this document rejects. The generic flow runner (rfc-flow) lands
  with vocabularies as data [R-vocab-data]; the plan-run vocabulary is
  the first conversion (declaration file plus one-line registration),
  and tool-native flow consumption is sanctioned as the equivalent form.
