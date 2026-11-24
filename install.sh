#!/bin/sh
# install.sh - install the DOX template + addenda into a project (idempotent).
#
# Usage: sh install.sh [--site-release] [--lazy-read] [TARGET]
#   TARGET: a project directory or an AGENTS.md file (default: ./AGENTS.md)
#
# - the honesty addendum is mandatory: always applied
# - site-release and lazy-read are opt-in flags; a re-run without the flag
#   removes that block again (declared state, deterministic)
# - a re-run that changes nothing produces a byte-identical file (no-op)
# - the protected core between DOX-CORE-START / DOX-CORE-END is never modified
set -e
script_dir=$(cd "$(dirname "$0")" && pwd)

want_site=0
want_lazy=0
target=""
for arg in "$@"; do
    case "$arg" in
        --site-release) want_site=1 ;;
        --lazy-read) want_lazy=1 ;;
        -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
        *) target="$arg" ;;
    esac
done
[ -n "$target" ] || target="./AGENTS.md"
[ -d "$target" ] && target="$target/AGENTS.md"

template="$script_dir/AGENTS.md"
honesty="$script_dir/addenda/honesty.md"
site="$script_dir/addenda/site-release.md"
lazy="$script_dir/addenda/lazy-read.md"
[ -f "$template" ] || { echo "install.sh: template AGENTS.md not found next to installer" >&2; exit 1; }
[ -f "$honesty" ] || { echo "install.sh: addenda/honesty.md not found next to installer" >&2; exit 1; }

# new target: start from the canonical template
if [ ! -f "$target" ]; then
    mkdir -p "$(dirname "$target")"
    cp "$template" "$target"
    echo "install.sh: installed template to $target"
fi

# the target must be a DOX file (marker pair intact) - refuse otherwise
starts=$(grep -c 'DOX-CORE-START' "$target" || true)
ends=$(grep -c 'DOX-CORE-END' "$target" || true)
if [ "$starts" != "1" ] || [ "$ends" != "1" ]; then
    echo "install.sh: REJECTED - $target has no intact DOX-CORE marker pair (START=$starts END=$ends)" >&2
    echo "  install the template first or fix the markers; appending addenda to a non-DOX file is unsupported" >&2
    exit 1
fi

# splice addenda: replace each ADDENDUM block with its source (or drop it),
# insert wanted blocks that are not present yet right after DOX-CORE-END.
# Runs in one awk pass over a buffered copy, then replaces the target
# atomically. Core range is untouched: the state machine only ever drops
# ADDENDUM blocks (which live after the core marker).
awk -v want_site="$want_site" -v want_lazy="$want_lazy" \
    -v honesty="$honesty" -v site="$site" -v lazy="$lazy" '
    function emit(src,   line) {
        while ((getline line < src) > 0) print line
        close(src)
    }
    BEGIN { n = 0 }
    { lines[++n] = $0 }
    END {
        # pass 1: which addendum blocks already exist in the target?
        delete exists
        for (i = 1; i <= n; i++) {
            if (match(lines[i], /^<!-- ADDENDUM-START: [a-z-]+/)) {
                name = substr(lines[i], 22, RLENGTH - 21)
                exists[name] = 1
            }
        }
        # pass 2: replace existing blocks (when wanted), insert missing ones
        # right after the core end marker
        open = ""
        for (i = 1; i <= n; i++) {
            line = lines[i]
            if (line ~ /^<!-- TEMPLATE-NOTICE-START -->/) { tn = 1; print "<!-- installed from the satwareAG/dox DOX template (see the repository for the sync protocol) -->"; continue }
            if (tn == 1 && line ~ /^<!-- TEMPLATE-NOTICE-END -->/) { tn = 0; continue }
            if (tn == 1) continue
            if (match(line, /^<!-- ADDENDUM-START: [a-z-]+/)) {
                name = substr(line, 22, RLENGTH - 21)
                open = name
                if (name == "honesty") emit(honesty)
                else if (name == "site-release" && want_site == 1) emit(site)
                else if (name == "lazy-read" && want_lazy == 1) emit(lazy)
                continue
            }
            if (open != "" && line ~ /^<!-- ADDENDUM-END -->/) { open = ""; continue }
            if (open != "") continue
            print line
            if (line ~ /^<!-- DOX-CORE-END -->/) {
                if (!exists["honesty"]) emit(honesty)
                if (want_site == 1 && !exists["site-release"]) emit(site)
                if (want_lazy == 1 && !exists["lazy-read"]) emit(lazy)
            }
        }
    }' "$target" > "$target.tmp"
mv "$target.tmp" "$target"
echo "install.sh: addenda applied to $target (honesty=always site-release=$want_site lazy-read=$want_lazy)"
