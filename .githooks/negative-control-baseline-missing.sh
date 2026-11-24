#!/bin/sh
# Negative control: baseline.sh must FAIL CLOSED when the pinned baseline tag
# is missing. Runs in a throwaway full clone so the source repo is untouched.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-nc-baseline-missing.XXXXXX)
cleanup() {
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git clone --quiet --no-local "$repo" "$tmp/clone"
cd "$tmp/clone"
git tag -d v0-upstream > /dev/null

if sh "$repo/.githooks/baseline.sh" > /dev/null 2>&1; then
    echo "NC FAILED: baseline.sh accepted a missing pinned baseline tag" >&2
    exit 1
fi
echo "NC PASS: missing pinned baseline tag rejected"
