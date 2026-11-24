#!/bin/sh
# Negative control: a rogue v*-upstream tag must fail baseline resolution AND
# pre-push (fail closed), even though the pushed AGENTS.md itself is clean.
# Runs in a throwaway full clone so the source repo is untouched.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-nc-rogue.XXXXXX)
cleanup() {
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git clone --quiet --no-local "$repo" "$tmp/clone"
cd "$tmp/clone"
rogue_target=$(git rev-parse HEAD)
git tag v9-upstream "$rogue_target"

# 1. baseline.sh must reject the rogue tag
if sh "$repo/.githooks/baseline.sh" > /dev/null 2>&1; then
    echo "NC FAILED: baseline.sh accepted a rogue v*-upstream tag" >&2
    exit 1
fi

# 2. pre-push must fail closed on the same clone (clean core, rogue tag present)
tip=$(git rev-parse HEAD)
base=$(git rev-parse v0-upstream)
if printf '%s %s %s %s\n' "refs/heads/main" "$tip" "refs/heads/main" "$base" \
    | sh "$repo/.githooks/pre-push" > /dev/null 2>&1; then
    echo "NC FAILED: pre-push accepted a push while a rogue v*-upstream tag exists" >&2
    exit 1
fi
echo "NC PASS: rogue baseline tag rejected"
