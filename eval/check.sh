#!/bin/sh
# success oracle for the fixed eval tasks. Usage: check.sh <fixture-dir> <t1|t2>
# Prints ok/failed per criterion (ALL of them), exits 0 only when ALL pass.
# No set -e: a failing probe must not abort before the failed: lines print.
d=$1
task=$2
fail=0
crit() { # crit <name> <result-ok:0/1>
    if [ "$2" = "0" ]; then echo "ok: $1"; else echo "failed: $1"; fail=1; fi
}

if [ "$task" = "t1" ]; then
    grep -q '/v2' "$d/src/config.js" 2> /dev/null
    crit "config.js uses /v2" $?
    grep -q '/v1' "$d/src/config.js" 2> /dev/null
    crit "config.js has no /v1 left" $((1 - $?))
elif [ "$task" = "t2" ]; then
    grep -q '"version": "1.3.0"' "$d/package.json" 2> /dev/null
    crit "package.json bumped to 1.3.0" $?
    grep -q '1.3.0' "$d/docs/changelog.md" 2> /dev/null
    crit "changelog has a 1.3.0 entry" $?
else
    echo "unknown task: $task" >&2
    exit 2
fi

[ "$fail" = "0" ] || exit 1
echo "success: $task"
