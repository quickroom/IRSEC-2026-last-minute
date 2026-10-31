#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
[ "$#" -eq 1 ] || die "usage: $SCRIPT_NAME evidence-directory"
DIR=$1 MANIFEST="$1/MANIFEST.sha256"
[ -f "$MANIFEST" ] || die "manifest not found: $MANIFEST"
bad=0
while IFS='  ' read -r expected rel; do
    [ -n "$rel" ] || continue
    actual=$(hash_file "$DIR/$rel")
    if [ "$actual" != "$expected" ]; then printf 'MISMATCH %s\n' "$rel"; bad=1; fi
done <"$MANIFEST"
[ "$bad" -eq 0 ] && echo "OK: evidence files match manifest"
exit "$bad"

