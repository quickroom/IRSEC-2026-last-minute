#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME [-o output-directory] [-t tag]"; exit 2; }
OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname)
while getopts 'o:t:h' opt; do case $opt in o) OUT=$OPTARG;; t) TAG=$OPTARG;; *) usage;; esac; done
make_case_dir "$OUT" "$TAG-dns-time"
capture_sh "$CASE_DIR/clock.txt" "Local clock and timezone" 'date; date -u; sysctl kern.boottime 2>/dev/null || true'
capture_sh "$CASE_DIR/time-status.txt" "NTP status" 'ntpq -pn 2>/dev/null || chronyc sources -v 2>/dev/null || true; echo; ps auxww | grep -E "(ntpd|chronyd)" | grep -v grep || true'
capture_sh "$CASE_DIR/resolver.txt" "Resolver configuration" 'cat /etc/resolv.conf 2>/dev/null || true; echo; ps auxww | grep -E "(unbound|dnsmasq)" | grep -v grep || true; echo; sockstat -46 | awk "NR==1 || /:53([[:space:]]|$)/"'
capture_sh "$CASE_DIR/routes.txt" "Routes relevant to DNS and time" 'netstat -rn -f inet; echo; netstat -rn -f inet6 2>/dev/null || true'
capture_sh "$CASE_DIR/log-errors.txt" "DNS and time errors" 'for f in /var/log/resolver.log /var/log/system.log; do [ -f "$f" ] && grep -Eai "(unbound|dns|resolve|ntp|clock|time.*(error|fail)|error|failed)" "$f"; done | tail -n 1000'
printf 'This script sends no DNS or NTP probes and changes no clock or resolver settings.\n' >"$CASE_DIR/NOTES.txt"
write_manifest "$CASE_DIR"
note "complete: $CASE_DIR"

