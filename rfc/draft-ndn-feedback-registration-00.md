# draft-ndn-feedback-registration-00: Feedback Registration for RFC Series

**Status:** DRAFT
**Category:** BCP
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)
**Date:** 2026-08-14

## Abstract

How feedback on an RFC is given and received: deliberate anywhere,
register in the artifact. The only registration with standing is the
committed consensus-table row (with its Changelog line); three transport
profiles — pull request, issue, and conversational — differ only in
where the evidence of assent lives. This process exists inside revision
control and leans on it deliberately: a disposition is anchored to the
revision it reviewed by SHA, and git history carries who, when, and what
changed between — where the IETF's forms compensate for standalone
documents, this process records in-band only what a deterministic check
needs at a glance.

## Motivation

An objection that lives in a comment thread has no defined weight at the
deadline; consent inferred from silence in a forum is not consent
registered anywhere. The process BCP already refuses to infer — silence
defaults, objections are recorded — but it does not yet say HOW a
disposition travels from a conversation, an issue, or a pull request
into the record, who may transcribe it, or what a registered concern
means once a document is frozen. The BCP's own LAST-CALL window will run
on these mechanics; they must exist before it opens.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **registration** — a committed consensus-table row (plus its Changelog
  line); the only feedback with standing.
- **disposition** — a reviewer's registered position: `pending`,
  `consent`, or `concern: <text>`.
- **reviewed-at** — the SHA of the draft revision a disposition was
  registered against.
- **transcription** — an editor committing a row on a reviewer's behalf,
  citing the deliberation artifact.
- **concerns ledger** — the series-local committed file recording
  post-publication concerns against frozen RFCs.

## Specification

### Registration is the only standing

Deliberation MAY happen anywhere — a conversation, an issue, a pull
request, a hallway. Standing lives in exactly one place: the committed
consensus-table row and its Changelog line. Unregistered feedback has no
standing at adjudication, symmetrically with the silence default —
objections are recorded, never inferred from threads. [R-registration]

```transcript @R-registration
$ cat > draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> **Status:** LAST-CALL
> ## Changelog
> - objections by 2026-08-21T17:00:00Z
> | reviewer | disposition |
> |---|---|
> | alice | maybe later |
> EOF
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "disposition must be"
1
```

### Revision anchoring

This process exists inside revision control, by design. A disposition
SHOULD carry the revision it reviewed: the consensus table's OPTIONAL
third column `reviewed-at` holds the SHA of the draft version the
reviewer read, and lint validates its form. What git already proves is
not restated in-band: the row's committer, date, and surrounding context
are the log's; the delta between the reviewed revision and the deadline
is `git diff`'s. Consent binds to its reviewed-at revision — at
adjudication, a consent registered against a revision that later changed
substantively reads at the adjudicator's discretion, and re-registration
SHOULD be requested for substantive deltas. Automated staleness scoring
is deliberately omitted: registering a row itself edits the file, so
"changed since review" is a judgment about substance, which is the
adjudicator's, made with the diff in hand. [R-reviewed-at]

```transcript @R-reviewed-at
$ cat > draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> **Status:** LAST-CALL
> ## Changelog
> - objections by 2026-08-21T17:00:00Z
> | reviewer | disposition | reviewed-at |
> |---|---|---|
> | alice | consent | 6571eaeb |
> EOF
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "reviewed-at"
0
? 1
$ cat > draft-a-y-00.md <<'EOF'
> # draft-a-y-00: Y
> **Status:** LAST-CALL
> ## Changelog
> - objections by 2026-08-21T17:00:00Z
> | reviewer | disposition | reviewed-at |
> |---|---|---|
> | bob | consent | not-a-sha |
> EOF
$ rfc-lint draft-a-y-00.md 2>&1 | grep -c "reviewed-at must be a commit SHA"
1
```

### Transport profiles

The three profiles share every registration semantic above; they differ
only in where the evidence of assent lives.

**Pull request.** The reviewer self-commits their row: git authorship is
the attribution, with no citation needed. A PR carrying proposed
text changes is simply a draft revision under existing machinery;
structural disagreement is a competing draft, as the process BCP already
provides.

**Issue.** Deliberation lives in an issue — in-repo issues (git-issue
style, where the deliberation itself is revision-controlled and
citations resolve in-repo indefinitely) are RECOMMENDED; forge-native
issues are permitted, cited by URL. An editor MAY transcribe the
reviewer's disposition: the transcribing commit MUST cite the
deliberation artifact (issue reference, URL, or message-id) and SHOULD
carry reviewed-at. A transcribed row is citation-sufficient — it stands
at the deadline as registered — and the named reviewer MAY demand a
countersign, which then supersedes the transcription.

**Conversational (primary in solo-plus-agent use).** The human–LLM
interview and synthesis loop is the deliberation, and the two-key commit
that codifies the row IS the registration: reviewer and countersigning
human are the same person, so no external citation is structurally
needed. The scaling boundary is hard: the two-key argument covers
EXACTLY the human or humans holding a key on the registering commit.
Consent relayed through a session on behalf of anyone else degrades to
the transcription rule — cite or countersign — and the conversational
path MUST NOT launder third-party approval.

A session or notebook reference is not mandatory (the commit suffices)
but SHOULD accompany contested or consequential dispositions when
available.

### Disposition lifecycle

A disposition moves through exactly this machine, and its witnesses are
cross-checked against it. [R-disposition-fsm]

```fsm @R-disposition-fsm
initial PENDING
PENDING -> CONSENT
PENDING -> CONCERN
CONCERN -> RESOLVED
CONCERN -> WITHDRAWN
terminal CONSENT RESOLVED WITHDRAWN
note PENDING: registered but unadjudicated — reads as consent at the deadline (silence default)
note CONCERN: blocks until resolved or withdrawn — text names what would resolve it
note RESOLVED: the concern was addressed and the reviewer's registration says so
note WITHDRAWN: the reviewer retracted the concern without change
```

<!-- evidence: @R-disposition-fsm -->
| from    | to        | allowed |
|---------|-----------|---------|
| PENDING | CONSENT   | yes     |
| PENDING | CONCERN   | yes     |
| CONCERN | RESOLVED  | yes     |
| CONCERN | WITHDRAWN | yes     |
| CONSENT | PENDING   | no      |
| RESOLVED| CONCERN   | no      |

### Post-publication concerns

Registration outlives publication. A published RFC is frozen, so a
concern against it cannot be a row in the document: it registers in the
series-local **concerns ledger** — the committed file `concerns` beside
the RFCs, one line per concern: `<rfc-name> <sha> <reviewer> <state>`,
where the SHA pins the published revision the concern is against and
state is `registered`, `addressed`, or `withdrawn`. A registered concern
is a standing obligation: it resolves only when a superseding or
updating draft addresses it (state `addressed`, citing the successor in
its commit) or a recorded decision withdraws it. Lint validates the
ledger's form. [R-concerns-ledger]

```transcript @R-concerns-ledger
$ printf '# post-publication concerns\n0001-registry 6571eaeb alice registered\n' > concerns
$ printf '# draft-a-x-00: X\n**Status:** DRAFT\n' > draft-a-x-00.md
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "concerns line malformed"
0
? 1
$ printf '0001-registry somewhere alice registered\n' > concerns
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "concerns line malformed"
1
```

### Adjudication

Deadline adjudication is forge-free: the record is the table state and
the git history at the `objections by` instant — nothing on any forge is
consulted to determine standing. Pending reads as consent (silence
default); standing concerns block; the adjudicating human reads each
consent's reviewed-at delta and judges substance.

## Alternatives Considered

### Sibling RFCs per transport path

Three documents, one per profile. Rejected: the paths share every
registration semantic, and splitting invites drift; a path that later
needs its own lifecycle can be split by supersession.

### Forum standing (threads count)

Let discussion carry weight directly. Rejected outright: it reintroduces
inference — the exact thing the silence default exists to prevent — and
makes adjudication forge-dependent.

### Countersign required for all transcription

Stronger attribution, rejected as default: it makes the issue path as
slow as its slowest reviewer and forge-dependent at the deadline;
citation-sufficient with countersign-on-request keeps the record
committed and the escalation available.

### In-band restatement of provenance

Rows carrying dates, full names, and rationale duplicated from git.
Rejected: this process is deliberately VCS-aware — in-band state is the
minimum a deterministic check reads at a glance (disposition, pin), and
revision control proves the rest.

### Automated staleness scoring

Lint comparing reviewed-at against the file's later history. Deliberately
omitted: the registering commit itself edits the file, so recency is not
substance; the adjudicator judges the diff. A derived tool MAY present
the delta; it never scores it.

## Security Considerations

Registration is an authorization surface: a row asserts a person's
position. The PR path ties assertion to git authorship; the transcription
path deliberately weakens that tie for liveness, and its citation
requirement is the audit trail — a forged transcription is a false
citation in a committed artifact, discoverable and revertable, and the
countersign escalation exists for exactly that dispute. The
conversational path's boundary rule is the load-bearing control: without
it, an agent session could launder "the team agrees" into a registered
row; with it, every key on the registering commit maps to a present
human. The concerns ledger MUST NOT contain secrets or PII beyond
reviewer identifiers already public in the series' history.

## References

- The process BCP: draft-ndn-authoring-rfcs-00 — the consensus table,
  silence default, deadline machinery, and competing-draft path this
  document gives transports to. Adopted there by reference; a formal
  `Updates:` relation is recorded if both publish.
- draft-ndn-fsm-session-00 — session state for interview/feedback stages;
  the conversational path's deliberation loop runs under it.
- draft-ndn-cross-repo-00 — citation and pinning forms reused by the
  ledger and reviewed-at anchor.
- rfcbot (Rust) — registered dispositions as the consensus record; the
  lineage of the consensus table this document extends.

## Changelog

- 2026-08-14: draft-00 created from the interview record (transports,
  registration-only standing, conversational scaling boundary,
  citation-sufficient transcription, git-issue-preferred issue substrate,
  post-publication registration chosen over full-track-only) and the
  revision-control adaptation: dispositions anchor to reviewed-at SHAs,
  in-band state shrinks to what a deterministic check reads, git history
  carries provenance, and automated staleness is deliberately left to
  the adjudicator's diff. Deviation from the reviewed shape: no
  `Updates:` header while the process BCP is itself a draft — adoption
  is by reference until both publish.
