#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.04.22 - v. 0.3 - nullglob, root and scan-file checks, set -euo pipefail, exit status on failure
# 2026.04.21 - v. 0.2 - add script history header and fix SCSI rescan write payload
# 2023.01.14 - v. 0.1 - initial release
#
# Writes "- - -" to each host's scan sysfs knob (wildcard channel, id, LUN).
# For richer rescans (multipath, IDs), see sg3-utils: rescan-scsi-bus.sh

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Writes "- - -" to each host's scan sysfs knob (wildcard channel, id, LUN).

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

set -euo pipefail
shopt -s nullglob

if (( EUID != 0 )); then
  echo "$(basename "$0"): must run as root (writes to /sys/class/scsi_host/*/scan)." >&2
  exit 1
fi

hosts=( /sys/class/scsi_host/host* )
if ((${#hosts[@]} == 0)); then
  echo "$(basename "$0"): no /sys/class/scsi_host/host* entries (no SCSI HBAs?)." >&2
  exit 1
fi

failed=0
for p in "${hosts[@]}"; do
  if [[ ! -e "$p/scan" ]]; then
    echo "$(basename "$0"): skip (no scan knob): $p" >&2
    continue
  fi
  if [[ ! -w "$p/scan" ]]; then
    echo "$(basename "$0"): not writable: $p/scan" >&2
    ((++failed)) || true
    continue
  fi
  echo "scan: $p"
  echo '- - -' >"$p/scan" || { echo "$(basename "$0"): write failed: $p/scan" >&2; ((++failed)) || true; }
done

if (( failed > 0 )); then
  echo "$(basename "$0"): finished with $failed error(s)." >&2
  exit 1
fi
