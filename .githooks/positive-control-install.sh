#!/bin/sh
# Positive control: the installer is idempotent, honesty is mandatory, and
# site-release / lazy-read are flag-gated.
#   (no flags)            : install twice -> byte-identical (no-op on re-run)
#   --check-flags         : site-release absent by default, present with flag
#   --check-lazy-read     : lazy-read flag-gated AND core bytes untouched
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-pc-install.XXXXXX)
cleanup() {
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

proj="$tmp/proj"
mkdir -p "$proj"

run_default() {
    sh "$repo/install.sh" "$proj/AGENTS.md" > /dev/null
}

run_default
cp "$proj/AGENTS.md" "$tmp/first"
run_default
if ! cmp -s "$tmp/first" "$proj/AGENTS.md"; then
    echo "PC FAILED: installer re-run changed the file (not idempotent)" >&2
    exit 1
fi
echo "PC PASS: installer idempotent"

grep -q 'ADDENDUM-START: honesty' "$proj/AGENTS.md" || {
    echo "PC FAILED: honesty addendum missing after default install" >&2
    exit 1
}
if grep -q 'ADDENDUM-START: site-release' "$proj/AGENTS.md"; then
    echo "PC FAILED: site-release block present without its flag" >&2
    exit 1
fi
sh "$repo/install.sh" --site-release "$proj/AGENTS.md" > /dev/null
grep -q 'ADDENDUM-START: site-release' "$proj/AGENTS.md" || {
    echo "PC FAILED: site-release block missing with flag set" >&2
    exit 1
}
if [ "$1" = "--check-flags" ]; then
    echo "PC PASS: site-release flag-gated"
    exit 0
fi
# flag dropped again -> block removed (declared state)
sh "$repo/install.sh" "$proj/AGENTS.md" > /dev/null
grep -q 'ADDENDUM-START: site-release' "$proj/AGENTS.md" && {
    echo "PC FAILED: site-release block survived flag removal" >&2
    exit 1
}

if [ "$1" = "--check-lazy-read" ]; then
    sh "$repo/install.sh" --lazy-read "$proj/AGENTS.md" > /dev/null
    grep -q 'ADDENDUM-START: lazy-read' "$proj/AGENTS.md" || {
        echo "PC FAILED: lazy-read block missing with flag set" >&2
        exit 1
    }
    # core untouched by any install: compare against the template core
    sed -n '/^<!-- DOX-CORE-START/,/^<!-- DOX-CORE-END/p' "$proj/AGENTS.md" > "$tmp/installed-core"
    sed -n '/^<!-- DOX-CORE-START/,/^<!-- DOX-CORE-END/p' "$repo/AGENTS.md" > "$tmp/template-core"
    cmp -s "$tmp/installed-core" "$tmp/template-core" || {
        echo "PC FAILED: install modified the protected core" >&2
        exit 1
    }
    echo "PC PASS: lazy-read addendum ok"
    exit 0
fi

echo "PC PASS: honesty mandatory, flags clean"
