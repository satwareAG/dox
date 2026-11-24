#!/bin/sh
# Positive control: a protected-core edit together with a SYNC.md carrying a
# valid 'Upstream-Commit: <40-hex>' trailer is the reviewed sync path and
# must be accepted by pre-commit.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-pc-sync.XXXXXX)
cleanup() {
    git -C "$repo" worktree remove --force "$tmp/wt" > /dev/null 2>&1 || true
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git -C "$repo" worktree add --detach "$tmp/wt" HEAD > /dev/null 2>&1
cd "$tmp/wt"
sed -i 's/- DOX is highly performant AGENTS.md hierarchy installed here/- DOX is a performant AGENTS.md hierarchy installed here (reviewed sync)/' AGENTS.md
printf -- '\nUpstream-Commit: 765ae4ac02cc884eefcd41a3d0f71941721adb89\n' >> SYNC.md
git add AGENTS.md SYNC.md
sh "$repo/.githooks/pre-commit"
echo "PC PASS: sync signal with Upstream-Commit trailer accepted"
