#!/bin/sh
# Negative control: pre-push must REJECT a tip whose protected core diverges
# from the baseline. Builds a tampered commit in a throwaway worktree (the
# object lives in the shared repo store, so the hook can read it), simulates
# the push of that tip, and expects a nonzero exit.
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
# mutate the protected core WITH a sync signal staged (passes pre-commit),
# so pre-push is the only gate that can catch this tip
sed -i 's/- AGENTS.md files are binding work contracts for their subtrees/- AGENTS.md files are binding work contracts, tampered/' AGENTS.md
printf -- '- core tampered in NC (revert follow-up)\n' >> SYNC.md
git add AGENTS.md SYNC.md
git -c user.name=nc-bot -c user.email=nc-bot@example.invalid commit -m "NC: tampered core tip" > /dev/null 2>&1
tampered_sha=$(git rev-parse HEAD)
git -C "$repo" branch nc-push-tampered "$tampered_sha"

base_sha=$(git -C "$repo" rev-parse v0-upstream)
cd "$repo"
if printf '%s %s %s %s\n' "refs/heads/main" "$tampered_sha" "refs/heads/main" "$base_sha" \
    | sh "$repo/.githooks/pre-push"; then
    echo "NC FAILED: pre-push accepted a tampered core tip" >&2
    exit 1
fi
echo "NC PASS: tampered core tip rejected"
