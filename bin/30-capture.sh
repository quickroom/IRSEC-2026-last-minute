#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME -i interface [-c packet-count] [-f tcpdump-filter] [-o directory] [-t tag]"; exit 2; }
IFACE= COUNT=500 FILTER= OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname)
while getopts 'i:c:f:o:t:h' opt; do case $opt in i) IFACE=$OPTARG;; c) COUNT=$OPTARG;; f) FILTER=$OPTARG;; o) OUT=$OPTARG;; t) TAG=$OPTARG;; *) usage;; esac; done
[ -n "$IFACE" ] || usage
case $COUNT in *[!0-9]*|'') usage;; esac
if ! ifconfig "$IFACE" >/dev/null 2>&1; then die "interface not found: $IFACE"; fi
make_case_dir "$OUT" "$TAG-capture"
PCAP="$CASE_DIR/traffic.pcap" META="$CASE_DIR/capture.txt"
header "$META" "Bounded local packet capture"
printf 'interface=%s\npacket_limit=%s\nfilter=%s\n' "$IFACE" "$COUNT" "${FILTER:-<none>}" >>"$META"
note "capturing at most $COUNT packets on $IFACE; press Ctrl-C to stop early"
if [ -n "$FILTER" ]; then tcpdump -n -i "$IFACE" -s 0 -c "$COUNT" -w "$PCAP" "$FILTER"
else tcpdump -n -i "$IFACE" -s 0 -c "$COUNT" -w "$PCAP"; fi
capture_sh "$CASE_DIR/summary.txt" "Capture summary" "tcpdump -n -tttt -r '$PCAP' 2>/dev/null"
write_manifest "$CASE_DIR"
note "local capture complete: $CASE_DIR"

