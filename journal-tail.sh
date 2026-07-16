#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2023.01.24 - v. 0.3 - grep changed to a regexp instead of hardcoded 2022
# 2022.12.02 - v. 0.2 - better detection of journalctl binary location with type
# 2022.11.25 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

-f --follow                Follow the journal

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

echo ; cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo

figlet -w 120 logs from systemd
sleep 1.5s

export JOURNALCTL_BIN=$(type -fP journalctl )

${JOURNALCTL_BIN} -fan500

#  -f --follow                Follow the journal
#  -a --all                   Show all fields, including long and unprintable
#  -n --lines[=INTEGER]       Number of journal entries to show

