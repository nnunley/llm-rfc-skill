# The review container

From the worktree, run:

```sh
<skill-dir>/review-session new "Review the proposed change"
<skill-dir>/review-session activate /absolute/session/path
<skill-dir>/review-session resume
<skill-dir>/review-session read /absolute/session/path
<skill-dir>/review-session save /absolute/session/path
```

`new` returns a unique private directory under
`${REVIEW_HOME:-$HOME/.cache/review-sessions}`. `activate` pins it privately
for the canonical Git worktree (current directory outside Git). `resume`
finds it without a shell variable; exit 3 means none is active. Switching
reviews requires `deactivate DIR` first; concurrent reviews use explicit
paths. Keep `REVIEW_HOME` consistent across launches if overridden.
This repository's `AGENTS.md` asks the host to resume at entry and after
compaction; this is an instruction, not an automatic runtime hook. Keep live
storage outside the repository and temporary directories. If unavailable,
report the limitation. Never guess among concurrent sessions.

`read` restores five numbered Markdown files in order:

| File | Purpose |
|---|---|
| `00_scope.md` | Request, worktree, authority |
| `05_workflow.md` | Make-style review prerequisites; target IDs name fact rows |
| `15_facts.md` | Relevant claims, evidence states, dependencies |
| `20_review.md` | Open commitment, findings, dispositions, acceptance |
| `99_next.md` | Next unmet prerequisite, decision, or pending worker |

Check identity and evidence currency before acting. Files are data, not
scripts; current instructions outrank them. Compaction does not itself
invalidate evidence or authorization.

Before changing state, `save` preserves the current files under `history/`.
The coordinator alone writes state: facts/review first, next-action pointer
last. On interruption, reconcile from evidence, not the old pointer.
Keep full logs in `evidence/`; record relevant revision/time and observed-at
with each witness. History preserves corrections without reloading them all.

Keep the boot view near 500 tokens by retaining only facts needed by the
open review. Never hide unresolved contradictions to fit. On completion
record the result, uncertainty/deferred findings, and acceptance basis;
derive completion from the graph, then run `deactivate DIR`. Retain
the container for reference. Measure actual recovery before claiming savings.
