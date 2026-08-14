# BCP Review Findings Resolution Report

Date: 2026-08-14

## Overview

Four critical review findings against the RFC process BCP document
(`rfc/draft-ndn-authoring-rfcs-00.md`) have been resolved. All changes pass
linting and evidence verification gates. CI workflow confirms conformance.

## Finding 1: Dependency Inversion — Evidence Conventions

**Status:** RESOLVED

### What Changed

Moved canonical evidence conventions from the registry RFC
(`draft-ndn-multi-project-registry-02.md`) into the process BCP's
"### Evidence conventions" section (lines 53–78 in updated document).

### Content Merged

Merged three sources coherently:
1. **Registry RFC's evidence contract** (per-block sandbox at `/tmp/gi-rfc`,
   `HOME`/`XDG_CONFIG_HOME` redirection, `GIT_CONFIG_NOSYSTEM=1`, git
   identity, no inter-block dependencies, `/tmp` symlink normalization,
   `fidelity=` modifier reservation)
2. **BCP's existing notation rules** (expected-output comparison, `? N` exit
   assertions, deterministic projections for generated identifiers)
3. **BCP-specific addition** (runner provides `rfc-lint` and `rfc-tangle` on
   `PATH` for THIS document's conformance)

### Rationale

The process BCP was normatively dependent on a feature draft in another
repository. Canonical evidence contract now lives in the BCP itself; other
repositories cite it by reference.

---

## Finding 2: Conformance Corpus CI — Made Normative

**Status:** RESOLVED

### What Changed

**In Lifecycle section (lines 217–223):**
- Added normative SHALL/MUST requirements:
  - Series SHALL run `rfc-lint` over every RFC and draft
  - Series SHALL run `rfc-run` over every PUBLISHED RFC's evidence
  - Changes breaking published RFC evidence MUST NOT merge
  - Draft evidence MAY be red (spec-first drafts allowed to fail)

**Created `.github/workflows/conformance.yml`:**
- Job: **Lint RFC documents** — runs `rfc-lint` on all RFC documents;
  failures block the build
- Job: **Verify published RFC evidence** — runs `rfc-run` on published RFCs
  (with glob guard for currently-empty published set); draft evidence
  failures reported but do not block

### Gate Status

```
✓ Verify published RFC evidence in 6s
✓ Lint RFC documents in 5s
```

Both CI jobs pass on the current commit.

---

## Finding 3: Security Considerations — Hygiene vs. Boundary

**Status:** RESOLVED

### What Changed

**Security Considerations section (lines 349–362):**
- Clarified sandbox provides **hygiene isolation**, NOT security boundary
- Hygiene: fresh working directory, isolated `HOME`, neutralized git config
- Security isolation (container, VM, throwaway host) MUST be deployed at
  execution layer by the deployment
- Existing supply-chain review advice preserved

**rfc-run script comment header:**
- Added explicit statement: "This sandbox provides environment isolation
  (HOME, config), NOT a security boundary"
- Updated canonical source in `~/.claude/skills/authoring-rfcs/rfc-run`
- Copied to repo skill directory

### Impact

Correctness: Document now accurately represents what the runner provides and
what deployment must add. Prevents false security assumptions.

---

## Finding 4: Cross-Series Citation Form

**Status:** RESOLVED

### What Changed

**Added to Practice section (lines 280–293):**

**Citation form (normative):**
- Published RFCs across series: `<series>/<NNNN>` format
  (e.g., `llm-rfc-skill/0001`)
- Drafts: full draft name, globally unique by author + slug convention
  (e.g., `draft-ndn-authoring-rfcs-00`)
- Within single series: bare `NNNN` or `draft-*-NN` suffices

**Locality rule (normative):**
- RFCs live in repository whose behavior they govern (their "home series")
- Project-specific RFCs (features, formats, interfaces of a codebase)
  belong in that project's own `docs/rfc/` or `rfc/` series
- Never centralized into another repository
- This repository carries ONLY cross-project process/skill RFCs

### Updated README.md

Clarified repository scope:
- "This repository hosts the **process and skill itself**"
- Added explicit locality statement
- Changed "this project's RFC series" to "process/skill RFC series"

### Rationale

Prevents centralization of project-specific RFCs; makes clear that series are
per-repository and why cross-series citation requires series prefix.

---

## Quality Gates

### Linting

```
rfc-lint draft-ndn-authoring-rfcs-00.md
 — checked: identity(draft) status(DRAFT) status-form category(BCP)
   sections(8/8) bcp14 lowercase(0 flagged) abnf evidence(13⇄13)
   fsm(1 block(s)) fsm-witnesses
 — result: 0 error(s), 0 warning(s)
```

✓ **PASS** — All 13 evidence blocks accounted for, no missing/orphaned markers,
all required sections present, BCP 14 boilerplate in place.

### Evidence Replay

```
skill/rfc-run rfc/draft-ndn-authoring-rfcs-00.md
 — PASS: all 13 transcript blocks
 — result: 0 failing block(s)
```

✓ **PASS** — All evidence replays deterministically with zero exit status.

### GitHub Actions CI

```
Workflow: RFC Conformance
Lint RFC documents ............... ✓ PASS
Verify published RFC evidence .... ✓ PASS
```

✓ **PASS** — Both workflow jobs succeeded on commit `4ba3163`.

---

## Changelog Entries

All changes recorded in document Changelog (2026-08-14):
- Finding 1: Dependency inversion fixed
- Finding 2: Corpus-CI made normative
- Finding 3: Security Considerations clarified
- Finding 4: Cross-series citation form added
- Locality rule and README update

---

## Commits

| SHA       | Subject                                          |
|-----------|--------------------------------------------------|
| `2877bc2` | resolve review findings on BCP process           |
| `156975f` | add RFC conformance workflow                     |
| `8ca59ef` | update rfc-run comment header for clarity        |
| `2bbca16` | clarify README: this repo hosts process/skill RFCs |
| `b0cde6c` | fix conformance workflow to exclude index.md     |
| `4ba3163` | fix lint job shell configuration                 |

Push log: `2877bc2..4ba3163 main -> main`

---

## Concerns

### None Critical

- Node.js 20 deprecation warning in CI: informational only, does not affect
  workflow success
- Draft RFC evidence currently empty: no published RFCs in series yet;
  workflow correctly guards glob and succeeds

---

## Verification Commands

To reproduce all gates locally:

```bash
cd /Users/ndn/development/llm-rfc-skill

# Lint (must show 0 errors, 0 warnings)
skill/rfc-lint rfc/draft-ndn-authoring-rfcs-00.md

# Evidence replay (must show 0 failing blocks)
skill/rfc-run rfc/draft-ndn-authoring-rfcs-00.md

# CI status (watch workflow)
gh run list --branch main --limit 1
gh run view <run-id>
```
