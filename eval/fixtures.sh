#!/bin/sh
# eval fixtures: build three identical copies of a small static-site project,
# differing only in the AGENTS.md setup.
#   fixture-no-dox/  : no AGENTS.md anywhere
#   fixture-bare/    : single root AGENTS.md, generic note (no DOX)
#   fixture-dox/     : DOX installed (template + honesty addendum) with a
#                      prebuilt two-child tree (docs/, src/)
# Deterministic: byte-identical fixtures on every rebuild.
set -e
eval_dir=$(cd "$(dirname "$0")" && pwd)
root="$eval_dir/2026-11-24-run1/fixtures"
rm -rf "$root"
mkdir -p "$root"

base() {
    d=$1
    mkdir -p "$d/src" "$d/docs" "$d/scripts"
    cat > "$d/package.json" <<'EOF'
{
  "name": "acme-landing",
  "version": "1.2.0",
  "private": true
}
EOF
    cat > "$d/LICENSE" <<'EOF'
MIT License

Copyright (c) 2026 Acme Demo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software to deal in the Software without restriction.
EOF
    cat > "$d/README.md" <<'EOF'
# acme-landing

Demo landing page project used by the DOX eval harness.
EOF
    cat > "$d/src/config.js" <<'EOF'
// runtime configuration
export const API_BASE = "https://api.acme-demo.invalid/v1";
export const BUILD_DIR = "dist";
EOF
    cat > "$d/src/version-ledger.md" <<'EOF'
# Version ledger

| Version | Date       | Note              |
|---------|------------|-------------------|
| 1.2.0   | 2026-10-02 | Landing page v1.2 |
| 1.1.0   | 2026-08-15 | Initial release   |
EOF
    cat > "$d/docs/changelog.md" <<'EOF'
# Changelog

## 1.2.0 - 2026-10-02

- Landing page hero refresh

## 1.1.0 - 2026-08-15

- Initial release
EOF
    cat > "$d/docs/guide.md" <<'EOF'
# Integration guide

Point your client at the API base URL from `src/config.js`.
Example: `https://api.acme-demo.invalid/v1/status`
EOF
    cat > "$d/scripts/build.sh" <<'EOF'
#!/bin/sh
echo "building acme-landing (no-op demo)"
EOF
}

# --- fixture-no-dox ---
base "$root/fixture-no-dox"

# --- fixture-bare: one generic root AGENTS.md, no DOX ---
base "$root/fixture-bare"
cat > "$root/fixture-bare/AGENTS.md" <<'EOF'
# Project notes

This is the acme-landing demo project. Keep the docs in sync when you change code.
EOF

# --- fixture-dox: DOX template + honesty, prebuilt two-child tree ---
base "$root/fixture-dox"
cp "$eval_dir/../AGENTS.md" "$root/fixture-dox/AGENTS.md"
sh "$eval_dir/../install.sh" "$root/fixture-dox" > /dev/null

# child docs carry the marker-wrapped core with the index placeholder replaced
# (valid only in installed copies) plus child-specific sections
make_child() {
    d=$1
    purpose=$2
    ownership=$3
    contracts=$4
    guidance=$5
    {
        sed -n '/^<!-- DOX-CORE-START/,/^<!-- DOX-CORE-END/p' "$eval_dir/../AGENTS.md"
        echo ""
        echo "## Purpose"
        echo ""
        echo "- $purpose"
        echo ""
        echo "## Ownership"
        echo ""
        echo "- $ownership"
        echo "- Parent root AGENTS.md owns project-wide rules and the top-level index"
        echo ""
        echo "## Local Contracts"
        echo ""
        echo "$contracts" | sed 's/^/- /'
        echo ""
        echo "## Work Guidance"
        echo ""
        echo "$guidance" | sed 's/^/- /'
        echo ""
        echo "## Verification"
        echo ""
        echo "- No automated verification exists yet; leave empty until one lands"
        echo ""
        echo "## Child DOX Index"
        echo ""
        echo "This directory has no child AGENTS.md files (childless, valid)."
    } > "$d/AGENTS.md.body"
    python3 - "$d/AGENTS.md.body" "$d/AGENTS.md" <<'PYEOF'
import sys
body_path, out_path = sys.argv[1], sys.argv[2]
s = open(body_path).read()
placeholder = "This project is not yet indexed. Before continuing you must scan the project, build the DOX tree and replace this message with the actual index. Go deep and scan files recursively to properly evaluate complexity and create nested DOX files where needed."
childless = "No child AGENTS.md files in this directory (childless, valid)."
assert placeholder in s, "core placeholder not found in child body"
open(out_path, "w").write(s.replace(placeholder, childless))
PYEOF
    rm -f "$d/AGENTS.md.body"
}

make_child "$root/fixture-dox/docs" \
    "Owns all end-user documentation for acme-landing" \
    "Owns: docs/** (changelog.md, guide.md)" \
    "Every release entry in changelog.md must have a matching entry appended to src/version-ledger.md (version, date, note)" \
    "Write release entries as '## X.Y.Z - YYYY-MM-DD' followed by the change bullets"

make_child "$root/fixture-dox/src" \
    "Owns the runtime source for acme-landing" \
    "Owns: src/** (config.js, version-ledger.md)" \
    "config.js is the single source for the API base path; changing it requires updating the examples in docs/guide.md" \
    "Keep config.js minimal; no feature flags in this demo"

# root Child DOX Index: replace the placeholder (project-fillable in an
# INSTALLED copy) with the machine-checkable index
python3 - "$root/fixture-dox/AGENTS.md" <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
placeholder = "This project is not yet indexed. Before continuing you must scan the project, build the DOX tree and replace this message with the actual index. Go deep and scan files recursively to properly evaluate complexity and create nested DOX files where needed."
index = """| Path | Scope | File |
|------|-------|------|
| `docs/` | end-user documentation and release process | [AGENTS.md](docs/AGENTS.md) |
| `src/` | runtime source, config and version ledger | [AGENTS.md](src/AGENTS.md) |"""
assert placeholder in s, "placeholder not found"
s = s.replace(placeholder, index)
open(p, "w").write(s)
print("root index installed")
PYEOF
echo "fixtures built under $root"
