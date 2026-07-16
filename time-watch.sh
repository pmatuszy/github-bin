#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.06.11 - v. 0.3 - show time only (no date) in figlet display
# 2026.04.21 - v. 0.2 - require procps-ng GNU watch (-w/--no-wrap; sub-second -n); document intent
# 2023.01.16 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Needs procps-ng `watch` (Linux): -t (no header), -w (no line wrap), fractional -n (e.g. 0.1s).

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

check_if_installed figlet watch

# Needs procps-ng `watch` (Linux): -t (no header), -w (no line wrap), fractional -n (e.g. 0.1s).
# BSD/macOS watch is different and will not work as-is.
require_gnu_watch() {
  local h
  h=$(watch -h 2>&1 || true)
  [[ -z "$h" ]] && h=$(watch --help 2>&1 || true)
  if ! grep -qE -- '(--no-wrap|[[:space:]]-w[,[:space:]])' <<<"$h"; then
    echo "(PGM) This script requires GNU procps-ng watch (-w / --no-wrap and sub-second -n). See time-watch.sh header." >&2
    exit 1
  fi
}
require_gnu_watch

sleep 2
watch -w -t -n0.1 "date '+%H:%M:%S' | figlet -w 140 -f big"

. /root/bin/_script_footer.sh
