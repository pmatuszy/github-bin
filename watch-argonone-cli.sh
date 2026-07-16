#!/bin/bash
# v. 20260716.164400 - add -h/-v/--no_startup_delay; check argonone-cli after CLI parse

# 2026.07.16 - v. 0.3 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2023.04.13 - v. 0.2 - added check if argonone-cli is installed
# 2021.09.19 - v. 0.1 - inicjalna wersja skryptu
#
# watch-argonone-cli.sh
#
# Live refresh of argonone-cli --decode (Argon ONE case fan/temp on Raspberry Pi).
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Run watch(1) on argonone-cli --decode (Argon ONE fan/temperature status).
Requires argonone-cli (Raspberry Pi with Argon ONE case).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay when run non-interactively.
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

check_if_installed argonone-cli

watch_temp_cleanup() {
  . /root/bin/_script_footer.sh
}
trap watch_temp_cleanup EXIT

watch -n 0.2 argonone-cli --decode
