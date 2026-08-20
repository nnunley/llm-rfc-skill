# draft-ndn-sandbox-providers-00: Configurable Sandbox Providers

**Status:** DRAFT
**Category:** Experimental
**Authors:** Norman Nunley, Jr <nnunley@gmail.com>, Claude (drafting agent)
**Date:** 2026-08-14

## Abstract

Corpus execution gains a configurable isolation seam: a **sandbox
provider** is an executable that wraps an adapter invocation, and the
runner — not the adapter, not the document — decides which provider wraps
which run. A series selects its provider with a one-line profile file;
invokers override with a flag; a selected provider that cannot be resolved
is a hard error, never a silent bare run. The built-in `env-scrub`
provider reproduces today's hygiene sandbox; stronger providers (container,
namespace, or policy sandboxes) drop in without touching an adapter or a
document.

## Motivation

The evidence-adapters design gave adapters ownership of "environment
concerns," and the bootstrap `transcript` adapter carries an inline
hygiene sandbox as a result. That coupling has two costs. First, the
isolation level is fixed per adapter: the transcript sandbox is explicitly
"hygiene, not a security boundary," and there is no way for a deployment
that needs a real boundary (running a foreign series' corpus) to get one
without editing adapters. Second, every new adapter must reinvent or skip
isolation.

The seam adopted here is spacedock's safehouse integration: **detect** a
workdir profile, **gate** on the wrapper binary actually resolving (with
an actionable install hint when it does not), and **wrap** the inner argv
as `wrapper [flags] -- inner...`, keeping the seam itself
provider-agnostic — each provider owns only its own flag vocabulary.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174)
when, and only when, they appear in all capitals, as shown here.

- **sandbox provider** — an executable that runs an inner command under
  isolation: `provider [flags] -- command args...`.
- **profile** — the series-local file `sandbox` (beside the RFCs) whose
  first effective line names the provider and its flags.
- **bare run** — an adapter invocation with no provider wrapped around it.

## Specification

### The provider contract

A provider is an executable invoked as `provider [flags] -- command
args...`. It MUST execute the inner command under its isolation and exit
with the inner command's status (or its own nonzero status if isolation
setup fails). The runner wraps *outside* the adapter: adapters MUST NOT
need to know whether they are sandboxed, and providers MUST NOT interpret
adapter output. [R-provider-contract]

```transcript @R-provider-contract
$ mkdir -p sandboxes adapters
$ printf '#!/bin/sh\nwhile [ "$#" -gt 0 ] && [ "$1" != "--" ]; do shift; done\nshift\nRFC_SANDBOXED=1 exec "$@"\n' > sandboxes/marker
$ chmod +x sandboxes/marker
$ printf '#!/bin/sh\n[ "$RFC_SANDBOXED" = 1 ]\n' > adapters/probe
$ chmod +x adapters/probe
$ printf 'x\n' > sample.probe
$ rfc-run --adapter-dir adapters --sandbox-dir sandboxes --sandbox marker --type probe sample.probe
? 0
$ rfc-run --adapter-dir adapters --type probe sample.probe
? 1
```

### Provider resolution

Runners resolve a provider name in the same order adapters resolve, and
for the same reason: the environment override (`RFC_SANDBOX_PATH`,
colon-separated directories), then the series-local `sandboxes/`
directory (the `--sandbox-dir` argument, or `<series>/sandboxes` in
corpus mode), then the tooling's built-in providers.
[R-provider-resolution]

```transcript @R-provider-resolution
$ mkdir -p override adapters
$ printf '#!/bin/sh\nwhile [ "$#" -gt 0 ] && [ "$1" != "--" ]; do shift; done\nshift\nRFC_SANDBOXED=1 exec "$@"\n' > override/marker
$ chmod +x override/marker
$ printf '#!/bin/sh\n[ "$RFC_SANDBOXED" = 1 ]\n' > adapters/probe
$ chmod +x adapters/probe
$ printf 'x\n' > sample.probe
$ RFC_SANDBOX_PATH=$PWD/override rfc-run --adapter-dir adapters --sandbox marker --type probe sample.probe
? 0
```

### Selection: profile file, then overrides

A series selects its provider with the file `sandbox` beside its RFCs.
The first line that is neither blank nor a `#` comment names the provider
and its flags, whitespace-separated. When the profile is present, corpus
runs over that series MUST wrap every adapter invocation with the named
provider. [R-profile-selection]

Selection precedence, highest first: the `--sandbox NAME` flag, the
`RFC_SANDBOX` environment variable, the series profile. The reserved name
`none` explicitly disables wrapping — the only way a selected provider is
ever skipped — and it is honored ONLY from the flag: an environment
variable or profile naming `none` is a loud error, so one stale export
in a CI environment cannot silently defeat a series' declared hygiene
floor. [R-selection-precedence]

```transcript @R-profile-selection
$ mkdir -p series/sandboxes series/adapters
$ printf '#!/bin/sh\nwhile [ "$#" -gt 0 ] && [ "$1" != "--" ]; do shift; done\nshift\nRFC_SANDBOXED=1 exec "$@"\n' > series/sandboxes/marker
$ chmod +x series/sandboxes/marker
$ printf '#!/bin/sh\n[ "$RFC_SANDBOXED" = 1 ]\n' > series/adapters/probe
$ chmod +x series/adapters/probe
$ printf '# hygiene floor for this series\nmarker\n' > series/sandbox
$ printf '# t\n\n\140\140\140probe @R-x\nx\n\140\140\140\n' > series/t.md
$ rfc-run series/t.md
PASS t.x.probe
rfc-run: 0 failing block(s)
? 0
```

```transcript @R-selection-precedence
$ mkdir -p sandboxes adapters
$ printf '#!/bin/sh\nwhile [ "$#" -gt 0 ] && [ "$1" != "--" ]; do shift; done\nshift\nRFC_SANDBOXED=1 exec "$@"\n' > sandboxes/marker
$ chmod +x sandboxes/marker
$ printf '#!/bin/sh\n[ "$RFC_SANDBOXED" = 1 ]\n' > adapters/probe
$ chmod +x adapters/probe
$ printf 'x\n' > sample.probe
$ RFC_SANDBOX=marker rfc-run --adapter-dir adapters --sandbox-dir sandboxes --type probe sample.probe
? 0
$ RFC_SANDBOX=marker rfc-run --adapter-dir adapters --sandbox-dir sandboxes --sandbox none --type probe sample.probe
? 1
$ RFC_SANDBOX=none rfc-run --adapter-dir adapters --sandbox-dir sandboxes --type probe sample.probe
rfc-run: the reserved name none is honored only from --sandbox
? 1
```

### The gate

A selected provider that cannot be resolved is a hard error naming the
provider — never a silent bare run. This is the spacedock gate and the
adapter-resolution rule, applied to isolation: an operator who asked for a
sandbox and did not get one has a corrupted verdict, not a degraded one.
[R-gate-hard-error]

```transcript @R-gate-hard-error
$ mkdir -p adapters
$ printf '#!/bin/sh\nexit 0\n' > adapters/probe
$ chmod +x adapters/probe
$ printf 'x\n' > sample.probe
$ rfc-run --adapter-dir adapters --sandbox missing --type probe sample.probe
rfc-run: no sandbox provider found for missing
? 1
```

### The built-in `env-scrub` provider

The tooling MUST ship a built-in `env-scrub` provider: a fresh temporary
HOME and XDG_CONFIG_HOME, `GIT_CONFIG_NOSYSTEM=1`, inner command executed
with the caller's working directory and PATH intact, temporary state
removed afterward. It is the hygiene floor generalized from the
transcript adapter's inline sandbox — and like it, hygiene, not a
security boundary. [R-env-scrub]

```transcript @R-env-scrub
$ mkdir -p adapters
$ printf '#!/bin/sh\n[ "$HOME" != "%s" ] && [ "$GIT_CONFIG_NOSYSTEM" = 1 ]\n' "$HOME" > adapters/probe
$ chmod +x adapters/probe
$ printf 'x\n' > sample.probe
$ rfc-run --adapter-dir adapters --sandbox env-scrub --type probe sample.probe
? 0
```

### A sandbox is per-invocation

A sandbox instance MUST be private to the invocation that created it. Where
a document specifies a sandbox path, that path is **logical**: an
implementation MUST NOT make it the physical directory shared by every run.
A shared physical sandbox is not an isolation mechanism but a global mutable
directory, and it forces a cross-run mutex whose holder cannot be
distinguished from a dead one — a killed run then leaves a lock that fails
every later run with a false negative, indefinitely, until a human
intervenes. Contention that can be removed MUST be removed rather than
serialised; serialisation belongs to resources that genuinely cannot be
duplicated, and a temporary directory can. [R-sandbox-per-invocation]

An implementation preserving a logical path over a private physical
directory MUST canonicalise in both directions, so that transcripts remain
byte-exact: the logical path substituted for the physical one on the way in,
and the physical path rewritten back to the logical one in captured output.
It MUST NOT create a lock, and MUST leave nothing behind that a later run
could mistake for contention.

```transcript @R-sandbox-per-invocation
$ pwd
/tmp/gi-rfc
$ printf hello > /tmp/gi-rfc/x
$ cat /tmp/gi-rfc/x
hello
$ test -e /tmp/gi-rfc.lock; echo $?
1
```

### Division of ownership

Providers own isolation; adapters continue to own their vocabulary's
engine mechanics. The transcript adapter's inline sandbox is engine
mechanics (its replay contract depends on it) and remains; a provider
wrapped outside it composes rather than replaces. New adapters SHOULD NOT
implement isolation, relying on this seam instead.

## Alternatives Considered

### Keep isolation inside each adapter

The status quo. Rejected: it fixes the isolation level per adapter,
forces every adapter to reinvent hygiene, and leaves no path to a real
security boundary for foreign corpora short of editing trusted
executables.

### Silent fallback to a bare run when the provider is missing

Friendlier for casual use. Rejected outright: it converts an isolation
request into a no-op exactly when the operator is least likely to notice,
and contradicts the series' standing rule that resolution failure is a
hard error. Spacedock's gate (fail with an install hint) is the model.

### A single hardcoded stronger sandbox (e.g. containers)

Rejected: container availability varies wildly across the environments
this tooling targets (macOS, Linux, BSD, CI runners, Git Bash), and the
right isolation is a deployment decision. The provider contract lets each
deployment choose without the documents or adapters knowing.

## Security Considerations

This seam is where the corpus's trust story becomes configurable.
A provider is trusted code wrapped around trusted code (the adapter) —
series MUST pin non-built-in providers by content exactly as adapters are
pinned, and provider changes are reviewed as evidence changes. The
profile file is config-controlled execution: running a foreign series'
corpus executes the provider its profile names, so the standing guidance
to isolate foreign corpora at the deployment layer applies to the profile
itself — a deployment-layer sandbox around the runner remains the outer
boundary. `--sandbox none` is deliberately loud in precedence (explicit
flag or env only, never a default) so bare runs are always operator
choice.

## References

- draft-ndn-evidence-adapters-00 — the adapter contract this seam wraps;
  its "adapters own environment concerns" is refined here to "adapters
  own engine mechanics; providers own isolation."
- The process BCP: draft-ndn-authoring-rfcs-00 — resolution-failure and
  pinning doctrine applied here to providers.
- spacedock safehouse seam — detect/gate/wrap with per-provider flag
  translators; the direct model for the profile, the gate, and the
  `wrapper [flags] -- inner` shape.
  https://github.com/spacedock-dev/spacedock
  (internal/safehouse/safehouse.go @ ca136f83a579fd44c223321ae7f8fe7785c685f7)
- agent-safehouse — the wrapped sandbox in spacedock's case; a candidate
  provider here. https://agent-safehouse.dev

## Changelog

- 2026-08-14: draft-00 created from the design conversation: configurable
  sandbox providers on spacedock's detect/gate/wrap seam, selected by
  series profile with flag/env override, hard-error gate, built-in
  `env-scrub` hygiene floor. Evidence is red until rfc-run gains the
  provider seam (spec-first; the transcripts above are the acceptance
  criteria).
- 2026-08-14: external-review hardening — `none` is honored only from
  the --sandbox flag; RFC_SANDBOX=none or a profile naming none is a
  loud error rather than a silent defeat of the declared hygiene floor.
- 2026-08-20: per-invocation sandbox isolation added
  ([R-sandbox-per-invocation]) after the bootstrap transcript adapter's
  shared physical sandbox produced exactly the failure the requirement now
  forbids: a killed corpus run orphaned the cross-run lock, and every
  subsequent run reported six unrelated drafts red. Found by Claude while
  running concurrent gates; the remedy is isolation, not a better lock.
