# llm-rfc-skill

A small, persistent container for reviewing code, designs, plans, and claims.

The working process is [evidence-review](skill/SKILL.md): keep relevant
facts and open findings, inspect their evidence, resolve disagreements,
and resume from disk after context loss. One human and one agent are enough.
The RFC series remains a collection of draft design notes and experiments;
using this workflow does not require publishing them or recruiting reviewers.

## Start a review

```sh
skill/review-session new "Review the proposed change"
skill/review-session activate /path/returned/by/new
skill/review-session resume
skill/review-session read /path/returned/by/new
skill/review-session save /path/returned/by/new
```

The first command creates a private directory under `~/.cache/review-sessions`
by default (`REVIEW_HOME` overrides the storage root):

```text
state/
  00_scope.md       request, worktree, authority
  05_workflow.md    review prerequisites, expressed in Make-style notation
  15_facts.md       assertions, conflicts, retractions, dependencies
  20_review.md      commitment, findings, dispositions
  99_next.md        next prerequisite or decision
evidence/          full logs and supporting artifacts
history/           snapshots taken before state edits
```

Activation persists a private pointer per worktree; resume works in a new
shell. `AGENTS.md` directs entry/recovery in this repository. Save before
updating state; `deactivate DIR` clears the pointer when the review closes.
See [session setup](skill/references/session.md). The helper initializes,
reads, and snapshots files; it does not judge evidence, resolve dependencies,
or install a runtime compaction hook. The graph and evidence determine
review completion; the saved next-action label is only a cache.

## Review, not a publication pipeline

A claim can be unknown, established, contradicted, or retracted. Conflicting
evidence remains visible. Retracting a premise reopens dependent conclusions
and commitments. Findings are addressed, dismissed, or explicitly deferred
with reasons; the agreed review criterion determines when to stop.

This adapts [Randal Schwartz's workflow](https://gist.github.com/RandalSchwartz/598a1f2b5760a23c1d70b57e9e85393f)
into a small working set, rather than loading every rule and RFC on every
turn. Requests, promises, observed results, and acceptance stay distinct.
Net token savings and automatic host recovery are not yet demonstrated.

## Install and check

```sh
make install
make test
```

Installation copies committed HEAD into
`~/.claude/skills/evidence-review`; override `SKILL_DEST` for another host.
Uncommitted edits are not installed. If migrating from the earlier
`authoring-rfcs` installation, disable that old skill in the host so it does
not also load; installation does not remove it.

The tooling uses bash and standard Unix utilities. `make test` exercises
the container and checks the existing RFC corpus. The corpus tools remain
available for specifications that need them: `rfc-lint`, `rfc-run`,
`rfc-check`, `rfc-render-llm`, and `rfc-fsm-exec`. Load
[their evidence reference](skill/references/conformance-corpus.md) only
when relevant. Existing adopted contracts keep their checks; the historical
RFC publication process is not the default review workflow.

[Rendered draft series](https://nnunley.github.io/llm-rfc-skill/) ·
[Draft index](rfc/index.md) · [Optional RFC template](skill/template.md)

## License and attribution

Three grants, by function:

- **Process text** — the RFC series (`rfc/`), `skill/SKILL.md`, and this
  README: [CC BY 4.0](LICENSE-CC-BY-4.0). Reuse and adapt freely **with
  attribution** (see Citing below). Per-document attribution belongs to
  each RFC's own `Authors:` line — contributors publishing here are
  credited as themselves.
- **Template** — `skill/template.md`: [CC0 / public domain](LICENSE-CC0).
  The template is itself derived from IETF practice — RFC 7322 document
  structure, BCP 14 boilerplate, conventions long predating this repo —
  so most of it was never ours to license; CC0 dedicates the little that
  is.
  The template exists to be copied into your documents; instantiating it
  creates **no derivative-work obligation, no attribution requirement, and
  no license carried into your RFC**.
- **Tooling** — `skill/rfc-lint`, `skill/rfc-tangle`, `skill/rfc-run`,
  `skill/rfc-search`, `skill/rfc-fsm-render`, `skill/rfc-mermaid-check`:
[MIT](LICENSE-MIT).

**No claim on outputs.** Documents produced using this process — including
those instantiated from the template and validated by the tooling — belong
entirely to their authors, under whatever license their home repository
chooses. Nothing here reaches into them.

Portions of the RFC texts quote IETF RFCs (e.g. the BCP 14 boilerplate of
RFC 8174) under the IETF Trust's provisions; those sentences remain the
Trust's and are not relicensed here.

### Citing

See [CITATION.cff](CITATION.cff) (GitHub's "Cite this repository" uses
it). Short form: *Nunley, N. — llm-rfc-skill: an RFC process for
human-LLM co-authored software specifications, formalized in
collaboration with Claude (Anthropic), 2026.*
