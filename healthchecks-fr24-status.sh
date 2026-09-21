#!/bin/bash
# v. 20260921.093458 - success from fr24feed-status (Process/Link/Receiver); journal is soft warning only
# v. 20260811.095711 - add --history (paged changelog via _script_header.sh print_script_history)
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS
#
# 2026.09.21 - v. 0.5 - Treat /usr/bin/fr24feed-status as the success signal: Feeder/Decoder
#                       Process running + Link connected + Receiver connected → Healthchecks OK.
#                       Recent journal "sent … AC" is only a soft warning now (it was failing
#                       checks even when fr24feed-status looked healthy).
# 2026.07.16 - v. 0.4 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2026.07.15 - v. 0.3 - fix inverted journal grep (match=activity); comment crontab examples for bash -n
# 2025.11.14 - v. 0.2 - added status from /usr/bin/fr24feed-status command output
# 2025.11.04 - v. 0.1 - initial release for monitoring fr24feed service
#
# healthchecks-fr24-status.sh
#
# Monitor fr24feed via fr24feed-status (+ systemd); report status to Healthchecks.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Check fr24feed health from /usr/bin/fr24feed-status and systemd; ping Healthchecks
with exit code. Lookup URL in healthchecks-ids.txt by script basename.

Success (exit 0) when all of these appear in fr24feed-status:
  * FR24 Feeder/Decoder Process: running
  * FR24 Link: connected …
  * Receiver: connected …

Journal "sent … AC" in the last 60 minutes is reported as a soft note only
(missing activity no longer fails the check when fr24feed-status looks healthy).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
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
    --history) print_script_history; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

# --- read Healthchecks URL for this script name ---
HEALTHCHECK_URL=""
if [ -f "$HEALTHCHECKS_FILE" ]; then
  HEALTHCHECK_URL=$(grep "^$(basename "$0")" "$HEALTHCHECKS_FILE" | awk '{print $2}')
fi

m=$(
  echo "${SCRIPT_VERSION}"
  echo
  echo
  boxes <<< "/usr/bin/fr24feed-status"
  echo
  fr24_status="$(/usr/bin/fr24feed-status 2>&1)" || true
  printf '%s\n' "$fr24_status"
  echo

  echo
  boxes <<< "systemctl status fr24feed"
  echo
  systemctl status fr24feed --no-pager -l 2>&1 | head -n 25
  echo

  # --- systemd unit must be active ---
  if ! systemctl is-active --quiet fr24feed; then
    echo ". ERROR: fr24feed service is NOT running (systemctl)!"
    exit 1
  fi
  echo ". systemctl: fr24feed is active."

  # --- authoritative health: fr24feed-status lines the operator cares about ---
  status_ok=1
  if ! grep -qiE 'FR24 Feeder/Decoder Process:[[:space:]]*running' <<<"$fr24_status"; then
    echo ". ERROR: Feeder/Decoder Process is not 'running' in fr24feed-status."
    status_ok=0
  else
    echo ". fr24feed-status: Feeder/Decoder Process: running"
  fi
  if ! grep -qiE 'FR24 Link:[[:space:]]*connected' <<<"$fr24_status"; then
    echo ". ERROR: FR24 Link is not 'connected' in fr24feed-status."
    status_ok=0
  else
    echo ". fr24feed-status: Link: connected"
  fi
  if ! grep -qiE 'Receiver:[[:space:]]*connected' <<<"$fr24_status"; then
    echo ". ERROR: Receiver is not 'connected' in fr24feed-status."
    status_ok=0
  else
    echo ". fr24feed-status: Receiver: connected"
  fi

  if (( status_ok == 0 )); then
    echo ". RESULT: FAIL (fr24feed-status unhealthy)"
    exit 1
  fi

  # Soft signal only — do not fail the Healthchecks ping when status looks good.
  # (Previously exit 2 here caused false failures despite a healthy fr24feed-status block.)
  if journalctl -u fr24feed --since "60 minutes ago" --no-pager 2>/dev/null \
       | grep -qE 'sent [0-9,]+ AC|ping|syncing stream'; then
    echo ". journal: upload activity seen in the last 60 minutes."
  else
    echo ".. NOTE: No journal upload activity matched in the last 60 minutes (soft; not a failure)."
  fi

  echo ". RESULT: OK (fr24feed-status healthy)"
  exit 0
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
