#!/bin/bash

# 2026.06.02 - v. 0.1 - proper script: header, stress-ng check, optional duration (arg1 or STRESS_SECONDS); runs all CPUs until timeout or Ctrl-C
# (was two bare lines: apt install + stress-ng — not safe for cron/copy-paste)

. /root/bin/_script_header.sh

check_if_installed stress-ng

DURATION="${1:-${STRESS_SECONDS:-}}"
STRESS_EXTRA=(--cpu 0 --cpu-method fft)

if [[ -n "$DURATION" ]]; then
  if [[ ! "$DURATION" =~ ^[0-9]+$ ]]; then
    echo "ERROR: duration must be a positive integer (seconds); got: $DURATION"
    exit 2
  fi
  echo "CPU stress on all cores for ${DURATION}s (Ctrl-C to stop early)..."
  stress-ng "${STRESS_EXTRA[@]}" --timeout "${DURATION}s"
else
  echo "CPU stress on all cores until Ctrl-C (pass duration in seconds as \$1 or set STRESS_SECONDS)..."
  stress-ng "${STRESS_EXTRA[@]}"
fi
kod_powrotu=$?

. /root/bin/_script_footer.sh
exit "${kod_powrotu}"
