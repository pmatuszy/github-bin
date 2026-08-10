#!/bin/bash
# v. 20260810.115956 - fix bash (( )) + =~ error; robust rsync stats byte parsing
# v. 20260806.172432 - transfer plan and result timing; dual MiB/MB GiB/GB TiB/TB size display
# v. 20260725.182831 - boxed SUCCESS/FAILURE summary; remove empty source dirs after verified move
# v. 20260724.203756 - avoid startup delay when displaying help or version information
# v. 20260724.203704 - initial network move with uncompressed SSH, source removal, and dry-run support

# 2026.08.10 - v. 0.3.1 - fix result size fallback test; parse rsync stats numbers reliably
# 2026.08.06 - v. 0.3 - preflight transfer plan (files, size, ETA); timing and rate in result box
# 2026.07.25 - v. 0.2 - print boxed result summary; verify source has no files and remove empty dirs
# 2026.07.24 - v. 0.1 - initial release
#
# move-pgm-rsync.sh
#
# Move files over SSH with rsync, disabling compression and removing transferred source files.
#

MOVE_PGM_HAVE_BOXES=no
if type -fP boxes &>/dev/null; then
  MOVE_PGM_HAVE_BOXES=yes
fi

MOVE_PGM_SSH_OPTS=(-o Compression=no -x -o LogLevel=error)
MOVE_PGM_RSYNC_STATS_FILE=
MOVE_PGM_PLAN_FILES=
MOVE_PGM_PLAN_BYTES=
MOVE_PGM_ACTUAL_BYTES=
MOVE_PGM_ACTUAL_FILES=
MOVE_PGM_ACTUAL_RATE_BPS=
MOVE_PGM_START_STR=
MOVE_PGM_END_STR=
MOVE_PGM_RUN_START=0
MOVE_PGM_PREFLIGHT_SEC=0
MOVE_PGM_TRANSFER_SEC=0
MOVE_PGM_CLEANUP_SEC=0

move_pgm_wall_clock_now() {
  date '+%Y.%m.%d %H:%M:%S'
}

move_pgm_format_elapsed() {
  local s="${1:-0}" h m
  (( s < 0 )) && s=0
  h=$(( s / 3600 ))
  m=$(( (s % 3600) / 60 ))
  s=$(( s % 60 ))
  if (( h > 0 )); then
    printf '%dh %dm %ds' "$h" "$m" "$s"
  elif (( m > 0 )); then
    printf '%dm %ds' "$m" "$s"
  else
    printf '%ds' "$s"
  fi
}

# Bytes with comma grouping; MiB/MB, GiB/GB, TiB/TB (binary / decimal pairs).
move_pgm_format_bytes() {
  local bytes="${1:-0}"
  [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0
  awk -v b="$bytes" '
  function comma(n,    s, len, out, i, c) {
    s = sprintf("%.0f", n)
    len = length(s)
    out = ""
    for (i = 1; i <= len; i++) {
      c = substr(s, i, 1)
      if (i > 1 && (len - i) % 3 == 0) out = out ","
      out = out c
    }
    return out
  }
  BEGIN {
  printf "%s bytes", comma(b)
  if (b >= 1024 && b < 1048576)
    printf " | %.2f KiB / %.2f KB", b / 1024, b / 1000
  if (b >= 1048576 && b < 1073741824)
    printf " | %.2f MiB / %.2f MB", b / 1048576, b / 1000000
  if (b >= 1073741824 && b < 1099511627776)
    printf " | %.2f MiB / %.2f MB | %.2f GiB / %.2f GB", \
      b / 1048576, b / 1000000, b / 1073741824, b / 1e9
  if (b >= 1099511627776)
    printf " | %.2f GiB / %.2f GB | %.2f TiB / %.2f TB", \
      b / 1073741824, b / 1e9, b / 1099511627776, b / 1e12
  }'
}

# rsync --bwlimit: numeric value is KiB/s; optional k/m/g suffix (1024-based).
move_pgm_bwlimit_to_bytes_per_sec() {
  local limit="${1,,}" n=0 mult=1024

  [[ -n "$limit" ]] || return 1
  if [[ "$limit" =~ ^([0-9]+)([kmg])?$ ]]; then
    n="${BASH_REMATCH[1]}"
    case "${BASH_REMATCH[2]:-}" in
      k) mult=$((1024 * 1024)) ;;
      m) mult=$((1024 * 1024 * 1024)) ;;
      g) mult=$((1024 * 1024 * 1024 * 1024)) ;;
    esac
    echo $(( n * mult ))
    return 0
  fi
  return 1
}

move_pgm_format_rate() {
  local bps="${1:-0}"
  [[ "$bps" =~ ^[0-9]+$ ]] || bps=0
  awk -v r="$bps" 'BEGIN {
    if (r <= 0) { print "n/a"; exit }
    printf "%.2f MiB/s / %.2f MB/s", r / 1048576, r / 1e6
  }'
}

move_pgm_parse_rsync_stats_text() {
  local text="$1"
  local var_prefix="${2:-MOVE_PGM_STAT}"

  printf -v "${var_prefix}_FILES" '%s' "$(
    awk '/^Number of regular files transferred:/{gsub(/,/,"",$6); print $6; exit}
         /^Number of files:/{gsub(/,/,"",$4); print $4; exit}' <<< "$text"
  )"
  printf -v "${var_prefix}_TOTAL_BYTES" '%s' "$(
    awk '/^Total file size:/{
      for (i = 1; i <= NF; i++)
        if ($i ~ /^[0-9][0-9,]*$/) { gsub(/,/, "", $i); print $i; exit }
    }' <<< "$text"
  )"
  printf -v "${var_prefix}_TRANSFERRED_BYTES" '%s' "$(
    awk '/^Total transferred file size:/{
      for (i = 1; i <= NF; i++)
        if ($i ~ /^[0-9][0-9,]*$/) { gsub(/,/, "", $i); print $i; exit }
    }' <<< "$text"
  )"
  printf -v "${var_prefix}_BYTES_PER_SEC" '%s' "$(
    awk '/^sent / {
      for (i = 1; i <= NF; i++)
        if ($i == "bytes/sec" && i > 1) {
          gsub(/,/, "", $(i - 1))
          print $(i - 1)
          exit
        }
    }' <<< "$text"
  )"
}

move_pgm_parse_rsync_stats_file() {
  local file="$1"
  local var_prefix="${2:-MOVE_PGM_STAT}"
  local text=""

  [[ -r "$file" ]] || return 1
  text="$(<"$file")"
  move_pgm_parse_rsync_stats_text "$text" "$var_prefix"
}

move_pgm_measure_local_file_source() {
  move_pgm_parse_rsync_spec "$SOURCE"
  if [[ "$MOVE_PGM_SPEC_KIND" != local || ! -f "$MOVE_PGM_SPEC_PATH" ]]; then
    return 1
  fi
  MOVE_PGM_PLAN_BYTES="$(stat -c%s "$MOVE_PGM_SPEC_PATH" 2>/dev/null || echo 0)"
  MOVE_PGM_PLAN_FILES=1
  return 0
}

move_pgm_run_transfer_preflight() {
  local -a preflight_args=(
    -a
    --dry-run
    --stats
    --no-inc-recursive
    -e "ssh -o Compression=no -x"
  )
  local preflight_out="" lap_start=$SECONDS

  if move_pgm_measure_local_file_source; then
    MOVE_PGM_PREFLIGHT_SEC=$(( SECONDS - lap_start ))
    return 0
  fi

  if [[ -n "$BWLIMIT" ]]; then
    preflight_args+=(--bwlimit="$BWLIMIT")
  fi

  preflight_out="$(rsync "${preflight_args[@]}" "$SOURCE" "$DESTINATION" 2>&1)" || return 1
  move_pgm_parse_rsync_stats_text "$preflight_out" MOVE_PGM_PLAN
  MOVE_PGM_PLAN_FILES="${MOVE_PGM_PLAN_FILES:-}"
  MOVE_PGM_PLAN_BYTES="${MOVE_PGM_PLAN_TOTAL_BYTES:-0}"
  MOVE_PGM_PREFLIGHT_SEC=$(( SECONDS - lap_start ))
  [[ "$MOVE_PGM_PLAN_BYTES" =~ ^[0-9]+$ ]] || MOVE_PGM_PLAN_BYTES=0
  [[ "$MOVE_PGM_PLAN_FILES" =~ ^[0-9]+$ ]] || MOVE_PGM_PLAN_FILES=0
  return 0
}

move_pgm_print_transfer_plan() {
  local -a lines=()
  local eta_sec=0 bps=0 eta_human=""

  lines=(
    "*** TRANSFER PLAN ***"
    "SOURCE: ${SOURCE}"
    "DESTINATION: ${DESTINATION}"
    "Started: ${MOVE_PGM_START_STR}"
  )

  if [[ "${MOVE_PGM_PLAN_FILES:-}" =~ ^[0-9]+$ ]]; then
    lines+=("Files: ${MOVE_PGM_PLAN_FILES}")
  fi
  if [[ "${MOVE_PGM_PLAN_BYTES:-}" =~ ^[0-9]+$ ]]; then
    lines+=("Size: $(move_pgm_format_bytes "$MOVE_PGM_PLAN_BYTES")")
  else
    lines+=("Size: could not determine (preflight failed)")
  fi

  if (( MOVE_PGM_PREFLIGHT_SEC > 0 )); then
    lines+=("Size scan: $(move_pgm_format_elapsed "$MOVE_PGM_PREFLIGHT_SEC")")
  fi

  if [[ -n "$BWLIMIT" && "${MOVE_PGM_PLAN_BYTES:-0}" =~ ^[0-9]+$ && "$MOVE_PGM_PLAN_BYTES" -gt 0 ]]; then
    if bps="$(move_pgm_bwlimit_to_bytes_per_sec "$BWLIMIT")"; then
      eta_sec=$(( (MOVE_PGM_PLAN_BYTES + bps - 1) / bps ))
      eta_human="$(move_pgm_format_elapsed "$eta_sec")"
      lines+=("Est. transfer: ~${eta_human} (bwlimit=${BWLIMIT})")
    fi
  fi

  echo
  move_pgm_emit_boxed_block stone "${lines[@]}"
  echo
}

move_pgm_cleanup_temp_files() {
  [[ -n "$MOVE_PGM_RSYNC_STATS_FILE" && -f "$MOVE_PGM_RSYNC_STATS_FILE" ]] \
    && rm -f "$MOVE_PGM_RSYNC_STATS_FILE"
}

move_pgm_emit_unicode_box() {
  local -a lines=( "$@" )
  local max_len=0 line w

  for line in "${lines[@]}"; do
    (( ${#line} > max_len )) && max_len=${#line}
  done
  (( max_len < 52 )) && max_len=52
  w=$(( max_len + 2 ))

  printf '┌%*s┐\n' "$w" '' | tr ' ' '─'
  for line in "${lines[@]}"; do
    printf '│ %-*s │\n' "$max_len" "$line"
  done
  printf '└%*s┘\n' "$w" '' | tr ' ' '─'
}

move_pgm_emit_boxed_block() {
  local design="$1"
  shift
  local -a lines=( "$@" )

  if [[ "$MOVE_PGM_HAVE_BOXES" == yes ]]; then
    printf '%s\n' "${lines[@]}" | boxes -a c -d "$design"
  else
    move_pgm_emit_unicode_box "${lines[@]}"
  fi
}

# [user@]host:/path is remote; otherwise local (rsync rules).
move_pgm_parse_rsync_spec() {
  local spec="$1"
  MOVE_PGM_SPEC_KIND=local
  MOVE_PGM_SPEC_SSH_TARGET=
  MOVE_PGM_SPEC_PATH="$spec"

  if [[ "$spec" == *:* && "$spec" != /* ]]; then
    MOVE_PGM_SPEC_KIND=remote
    MOVE_PGM_SPEC_SSH_TARGET="${spec%%:*}"
    MOVE_PGM_SPEC_PATH="${spec#*:}"
  fi

  MOVE_PGM_SPEC_PATH="${MOVE_PGM_SPEC_PATH%/}"
}

move_pgm_shell_quote() {
  local s=${1//\'/\'\\\'\'}
  printf "'%s'" "$s"
}

move_pgm_source_is_directory() {
  case "$MOVE_PGM_SPEC_KIND" in
    local)
      [[ -d "$MOVE_PGM_SPEC_PATH" ]]
      ;;
    remote)
      ssh "${MOVE_PGM_SSH_OPTS[@]}" "$MOVE_PGM_SPEC_SSH_TARGET" \
        "test -d $(move_pgm_shell_quote "$MOVE_PGM_SPEC_PATH")"
      ;;
  esac
}

move_pgm_count_source_files() {
  case "$MOVE_PGM_SPEC_KIND" in
    local)
      find "$MOVE_PGM_SPEC_PATH" -type f 2>/dev/null | wc -l | tr -d ' '
      ;;
    remote)
      ssh "${MOVE_PGM_SSH_OPTS[@]}" "$MOVE_PGM_SPEC_SSH_TARGET" \
        "find $(move_pgm_shell_quote "$MOVE_PGM_SPEC_PATH") -type f 2>/dev/null | wc -l" \
        | tr -d ' '
      ;;
  esac
}

move_pgm_remove_empty_source_dirs() {
  case "$MOVE_PGM_SPEC_KIND" in
    local)
      find "$MOVE_PGM_SPEC_PATH" -depth -type d -empty -print -delete 2>/dev/null \
        | wc -l | tr -d ' '
      ;;
    remote)
      ssh "${MOVE_PGM_SSH_OPTS[@]}" "$MOVE_PGM_SPEC_SSH_TARGET" \
        "find $(move_pgm_shell_quote "$MOVE_PGM_SPEC_PATH") -depth -type d -empty -print -delete 2>/dev/null | wc -l" \
        | tr -d ' '
      ;;
  esac
}

# After a successful rsync move, confirm the source tree has no files and remove empty dirs.
# Sets MOVE_PGM_CLEANUP_SUMMARY for the final result box.
move_pgm_cleanup_source_directories() {
  local remaining="" removed=""

  MOVE_PGM_CLEANUP_SUMMARY="Source cleanup: not applicable (source is not a directory)."

  move_pgm_parse_rsync_spec "$SOURCE"
  if ! move_pgm_source_is_directory; then
    return 0
  fi

  if (( DRY_RUN == 1 )); then
    MOVE_PGM_CLEANUP_SUMMARY="Source cleanup: would verify ${SOURCE} has no files and remove empty directories after transfer (dry-run)."
    return 0
  fi

  remaining="$(move_pgm_count_source_files)"
  [[ "$remaining" =~ ^[0-9]+$ ]] || remaining=-1

  if (( remaining < 0 )); then
    MOVE_PGM_CLEANUP_SUMMARY="Source cleanup: could not verify files under ${SOURCE}."
    return 1
  fi

  if (( remaining > 0 )); then
    MOVE_PGM_CLEANUP_SUMMARY="Source cleanup: ${remaining} file(s) still under ${SOURCE} — directories kept."
    return 1
  fi

  removed="$(move_pgm_remove_empty_source_dirs)"
  [[ "$removed" =~ ^[0-9]+$ ]] || removed=0
  MOVE_PGM_CLEANUP_SUMMARY="Source cleanup: no files left; removed ${removed} empty dir(s) under ${SOURCE}."
  return 0
}

move_pgm_print_result() {
  local rsync_rc="$1"
  local exit_rc="$2"
  local -a lines=()
  local design=stone
  local total_sec=0 transferred_bytes=0 rate_line=""

  total_sec=$(( SECONDS - MOVE_PGM_RUN_START ))
  MOVE_PGM_END_STR="$(move_pgm_wall_clock_now)"

  echo
  if (( exit_rc == 0 )); then
    lines=(
      "*** RESULT: SUCCESS ***"
      "Return code: ${exit_rc}"
      "Move completed successfully."
    )
    design=ada-box
  elif (( rsync_rc == 0 )); then
    lines=(
      "*** RESULT: FAILURE ***"
      "Return code: ${exit_rc}"
      "Transfer finished (rsync=${rsync_rc}) but source cleanup failed."
    )
    design=stone
  else
    lines=(
      "*** RESULT: FAILURE ***"
      "Return code: ${exit_rc}"
      "Move did not complete successfully (rsync=${rsync_rc})."
    )
    design=stone
  fi

  transferred_bytes="${MOVE_PGM_ACTUAL_BYTES:-0}"
  [[ "$transferred_bytes" =~ ^[0-9]+$ ]] || transferred_bytes=0
  if (( transferred_bytes == 0 )) && [[ "${MOVE_PGM_PLAN_BYTES:-0}" =~ ^[0-9]+$ ]] \
    && (( MOVE_PGM_PLAN_BYTES > 0 )); then
    transferred_bytes="$MOVE_PGM_PLAN_BYTES"
  fi

  if (( DRY_RUN == 1 )); then
    lines+=("Mode: dry-run (no changes made)")
    if [[ "${MOVE_PGM_PLAN_FILES:-}" =~ ^[0-9]+$ ]]; then
      lines+=("Would move files: ${MOVE_PGM_PLAN_FILES}")
    fi
    if (( transferred_bytes > 0 )); then
      lines+=("Would move size: $(move_pgm_format_bytes "$transferred_bytes")")
    fi
  else
    if [[ "${MOVE_PGM_ACTUAL_FILES:-}" =~ ^[0-9]+$ ]]; then
      lines+=("Files transferred: ${MOVE_PGM_ACTUAL_FILES}")
    elif [[ "${MOVE_PGM_PLAN_FILES:-}" =~ ^[0-9]+$ ]]; then
      lines+=("Files: ${MOVE_PGM_PLAN_FILES}")
    fi
    if (( transferred_bytes > 0 )); then
      lines+=("Transferred: $(move_pgm_format_bytes "$transferred_bytes")")
    fi
  fi

  lines+=("Timing:")
  lines+=("  Started:  ${MOVE_PGM_START_STR}")
  lines+=("  Finished: ${MOVE_PGM_END_STR}")
  lines+=("  Elapsed:  $(move_pgm_format_elapsed "$total_sec")")
  if (( MOVE_PGM_PREFLIGHT_SEC > 0 )); then
    lines+=("  Size scan: $(move_pgm_format_elapsed "$MOVE_PGM_PREFLIGHT_SEC")")
  fi
  if (( MOVE_PGM_TRANSFER_SEC > 0 )); then
    lines+=("  Transfer: $(move_pgm_format_elapsed "$MOVE_PGM_TRANSFER_SEC")")
  fi
  if (( MOVE_PGM_CLEANUP_SEC > 0 )); then
    lines+=("  Cleanup:  $(move_pgm_format_elapsed "$MOVE_PGM_CLEANUP_SEC")")
  fi

  if [[ -n "${MOVE_PGM_ACTUAL_RATE_BPS:-}" ]] \
    && awk -v r="${MOVE_PGM_ACTUAL_RATE_BPS}" 'BEGIN { exit (r + 0 > 0) ? 0 : 1 }'; then
    rate_line="$(move_pgm_format_rate "$(awk -v r="${MOVE_PGM_ACTUAL_RATE_BPS}" 'BEGIN { printf "%.0f", r + 0 }')")"
    lines+=("  Avg rate: ${rate_line}")
  elif (( MOVE_PGM_TRANSFER_SEC > 0 && transferred_bytes > 0 )); then
    rate_line="$(move_pgm_format_rate $(( transferred_bytes / MOVE_PGM_TRANSFER_SEC )))"
    lines+=("  Avg rate: ${rate_line}")
  fi

  lines+=("SOURCE: ${SOURCE}")
  lines+=("DESTINATION: ${DESTINATION}")
  if [[ -n "${MOVE_PGM_CLEANUP_SUMMARY:-}" ]]; then
    lines+=("${MOVE_PGM_CLEANUP_SUMMARY}")
  fi

  move_pgm_emit_boxed_block "$design" "${lines[@]}"
  echo
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <SOURCE> <DESTINATION>

Move files between local and remote systems with rsync over SSH. SOURCE and
DESTINATION use normal rsync syntax; one is normally [user@]host:/path.

Options:
  -h, --help             Show this help and exit.
  -v, --version          Print script version and exit.
  -n, --dry-run          Show what would be transferred and removed, but change nothing.
  --bwlimit RATE         Limit bandwidth using rsync RATE syntax (for example 5000 or 10m).
                         By default no bandwidth limit is applied.
  --no_startup_delay     Skip random startup delay when run non-interactively.
  --                     End option parsing.

Transfer behaviour:
  - Uses archive and verbose modes, in-place updates, partial transfers, statistics,
    and progress output.
  - Disables both rsync compression and SSH compression.
  - Disables SSH X11 forwarding.
  - Removes each source file only after rsync transfers it successfully.
  - After a successful move, verifies the source directory tree has no files left
    and removes empty source directories.
  - Before transfer (except --dry-run), prints a boxed transfer plan with file
    count, size (bytes plus MiB/MB, GiB/GB, TiB/TB), and optional ETA when
    --bwlimit is set.
  - Prints a boxed SUCCESS or FAILURE summary with return code, transferred size,
    and timing (start, end, elapsed, transfer, cleanup, average rate).

Examples:
  $(basename "$0") 20260724-Basel_Tattoo \\
    root@lublin.eth.r.matuszyk.com:/root/linki/archiwum/_filmy/2026

  $(basename "$0") --dry-run 20260724-Basel_Tattoo \\
    root@lublin.eth.r.matuszyk.com:/root/linki/archiwum/_filmy/2026

  $(basename "$0") --bwlimit 10m /data/video/ \\
    root@example.com:/archive/video/

Note: rsync trailing-slash rules apply. SOURCE_DIR copies the directory itself;
SOURCE_DIR/ copies only its contents.
EOF
}

HEADER_EXTRA_ARGS=()
CLI_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY) ;;
    -h|--help|-v|--version)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      CLI_ARGS+=("$arg")
      ;;
    *) CLI_ARGS+=("$arg") ;;
  esac
done
set -- "${CLI_ARGS[@]}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -r /root/bin/_script_header.sh ]]; then
  SCRIPT_SUPPORT_DIR=/root/bin
else
  SCRIPT_SUPPORT_DIR="$SCRIPT_DIR"
fi
. "$SCRIPT_SUPPORT_DIR/_script_header.sh" "${HEADER_EXTRA_ARGS[@]}"

DRY_RUN=0
BWLIMIT=
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      print_version_banner
      exit 0
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    --bwlimit)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "Option --bwlimit requires a RATE." >&2
        exit 1
      fi
      BWLIMIT="$2"
      shift 2
      ;;
    --bwlimit=*)
      BWLIMIT="${1#*=}"
      if [[ -z "$BWLIMIT" ]]; then
        echo "Option --bwlimit requires a non-empty RATE." >&2
        exit 1
      fi
      shift
      ;;
    --)
      shift
      POSITIONAL+=("$@")
      break
      ;;
    -*)
      echo "Unknown option: $1 (try --help)" >&2
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if (( ${#POSITIONAL[@]} != 2 )); then
  echo "Exactly one SOURCE and one DESTINATION are required." >&2
  echo "Try: $(basename "$0") --help" >&2
  exit 1
fi

SOURCE="${POSITIONAL[0]}"
DESTINATION="${POSITIONAL[1]}"

check_if_installed rsync
check_if_installed ssh openssh-client

RSYNC_ARGS=(
  -a
  -v
  --inplace
  --no-compress
  --stats
  --progress
  --info=progress1
  --partial
  --remove-source-files
  --no-inc-recursive
  -e "ssh -o Compression=no -x"
)

if [[ -n "$BWLIMIT" ]]; then
  RSYNC_ARGS+=(--bwlimit="$BWLIMIT")
fi

if (( DRY_RUN == 1 )); then
  RSYNC_ARGS+=(--dry-run --itemize-changes)
  echo "DRY RUN: no files will be transferred or removed."
fi

MOVE_PGM_START_STR="$(move_pgm_wall_clock_now)"
MOVE_PGM_RUN_START=$SECONDS
MOVE_PGM_RSYNC_STATS_FILE="$(mktemp)"
trap 'move_pgm_cleanup_temp_files' EXIT

if (( DRY_RUN == 0 )); then
  if move_pgm_run_transfer_preflight; then
    move_pgm_print_transfer_plan
  else
    echo "WARNING: could not determine transfer size (preflight failed); continuing." >&2
    echo
  fi
fi

printf 'Running: rsync'
printf ' %q' "${RSYNC_ARGS[@]}" "$SOURCE" "$DESTINATION"
printf '\n\n'

transfer_start=$SECONDS
rsync "${RSYNC_ARGS[@]}" "$SOURCE" "$DESTINATION" 2> >(tee "$MOVE_PGM_RSYNC_STATS_FILE" >&2)
return_code=$?
MOVE_PGM_TRANSFER_SEC=$(( SECONDS - transfer_start ))

move_pgm_parse_rsync_stats_file "$MOVE_PGM_RSYNC_STATS_FILE" MOVE_PGM_ACTUAL
MOVE_PGM_ACTUAL_BYTES="${MOVE_PGM_ACTUAL_TRANSFERRED_BYTES:-${MOVE_PGM_ACTUAL_TOTAL_BYTES:-0}}"
MOVE_PGM_ACTUAL_FILES="${MOVE_PGM_ACTUAL_FILES:-}"
MOVE_PGM_ACTUAL_RATE_BPS="${MOVE_PGM_ACTUAL_BYTES_PER_SEC:-}"
[[ "$MOVE_PGM_ACTUAL_BYTES" =~ ^[0-9]+$ ]] || MOVE_PGM_ACTUAL_BYTES=0

if (( DRY_RUN == 1 )); then
  MOVE_PGM_PLAN_FILES="${MOVE_PGM_ACTUAL_FILES:-0}"
  MOVE_PGM_PLAN_BYTES="${MOVE_PGM_ACTUAL_TOTAL_BYTES:-0}"
fi

MOVE_PGM_CLEANUP_SUMMARY=""
exit_code=$return_code
if (( return_code == 0 )); then
  cleanup_start=$SECONDS
  move_pgm_cleanup_source_directories || {
    if (( DRY_RUN == 0 )); then
      exit_code=1
    fi
  }
  MOVE_PGM_CLEANUP_SEC=$(( SECONDS - cleanup_start ))
fi

move_pgm_print_result "$return_code" "$exit_code"

return_code=$exit_code
. "$SCRIPT_SUPPORT_DIR/_script_footer.sh"

exit "$exit_code"
