#!/bin/sh
# Negative control: pre-commit must REJECT a protected-core edit with no sync signal.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-nc-core.XXXXXX)
cleanup() {
    git -C "$repo" worktree remove --force "$tmp/wt" > /dev/null 2>&1 || true
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git -C "$repo" worktree add --detach "$tmp/wt" HEAD > /dev/null 2>&1
cd "$tmp/wt"
# edit a line INSIDE the protected range (the Core Contract bullet)
sed -i 's/- AGENTS.md files are binding work contracts for their subtrees/- AGENTS.md files are binding work contracts, mutated/' AGENTS.md
git add AGENTS.md
# run the hook directly; nonzero exit = core edit blocked = PASS
if sh "$repo/.githooks/pre-commit"; then
    echo "NC FAILED: pre-commit accepted a protected-core edit" >&2
    exit 1
fi
echo "NC PASS: protected-core edit rejected"
