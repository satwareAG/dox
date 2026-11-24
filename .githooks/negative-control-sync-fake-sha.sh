#!/bin/sh
# Negative control: a trailer SHA that is NOT reachable from upstream/main
# must be rejected, even when the pin is bumped to it and the core matches
# the claim. Sandbox: local simulated upstream carrying only the real
# baseline commit; the trailer names a 40-hex SHA that exists nowhere.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
base_sha=765ae4ac02cc884eefcd41a3d0f71941721adb89
fake_sha=1234567890abcdef1234567890abcdef12345678
tmp=$(mktemp -d /tmp/dox-nc-fake.XXXXXX)
cleanup() {
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git clone --quiet --no-local "$repo" "$tmp/work"
cd "$tmp/work"
git config user.name nc-fake-bot
git config user.email nc-fake-bot@example.invalid

git init --bare --quiet "$tmp/upstream.git"
git push --quiet "$tmp/upstream.git" "$base_sha:refs/heads/main"
git remote add upstream "$tmp/upstream.git"
git fetch --quiet upstream main

# core EDITED (differs from the current core, so the sync path triggers), pin
# bumped to the fake SHA, trailer names the fake SHA - only reachability can
# catch it
{
    printf '%s\n' '<!-- DOX-CORE-START (protected: do not edit inside this range) -->'
    git show "$base_sha:AGENTS.md"
    printf '\n## Fake sync tail (simulated)\n'
    sed -n '/^<!-- DOX-CORE-END/,$p' AGENTS.md
} > AGENTS.md.new
mv AGENTS.md.new AGENTS.md
sed -i "s/^PINNED_SHA=.*/PINNED_SHA=$fake_sha/" .githooks/baseline.sh
printf -- '\nUpstream-Commit: %s\n' "$fake_sha" >> SYNC.md
git add AGENTS.md SYNC.md .githooks/baseline.sh

if out=$(sh "$repo/.githooks/pre-commit" 2>&1); then
    echo "NC FAILED: pre-commit accepted an unreachable trailer SHA" >&2
    exit 1
fi
printf '%s\n' "$out" | grep -q 'does not resolve' || {
    echo "NC FAILED: rejection reason was not the reachability check; got:" >&2
    printf '%s\n' "$out" | tail -2 >&2
    exit 1
}
echo "NC PASS: fake (unreachable) trailer SHA rejected"
