#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME -r local.pcap [-o output-directory] [-t tag]"; exit 2; }
PCAP= OUT=./irsec-evidence TAG=pcap
while getopts 'r:o:t:h' opt; do case $opt in r) PCAP=$OPTARG;; o) OUT=$OPTARG;; t) TAG=$OPTARG;; *) usage;; esac; done
[ -f "$PCAP" ] || usage
case $PCAP in *"'"*|*"\n"*) die "pcap path contains unsupported characters";; esac
make_case_dir "$OUT" "$TAG-analysis"
capture_sh "$CASE_DIR/packets.txt" "Packet listing" "tcpdump -n -tttt -r '$PCAP' 2>/dev/null"
capture_sh "$CASE_DIR/conversations.txt" "Observed IP conversations" "tcpdump -n -r '$PCAP' 2>/dev/null | awk '/ IP6? / {print \$3, \$5}' | sed 's/:$//' | sort | uniq -c | sort -nr"
capture_sh "$CASE_DIR/port514.txt" "Observed TCP/UDP 514 traffic" "tcpdump -n -r '$PCAP' 'port 514' 2>/dev/null"
capture_sh "$CASE_DIR/dns.txt" "Observed DNS traffic" "tcpdump -n -r '$PCAP' 'port 53' 2>/dev/null"
write_manifest "$CASE_DIR"
note "analysis complete: $CASE_DIR"

