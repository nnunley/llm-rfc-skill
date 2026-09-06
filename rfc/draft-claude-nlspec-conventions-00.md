# draft-claude-nlspec-conventions-00: NLSpec Conventions as RFC Authoring Practice

**Status:** DRAFT
**Category:** Informational
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>

## Abstract

NLSpec (jhugman/nlspec) is a specification format optimized for a coding
agent that implements from the document alone: natural-language narrative
with formal structures — pseudocode, RECORD/ENUM/INTERFACE definitions,
normative tables, grammars — wherever prose would be ambiguous, closed by
a Definition of Done that mirrors the body. This document converts NLSpec
into practice for this RFC process. Each NLSpec convention receives a
disposition: adopted as authoring guidance for the Specification body,
already satisfied by an existing mechanism of the process, transformed
where its verification story conflicts with dual verifiability, or
rejected with the reason. Three compatibility requirements are proven
against the series' own tooling.

## Motivation

The RFC process governs the *identity, lifecycle, consent, and evidence*
of a specification: what a document is named, when it is frozen, who
consented, and how each requirement is proven. It says almost nothing
about how to write the body of a Specification so that an agent with no
other context can implement it — where defaults live, how precedence is
stated, how a data structure is declared, what an error table needs. An
author who follows the BCP to the letter can still produce a lint-clean
Specification full of implementation gaps, because the gaps are not
requirements and so carry no markers.

NLSpec addresses exactly that layer and nothing else. Its own scope
statement excludes lifecycle, requirement gathering, and version control
— the ground this series stands on — so the two are complementary rather
than competing. But NLSpec's completeness mechanism, a checkbox list an
implementer ticks, is self-reported: the same agent that implements
decides that it is done. That is the failure mode this series exists to
prevent. The conversion therefore takes NLSpec's *precision devices*
whole and replaces its *verification device* with the marker/evidence
pairing the process already has.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **NLSpec** — the Natural Language Specification format, as pinned in
  References.
- **precision device** — an NLSpec construct that removes ambiguity from
  the body of a specification without asserting that anything has been
  verified: attribute tables with defaults, precedence hierarchies,
  fallback chains, RECORD/ENUM/INTERFACE declarations, pseudocode.
- **verification device** — a construct that asserts completeness or
  correctness: NLSpec's Definition of Done checkboxes; this process's
  `[R-]` marker paired with an evidence block.
- **extension point** — in an Out of Scope entry, the named place where
  an excluded capability would attach if it were later adopted.
- **disposition** — this document's ruling on one NLSpec convention:
  *adopt*, *covered* (an existing mechanism already provides it),
  *transform* (adopted with its verification story replaced), or
  *reject*.

## Specification

### Disposition of NLSpec conventions

The table is the ruling; the subsections that follow give the form each
adopted or transformed convention takes in an RFC.

| NLSpec section | Convention | Disposition | RFC-process mechanism |
|---|---|---|---|
| 2.1 | Four-phase arc (Why → What → How → Done) | covered | Motivation → Terminology → Specification → embedded evidence |
| 2.2 | Decimal section numbering | reject | `[R-<slug>]` IDs are the stable anchors; numbers shift on edit |
| 2.3 | Linked table of contents | reject | rendered site derives it; digest drops it |
| 2.4 | Horizontal rules between sections | reject | headings suffice; lint keys on headings |
| 2.6 | Parallel subsection structure for multiple implementations | adopt | see Parallel structure |
| 3.1–3.2 | Opening paragraph, problem statement (state → problem → solution) | covered | Abstract and Motivation |
| 3.3 | Design principles as bold-lead named constraints | adopt | Motivation or Specification preamble |
| 3.4 | Reference projects table (exemplars, not dependencies) | adopt | References |
| 3.5 | Layering statement (defines X; does NOT define Y) | adopt | Specification preamble |
| 4 | Out of Scope section, four-part items with extension point | adopt | see Out of Scope |
| 5 | Design Decision Rationale as bold questions naming the rejected alternative | adopt | Alternatives Considered entries |
| 5.1 | Inline anti-pattern notes near the relevant section | adopt | Specification prose |
| 5.2 | Temporal anchors on data that ages | adopt | see Temporal anchors |
| 6.1 | DoD checkbox format, `[x]` = verified | reject | checkbox state is self-reported |
| 6.2 | DoD mirrors body sections point-by-point | transform | marker ⇄ evidence pairing, lint-enforced both directions |
| 6.3 | Requirement density heuristic | adopt | see Definition of Done |
| 6.4 | Integration smoke test as the final DoD item | covered | a transcript block is an executable smoke test |
| 6.5 | Validation matrices across implementations | adopt | evidence table with one row per case |
| 6.6 | HTML comments linking DoD items to implementation | reject | evidence blocks carry the link |
| 7 | Appendices, lettered, each referenced from the body | adopt | after the final section; digest drops them |
| 8 | Pseudocode conventions (UPPER keywords, `--` comments, snake/Pascal case) | transform | descriptive only; see Pseudocode |
| 8.3 | Layered composition notation | adopt | Specification prose |
| 8.4 | Behavior summaries after complex pseudocode | adopt | Specification prose |
| 9.1–9.3 | RECORD / ENUM / INTERFACE declarations | transform | descriptive only; see Pseudocode |
| 9.2 | ENUM paired with a classification table | adopt | the table is normative; the ENUM names it |
| 9.4 | Domain-specific keywords, defined before first use | adopt | Terminology |
| 9.5 | Namespace prefix tables for shared state | adopt | evidence table where checkable |
| 10.1 | Attribute tables with a Default column | adopt | see Precision devices |
| 10.2–10.5 | Mapping, classification, validation, mode, constraint tables | adopt | Specification; tag as evidence when a runner exists |
| 11 | Formal grammar where syntax exists; syntax separated from semantics | covered | ABNF with witnesses (BCP) |
| 12.1 | Established notations (state diagrams, sequence diagrams, trees, regex) | covered / adopt | state diagrams derive from fsm; others descriptive |
| 12.2 | Example progression: minimal → feature → composition → integration | adopt | ordering of evidence blocks within a section |
| 12.4 | Examples are illustrative, not normative | transform | a tagged evidence block IS normative; untagged examples are not |
| 13.1–13.4 | Present tense, imperative requirements, negative design constraints, justification after the requirement | adopt | Specification prose |
| 13.5 | (Critical) section marker | reject | BCP 14 keyword strength carries emphasis |
| 13.6 | Anti-jargon: define on first use, no synonyms | covered | Terminology; lint hygiene |
| 14.1–14.7 | Fallback chains, edge cases in pseudocode, error tables with Recovery, defaults with rationale, precedence hierarchies, procedural sequences, escape hatches | adopt | see Precision devices |
| 15.1 | "(see Section X.Y)" internal references | reject | cite `[R-<slug>]` or the heading text |
| 15.2 | Hard/soft inter-spec dependencies with imported types | covered / adopt | draft-ndn-cross-repo-00 for identity; imported-type lists adopted |
| 15.3 | External references with full URLs | covered | References |
| 16 | Out of Scope exclusions justified by layering (requirement gathering, decomposition, version control) | transform | permissively open seams; this series registers an offer at each — see Supplying NLSpec’s open seams |

### Out of Scope

An RFC MAY carry an `## Out of Scope` section, placed after
Specification and before Alternatives Considered. Each entry is one
paragraph in four parts, in this order: the excluded capability in
bold; what it is, in one sentence; why it is excluded; and its extension
point — the named seam (a section, a marker, an adapter type, a profile)
where it would attach if adopted later. An entry without an extension
point reads as a permanent exclusion and SHOULD NOT be written; if no
seam exists, the entry says so, and that absence is itself the finding.

Out of Scope and Alternatives Considered answer different questions and
MUST NOT be merged: Alternatives Considered records designs rejected for
something the document *does* specify; Out of Scope records capabilities
the document *does not* specify. An RFC whose exclusions are all
obvious omits the section.

### Alternatives Considered in question form

Each entry under Alternatives Considered SHOULD be headed by a bold
question that names the rejected alternative — "**Why not a single
method with a `stream` flag?**" — followed by the answer. The question
form exists so that an implementer who is about to propose the same
alternative finds it by its own name. Where a rejected approach bears
on one section only, a one-sentence inline note in that section
("A shared lock was rejected because …") is placed beside the rule it
protects, in addition to or instead of the entry.

### Temporal anchors

Data that ages — model catalogs, tool versions, prices, the pinned
revision of an external methodology — is introduced with an explicit
anchor: "At the time of writing (September 2026), …". The anchor marks
the data as perishable without invalidating the pattern around it. A
pinned commit in References is the anchor for a converted external
document, which is why every candidate-practice draft in this series
carries one.

### Precision devices

The following NLSpec devices are adopted as authoring guidance for the
body of a Specification. None is a verification device: each removes
ambiguity so that a marked requirement has one reading, and the
requirement's evidence — not the device — proves it.

- **Attribute tables carry a Default column.** Every configurable value
  the document introduces has an explicit default in a table
  (`Key | Type | Default | Description`); a value without a default is
  a value the implementer will guess.
- **Classification tables say what the system does.** A table that
  assigns behavior to categories (statuses, error kinds, enum values)
  has a Meaning column stating the system's response, not a restatement
  of the name.
- **Error tables carry a Recovery column.** An error category without
  its recovery action is incomplete.
- **Precedence hierarchies are numbered, highest first, and end in a
  default.** They answer "which source wins when several define the
  same value".
- **Fallback chains are numbered and terminate.** They answer "what
  happens when the preferred path is unavailable"; the last step never
  falls through.
- **Procedural sequences are numbered and every step runs.** They
  describe fixed-order operations at a system boundary (shutdown,
  publication, migration).
- **Defaults are stated with their rationale**, after the rule, so a
  later author does not change the default without meeting the reason.
- **Escape hatches are marked non-portable.** A deliberate bypass of an
  abstraction is documented as a decision, with the warning that code
  using it does not transfer.
- **Layered composition** of a value assembled from ordered sources is
  written as a numbered additive list with each layer's source in
  parentheses and later layers overriding earlier ones.

Any of these that has a deterministic runner in the series — a row
adapter for a table, a transcript that exercises a precedence rule —
SHOULD be tagged as evidence for the requirement it grounds. The rest
remain descriptive prose.

### Parallel structure

When a Specification documents several implementations of one interface
(adapters, providers, sandbox profiles), each implementation's
subsection carries the same subsections in the same order. A missing
subsection is then visible by contrast. Where the series already
enumerates implementations in an evidence table (one row per provider
per case), the table is the parallel structure and prose subsections
are not needed.

### Pseudocode and type declarations

A Specification MAY use NLSpec's pseudocode and RECORD/ENUM/INTERFACE
declarations to state an algorithm or a data shape with less ambiguity
than prose, in NLSpec's form: UPPER CASE keywords, `--` comments,
`snake_case` names and `PascalCase` types, colon-terminated headers with
indented bodies. Such blocks are **descriptive**: they fix the reading
of a requirement, they do not prove it.

A pseudocode or declaration block MUST NOT carry an `@R-` tag. It has no
deterministic runner, so it cannot be evidence; the requirement it
illustrates carries its own marker, proven by a block of a runnable type
beside it. Lint's pairing check accepts a tagged block of any type
name, so the rule is enforced at replay: the corpus goes red, not the
lint. [R-pseudocode-not-evidence] A state-bearing ENUM whose values
drive transitions is expressed as an `fsm` block instead, which is both
descriptive and verified.

```transcript @R-pseudocode-not-evidence
$ cat > draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> **Status:** DRAFT
> Routes by provider. [R-route]
> ```pseudocode @R-route
> FUNCTION complete(request) -> Response:
>     adapter = resolve_adapter(request.provider)
>     RETURN translate(adapter.send(request))
> ```
> EOF
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c 'evidence(1'
1
$ rfc-run draft-a-x-00.md 2>&1 | grep -c 'no adapter found for type pseudocode'
1
$ rfc-run draft-a-x-00.md >/dev/null 2>&1
? 1
```

### Definition of Done

NLSpec's Definition of Done is a checklist mirroring the body; its
checkbox state records whether each item was implemented and verified.
In this process the closed loop it describes already exists and is
mechanical: every provable requirement carries a marker, every marker
has evidence, every evidence block has a marker, and `rfc-lint` rejects
a gap in either direction. The token-minimal digest (`rfc-render-llm`)
is the derived checklist — it lists exactly the marked requirements and
nothing else, and its marker set is verified equal to the source's.

An RFC MAY nonetheless carry a `## Definition of Done` section as a
reader's index, placed after Specification. Each item MUST cite the
marker or markers it summarizes, and the item's verification record is
that marker's evidence, never the checkbox: a checklist item that names
a marker inherits the marker's pairing obligation, so an item asserting
`[x]` for a requirement with no evidence is a lint error, not a
completed task. [R-dod-cites-marker] Checkbox characters, if used,
carry no meaning to the tooling.

```transcript @R-dod-cites-marker
$ printf '# draft-a-y-00: Y\n**Status:** DRAFT\n## Definition of Done\n- [x] Parser accepts the supported subset. [R-parse]\n' > draft-a-y-00.md
$ rfc-lint draft-a-y-00.md 2>&1 | grep -c 'no embedded evidence block tagged @R-parse'
1
$ rfc-lint draft-a-y-00.md >/dev/null 2>&1
? 1
```

NLSpec's density heuristic transfers directly: a Specification section
of many lines and few markers is a section that has not yet said
anything provable; a section of many markers and little prose has not
yet explained itself. Both are review findings.

### Compatibility of the added sections

Out of Scope, Definition of Done, and appendices are additions on top of
the mandatory structure. A document carrying all of them beside the
seven mandatory sections lints clean; the process does not police
section names beyond the mandatory set. [R-nlspec-sections-compatible]

```transcript @R-nlspec-sections-compatible
$ cat > draft-a-z-00.md <<'EOF'
> # draft-a-z-00: Z
> **Status:** DRAFT
> ## Abstract
> A.
> ## Motivation
> M.
> ## Terminology
> T.
> ## Specification
> S.
> ## Out of Scope
> **Thing.** What it is. Why it is excluded. Where it would attach.
> ## Definition of Done
> - [ ] Nothing yet.
> ## Alternatives Considered
> **Why not the other way?** Because.
> ## Security Considerations
> None: the document executes nothing.
> ## References
> - r
> ## Appendix A: Reference
> Referenced from Specification.
> EOF
$ rfc-lint draft-a-z-00.md 2>&1 | grep -c 'sections(7/7)'
1
$ rfc-lint draft-a-z-00.md >/dev/null 2>&1
? 0
```

### Relationship to the authoring BCP

This document changes no rule of draft-ndn-authoring-rfcs-00. It adds
guidance for the body of a Specification, one elective section
(Out of Scope), a preferred form for Alternatives Considered entries,
and a ruling that NLSpec-style pseudocode is descriptive. The skill's
template carries the shape as its default Specification body, and the
BCP's own body is written in it — its Scope and principles opener,
masthead and sandbox tables, Out of Scope section, question-form
alternatives, and diagnostics appendix are this document applied. The
BCP's rules are unchanged, because none of this is a lifecycle or
evidence rule; this document remains the disposition record.

### Supplying NLSpec's open seams

NLSpec's own Out of Scope section (its §16) excludes requirement
gathering, system decomposition, and version control conventions by
layering: "these are workflow concerns". That is not a missing
extension point — NLSpec §4 explicitly sanctions layering as an
exclusion justification, and a named layer is a **permissive**
extension convention: any convention the adopting project brings to
that layer is a legal extension. What such a seam lacks is only a
registered offer, and since version control conventions are inherently
per-project, an offer — never a mandate — is the correct shape.

This series is one such offer. A project authoring NLSpec documents
MAY adopt it as its version control and lifecycle convention with the
body format untouched:

- The NLSpec body becomes the Specification of a draft named
  `draft-<author>-<slug>-NN.md` — author-scoped, so concurrent authors
  never coordinate.
- Revision is in-place while DRAFT with the commit log as its
  history; spec review is registered consent (LAST-CALL, consensus
  table, concerns block); spec diffs land under commit discipline.
- Publication freezes and numbers the document; later change is a
  superseding or updating draft, so spec history is never rewritten.
- The Definition of Done's verification burden moves onto marker ⇄
  evidence pairing and the replayed corpus — closing the loop the
  checkbox leaves to the implementer's own report.

The other two seams take the same shape: the BCP's authoring path
(research, interview, synthesis, formalize) stands at the
requirement-gathering seam, and NLSpec's one-document-or-many question
maps onto series membership at the decomposition seam — one RFC per
decision, cross-referenced by requirement ID, with `Updates:` for
partial amendment. Each is one possibility at an open seam, chosen per
project, never a claim that the format demands it.

## Out of Scope

**A `pseudocode` evidence adapter.** An adapter that would execute or
check NLSpec pseudocode blocks. Excluded because pseudocode has no
deterministic semantics — checking it would require either a real
language (at which point a transcript already exists) or an LLM judge
(rejected by the BCP). Extension point: draft-ndn-evidence-adapters-00,
should a subset of the pseudocode ever be given executable semantics.

**A DoD-mirroring check in `rfc-lint`.** A lint pass verifying that
each Specification subsection has a Definition of Done item. Excluded
because the marker/evidence pairing is a strictly stronger check that
already exists, and mirroring headings would encourage padding.
Extension point: the lint's evidence-pairing pass, if a series wants
section-level coverage reported.

**Lint rejection of tagged blocks with no adapter.** Today lint accepts
`@R-` on any fence type and the gap surfaces only at replay
[R-pseudocode-not-evidence]. A lint-time check would fail faster.
Excluded from this document because adapter resolution is the runner's
concern (RFC_ADAPTER_PATH, series-local adapters), which lint does not
model. Extension point: `rfc-lint`'s evidence pass, consulting the same
resolution order as `rfc-run`.

## Alternatives Considered

**Why not adopt NLSpec as the document format outright?** NLSpec's own
scope excludes lifecycle, consent, requirement gathering, and version
control (its Section 16), and its verification device is a self-reported
checkbox. Adopting it whole would discard identity, freezing, registered
consensus, and the corpus, and would install the one mechanism this
series forbids. Adopting its precision devices keeps what it does best.

**Why not let `[x]` in a Definition of Done count as verification?**
The agent that implements would be the agent that verifies. The BCP's
rule — LLMs author, they never verify — is a security property as well
as a methodological one, and a checkbox is exactly the verification
surface an LLM can tick without evidence.

**Why keep RECORD/ENUM/INTERFACE and pseudocode at all if they prove
nothing?** Because an implementer needs the data shape and the algorithm
stated once, unambiguously, and prose does that badly. The devices earn
their place by fixing the reading of a requirement; proof is a separate
job the evidence does.

**Why not decimal section numbering and "(see Section 4.2)"
references?** Numbers move whenever a section is inserted, and the
digest drops discursive sections, so a numbered reference can point at
nothing. `[R-<slug>]` IDs are permanent once published and survive the
digest; heading text survives an edit. Both are better anchors.

**Why not the (Critical) section marker?** BCP 14 already grades
strength (MUST versus SHOULD), and the marker is a second, unenforced
grading that NLSpec itself warns loses signal beyond two or three uses.

## Security Considerations

This document adds prose conventions and one optional section; it
executes nothing and introduces no runner. The one risk it addresses is
a document that *looks* verified: NLSpec pseudocode and checkbox lists
read as authoritative to an agent, and an agent could treat a tagged
pseudocode block or a ticked checklist as proof. Both are closed by
rule — a pseudocode block MUST NOT be tagged, and a checklist item's
record is its marker's evidence — and the first is caught mechanically
at replay [R-pseudocode-not-evidence]. The residual gap, that lint
alone does not catch a tagged non-runnable block, is recorded in Out of
Scope with its extension point.

## Compatibility

No existing document changes. Documents that add an Out of Scope or
Definition of Done section remain lint-clean [R-nlspec-sections-compatible].
The digest projection is unaffected: the added sections are discursive
and drop out, and marked requirements inside them survive as they would
anywhere.

## References

- NLSpec — jhugman/nlspec, `nlspec.nlspec.md` at commit `eae0052c948f`
  (2026-02-13, Apache-2.0): https://github.com/jhugman/nlspec/blob/eae0052c948f/nlspec.nlspec.md
- draft-ndn-authoring-rfcs-00 — the BCP: dual verifiability, marker ⇄
  evidence pairing, the prohibition on LLM verification.
- draft-ndn-evidence-adapters-00 — adapter resolution; the extension
  point for any future executable-pseudocode subset.
- draft-ndn-llm-digest-00 — the digest as the derived requirement list.
- draft-ndn-cross-repo-00 — inter-series dependency identity, which
  NLSpec's hard/soft dependency declarations map onto.
- BCP 14 = RFC 2119 + RFC 8174 — requirement keywords, where NLSpec's
  imperative voice lands.

