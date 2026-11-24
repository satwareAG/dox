#!/bin/sh
# Positive control: a CORRECT upstream sync passes the whole chain.
# Sandbox: a throwaway clone with a SIMULATED upstream (local bare repo) that
# carries a crafted child commit of the real upstream baseline. The sync
# adopts exactly that commit: core replaced by its AGENTS.md, trailer naming
# it, pin bumped to it, baseline tag retagged - pre-commit accepts the staged
# state and pre-push accepts the committed tip.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
base_sha=765ae4ac02cc884eefcd41a3d0f71941721adb89
tmp=$(mktemp -d /tmp/dox-pc-sync.XXXXXX)
cleanup() {
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git clone --quiet --no-local "$repo" "$tmp/work"
cd "$tmp/work"
git config user.name pc-sync-bot
git config user.email pc-sync-bot@example.invalid
fork_base=$(git rev-parse HEAD)

# simulated upstream: baseline commit + one crafted child commit
git init --bare --quiet "$tmp/upstream.git"
git push --quiet "$tmp/upstream.git" "$base_sha:refs/heads/main"
git checkout --quiet -b upwork "$base_sha"
printf '\n## Upstream addition (simulated)\n\n- new upstream bullet\n' >> AGENTS.md
git commit --quiet -am "Simulated upstream change"
up_sha=$(git rev-parse HEAD)
git push --quiet "$tmp/upstream.git" upwork:refs/heads/main
git remote add upstream "$tmp/upstream.git"
git fetch --quiet upstream main

# fork side: adopt exactly up_sha's core, bump the pin, name it in SYNC.md
git checkout --quiet -B work "$fork_base"
{
    printf '%s\n' '<!-- DOX-CORE-START (protected: do not edit inside this range) -->'
    git show "$up_sha:AGENTS.md"
    sed -n '/^<!-- DOX-CORE-END/,$p' AGENTS.md
} > AGENTS.md.new
mv AGENTS.md.new AGENTS.md
sed -i "s/^PINNED_SHA=.*/PINNED_SHA=$up_sha/" .githooks/baseline.sh
printf -- '\nUpstream-Commit: %s\n' "$up_sha" >> SYNC.md
git add AGENTS.md SYNC.md .githooks/baseline.sh

sh "$repo/.githooks/pre-commit"
echo "PC sub-a PASS: correct sync accepted by pre-commit"

# full chain: commit (message carries the trailer), retag, pre-push green
git commit --quiet -m "Sync upstream $up_sha

Upstream-Commit: $up_sha"
git tag -f v0-upstream "$up_sha" > /dev/null
tip=$(git rev-parse HEAD)
if printf '%s %s %s %s\n' "refs/heads/main" "$tip" "refs/heads/main" "$base_sha" \
    | sh "$repo/.githooks/pre-push"; then
    echo "PC sub-b PASS: correct sync accepted by pre-push"
else
    echo "PC FAILED: pre-push rejected a fully correct sync" >&2
    exit 1
fi
echo "PC PASS: sync signal with Upstream-Commit trailer accepted"
