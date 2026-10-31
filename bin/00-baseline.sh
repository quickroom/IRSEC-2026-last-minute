#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"

usage() { echo "usage: $SCRIPT_NAME [-o output-directory] [-t case-tag]"; exit 2; }
OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname)
while getopts 'o:t:h' opt; do case $opt in o) OUT=$OPTARG;; t) TAG=$OPTARG;; *) usage;; esac; done
make_case_dir "$OUT" "$TAG-baseline"
require_root_hint
note "writing local evidence to $CASE_DIR"

capture "$CASE_DIR/system.txt" "System identity" uname -a
capture_sh "$CASE_DIR/version.txt" "pfSense and FreeBSD versions" '(cat /etc/version 2>/dev/null || true); freebsd-version -ku 2>/dev/null || true'
capture "$CASE_DIR/interfaces.txt" "Interfaces and addresses" ifconfig -a
capture "$CASE_DIR/routes.txt" "Routing table" netstat -rn -f inet
capture_sh "$CASE_DIR/routes6.txt" "IPv6 routing table" 'netstat -rn -f inet6 2>/dev/null || true'
capture "$CASE_DIR/arp.txt" "Neighbor cache" arp -an
capture_sh "$CASE_DIR/pf-info.txt" "PF status" 'pfctl -si 2>/dev/null || true'
capture_sh "$CASE_DIR/pf-rules.txt" "PF rules with counters" 'pfctl -vvsr 2>/dev/null || true'
capture_sh "$CASE_DIR/pf-nat.txt" "PF NAT rules" 'pfctl -vvsn 2>/dev/null || true'
capture_sh "$CASE_DIR/pf-states.txt" "PF states" 'pfctl -ss 2>/dev/null || true'
capture_sh "$CASE_DIR/pf-tables.txt" "PF tables" 'pfctl -s Tables 2>/dev/null || true'
capture "$CASE_DIR/listeners.txt" "Listening and connected sockets" sockstat -46
capture "$CASE_DIR/processes.txt" "Processes" ps auxww
capture_sh "$CASE_DIR/process-tree.txt" "Process tree" 'ps axd -o user,pid,ppid,start,time,command 2>/dev/null || ps axww -o user,pid,ppid,start,time,command'
capture_sh "$CASE_DIR/services.txt" "Enabled and running services" 'service -e 2>/dev/null; echo; ps auxww | grep -E "(syslog-ng|datadog|dd-agent)" | grep -v grep || true'
capture_sh "$CASE_DIR/config-metadata.txt" "Configuration metadata and hashes" 'for f in /cf/conf/config.xml /etc/pf.conf /usr/local/etc/syslog-ng.conf /usr/local/etc/sshd_config /etc/ssh/sshd_config; do if [ -e "$f" ]; then stat -f "%Sp %Su:%Sg %z %Sm %N" -t "%Y-%m-%dT%H:%M:%SZ" "$f"; (sha256 -q "$f" 2>/dev/null || cksum "$f"); fi; done'
capture_sh "$CASE_DIR/protected-observations.txt" "Protected component observations (no modification)" 'echo "whiteteam account:"; pw usershow whiteteam 2>/dev/null || true; echo; echo "Datadog objects (names only):"; (pw usershow dd-agent 2>/dev/null; pw usershow ddagentuser 2>/dev/null; service -l 2>/dev/null | grep -i datadog) || true; echo; echo "Port 514 sockets/states:"; sockstat -46 | awk "NR==1 || /:514([[:space:]]|$)/"; pfctl -ss 2>/dev/null | awk "/:514([[:space:]]|$)/"'
write_manifest "$CASE_DIR"
note "complete: $CASE_DIR"

