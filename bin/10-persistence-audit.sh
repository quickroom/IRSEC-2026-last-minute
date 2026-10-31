#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME [-o output-directory] [-t case-tag]"; exit 2; }
OUT=./irsec-evidence TAG=$(hostname -s 2>/dev/null || hostname)
while getopts 'o:t:h' opt; do case $opt in o) OUT=$OPTARG;; t) TAG=$OPTARG;; *) usage;; esac; done
make_case_dir "$OUT" "$TAG-audit"
require_root_hint

capture "$CASE_DIR/passwd.txt" "Local accounts" getent passwd
capture "$CASE_DIR/groups.txt" "Local groups" getent group
capture_sh "$CASE_DIR/uid0.txt" "UID 0 accounts" "getent passwd | awk -F: '\$3 == 0 {print}'"
capture_sh "$CASE_DIR/login-policy.txt" "Account status" 'pw usershow -a 2>/dev/null || true; echo; last -20 2>/dev/null || true; echo; who 2>/dev/null || true'
capture_sh "$CASE_DIR/ssh-config.txt" "Effective SSH configuration" 'sshd -T 2>/dev/null || (grep -Ev "^[[:space:]]*(#|$)" /etc/ssh/sshd_config 2>/dev/null || true)'
capture_sh "$CASE_DIR/authorized-keys-metadata.txt" "Authorized key metadata and fingerprints" 'find /root /home -xdev -type f -name authorized_keys -print 2>/dev/null | while IFS= read -r f; do stat -f "%Sp %Su:%Sg %z %Sm %N" -t "%Y-%m-%dT%H:%M:%SZ" "$f"; if command -v ssh-keygen >/dev/null 2>&1; then while IFS= read -r line; do printf "%s\n" "$line" | ssh-keygen -lf - 2>/dev/null || true; done < "$f"; fi; done'
capture_sh "$CASE_DIR/sudoers-metadata.txt" "Privilege configuration metadata" 'find /usr/local/etc/sudoers* /etc/sudoers* -xdev -type f -exec stat -f "%Sp %Su:%Sg %z %Sm %N" -t "%Y-%m-%dT%H:%M:%SZ" {} \; 2>/dev/null || true'
capture_sh "$CASE_DIR/cron.txt" "Scheduled tasks" 'crontab -l 2>/dev/null || true; echo; find /etc/cron.d /etc/periodic /var/cron/tabs -xdev -type f -maxdepth 4 -exec stat -f "%Sp %Su:%Sg %z %Sm %N" -t "%Y-%m-%dT%H:%M:%SZ" {} \; 2>/dev/null | sort'
capture_sh "$CASE_DIR/startup.txt" "Startup and package scripts" 'for d in /etc/rc.conf /etc/rc.conf.local /etc/rc.local /etc/rc.d /usr/local/etc/rc.d; do [ -e "$d" ] && find "$d" -xdev -maxdepth 2 -type f -exec stat -f "%Sp %Su:%Sg %z %Sm %N" -t "%Y-%m-%dT%H:%M:%SZ" {} \;; done 2>/dev/null | sort'
capture_sh "$CASE_DIR/recent-executables.txt" "Recently changed executable files" 'find /etc /usr/local/etc /usr/local/www /tmp /var/tmp -xdev -type f -mtime -8 -perm -111 -exec stat -f "%Sp %Su:%Sg %z %Sm %N" -t "%Y-%m-%dT%H:%M:%SZ" {} \; 2>/dev/null | sort'
capture_sh "$CASE_DIR/temp-processes.txt" "Processes referencing temporary paths" 'ps auxww | awk "NR==1 || /\/tmp\/|\/var\/tmp\/|\/dev\/shm\//"'
capture_sh "$CASE_DIR/web-metadata.txt" "Web GUI file changes (metadata only)" 'find /usr/local/www -xdev -type f -mtime -8 -exec stat -f "%Sp %Su:%Sg %z %Sm %N" -t "%Y-%m-%dT%H:%M:%SZ" {} \; 2>/dev/null | sort'
write_manifest "$CASE_DIR"
note "complete: $CASE_DIR"

