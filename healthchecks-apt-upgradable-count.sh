#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS
# 2026.07.16 - v. 0.8 - rename from sprawdz-ile-apt-list--upgradable.sh; add -h/-v/--no_startup_delay
# 2026.07.15 - v. 0.7 - fix fail-path message quoting; comment crontab examples for bash -n
# 2026.05.26 - user-facing messages translated from Polish to English
# 2025.11.13 - v. 0.6 - added while loop (with little help of ChatGPT)
# 2023.10.14 - v. 0.5 - increased sleep delay from 100 to 600s
# 2023.01.03 - v. 0.4 - added random delay when script runs non-interactively
# 2022.06.15 - v. 0.3 - added wait when apt-get update runs concurrently in another process
# 2022.05.05 - v. 0.2 - added uptime and hostname
# 20xx.xx.xx - v. 0.1 - initial release (date unknown)
#
# healthchecks-apt-upgradable-count.sh
#
# Count apt upgradable packages; fail Healthchecks when count exceeds limit.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Count apt upgradable packages; fail Healthchecks when count exceeds limit.
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
if [ -f "$HEALTHCHECKS_FILE" ]; then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" | grep "^`basename $0`" | awk '{print $2}')
else
  HEALTHCHECK_URL=""
fi

check_if_installed curl

ile_max_by_nie_raportowac=45

###############################################################################
# Retry loop for apt-get update (instead of two attempts + sleep 600)
###############################################################################
blad=1
how_many_retries=20
retry_delay=60
return_code=999

while (( blad != 0 && how_many_retries != 0 )); do
    /usr/bin/apt-get update &>/dev/null
    return_code=$?

    if (( return_code == 0 )); then
        blad=0
        break
    else
        ((how_many_retries--))
        sleep "$retry_delay"
    fi
done

# If still failing → exit 2 and notify healthchecks
if (( blad != 0 )); then
    m=$( echo "${SCRIPT_VERSION}"; echo ; echo "apt update is running on another terminal and lock cannot be acquired, exiting" )
    /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "${m}" \
        -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
    exit 2
fi
###############################################################################

ile_jest_do_upgradeowania=$(/usr/bin/apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)

m=$( echo "${SCRIPT_VERSION}";echo
  echo ile_jest_do_upgradeowania = $ile_jest_do_upgradeowania
  echo ile_max_by_nie_raportowac = $ile_max_by_nie_raportowac
  echo "uptime: `uptime`"
  echo "hostname: `hostname`"
  /usr/bin/apt list --upgradable 2>&1 | egrep -v "WARNING: apt does not have a stable CLI interface. Use with caution in scripts.|Listing..."
)

if [ $ile_jest_do_upgradeowania -gt $ile_max_by_nie_raportowac ]; then
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" \
      -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" \
      -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit $?

#####
# new crontab entry
# @reboot ( sleep 60 && /root/bin/healthchecks-apt-upgradable-count.sh --no_startup_delay ) 2>&1
# 2 */6 * * * /root/bin/healthchecks-apt-upgradable-count.sh --no_startup_delay
