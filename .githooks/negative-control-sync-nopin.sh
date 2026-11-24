#!/bin/sh
# Negative control: a REAL upstream commit named in the trailer but WITHOUT
# the pin bump in the same change must be rejected. Sandbox: local simulated
# upstream with a crafted child commit; core correctly equals that commit's
# AGENTS.md; baseline.sh pin still points at the old baseline.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
base_sha=765ae4ac02cc884eefcd41a3d0f71941721adb89
tmp=$(mktemp -d /tmp/dox-nc-nopin.XXXXXX)
cleanup() {
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git clone --quiet --no-local "$repo" "$tmp/work"
cd "$tmp/work"
git config user.name nc-nopin-bot
git config user.email nc-nopin-bot@example.invalid
fork_base=$(git rev-parse HEAD)

git init --bare --quiet "$tmp/upstream.git"
git push --quiet "$tmp/upstream.git" "$base_sha:refs/heads/main"
git checkout --quiet -b upwork "$base_sha"
printf '\n## Upstream addition (simulated)\n\n- new upstream bullet\n' >> AGENTS.md
git commit --quiet -am "Simulated upstream change"
up_sha=$(git rev-parse HEAD)
git push --quiet "$tmp/upstream.git" upwork:refs/heads/main
git remote add upstream "$tmp/upstream.git"
git fetch --quiet upstream main

# core correctly equals up_sha's AGENTS.md, trailer names it, pin NOT bumped
git checkout --quiet -B work "$fork_base"
{
    printf '%s\n' '<!-- DOX-CORE-START (protected: do not edit inside this range) -->'
    git show "$up_sha:AGENTS.md"
    sed -n '/^<!-- DOX-CORE-END/,$p' AGENTS.md
} > AGENTS.md.new
mv AGENTS.md.new AGENTS.md
printf -- '\nUpstream-Commit: %s\n' "$up_sha" >> SYNC.md
git add AGENTS.md SYNC.md

if sh "$repo/.githooks/pre-commit" > /dev/null 2>&1; then
    echo "NC FAILED: pre-commit accepted a sync without the pin bump" >&2
    exit 1
fi
echo "NC PASS: real upstream SHA without pin bump rejected"
