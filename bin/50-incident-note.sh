#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../lib/common.sh"
usage() { echo "usage: $SCRIPT_NAME -s short-title [-H host] [-o notes-directory]"; exit 2; }
TITLE= HOST=unknown OUT=./irsec-notes
while getopts 's:H:o:h' opt; do case $opt in s) TITLE=$OPTARG;; H) HOST=$OPTARG;; o) OUT=$OPTARG;; *) usage;; esac; done
[ -n "$TITLE" ] || usage
STAMP=$(date -u '+%Y%m%dT%H%M%SZ')
DIR="${OUT%/}/$STAMP-$(safe_tag "$TITLE")"
mkdir -p "$DIR" || die "cannot create $DIR"
cat >"$DIR/finding.md" <<EOF
# Finding: $TITLE

- UTC first observed: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
- Host: $HOST
- Recorded by:
- Status: investigating

## What was observed

[Human operator: describe the observation in your own words.]

## Evidence

- Evidence path or screenshot:
- Relevant timestamp:
- Hash or manifest result:

## Service impact

[Human operator: record affected service and scoring impact.]

## Actions and authorization

[Human operator: record manual actions, time, result, rollback information, and any White Team direction.]

## Follow-up

[Human operator: record remaining questions and validation steps.]

This template organizes contemporaneous evidence only. Do not use it as an AI-written inject or final Incident Response Report. The registered team members must author those submissions themselves under IRSeC rules.
EOF
printf 'Created %s\n' "$DIR/finding.md"

