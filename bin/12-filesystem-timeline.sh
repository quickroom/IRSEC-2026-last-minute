#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME [-o directory] [-t tag] [-d days]"; exit 2; }
OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname) DAYS=8
while getopts 'o:t:d:h' opt; do case $opt in o) OUT=$OPTARG;; t) TAG=$OPTARG;; d) DAYS=$OPTARG;; *) usage;; esac; done
case $DAYS in *[!0-9]*|'') usage;; esac
make_case_dir "$OUT" "$TAG-file-timeline"
OUTFILE="$CASE_DIR/recent-files.tsv"
printf 'mtime_utc\tmode\towner\tgroup\tsize\tsha256\tpath\n' >"$OUTFILE"
for root in /cf/conf /etc /usr/local/etc /usr/local/www /etc/rc.d /usr/local/etc/rc.d /tmp /var/tmp; do
    [ -d "$root" ] || continue
    find "$root" -xdev -type f -mtime "-$DAYS" ! -iname '*datadog*' -print 2>/dev/null
done | LC_ALL=C sort -u | while IFS= read -r file; do
    case $file in *[Dd][Aa][Tt][Aa][Dd][Oo][Gg]*) continue;; esac
    sum=$(hash_file "$file")
    meta=$(stat -f '%Sm\t%Sp\t%Su\t%Sg\t%z' -t '%Y-%m-%dT%H:%M:%SZ' "$file" 2>/dev/null || printf '?\t?\t?\t?\t?')
    printf '%s\t%s\t%s\n' "$meta" "$sum" "$file"
done >>"$OUTFILE"
printf 'window_days=%s\nDatadog-named paths were excluded. Review timestamps as leads, not proof of compromise.\n' "$DAYS" >"$CASE_DIR/NOTES.txt"
write_manifest "$CASE_DIR"
note "complete: $CASE_DIR"

