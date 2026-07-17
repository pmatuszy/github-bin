#!/bin/bash
# v. 20260716.164400 - -v via _script_header.sh print_version_banner; standard CLI parse

# 2026.04.21 - v. 0.9 - help text includes usage examples
# 2026.04.21 - v. 0.8 - -v / --version prints script version and date (before header)
# 2026.04.21 - v. 0.7 - -h / --help prints usage and exits (before header)
# 2026.04.21 - v. 0.6 - _script_header/footer, check_if_installed progress; extra commands via WATCH_PROGRESS_EXTRA, WATCH_PROGRESS_WAIT_DELAY, or args
# 2022.11.14 - v. 0.5 - added pbzip2 to monitored commands
# 2022.09.05 - v. 0.4 - added mc to monitored commands
# 2022.06.08 - v. 0.3 - added par2 to monitored commands
# 2021.11.04 - v. 0.2 - switched watch to progress -M
# 2021.09.19 - v. 0.1 - inicjalna wersja skryptu
#
# watch-progress.sh
#
# Monitor backup/compression tools via progress(1) --monitor-continuously.
#

show_help() {
  cat <<'EOF'
Usage: watch-progress.sh [-h|--help] [-v|--version] [--no_startup_delay] [PROCESS...]

Runs progress(1) with --monitor-continuously, --wait, and extra
--additional-command names for common backup/compression tools.

Options:
  -h, --help       Show this help and exit.
  -v, --version    Print script version and exit.
  --no_startup_delay
                   Skip random startup delay when run non-interactively.

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
}

HEADER_EXTRA_ARGS=()
CLI_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      . /root/bin/_script_header.sh NO_STARTUP_DELAY
      print_version_banner
      exit 0
      ;;
    --) shift; CLI_ARGS+=("$@"); break ;;
    -*) echo "Unknown option: $1 (try --help)" >&2; exit 1 ;;
    *) CLI_ARGS+=("$1"); shift ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

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
for c in "${CLI_ARGS[@]}"; do _wp_add "$c"; done

wait_delay="${WATCH_PROGRESS_WAIT_DELAY:-0.5}"

progress --monitor-continuously "${WP_PROGRESS_ARGS[@]}" --wait --wait-delay "$wait_delay"
return_code=$?

. /root/bin/_script_footer.sh

exit "${return_code}"
