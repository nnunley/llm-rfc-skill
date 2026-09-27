# draft-ndn-snippet-attributes-00: Snippet Attributes — Modes, Expected Results, Variants, Chunks and Parameter Tables

**Status:** DRAFT
**Category:** Standards-Track
**Corpus:** green
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)

## Abstract

Evidence blocks today carry one type and one requirement tag. This
document extends the fence info string with attributes, so a block can
state how it runs (`mode=`), which implementations it applies to
(`when=`), which shared chunks it builds on (`id=`, `uses=`,
`include=`), and what it must produce (a following `expect` block). A
table of parameters instantiates one template chunk per row. Every
existing evidence block keeps its meaning.

## Motivation

Language specifications need more from a snippet than "this block
passes". A Mica book example must say whether it runs as one task or as
a file-in; a conformance case must state the value or error it
produces; a requirement may behave differently in two implementations
while both are being brought to the same contract; and many cases share
setup or differ only in a few values. Existing Markdown conventions
cover these piecemeal — rustdoc's comma flags, Sphinx's paired output
blocks, ocaml-mdx's platform labels, noweb's named chunks, mdBook's
anchored includes, Org Babel's `:var` — and none has a written grammar.
This document fixes one grammar and one tangle contract so adapters stop
re-parsing Markdown and so a series can express cases as data.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **info string** — the text after a fence's opening backticks (CommonMark §4.5).
- **attribute** — a `key=value` item in the info string.
- **chunk** — a block named with `id=`; it is not evidence on its own.
- **variant** — one of several evidence blocks for the same requirement and type.
- **profile** — the facts (`key=value`) that describe the implementation under test.
- **sidecar** — a file `rfc-tangle` writes next to a tangled block: `.attrs`, `.expect`, `.expect-error`.

## Specification

### Info string grammar

An evidence or chunk fence MUST have an info string matching `info`
below. The first word names the type; a comma-joined word after it is a
legacy flag (rustdoc and mdBook books use `mica,eval`); a requirement tag
and attributes follow, separated by spaces. Values
containing spaces are double-quoted. A fence whose info string does not
match is not evidence. [R-info-grammar]

```abnf
info       = type *( "," flag ) *( 1*SP item )
type       = ALPHA *( ALPHA / DIGIT / "-" )
flag       = 1*( ALPHA / DIGIT / "-" )
item       = tag / attr
tag        = "@R-" slug
slug       = ( %x61-7A / DIGIT ) *( %x61-7A / DIGIT / "-" )
attr       = key "=" value
key        = ALPHA *( ALPHA / DIGIT / "-" )
value      = bare / quoted
bare       = 1*( %x21 / %x23-5F / %x61-7E )
quoted     = DQUOTE *( %x20-21 / %x23-5F / %x61-7E ) DQUOTE
```

<!-- evidence: @R-info-grammar -->
| Info string | Valid | Reads as |
|---|---|---|
| `transcript @R-tangle` | yes | type `transcript`, tag `tangle` |
| `mica,eval @R-leg` | yes | type `mica`, flag `eval`, tag `leg` |
| `mica mode=eval @R-add` | yes | type `mica`, `mode=eval`, tag `add` |
| `sh @R-run note="two words"` | yes | `note` is `two words` |
| `sh id=setup` | yes | chunk `setup` |
| `sh @R-x mode=` | no | empty value |
| `sh @R-X` | no | upper-case slug |
| `sh mode=a b` | no | `b` is neither a tag nor an attribute |

`rfc-tangle` MUST write a block's attributes to a sidecar `<file>.attrs`,
one `key=value` per line in written order, and MUST record legacy flags
as a single `flags=` line (comma-joined). A block with neither writes no
sidecar, so existing corpora tangle unchanged. [R-attrs-sidecar]

```transcript @R-attrs-sidecar
$ cat > draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> Runs. [R-run]
> ```sh @R-run mode=eval note="two words"
> true
> ```
> Legacy. [R-leg]
> ```mica,eval @R-leg
> return 1
> ```
> EOF
$ rfc-tangle draft-a-x-00.md out | sort
out/draft-a-x-00.leg.mica
out/draft-a-x-00.run.sh
$ cat out/draft-a-x-00.run.sh.attrs
mode=eval
note=two words
$ cat out/draft-a-x-00.leg.mica.attrs
flags=eval
```

The reserved attribute keys are `mode`, `when`, `id`, `uses`,
`include`, and `template` (on an evidence-table comment). Any other key
belongs to the adapter for the block's type, which MUST receive it
unchanged in the sidecar. `rfc-lint` MUST reject a malformed info string
on a fence that carries a tag or an `id=`. [R-info-lint]

```transcript @R-info-lint
$ printf '# draft-a-x-00: X\n**Status:** DRAFT\nX. [R-x]\n```sh @R-x mode=\n```\n' > draft-a-x-00.md
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "malformed info string"
1
```

### Expected results

One or more blocks of type `expect` or `expect-error` that immediately
follow an evidence block (blank lines allowed between) state what that
block produces. `rfc-tangle` MUST write them as sidecars
`<file>.expect` and `<file>.expect-error`; an `expect` block anywhere
else is an error. How "produce" is observed is the adapter's decision;
how expected text is matched is fixed here. [R-expect-pairing]

```transcript @R-expect-pairing
$ cat > draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> Adds. [R-add]
> ```mica mode=eval @R-add
> return 1 + 1
> ```
> ```expect
> 2
> ```
> EOF
$ rfc-tangle draft-a-x-00.md out | sort
out/draft-a-x-00.add.mica
$ cat out/draft-a-x-00.add.mica.expect
2
```

`rfc-expect <actual> <expected>` MUST compare line by line after
dropping trailing whitespace on each line and trailing blank lines:
a line of exactly `...` matches zero or more lines; within a line,
`{{regex}}` matches that regular expression and all other text matches
literally. It exits 0 on a match and 1 with a unified diff otherwise.
Adapters that check expected results SHOULD call it rather than
implement matching. [R-expect-match]

```transcript @R-expect-match
$ printf 'task 7 complete\nline a\nline b\nvalue: 42\n' > actual
$ printf 'task {{[0-9]+}} complete\n...\nvalue: 42\n' > want
$ rfc-expect actual want
$ printf 'value: 43\n' > want
$ rfc-expect actual want > /dev/null
? 1
```

### Variants and profiles

A block MAY carry `when=key:value[,key:value]`; it applies only when
every named fact equals the profile's value. The profile is the
environment variable `RFC_PROFILE` (space-separated `key=value`) or,
when that is unset, the series file `profile` (one `key=value` per
line). `rfc-run` MUST report a block whose `when=` does not hold as
`N/A` and count it neither as a pass nor as a failure. When one
requirement has several blocks of the same type, `rfc-tangle` MUST
number them in document order as `<base>.<slug>.<n>.<type>` so no
variant overwrites another. [R-when-selection]

```transcript @R-when-selection
$ mkdir -p s/adapters
$ printf '#!/bin/sh\nexit 0\n' > s/adapters/sh; chmod +x s/adapters/sh
$ cat > s/draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> Runs. [R-run]
> ```sh @R-run when=impl:alpha
> true
> ```
> ```sh @R-run when=impl:beta
> true
> ```
> EOF
$ RFC_PROFILE="impl=alpha" rfc-run --sandbox none s/draft-a-x-00.md | grep -v "^rfc-run:" | sort
N/A draft-a-x-00.run.2.sh
PASS draft-a-x-00.run.1.sh
```

### Chunks and includes

A block with `id=name` and no tag is a chunk. A block with
`uses=a,b` MUST be tangled as the contents of chunks `a` then `b`,
then its own body; an unknown name or a cycle is an error.
`include=path#anchor` MUST insert the lines of `path` (relative to the
document's directory) between a line containing `ANCHOR: anchor` and a
line containing `ANCHOR_END: anchor`, marker lines excluded, before the
block's own body; without `#anchor` the whole file is inserted.
[R-chunk-uses]

```transcript @R-chunk-uses
$ printf 'x = 1\n# ANCHOR: two\ny = 2\n# ANCHOR_END: two\n' > lib.txt
$ cat > draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> ```sh id=setup
> echo setup
> ```
> Uses. [R-use]
> ```sh @R-use uses=setup include=lib.txt#two
> echo body
> ```
> EOF
$ rfc-tangle draft-a-x-00.md out > /dev/null
$ cat out/draft-a-x-00.use.sh
echo setup
y = 2
echo body
```

An `include=` path MUST resolve inside the document's directory; an
absolute path or one that climbs out with `..` is an error, so a series
cannot tangle files from elsewhere on the machine. [R-include-confined]

```transcript @R-include-confined
$ printf '# draft-a-x-00: X\nX. [R-x]\n```sh @R-x include=../escape.txt\nfoo\n```\n' > draft-a-x-00.md
$ rfc-tangle draft-a-x-00.md out 2>&1 | grep -c "outside the document directory"
1
```

### Parameter tables

An evidence table MAY name a chunk by adding `template=name` after the
tag in its evidence comment. Each data row MUST become one
tangled case `<base>.<slug>.<n>.<type>` (the chunk's type), whose body
is the chunk with every `{{column}}` replaced by that row's cell. A
column named `expect` or `expect-error` MUST instead become that case's
sidecar. The chunk's attributes other than `id=` carry over to every case. [R-template-rows]

```transcript @R-template-rows
$ cat > draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> ```mica id=len-case mode=eval
> return len({{input}})
> ```
> Counts. [R-len]
> ```mica mode=eval @R-len
> return len([])
> ```
> <!-- evidence: @R-len template=len-case -->
> | input | expect |
> |---|---|
> | `[1, 2]` | 2 |
> | `"héllo"` | 5 |
> | `"a\|b\n"` | 4 |
> EOF
$ rfc-tangle draft-a-x-00.md out
out/draft-a-x-00.len.1.mica
out/draft-a-x-00.len.2.mica
out/draft-a-x-00.len.3.mica
out/draft-a-x-00.len.4.mica
$ cat out/draft-a-x-00.len.3.mica out/draft-a-x-00.len.3.mica.expect out/draft-a-x-00.len.3.mica.attrs
return len("héllo")
5
mode=eval
$ cat out/draft-a-x-00.len.4.mica
return len("a|b\n")
```

Cells are read as written, except that `\|` stands for a literal `|`
(the table's own escape) and one pair of surrounding backticks is
removed so a cell can show code; every other backslash is kept. Blocks
and table rows tagged for the same requirement and type are numbered
together in document order. `rfc-lint` MUST reject a
template whose chunk does not exist and a `{{column}}` placeholder with
no matching column. [R-template-lint]

```transcript @R-template-lint
$ cat > draft-a-x-00.md <<'EOF'
> # draft-a-x-00: X
> **Status:** DRAFT
> ```sh id=case
> echo {{missing}}
> ```
> X. [R-x]
> <!-- evidence: @R-x template=case -->
> | input |
> |---|
> | 1 |
> EOF
$ rfc-lint draft-a-x-00.md 2>&1 | grep -c "placeholder {{missing}} has no column"
1
```

### Tangle contract summary

| Source | Tangled file | Sidecars |
|---|---|---|
| one block tagged `@R-s` of type `t` | `<base>.s.t` | `.attrs` if attributes or flags |
| several blocks tagged `@R-s` of type `t` | `<base>.s.<n>.t` | per block |
| table with `template=c` | `<base>.s.<n>.<type of c>` per row | `.attrs` from `c`; `.expect`/`.expect-error` from columns |
| `expect` / `expect-error` block after evidence | — | `.expect` / `.expect-error` |
| chunk (`id=`, no tag) | none | none |

`rfc-run` MUST NOT dispatch a sidecar as evidence.

## Out of Scope

- Matching expected results structurally (as values rather than text) —
  a type's adapter may do so; extension point: the adapter contract of
  draft-ndn-evidence-adapters-00.
- Boolean expressions in `when=` beyond conjunction — extension point:
  the `when` attribute value grammar.
- Includes of other Markdown documents' chunks — extension point: a
  future `uses=doc#chunk` form.

## Alternatives Considered

**Why not Pandoc attribute braces (`{.mica #id key=val}`)?** They are
not a CommonMark info string convention most renderers show, and the
books this must read (mdBook, rustdoc) use bare words and commas.
`key=value` items keep the fence readable and parse with the same rule.

**Why not a comment pragma before the fence (ocaml-mdx `<!-- $MDX -->`)?**
It separates a block's meaning from the block. Attributes on the fence
line travel with the block when it is moved or quoted.

**Why keep comma flags at all?** Books shared with other harnesses
(Rust mica's book test reads `mica,eval`) must keep working; recording
them as `flags=` lets a type's profile map them to `mode=` without
another spelling.

**Why templates from tables instead of Org Babel `:var` calls?** A table
is a readable list of cases for a person and data for the tangler; a
call syntax would be a small programming language inside Markdown.

## Security Considerations

Includes read files from disk into evidence that is then executed, so
they are confined to the document's directory ([R-include-confined]).
Template cells are substituted as text into a chunk that an adapter runs;
a series that accepts tables from untrusted authors inherits whatever
its adapters do with that text, and sandbox providers
(draft-ndn-sandbox-providers-00) remain the containment boundary.
`when=` only selects blocks; it cannot widen what a block may do.

## References

- CommonMark Spec 0.31.2, §4.5 Fenced code blocks.
- RFC 5234 / RFC 7405 — ABNF.
- draft-ndn-authoring-rfcs-00 — embedded evidence, `rfc-tangle`.
- draft-ndn-evidence-adapters-00 — adapter resolution and contract.
- draft-ndn-sandbox-providers-00 — isolation of adapter runs.
- rustdoc documentation tests; mdBook `{{#include}}` anchors; Sphinx
  `testcode`/`testoutput`; ocaml-mdx labels; LLVM FileCheck `{{regex}}`;
  noweb and Entangled chunks; Org Babel header arguments.
