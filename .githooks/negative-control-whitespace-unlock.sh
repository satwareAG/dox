#!/bin/sh
# Negative control: a whitespace-only SYNC.md edit is NOT a sync signal.
# A protected-core edit staged together with a whitespace-only SYNC.md change
# (no Upstream-Commit trailer) must be rejected by pre-commit.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-nc-ws.XXXXXX)
cleanup() {
    git -C "$repo" worktree remove --force "$tmp/wt" > /dev/null 2>&1 || true
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git -C "$repo" worktree add --detach "$tmp/wt" HEAD > /dev/null 2>&1
cd "$tmp/wt"
# whitespace-only SYNC.md change (trailing blank line added)
printf '\n' >> SYNC.md
# core content edit inside the protected range
sed -i 's/- DOX is highly performant AGENTS.md hierarchy installed here/- DOX is highly performant AGENTS.md hierarchy installed HERE/' AGENTS.md
git add SYNC.md AGENTS.md

if sh "$repo/.githooks/pre-commit" > /dev/null 2>&1; then
    echo "NC FAILED: a whitespace-only SYNC.md edit unlocked a protected-core edit" >&2
    exit 1
fi
echo "NC PASS: whitespace-only sync signal rejected"
