#!/bin/bash
# v. 20261014.225225 - roll back audio-pgm-swap-audio.sh: delete each *-backup copy one by one (original stays)
#
# 2026.10.14 - v. 0.1 - initial release: find stem-backup.ext next to stem.ext, confirm, remove the
#   swapped copy; if the original name is missing, rename the backup back to that name
#
# audio-pgm-swap-audio-undo.sh
#
# Undo a run of audio-pgm-swap-audio.sh that kept the original and wrote
# clip-backup.mp4 (the swapped file). Each pair is confirmed one by one.
# The original name stays; the swapped *-backup copy is removed. If the
# original name is gone, the backup is renamed to that name.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-n|--dry-run] [--colors yes|no]
       [FILE|DIR ...]

Undo swapped copies written by audio-pgm-swap-audio.sh as stem-backup.ext
beside the original stem.ext.

With no FILE or DIR, the current directory is used. A directory's backups
are the files in that directory, not in folders inside it. Windows paths
such as P:\\video\\trip are read as /mnt/p/video/trip.

Each pair is asked one by one (default Yes):
  keep    clip.mp4           (original)
  remove  clip-backup.mp4    (swapped copy)

If clip.mp4 is missing, the backup is renamed to clip.mp4.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask. Roll back every pair found.
  -n, --dry-run        Print the plan; write nothing.
  --colors yes|no      Use terminal colors (skip the colors question).

A run summary is always printed at the end, and on Ctrl-C.

Examples:
  $(basename "$0")
      Read the current directory, ask before removing each *-backup file.
  $(basename "$0") -y /mnt/p/video
EOF
}

HEADER_EXTRA_ARGS=()
for _un_a in "$@"; do
  [[ "$_un_a" == --no_startup_delay ]] && HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
done
# shellcheck disable=SC1091
. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

DO_YES=0
DRY_RUN=0
COLORS_SET=0
USE_COLORS=""
APPLY_REST=0
UN_SHOWN=0
UN_TOTAL=0
INPUT_ARGS=()
C_B="" C_DIM="" C_G="" C_Y="" C_R="" C_C="" C_0=""
SCRIPT_START_NS=""
STOPPED=no
SUMMARY_DONE=0
return_code=0

BACKUPS=()
ORIGS=()
MODES=()   # remove | rename
DONE_LIST=()
SKIPPED_LIST=()
FAILED_LIST=()

un_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

un_now_ns() {
  date +%s.%N
}

un_summary_kv() {
  printf '  %-*s  %s\n' 20 "${1}:" "$2"
}

un_file_bytes() {
  local n=0
  [[ -f "$1" ]] && n=$(stat -c %s -- "$1" 2>/dev/null || printf '0')
  [[ "$n" =~ ^[0-9]+$ ]] || n=0
  printf '%s\n' "$n"
}

un_human_size() {
  awk -v b="${1:-0}" 'BEGIN {
    split("B KiB MiB GiB TiB", u, " ")
    i = 1
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    if (i == 1) printf "%d %s", b, u[i]
    else printf "%.1f %s", b, u[i]
  }'
}

un_mtime_label() {
  date -r "$1" '+%Y.%m.%d %H:%M:%S' 2>/dev/null || true
}

un_colors() {
  C_B="" C_DIM="" C_G="" C_Y="" C_R="" C_C="" C_0=""
  if [[ "$USE_COLORS" == yes && -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_B=$'\e[1m'
    C_DIM=$'\e[2m'
    C_G=$'\e[32m'
    C_Y=$'\e[33m'
    C_R=$'\e[31m'
    C_C=$'\e[36m'
    C_0=$'\e[0m'
  fi
}

un_print_question() {
  if [[ "$USE_COLORS" == yes ]]; then
    printf '%s%s%s\n' "$C_G" "$*" "$C_0"
  else
    printf '%s\n' "$*"
  fi
}

un_print_selected() {
  printf '%s Selected: %s\n' "$(un_ts)" "$*"
}

un_flush_stdin() {
  local discard drained=0
  while (( drained < 256 )) && IFS= read -r -t 0.02 -n 1 discard; do
    (( drained++ )) || true
  done
}

un_read_key() {
  local prompt="$1" default_key="${2:-}" chosen="${3:-}" answer=""
  if (( ! script_is_run_interactively )); then
    REPLY="$default_key"
    return 0
  fi
  printf '%s' "$prompt"
  un_flush_stdin
  IFS= read -r -n 1 answer || answer=""
  answer="${answer,,}"
  if [[ "$answer" == ' ' ]]; then
    echo
    answer=""
  fi
  if [[ -z "$answer" && -n "$chosen" ]]; then
    printf '  [%s] %s\n' "${default_key^^}" "$chosen"
  else
    echo
  fi
  REPLY="${answer:-$default_key}"
}

un_quit() {
  echo "$(un_ts) Quit."
  STOPPED=yes
  return_code=0
  exit 0
}

un_unix_path() {
  local p="$1" re='^([A-Za-z]):[\\/](.*)$' drive rest
  if [[ "$p" =~ $re ]]; then
    drive="${BASH_REMATCH[1],,}"
    rest="${BASH_REMATCH[2]//\\//}"
    if [[ -d "/mnt/${drive}" ]]; then
      printf '/mnt/%s/%s\n' "$drive" "$rest"
      return 0
    fi
  fi
  printf '%s\n' "$p"
}

un_is_video_name() {
  local base="${1,,}"
  case "$base" in
    *.mp4|*.mkv|*.mov|*.m4v|*.webm|*.avi|*.ts|*.mts|*.m2ts|*.mpg|*.mpeg|*.wmv) return 0 ;;
  esac
  return 1
}

un_original_of_backup() {
  local path="$1" dir base stem ext
  dir="$(dirname -- "$path")"
  base="${path##*/}"
  if [[ "$base" == *.* ]]; then
    ext="${base##*.}"
    stem="${base%.*}"
  else
    ext=""
    stem="$base"
  fi
  [[ "$stem" == *-backup ]] || return 1
  stem="${stem%-backup}"
  [[ -n "$stem" ]] || return 1
  if [[ -n "$ext" ]]; then
    if [[ "$dir" == . ]]; then
      printf '%s.%s\n' "$stem" "$ext"
    else
      printf '%s/%s.%s\n' "$dir" "$stem" "$ext"
    fi
  else
    if [[ "$dir" == . ]]; then
      printf '%s\n' "$stem"
    else
      printf '%s/%s\n' "$dir" "$stem"
    fi
  fi
}

un_add_backup() {
  local path="$1" base orig
  path="$(un_unix_path "$path")"
  [[ -f "$path" ]] || return 1
  base="${path##*/}"
  un_is_video_name "$base" || return 1
  orig="$(un_original_of_backup "$path")" || return 1
  BACKUPS+=("$path")
  ORIGS+=("$orig")
  if [[ -e "$orig" ]]; then
    MODES+=("remove")
  else
    MODES+=("rename")
  fi
}

un_add_directory() {
  local dir="$1" f
  dir="$(un_unix_path "$dir")"
  [[ -d "$dir" ]] || return 1
  while IFS= read -r -d '' f; do
    un_add_backup "$f" || true
  done < <(find "$dir" -maxdepth 1 -type f -name '*-backup.*' -print0 | sort -z)
}

un_ask_colors() {
  if (( COLORS_SET )); then
    un_colors
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    USE_COLORS=no
    un_colors
    return 0
  fi
  USE_COLORS=yes
  un_colors
  echo
  un_print_question "Use colors in the terminal?"
  echo "  [Y] Yes (default)"
  echo "  [n] No"
  echo "  [q] Quit"
  un_read_key "Use colors? [Y/n/q]: " y "Yes (use colors)"
  case "$REPLY" in
    y) USE_COLORS=yes ;;
    n) USE_COLORS=no ;;
    q) un_quit ;;
    *) echo "$(un_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
  [[ "$REPLY" == y ]] && un_print_selected "yes (use colors)"
  [[ "$REPLY" == n ]] && un_print_selected "no (colors off)"
  un_colors
}

un_process_one() {
  local i="$1" bak orig mode
  bak="${BACKUPS[$i]}"
  orig="${ORIGS[$i]}"
  mode="${MODES[$i]}"
  (( UN_SHOWN++ )) || true
  echo
  echo "$(un_ts) ${bak##*/}   (${UN_SHOWN} of ${UN_TOTAL})"
  if [[ "$mode" == rename ]]; then
    echo "  Original is missing: ${orig##*/}"
    echo "  Backup:              ${bak##*/}  ($(un_human_size "$(un_file_bytes "$bak")"), $(un_mtime_label "$bak"))"
    echo "  Roll back: rename the backup to ${orig##*/}"
  else
    echo "  keep    ${orig##*/}  ($(un_human_size "$(un_file_bytes "$orig")"), $(un_mtime_label "$orig"))"
    echo "  remove  ${bak##*/}  ($(un_human_size "$(un_file_bytes "$bak")"), $(un_mtime_label "$bak"))"
  fi
  if (( ! DO_YES )) && (( ! APPLY_REST )) && (( script_is_run_interactively )); then
    echo
    un_print_question "Roll back this file?"
    echo "  [Y] Yes (default) — original stays; swapped copy is removed"
    echo "  [s] Skip this file"
    echo "  [A] Yes, and the same for every remaining file"
    echo "  [q] Quit"
    un_read_key "Roll back? [Y/s/A/q]: " y "Yes — roll back this file"
    case "$REPLY" in
      y) un_print_selected "yes (roll back)" ;;
      s)
        un_print_selected "skip this file"
        SKIPPED_LIST+=("${bak} (skipped)")
        return 0
        ;;
      a)
        APPLY_REST=1
        un_print_selected "yes, and the same for the rest"
        ;;
      q) un_quit ;;
      *)
        echo "$(un_ts) That is not a choice. Skipping."
        SKIPPED_LIST+=("${bak} (skipped)")
        return 0
        ;;
    esac
  fi
  if (( DRY_RUN )); then
    if [[ "$mode" == rename ]]; then
      echo "$(un_ts) Would rename ${bak} -> ${orig}"
    else
      echo "$(un_ts) Would remove ${bak}  (original stays)"
    fi
    DONE_LIST+=("${bak} (dry run)")
    return 0
  fi
  if [[ "$mode" == rename ]]; then
    echo "$(un_ts) Renaming ${bak##*/} -> ${orig##*/}"
    if mv -f -- "$bak" "$orig"; then
      echo "$(un_ts) Rolled back ${orig##*/}"
      DONE_LIST+=("$orig")
      return 0
    fi
    echo "$(un_ts) Could not rename ${bak}." >&2
    FAILED_LIST+=("$bak")
    return_code=1
    return 1
  fi
  echo "$(un_ts) Removing swapped copy ${bak##*/}  (original stays)"
  if rm -f -- "$bak"; then
    echo "$(un_ts) Rolled back ${orig##*/}"
    DONE_LIST+=("$orig")
    return 0
  fi
  echo "$(un_ts) Could not remove ${bak}." >&2
  FAILED_LIST+=("$bak")
  return_code=1
  return 1
}

un_print_summary() {
  local item
  (( SUMMARY_DONE )) && return 0
  SUMMARY_DONE=1
  echo
  echo "--- Run summary ---"
  un_summary_kv "Working directory" "$(pwd -P 2>/dev/null || pwd)"
  un_summary_kv "Backups found" "${#BACKUPS[@]}"
  un_summary_kv "Rolled back" "${#DONE_LIST[@]} file(s)"
  for item in "${DONE_LIST[@]}"; do
    printf '    %s\n' "$item"
  done
  if (( ${#SKIPPED_LIST[@]} > 0 )); then
    un_summary_kv "Skipped" "${#SKIPPED_LIST[@]}"
    for item in "${SKIPPED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  if (( ${#FAILED_LIST[@]} > 0 )); then
    printf '%s' "$C_R"
    un_summary_kv "Failed" "${#FAILED_LIST[@]}"
    printf '%s' "$C_0"
    for item in "${FAILED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  [[ "$STOPPED" == yes ]] && un_summary_kv "Stopped by user" "yes"
  echo
}

un_on_exit() {
  un_print_summary
  if [[ -r /root/bin/_script_footer.sh ]]; then
    # shellcheck disable=SC1091
    . /root/bin/_script_footer.sh
  fi
}

un_ctrl_c() {
  STOPPED=yes
  echo
  echo "$(un_ts) Interrupted."
  return_code=130
  exit 130
}

trap un_on_exit EXIT
trap un_ctrl_c INT

un_need_value() {
  [[ $# -ge 2 && -n "${2:-}" ]] || { echo "ERROR: missing value for $1" >&2; exit 1; }
}

while [[ $# -gt 0 ]]; do
  opt="$1"
  val=""
  case "$opt" in
    --*=*) val="${opt#*=}"; opt="${opt%%=*}"; set -- "$opt" "$val" "${@:2}" ;;
  esac
  case "$1" in
    -h|--help) show_help; SUMMARY_DONE=1; exit 0 ;;
    -v|--version) print_version_banner; SUMMARY_DONE=1; exit 0 ;;
    --history) print_script_history; SUMMARY_DONE=1; exit 0 ;;
    --no_startup_delay) shift ;;
    -y|--yes) DO_YES=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    --colors)
      un_need_value "$@"
      case "$2" in
        yes|no) USE_COLORS="$2"; COLORS_SET=1 ;;
        *) echo "ERROR: --colors must be yes or no, not: $2" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --) shift; INPUT_ARGS+=("$@"); break ;;
    -*) echo "ERROR: unknown option: $1 (see --help)" >&2; exit 1 ;;
    *) INPUT_ARGS+=("$1"); shift ;;
  esac
done

SCRIPT_START_NS="$(un_now_ns)"
un_ask_colors

if (( ${#INPUT_ARGS[@]} == 0 )); then
  echo
  echo "$(un_ts) Searching for *-backup videos in ."
  un_add_directory "."
else
  echo
  echo "$(un_ts) Searching for *-backup videos."
  for _arg in "${INPUT_ARGS[@]}"; do
    _path="$(un_unix_path "$_arg")"
    if [[ -d "$_path" ]]; then
      un_add_directory "$_path"
    elif [[ -f "$_path" ]]; then
      if ! un_add_backup "$_path"; then
        echo "ERROR: not a *-backup video: ${_arg}" >&2
        exit 1
      fi
    else
      echo "ERROR: not a file or directory: ${_arg}" >&2
      exit 1
    fi
  done
fi

UN_TOTAL=${#BACKUPS[@]}
if (( UN_TOTAL == 0 )); then
  echo "$(un_ts) No *-backup video files."
  exit 0
fi
if (( UN_TOTAL == 1 )); then
  echo "$(un_ts) Found 1 backup."
else
  echo "$(un_ts) Found ${UN_TOTAL} backups."
fi

if (( DRY_RUN )); then
  echo "$(un_ts) Dry run: nothing written."
fi

if (( ! DO_YES )) && (( ! script_is_run_interactively )) && (( ! DRY_RUN )); then
  echo "$(un_ts) Not a terminal: nothing written. Add -y to roll back without asking."
  exit 0
fi

for i in "${!BACKUPS[@]}"; do
  un_process_one "$i" || true
done

exit "$return_code"
