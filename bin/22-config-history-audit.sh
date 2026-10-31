#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME [-o output-directory] [-t tag]"; exit 2; }
OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname)
while getopts 'o:t:h' opt; do case $opt in o) OUT=$OPTARG;; t) TAG=$OPTARG;; *) usage;; esac; done
make_case_dir "$OUT" "$TAG-config-history"
HISTORY=/cf/conf/backup OUTFILE="$CASE_DIR/config-history.tsv"
printf 'sha256\tmode\towner\tgroup\tsize\tmtime_utc\tpath\n' >"$OUTFILE"
if [ -d "$HISTORY" ]; then
    find "$HISTORY" -xdev -type f -print 2>/dev/null | LC_ALL=C sort | while IFS= read -r file; do
        sum=$(hash_file "$file")
        meta=$(stat -f '%Sp\t%Su\t%Sg\t%z\t%Sm' -t '%Y-%m-%dT%H:%M:%SZ' "$file" 2>/dev/null || printf '?\t?\t?\t?\t?')
        printf '%s\t%s\t%s\n' "$sum" "$meta" "$file"
    done >>"$OUTFILE"
else
    printf 'No readable %s directory found.\n' "$HISTORY" >"$CASE_DIR/NOTES.txt"
fi
capture_sh "$CASE_DIR/current-config.txt" "Current configuration fingerprint" 'if [ -f /cf/conf/config.xml ]; then stat -f "%Sp %Su:%Sg %z %Sm %N" -t "%Y-%m-%dT%H:%M:%SZ" /cf/conf/config.xml; (sha256 -q /cf/conf/config.xml 2>/dev/null || cksum /cf/conf/config.xml); fi'
cat >"$CASE_DIR/REVIEW.txt" <<'EOF'
This audit intentionally records metadata and hashes only. It does not copy, print, restore, or parse configuration contents because they may contain credentials, keys, and protected settings.

Use pfSense's authenticated configuration-history interface for a human review. Never restore automatically. Escalate any history involving whiteteam, Datadog, syslog-ng, timing, or port 514 to White Team before acting.
EOF
write_manifest "$CASE_DIR"
note "complete: $CASE_DIR"

