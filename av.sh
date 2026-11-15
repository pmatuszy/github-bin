#!/usr/bin/env bash
# v. 20261115.183600 - AV menu: list audio/media/video scripts; single-key pick, no Enter
#
# 2026.11.15 - v. 0.1.0 - initial: scan sibling bin for audio/media/video/par2/ffmpeg/rename; letter keys (skip q = quit)
#
# av.sh
#
# Short launcher: show audio / media / video tools beside this script and run one.
# Keys are single letters — no Enter. [q] quits. Extra args are forwarded to the chosen script.
#

set -o nounset
set -o pipefail

SCRIPT_VERSION="0.1.0"

av_script_dir() {
  local src="${BASH_SOURCE[0]}"
  local dir

  dir="$(cd "$(dirname "$src")" && pwd -P)"
  printf '%s' "$dir"
}

# Skip q — reserved for quit (single-key, no Enter).
av_keys="abcdefghijklmnoprstuvwxyz"

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

  # Stable order within each group
  if ((${#_audio[@]})); then
    mapfile -t _audio < <(printf '%s\n' "${_audio[@]}" | LC_ALL=C sort)
  fi
  if ((${#_media[@]})); then
    mapfile -t _media < <(printf '%s\n' "${_media[@]}" | LC_ALL=C sort)
  fi
  if ((${#_video[@]})); then
    mapfile -t _video < <(printf '%s\n' "${_video[@]}" | LC_ALL=C sort)
  fi
  if ((${#_tools[@]})); then
    mapfile -t _tools < <(printf '%s\n' "${_tools[@]}" | LC_ALL=C sort)
  fi
}

av_flush_stdin() {
  local discard drained=0 max_drain=256
  [[ -t 0 ]] || return 0
  while (( drained < max_drain )) && IFS= read -r -t 0.02 -n 1 discard; do
    ((++drained))
  done
}

# Uses globals: next_key_i, key_to_script, av_keys
av_print_section() {
  local title="$1"
  shift
  local -a items=("$@")
  local name key

  ((${#items[@]})) || return 0
  printf '\n  %s\n' "$title"
  for name in "${items[@]}"; do
    if (( next_key_i >= ${#av_keys} )); then
      printf '  (!) too many scripts — skipping %s\n' "$name" >&2
      continue
    fi
    key="${av_keys:next_key_i:1}"
    ((++next_key_i))
    key_to_script[$key]="$name"
    printf '  [%s] %s\n' "$key" "$name"
  done
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--] [ARGS...]

List audio / media / video scripts next to this file and run one.
Press a single letter — no Enter. [q] quits.

Any ARGS after the menu options are forwarded to the chosen script.
EOF
}

main() {
  local dir key chosen
  local -a audio_scripts media_scripts video_scripts tool_scripts
  local -a forward=()

  # Shared with av_print_section (bash locals are not visible to callees).
  next_key_i=0
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
  av_print_section "Audio" "${audio_scripts[@]+"${audio_scripts[@]}"}"
  av_print_section "Media / rename / PAR2" "${media_scripts[@]+"${media_scripts[@]}"}"
  av_print_section "Video" "${video_scripts[@]+"${video_scripts[@]}"}"
  av_print_section "Tools / install" "${tool_scripts[@]+"${tool_scripts[@]}"}"
  printf '\n  [q] quit\n'
  printf '======================================================================\n'

  while true; do
    av_flush_stdin
    printf '(%s) pick [letter/q]: ' "$(date '+%Y.%m.%d %H:%M:%S')"
    IFS= read -r -n 1 key || key=
    printf '\n'
    key="${key,,}"
    [[ -z "$key" ]] && continue
    case "$key" in
      q)
        exit 0
        ;;
      [$av_keys])
        chosen="${key_to_script[$key]:-}"
        if [[ -z "$chosen" ]]; then
          printf 'No script on [%s] — try again.\n' "$key"
          continue
        fi
        if [[ ! -x "$dir/$chosen" && ! -f "$dir/$chosen" ]]; then
          printf 'Missing: %s\n' "$dir/$chosen" >&2
          exit 1
        fi
        printf 'Running: %s\n' "$chosen"
        exec "$dir/$chosen" "${forward[@]+"${forward[@]}"}"
        ;;
      *)
        printf 'Unknown key [%s] — try again (or q).\n' "$key"
        ;;
    esac
  done
}

main "$@"
