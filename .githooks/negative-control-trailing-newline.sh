#!/bin/sh
# Negative control: a trailing-newline-only edit inside the protected core
# must NOT reach origin.
#   a) without a sync signal, pre-commit rejects it (byte-exact cmp catches
#      what $(...) stripping would hide)
#   b) even with a sync signal staged (SYNC.md carrying a valid
#      Upstream-Commit trailer), a tip whose core diverges from the pinned
#      baseline is rejected by pre-push when the commit message lacks the
#      trailer
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-nc-tnl.XXXXXX)
cleanup() {
    git -C "$repo" worktree remove --force "$tmp/wt" > /dev/null 2>&1 || true
    git -C "$repo" branch -D nc-tnl-tip > /dev/null 2>&1 || true
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git -C "$repo" worktree add --detach "$tmp/wt" HEAD > /dev/null 2>&1
cd "$tmp/wt"
# insert a blank line before the END marker: trailing-newline-only core edit
awk '/^<!-- DOX-CORE-END/ && !done { print ""; print; done = 1; next } { print }' AGENTS.md > AGENTS.md.tnl
mv AGENTS.md.tnl AGENTS.md
git add AGENTS.md

# a) no sync signal staged -> pre-commit must reject
if sh "$repo/.githooks/pre-commit" > /dev/null 2>&1; then
    echo "NC FAILED: pre-commit accepted a trailing-newline core edit without a sync signal" >&2
    exit 1
fi
echo "NC sub-a PASS: trailing-newline core edit rejected without sync signal"

# b) valid trailer in the staged SYNC.md, but the commit message carries no
#    trailer -> pre-commit accepts, pre-push must reject the tip
printf -- '\nUpstream-Commit: 765ae4ac02cc884eefcd41a3d0f71941721adb89\n' >> SYNC.md
git add SYNC.md
if ! sh "$repo/.githooks/pre-commit" > /dev/null 2>&1; then
    echo "NC FAILED: pre-commit rejected a properly signalled sync-path edit (positive path broken)" >&2
    exit 1
fi
echo "NC sub-b1 PASS: trailer-carrying SYNC.md unlocks the sync path"
git -c user.name=nc-bot -c user.email=nc-bot@example.invalid \
    commit -m "NC: trailing-newline core tip (message lacks trailer)" > /dev/null 2>&1
tip=$(git rev-parse HEAD)
base=$(git -C "$repo" rev-parse v0-upstream)
if printf '%s %s %s %s\n' "refs/heads/main" "$tip" "refs/heads/main" "$base" \
    | sh "$repo/.githooks/pre-push" > /dev/null 2>&1; then
    echo "NC FAILED: pre-push accepted a trailing-newline core tip" >&2
    exit 1
fi
echo "NC sub-b2 PASS: trailing-newline core tip rejected by pre-push"

echo "NC PASS: trailing-newline core edit rejected"
