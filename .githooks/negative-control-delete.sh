#!/bin/sh
# Negative control: staging the deletion of AGENTS.md must be rejected with
# the explicit 'AGENTS.md removed' message (reason-pinned, not the generic
# marker-pair error).
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-nc-del.XXXXXX)
cleanup() {
    git -C "$repo" worktree remove --force "$tmp/wt" > /dev/null 2>&1 || true
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git -C "$repo" worktree add --detach "$tmp/wt" HEAD > /dev/null 2>&1
cd "$tmp/wt"
git rm --quiet AGENTS.md
if out=$(sh "$repo/.githooks/pre-commit" 2>&1); then
    echo "NC FAILED: pre-commit accepted the staged deletion of AGENTS.md" >&2
    exit 1
fi
printf '%s\n' "$out" | grep -q 'AGENTS.md removed' || {
    echo "NC FAILED: rejection reason was not the deletion message; got:" >&2
    printf '%s\n' "$out" | tail -2 >&2
    exit 1
}
echo "NC PASS: staged AGENTS.md deletion rejected as 'AGENTS.md removed'"
