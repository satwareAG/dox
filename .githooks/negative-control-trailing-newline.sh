#!/bin/sh
# Negative control: a trailing-newline-only edit inside the protected core
# must NOT reach origin.
#   a) without a sync signal, pre-commit rejects it (byte-exact cmp catches
#      what $(...) stripping would hide)
#   b) even with a format-valid sync signal (trailer naming the real upstream
#      commit, pin matching), the byte-exact core-equality check rejects it:
#      a trailing newline is not part of the upstream file
#   c) a --no-verify commit of that tip (message without trailer) is rejected
#      by pre-push
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

# b) format-valid sync signal (trailer + pin matching the named commit) but
#    the core carries the extra newline -> the equality check must reject
printf -- '\nUpstream-Commit: 765ae4ac02cc884eefcd41a3d0f71941721adb89\n' >> SYNC.md
git add SYNC.md
if sh "$repo/.githooks/pre-commit" > /dev/null 2>&1; then
    echo "NC FAILED: pre-commit accepted a trailing-newline core despite a format-valid sync signal" >&2
    exit 1
fi
echo "NC sub-b PASS: trailing-newline core rejected despite format-valid sync signal"

# c) --no-verify commit (message without trailer) -> pre-push must reject the tip
git -c user.name=nc-bot -c user.email=nc-bot@example.invalid \
    commit --no-verify -m "NC: trailing-newline core tip (message lacks trailer)" > /dev/null 2>&1
tip=$(git rev-parse HEAD)
base=$(git -C "$repo" rev-parse v0-upstream)
if printf '%s %s %s %s\n' "refs/heads/main" "$tip" "refs/heads/main" "$base" \
    | sh "$repo/.githooks/pre-push" > /dev/null 2>&1; then
    echo "NC FAILED: pre-push accepted a trailing-newline core tip" >&2
    exit 1
fi
echo "NC sub-c PASS: trailing-newline core tip rejected by pre-push"

echo "NC PASS: trailing-newline core edit rejected"
