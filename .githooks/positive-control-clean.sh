#!/bin/sh
# Positive control: pre-commit must ACCEPT a clean staged change.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-pc-clean.XXXXXX)
cleanup() {
    git -C "$repo" worktree remove --force "$tmp/wt" > /dev/null 2>&1 || true
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git -C "$repo" worktree add --detach "$tmp/wt" HEAD > /dev/null 2>&1
cd "$tmp/wt"
printf -- '- hook control probe\n' > pc-probe-note.txt
git add pc-probe-note.txt
# run the hook directly; zero exit = clean change accepted = PASS
sh "$repo/.githooks/pre-commit"
echo "PC PASS: clean staged change accepted"
