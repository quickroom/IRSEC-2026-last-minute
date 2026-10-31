#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME [-o directory] [-t tag] [-i seconds] [-n iterations]"; exit 2; }
OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname) INTERVAL=30 ITERATIONS=10
while getopts 'o:t:i:n:h' opt; do case $opt in o) OUT=$OPTARG;; t) TAG=$OPTARG;; i) INTERVAL=$OPTARG;; n) ITERATIONS=$OPTARG;; *) usage;; esac; done
case $INTERVAL:$ITERATIONS in *[!0-9:]*|:*) usage;; esac
[ "$ITERATIONS" -gt 0 ] || die "iterations must be greater than zero"
make_case_dir "$OUT" "$TAG-pf-counters"
LOG="$CASE_DIR/pf-counter-snapshots.txt"
header "$LOG" "PF rule and state counter snapshots"
count=1
trap 'write_manifest "$CASE_DIR"; note "stopped: $CASE_DIR"; exit 0' INT TERM HUP
while [ "$count" -le "$ITERATIONS" ]; do
    printf '\n===== snapshot %s/%s %s =====\n' "$count" "$ITERATIONS" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
    pfctl -vvsr >>"$LOG" 2>&1 || true
    printf '\n--- state summary ---\n' >>"$LOG"
    pfctl -si >>"$LOG" 2>&1 || true
    count=$((count + 1))
    [ "$count" -le "$ITERATIONS" ] && sleep "$INTERVAL"
done
write_manifest "$CASE_DIR"
note "complete: $CASE_DIR"

