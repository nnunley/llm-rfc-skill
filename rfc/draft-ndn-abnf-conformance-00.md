# draft-ndn-abnf-conformance-00: Grammar Conformance for ABNF in RFCs

**Status:** DRAFT
**Corpus:** red (spec-first — the evidence is the acceptance criteria for rfc-abnf)
**Category:** Experimental
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)

## Abstract

ABNF in this series is checked for syntax only. This document makes a
document's grammar an executable oracle at three levels: witness strings
tested against the grammar itself, implementation output tested against
the grammar, and generated strings — valid and near-miss — fed to the
implementation's parser so the parser and the grammar must agree in both
directions. It specifies one dependency-free tool, `rfc-abnf`, and the
evidence forms that use it. Matching is delegated to the `abnf` Python
package, vendored at a pinned version; this document adds the generator,
the evidence forms, and the semantics they must hold to.

## Motivation

The series holds 13 ABNF blocks across 9 drafts. `rfc-lint` checks their
rule syntax, undefined references, and duplicates — whether each grammar
is well formed, not whether it means what its prose says or whether any
implementation honors it. The existing evidence works around the grammar
rather than through it: draft-ndn-snippet-attributes-00 proves its
info-string grammar with a witness table run against the tangler's own
parser, so a parser and grammar that disagree pass together; and
draft-ndn-fsm-session-01's first claim evidence was a hand-written
regular expression that only resembled the `claim` rule, free to drift
from it. This document provides a matcher and generator driven by the
grammar in the document, so the grammar is the thing tested and the
thing every implementation is tested against.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **document grammar** — every `abnf` fenced block in one RFC, read in
  document order as one rule set.
- **match** — an input matches a rule when at least one derivation of the
  rule produces exactly the whole input.
- **witness** — an input paired with the verdict (valid or invalid) the
  prose intends for a named rule.
- **near-miss** — a string one mutation away from a valid string, which
  the document grammar rejects.
- **differential check** — running generated valid strings and
  near-misses through an implementation's parser and requiring its
  verdicts to equal the grammar's.

## Specification

This document defines the `rfc-abnf` tool, its matching and generation
semantics, and three evidence forms. It does NOT define ABNF, which is
RFC 5234 with the case-sensitive strings of RFC 7405, and it does NOT
change what `rfc-lint` checks.

**The grammar is the oracle.** Evidence about a grammar-shaped value
MUST be decided by the document grammar, never by a pattern written
beside it; a pattern beside a grammar is a second, unchecked grammar.

**Unordered alternation.** ABNF alternation has no order. A matcher that
commits to the first alternative that succeeds (PEG semantics) accepts a
different language for some grammars and is not a conforming matcher.

**No install step.** `rfc-abnf` MUST run with the Python standard library
and files shipped in the skill directory only: its matcher is the `abnf`
package (MIT), vendored at `skill/vendor/abnf/` with its licence and a
`VERSION` file naming the pinned release, so `make install` remains a
copy of the skill directory and no machine needs network access or
`pip`. [R-abnf-vendored]

```transcript @R-abnf-vendored
$ printf '```abnf\nr = "a"\n```\n' > d.md
$ printf 'a\n' | env -i PATH="$PATH" PYTHONNOUSERSITE=1 rfc-abnf d.md r; echo $?
0
$ test -f "$(dirname "$(command -v rfc-abnf)")/vendor/abnf/VERSION"; echo $?
0
```

### Matching

`rfc-abnf <doc.md> <rule>` MUST read the document grammar of `<doc.md>`,
read inputs from standard input one per line, and exit 0 when every
input matches `<rule>`; otherwise it exits 1 and names the first input
that does not match. Matching MUST implement RFC 5234 and RFC 7405
(`%s` case-sensitive and `%i` case-insensitive strings; plain quoted
strings are case-insensitive), with the RFC 5234 core rules (`ALPHA`,
`BIT`, `CHAR`, `CR`, `CRLF`, `CTL`, `DIGIT`, `DQUOTE`, `HEXDIG`, `HTAB`,
`LF`, `LWSP`, `OCTET`, `SP`, `VCHAR`, `WSP`) predefined unless the
document redefines them, and MUST accept an input if and only if some
derivation of the rule produces the whole input. [R-abnf-match]

```transcript @R-abnf-match
$ cat > d.md <<'EOF'
> ```abnf
> pair = word SP word
> word = 1*ALPHA
> ```
> EOF
$ printf 'ab cd\n' | rfc-abnf d.md pair; echo $?
0
$ printf 'ab  cd\n' | rfc-abnf d.md pair; echo $?
! rfc-abnf: input 1 does not match pair: "ab  cd"
1
```

Unordered alternation, the case a first-match matcher gets wrong:

```transcript @R-abnf-match
$ cat > d.md <<'EOF'
> ```abnf
> r = ( "a" / "ab" ) "c"
> ```
> EOF
$ printf 'abc\n' | rfc-abnf d.md r; echo $?
0
```

`--whole` MUST treat all of standard input as one input, for values that
span lines. Rules MUST resolve across all `abnf` blocks of the document,
so a grammar split around prose is one grammar.

### Level 1 — witness tables

An evidence table whose marker carries `abnf=<rule>`
(`<!-- evidence: @R-<slug> abnf=<rule> -->`) is a witness table. Its rows
MUST have the columns `Input` and `Valid`; `Input` is a code span holding
the input literally (a `|` written `\|`), `Valid` is `yes` or `no`. The
`abnf` adapter MUST test every row against `<rule>` of the same
document's grammar and fail the block on the first row whose verdict
differs, naming it. Further columns are commentary and are ignored.
[R-abnf-witness]

```transcript @R-abnf-witness
$ cat > d.md <<'EOF'
> ```abnf
> word = 1*ALPHA
> ```
> <!-- evidence: @R-w abnf=word -->
> | Input | Valid |
> |---|---|
> | `abc` | yes |
> | `a1` | no |
> EOF
$ rfc-abnf --witness d.md; echo $?
0
```

A witness table states what the prose intends and the grammar is held to
it; rows are written from the prose, not by running the grammar.

### Level 2 — output conformance

A transcript that asserts the shape of an implementation's output SHOULD
pipe that output through `rfc-abnf "$RFC_DOC" <rule>` in place of a
regular expression or a literal pattern. [R-abnf-output]

The transcript runner MUST export `RFC_DOC`, the absolute path of the
document a block was tangled from, so a transcript can test output
against its own document's grammar without naming a path that depends
on where the series is checked out. [R-abnf-doc-env]

```transcript @R-abnf-doc-env
$ test -f "$RFC_DOC"; echo $?
0
$ grep -c '^# draft-ndn-abnf-conformance-00:' "$RFC_DOC"
1
```

```transcript @R-abnf-output
$ cat > d.md <<'EOF'
> ```abnf
> id = 1*DIGIT "-" 1*ALPHA
> ```
> EOF
$ printf '42-abc\n7-x\n' | rfc-abnf d.md id; echo $?
0
```

### Level 3 — generation and differential checks

Generation walks the vendored package's parsed grammar — concatenation,
alternation, repetition with its bounds, options, literals and their case
rules, and rule references — and every string it produces is checked by
the same matcher before it is printed.

`rfc-abnf <doc> <rule> --generate N` MUST print N strings that match
`<rule>`, and `--near-miss N` MUST print up to N strings that `<rule>`
rejects, each derived from a generated valid string by one mutation:
deleting, duplicating, or replacing one character, where a replacement
takes a value just outside a numeric range or terminal set the grammar
uses. Every printed string MUST be verified against the grammar before it
is printed, so a valid string never appears among near-misses. Output
MUST be a pure function of the document grammar, the rule, N, and
`--seed` (default 0), so a failure reproduces. [R-abnf-generate]

```transcript @R-abnf-generate
$ cat > d.md <<'EOF'
> ```abnf
> id = 1*DIGIT "-" 1*ALPHA
> ```
> EOF
$ rfc-abnf d.md id --generate 20 | rfc-abnf d.md id; echo $?
0
$ rfc-abnf d.md id --near-miss 20 | while read -r s; do printf '%s\n' "$s" | rfc-abnf d.md id 2>/dev/null && echo "accepted: $s"; done | wc -l
0
$ test "$(rfc-abnf d.md id --generate 5 --seed 3)" = "$(rfc-abnf d.md id --generate 5 --seed 3)"; echo $?
0
```

`rfc-abnf <doc> <rule> --against '<command>'` MUST run the command once
per generated valid string and once per near-miss, passing the string on
standard input, and MUST exit 0 only when the command exits 0 for every
valid string and nonzero for every near-miss; otherwise it exits 1 and
prints the first disagreeing input and which side accepted it.
[R-abnf-differential]

```transcript @R-abnf-differential
$ cat > d.md <<'EOF'
> ```abnf
> id = 1*DIGIT "-" 1*ALPHA
> ```
> EOF
$ rfc-abnf d.md id --against 'grep -qE "^[0-9]+-[A-Za-z]+$"'; echo $?
0
$ rfc-abnf d.md id --against 'grep -qE "^[0-9]*-[A-Za-z]+$"' 2>&1 | head -1
parser accepts a near-miss the grammar rejects: "-a"
```

A grammar with no near-misses (a rule that accepts every string over its
alphabet) prints none and is not an error; `--against` then checks the
valid side only and says so.

### Configuration

| Key | Type | Default | Description |
|---|---|---|---|
| `--seed` | Integer | `0` | Seed for generation; fixed by default so runs reproduce. |
| `--max-repeat` | Integer | `3` | Extra repetitions generation adds beyond a repetition's minimum for an unbounded `*`. Small, because coverage comes from N, not from length. |
| `--max-depth` | Integer | `16` | Rule-expansion depth during generation; a branch that would exceed it takes its shortest alternative. Bounds recursive grammars. |
| `--generate` / `--near-miss` with `--against` | Integer | `100` each | Strings per side of a differential check. |

### Errors

| Condition | Exit | Recovery |
|---|---|---|
| Input does not match | 1 | The message names the input; fix the output or the grammar. |
| Unknown rule | 2 | Name a rule defined in the document grammar. |
| Document has no `abnf` block | 2 | The document defines no grammar to test against. |
| Undefined rule reference | 2 | Define it; `rfc-lint` reports the same error. |
| Differential disagreement | 1 | The message names the input and which side accepted it. |
| Witness row disagrees | 1 | Fix the grammar, or the row if the prose was misread. |

### Rollout

Levels 1 and 2 are delivered first; the claim grammar of
draft-ndn-fsm-session-01 is their first user. Level 3 then applies first
to the parsers whose grammars this series already states: the info
string of draft-ndn-snippet-attributes-00 (parsed by `rfc-snippets`),
the fsm statements (parsed by `adapters/fsm` and `rfc-lint`), and the
claim (read back by `rfc-fsm-exec --audit`).

## Alternatives Considered

### Why not keep regular expressions beside grammars?

A pattern beside a grammar is a second grammar nothing checks against
the first; that drift is the problem this document exists to remove.

### Why not compile ABNF to a PEG?

PEG's ordered choice accepts a different language than ABNF's unordered
alternation for some grammars: `( "a" / "ab" ) "c"` rejects `abc` under
PEG. The oracle would be wrong in exactly the cases that are hard to see.

### Why not compile ABNF to a regular expression (abnf-to-regexp)?

A backtracking engine with a full match decides a non-recursive
grammar's language exactly, so this would be correct for every grammar
the series has today. It is rejected because it cannot express recursive
rules, the converter pins an older `abnf` and adds three further
packages, and generating strings from a regular expression needs yet
another library.

### Why not write a matcher?

The vendored `abnf` package already decides RFC 5234 and RFC 7405
correctly, including unordered alternation and repetition that must give
back characters (`*"a" "a"` matches `a`). Writing a second one would add
a component to verify without adding capability; the generator is the
only part no candidate provides.

### Why not generate with exrex or hypothesis?

`exrex` is AGPL-licensed, a poor fit for an MIT/CC0 series. `hypothesis`
(`from_regex`) is large, generates from regular expressions rather than
the grammar, and produces no near-misses.

### Why vendor rather than depend on pip?

Every other tool in the skill runs from a copy of the skill directory.
A pip dependency makes the conformance gate depend on an install step,
and an optional one lets the gate pass on machines that never ran the
checks — a broken runner reported as success.

### Why not compile each rule to an fsm and walk it?

Considered: every grammar in the series is non-recursive, so each rule
is a finite automaton, and matching, generation, and near-misses become
walks over it. It is set aside because a matcher already exists; it
remains the natural route if the generator outgrows the grammar tree.

### Why not keep testing grammars through the implementation's parser?

That tests the parser, not the grammar: a parser and a grammar that
disagree pass together. Witness tables against the grammar and
differential checks against the parser test the two separately and then
against each other.

## Security Considerations

`rfc-abnf --against` executes a command written in the document, the same
trust posture as a transcript, and runs under the sandbox provider of
draft-ndn-sandbox-providers-00 when invoked from evidence. Matching and
generation are bounded: generation by `--max-depth` and `--max-repeat`,
and matching by memoized search over input positions, so a recursive or
ambiguous grammar cannot make the tool run without bound on finite
input. Inputs are never evaluated, only matched.

## References

- RFC 5234 — Augmented BNF for Syntax Specifications: ABNF.
- RFC 7405 — Case-Sensitive String Support in ABNF.
- draft-ndn-snippet-attributes-00 — the info-string grammar and its
  parser-run witness table.
- draft-ndn-fsm-session-01 — the claim grammar, the first user of levels
  1 and 2.
- draft-ndn-sandbox-providers-00 — where `--against` commands run.
- The `abnf` Python package (MIT) — the vendored matcher and grammar
  tree.
