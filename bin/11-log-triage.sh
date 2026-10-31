#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME [-o output-directory] [-t tag] [-m minutes]"; exit 2; }
OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname) MINUTES=120
while getopts 'o:t:m:h' opt; do case $opt in o) OUT=$OPTARG;; t) TAG=$OPTARG;; m) MINUTES=$OPTARG;; *) usage;; esac; done
case $MINUTES in *[!0-9]*|'') usage;; esac
make_case_dir "$OUT" "$TAG-logs"
require_root_hint

LOGS="/var/log/system.log /var/log/auth.log /var/log/filter.log /var/log/nginx.log /var/log/php-fpm.log /var/log/resolver.log /var/log/dhcpd.log"
header "$CASE_DIR/log-files.txt" "Available local logs (Datadog excluded)"
for file in $LOGS; do [ -f "$file" ] && stat -f '%Sp %Su:%Sg %z %Sm %N' -t '%Y-%m-%dT%H:%M:%SZ' "$file" >>"$CASE_DIR/log-files.txt"; done

capture_sh "$CASE_DIR/auth-events.txt" "Authentication and access events" 'for f in /var/log/auth.log /var/log/system.log; do [ -f "$f" ] && grep -Eai "(sshd|login|authentication|failed|accepted|invalid user|sudo|su:)" "$f"; done | tail -n 1000'
capture_sh "$CASE_DIR/gui-events.txt" "Web GUI and PHP events" 'for f in /var/log/nginx.log /var/log/php-fpm.log /var/log/system.log; do [ -f "$f" ] && grep -Eai "(nginx|php-fpm|webgui|login|error|warning|fatal|config)" "$f"; done | tail -n 1000'
capture_sh "$CASE_DIR/firewall-events.txt" "Recent firewall log records" 'for f in /var/log/filter.log /var/log/system.log; do [ -f "$f" ] && tail -n 1500 "$f"; done'
capture_sh "$CASE_DIR/service-errors.txt" "Recent service errors" 'for f in /var/log/system.log /var/log/nginx.log /var/log/php-fpm.log /var/log/resolver.log /var/log/dhcpd.log; do [ -f "$f" ] && grep -Eai "(error|failed|failure|fatal|panic|segfault|denied|timeout|refused)" "$f"; done | tail -n 1000'
capture_sh "$CASE_DIR/config-events.txt" "Configuration-related events" 'for f in /var/log/system.log /var/log/auth.log; do [ -f "$f" ] && grep -Eai "(config|filter reload|pfctl|rc\.filter|xml|backup|restore)" "$f"; done | tail -n 1000'
printf 'requested_window_minutes=%s\nnote=Log formats vary; output is a bounded keyword triage, not a complete interpretation. Datadog paths are intentionally excluded.\n' "$MINUTES" >"$CASE_DIR/NOTES.txt"
write_manifest "$CASE_DIR"
note "complete: $CASE_DIR"

