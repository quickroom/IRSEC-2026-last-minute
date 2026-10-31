#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME [-o output-directory] [-t tag]"; exit 2; }
OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname)
while getopts 'o:t:h' opt; do case $opt in o) OUT=$OPTARG;; t) TAG=$OPTARG;; *) usage;; esac; done
make_case_dir "$OUT" "$TAG-process-map"
require_root_hint
capture_sh "$CASE_DIR/processes.tsv" "Process identity and ancestry" 'ps axww -o user,pid,ppid,lstart,time,state,command'
capture "$CASE_DIR/sockets.txt" "Process socket map" sockstat -46
capture_sh "$CASE_DIR/open-files.txt" "Open file map" 'command -v procstat >/dev/null 2>&1 && procstat -af 2>/dev/null || true'
capture_sh "$CASE_DIR/executable-map.txt" "Process executable map" 'if command -v procstat >/dev/null 2>&1; then for p in $(ps ax -o pid=); do procstat -b "$p" 2>/dev/null; done; fi'
capture_sh "$CASE_DIR/suspicious-locations.txt" "Temporary or deleted executable indicators" 'ps axww -o user,pid,ppid,lstart,command | awk "NR==1 || /\/tmp\/|\/var\/tmp\/|\/dev\/shm\/|\(deleted\)/"'
write_manifest "$CASE_DIR"
note "complete: $CASE_DIR"

