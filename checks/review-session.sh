#!/usr/bin/env bash
set -eu
project=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export REVIEW_HOME="$scratch/private sessions"
session=$(bash "$project/skill/review-session" new 'Review a design')
second=$(bash "$project/skill/review-session" new 'Review another design')
test "$session" != "$second"
if bash "$project/skill/review-session" resume > "$scratch/resume" 2>&1; then exit 1; else test "$?" = 3; fi
bash "$project/skill/review-session" activate "$session"
bash "$project/skill/review-session" activate "$session"
env -u REVIEW_SESSION_DIR bash "$project/skill/review-session" resume > "$scratch/resume"
grep -q 'Review a design' "$scratch/resume"
(cd "$project/skill" && bash "$project/skill/review-session" resume) > "$scratch/subdir"
grep -q 'Review a design' "$scratch/subdir"
mv "$session" "$session.moved"
if bash "$project/skill/review-session" resume > /dev/null 2>&1; then exit 1; else test "$?" = 1; fi
mv "$session.moved" "$session"
if bash "$project/skill/review-session" activate "$second" 2>/dev/null; then exit 1; fi
test ! -e "$session/$(basename "$second")"
if bash "$project/skill/review-session" deactivate "$second" 2>/dev/null; then exit 1; fi
mkdir "$scratch/other-worktree"
if (cd "$scratch/other-worktree" && bash "$project/skill/review-session" activate "$session") 2>/dev/null; then exit 1; fi
if (cd "$scratch/other-worktree" && bash "$project/skill/review-session" resume) > /dev/null 2>&1; then exit 1; else test "$?" = 3; fi
bash "$project/skill/review-session" deactivate "$session"
if bash "$project/skill/review-session" resume > /dev/null 2>&1; then exit 1; else test "$?" = 3; fi
test -d "$session/state"
case "$(uname -s)" in
    Darwin) mode=$(stat -f %Lp "$session") ;;
    *) mode=$(stat -c %a "$session") ;;
esac
test "$mode" = 700
bash "$project/skill/review-session" read "$session" > "$scratch/boot"
grep -q 'Review a design' "$scratch/boot"
grep -q UNKNOWN "$scratch/boot"
test "$(find "$session/state" -type f | wc -l | tr -d ' ')" = 5
grep -q '^review-complete: scope-known findings-assessed findings-resolved checks-current outcome-accepted$' "$session/state/05_workflow.md"
printf 'F1 | old claim | ESTABLISHED | probe-1 | none\n' >> "$session/state/15_facts.md"
snapshot=$(bash "$project/skill/review-session" save "$session")
printf 'F1 | withdrawn claim | RETRACTED | probe-2 | none\n' > "$session/state/15_facts.md"
grep -q 'old claim' "$snapshot/15_facts.md"
cmp "$session/state/05_workflow.md" "$snapshot/05_workflow.md"
if grep -q 'withdrawn claim' "$snapshot/15_facts.md"; then exit 1; fi
bash "$project/skill/review-session" read "$session" > "$scratch/boot"
grep -q RETRACTED "$scratch/boot"
printf '%s(touch %s)\n' '$' "$scratch/executed" >> "$session/state/15_facts.md"
bash "$project/skill/review-session" read "$session" > /dev/null
test ! -e "$scratch/executed"
mv "$session/state/99_next.md" "$scratch/next"
if bash "$project/skill/review-session" read "$session" 2>/dev/null; then exit 1; fi
if bash "$project/skill/review-session" save "$session" 2>/dev/null; then exit 1; fi
mv "$scratch/next" "$session/state/99_next.md"
mv "$session/state/15_facts.md" "$scratch/facts"
ln -s "$scratch/facts" "$session/state/15_facts.md"
if bash "$project/skill/review-session" read "$session" 2>/dev/null; then exit 1; fi
if bash "$project/skill/review-session" unknown 2>/dev/null; then exit 1; fi
echo 'review-session: PASS'
