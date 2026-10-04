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
and files shipped in the skill directory only. Its matcher is the `abnf`
package (MIT), vendored at `skill/vendor/abnf/` with its licence, a
`VERSION` file naming the pinned release and the SHA-256 of the release
archive it was copied from, and a `PATCHES` file listing every local
change and why. `rfc-abnf` MUST import the matcher from that directory
and refuse to run (exit 2) if the module it loaded resolves anywhere
else, so an installed copy of the package can never stand in for the
pinned one. [R-abnf-vendored]

```transcript @R-abnf-vendored
$ printf '```abnf\nr = "a"\n```\n' > d.md
$ printf 'a\n' | env -i PATH="$PATH" PYTHONNOUSERSITE=1 rfc-abnf d.md r; echo $?
0
$ rfc-abnf --version | grep -cE '^abnf [0-9.]+ sha256:[0-9a-f]{64} vendor:.*skill/vendor/abnf$'
1
```

### Matching

`rfc-abnf <doc.md> <rule>` MUST read the document grammar of `<doc.md>`,
read inputs from standard input, and exit 0 when every input matches
`<rule>`; otherwise it exits 1 and names the first input that does not
match. Matching MUST implement RFC 5234 and RFC 7405 (`%s` case-sensitive
and `%i` case-insensitive strings; plain quoted strings are
case-insensitive), with the RFC 5234 core rules predefined unless the
document redefines them, and MUST accept an input if and only if some
derivation of the rule produces the whole input — including the empty
input, when the rule derives it. [R-abnf-match]

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

The cases a careless matcher gets wrong — unordered alternation, a
repetition that has to give characters back, and an empty alternative:

```transcript @R-abnf-match
$ cat > d.md <<'EOF'
> ```abnf
> alt   = ( "a" / "ab" ) "c"
> giver = *"a" "a"
> empty = "(" empty ")" / ""
> ```
> EOF
$ printf 'abc\n' | rfc-abnf d.md alt; echo $?
0
$ printf 'a\n' | rfc-abnf d.md giver; echo $?
0
$ printf '(())\n' | rfc-abnf d.md empty; echo $?
0
$ printf '' | rfc-abnf --whole d.md empty; echo $?
0
```

**Input framing.** Inputs are records, and every record is the bytes
before a terminator. By default the terminator is LF, removed: a lone LF
is one empty record, `a` LF LF is the records `a` and the empty string,
and input that does not end with LF has a final record of the bytes
after the last one. `-z` MUST use NUL as the terminator instead, so a
record can contain CR, LF, or any octet but NUL. `--length` MUST read
records as `<decimal length>:<bytes>`, one after another with nothing
between them, so a record can hold any octet. `--whole` MUST read all of
standard input as exactly one record. Zero records MUST be an error
(exit 2, "no input"), so evidence cannot pass by testing nothing. The
same three framings apply to everything `rfc-abnf` prints (see
Generation). [R-abnf-framing]

```transcript @R-abnf-framing
$ printf '```abnf\nany = *OCTET\nempty = ""\n```\n' > d.md
$ printf '\n' > lone-lf; printf 'a\n\n' > two; printf '3:a\nb2:\0x' > framed; : > nothing
$ rfc-abnf d.md empty < lone-lf; echo $?
0
$ rfc-abnf --reject d.md empty < two >/dev/null 2>&1; echo $?
1
$ rfc-abnf --length --verdicts d.md any < framed
accept
accept
$ rfc-abnf d.md any < nothing; echo $?
! rfc-abnf: no input
2
```

`--verdicts` MUST print one line per record, `accept` or `reject`, in
order, instead of stopping at the first mismatch, so `rfc-abnf` can
serve as the batch parser of a differential check. `--reject` MUST invert the verdict: exit 0 only when every
record fails to match, so a set of near-misses is checked in full and
not only up to its first. Rules resolve across all `abnf` blocks of
the document, so a grammar split around prose is one grammar.

**Unsupported grammars.** The matcher decides what it can decide and
says so about the rest. `rfc-abnf` MUST refuse a document whose grammar
contains a left-recursive rule (direct or indirect), an unproductive
rule (one that derives no finite string, such as `r = r`), or a
prose value (`<...>`), with exit 2 naming the rule and the reason, before
matching anything. These are rejected rather than half-supported: a
matcher that loops or silently fails on them would make the oracle wrong
exactly where nobody looks. [R-abnf-unsupported]

```transcript @R-abnf-unsupported
$ printf '```abnf\nr = r "a" / "b"\n```\n' > left.md
$ printf 'b\n' > in
$ rfc-abnf left.md r < in
! rfc-abnf: unsupported grammar: r is left-recursive
? 2
$ printf '```abnf\nr = r\n```\n' > loop.md
$ rfc-abnf loop.md r < in
! rfc-abnf: unsupported grammar: r derives no finite string
? 2
```

**Matching budget.** Matching MUST terminate for every supported grammar
and input without changing the language it decides. A repetition takes
an iteration that consumes nothing only while it still needs iterations
to reach its minimum count — so `2("")` matches the empty input — and
never beyond it, so a nullable element under `*` cannot loop; such an
iteration past the minimum would add no string. `--max-steps` bounds the
work spent on one record, so an ambiguous grammar over a long input
cannot run without bound. Exhausting the budget is its own outcome —
exit 4, with `record <n>: matching budget exhausted` on standard error —
never a match and never a rejection. [R-abnf-budget]

```transcript @R-abnf-budget
$ printf '```abnf\nr = *( *"a" ) "b"\nexact = 2("")\nmixed = *( "" / "a" ) "b"\n```\n' > nullable.md
$ printf 'aaab\n' > in
$ rfc-abnf nullable.md r < in; echo $?
0
$ printf '' | rfc-abnf --whole nullable.md exact; echo $?
0
$ printf 'aab\n' | rfc-abnf nullable.md mixed; echo $?
0
$ printf '```abnf\nr = *( "a" / "aa" ) "b"\n```\n' > ambiguous.md
$ printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaac\n' > long
$ rfc-abnf --max-steps 10 ambiguous.md r < long 2> err; echo $?
4
$ grep -c 'record 1: matching budget exhausted' err
1
```

### Level 1 — witness tables

An evidence table whose marker carries `abnf=<rule>`
(`<!-- evidence: @R-<slug> abnf=<rule> -->`) is a witness table. Its rows
MUST have the columns `Input` and `Valid`; `Input` is a code span holding
the input, with `\|` for `|` and `\xHH` for any other octet a code span
cannot show (CR, LF, NUL); `Valid` is `yes` or `no`. The `abnf` adapter
MUST test every row against `<rule>` of the same document's grammar and
fail the block on the first row whose verdict differs, naming it. Further
columns are commentary. [R-abnf-witness]

```transcript @R-abnf-witness
$ cat > d.md <<'EOF'
> ```abnf
> word = 1*ALPHA
> line = 1*ALPHA CRLF
> ```
> <!-- evidence: @R-w abnf=word -->
> | Input | Valid |
> |---|---|
> | `abc` | yes |
> | `a1` | no |
> <!-- evidence: @R-l abnf=line -->
> | Input | Valid |
> |---|---|
> | `ab\x0D\x0A` | yes |
> | `ab\x0A` | no |
> EOF
$ rfc-abnf --witness d.md; echo $?
0
```

Witness rows are written from the prose, by someone other than whoever
wrote the generator, and never by running the grammar: they are the
check that does not share the matcher's or the generator's reading of
the grammar.

### Level 2 — output conformance

A transcript that asserts the shape of an implementation's output SHOULD
pipe that output through `rfc-abnf "$RFC_DOC" <rule>` in place of a
regular expression or a literal pattern. [R-abnf-output]

```transcript @R-abnf-output
$ cat > d.md <<'EOF'
> ```abnf
> id = 1*DIGIT "-" 1*ALPHA
> ```
> EOF
$ printf '42-abc\n7-x\n' > out
$ rfc-abnf d.md id < out; echo $?
0
```

The transcript runner MUST export `RFC_DOC`, the absolute path of the
document a block was tangled from, so a transcript can test output
against its own document's grammar without naming a path that depends on
where the series is checked out. [R-abnf-doc-env]

```transcript @R-abnf-doc-env
$ test -f "$RFC_DOC"; echo $?
0
$ grep -c '^# draft-ndn-abnf-conformance-00:' "$RFC_DOC"
1
```

### Level 3 — generation and differential checks

Level 3 is built only after levels 1 and 2 pass on every grammar in the
series, so the matcher is trusted before the generator is checked
against it.

**Generation.** `rfc-abnf <doc> <rule> --generate N` MUST print up to N
distinct strings that match `<rule>`, walking the vendored package's
parsed grammar (concatenation, alternation, repetition, options,
literals with their case rules, rule references) and checking each
string with the matcher before printing it. Within N and
`--max-length`, it MUST include each repetition's boundary counts among
the samples — minimum and maximum for a bounded repetition, minimum and
minimum plus `--max-repeat` for an unbounded one — so lengths at the
edges are exercised, not only lengths near the middle; a boundary it
could not include is reported on standard error as
`uncovered: <rule> <count>`. When the rule's language has fewer than
N strings within the bounds, or `--max-attempts` runs out, it prints what
it found and reports `exhausted: <found> of <N>` on standard error with
exit 0: generation that comes up short has still done its job, and the
evidence that needs samples decides whether a shortfall fails it. Output
uses the framing of Input framing; a string containing the active
terminator cannot be printed in LF or NUL framing, so it is skipped and
counted in an `unrepresentable: <n>` report, and `--length` represents
every string. [R-abnf-generate]

**Near-misses.** `--near-miss N` MUST print up to N strings the rule
rejects, each derived from a generated valid string by one mutation:
inserting, deleting, duplicating, or replacing one character (an
inserted or replacing character takes a value just outside a numeric
range or terminal set the grammar uses); dropping one element of a
concatenation; or swapping two adjacent elements of a concatenation. A
mutation that does not apply — deleting from the empty string, dropping
from a one-element concatenation, swapping identical adjacent elements —
produces no candidate, but every mutation selection, applicable or not,
counts against `--max-attempts`, so a grammar where few mutations apply
still ends. Each candidate is checked by
the matcher and printed only if rejected. It MUST report `near-misses: <found> from <tried>
candidates` on standard error, and with `--require-near-miss` exit 1 when
it found none, which evidence for a fixture whose grammar has near-misses
MUST use. [R-abnf-near-miss]

```transcript @R-abnf-generate
$ cat > d.md <<'EOF'
> ```abnf
> id  = 1*DIGIT "-" 1*ALPHA
> two = %s"a" / %s"b"
> ```
> EOF
$ rfc-abnf -z d.md id --generate 20 > valid
$ rfc-abnf -z d.md id < valid; echo $?
0
$ rfc-abnf d.md two --generate 5 > out 2> err; echo $?
0
$ cat err
exhausted: 2 of 5
$ grep -c . out
2
$ rfc-abnf d.md id --generate 5 --seed 3 > a; rfc-abnf d.md id --generate 5 --seed 3 > b
$ cmp -s a b; echo $?
0
```

```transcript @R-abnf-near-miss
$ cat > d.md <<'EOF'
> ```abnf
> claim = "x:" 1*DIGIT "/" 1*ALPHA
> ```
> EOF
$ rfc-abnf -z d.md claim --near-miss 30 --require-near-miss > misses 2>report; echo $?
0
$ rfc-abnf -z --reject d.md claim < misses; echo $?
0
$ grep -cE '^near-misses: [1-9][0-9]* from [0-9]+ candidates$' report
1
$ printf '```abnf\nnone = ""\n```\n' > empty.md
$ rfc-abnf empty.md none --near-miss 5 --require-near-miss --length > misses; echo $?
0
$ rfc-abnf --length --reject empty.md none < misses; echo $?
0
```

**Reproducibility.** Generated output MUST be a pure function of the
document grammar, the rule, every generation option (`--seed`, N,
`--max-repeat`, `--max-depth`, `--max-length`, `--max-attempts`), and the
generator's version, which `rfc-abnf --version` prints; a failure
reported with those values reproduces exactly.

**Differential checks.** `rfc-abnf <doc> <rule> --against '<command>'`
MUST run the command on every generated valid string and every
near-miss, passing the string's exact bytes on standard input, and
classify each run as **accept** (exit 0), **reject** (exit 1), or
**failure** (any other exit, a signal, or exceeding `--timeout`). It exits
0 only when it ran at least one valid string and at least one near-miss
(no near-miss is allowed only with `--allow-no-near-miss`, for a rule
that accepts every string over its alphabet), every valid string was
accepted, and every near-miss rejected;
1 on a disagreement, printing the input and which side accepted it; and
3 on any failure, printing the input and how the command failed — a
crash is never counted as a rejection. With `--batch`, the command is
started once and reads every sample on standard input in `--length`
framing — `<decimal length>:<bytes>` records with nothing between them —
so a sample can hold any octet, and writes one line per sample, in
order, that is exactly `accept` or `reject`. Any
other reply — a missing or extra line, a malformed line, a nonzero exit
of the batch command, or the whole batch exceeding `--timeout` — is a
failure (exit 3). Generation running short during `--against` is
reported and is not itself a failure; a side it leaves with no samples
is (exit 1, above). [R-abnf-differential]

```transcript @R-abnf-differential
$ cat > d.md <<'EOF'
> ```abnf
> id = 1*DIGIT "-" 1*ALPHA
> ```
> EOF
$ rfc-abnf d.md id --against 'grep -qE "^[0-9]+-[A-Za-z]+$"'; echo $?
0
$ rfc-abnf d.md id --against 'grep -qE "^[0-9]*-[A-Za-z]+$"' > /dev/null 2> err; echo $?
1
$ grep -c 'parser accepts a near-miss the grammar rejects' err
1
$ rfc-abnf d.md id --against 'exit 7' >/dev/null 2>&1; echo $?
3
```

The failure modes — a side with no samples, binary samples through a
batch, a malformed batch reply, and a timeout:

```transcript @R-abnf-differential
$ cat > d.md <<'EOF'
> ```abnf
> all  = *OCTET
> bin  = %x00 1*%x41-42 %x0A
> ```
> EOF
$ rfc-abnf d.md all --against 'true' >/dev/null 2> err; echo $?
1
$ grep -c 'no near-miss' err
1
$ rfc-abnf d.md all --allow-no-near-miss --against 'true' >/dev/null 2>&1; echo $?
0
$ rfc-abnf d.md bin --batch --against "rfc-abnf --length --verdicts $PWD/d.md bin"; echo $?
0
$ rfc-abnf d.md bin --batch --against 'echo maybe' >/dev/null 2>&1; echo $?
3
$ rfc-abnf d.md bin --timeout 1s --against 'sleep 5' >/dev/null 2>&1; echo $?
3
```

### Configuration

| Key | Type | Default | Description |
|---|---|---|---|
| `--seed` | Integer | `0` | Seed for generation; fixed so runs reproduce. |
| `--max-repeat` | Integer | `3` | Repetitions beyond the minimum that generation uses for an unbounded `*`. |
| `--max-depth` | Integer | `16` | Rule-expansion depth during generation; past it, generation takes the alternative with the shortest derivation (always defined, since unproductive rules are refused). |
| `--max-length` | Integer | `256` | Longest string generation emits, in octets; bounds output size and large mandatory repetitions. |
| `--max-attempts` | Integer | `50 × N` | Candidate strings generation or mutation tries before reporting exhaustion. |
| `--generate` / `--near-miss` with `--against` | Integer | `100` each | Samples per side of a differential check. |
| `--length` / `-z` / `--whole` | Framing | LF records | Input and output framing (see Input framing). |
| `--verdicts` | Flag | off | Print `accept`/`reject` per record instead of stopping at the first mismatch. |
| `--timeout` | Duration | `10s` | Per-run limit for `--against` (per batch with `--batch`); exceeding it is a failure, not a rejection. |
| `--max-steps` | Integer | `1000000` | Matcher steps allowed per record; exceeding it is exit 4, never a verdict. |

### Errors

| Condition | Exit | Recovery |
|---|---|---|
| Input does not match (or, under `--reject`, matches) | 1 | The message names the input; fix the output or the grammar. |
| No input records | 2 | Supply input; use `--whole` to test the empty input. |
| Differential ran no valid sample, or no near-miss | 1 | Raise N or `--max-attempts`; `--allow-no-near-miss` only for an all-accepting rule. |
| Matching budget exhausted | 4 | The grammar is too ambiguous for the input at this budget; raise `--max-steps` or restate the rule. |
| Witness row disagrees | 1 | Fix the grammar, or the row if the prose was misread. |
| Differential disagreement | 1 | The message names the input and which side accepted it. |
| No near-miss found under `--require-near-miss` | 1 | Raise `--max-attempts`, or the fixture's grammar has none. |
| Unknown rule, no `abnf` block, undefined reference | 2 | Name or define the rule; `rfc-lint` reports undefined references too. |
| Unsupported grammar (left recursion, unproductive rule, prose value) | 2 | Restate the rule without it. |
| Vendored matcher missing, or loaded from elsewhere | 2 | Restore `skill/vendor/abnf/`. |
| `--against` command crashes, is signalled, or times out | 3 | The parser failed; that is not a verdict. |

### Rollout

Levels 1 and 2 are delivered first; the claim grammar of
draft-ndn-fsm-session-01 is their first user. Level 3 follows once every
grammar in the series passes levels 1 and 2, applied first to the parsers
whose grammars the series already states: the info string of
draft-ndn-snippet-attributes-00 (parsed by `rfc-snippets`), the fsm
statements (parsed by `adapters/fsm` and `rfc-lint`), and the claim (read
back by `rfc-fsm-exec --audit`).

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

The vendored `abnf` package decides RFC 5234 and RFC 7405 correctly for
the grammars this series writes, including unordered alternation and
repetition that must give back characters (`*"a" "a"` matches `a`).
Tested before this draft, it fails on two things: left recursion
(`r = r "a" / "b"` raises a recursion error) and an empty alternative
(`r = "(" r ")" / ""` rejects the empty input). The first is refused up
front as an unsupported grammar; the second is a defect fixed in the
vendored copy and recorded in `PATCHES`. Writing a second matcher would
add a component to verify without adding capability; the generator is
the only part no candidate provides.

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
draft-ndn-sandbox-providers-00 when invoked from evidence. Generation is
bounded by `--max-depth`, `--max-repeat`, `--max-length`, and
`--max-attempts`; matching by `--max-steps`, after refusing
left-recursive and unproductive rules; and `--against` by `--timeout`.
Generation that runs out of budget ends early, reports its shortfall,
and still exits 0; evidence that needs samples — a differential,
`--require-near-miss` — fails when the shortfall leaves it without them.
Exhausting the matching budget is exit 4. No budget exhaustion is ever
reported as a match or a rejection. Inputs are never evaluated, only matched.

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
