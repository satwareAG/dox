#!/bin/sh
# Negative control: a tampered tip must not reach origin even when the
# committer forges a full-looking sync signal. The tip is created with
# --no-verify (bypass simulation): core tampered, SYNC.md and the commit
# message carry a REAL upstream SHA, but the core does not equal that
# commit's AGENTS.md - pre-push's sync verification must reject it.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-nc-push.XXXXXX)
cleanup() {
    git -C "$repo" worktree remove --force "$tmp/wt" > /dev/null 2>&1 || true
    git -C "$repo" branch -D nc-push-tampered > /dev/null 2>&1 || true
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git -C "$repo" worktree add --detach "$tmp/wt" HEAD > /dev/null 2>&1
cd "$tmp/wt"
sed -i 's/- AGENTS.md files are binding work contracts for their subtrees/- AGENTS.md files are binding work contracts, tampered/' AGENTS.md
printf -- '\nUpstream-Commit: 765ae4ac02cc884eefcd41a3d0f71941721adb89\n' >> SYNC.md
git add AGENTS.md SYNC.md
git -c user.name=nc-bot -c user.email=nc-bot@example.invalid \
    commit --no-verify -m "NC: tampered core tip

Upstream-Commit: 765ae4ac02cc884eefcd41a3d0f71941721adb89" > /dev/null 2>&1
tampered_sha=$(git rev-parse HEAD)
git -C "$repo" branch nc-push-tampered "$tampered_sha"

base_sha=$(git -C "$repo" rev-parse v0-upstream)
cd "$repo"
if printf '%s %s %s %s\n' "refs/heads/main" "$tampered_sha" "refs/heads/main" "$base_sha" \
    | sh "$repo/.githooks/pre-push"; then
    echo "NC FAILED: pre-push accepted a tampered core tip with a forged sync signal" >&2
    exit 1
fi
echo "NC PASS: tampered core tip rejected"
