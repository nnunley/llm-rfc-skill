# draft-ndn-authoring-rfcs-00: The RFC Process for Human–LLM Specification Authoring

**Status:** DRAFT
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

Each transcript block in this document is an independent conformance test
executed under replay-and-diff. The runner provides, per block, a fresh
sandbox: an empty directory whose logical path is exactly `/tmp/gi-rfc`
(the shell's working directory at block start), `HOME` and `XDG_CONFIG_HOME`
redirected inside the sandbox (empty global git config, no host excludes),
system git config neutralized (`GIT_CONFIG_NOSYSTEM=1`), a configured git
identity, and no inter-block state. Blocks construct every piece of state
they reference — no block depends on another block, on this repository, or
on the author's machine.

Notation: lines beginning `$ ` are commands (shell state persists within a
block); a line beginning `> ` continues the preceding command — PS2 — and the
join PRESERVES the newline: the replayed input is byte-for-byte the
multiline command as typed, reading exactly as a terminal displays it,
and the command executes at the first non-continuation line. Heredoc provisioning SHOULD
replace escape-laden single-line `printf` for multiline content; as a
side effect, `> `-prefixed heredoc lines shield nested evidence fences
from the markdown parser. Other lines are the expected output, compared
byte-exactly; a line
`? N` asserts that the immediately preceding command exited with status N,
and absent a `?` line the status is asserted to be 0. Where real output
embeds generated identifiers or timestamps, the transcript asserts through
a deterministic projection (`grep -c`, `cut`, `sort`) — the projection is
part of the evidence. Runners on systems where `/tmp` is a symlink
normalize exactly the sandbox-root prefix between its physical and logical
spellings; no other substitution exists. A `fidelity=` modifier on the
fence info string is reserved for future per-block strictness levels
(e.g. strict alignment for state-machine tables and production rules) and
is currently undefined.

The transcript runner provides the skill's own tools on `PATH` for every
corpus it replays; this document's transcripts rely on that provision
for `rfc-lint` and `rfc-tangle`, checking conformance against THIS
document. One notation limit is normative: an expected-output line
beginning `$ ` or `> ` cannot be expressed literally (it reads as a
command or a continuation) — such output is asserted through a
projection instead.

### Document identity

Unpublished documents MUST be named `draft-<author>-<slug>-NN.md` and
published documents `NNNN-slug.md`, per the Formal Grammar; the document
title line MUST repeat the identity (`# draft-...:` or `# RFC NNNN:`).
An author token containing hyphens separates from the slug with a DOUBLE
hyphen (`draft-prime-agent--review-00.md`): parsing splits at the first
`--` when present, otherwise at the first `-`, and a slug MUST NOT
contain `--` — every name parses one way. Author-scoped draft names
require no coordination between concurrent authors, human or agent.
A series MAY instead declare the repo identity profile
(draft-ndn-cross-repo-00), in which the repository is the author
namespace and draft names omit the author token; the profiles coexist.
[R-identity]

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
| draft-ndn-registry-00.md          | yes   |
| draft-claude-registry-03.md       | yes   |
| draft-prime-agent--registry-00.md | yes   |
| 0001-registry.md                  | yes   |
| registry-design.md                | no    |
| draft-Ndn-registry-00.md          | no    |
| draft---registry-00.md            | no    |

### Status machine

Every document MUST carry a `**Status:**` line whose value is one of
`DRAFT`, `LAST-CALL`, `POSTPONED`, `PUBLISHED`, `SUPERSEDED`,
`WITHDRAWN`, or `HISTORIC`. [R-status-vocab] Status MUST agree with the filename form:
draft-named documents are unpublished (`DRAFT`, `LAST-CALL`, `POSTPONED`,
`WITHDRAWN` — plus `SUPERSEDED` solely as the cross-repository
forwarding pointer of draft-ndn-cross-repo-00, whose number lives in the
accepting series) and numbered documents are published (`PUBLISHED`,
`SUPERSEDED`, `HISTORIC`) — numbers do not exist before publication in
the series that assigned them. [R-status-form]

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

Documents MUST NOT reference local machines, secrets, or PII-bearing
real paths; example data uses generic placeholders (lint-enforced:
home-directory paths, credential patterns, key material).

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

State machines are expressed in fsm blocks — `initial`, `A -> B`
transitions, `terminal` — validated for a single initial state,
reachability of every state, terminal closure, and dead ends [R-fsm];
witness tables of allowed and forbidden transitions are cross-checked
against the machine, and mermaid/D2 renders are derived by
`rfc-fsm-render`, never authored.

```transcript @R-fsm
$ printf '# draft-a-x-00: X\n**Status:** DRAFT\n```fsm\ninitial A\nA -> B\nC -> B\nterminal B\n```\n' > draft-a-x-00.md
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "unreachable"
1
```

A state MAY carry a deadline: `deadline <state> [<instant>] -> <target>`.
Deadlines are process state separate from any particular lifecycle status
— any non-terminal state of any machine MAY bear one. A deadline line
REQUIRES its timeout handler: the `-> <target>` names the transition the
process takes when the deadline expires, and it MUST be one of the
state's declared transitions (a timeout is never a new edge — it selects
a default among the legal moves). An OPTIONAL `<instant>` uses the same
second-resolution forms as `objections by` (bare date = midnight UTC;
date with zone offset = midnight in that zone); a machine that describes
a recurring process omits it, and the governing document supplies the
concrete instant. The state name `timeout` is RESERVED — it is the
executor's timeout pseudo-target, and a machine declaring it would make
a legal transition unreachable through the executor. A deadline on a
terminal state, a handler that is not a declared transition, a deadline
line without a handler, or a state named `timeout` are all errors.
[R-fsm-deadline]

```transcript @R-fsm-deadline
$ printf 'initial A\nA -> B\nterminal B\ndeadline A 2026-08-21T17:00:00Z -> B\n' > ok.fsm
$ rfc-run --type fsm ok.fsm
? 0
$ printf 'initial A\nA -> B\nB -> C\nterminal C\ndeadline A -> C\n' > bad.fsm
$ rfc-run --type fsm bad.fsm
deadline handler A -> C is not a declared transition
? 1
$ printf 'initial A\nA -> B\nterminal B\ndeadline A\n' > nohandler.fsm
$ rfc-run --type fsm nohandler.fsm
not an fsm statement: deadline A
? 1
$ printf 'initial A\nA -> timeout\nterminal timeout\n' > shadow.fsm
$ rfc-run --type fsm shadow.fsm
state name timeout is reserved
? 1
```

The fsm notation is exactly this grammar; a line matching no production
is an error, and the structural rules above (single initial, reachability,
terminal closure, deadline handler legality) apply on top of it.
[R-fsm-grammar]

```abnf
fsm        = *( fsm-line LF )
fsm-line   = [ ws ] [ stmt ] [ ws ] [ comment ]
stmt       = initial / transition / terminals / note-stmt / deadline
initial    = %s"initial" ws state
transition = state ws "->" ws state
terminals  = %s"terminal" 1*( ws state )
note-stmt  = %s"note" ws state ":" ws note-text
deadline   = %s"deadline" ws state [ ws instant ] ws "->" ws state
state      = 1*( ALPHA / DIGIT / "-" / "_" )
instant    = date [ time / zone ]           ; bare date = midnight UTC
date       = 4DIGIT "-" 2DIGIT "-" 2DIGIT   ; date+zone = midnight there
time       = %s"T" 2DIGIT ":" 2DIGIT ":" 2DIGIT ( %s"Z" / zone )
zone       = ( "+" / "-" ) 2DIGIT ":" 2DIGIT
note-text  = 1*( VCHAR / WSP )
comment    = ";" *( VCHAR / WSP )
ws         = 1*WSP
```

```transcript @R-fsm-grammar
$ printf 'initial A\nA -> B\ndeadline A 2026-01-01 -> B\nnote A: waiting\nterminal B\n' > full.fsm
$ rfc-run --type fsm full.fsm
? 0
$ printf 'initial A\nA -> B\nA => C\nterminal B\n' > bad.fsm
$ rfc-run --type fsm bad.fsm
not an fsm statement: A => C
? 1
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
$ cat > draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> **Status:** DRAFT
> Works. [R-w]
> ```transcript @R-w
> $ true
> ```
> EOF
$ rfc-tangle draft-a-x-00.md out
out/draft-a-x-00.w.transcript
$ grep -c '^\$ true$' out/draft-a-x-00.w.transcript
1
```

### Lifecycle

Publication REQUIRES the document's embedded evidence to replay green —
implementation experience in the sense of W3C Candidate Recommendation
and TC39 stage 4. A spec-first draft keeps its red corpus while DRAFT
and publishes only once implementation turns it green; this is what
makes the published-corpus-green CI rule an invariant rather than an
aspiration. Publication assigns the number: the next number is taken from the series
`index.md`, the file is renamed and retitled, status becomes `PUBLISHED`,
and the index entry is committed — concurrent publications collide on the
index, and that merge conflict is the allocation lock. A published RFC is
frozen: modification in the working tree is a lint error, and the sole
permitted edit is setting `SUPERSEDED` with its `**Superseded-By:**` link
when a successor publishes. [R-immutable] A document in `SUPERSEDED`
status MUST name its successor. [R-supersede] A document in `LAST-CALL`
MUST state its objection deadline in the Changelog: `objections by
<instant>`, resolved to second precision — the canonical form is
`YYYY-MM-DDTHH:MM:SSZ` (numeric zone offsets permitted); a bare
`YYYY-MM-DD` denotes midnight UTC of that date, and `YYYY-MM-DD±HH:MM`
denotes midnight in that zone. Every accepted form names one unambiguous
second. [R-lastcall]
`LAST-CALL` is not a one-way gate: the document returns to `DRAFT` when
substantive objections stand unaddressed at the deadline, or when the
call is retracted as premature (a last call asserts a settled design;
active revision falsifies the assertion). From `LAST-CALL` a document
proceeds to `PUBLISHED` on rough consensus, returns to `DRAFT`, or ends
`WITHDRAWN` — a Changelog entry records which, and why.
The complete lifecycle transition relation is exactly the machine below;
a status change outside it is a process violation. [R-lifecycle]

A conformance corpus MUST be maintained in continuous integration: a series
SHALL run `rfc-lint` over every RFC and draft, and SHALL run `rfc-run` over
every `PUBLISHED` RFC's evidence as part of each CI job. A change that breaks
a published RFC's evidence MUST NOT merge; draft evidence MAY be red
(spec-first drafts describe unimplemented behavior and are allowed to fail).
The series's `.github/workflows/conformance.yml` implements this
contract.

A draft's corpus state is declared, never discovered: the masthead header
`**Corpus:** green|red (parenthetical note)` states the expected replay result
(absent means green), and `rfc-run --expect` verifies the declaration
against reality in BOTH directions — a green declaration whose corpus
fails and a red declaration whose corpus passes are equally stale, and
both are errors. CI SHALL gate drafts with `--expect`: a draft MAY be red
only by declaration, never by surprise, so a regression in a working
draft's evidence breaks immediately rather than at the publication gate.
Published RFCs MUST NOT declare red (lint-enforced — the publication gate
requires green). [R-corpus-declared]

```transcript @R-corpus-declared
$ mkdir -p adapters
$ printf '#!/bin/sh\nexit 1\n' > adapters/always-red
$ chmod +x adapters/always-red
$ printf '# t\n\n**Corpus:** red (spec-first)\n\n\140\140\140always-red @R-x\nx\n\140\140\140\n' > t.md
$ rfc-run --expect t.md
FAIL t.x.always-red
EXPECT ok t.md — corpus red as declared
rfc-run: 0 failing block(s)
? 0
$ printf '#!/bin/sh\nexit 0\n' > adapters/always-green
$ chmod +x adapters/always-green
$ printf '# t2\n\n**Corpus:** red (stale)\n\n\140\140\140always-green @R-x\nx\n\140\140\140\n' > t2.md
$ rfc-run --expect t2.md
PASS t2.x.always-green
EXPECT MISMATCH t2.md — declared red but corpus is green
rfc-run: 1 failing block(s)
? 1
```

```fsm @R-lifecycle
initial DRAFT
DRAFT -> LAST-CALL
DRAFT -> PUBLISHED       ; fast track
DRAFT -> WITHDRAWN
LAST-CALL -> PUBLISHED
LAST-CALL -> DRAFT       ; objections unaddressed, or call retracted
LAST-CALL -> WITHDRAWN
DRAFT -> POSTPONED         ; good idea, wrong time
LAST-CALL -> POSTPONED     ; a call can conclude "not now"
POSTPONED -> DRAFT         ; resume
POSTPONED -> WITHDRAWN     ; terminate
PUBLISHED -> SUPERSEDED
PUBLISHED -> HISTORIC
deadline LAST-CALL -> PUBLISHED    ; expiry executes the silence default; standing concerns preempt
terminal SUPERSEDED HISTORIC WITHDRAWN
note DRAFT: revise in place, Changelog each change, corpus can be red
note LAST-CALL: consensus table + deadline required, concerns block
note POSTPONED: parked - sound idea, wrong time
note PUBLISHED: frozen, number assigned, corpus-green invariant
note SUPERSEDED: successor named in Superseded-By
note HISTORIC: retired without successor
note WITHDRAWN: dead draft
```

<!-- evidence: @R-lifecycle -->
| from       | to         | allowed |
|------------|------------|---------|
| LAST-CALL  | DRAFT      | yes     |
| DRAFT      | PUBLISHED  | yes     |
| PUBLISHED  | DRAFT      | no      |
| SUPERSEDED | DRAFT      | no      |
| WITHDRAWN  | LAST-CALL  | no      |
| POSTPONED  | DRAFT      | yes     |
| POSTPONED  | PUBLISHED  | no      |
Full replacement uses `Obsoletes:`; partial amendment uses `Updates:` and
replaces only the requirement IDs it names; retirement without a successor
is `HISTORIC`; dead drafts are `WITHDRAWN`. `POSTPONED` parks a draft
whose idea is sound but whose time is wrong (a last call MAY conclude
this); a postponed draft keeps its name, resumes to `DRAFT`, or ends
`WITHDRAWN` — it never publishes without first resuming. Requirement IDs are permanent
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
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "objections by YYYY-MM-DDTHH:MM:SSZ"
1
```

### Commit discipline

A commit that records a decision accepted by a human collaborator is the
decision's entry into history, and its message is checked twice — once by
a tool, once by a person, the dual-verifiability split applied to the
commit itself.

The deterministic half: the message MUST conform to Conventional Commits
v1.0.0, whose specification is itself stated in RFC 2119 keywords and is
incorporated here by reference — its numbered rules govern, including its
content guidance that the body provides context about the change. The
mechanical surface (`type[(scope)][!]: description`, body separated from
the header by a blank line) is checkable with `rfc-commit-lint` (usable
directly or as a `commit-msg` hook). [R-commit-conventional] The header
grammar, transliterated to ABNF as a derived convenience (the CC text is
authoritative):

```abnf
commit-header = type [ "(" scope ")" ] [ "!" ] ": " description
type          = 1*ALPHA              ; feat and fix carry CC semantics
scope         = 1*( ALPHA / DIGIT / "." / "_" / "/" / "-" )
description   = 1*( VCHAR / WSP )
```

Attribution names only human committers: a message MUST NOT carry LLM
attribution (Co-Authored-By an agent, "generated with" trailers) —
UNLESS the repository declares that LLM disclosure is mandatory, in
which case the check inverts to demand its presence (`rfc-commit-lint
--require-llm`). Either policy is deterministic; mixing them silently is
not permitted. [R-commit-attribution]

```transcript @R-commit-conventional
$ printf 'feat(registry): add prune subcommand\n\nRemoves stale entries on demand rather than at read time.\n' > msg
$ rfc-commit-lint msg
? 0
$ printf 'added some stuff\n' > bad
$ rfc-commit-lint bad
rfc-commit-lint: header is not Conventional Commits v1.0.0 (type[(scope)][!]: description)
? 1
$ printf 'fix: x\nbody with no blank line\n' > nosep
$ rfc-commit-lint nosep
rfc-commit-lint: body must be separated from the header by a blank line
? 1
```

```transcript @R-commit-attribution
$ printf 'fix: correct message matching\n\nCo-Authored-By: Claude <agent@example>\n' > msg
$ rfc-commit-lint msg
rfc-commit-lint: non-human attribution present (repository does not require LLM disclosure)
? 1
$ rfc-commit-lint --require-llm msg
? 0
$ printf 'fix: correct message matching\n' > human
$ rfc-commit-lint --require-llm human
rfc-commit-lint: LLM disclosure required by repository but absent
? 1
```

The judgment half is a two-key read. Key one: an LLM with FRESH context
— never the authoring agent's session — receives the changeset and the
message and reports whether the message narrates WHAT HAPPENED, the
decision and its effect, not the fine-grained edits. Key two: the human
collaborator reads the message and that report. Both keys MUST concur
before the commit is accepted. Fresh context is the point — an author
reviewing its own narrative inherits its own framing, the same reasoning
that makes adversarial reviewers independent. This is CC's own body
guidance sharpened to a gate: a message that enumerates hunks, renamed
variables, or touched files is a diff restated, and the diff already
exists; the message exists to carry what the diff cannot. The two-key
read is review judgment and lives outside the deterministic linter; the
conformance corpus itself remains LLM-free.

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
necessarily withdrawn, and humans adjudicate when contested. Silence
implies consent ONLY inside a declared LAST-CALL window; silence during
the draft stage implies nothing at all — a draft comment period asks
"what is wrong?", a last call asks only "does anyone object?".
Consent is registered, never inferred: a document in LAST-CALL MUST
carry a consensus table naming its reviewers (dispositions: pending,
consent, or concern with text — lint-checked). A recorded concern MUST
block publication until its resolution is recorded; the objection
deadline binds only once every named reviewer has registered a
disposition. Any
participant, human or agent, is welcome as author, reviewer, or objector.

Published RFCs are cited across repository series as `<series>/<NNNN>` where
`<series>` is the hosting repository name (e.g. `llm-rfc-skill/0001`);
drafts are cited by their full draft name, which is globally unique by
author and slug convention (e.g. `draft-ndn-authoring-rfcs-00`). Within a
single series, bare `NNNN` or `draft-*-NN` suffices.

An RFC lives in the repository whose behavior it governs (its "home series").
Project RFCs describing features, formats, or interfaces of a specific
codebase belong in that project's own `docs/rfc/` or `rfc/` series — they
are never centralized into another repository. This repository carries ONLY
cross-project process and practice documents (BCPs like this one). The
`<series>/<NNNN>` citation form exists precisely because series are
per-repository.

## Formal Grammar

```abnf
draft-file = %s"draft-" ( author "-" / hyph-author "--" ) slug "-" 2DIGIT %s".md"
hyph-author = author 1*( "-" author )   ; hyphenated identities take the double-hyphen separator
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
runners: running a series' corpus is running its authors' code. The runner
provides hygiene-level sandbox isolation (fresh working directory, isolated
`HOME`, neutralized git config) to prevent inter-block leakage and host
contamination; this sandbox is NOT a security boundary. When executing
evidence from outside one's trust domain, security isolation (container,
VM, or throwaway host) MUST be deployed at the execution layer by the
deployment — the runner does not provide it. Adopting another party's RFC
series into CI is a supply-chain decision: review its evidence blocks as
you would its build scripts.

Requirement markers and evidence tags influence what CI enforces; because
pairing is bidirectional and lint-checked, silently dropping an obligation
requires a visible document edit, which review and the frozen-once-published
rule are designed to catch. The prohibition on LLM verification is a security
property as much as a methodological one: the class of system being
constrained is excluded from judging its own conformance.

## References

- RFC 2026, RFC 6410 (process, categories); RFC 7282, RFC 8789 (rough
  consensus); RFC 7322 (style); BCP 14 = RFC 2119 + RFC 8174; RFC 5234,
  RFC 7405 (ABNF); https://www.ietf.org/process/informal/.
- Conventional Commits v1.0.0 — the commit-message specification
  incorporated by reference in Commit discipline; itself an RFC
  2119-keyword document. https://www.conventionalcommits.org/en/v1.0.0/
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
- 2026-08-14: returned to DRAFT — the last call was premature (the document
  is still under active revision; a last call asserts a settled design).
  Review remains welcome as ordinary draft review.
- 2026-08-14: lifecycle gap found in review — LAST-CALL had no specified
  outbound transitions (the same day's premature-call retraction was
  therefore unspecified behavior). LAST-CALL -> DRAFT | PUBLISHED |
  WITHDRAWN now explicit.
- 2026-08-14: fsm evidence type added — the lifecycle transition relation
  is now a verified machine [R-lifecycle] with allowed/forbidden witnesses
  (including LAST-CALL -> DRAFT, the transition exercised before it was
  specified), and fsm validation itself is a proven requirement [R-fsm].
  Displays (mermaid/D2) are derived by rfc-fsm-render, never authored.
- 2026-08-14: dependency inversion fixed — Evidence conventions moved from
  registry RFC into this BCP as canonical [Finding 1]. Normative content
  from draft-ndn-multi-project-registry-02's section merged with BCP-specific
  additions (rfc-lint/rfc-tangle on PATH) and notation limit, eliminating
  process BCP normatively depending on feature draft in another repo.
- 2026-08-14: conformance corpus CI made normative [Finding 2]. Lifecycle
  section now prescribes rfc-lint over all documents and rfc-run over all
  published RFC evidence in CI as a SHALL requirement; changes breaking
  published evidence MUST NOT merge (draft evidence allowed to fail).
  Conformance workflow created in .github/workflows/conformance.yml.
- 2026-08-14: Security Considerations clarified [Finding 3]. Sandbox
  distinguished as hygiene isolation (preventing inter-block leakage), NOT
  security boundary; security isolation (container/VM/throwaway host) MUST be
  deployed at execution layer by deployment. rfc-run comment header updated.
- 2026-08-14: cross-series citation form added to Practice [Finding 4].
  Published RFCs cited as series/NNNN (e.g. llm-rfc-skill/0001); drafts by
  full draft name; bare form within single series.
- 2026-08-14: locality rule added to Practice — RFCs live in the repository
  whose behavior they govern; project-specific RFCs belong in that project's
  own rfc/ series, never centralized. This repository carries only
  cross-project process/skill RFCs. README.md clarified accordingly.
- 2026-08-14: the silence-default distinction made explicit — consent by
  silence exists only inside a declared LAST-CALL window; draft-stage
  silence carries no meaning (comment request and consent gate are
  different instruments).
- 2026-08-14: POSTPONED status added (from Rust's FCP dispositions):
  non-terminal, so the machine gains its resume (-> DRAFT) and
  termination (-> WITHDRAWN) arcs — the fsm dead-end rule enforces that
  requirement mechanically, as demonstrated before wiring.
- 2026-08-14: registered consensus adopted (rfcbot-derived): LAST-CALL
  documents carry a lint-checked consensus table; concerns block
  publication; the deadline binds only after full registration.
- 2026-08-14: publication gate adopted (W3C CR / TC39 stage-4 derived):
  evidence MUST replay green before publication — resolving the latent
  tension between spec-first red corpora and the published-corpus-green
  CI requirement.
- 2026-08-14: hygiene rule adopted — no local-machine references, secrets,
  or PII-bearing paths in documents; generic placeholders for examples
  (lint-enforced).
- 2026-08-14: fsm notation gains per-state note guidance and the machine
  becomes executable: rfc-fsm-exec derives an agent's stage permissions
  (query) and guards transitions (exit code) directly from the verified
  machine — process guidance from the document, never from memory.
- 2026-08-14: deadlines separated from LAST-CALL and given second
  resolution — the fsm vocabulary gains optional `deadline <state>
  [<instant>] -> <target>` lines with a REQUIRED timeout handler that
  must be a declared transition [R-fsm-deadline]; the lifecycle machine
  declares LAST-CALL's expiry default (silence-default publish). Deadline
  instants resolve to one unambiguous second: bare date = midnight UTC,
  date with zone offset = midnight in that zone, canonical form
  YYYY-MM-DDTHH:MM:SSZ.
- 2026-08-14: corpus state made a declaration, not a discovery — drafts
  carry a visible `**Corpus:** green|red` indicator (absent = green),
  `rfc-run --expect` verifies it in both directions, and CI gates drafts
  on the declaration so working evidence cannot rot silently until the
  publication gate. [R-corpus-declared]
- 2026-08-14: fsm notation given its ABNF (the process eating its own
  doctrine — syntax defined by a document is expressed in ABNF with
  witnesses) [R-fsm-grammar], covering the deadline extension and instant
  forms.
- 2026-08-14: commit discipline added — an accepted decision's commit
  message MUST be Conventional Commits v1.0.0 [R-commit-conventional]
  with human-only attribution unless the repository requires LLM
  disclosure [R-commit-attribution] (deterministic, rfc-commit-lint);
  a two-key read — a fresh-context LLM with the changeset, then the
  human — confirms the message narrates what happened, not the hunks.
- 2026-08-14: hyphenated authors made expressible without ambiguity —
  a hyphen-bearing author token separates from the slug with a double
  hyphen (draft-prime-agent--review-00.md); slugs never contain "--";
  every name parses one way. Chosen over constraining authors to
  hyphen-free tokens (silent misparse risk) and a registered-author list
  (reintroduces coordination).
- 2026-08-14: external-review fixes — the state name timeout is reserved
  in the fsm vocabulary (it shadowed the executor's pseudo-target,
  making a declared transition unreachable); the transcript-runner PATH
  provision is documented as a general contract rather than a
  this-document addition; rfc-commit-lint's attribution scan anchors to
  trailer position in the final paragraph, so body prose mentioning the
  words is never a false positive.
- 2026-08-14: multiline commands made human-readable — the transcript
  vocabulary gains PS2 continuation (`> ` lines join the preceding
  command with their newlines preserved, executing at the first
  non-continuation line), heredocs become the RECOMMENDED provisioning
  form over escape-laden one-line printf, `> `-prefixed heredoc lines
  shield nested evidence fences, and the `$ ` output limit extends to
  `> `. The tangle exemplar is rewritten in the new form as its witness.
- 2026-08-14: cross-repository machinery adopted by reference
  (draft-ndn-cross-repo-00): the repo identity profile coexists with
  author-scoped names, and draft-named SUPERSEDED is legalized solely as
  the cross-repo forwarding pointer.
