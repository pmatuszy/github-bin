#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.04.06 - v. 0.3 - excluding temp dir /podsync-hdd/_temp/
# 2021.02.07 - v. 0.2 - spr. czy nie ma wiecej dzialajacych instancji skryptu....
# 2020.xx.xx - v. 0.1 - initial release

# 2021-01-21: 2>/dev/null on each find to avoid cron mails about missing files

# if more than one instance is running, exit
show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

2021-01-21: 2>/dev/null on each find to avoid cron mails about missing files

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

if [[ `ps -e|grep $0` -gt 1 ]]; then
  exit 2
fi

find /podsync-hdd/ -type f ! -group www-data -regex '.*\.\(mp3\|mp4\|webm\|xml\|m4a\)' -exec chgrp -v www-data {} \; 2>/dev/null
find /podsync-hdd/ -type f ! -perm 640       -regex '.*\.\(mp3\|mp4\|webm\|xml\|m4a\)' -exec chmod -v 640 {} \;      2>/dev/null
find /podsync-hdd/ -type d ! -wholename \*_temp\* ! -perm 750       -exec chmod 750 -v {} \;                         2>/dev/null
find /podsync-hdd/ -type d ! -wholename \*_temp\* ! -group www-data -exec chgrp www-data -v {} \;                    2>/dev/null


exit 

#### cron entry ####
* * * * *     ( /usr/bin/flock --nonblock --exclusive /root/bin/zmien-uprawnienia-podsync-hdd.sh -c /root/bin/zmien-uprawnienia-podsync-hdd.sh ) 2>&1 > /dev/null

