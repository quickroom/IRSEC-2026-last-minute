#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME [-o output-directory] [-t tag] [-i seconds] [-n iterations]"; exit 2; }
OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname) INTERVAL=60 ITERATIONS=0
while getopts 'o:t:i:n:h' opt; do case $opt in o) OUT=$OPTARG;; t) TAG=$OPTARG;; i) INTERVAL=$OPTARG;; n) ITERATIONS=$OPTARG;; *) usage;; esac; done
case $INTERVAL:$ITERATIONS in *[!0-9:]*|:*) usage;; esac
make_case_dir "$OUT" "$TAG-monitor"
PREV="$CASE_DIR/previous.tsv" LOG="$CASE_DIR/changes.log"
snapshot() {
    dest=$1
    for root in /cf/conf /etc /usr/local/etc /usr/local/www; do [ -d "$root" ] && find "$root" -xdev -type f -print 2>/dev/null; done | LC_ALL=C sort -u |
    while IFS= read -r file; do printf '%s\t%s\n' "$(hash_file "$file")" "$file"; done >"$dest"
}
header "$LOG" "Configuration change monitor"
snapshot "$PREV"
count=0
trap 'note "stopped; evidence retained in $CASE_DIR"; write_manifest "$CASE_DIR"; exit 0' INT TERM HUP
while :; do
    sleep "$INTERVAL"
    CUR="$CASE_DIR/current.tsv"
    snapshot "$CUR"
    if ! cmp -s "$PREV" "$CUR"; then
        printf '\n## %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$LOG"
        diff -u "$PREV" "$CUR" >>"$LOG" 2>&1 || true
        mv "$CUR" "$PREV"
    else rm -f "$CUR"; fi
    count=$((count + 1))
    [ "$ITERATIONS" -gt 0 ] && [ "$count" -ge "$ITERATIONS" ] && break
done
write_manifest "$CASE_DIR"
note "complete: $CASE_DIR"

