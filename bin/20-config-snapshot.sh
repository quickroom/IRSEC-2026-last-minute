#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME [-o output-directory] [-t case-tag]"; exit 2; }
OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname)
while getopts 'o:t:h' opt; do case $opt in o) OUT=$OPTARG;; t) TAG=$OPTARG;; *) usage;; esac; done
make_case_dir "$OUT" "$TAG-config"
OUTFILE="$CASE_DIR/config-fingerprints.tsv"
printf 'sha256\tmode\towner\tgroup\tsize\tmtime_utc\tpath\n' >"$OUTFILE"
for root in /cf/conf /etc /usr/local/etc /usr/local/www; do
    [ -d "$root" ] || continue
    find "$root" -xdev -type f -print 2>/dev/null
done | LC_ALL=C sort -u | while IFS= read -r file; do
    sum=$(hash_file "$file")
    meta=$(stat -f '%Sp\t%Su\t%Sg\t%z\t%Sm' -t '%Y-%m-%dT%H:%M:%SZ' "$file" 2>/dev/null || printf '?\t?\t?\t?\t?')
    printf '%s\t%s\t%s\n' "$sum" "$meta" "$file"
done >>"$OUTFILE"
write_manifest "$CASE_DIR"
note "fingerprints only; no configuration contents copied: $CASE_DIR"

