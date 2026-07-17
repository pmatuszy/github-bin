#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS
# 2026.07.16 - v. 0.3 - rename from sprawdz-czy-dziala-server-vpn.sh; add -h/-v/--no_startup_delay
# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.01.03 - v. 0.2 - added random delay when script runs non-interactively
# 20xx.xx.xx - v. 0.1 - initial release (date unknown)
#
# healthchecks-vpn-server-is-running.sh
#
# Check vpnserver process; ping Healthchecks fail when VPN is down.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Check vpnserver process; ping Healthchecks fail when VPN is down.
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

# spr. czy dziala vpn
if [ `ps -ef|grep vpnserver | awk '{print $8}'|grep -v grep|uniq|wc -l` -eq 0 ];then 
#  (echo "vpn on `hostname` is DOWN" | mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`/bin/hostname`-`date '+\%Y.\%m.\%d \%H:\%M:\%S'`) vpn is down" matuszyk+`/bin/hostname`@matuszyk.com)
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

exit $?

#####
# new crontab entry

*/3 * * * * /root/bin/healthchecks-vpn-server-is-running.sh --no_startup_delay

# old crontab entry
# spr. czy dziala vpn
#5 */6 * * * if [ `ps -ef|grep vpnserver | awk '{print $8}'|grep -v grep|uniq|wc -l` -eq 0 ];then (echo "vpn on `hostname` is DOWN" | mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`/bin/hostname`-`date '+\%Y.\%m.\%d \%H:\%M:\%S'`) vpn is down" matuszyk+`/bin/hostname`@matuszyk.com) ; fi
