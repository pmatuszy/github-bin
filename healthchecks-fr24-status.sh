#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS
#
# 2026.07.16 - v. 0.4 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2026.07.15 - v. 0.3 - fix inverted journal grep (match=activity); comment crontab examples for bash -n
# 2025.11.14 - v. 0.2 - added status from /usr/bin/fr24feed-status command output
# 2025.11.04 - v. 0.1 - initial release for monitoring fr24feed service
#
# healthchecks-fr24-status.sh
#
# Monitor fr24feed service and upload activity; report status to Healthchecks.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Check fr24feed service and recent upload activity; ping Healthchecks with exit code.
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

# --- read Healthchecks URL for this script name ---
HEALTHCHECK_URL=""
if [ -f "$HEALTHCHECKS_FILE" ]; then
  HEALTHCHECK_URL=$(grep "^$(basename $0)" "$HEALTHCHECKS_FILE" | awk '{print $2}')
fi

m=$( echo "${SCRIPT_VERSION}";echo
  echo
  echo ; 
  boxes <<< "/usr/bin/fr24feed-status" ; echo 
  /usr/bin/fr24feed-status
  echo ;

  echo ;
  boxes <<< "systemctl status fr24feed"  ; echo

  systemctl status fr24feed --no-pager -l | head -n 25
  echo

  # --- check if service is running ---
  if ! systemctl is-active --quiet fr24feed; then
    echo ". ERROR: fr24feed service is NOT running!"
    exit 1
  fi

# --- check for recent upload activity in logs ---
  # grep -q: 0 = match (activity found), nonzero = no match
  if journalctl -u fr24feed --since "60 minutes ago" 2>/dev/null | grep -qE "sent [0-9,]+ AC|ping|syncing stream"; then
    echo ". Detected upload activity in the last 60 minutes."
    exit 0
  else
    echo "..  WARNING: No upload activity detected in the last 60 minutes!"
    exit 2
  fi
)

return_code=$?

if [[ -n "${HEALTHCHECK_URL}" ]]; then
  /usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 \
    --data-raw "$m" -o /dev/null "${HEALTHCHECK_URL}/${return_code}" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit $return_code

#####
# new crontab entry (example — install with crontab -e, not as shell):
#
# @reboot ( sleep 3m ; /root/bin/healthchecks-fr24-status.sh --no_startup_delay >/dev/null 2>&1)
#
# 0 7-23 * * * /root/bin/healthchecks-fr24-status.sh --no_startup_delay
