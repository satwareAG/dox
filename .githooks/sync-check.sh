#!/bin/sh
# sync-check.sh - shared verifier for the reviewed upstream sync path.
#
# A staged (mode=staged) or committed (mode=tip) sync is VALID only when ALL of:
#   1. the upstream remote exists and `git fetch upstream main` succeeds
#   2. the trailer SHA resolves and is reachable from upstream/main
#   3. the proposed core equals <sha>:AGENTS.md (byte-exact)
#   4. .githooks/baseline.sh PINNED_SHA is bumped to the trailer SHA in the
#      same change (proposed = index for staged, tip tree for tip)
# Any miss fails closed with a distinct error.
#
# Usage: sh sync-check.sh staged <sha>
#        sh sync-check.sh tip <sha> <tree-ish>
# Prints the reason on stderr and exits 1 on any failure; exit 0 = valid.

mode=$1
sha=$2

fail() {
    echo "sync-check: $1" >&2
    exit 1
}

[ -n "$sha" ] || fail "no trailer SHA given"
printf '%s' "$sha" | grep -qE '^[0-9a-f]{40}$' || fail "trailer '$sha' is not a 40-hex commit SHA"

# 1. upstream remote + fetch (fail closed on missing remote or fetch error)
if ! git remote get-url upstream > /dev/null 2>&1; then
    fail "no 'upstream' remote configured (SYNC.md step 1: git remote add upstream <upstream-url>)"
fi
if ! git fetch upstream main > /dev/null 2>&1; then
    fail "git fetch upstream main failed (unreachable upstream - fail closed)"
fi

# 2. the SHA must resolve and be reachable from upstream/main
git cat-file -e "${sha}^{commit}" 2> /dev/null || fail "trailer SHA $sha does not resolve to a commit in this clone"
git merge-base --is-ancestor "$sha" FETCH_HEAD 2> /dev/null \
    || fail "trailer SHA $sha is NOT reachable from upstream/main"

# 3. the proposed core must equal <sha>:AGENTS.md byte-exactly
if [ "$mode" = "staged" ]; then
    agents_src=":AGENTS.md"
    baseline_src=":.githooks/baseline.sh"
else
    tip=$3
    [ -n "$tip" ] || fail "tip mode requires a tree-ish"
    agents_src="$tip:AGENTS.md"
    baseline_src="$tip:.githooks/baseline.sh"
fi
tmp=$(mktemp -d "${TMPDIR:-/tmp}/dox-synccheck.XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT TERM
git show "$agents_src" > "$tmp/agents" 2> /dev/null || fail "cannot read proposed AGENTS.md ($agents_src)"
sed -n '/^<!-- DOX-CORE-START/,/^<!-- DOX-CORE-END/p' "$tmp/agents" | sed '1d;$d' > "$tmp/core"
git show "$sha:AGENTS.md" > "$tmp/expected" 2> /dev/null || fail "cannot read $sha:AGENTS.md"
cmp -s "$tmp/core" "$tmp/expected" || fail "proposed core does NOT equal $sha:AGENTS.md byte-exactly (a sync adopts exactly that commit's core)"

# 4. the pin must be bumped to the trailer SHA in the same change
proposed_pin=$(git show "$baseline_src" 2> /dev/null | grep '^PINNED_SHA=' | head -1 | cut -d= -f2)
[ "$proposed_pin" = "$sha" ] || fail "baseline.sh PINNED_SHA is '${proposed_pin:-unset}', must be bumped to $sha in the same change"

exit 0
