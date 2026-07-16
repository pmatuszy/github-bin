#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay
# 2021.05.26 - v. 0.2 - added XDG_RUNTIME_DIR,XDG_DATA_DIR,added -u 
# 2021.05.20 - v. 0.1 - initial release


show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (signal-test).

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
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

if [ ! -f /opt/signal-cli/bin/signal-cli ];then
  echo 
  echo "signal-cli is not installed (/opt/signal-cli/bin/signal-cli)"
  echo 
  exit 1
fi

export XDG_DATA_DIR=/encrypted/root/XDG_DATA_HOME
export XDG_RUNTIME_DIR=/run/user/0

time /opt/signal-cli/bin/signal-cli -u +41763691467 send -m "[`date '+%Y.%m.%d %H:%M:%S'`] test from `hostname`" --note-to-self
