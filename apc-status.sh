#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.06.02 - v. 0.4 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2023.11.05 - v. 0.3 - dodano sprawdzanie, czy pakiet apcupsd jest zainstalowany
# 2023.01.16 - v. 0.2 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.09 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Report APC UPS status via apcaccess and ping Healthchecks (success/fail URL from
healthchecks-ids.txt when configured).

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

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

check_if_installed apcupsd

# spr. czy nie ma bledow
if [ $(/usr/bin/env apcaccess | egrep "STATUS   : ONLINE *$"|wc -l) -eq 0 ];then
  m=$( echo "${SCRIPT_VERSION}";echo ;/usr/bin/env apcaccess 2>&1)
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  m=$(echo "${SCRIPT_VERSION}";echo ; /usr/bin/env apcaccess 2>&1| egrep "STATUS   : ONLINE *")
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit $?


# wysylanie info o statusie APC ups'a
0 * * * *    /root/bin/apc-status.sh
