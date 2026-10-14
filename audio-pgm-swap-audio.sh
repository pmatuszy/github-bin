#!/bin/bash
# v. 20261014.213909 - swap audio tracks in a video; every other stream stays, in the same order
#
# 2026.10.14 - v. 0.1 - initial release: list each file's streams (language when the file has one),
#   swap the audio tracks (default: the first two), and write stem_audio-swap.ext beside the source
#   with -c copy; video, subtitles, chapters, metadata, file times, and GoPro telemetry stay;
#   non-audio streams keep their original order; a run summary is always printed
#
# audio-pgm-swap-audio.sh
#
# Change the order of the audio tracks inside a video. The picture, subtitles,
# chapters, metadata, file times, and data streams (GoPro MET/gpmd, and so on)
# stay. Those other streams keep the order they had. Only the audio tracks
# move. A stream that ffmpeg cannot copy into MP4 (tmcd, mp4s) is skipped and
# named in the log; telemetry (gpmd) is kept.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-n|--dry-run] [--colors yes|no] [--order 2,1]
       [FILE|DIR ...]

Swap the audio tracks inside each video. The picture, subtitles, chapters,
metadata, file times, and other streams stay, in the same order they had.
Only the audio tracks change places. Language tags and the "default" flag
travel with that audio track.

With no FILE or DIR, the current directory is used. A directory's videos are
the files in that directory, not in folders inside it. Windows paths such as
P:\\video\\trip are read as /mnt/p/video/trip.

A file with fewer than two audio tracks is listed and skipped. A file whose
name already has _audio-swap is skipped.

The new file is written beside the source:
  clip.mp4  ->  clip_audio-swap.mp4
Video is copied, not re-encoded. If that name is already there you can keep
it, replace it, or write a name with the clock.

Default order: the first two audio tracks swap (2,1), and any further audio
tracks stay after them in their old order. --order 2,1 is that same rule.
--order 3,1,2 is audio track 3, then 1, then 2 (the numbers in the printed
list, not ffmpeg's stream index).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask. Swap every file that has two or more
                       audio tracks. An existing output is skipped.
  -n, --dry-run        Print the plan; write nothing.
  --colors yes|no      Use terminal colors (skip the colors question).
  --order LIST         Audio-track numbers, comma-separated, as printed
                       (1 is the first audio track). Default: 2,1.

A run summary is always printed at the end, and on Ctrl-C.

Needs: ffmpeg and ffprobe. When something is missing the script lists it and
asks whether to install it with apt-get (with sudo when not root). With -y
or without a terminal it only prints the install command.

Examples:
  $(basename "$0")
      Read the current directory, print the streams, ask before writing.
  $(basename "$0") -y --order 2,1 /mnt/p/video
  $(basename "$0") --colors yes clip.mp4
EOF
}

HEADER_EXTRA_ARGS=()
for _sa_a in "$@"; do
  [[ "$_sa_a" == --no_startup_delay ]] && HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
done
# shellcheck disable=SC1091
. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

DO_YES=0
DRY_RUN=0
COLORS_SET=0
USE_COLORS=""
ORDER_SET=0
ORDER_SPEC="2,1"
INPUT_ARGS=()
C_B="" C_DIM="" C_G="" C_Y="" C_R="" C_C="" C_0=""
SCRIPT_START_NS=""
PROC_SEC=0
PROC_SLICE=""
STOPPED=no
SUMMARY_DONE=0
return_code=0
TMP_FILE=""
APPLY_REST=0
REST_ORDER=""

FILES=()
FILE_STATE=()   # swap | skip | fail
FILE_WHY=()
FILE_AUDIO_N=()
FILE_DEST=()
DONE_LIST=()
SKIPPED_LIST=()
FAILED_LIST=()
OLD_KEPT=()
OLD_DELETED=()

ST_IDX=() ST_TYPE=() ST_CODEC=() ST_TAG=() ST_LANG=() ST_TITLE=()
ST_HANDLER=() ST_CH=() ST_RATE=() ST_WH=() ST_DEF=()
AUDIO_ST=()

sa_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

sa_now_ns() {
  date +%s.%N 2>/dev/null || date +%s
}

sa_proc_begin() {
  PROC_SLICE="$(sa_now_ns)"
}

sa_proc_end() {
  [[ -n "${PROC_SLICE:-}" ]] || return 0
  PROC_SEC="$(awk -v a="${PROC_SEC:-0}" -v t0="$PROC_SLICE" -v t1="$(sa_now_ns)" \
    'BEGIN { d = t1 - t0; if (d < 0) d = 0; printf "%.6f", a + d }')"
  PROC_SLICE=""
}

sa_format_elapsed() {
  awk -v s="${1:-0}" 'BEGIN {
    if (s < 0) s = 0
    t = int(s + 0.5)
    if (t < 1) { printf "0s"; exit }
    h = int(t / 3600)
    m = int((t % 3600) / 60)
    x = t % 60
    if (h > 0) printf "%dh %02dm %02ds", h, m, x
    else if (m > 0) printf "%dm %02ds", m, x
    else printf "%ds", x
  }'
}

sa_format_wall() {
  date -d "@${1%.*}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null || date '+%Y.%m.%d %H:%M:%S'
}

sa_summary_kv() {
  printf '  %-*s  %s\n' 20 "${1}:" "$2"
}

sa_file_bytes() {
  local n=0
  [[ -f "$1" ]] && n=$(stat -c %s -- "$1" 2>/dev/null || printf '0')
  [[ "$n" =~ ^[0-9]+$ ]] || n=0
  printf '%s\n' "$n"
}

sa_human_size() {
  awk -v b="${1:-0}" 'BEGIN {
    split("B KiB MiB GiB TiB", u, " ")
    i = 1
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    if (i == 1) printf "%d %s", b, u[i]
    else printf "%.1f %s", b, u[i]
  }'
}

sa_colors() {
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

sa_print_question() {
  if [[ "$USE_COLORS" == yes ]]; then
    printf '%s%s%s\n' "$C_G" "$*" "$C_0"
  else
    printf '%s\n' "$*"
  fi
}

sa_print_selected() {
  printf '%s Selected: %s\n' "$(sa_ts)" "$*"
}

sa_flush_stdin() {
  local discard drained=0
  while (( drained < 256 )) && IFS= read -r -t 0.02 -n 1 discard; do
    (( drained++ )) || true
  done
}

# One key, no Enter. Space and Enter take the default.
sa_read_key() {
  local prompt="$1" default_key="${2:-}" chosen="${3:-}" answer=""
  if (( ! script_is_run_interactively )); then
    REPLY="$default_key"
    return 0
  fi
  printf '%s' "$prompt"
  sa_flush_stdin
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

sa_quit() {
  echo "$(sa_ts) Quit."
  STOPPED=yes
  return_code=0
  exit 0
}

sa_unix_path() {
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

sa_quote_args() {
  local a out=""
  for a in "$@"; do
    out+="$(printf '%q' "$a") "
  done
  printf '%s' "${out% }"
}

sa_is_video_name() {
  local base="${1,,}"
  case "$base" in
    *.mp4|*.mkv|*.mov|*.m4v|*.webm|*.avi|*.ts|*.mts|*.m2ts|*.mpg|*.mpeg|*.wmv) return 0 ;;
  esac
  return 1
}

sa_skip_name() {
  local base="$1"
  [[ "$base" == ._* || "$base" == *_old-* || "$base" == *.partial || "$base" == *.partial.* ]] && return 0
  [[ "$base" == *_audio-swap.* || "$base" == *_audio-swap_* ]] && return 0
  return 1
}

sa_ffprobe_one() {
  local line
  while IFS= read -r line; do
    line="${line//$'\r'/}"
    [[ -n "$line" ]] || continue
    printf '%s\n' "$line"
    return 0
  done
  return 0
}

sa_probe_field() {
  local file="$1" idx="$2" entries="$3"
  ffprobe -v error -select_streams "$idx" -show_entries "$entries" \
    -of default=nw=1:nk=1 -- "$file" 2>/dev/null | sa_ffprobe_one || true
}

sa_is_mp4_family() {
  local ref="$1"
  case "${ref##*.}" in
    [mM][pP]4|[mM]4[vV]|[mM][oO][vV]|3[gG][pP]) return 0 ;;
  esac
  return 1
}

# tmcd and MPEG-4 Systems cannot be stream-copied into MP4. gpmd/fdsc stay.
sa_stream_unmappable_mp4() {
  local codec_type="$1" codec_name="$2" codec_tag="$3" handler="$4"
  local tag="${codec_tag,,}" name="${codec_name,,}"
  [[ "$tag" == mp4s ]] && return 0
  [[ "$tag" == tmcd || "$handler" == *TCD* ]] && return 0
  [[ "$name" == none && "$tag" != gpmd && "$tag" != fdsc ]] || return 1
  case "${codec_type,,}" in
    data|unknown|'') return 0 ;;
  esac
  return 1
}

sa_load_streams() {
  local file="$1" idx ctype
  local -A seen=()
  ST_IDX=() ST_TYPE=() ST_CODEC=() ST_TAG=() ST_LANG=() ST_TITLE=()
  ST_HANDLER=() ST_CH=() ST_RATE=() ST_WH=() ST_DEF=()
  AUDIO_ST=()

  while IFS= read -r idx; do
    idx="${idx//$'\r'/}"
    [[ "$idx" =~ ^[0-9]+$ ]] || continue
    [[ -n "${seen[$idx]+x}" ]] && continue
    seen[$idx]=1
    ctype="$(sa_probe_field "$file" "$idx" stream=codec_type)"
    ST_IDX+=("$idx")
    ST_TYPE+=("$ctype")
    ST_CODEC+=("$(sa_probe_field "$file" "$idx" stream=codec_name)")
    ST_TAG+=("$(sa_probe_field "$file" "$idx" stream=codec_tag_string)")
    ST_LANG+=("$(sa_probe_field "$file" "$idx" stream_tags=language)")
    ST_TITLE+=("$(sa_probe_field "$file" "$idx" stream_tags=title)")
    ST_HANDLER+=("$(sa_probe_field "$file" "$idx" stream_tags=handler_name)")
    ST_CH+=("$(sa_probe_field "$file" "$idx" stream=channels)")
    ST_RATE+=("$(sa_probe_field "$file" "$idx" stream=sample_rate)")
    ST_WH+=("$(sa_probe_field "$file" "$idx" stream=width)x$(sa_probe_field "$file" "$idx" stream=height)")
    ST_DEF+=("$(sa_probe_field "$file" "$idx" stream_disposition=default)")
    if [[ "${ctype,,}" == audio ]]; then
      AUDIO_ST+=("$idx")
    fi
  done < <(ffprobe -v error -show_entries stream=index -of csv=p=0 -- "$file" 2>/dev/null || true)
}

sa_audio_label() {
  local i="$1" bits="" lang title ch rate def
  lang="${ST_LANG[$i]}"
  title="${ST_TITLE[$i]}"
  ch="${ST_CH[$i]}"
  rate="${ST_RATE[$i]}"
  def="${ST_DEF[$i]}"
  bits="${ST_CODEC[$i]:-?}"
  [[ -n "$ch" ]] && bits+=" ${ch}ch"
  [[ -n "$rate" ]] && bits+=" ${rate} Hz"
  [[ -n "$lang" ]] && bits+="  lang=${lang}"
  [[ -n "$title" ]] && bits+="  ${title}"
  [[ "$def" == 1 ]] && bits+="  default"
  printf '%s' "$bits"
}

sa_print_streams() {
  local i n type extra a_n=0
  n=${#ST_IDX[@]}
  (( n )) || { echo "    (no streams)"; return 0; }
  echo "  Streams:"
  for (( i = 0; i < n; i++ )); do
    type="${ST_TYPE[$i],,}"
    extra=""
    case "$type" in
      audio)
        (( a_n++ )) || true
        extra="  audio ${a_n}: $(sa_audio_label "$i")"
        ;;
      video)
        extra="  ${ST_CODEC[$i]:-?}  ${ST_WH[$i]}"
        extra="${extra/x0/}"
        extra="${extra/0x/}"
        [[ -n "${ST_HANDLER[$i]}" ]] && extra+="  ${ST_HANDLER[$i]}"
        ;;
      subtitle)
        extra="  ${ST_CODEC[$i]:-?}"
        [[ -n "${ST_LANG[$i]}" ]] && extra+="  lang=${ST_LANG[$i]}"
        ;;
      *)
        extra="  ${ST_CODEC[$i]:-${ST_TAG[$i]:-?}}"
        [[ -n "${ST_TAG[$i]}" && "${ST_TAG[$i]}" != "${ST_CODEC[$i]}" ]] && extra+="  tag=${ST_TAG[$i]}"
        [[ -n "${ST_HANDLER[$i]}" ]] && extra+="  ${ST_HANDLER[$i]}"
        ;;
    esac
    printf '    #%s  %-8s%s\n' "${ST_IDX[$i]}" "${ST_TYPE[$i]:-?}" "$extra"
  done
}

# Expand a slot list such as 2,1 for N audio tracks to a full permutation.
# Remaining tracks keep their old order after the named ones.
sa_expand_slots() {
  local n="$1" spec="$2" tok
  local -a named=() used=() out=()
  local i k
  (( n >= 1 )) || return 1
  spec="${spec// /}"
  [[ -n "$spec" ]] || spec="2,1"
  IFS=',' read -r -a named <<< "$spec"
  used=()
  for (( i = 1; i <= n; i++ )); do
    used[$i]=0
  done
  for tok in "${named[@]}"; do
    [[ "$tok" =~ ^[0-9]+$ ]] || return 1
    k=$((10#$tok))
    (( k >= 1 && k <= n )) || return 1
    (( used[k] == 0 )) || return 1
    used[$k]=1
    out+=("$k")
  done
  for (( i = 1; i <= n; i++ )); do
    (( used[i] )) && continue
    out+=("$i")
  done
  (( ${#out[@]} == n )) || return 1
  printf '%s' "${out[0]}"
  for (( i = 1; i < n; i++ )); do
    printf ',%s' "${out[$i]}"
  done
  printf '\n'
}

sa_slots_are_identity() {
  local spec="$1" n="$2" i tok
  local -a parts=()
  IFS=',' read -r -a parts <<< "$spec"
  (( ${#parts[@]} == n )) || return 1
  for (( i = 0; i < n; i++ )); do
    tok="${parts[$i]}"
    (( 10#$tok == i + 1 )) || return 1
  done
  return 0
}

sa_dest_path() {
  local src="$1" dir base stem ext
  dir="$(dirname -- "$src")"
  base="${src##*/}"
  if [[ "$base" == *.* ]]; then
    ext="${base##*.}"
    stem="${base%.*}"
    if [[ "$dir" == . ]]; then
      printf '%s_audio-swap.%s\n' "$stem" "$ext"
    else
      printf '%s/%s_audio-swap.%s\n' "$dir" "$stem" "$ext"
    fi
  else
    if [[ "$dir" == . ]]; then
      printf '%s_audio-swap\n' "$base"
    else
      printf '%s/%s_audio-swap\n' "$dir" "$base"
    fi
  fi
}

sa_next_take_name() {
  local dest="$1" dir base stem ext stamp cand n=2
  dir="$(dirname -- "$dest")"
  base="${dest##*/}"
  if [[ "$base" == *.* ]]; then
    ext=".${base##*.}"
    stem="${base%.*}"
  else
    ext=""
    stem="$base"
  fi
  stamp="$(date '+%Y%m%d-%H%M%S')"
  if [[ "$dir" == . ]]; then
    cand="${stem}_${stamp}${ext}"
  else
    cand="${dir}/${stem}_${stamp}${ext}"
  fi
  while [[ -e "$cand" ]]; do
    if [[ "$dir" == . ]]; then
      cand="${stem}_${stamp}_${n}${ext}"
    else
      cand="${dir}/${stem}_${stamp}_${n}${ext}"
    fi
    (( n++ ))
  done
  printf '%s\n' "$cand"
}

sa_temp_path() {
  local dest="$1" dir base stem ext
  dir="$(dirname -- "$dest")"
  base="${dest##*/}"
  if [[ "$base" == *.* ]]; then
    ext="${base##*.}"
    stem="${base%.*}"
    if [[ "$dir" == . ]]; then
      printf '%s.tmp.%s.%s\n' "$stem" "$$" "$ext"
    else
      printf '%s/%s.tmp.%s.%s\n' "$dir" "$stem" "$$" "$ext"
    fi
  else
    if [[ "$dir" == . ]]; then
      printf '%s.tmp.%s\n' "$base" "$$"
    else
      printf '%s/%s.tmp.%s\n' "$dir" "$base" "$$"
    fi
  fi
}

# Map every original stream slot in order; audio slots take the permuted sources.
sa_build_map_args() {
  local src="$1" dest="$2" slot_csv="$3"
  local -n out_map=$4
  local -n out_note=$5
  local i type idx slot src_idx mp4=0 skipped=""
  local -a slots=() audio_src=()
  out_map=()
  out_note=""
  sa_is_mp4_family "$dest" && mp4=1
  (( mp4 == 0 )) && sa_is_mp4_family "$src" && mp4=1
  IFS=',' read -r -a slots <<< "$slot_csv"
  (( ${#slots[@]} == ${#AUDIO_ST[@]} )) || return 1
  for slot in "${slots[@]}"; do
    audio_src+=("${AUDIO_ST[$((10#$slot - 1))]}")
  done
  (( mp4 )) && out_map+=(-copy_unknown)
  slot=0
  for (( i = 0; i < ${#ST_IDX[@]}; i++ )); do
    idx="${ST_IDX[$i]}"
    type="${ST_TYPE[$i],,}"
    if (( mp4 )) && sa_stream_unmappable_mp4 "${ST_TYPE[$i]}" "${ST_CODEC[$i]}" "${ST_TAG[$i]}" "${ST_HANDLER[$i]}"; then
      if [[ -n "$skipped" ]]; then
        skipped+=", #${idx}"
      else
        skipped="#${idx} ${ST_TAG[$i]:-${ST_CODEC[$i]:-tmcd}}"
      fi
      continue
    fi
    if [[ "$type" == audio ]]; then
      src_idx="${audio_src[$slot]}"
      (( slot++ )) || true
      out_map+=(-map "0:${src_idx}")
    else
      out_map+=(-map "0:${idx}")
    fi
  done
  [[ -n "$skipped" ]] && out_note="MP4 cannot copy ${skipped} (telemetry is kept)"
  return 0
}

sa_print_ffmpeg_tail() {
  local log="$1"
  [[ -s "$log" ]] || return 0
  echo "    ffmpeg said:"
  tail -n 12 -- "$log" | sed 's/^/      /'
}

sa_restore_times() {
  local dest="$1" ref="$2"
  [[ -f "$ref" ]] || return 0
  touch -r "$ref" -- "$dest" 2>/dev/null || true
  if command -v chmod >/dev/null 2>&1; then
    chmod --reference="$ref" -- "$dest" 2>/dev/null || true
  fi
}

sa_remux() {
  local src="$1" dest="$2" slot_csv="$3"
  local tmp ref log rc=0 note=""
  local -a map_args=()
  tmp="$(sa_temp_path "$dest")"
  ref="$(mktemp)"
  log="$(mktemp)"
  touch -r "$src" -- "$ref" 2>/dev/null || true
  TMP_FILE="$tmp"
  sa_build_map_args "$src" "$dest" "$slot_csv" map_args note || {
    rm -f -- "$ref" "$log"
    TMP_FILE=""
    return 1
  }
  [[ -n "$note" ]] && echo "$(sa_ts) ${note}"
  ffmpeg -hide_banner -nostats -y -i "$src" \
    "${map_args[@]}" \
    -map_metadata 0 \
    -map_chapters 0 \
    -c copy \
    -max_muxing_queue_size 9999 \
    -- "$tmp" 2>"$log" || rc=$?
  if (( rc != 0 )) || [[ ! -s "$tmp" ]]; then
    sa_print_ffmpeg_tail "$log"
    rm -f -- "$tmp" "$ref" "$log"
    TMP_FILE=""
    return 1
  fi
  rm -f -- "$log"
  if ! mv -f -- "$tmp" "$dest"; then
    rm -f -- "$tmp" "$ref"
    TMP_FILE=""
    return 1
  fi
  TMP_FILE=""
  sa_restore_times "$dest" "$ref"
  rm -f -- "$ref"
  return 0
}

sa_add_file() {
  local path="$1" base
  path="$(sa_unix_path "$path")"
  [[ -f "$path" ]] || return 1
  base="${path##*/}"
  sa_is_video_name "$base" || return 1
  sa_skip_name "$base" && return 1
  FILES+=("$path")
}

sa_add_directory() {
  local dir="$1" f
  dir="$(sa_unix_path "$dir")"
  [[ -d "$dir" ]] || return 1
  while IFS= read -r -d '' f; do
    sa_add_file "$f" || true
  done < <(find "$dir" -maxdepth 1 -type f -print0 | sort -z)
}

sa_missing_prereqs() {
  if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
    echo "ffmpeg|ffmpeg and ffprobe: copy the streams and list the audio tracks"
  fi
  return 0
}

sa_check_prereqs() {
  local line rc=0
  local -a missing=() pkgs=() cmd=()
  mapfile -t missing < <(sa_missing_prereqs)
  (( ${#missing[@]} == 0 )) && return 0
  for line in "${missing[@]}"; do
    pkgs+=("${line%%|*}")
  done
  cmd=(apt-get install -y "${pkgs[@]}")
  (( EUID != 0 )) && cmd=(sudo "${cmd[@]}")
  echo
  echo "  This script needs these, and they are not installed:"
  for line in "${missing[@]}"; do
    printf '  %-12s %s\n' "${line%%|*}" "${line#*|}"
  done
  echo "  Install command: $(sa_quote_args "${cmd[@]}")"
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "$(sa_ts) apt-get is not available here; install them with this system's package manager." >&2
    exit 1
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    echo "$(sa_ts) Nothing is installed without asking. Run the install command, or start this script in a terminal without -y." >&2
    exit 1
  fi
  echo
  sa_print_question "Install them now?"
  echo "  [Y] Yes, install with the command above, then continue (default)"
  echo "  [n] No, stop here"
  echo "  [q] Quit"
  sa_read_key "Install them now? [Y/n/q]: " y "Yes, install then continue"
  case "$REPLY" in
    y) ;;
    *) echo "$(sa_ts) Nothing installed."; exit 1 ;;
  esac
  "${cmd[@]}" || rc=$?
  if (( rc != 0 )); then
    echo "$(sa_ts) Install failed; refreshing the package lists and trying again."
    if (( EUID != 0 )); then
      sudo apt-get update || true
    else
      apt-get update || true
    fi
    rc=0
    "${cmd[@]}" || rc=$?
  fi
  mapfile -t missing < <(sa_missing_prereqs)
  if (( rc != 0 || ${#missing[@]} > 0 )); then
    echo "$(sa_ts) Still missing after the install." >&2
    exit 1
  fi
  echo "$(sa_ts) Installed. Continuing."
}

sa_ask_colors() {
  if (( COLORS_SET )); then
    sa_colors
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    USE_COLORS=no
    sa_colors
    return 0
  fi
  USE_COLORS=yes
  sa_colors
  echo
  sa_print_question "Use colors in the terminal?"
  echo "  [Y] Yes (default)"
  echo "  [n] No"
  echo "  [q] Quit"
  sa_read_key "Use colors? [Y/n/q]: " y "Yes (use colors)"
  case "$REPLY" in
    y) USE_COLORS=yes ;;
    n) USE_COLORS=no ;;
    q) sa_quit ;;
    *) echo "$(sa_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
  [[ "$REPLY" == y ]] && sa_print_selected "yes (use colors)"
  [[ "$REPLY" == n ]] && sa_print_selected "no (colors off)"
  sa_colors
}

sa_equivalent_cli() {
  local cmd out q_dir p
  local -a parts=()
  cmd="$(basename -- "${BASH_SOURCE[0]:-$0}")"
  (( DO_YES )) && parts+=("--yes")
  (( DRY_RUN )) && parts+=("--dry-run")
  if [[ -n "$USE_COLORS" ]]; then
    parts+=("--colors" "$USE_COLORS")
  fi
  if (( ORDER_SET )) || [[ -n "$REST_ORDER" ]]; then
    parts+=("--order" "${REST_ORDER:-$ORDER_SPEC}")
  else
    parts+=("--order" "$ORDER_SPEC")
  fi
  out="$(printf '%q' "$cmd")"
  for p in "${parts[@]}"; do
    out+=" $(printf '%q' "$p")"
  done
  if (( ${#INPUT_ARGS[@]} )); then
    out+=" --"
    for p in "${INPUT_ARGS[@]}"; do
      out+=" $(printf '%q' "$p")"
    done
  fi
  q_dir="$(printf '%q' "$PWD")"
  printf '  %-21s%s\n' "Equivalent CLI:" "cd $q_dir && $out"
}

sa_print_run_settings() {
  echo
  echo "=== Run settings ==="
  if (( DO_YES )); then
    echo "  -y/--yes:            given (swap without asking; skip an existing output)"
  else
    echo "  -y/--yes:            not given (prompt per file)"
  fi
  if (( DRY_RUN )); then
    echo "  -n/--dry-run:        given (write nothing)"
  else
    echo "  -n/--dry-run:        not given"
  fi
  if (( COLORS_SET )); then
    printf '  %-21s%s\n' "--colors:" "given (${USE_COLORS})"
  else
    printf '  %-21s%s\n' "--colors:" "${USE_COLORS:-yes} (asked)"
  fi
  if (( ORDER_SET )); then
    printf '  %-21s%s\n' "--order:" "given (${ORDER_SPEC})"
  else
    printf '  %-21s%s\n' "--order:" "${ORDER_SPEC} (default: first two audio tracks swap)"
  fi
  printf '  %-21s%s\n' "Work dir:" "$PWD"
  sa_equivalent_cli
  echo
}

sa_probe_plan() {
  local i src n why dest expanded
  for i in "${!FILES[@]}"; do
    src="${FILES[$i]}"
    FILE_STATE[$i]=skip
    FILE_WHY[$i]=""
    FILE_AUDIO_N[$i]=0
    FILE_DEST[$i]=""
    sa_load_streams "$src"
    n=${#AUDIO_ST[@]}
    FILE_AUDIO_N[$i]="$n"
    dest="$(sa_dest_path "$src")"
    FILE_DEST[$i]="$dest"
    if (( n == 0 )); then
      FILE_WHY[$i]="no audio track"
      continue
    fi
    if (( n == 1 )); then
      FILE_WHY[$i]="one audio track"
      continue
    fi
    if ! expanded=$(sa_expand_slots "$n" "$ORDER_SPEC"); then
      FILE_WHY[$i]="order ${ORDER_SPEC} does not fit ${n} audio tracks"
      continue
    fi
    if sa_slots_are_identity "$expanded" "$n"; then
      FILE_WHY[$i]="that order leaves the audio as it is"
      continue
    fi
    FILE_STATE[$i]=swap
    FILE_WHY[$i]="$expanded"
  done
}

sa_print_plan() {
  local i src n state why dest a
  echo
  echo "Videos:"
  for i in "${!FILES[@]}"; do
    src="${FILES[$i]}"
    n="${FILE_AUDIO_N[$i]}"
    state="${FILE_STATE[$i]}"
    why="${FILE_WHY[$i]}"
    dest="${FILE_DEST[$i]}"
    printf '  %s\n' "$src"
    sa_load_streams "$src"
    sa_print_streams
    if [[ "$state" == swap ]]; then
      printf '    -> %s  (audio order %s)\n' "$dest" "$why"
    else
      printf '    skip: %s\n' "$why"
    fi
    echo
  done
}

sa_ask_custom_order() {
  local n="$1" default="$2" typed="" expanded
  echo "  Audio-track numbers, comma-separated. 1 is the first audio track."
  printf '  New order [%s]: ' "$default"
  sa_flush_stdin
  IFS= read -r typed || sa_quit
  typed="${typed// /}"
  [[ -z "$typed" ]] && typed="$default"
  if expanded=$(sa_expand_slots "$n" "$typed"); then
    if sa_slots_are_identity "$expanded" "$n"; then
      echo "  That order leaves the audio as it is."
      return 1
    fi
    REPLY="$typed"
    return 0
  fi
  echo "  That is not a list of these audio tracks."
  return 1
}

sa_ask_existing() {
  local dest="$1"
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    echo "$(sa_ts) Already there, skipping: ${dest}"
    return 1
  fi
  echo
  echo "  ${dest} is already there."
  echo "  [K] Keep it, skip this file (default)"
  echo "  [r] Replace it"
  echo "  [n] Write a new name with the clock"
  echo "  [q] Quit"
  sa_read_key "Existing file [K/r/n/q]: " k "Keep it, skip this file"
  case "$REPLY" in
    k) echo "$(sa_ts) Keeping ${dest}."; return 1 ;;
    r) return 0 ;;
    n)
      NEW_DEST="$(sa_next_take_name "$dest")"
      echo "$(sa_ts) New name: ${NEW_DEST}"
      return 2
      ;;
    q) sa_quit ;;
    *) echo "$(sa_ts) That is not a choice. Skipping."; return 1 ;;
  esac
}

sa_process_one() {
  local i="$1" src dest n order why rc=0
  src="${FILES[$i]}"
  dest="${FILE_DEST[$i]}"
  n="${FILE_AUDIO_N[$i]}"
  why="${FILE_WHY[$i]}"
  if [[ "${FILE_STATE[$i]}" != swap ]]; then
    SKIPPED_LIST+=("${src} (${why})")
    return 0
  fi
  sa_load_streams "$src"
  echo
  echo "$(sa_ts) ${src}"
  sa_print_streams
  order="$why"
  if (( APPLY_REST )) && [[ -n "$REST_ORDER" ]]; then
    if ! order=$(sa_expand_slots "$n" "$REST_ORDER"); then
      echo "$(sa_ts) Order ${REST_ORDER} does not fit this file. Skipping."
      SKIPPED_LIST+=("${src} (order does not fit)")
      FILE_STATE[$i]=skip
      return 0
    fi
  elif (( ! DO_YES )) && (( script_is_run_interactively )) && (( ! APPLY_REST )); then
    echo
    sa_print_question "Swap the audio in this file?"
    echo "  [Y] Yes, order ${order} (default)"
    echo "  [o] Type a new audio order"
    echo "  [s] Skip this file"
    echo "  [A] Yes, and the same order for every remaining file"
    echo "  [q] Quit"
    sa_read_key "Swap audio? [Y/o/s/A/q]: " y "Yes, order ${order}"
    case "$REPLY" in
      y) sa_print_selected "yes (${order})" ;;
      o)
        if sa_ask_custom_order "$n" "$ORDER_SPEC"; then
          ORDER_SPEC="$REPLY"
          ORDER_SET=1
          order="$REPLY"
          if ! order=$(sa_expand_slots "$n" "$ORDER_SPEC"); then
            echo "$(sa_ts) That order does not fit this file. Skipping."
            SKIPPED_LIST+=("${src} (order does not fit)")
            return 0
          fi
          sa_print_selected "order ${ORDER_SPEC}"
        else
          SKIPPED_LIST+=("${src} (left as it is)")
          return 0
        fi
        ;;
      s)
        sa_print_selected "skip this file"
        SKIPPED_LIST+=("${src} (skipped)")
        return 0
        ;;
      a)
        APPLY_REST=1
        REST_ORDER="$ORDER_SPEC"
        ORDER_SET=1
        sa_print_selected "yes, and the same order for the rest (${ORDER_SPEC})"
        ;;
      q) sa_quit ;;
      *)
        echo "$(sa_ts) That is not a choice. Skipping."
        SKIPPED_LIST+=("${src} (skipped)")
        return 0
        ;;
    esac
  fi
  if sa_slots_are_identity "$order" "$n"; then
    echo "$(sa_ts) That order leaves the audio as it is. Skipping."
    SKIPPED_LIST+=("${src} (left as it is)")
    return 0
  fi
  if (( DRY_RUN )); then
    echo "$(sa_ts) Would write ${dest}  (audio order ${order})"
    DONE_LIST+=("${dest} (dry run, ${order})")
    return 0
  fi
  NEW_DEST=""
  if [[ -e "$dest" ]]; then
    sa_ask_existing "$dest"
    rc=$?
    if (( rc == 1 )); then
      SKIPPED_LIST+=("${dest} (already there)")
      return 0
    fi
    if (( rc == 2 )); then
      dest="$NEW_DEST"
    fi
  fi
  echo "$(sa_ts) Writing ${dest}  (audio order ${order}, copy)"
  sa_proc_begin
  if sa_remux "$src" "$dest" "$order"; then
    sa_proc_end
    echo "$(sa_ts) Wrote ${dest}  ($(sa_human_size "$(sa_file_bytes "$dest")"))"
    DONE_LIST+=("$dest")
    return 0
  fi
  sa_proc_end
  echo "$(sa_ts) Could not write ${dest}." >&2
  FAILED_LIST+=("$src")
  return_code=1
  return 1
}

sa_print_summary() {
  local item end_ns total_sec wait_sec in_sum=0 out_sum=0
  (( SUMMARY_DONE )) && return 0
  SUMMARY_DONE=1
  sa_proc_end
  end_ns="$(sa_now_ns)"
  total_sec="$(awk -v s0="${SCRIPT_START_NS:-0}" -v s1="$end_ns" 'BEGIN { printf "%.6f", s1 - s0 }')"
  wait_sec="$(awk -v t="$total_sec" -v p="${PROC_SEC:-0}" 'BEGIN { w = t - p; if (w < 0) w = 0; printf "%.6f", w }')"
  echo
  echo "--- Run summary ---"
  sa_summary_kv "Working directory" "$(pwd -P 2>/dev/null || pwd)"
  sa_summary_kv "Files found" "${#FILES[@]}"
  sa_summary_kv "Swapped" "${#DONE_LIST[@]} file(s)"
  for item in "${DONE_LIST[@]}"; do
    printf '    %s\n' "$item"
    out_sum=$(( out_sum + $(sa_file_bytes "$item") ))
  done
  if (( ${#SKIPPED_LIST[@]} > 0 )); then
    sa_summary_kv "Skipped" "${#SKIPPED_LIST[@]}"
    for item in "${SKIPPED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  if (( ${#FAILED_LIST[@]} > 0 )); then
    printf '%s' "$C_R"
    sa_summary_kv "Failed" "${#FAILED_LIST[@]}"
    printf '%s' "$C_0"
    for item in "${FAILED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  local i src
  for i in "${!FILES[@]}"; do
    src="${FILES[$i]}"
    in_sum=$(( in_sum + $(sa_file_bytes "$src") ))
  done
  sa_summary_kv "Input size" "$(sa_human_size "$in_sum")"
  sa_summary_kv "Output size" "$(sa_human_size "$out_sum")"
  echo
  echo "--- Timing ---"
  sa_summary_kv "Started" "$(sa_format_wall "${SCRIPT_START_NS:-}")"
  sa_summary_kv "Finished" "$(date '+%Y.%m.%d %H:%M:%S')"
  sa_summary_kv "Total wall time" "$(sa_format_elapsed "$total_sec")"
  sa_summary_kv "Processing time" "$(sa_format_elapsed "${PROC_SEC:-0}")  (remux)"
  sa_summary_kv "Other/wait time" "$(sa_format_elapsed "$wait_sec")  (prompts, startup, overhead)"
  [[ "$STOPPED" == yes ]] && sa_summary_kv "Stopped by user" "yes"
  echo
}

sa_on_exit() {
  [[ -n "${TMP_FILE:-}" && -f "$TMP_FILE" ]] && rm -f -- "$TMP_FILE"
  sa_print_summary
  if [[ -r /root/bin/_script_footer.sh ]]; then
    # shellcheck disable=SC1091
    . /root/bin/_script_footer.sh
  fi
}

sa_ctrl_c() {
  STOPPED=yes
  echo
  echo "$(sa_ts) Interrupted."
  return_code=130
  exit 130
}

trap sa_on_exit EXIT
trap sa_ctrl_c INT

sa_need_value() {
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
      sa_need_value "$@"
      case "$2" in
        yes|no) USE_COLORS="$2"; COLORS_SET=1 ;;
        *) echo "ERROR: --colors must be yes or no, not: $2" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --order)
      sa_need_value "$@"
      ORDER_SPEC="${2// /}"
      ORDER_SET=1
      shift 2 ;;
    --) shift; INPUT_ARGS+=("$@"); break ;;
    -*) echo "ERROR: unknown option: $1 (see --help)" >&2; exit 1 ;;
    *) INPUT_ARGS+=("$1"); shift ;;
  esac
done

SCRIPT_START_NS="$(sa_now_ns)"
sa_ask_colors
sa_check_prereqs

if (( ${#INPUT_ARGS[@]} == 0 )); then
  sa_add_directory "."
else
  for _arg in "${INPUT_ARGS[@]}"; do
    _path="$(sa_unix_path "$_arg")"
    if [[ -d "$_path" ]]; then
      sa_add_directory "$_path"
    elif [[ -f "$_path" ]]; then
      if ! sa_add_file "$_path"; then
        echo "ERROR: not a video I swap audio in: ${_arg}" >&2
        exit 1
      fi
    else
      echo "ERROR: not a file or directory: ${_arg}" >&2
      exit 1
    fi
  done
fi

if (( ${#FILES[@]} == 0 )); then
  echo "$(sa_ts) No video files."
  exit 0
fi

sa_probe_plan
sa_print_plan
sa_print_run_settings

swap_n=0
for i in "${!FILES[@]}"; do
  [[ "${FILE_STATE[$i]}" == swap ]] && (( swap_n++ )) || true
done
if (( swap_n == 0 )); then
  echo "$(sa_ts) No file with two or more audio tracks to swap."
  exit 0
fi

if (( DRY_RUN )); then
  echo "$(sa_ts) Dry run: nothing written."
  for i in "${!FILES[@]}"; do
    sa_process_one "$i" || true
  done
  exit 0
fi

if (( ! DO_YES )); then
  if (( ! script_is_run_interactively )); then
    echo "$(sa_ts) Not a terminal: nothing written. Add -y to swap without asking."
    exit 0
  fi
  sa_print_question "Swap audio in these files?"
  echo "  [Y] Yes (default)"
  echo "  [n] No"
  echo "  [q] Quit"
  sa_read_key "Swap audio in these files? [Y/n/q]: " y "Yes"
  case "$REPLY" in
    y) sa_print_selected "yes" ;;
    n)
      sa_print_selected "no"
      echo "$(sa_ts) Nothing written."
      exit 0
      ;;
    q) sa_quit ;;
    *) echo "$(sa_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
fi

for i in "${!FILES[@]}"; do
  sa_process_one "$i" || true
done

exit "$return_code"
