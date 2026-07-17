#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2023.04.11 - v. 0.4 - added invocation of _script_header.sh and _script_footer.sh
# 2023.02.17 - v. 0.3 - added yt_bin variable
# 2022.12.15 - v. 0.2 - bugfix - changed ls -l to point to the proper directory
# 2022.12.14 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

yt_bin=/snap/youtube-dl/current/bin/youtube-dl

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

export url="https://www.youtube.com/watch?v=e2gC37ILQmk"
export DEST_PREFIX="/worek-samba/nagrania/Kijow-webcamy"

delay_between_runs=60s
file_owner="che:che"

yt_bin=/usr/local/bin/youtube-dl
# yt_bin=/snap/youtube-dl/current/bin/youtube-dl

while : ; do 
  output_filename="Kijow-livecam_$(date '+%Y%m%d_%H%M%S').mp4"
  "${yt_bin}" --ignore-errors --no-part --output "${DEST_PREFIX}/${output_filename}" "$url" 
  chown "${file_owner}" "${DEST_PREFIX}/${output_filename}" 2>/dev/null
#  (echo "koniec wykonywania $0" && ls -lr "${DEST_PREFIX}") | strings | aha | \
#      mailx -r root@`hostname` -a 'Content-Type: text/html' -s "$0 (`/bin/hostname`-`date '+%Y.%m.%d %H:%M:%S'`)" matuszyk@matuszyk.com
  sleep ${delay_between_runs}
done

. /root/bin/_script_footer.sh
