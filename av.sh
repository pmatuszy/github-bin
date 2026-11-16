#!/usr/bin/env bash
# v. 20261116.161500 - Up/Down arrow menu (shared script_arrow_menu); drop dialog
# v. 20261116.112100 - dialog --menu when dialog is installed (arrows + tags); key menu fallback
# v. 20261115.184800 - keys 10+: letter suffix (v9 then va, vb…); always two chars
# v. 20261115.184700 - column gap: pad left to content width + two spaces before |
# v. 20261115.184500 - key echo: read -s so terminal does not double each letter
# v. 20261115.184300 - column gutter ' | ' between left and right
# v. 20261115.184200 - keys a1..aN / v1..vN / m1.. / t1..; two-column; no default
# v. 20261115.184000 - two-column menu (Audio/Video | rest); no default selection
# v. 20261115.183600 - AV menu: list audio/media/video scripts; single-key pick, no Enter
#
# 2026.11.16 - v. 0.5.0 - Prefer shared script_arrow_menu (Up/Down + Enter; tags a1/v2/…).
#   No dialog(1). Typed two-column key menu remains the non-TTY / missing-helper fallback.
# 2026.11.16 - v. 0.4.0 - when dialog(1) is installed and stdin/stdout are a TTY, use dialog
#   --menu (arrows + Enter; tags a1/v2/…); Esc/Cancel quits. Otherwise keep the typed-key menu.
# 2026.11.15 - v. 0.3.4 - after 9 use a,b,c… (skip q); drop two-digit keys / digit timeout
# 2026.11.15 - v. 0.3.3 - only two spaces before | (drop wide fixed AV_COL_WIDTH padding)
# 2026.11.15 - v. 0.3.2 - silent read + one printf per key (was printing vv for one v)
# 2026.11.15 - v. 0.3.1 - print ' | ' between left and right columns
# 2026.11.15 - v. 0.3.0 - audio a1..aN, video v1..vN, media m1.., tools t1..; typed keys, no Enter
# 2026.11.15 - v. 0.2.0 - two columns: left Audio+Video, right Media/PAR2/rename + Tools; no default
# 2026.11.15 - v. 0.1.0 - initial: scan sibling bin for audio/media/video/par2/ffmpeg/rename; letter keys (skip q = quit)
#
# av.sh
#
# Short launcher: show audio / media / video tools beside this script and run one.
# TTY + shared arrow menu: Up/Down + Enter (tags a1/v2/…). Otherwise typed
# two-char keys, no Enter. [q] quits.
#

set -o nounset
set -o pipefail

SCRIPT_VERSION="0.5.0"

# 1..9 → digit; 10+ → a,b,c… (q skipped so it never looks like quit).
AV_LETTER_SUFFIXES="abcdefghijklmnoprstuvwxyz"

av_script_dir() {
  local src="${BASH_SOURCE[0]}"
  local dir

  dir="$(cd "$(dirname "$src")" && pwd -P)"
  printf '%s' "$dir"
}

# Load only the shared colors/arrow-menu block from _script_header.sh (not the full header:
# banners, LC_ALL=C, INT trap, apt prompts). Same approach as rename.sh.
av_load_script_arrow_menu() {
  local live_dir="${1-}" hdr="" dir="" block=""

  declare -F script_arrow_menu >/dev/null 2>&1 && return 0
  for dir in "$live_dir" "${profile_location_dir:-$HOME}/bin" "$HOME/bin" "/root/bin"; do
    [[ -n "$dir" && -f "$dir/_script_header.sh" ]] || continue
    hdr="$dir/_script_header.sh"
    break
  done
  [[ -n "$hdr" ]] || return 1
  block="$(sed -n '/^# Shared terminal colors for interactive/,/^# Ask once\./p' "$hdr" 2>/dev/null || true)"
  [[ "$block" == *'script_arrow_menu()'* ]] || return 1
  # shellcheck disable=SC1090
  eval "$block"
  declare -F script_arrow_menu >/dev/null 2>&1
}

# Append basename to nameref array if file exists and is not already listed.
av_add_if_present() {
  local -n _arr=$1
  local path="$2"
  local base already

  [[ -f "$path" && -r "$path" ]] || return 0
  base="$(basename "$path")"
  [[ "$base" == "av.sh" ]] && return 0
  for already in "${_arr[@]+"${_arr[@]}"}"; do
    [[ "$already" == "$base" ]] && return 0
  done
  _arr+=("$base")
}

av_sort_inplace() {
  local -n _arr=$1
  ((${#_arr[@]})) || return 0
  mapfile -t _arr < <(printf '%s\n' "${_arr[@]}" | LC_ALL=C sort)
}

# Collect matching .sh basenames from DIR into group arrays (namerefs).
av_collect() {
  local dir="$1"
  local -n _audio=$2
  local -n _media=$3
  local -n _video=$4
  local -n _tools=$5
  local f base

  _audio=()
  _media=()
  _video=()
  _tools=()

  shopt -s nullglob
  for f in "$dir"/audio-pgm-*.sh; do
    av_add_if_present _audio "$f"
  done
  for f in "$dir"/media-pgm-*.sh; do
    av_add_if_present _media "$f"
  done
  av_add_if_present _media "$dir/rename.sh"
  for f in "$dir"/par2-*.sh; do
    av_add_if_present _media "$f"
  done
  for f in "$dir"/video-pgm-*.sh; do
    base="$(basename "$f")"
    case "$base" in
      video-pgm-install-*|video-pgm-update-*)
        av_add_if_present _tools "$f"
        ;;
      *)
        av_add_if_present _video "$f"
        ;;
    esac
  done
  for f in "$dir"/ffmpeg-*.sh; do
    av_add_if_present _tools "$f"
  done
  shopt -u nullglob

  av_sort_inplace _audio
  av_sort_inplace _media
  av_sort_inplace _video
  av_sort_inplace _tools
}

av_flush_stdin() {
  local discard drained=0 max_drain=256
  [[ -t 0 ]] || return 0
  while (( drained < max_drain )) && IFS= read -r -t 0.02 -n 1 discard; do
    ((++drained))
  done
}

# 1-based index → one-char suffix: 1..9 or a,b,c… (sets av_suffix_out).
av_index_suffix() {
  local n="$1"
  local li

  av_suffix_out=""
  if (( n >= 1 && n <= 9 )); then
    av_suffix_out="$n"
    return 0
  fi
  if (( n >= 10 )); then
    li=$(( n - 10 ))
    if (( li < ${#AV_LETTER_SUFFIXES} )); then
      av_suffix_out="${AV_LETTER_SUFFIXES:li:1}"
      return 0
    fi
  fi
  return 1
}

# True when the shared Up/Down menu can run on this TTY.
av_have_arrow_menu() {
  [[ -t 0 && -t 1 ]] || return 1
  declare -F script_arrow_menu >/dev/null 2>&1
}

# Register ITEM under PREFIX + suffix for 1-based N. Sets av_cell_out.
# Fills key_to_script and appends key|label to av_arrow_opts.
av_item_cell() {
  local prefix="$1"
  local n="$2"
  local name="$3"
  local key label

  if ! av_index_suffix "$n"; then
    av_cell_out="  (!) skip $name"
    return 1
  fi
  key="${prefix}${av_suffix_out}"
  key_to_script[$key]="$name"
  case "$prefix" in
    a) label="Audio  ${name}" ;;
    v) label="Video  ${name}" ;;
    m) label="Media  ${name}" ;;
    t) label="Tools  ${name}" ;;
    *) label="$name" ;;
  esac
  av_arrow_opts+=("${key}|${label}")
  av_cell_out="  [${key}] ${name}"
}

# Build left/right rows and print two columns (typed-key fallback).
# Left: Audio (a1..) then Video (v1..). Right: Media (m1..) then Tools (t1..).
# Uses globals: key_to_script, av_cell_out, av_arrow_opts
av_print_two_columns() {
  local -n _la=$1
  local -n _lv=$2
  local -n _rm=$3
  local -n _rt=$4

  local -a left_cells=() right_cells=()
  local name i n max_rows left_cell right_cell pad left_width=0

  if ((${#_la[@]})); then
    left_cells+=("  Audio")
    n=1
    for name in "${_la[@]}"; do
      av_item_cell a "$n" "$name"
      left_cells+=("$av_cell_out")
      ((++n))
    done
  fi
  if ((${#_lv[@]})); then
    ((${#_la[@]})) && left_cells+=("")
    left_cells+=("  Video")
    n=1
    for name in "${_lv[@]}"; do
      av_item_cell v "$n" "$name"
      left_cells+=("$av_cell_out")
      ((++n))
    done
  fi

  if ((${#_rm[@]})); then
    right_cells+=("  Media / rename / PAR2")
    n=1
    for name in "${_rm[@]}"; do
      av_item_cell m "$n" "$name"
      right_cells+=("$av_cell_out")
      ((++n))
    done
  fi
  if ((${#_rt[@]})); then
    ((${#right_cells[@]})) && right_cells+=("")
    right_cells+=("  Tools / install")
    n=1
    for name in "${_rt[@]}"; do
      av_item_cell t "$n" "$name"
      right_cells+=("$av_cell_out")
      ((++n))
    done
  fi

  for left_cell in "${left_cells[@]+"${left_cells[@]}"}"; do
    (( ${#left_cell} > left_width )) && left_width=${#left_cell}
  done

  max_rows=${#left_cells[@]}
  (( ${#right_cells[@]} > max_rows )) && max_rows=${#right_cells[@]}

  for (( i=0; i < max_rows; i++ )); do
    left_cell=""
    right_cell=""
    (( i < ${#left_cells[@]} )) && left_cell="${left_cells[i]}"
    (( i < ${#right_cells[@]} )) && right_cell="${right_cells[i]}"

    pad=$(( left_width - ${#left_cell} ))
    (( pad < 0 )) && pad=0
    if [[ -n "$right_cell" || -n "$left_cell" ]]; then
      # Two spaces before |, none forced after (right cell already has leading spaces).
      printf '%s%*s  |%s\n' "$left_cell" "$pad" '' "$right_cell"
    else
      printf '\n'
    fi
  done
}

# Register all scripts into key_to_script + av_arrow_opts (no column print).
av_register_all() {
  local -n _la=$1
  local -n _lv=$2
  local -n _rm=$3
  local -n _rt=$4
  local name n

  if ((${#_la[@]})); then
    n=1
    for name in "${_la[@]}"; do
      av_item_cell a "$n" "$name" || true
      ((++n))
    done
  fi
  if ((${#_lv[@]})); then
    n=1
    for name in "${_lv[@]}"; do
      av_item_cell v "$n" "$name" || true
      ((++n))
    done
  fi
  if ((${#_rm[@]})); then
    n=1
    for name in "${_rm[@]}"; do
      av_item_cell m "$n" "$name" || true
      ((++n))
    done
  fi
  if ((${#_rt[@]})); then
    n=1
    for name in "${_rt[@]}"; do
      av_item_cell t "$n" "$name" || true
      ((++n))
    done
  fi
}

# Read one key silently, then echo it once (avoids "vv" from tty echo + printf).
av_read_char() {
  local __var="$1"
  IFS= read -r -s -n 1 "$__var"
}

# Read a menu choice with no Enter and no default.
# Sets av_choice_key (e.g. a1, va, q) or returns 1 if incomplete/invalid start.
av_read_choice() {
  local c d1
  av_choice_key=""

  av_read_char c || c=
  [[ -z "$c" || "$c" == $'\n' || "$c" == $'\r' ]] && return 1
  c="${c,,}"
  printf '%s' "$c"

  case "$c" in
    q)
      av_choice_key=q
      return 0
      ;;
    a|v|m|t)
      av_read_char d1 || d1=
      if [[ -z "$d1" || "$d1" == $'\n' || "$d1" == $'\r' ]]; then
        return 1
      fi
      d1="${d1,,}"
      # 1..9 or letter suffix (a..z except bare quit is only single q).
      if [[ ! "$d1" =~ ^[1-9a-z]$ ]]; then
        printf '%s' "$d1"
        return 1
      fi
      printf '%s' "$d1"
      av_choice_key="${c}${d1}"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Shared Up/Down menu. Sets av_choice_key. Empty default = no preferred row mark;
# Enter still accepts the highlighted row.
av_arrow_choice() {
  av_choice_key=""
  ((${#av_arrow_opts[@]} >= 1)) || return 1
  script_arrow_menu "" "${av_arrow_opts[@]}" "q|Quit"
  av_choice_key="${REPLY:-}"
  [[ -n "$av_choice_key" ]] || return 1
  return 0
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--] [ARGS...]

List audio / media / video scripts next to this file and run one.

On a TTY with the shared arrow menu (_script_header.sh):
  Up/Down + Enter to run; tags a1/v2/…; [q] Quit.

Otherwise typed keys (no Enter, no default) — two chars after the section letter:
  a1..a9, aa..   audio
  v1..v9, va..   video
  m1..m9, ma..   media / rename / PAR2
  t1..t9, ta..   tools / install
  q              quit

Any ARGS after the menu options are forwarded to the chosen script.
EOF
}

main() {
  local dir chosen use_arrows=0
  local -a audio_scripts media_scripts video_scripts tool_scripts
  local -a forward=()

  declare -gA key_to_script=()
  declare -ga av_arrow_opts=()

  while (($#)); do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      -v|--version)
        printf '%s\n' "$SCRIPT_VERSION"
        exit 0
        ;;
      --)
        shift
        forward+=("$@")
        break
        ;;
      -*)
        printf 'Unknown option: %s (try --help)\n' "$1" >&2
        exit 2
        ;;
      *)
        forward+=("$@")
        break
        ;;
    esac
    shift
  done

  dir="$(av_script_dir)"
  av_load_script_arrow_menu "$dir" || true
  if [[ -t 1 ]] && declare -F script_colors_init >/dev/null 2>&1; then
    SCRIPT_USE_COLORS=1
    script_colors_init
  fi

  av_collect "$dir" audio_scripts media_scripts video_scripts tool_scripts

  if ((${#audio_scripts[@]} + ${#media_scripts[@]} + ${#video_scripts[@]} + ${#tool_scripts[@]} == 0)); then
    printf 'No audio/media/video scripts found in %s\n' "$dir" >&2
    exit 1
  fi

  av_have_arrow_menu && use_arrows=1

  av_build_menu_maps() {
    key_to_script=()
    av_arrow_opts=()
    if (( use_arrows )); then
      av_register_all audio_scripts video_scripts media_scripts tool_scripts
    else
      printf '=== AV menu ============================================================\n'
      av_print_two_columns audio_scripts video_scripts media_scripts tool_scripts
      printf '\n  [q] quit   (no default — type a1 / v3 / va / m1 / t2 / q)\n'
      printf '======================================================================\n'
    fi
  }

  av_build_menu_maps

  while true; do
    if (( use_arrows )); then
      printf 'AV menu — Up/Down move · Enter run · [q] Quit\n'
      if ! av_arrow_choice; then
        printf 'Arrow menu failed — falling back to typed keys.\n' >&2
        use_arrows=0
        av_build_menu_maps
        continue
      fi
    else
      av_flush_stdin
      printf '(%s) key (no default): ' "$(date '+%Y.%m.%d %H:%M:%S')"
      if ! av_read_choice; then
        printf '\n'
        printf 'Need a key like a1, v2, va, m1, t1, or q — no default.\n'
        continue
      fi
      printf '\n'
    fi

    if [[ "$av_choice_key" == q ]]; then
      exit 0
    fi

    chosen="${key_to_script[$av_choice_key]:-}"
    if [[ -z "$chosen" ]]; then
      printf 'No script on [%s] — try again (no default).\n' "$av_choice_key"
      continue
    fi
    if [[ ! -x "$dir/$chosen" && ! -f "$dir/$chosen" ]]; then
      printf 'Missing: %s\n' "$dir/$chosen" >&2
      exit 1
    fi
    printf 'Running: %s\n' "$chosen"
    exec "$dir/$chosen" "${forward[@]+"${forward[@]}"}"
  done
}

main "$@"
