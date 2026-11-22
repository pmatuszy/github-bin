#!/bin/bash
# v. 20261122.202500 - also unset CALLER_SCRIPT* before screen (rename still re-execd reboot)
# v. 20261122.163000 - unset SCRIPT_SELF_* before screen so child shells do not inherit seal env
# v. 20260811.095711 - add --history (paged changelog via _script_header.sh print_script_history)
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2023.10.10 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(script_live_basename) [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (screen-after-the-reboot).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
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

. "${profile_location_dir:-$HOME}/bin/_script_header.sh" "${HEADER_EXTRA_ARGS[@]}"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --history) print_script_history; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $(script_live_basename) --help" >&2; exit 1 ;;
  esac
done

# Do not let seal env from this script poison bash inside screen (would make
# later tools e.g. rename.sh re-exec this script and reject their own flags).
unset SCRIPT_SELF_SEALED SCRIPT_SELF_LIVE_PATH SCRIPT_SELF_SEAL_TMP CALLER_SCRIPT CALLER_SCRIPT_BASENAME 2>/dev/null || true

$(type -fP screen) -c /root/bin/screen-after-the-reboot.rc
