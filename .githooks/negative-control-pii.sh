#!/bin/sh
# Negative control: a staged file containing machine-local paths and private
# LAN addresses must be rejected by pre-commit (PII layer). Also proves the
# CI-added-line PII pattern fires on the same content.
# Fixture literals are written split (\057 is '/', quoted-adjacent octets) so
# the SOURCE of this control carries no PII-shaped text itself; they assemble
# only at runtime.
set -e
repo=$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/dox-nc-pii.XXXXXX)
cleanup() {
    git -C "$repo" worktree remove --force "$tmp/wt" > /dev/null 2>&1 || true
    rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

git -C "$repo" worktree add --detach "$tmp/wt" HEAD > /dev/null 2>&1
cd "$tmp/wt"
{
    printf 'log = \057home/demo-user/work/secret.txt\n'
    printf 'mirror = \057Users/demo-user/Projects/site\n'
    printf 'printer = 192.168.''1.44\n'
    printf 'nas = 10.0.''0.7\n'
    printf 'san = 172.16.''4.9\n'
} > pii-fixture.txt
git add pii-fixture.txt

if sh "$repo/.githooks/pre-commit" > /dev/null 2>&1; then
    echo "NC FAILED: pre-commit accepted staged machine-local paths / LAN addresses" >&2
    exit 1
fi
echo "NC sub-a PASS: pre-commit rejected PII fixture"

# the CI-added-line pattern must fire on the same content (split literals again)
home_lit='\057home/demo-user/work/secret.txt'
ip_lit='10.0.''0.7'
pii_ere='^\+.*(/ho''me/|/Use''rs/|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3})'
diff_text=$(printf -- '-log = x\n+log = %b\n+nas = %b\n' "$home_lit" "$ip_lit")
added_lines=$(printf '%s\n' "$diff_text" | grep -E "$pii_ere" | wc -l)
[ "$added_lines" -ge 2 ] || {
    echo "NC FAILED: CI-added-line PII pattern did not fire ($added_lines lines)" >&2
    exit 1
}
echo "NC sub-b PASS: CI-added-line PII pattern fired"

# positive half: clean lines and a doc mention of the slack prefix must NOT trip the layers
clean_lines=$(printf -- '+slack tokens look like xoxb- and are issued per workspace\n+the docs live in docs/\n+version 10.2.0 released\n' | grep -E "$pii_ere" | wc -l)
[ "$clean_lines" -eq 0 ] || {
    echo "NC FAILED: PII pattern fired on clean lines" >&2
    exit 1
}
echo "NC sub-c PASS: clean lines pass (doc slack mention, version-like 10.2.0)"

echo "NC PASS: PII layer rejects machine-local paths and LAN addresses"
