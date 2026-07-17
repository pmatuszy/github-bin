#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.07.16 - v. 0.4 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.01.16 - v. 0.3 - better service restart failure detection, redirection of 2> on 1>
# 2023.01.03 - v. 0.2 - added random delay when script runs non-interactively
# 2022.05.18 - v. 0.1 - initial release
#
# healthchecks-smartd.sh
#
# Restart smartd and report service status to Healthchecks.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Restart smartd and report status to Healthchecks (fail on errors).
Lookup URL in healthchecks-ids.txt by script basename.

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

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

m=$( echo "${SCRIPT_VERSION}";echo ;
     cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo
     systemctl restart smartd --no-pager 2>&1
     return_code=$?
     sleep 5 ; echo ; echo "STATUS AFTER SERVICE RESTART: " ; echo
     systemctl status smartd --no-pager ; echo ; exit $return_code )
wynik_po_restarcie=$?

wiadomosc=""
if (( $(echo "$m" |grep -i "error" | wc -l) > 0 )) || (( $wynik_po_restarcie != 0 )) ;then
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit $?

######
# template crontab entry:

# @reboot ( sleep 45 && /root/bin/healthchecks-smartd.sh --no_startup_delay) 2>&1

# 0 18 * * *  /root/bin/healthchecks-smartd.sh --no_startup_delay
