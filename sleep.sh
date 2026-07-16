#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.04.21 - v. 0.4 - prefer pm-suspend first and use systemctl suspend only as fallback
# 2026.04.20 - v. 0.3 - added _script_header.sh and _script_footer.sh integration
# 2026.04.20 - v. 0.2 - style update to match other scripts in this directory
# 2026.04.20 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (sleep).

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

return_code=1

if type -fP pm-suspend 2>&1 >/dev/null; then
  pm-suspend
  return_code=$?
elif type -fP systemctl 2>&1 >/dev/null; then
  systemctl suspend
  return_code=$?
else
  echo
  echo "(PGM) I can't find systemctl or pm-suspend utility... exiting ..."
  echo
  return_code=1
fi

. /root/bin/_script_footer.sh

exit ${return_code}
