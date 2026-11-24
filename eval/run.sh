#!/bin/sh
# eval runner: runs the fixed tasks across the three fixture configs with
# opencode (fixed model from the user config), exports raw session artifacts,
# and writes meta.json per run. Usage: run.sh [t1|t2|both]
set -e
eval_dir=$(cd "$(dirname "$0")" && pwd)
run_dir="$eval_dir/2026-11-24-run1"
fixtures="$run_dir/fixtures"
out="$run_dir/runs"
mkdir -p "$out"

which_t=${1:-both}

run_one() {
    cfg=$1
    task=$2
    d="$fixtures/$cfg"
    title="dox-eval $cfg $task"
    stamp=$(date -u +%Y%m%dT%H%M%SZ)
    slug="$cfg-$task"
    echo "=== run: $slug ==="
    # each task gets its own pristine copy so runs never share state
    work="$out/$slug/work"
    rm -rf "$work"
    mkdir -p "$out/$slug"
    cp -r "$d" "$work"
    prompt_t1="In this project, change the API base path in src/config.js from /v1 to /v2. Then stop and report."
    prompt_t2="Release version 1.3.0 of this project: bump the version in package.json to 1.3.0 and add a matching release entry to docs/changelog.md (today is 2026-11-24). Then stop and report."
    if [ "$task" = "t1" ]; then prompt=$prompt_t1; else prompt=$prompt_t2; fi
    out_json="$out/$slug/opencode-output.json"
    (cd "$work" && opencode run --model zai-coding-plan/glm-5.3-flash --title "$title" --archived --format json "$prompt") > "$out_json" 2> "$out/$slug/opencode-stderr.log" || echo "nonzero exit from opencode run (recorded)" > "$out/$slug/exit-note.txt"
    # session id from the json output (last line carrying a sessionID)
    sid=$(jq -r 'paths(.sessionID) as $p | getpath($p)' "$out_json" 2> /dev/null | grep '^ses_' | tail -1 || true)
    if [ -z "$sid" ]; then
        # fall back: find the newest archived session by title
        sid=$(opencode api get /api/session | jq -r --arg t "$title" '.data[] | select(.title == $t) | .id' | head -1)
    fi
    echo "session: $sid"
    if [ -n "$sid" ]; then
        opencode api get "/api/experimental/session/$sid/export" > "$out/$slug/transcript.json" 2>/dev/null || true
        opencode api get /api/session | jq --arg s "$sid" '.data[] | select(.id == $s) | {id, title, model, cost, tokens, time}' > "$out/$slug/meta.json" 2>/dev/null || true
    fi
    # success oracle
    if sh "$eval_dir/check.sh" "$work" "$task" > "$out/$slug/checks.txt" 2>&1; then
        echo "success: true" > "$out/$slug/result.txt"
    else
        echo "success: false" > "$out/$slug/result.txt"
    fi
    cat "$out/$slug/checks.txt"
    cat "$out/$slug/result.txt"
}

for cfg in fixture-no-dox fixture-bare fixture-dox; do
    if [ "$which_t" = "both" ] || [ "$which_t" = "t1" ]; then run_one "$cfg" t1; fi
    if [ "$which_t" = "both" ] || [ "$which_t" = "t2" ]; then run_one "$cfg" t2; fi
done
echo "runs complete under $out"
