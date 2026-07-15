#!/bin/bash

# 2026.07.15 - v. 0.8 - repo path: ${profile_location_dir:-$HOME}/github/github-bin
# 2026.07.15 - v. 0.7 - profile_location_dir from _script_header.sh
# 2026.07.15 - v. 0.6 - repo path: ${profile_location_dir}/github/github-bin
# 2026.07.15 - v. 0.5 - repo path: $HOME/github/github-bin (was /root/github-bin)
# 2026.06.02 - v. 0.4 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2026.06.02 - v. 0.3 - ping Healthchecks only when HEALTHCHECK_URL is set (avoid silent curl to empty URL)
# 2023.02.28 - v. 0.2 - curl with return_code
# 2023.02.17 - v. 0.1 - initial release

print_version_banner() {
  local ver=unknown date= line title verline width=60
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*) ]]; then
      date="${BASH_REMATCH[1]}"
      ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  title="$(basename "$0")"
  if [[ -n "$date" ]]; then
    verline="Version: ${ver} (${date})"
  else
    verline="Version: ${ver}"
  fi
  printf '┌%*s┐\n' "$width" '' | tr ' ' '─'
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$title"
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$verline"
  printf '└%*s┘\n' "$width" '' | tr ' ' '─'
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Cron wrapper: run ${profile_location_dir:-$HOME}/github/github-bin/git-push.sh batch, optionally report exit code
to Healthchecks (see healthchecks-ids.txt).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
EOF
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"
HEALTHCHECK_URL=""
if [[ -f "$HEALTHCHECKS_FILE" ]]; then
  HEALTHCHECK_URL=$(grep "^$(basename "$0")" "$HEALTHCHECKS_FILE" | awk '{print $2}')
fi

HC_message=$("${profile_location_dir:-$HOME}/github/github-bin/git-push.sh" batch 2>&1 ; exit $?)
return_code=$?

if (( script_is_run_interactively ));then
   echo "${HC_message}"
fi

if [[ -n "${HEALTHCHECK_URL:-}" ]]; then
  echo "$HC_message" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "${HEALTHCHECK_URL}/${return_code}" 2>/dev/null
fi

exit "${return_code}"

#####
# new crontab entry

2 7 * * * /root/bin/cron-git-bin-push.sh
