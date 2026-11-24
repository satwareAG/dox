#!/bin/sh
# baseline.sh - single source of truth for the upstream baseline tag.
#
# Prints the pinned baseline commit SHA on stdout; exits 1 (fail closed) when
#   - the pinned tag is missing or moved, or
#   - any other v*-upstream tag exists that is not the pinned one.
#
# The newest v*-upstream tag is NEVER used: a rogue local tag must fail
# resolution, not silently become the comparison base.
# SYNC.md protocol step 4 bumps this pin in the same commit as a reviewed
# upstream sync (retag + pin bump travel together).
PINNED_TAG=v0-upstream
PINNED_SHA=765ae4ac02cc884eefcd41a3d0f71941721adb89

fail() {
    echo "baseline.sh: $1" >&2
    exit 1
}

resolved=$(git rev-parse --verify --quiet "${PINNED_TAG}^{commit}") \
    || fail "pinned baseline tag $PINNED_TAG is missing (fail closed; fetch tags or restore the pin)"

[ "$resolved" = "$PINNED_SHA" ] \
    || fail "tag $PINNED_TAG points at $resolved but the pin says $PINNED_SHA (moved or rogue tag; fail closed)"

for t in $(git tag --list 'v*-upstream'); do
    [ "$t" = "$PINNED_TAG" ] && continue
    fail "rogue baseline tag $t: only $PINNED_TAG@$PINNED_SHA is trusted (fail closed; delete the rogue tag or bump the pin via a reviewed sync)"
done

printf '%s\n' "$resolved"
