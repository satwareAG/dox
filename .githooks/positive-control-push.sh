#!/bin/sh
# Positive control: pre-push must PASS on the current state, verifying the
# AGENTS.md path (range from the baseline tag to tip touches AGENTS.md).
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
local_sha=$(git -C "$repo" rev-parse HEAD)
remote_sha=$(git -C "$repo" rev-parse v0-upstream)
cd "$repo"
printf '%s %s %s %s\n' "refs/heads/main" "$local_sha" "refs/heads/main" "$remote_sha" \
    | sh "$repo/.githooks/pre-push"
echo "PC PASS: pre-push verification green"
