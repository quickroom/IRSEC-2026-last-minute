#!/bin/sh
set -u
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail=0

for file in "$ROOT"/bin/*.sh "$ROOT"/lib/*.sh; do
    if ! /bin/sh -n "$file"; then echo "FAIL syntax: $file"; fail=1; fi
done

# Reject system-changing command forms. Local evidence housekeeping (mkdir,
# mv/rm within CASE_DIR) is intentionally allowed.
if grep -R -n -E 'pfctl[[:space:]]+-(d|e|f|F)|easyrule|service[[:space:]].*(start|stop|restart|enable|disable)|sysrc|pkg[[:space:]]+(add|install|delete)|pw[[:space:]]+(useradd|usermod|userdel)|(^|[;|])[[:space:]]*passwd([[:space:]]|$)|kill(all)?[[:space:]]|shutdown|reboot|ifconfig[[:space:]].*(up|down)|route[[:space:]]+(add|delete|change)|curl.*(-T|--upload)|scp[[:space:]]|ftp[[:space:]]' "$ROOT/bin" "$ROOT/lib"; then
    echo "FAIL: possible mutating or upload command found"
    fail=1
fi

TMPBASE=${TMPDIR:-/tmp}/irsec-toolkit-test.$$
mkdir -p "$TMPBASE/case"
printf 'sample evidence\n' >"$TMPBASE/case/sample.txt"
(
    . "$ROOT/lib/common.sh"
    write_manifest "$TMPBASE/case"
)
if ! "$ROOT/bin/90-verify-evidence.sh" "$TMPBASE/case" >/dev/null; then
    echo "FAIL: evidence manifest verification"
    fail=1
fi
printf 'tamper\n' >>"$TMPBASE/case/sample.txt"
if "$ROOT/bin/90-verify-evidence.sh" "$TMPBASE/case" >/dev/null 2>&1; then
    echo "FAIL: evidence tampering was not detected"
    fail=1
fi
rm -rf "$TMPBASE"

if [ "$fail" -eq 0 ]; then
    echo "PASS: syntax, read-only policy scan, and manifest integrity tests"
fi
exit "$fail"
