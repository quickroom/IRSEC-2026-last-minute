#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME [-o output-directory] [-t tag]"; exit 2; }
OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname)
while getopts 'o:t:h' opt; do case $opt in o) OUT=$OPTARG;; t) TAG=$OPTARG;; *) usage;; esac; done
make_case_dir "$OUT" "$TAG-gui-health"
capture_sh "$CASE_DIR/services.txt" "Web GUI process status" 'ps auxww | grep -E "(nginx|php-fpm)" | grep -v grep || true; echo; service -e 2>/dev/null | grep -E "(nginx|php-fpm)" || true'
capture_sh "$CASE_DIR/listeners.txt" "Web GUI listeners" 'sockstat -46 | awk "NR==1 || /:(80|443)([[:space:]]|$)/"'
capture_sh "$CASE_DIR/log-errors.txt" "Web GUI errors" 'for f in /var/log/nginx.log /var/log/php-fpm.log /var/log/system.log; do [ -f "$f" ] && grep -Eai "(nginx|php-fpm|error|fatal|failed)" "$f"; done | tail -n 1000'
capture_sh "$CASE_DIR/certificates.txt" "Certificate metadata and public details" 'find /conf /cf/conf /etc /usr/local/etc -xdev -type f \( -name "*.crt" -o -name "*.pem" \) ! -iname "*datadog*" -print 2>/dev/null | while IFS= read -r f; do echo "### $f"; stat -f "%Sp %Su:%Sg %z %Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$f"; openssl x509 -in "$f" -noout -subject -issuer -serial -dates -fingerprint -sha256 2>/dev/null || echo "not a readable X.509 certificate"; done'
printf 'Private keys and certificate bodies are not copied. Datadog-named paths are excluded. No services are restarted.\n' >"$CASE_DIR/NOTES.txt"
write_manifest "$CASE_DIR"
note "complete: $CASE_DIR"

