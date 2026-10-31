#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME -d destination-ip -p port [-P tcp|udp] [-o directory] [-t tag]"; exit 2; }
DEST= PORT= PROTO=tcp OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname)
while getopts 'd:p:P:o:t:h' opt; do case $opt in d) DEST=$OPTARG;; p) PORT=$OPTARG;; P) PROTO=$OPTARG;; o) OUT=$OPTARG;; t) TAG=$OPTARG;; *) usage;; esac; done
[ -n "$DEST" ] && [ -n "$PORT" ] || usage
case $DEST in *[!0-9a-fA-F:.]*) die "destination must be a literal IP address";; esac
case $PORT in *[!0-9]*|'') usage;; esac
[ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ] || usage
case $PROTO in tcp|udp) ;; *) usage;; esac
make_case_dir "$OUT" "$TAG-score-$DEST-$PORT"
capture "$CASE_DIR/route.txt" "Route lookup" route -n get "$DEST"
capture_sh "$CASE_DIR/listeners.txt" "Local listeners for requested port" "sockstat -46 | awk 'NR==1 || /:$PORT([[:space:]]|$)/'"
capture_sh "$CASE_DIR/states.txt" "PF states for endpoint" "pfctl -ss 2>/dev/null | awk '/$DEST/ && /:$PORT([[:space:]]|$)/'"
capture_sh "$CASE_DIR/rules.txt" "PF rule counters" 'pfctl -vvsr 2>/dev/null || true'
capture_sh "$CASE_DIR/nat.txt" "PF NAT rules" 'pfctl -vvsn 2>/dev/null || true'
capture_sh "$CASE_DIR/port514-protection.txt" "Barrier-to-timing 514 observations" 'sockstat -46 | awk "NR==1 || /:514([[:space:]]|$)/"; pfctl -ss 2>/dev/null | awk "/:514([[:space:]]|$)/"'
cat >"$CASE_DIR/NEXT-STEPS.txt" <<EOF
Read-only troubleshooting record for $PROTO $DEST:$PORT.

1. Check Hermes' per-check diagnostic before changing anything.
2. Confirm the service listens on the destination host, then test from the router and a permitted remote host.
3. Compare interface, route, NAT, PF rule counters, and PF state evidence in this directory.
4. Do not alter topology or scoring behavior. Do not block subnets or any out-of-scope address.
5. Preserve whiteteam administration, Datadog, and barrier-to-timing TCP/UDP 514.
6. Escalate ambiguous scoring or protected-flow issues to White Team.

This helper intentionally sends no packets. If an active connection test is needed, use a single
known scored endpoint during Hands On and follow the competition packet/White Team direction.
EOF
write_manifest "$CASE_DIR"
note "read-only troubleshooting evidence complete: $CASE_DIR"

