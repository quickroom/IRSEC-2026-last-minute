#!/bin/sh

# Shared, POSIX-compatible helpers. This toolkit deliberately performs no
# firewall, account, service, package, or configuration changes.

set -u
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
umask 077

TOOLKIT_VERSION="1.0.0"
SCRIPT_NAME=$(basename "$0")

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
note() { printf '[%s] %s\n' "$SCRIPT_NAME" "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

safe_tag() {
    printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

make_case_dir() {
    base=${1:-./irsec-evidence}
    tag=${2:-$(hostname -s 2>/dev/null || hostname)}
    stamp=$(date -u '+%Y%m%dT%H%M%SZ')
    CASE_DIR="${base%/}/$(safe_tag "$tag")-$stamp"
    mkdir -p "$CASE_DIR" || die "cannot create $CASE_DIR"
    export CASE_DIR
}

header() {
    file=$1 title=$2
    {
        printf '# %s\n' "$title"
        printf '# UTC: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        printf '# Host: %s\n' "$(hostname 2>/dev/null || printf unknown)"
        printf '# Toolkit: %s\n\n' "$TOOLKIT_VERSION"
    } >"$file"
}

capture() {
    file=$1 title=$2
    shift 2
    header "$file" "$title"
    printf '$' >>"$file"
    for arg in "$@"; do printf ' %s' "$arg" >>"$file"; done
    printf '\n' >>"$file"
    "$@" >>"$file" 2>&1
    rc=$?
    printf '\n# exit_status=%s\n' "$rc" >>"$file"
    return 0
}

capture_sh() {
    file=$1 title=$2 command_text=$3
    header "$file" "$title"
    printf '$ %s\n' "$command_text" >>"$file"
    sh -c "$command_text" >>"$file" 2>&1
    rc=$?
    printf '\n# exit_status=%s\n' "$rc" >>"$file"
    return 0
}

hash_file() {
    if have sha256; then sha256 -q "$1" 2>/dev/null
    elif have sha256sum; then sha256sum "$1" 2>/dev/null | awk '{print $1}'
    else cksum "$1" 2>/dev/null | awk '{print "cksum:" $1 ":" $2}'
    fi
}

write_manifest() {
    dir=$1 out="$1/MANIFEST.sha256"
    : >"$out"
    find "$dir" -type f ! -name MANIFEST.sha256 -print | LC_ALL=C sort |
    while IFS= read -r file; do
        sum=$(hash_file "$file")
        rel=${file#"$dir"/}
        printf '%s  %s\n' "$sum" "$rel" >>"$out"
    done
}

require_root_hint() {
    if [ "$(id -u)" -ne 0 ]; then
        note "not root: some process, socket, account, and configuration details may be hidden"
    fi
}

