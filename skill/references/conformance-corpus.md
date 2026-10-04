# Conformance corpus — full reference

Loaded from SKILL.md when writing or changing evidence.

**Dual verifiability governs evidence:** every conformance artifact must be
checkable by a person at a glance AND by a deterministic tool. LLMs may
author artifacts; they never sit in the verification loop.

The RFC is literate: provable requirements carry `[R-<slug>]` markers, and
the evidence lives IN the document beside them — typed fenced blocks whose
info string carries the tag (` ```transcript @R-<slug> `), or tables
preceded by `<!-- evidence: @R-<slug> -->`. Pairing is lint-enforced both
directions; `rfc-tangle <rfc.md> [outdir]` extracts each block verbatim
into the type's native file for its runner. An evidence *type* is just a
name plus a **runner contract**: a deterministic command that takes the
tangled file and exits 0/1. Choose types by least indirection:

- Info strings take attributes (draft-ndn-snippet-attributes-00):
  ` ```mica @R-slug mode=eval when=impl:omica uses=setup `. `mode=` says how
  a block runs; a following ` ```expect ` / ` ```expect-error ` block states
  its result (matched by `rfc-expect`: literal lines, `...`, `{{regex}}`);
  `when=` selects variants by profile facts (`RFC_PROFILE` or the series
  `profile` file; non-matching blocks report `N/A`); `id=`/`uses=` share
  chunks; `include=path#anchor` pulls a marked file region; and an evidence
  table with `template=chunk` runs one case per row, filling `{{column}}`.
  Sidecars (`.attrs`, `.expect`, `.expect-error`) sit beside each tangled
  block. Legacy `type,flag` (rustdoc/mdBook) is read as `flags=`.

- Evidence dispatches through **adapters** (draft-ndn-evidence-adapters-00):
  `rfc-run` resolves each tangled block's type via RFC_ADAPTER_PATH ->
  series-local `adapters/` -> built-ins, and the adapter owns all engine
  and environment concerns. Built-ins: `transcript` (bootstrap: shell
  replay in the hygiene sandbox) and `fsm` (structural validation).
  Prefer thin declarative vocabularies over raw shell once a domain
  accumulates evidence.
- Isolation is a separate seam (draft-ndn-sandbox-providers-00): a
  **sandbox provider** wraps any adapter run (`provider [flags] -- adapter
  file`), selected by `--sandbox NAME` > `RFC_SANDBOX` > the series
  profile file `sandbox`; a selected-but-unresolvable provider is a hard
  error, never a silent bare run. Built-in: `env-scrub` (hygiene floor).
- Project session formats (e.g. mooR's `moot`) — register the existing
  runner; the fenced block is the file, no transliteration.
- Evidence tables — one row per case for rule surfaces (validity matrices,
  state transitions); runner = thin row adapter.
- `abnf` — the ∀ statement of syntax; pair it with witness rows (concrete
  valid/invalid strings) as its checkable shadow.
- `fsm` — state machines (`initial` / `A -> B` / `terminal ...`, plus
  optional `deadline <state> [<instant>] -> <target>` where the timeout
  handler is REQUIRED and must be a declared transition; instants are
  second-resolution — bare date = midnight UTC, date+offset = midnight in
  that zone), validated
  for single initial, reachability, terminal closure, and dead ends;
  allowed/forbidden transition witness tables are cross-checked against the
  machine; mermaid/D2 displays are derived via `rfc-fsm-render`, never
  authored — and the derived display is itself verified, since a render
  the engine rejects publishes a syntax error where the machine should be
  while the corpus still reports green: `rfc-lint` holds each render to
  the legal stateDiagram-v2 subset offline, and `rfc-mermaid-check` (CI)
  renders them with real mermaid. Per-state `note <STATE>: <guidance>` lines carry stage
  permissions; `rfc-fsm-exec <file.fsm> <state> [target]` executes the
  machine as a process governor — query mode prints the stage guidance and
  permitted transitions, guard mode exits nonzero on an illegal move —
  so an agent derives what is and is not permitted from the document,
  never from memory. Session mode (`--state FILE`) persists the walked
  path as a validated witness across context resets and discloses ONLY
  the current stage — use it when executing an RFC-governed process.
  `rfc-render-llm <rfc.md>` emits a token-minimal normative digest
  (`--verify` checks its invariants); prefer the digest when loading an
  RFC into context, and resolve markers to the full document as needed.

The tangled evidence of ALL published RFCs is the conformance corpus: CI
runs the WHOLE corpus, never just the newest RFC's — work on one RFC cannot
silently regress another's requirements. Supersession retires an RFC's
evidence; an `Updates:` RFC replaces only the requirement IDs it names.
IDs are permanent once published: plans, commits, and later RFCs cite them,
so obligations accumulate instead of resetting with each conversation.

Drafts declare their expected corpus state with an optional masthead
header `**Corpus:** green|red (note)` (absent = green); `rfc-run --expect`
verifies the declaration in both directions and CI gates drafts on it —
red only by declaration, never by surprise. Published RFCs must be green.
