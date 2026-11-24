#!/bin/sh
# Negative control: pre-commit must REJECT a staged fake secret.
# The ghp_ fixture is built from split literals - the repo blob never contains
# a scannable contiguous token (GitHub push protection does not honor
# betterleaks:allow comments); the WRITTEN fixture file does, so the control fires.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-nc-secret.XXXXXX)
cleanup() {
    git -C "$repo" worktree remove --force "$tmp/wt" > /dev/null 2>&1 || true
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git -C "$repo" worktree add --detach "$tmp/wt" HEAD > /dev/null 2>&1
cd "$tmp/wt"
{
    printf 'aws = "AKIAIOSFODNN7EXAMPLE"\n'   # betterleaks:allow (test fixture)
    printf 'gh = "ghp_'"FLAdAxCmjvwPQrsTtUvWxYz1234567890"'"\n'
    printf 'slack = "xoxb-'"123456789012-1234567890123-abcdefghijklmnopqrstuv"'"\n'   # betterleaks:allow (test fixture; literal split for GitHub push protection)
} > nc-secret.txt
git add nc-secret.txt
# run the hook directly; nonzero exit = secret blocked = PASS
if sh "$repo/.githooks/pre-commit"; then
    echo "NC FAILED: pre-commit accepted a staged fake secret" >&2
    exit 1
fi
echo "NC PASS: staged fake secret rejected"
