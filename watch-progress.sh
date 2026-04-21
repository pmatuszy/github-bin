#!/bin/bash

# 2026.04.21 - v. 0.9 - help text includes usage examples
# 2026.04.21 - v. 0.8 - -v / --version prints script version and date (before header)
# 2026.04.21 - v. 0.7 - -h / --help prints usage and exits (before header)
# 2026.04.21 - v. 0.6 - _script_header/footer, check_if_installed progress; extra commands via WATCH_PROGRESS_EXTRA, WATCH_PROGRESS_WAIT_DELAY, or args
# 2022.11.14 - v. 0.5 - dodalem pbzip2 do monitorowanych komend
# 2022.09.05 - v. 0.4 - dodalem mc do monitorowanych komend
# 2022.06.08 - v. 0.3 - dodalem par2 do monitorowanych komend
# 2021.11.04 - v. 0.2 - zmiana watch na "progress -M"
# 2021.09.19 - v. 0.1 - inicjalna wersja skryptu

if [[ "${1:-}" == -h || "${1:-}" == --help ]]; then
  cat <<'EOF'
Usage: watch-progress.sh [-h|--help|-v|--version] [PROCESS...]

Runs progress(1) with --monitor-continuously, --wait, and extra
--additional-command names for common backup/compression tools.

Options:
  -h, --help       Show this help and exit.
  -v, --version    Print script version and exit.

Environment:
  WATCH_PROGRESS_EXTRA       Space-separated extra process basenames to monitor.
  WATCH_PROGRESS_WAIT_DELAY  Poll interval in seconds (default: 0.5).

Arguments:
  Each PROCESS is a process basename (as in ps) added via --additional-command.

Built-in extras include: pbzip2, par2, restic, mc, rclone, zstd, pigz, xz, borg, lz4.

Examples:
  watch-progress.sh
      Defaults only; leave running in a screen window while you run backups elsewhere.

  watch-progress.sh gpg 7zz
      Also watch processes whose ps basename is gpg or 7zz.

  WATCH_PROGRESS_EXTRA="ffmpeg openssl" watch-progress.sh
      Add more basenames without changing the script (space-separated).

  WATCH_PROGRESS_WAIT_DELAY=1 watch-progress.sh
      Poll once per second instead of every 0.5 s.

  WATCH_PROGRESS_EXTRA="ffmpeg" watch-progress.sh openssl
      Env extras plus extra PROCESS names on one line (all get --additional-command).
EOF
  exit 0
fi

if [[ "${1:-}" == -v || "${1:-}" == --version ]]; then
  _wp_ver=unknown
  _wp_date=
  while IFS= read -r _wp_line; do
    if [[ "$_wp_line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*)\ - ]]; then
      _wp_date="${BASH_REMATCH[1]}"
      _wp_ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  if [[ -n "$_wp_date" ]]; then
    printf '%s version %s (%s)\n' "$(basename "$0")" "$_wp_ver" "$_wp_date"
  else
    printf '%s version %s\n' "$(basename "$0")" "$_wp_ver"
  fi
  exit 0
fi

. /root/bin/_script_header.sh

check_if_installed progress

# Process basenames (as in ps) to pass to progress --additional-command.
DEFAULT_CMDS=(pbzip2 par2 restic mc rclone zstd pigz xz borg lz4)

env_extra=()
if [[ -n "${WATCH_PROGRESS_EXTRA:-}" ]]; then
  read -r -a env_extra <<< "${WATCH_PROGRESS_EXTRA}"
fi

declare -A _wp_seen=()
_wp_add() {
  local c="$1"
  [[ -z "$c" ]] && return
  [[ -n "${_wp_seen[$c]:-}" ]] && return
  _wp_seen[$c]=1
  WP_PROGRESS_ARGS+=(--additional-command "$c")
}

WP_PROGRESS_ARGS=()
for c in "${DEFAULT_CMDS[@]}"; do _wp_add "$c"; done
for c in "${env_extra[@]}"; do _wp_add "$c"; done
for c in "$@"; do _wp_add "$c"; done

wait_delay="${WATCH_PROGRESS_WAIT_DELAY:-0.5}"

progress --monitor-continuously "${WP_PROGRESS_ARGS[@]}" --wait --wait-delay "$wait_delay"
kod_powrotu=$?

. /root/bin/_script_footer.sh

exit "${kod_powrotu}"
