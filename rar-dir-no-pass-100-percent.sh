#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 /path/to/directory"
    exit 1
fi

SRC_DIR="${1%/}"

if [ ! -d "$SRC_DIR" ]; then
    echo "Error: '$SRC_DIR' is not a directory"
    exit 1
fi

MASK="{_NO_password_100prc_rec_record}"
BASE_NAME="$(basename "$SRC_DIR")"
PARENT_DIR="$(dirname "$SRC_DIR")"
ARCHIVE_NAME="${BASE_NAME}${MASK}.rar"

cd "$PARENT_DIR"

rar a \
    -ma5 \
    -m5 \
    -ep1 \
    -r \
    -df \
    -rr100% \
    -t \
    -qo+ \
    -oi+ \
    -htb \
    "-ms*.rar;*.zip;*.jpg;*.mp4;*.mp3" \
    -- \
    "$ARCHIVE_NAME" \
    "$BASE_NAME"

echo "Created: $PARENT_DIR/$ARCHIVE_NAME"
