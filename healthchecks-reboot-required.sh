#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS
# 2026.07.16 - v. 0.4 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2026.07.16 - v. 0.3 - rename from sprawdz-czy-reboot-required.sh; Healthchecks ping for /var/run/reboot-required
# 2023.01.09 - v. 0.2 - small changes (along with the random delay) and a new crontab entry after the reboot
# 2022.11.03 - v. 0.1 - initial release (date unknown)
#
# healthchecks-reboot-required.sh
#
# Ping Healthchecks: fail when /var/run/reboot-required exists, else success.
# Lookup URL in healthchecks-ids.txt by script basename.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Ping Healthchecks for pending reboot (/var/run/reboot-required).
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

HEALTHCHECK_URL=""
if [[ -f "$HEALTHCHECKS_FILE" ]]; then
  HEALTHCHECK_URL=$(grep "^$(basename "$0")" "$HEALTHCHECKS_FILE" | awk '{print $2}')
fi

if [[ -f /var/run/reboot-required ]]; then
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "${HEALTHCHECK_URL}/fail" 2>/dev/null
else
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "${HEALTHCHECK_URL}" 2>/dev/null
fi

exit $?

#####
# new crontab entry

# @reboot ( /root/bin/healthchecks-reboot-required.sh --no_startup_delay ) 2>&1

# 0 7-22 * * * /root/bin/healthchecks-reboot-required.sh --no_startup_delay
