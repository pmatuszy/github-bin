#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.06.02 - v. 0.3 - inline print_version_banner (no _script_cli.sh)
# 2026.06.02 - v. 0.2 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2026.06.02 - v. 0.1 - proper script: header, stress-ng check, optional duration (arg1 or STRESS_SECONDS); runs all CPUs until timeout or Ctrl-C
# (was two bare lines: apt install + stress-ng — not safe for cron/copy-paste)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay] [DURATION_SEC]

Run stress-ng on all CPU cores until Ctrl-C or for DURATION_SEC seconds.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay when run non-interactively
                       (see _script_header.sh).

Arguments / environment:
  DURATION_SEC         Optional duration in seconds (positional \$1).
  STRESS_SECONDS       Same as DURATION_SEC if no positional argument is given.
EOF
}

HEADER_EXTRA_ARGS=()
DURATION_CLI=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      print_version_banner
      exit 0
      ;;
    -*)
      echo "Unknown option: $1 (try --help)" >&2
      exit 1
      ;;
    *)
      if [[ -n "$DURATION_CLI" ]]; then
        echo "Only one duration argument allowed (try --help)." >&2
        exit 1
      fi
      DURATION_CLI=$1
      shift
      ;;
  esac
done

check_if_installed stress-ng

DURATION="${DURATION_CLI:-${STRESS_SECONDS:-}}"
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
return_code=$?

. /root/bin/_script_footer.sh
exit "${return_code}"
