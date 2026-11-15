#!/usr/bin/env bash
# v. 20261115.184300 - column gutter ' | ' between left and right
# v. 20261115.184200 - keys a1..aN / v1..vN / m1.. / t1..; two-column; no default
# v. 20261115.184000 - two-column menu (Audio/Video | rest); no default selection
# v. 20261115.183600 - AV menu: list audio/media/video scripts; single-key pick, no Enter
#
# 2026.11.15 - v. 0.3.1 - print ' | ' between left and right columns
# 2026.11.15 - v. 0.3.0 - audio a1..aN, video v1..vN, media m1.., tools t1..; typed keys, no Enter
# 2026.11.15 - v. 0.2.0 - two columns: left Audio+Video, right Media/PAR2/rename + Tools; no default
# 2026.11.15 - v. 0.1.0 - initial: scan sibling bin for audio/media/video/par2/ffmpeg/rename; letter keys (skip q = quit)
#
# av.sh
#
# Short launcher: show audio / media / video tools beside this script and run one.
# Keys: a1.. / v1.. / m1.. / t1.. — no Enter, no default. [q] quits. Extra args are forwarded.
#

set -o nounset
set -o pipefail

SCRIPT_VERSION="0.3.1"

# Left column width (chars): "  [a1] name" padded to this before the right column.
AV_COL_WIDTH=50
# After first digit, wait this long for an optional second digit (v10 vs v1).
AV_DIGIT2_TIMEOUT=0.45

av_script_dir() {
  local src="${BASH_SOURCE[0]}"
  local dir

  dir="$(cd "$(dirname "$src")" && pwd -P)"
  printf '%s' "$dir"
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

# True if some registered key is PREFIX followed by more characters (e.g. v1 vs v10).
av_has_longer_key() {
  local prefix="$1"
  local k
  for k in "${!key_to_script[@]}"; do
    [[ "$k" == "$prefix"?* ]] && return 0
  done
  return 1
}

# Register ITEM under PREFIX+N (1-based). Sets av_cell_out. Uses key_to_script.
av_item_cell() {
  local prefix="$1"
  local n="$2"
  local name="$3"
  local key="${prefix}${n}"

  key_to_script[$key]="$name"
  av_cell_out="  [${key}] ${name}"
}

# Build left/right rows and print two columns.
# Left: Audio (a1..) then Video (v1..). Right: Media (m1..) then Tools (t1..).
# Uses globals: key_to_script, AV_COL_WIDTH, av_cell_out
av_print_two_columns() {
  local -n _la=$1
  local -n _lv=$2
  local -n _rm=$3
  local -n _rt=$4

  local -a left_cells=() right_cells=()
  local name i n max_rows left_cell right_cell pad

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

  max_rows=${#left_cells[@]}
  (( ${#right_cells[@]} > max_rows )) && max_rows=${#right_cells[@]}

  for (( i=0; i < max_rows; i++ )); do
    left_cell=""
    right_cell=""
    (( i < ${#left_cells[@]} )) && left_cell="${left_cells[i]}"
    (( i < ${#right_cells[@]} )) && right_cell="${right_cells[i]}"

    pad=$(( AV_COL_WIDTH - ${#left_cell} ))
    (( pad < 0 )) && pad=0
    if [[ -n "$right_cell" || -n "$left_cell" ]]; then
      printf '%s%*s | %s\n' "$left_cell" "$pad" '' "$right_cell"
    else
      printf '\n'
    fi
  done
}

# Read a menu choice with no Enter and no default.
# Sets av_choice_key (e.g. a1, v10, q) or returns 1 if incomplete/invalid start.
av_read_choice() {
  local c d1 d2
  av_choice_key=""

  IFS= read -r -n 1 c || c=
  [[ -z "$c" || "$c" == $'\n' || "$c" == $'\r' ]] && return 1
  c="${c,,}"
  printf '%s' "$c"

  case "$c" in
    q)
      av_choice_key=q
      return 0
      ;;
    a|v|m|t)
      IFS= read -r -n 1 d1 || d1=
      if [[ -z "$d1" || "$d1" == $'\n' || "$d1" == $'\r' ]]; then
        return 1
      fi
      if [[ ! "$d1" =~ ^[0-9]$ ]]; then
        printf '%s' "$d1"
        return 1
      fi
      printf '%s' "$d1"
      av_choice_key="${c}${d1}"

      # Optional 2nd digit when both v1 and v10 (etc.) exist — short wait, still no Enter.
      if av_has_longer_key "$av_choice_key"; then
        if IFS= read -r -t "$AV_DIGIT2_TIMEOUT" -n 1 d2; then
          if [[ "$d2" =~ ^[0-9]$ ]]; then
            printf '%s' "$d2"
            av_choice_key+="$d2"
          fi
        fi
      fi
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--] [ARGS...]

List audio / media / video scripts next to this file and run one.
Keys (no Enter, no default):
  a1..aN   audio
  v1..vN   video
  m1..mN   media / rename / PAR2
  t1..tN   tools / install
  q        quit

Any ARGS after the menu options are forwarded to the chosen script.
EOF
}

main() {
  local dir chosen
  local -a audio_scripts media_scripts video_scripts tool_scripts
  local -a forward=()

  declare -gA key_to_script=()

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
  av_collect "$dir" audio_scripts media_scripts video_scripts tool_scripts

  if ((${#audio_scripts[@]} + ${#media_scripts[@]} + ${#video_scripts[@]} + ${#tool_scripts[@]} == 0)); then
    printf 'No audio/media/video scripts found in %s\n' "$dir" >&2
    exit 1
  fi

  printf '=== AV menu ============================================================\n'
  av_print_two_columns audio_scripts video_scripts media_scripts tool_scripts
  printf '\n  [q] quit   (no default — type a1 / v3 / m1 / t2 / q)\n'
  printf '======================================================================\n'

  while true; do
    av_flush_stdin
    printf '(%s) key (no default): ' "$(date '+%Y.%m.%d %H:%M:%S')"
    if ! av_read_choice; then
      printf '\n'
      printf 'Need a key like a1, v2, m1, t1, or q — no default.\n'
      continue
    fi
    printf '\n'

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
