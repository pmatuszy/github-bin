#!/usr/bin/env bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (rar-dir-no-pass-100-percent).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
EOF
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    *) break ;;
  esac
done

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
