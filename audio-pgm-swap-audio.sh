#!/bin/bash
# v. 20261014.225831 - if clip-backup already exists, save another original copy as clip-backup_YYYYMMDD-HHMMSS.ext
# v. 20261014.225419 - original is moved to stem-backup.ext; the swapped file keeps the original name
# v. 20261014.224924 - first-file report is compact: facts, present, streams and plan in a few short lines
# v. 20261014.224804 - Videos list is tight and multi-line: name, backup, then a short facts line
# v. 20261014.224553 - Getting file info (1/8) also prints the file name; the Videos: dump is gone
# v. 20261014.224006 - after the file list: keep English, Polish, German (default yes); drop other audio/subtitle languages, or choose which to drop
# v. 20261014.223151 - after a swap, audio track 1 is default; matching subtitles follow the audio order (asked, default yes) and subtitle 1 is default
# v. 20261014.222646 - probe progress is "Getting file info (1/8)", with no file name
# v. 20261014.221754 - check ffmpeg/ffprobe first; ask colors, keep-copy, and one-by-one before reading files; print search and probe progress
# v. 20261014.221053 - ask one-by-one or together; the first file gets a full stream report
# v. 20261014.220750 - the kept copy is named stem-backup.ext
# v. 20261014.220133 - ask to keep the original (default yes); print a facts table before and after each swap
# v. 20261014.213909 - swap audio tracks in a video; every other stream stays, in the same order
#
# 2026.10.14 - v. 0.13 - if clip-backup.mp4 is already there, copy the original to clip-backup_YYYYMMDD-HHMMSS.mp4 instead of overwriting
# 2026.10.14 - v. 0.12 - keep-original moves the original to clip-backup.mp4, then writes the swapped file under the original name
# 2026.10.14 - v. 0.11 - first-file listing is compact (size/duration/times on one line, present on one line, plan on two lines)
# 2026.10.14 - v. 0.10 - Videos list is three short lines per file (name, backup, facts), not one long line
# 2026.10.14 - v. 0.9 - probe line is "Getting file info (1/8) name"; do not print the Videos: source/backup list
# 2026.10.14 - v. 0.8 - after the file list, if there are languages other than English, Polish and German, ask to drop them (default yes) or choose which to drop; the last remaining audio track is never dropped
# 2026.10.14 - v. 0.7 - after a swap, the new first audio track is default; ask to reorder subtitles to the same languages as audio (default yes) and then make the first subtitle default
# 2026.10.14 - v. 0.6 - while streams are read, print "Getting file info (1/8)" (no file name)
# 2026.10.14 - v. 0.5 - ffmpeg and ffprobe are required (exit if missing); colors, keep a copy, and one-by-one/together are asked before any file is opened; then search and "file k of N" while streams are read
# 2026.10.14 - v. 0.4 - after the list: one by one (default) or together; the first file prints every stream, GPS, throughput, and present/not present
# 2026.10.14 - v. 0.3 - the kept copy is clip-backup.mp4 (not clip_audio-swap.mp4)
# 2026.10.14 - v. 0.2 - keep a copy of the original is the default; each file gets a table of duration, streams, GPS and times before the swap, and the same table again with input and output side by side
# 2026.10.14 - v. 0.1 - initial release: list each file's streams (language when the file has one),
#   swap the audio tracks (default: the first two), and write stem_audio-swap.ext beside the source
#   with -c copy; video, subtitles, chapters, metadata, file times, and GoPro telemetry stay;
#   non-audio streams keep their original order; a run summary is always printed
#
# audio-pgm-swap-audio.sh
#
# Change the order of the audio tracks inside a video. The picture, chapters,
# metadata, file times, and data streams (GoPro MET/gpmd, and so on) stay.
# Subtitle tracks can follow the same language order as the audio, when the
# user says yes (the default). After a swap, audio track 1 is the default
# track; if subtitles were reordered, subtitle track 1 is the default too.
# A stream that ffmpeg cannot copy into MP4 (tmcd, mp4s) is skipped and
# named in the log; telemetry (gpmd) is kept.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-n|--dry-run] [--colors yes|no]
       [--keep-original yes|no] [--one-by-one|--together]
       [--subtitles yes|no] [--languages keep|all] [--drop LIST]
       [--order 2,1]
       [FILE|DIR ...]

Swap the audio tracks inside each video. The picture, chapters, metadata,
file times, and other non-subtitle streams stay, in the same order they had.
After a swap, audio track 1 is marked default (other audio is not).
Subtitle tracks with the same languages as the audio can be reordered the
same way (asked up front, default Yes). If they are, subtitle track 1 is
marked default too. A subtitle with no language, or a language that is not
on an audio track, stays after the matched ones in its old relative order.

With no FILE or DIR, the current directory is used. A directory's videos are
the files in that directory, not in folders inside it. Windows paths such as
P:\\video\\trip are read as /mnt/p/video/trip.

A file with fewer than two audio tracks is listed and skipped, unless extra
languages are being dropped (then a file with one remaining audio is still
written). A file whose name already has -backup or _audio-swap is skipped.

After the files are read, if any audio or subtitle language is not English
(American counts as English), Polish or German, the script asks to leave
only those three (default Yes). [c] lets you type the numbers to drop
(more than one is allowed). [k] keeps every language. A stream with no
language tag is kept. The last remaining audio track is never dropped.

Keep a copy of each original? [Y/n/q] (default Yes): the original is moved
to clip-backup.mp4, and the swapped file keeps the original name. No: the
original is replaced. Video is copied, not re-encoded. If clip-backup.mp4
is already there, the original is copied to
clip-backup_YYYYMMDD-HHMMSS.mp4 so that copy is never overwritten.
Roll back with audio-pgm-swap-audio-undo.sh (puts a backup back as
clip.mp4, one file at a time).

The first four questions (colors, keep a copy, one by one or together,
matching subtitles) are asked before any file is opened. One by one is
the default. Matching subtitles is Yes. Then the script searches for
videos and prints "Getting file info (1/8) name" while it reads streams. The first file prints a compact report: size, duration, times, what is
present, each audio/video/subtitle line, and the swap plan. Later files
keep the shorter table. After the
remux the same facts are printed side by side for input and output. A value
that changed is marked with * on the output side.

Default order: the first two audio tracks swap (2,1), and any further audio
tracks stay after them in their old order. --order 2,1 is that same rule.
--order 3,1,2 is audio track 3, then 1, then 2 (the numbers in the printed
list, not ffmpeg's stream index).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask. Swap every file that has two or more
                       audio tracks. An existing clip-backup.mp4 is left;
                       a dated copy is written beside it.
  -n, --dry-run        Print the plan; write nothing.
  --colors yes|no      Use terminal colors (skip the colors question).
  --keep-original yes|no
                       Keep the original file (skip that question).
                       yes (default): move it to clip-backup.mp4, then write
                       the swapped file as clip.mp4. If that backup is
                       already there, copy to clip-backup_YYYYMMDD-HHMMSS.mp4.
                       no: replace the original.
  --one-by-one         Ask about each file (default; skip that question).
  --together           Same audio order for every file (skip that question).
  --subtitles yes|no   Reorder subtitle tracks to the same languages as
                       the audio (skip that question). yes is the default.
  --languages keep|all After the files are read: keep English, Polish, German
                       and drop the rest (keep, default), or keep every
                       language (all). Skips that question.
  --drop LIST          Language codes or names to drop, comma-separated
                       (rus,ukr,spa). Skips the languages question.
  --order LIST         Audio-track numbers, comma-separated, as printed
                       (1 is the first remaining audio track). Default: 2,1.

A run summary is always printed at the end, and on Ctrl-C.

Needs: ffmpeg and ffprobe in PATH. If either is missing the script prints
which one is missing and exits. -h, -v and --history do not need them.

Examples:
  $(basename "$0")
      Read the current directory, print the streams, ask before writing.
  $(basename "$0") -y --order 2,1 /mnt/p/video
  $(basename "$0") --colors yes clip.mp4
  audio-pgm-swap-audio-undo.sh
      Put each clip-backup.mp4 back as clip.mp4, one file at a time.
EOF
}

HEADER_EXTRA_ARGS=()
for _sa_a in "$@"; do
  [[ "$_sa_a" == --no_startup_delay ]] && HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
done
# shellcheck disable=SC1091
. "${profile_location_dir:-$HOME}/bin/_script_header.sh" "${HEADER_EXTRA_ARGS[@]}"

DO_YES=0
DRY_RUN=0
COLORS_SET=0
USE_COLORS=""
ORDER_SET=0
ORDER_SPEC="2,1"
KEEP_SET=0
KEEP_ORIGINAL=1
TOGETHER_SET=0
TOGETHER=0
SUBS_SET=0
SWAP_SUBS=1
LANGS_SET=0
LANGS_MODE=""
DROP_SPEC=""
DROP_FAMS=()
EXTRA_FAMS=()
KEPT_AUDIO_ST=()
KEPT_SUBTITLE_ST=()
ALL_FAMS=()
LANG_MENU_FAM=()
SWAP_SHOWN=0
SWAP_TOTAL=0
INPUT_ARGS=()
C_B="" C_DIM="" C_G="" C_Y="" C_R="" C_C="" C_0=""
SCRIPT_START_NS=""
PROC_SEC=0
PROC_SLICE=""
STOPPED=no
SUMMARY_DONE=0
return_code=0
TMP_FILE=""
ASIDE_ORIG=""
ASIDE_BACKUP=""
APPLY_REST=0
REST_ORDER=""

FILES=()
FILE_STATE=()   # swap | skip | fail
FILE_WHY=()
FILE_AUDIO_N=()
FILE_AUDIO_FAMS=()
FILE_SUB_FAMS=()
FILE_SUB_NOTE=()
FILE_DEST=()
FILE_BACKUP=()
DONE_LIST=()
SKIPPED_LIST=()
FAILED_LIST=()
OLD_KEPT=()
OLD_DELETED=()

ST_IDX=() ST_TYPE=() ST_CODEC=() ST_TAG=() ST_LANG=() ST_TITLE=()
ST_HANDLER=() ST_CH=() ST_RATE=() ST_WH=() ST_DEF=() ST_FPS=() ST_BR=()
AUDIO_ST=()
SUBTITLE_ST=()
INFO_FILE="" INFO_SIZE="" INFO_DUR="" INFO_THRU="" INFO_CREATED="" INFO_MTIME=""
INFO_GPS="" INFO_CHAPTERS="" INFO_GOPRO="" INFO_AUDIO=""
IN_FILE="" IN_SIZE="" IN_DUR="" IN_CREATED="" IN_MTIME="" IN_GPS="" IN_CHAPTERS="" IN_GOPRO="" IN_AUDIO=""
OUT_FILE="" OUT_SIZE="" OUT_DUR="" OUT_CREATED="" OUT_MTIME="" OUT_GPS="" OUT_CHAPTERS="" OUT_GOPRO="" OUT_AUDIO=""
IN_IDX=() IN_TYPE=() IN_CODEC=() IN_DET=()
OUT_IDX=() OUT_TYPE=() OUT_CODEC=() OUT_DET=()

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

sa_dash() {
  if [[ -n "${1:-}" ]]; then
    printf '%s' "$1"
  else
    printf '—'
  fi
}

sa_trunc() {
  local text="$1" width="$2"
  if (( ${#text} <= width )); then
    printf '%s' "$text"
    return 0
  fi
  if (( width < 4 )); then
    printf '%s' "${text:0:width}"
    return 0
  fi
  printf '%s…' "${text:0:$((width - 1))}"
}

sa_clock_from_sec() {
  awk -v s="${1:-0}" 'BEGIN {
    if (s == "" || s + 0 != s) { printf "—"; exit }
    t = int(s + 0.5)
    if (t < 0) t = 0
    h = int(t / 3600)
    m = int((t % 3600) / 60)
    x = t % 60
    if (h > 0) printf "%d:%02d:%02d", h, m, x
    else printf "%d:%02d", m, x
  }'
}

sa_fps_label() {
  awk -v r="${1:-}" 'BEGIN {
    if (r == "" || r == "0/0") { print ""; exit }
    n = split(r, a, "/")
    if (n == 2 && a[2] + 0 > 0) v = a[1] / a[2]
    else v = r + 0
    if (v <= 0) { print ""; exit }
    if (v == int(v)) printf "%d fps", v
    else printf "%.3g fps", v
  }'
}

sa_rate_label() {
  awk -v b="${1:-}" 'BEGIN {
    if (b == "" || b + 0 <= 0) { print ""; exit }
    if (b >= 1000000) printf "%.1f Mb/s", b / 1000000
    else if (b >= 1000) printf "%.0f kb/s", b / 1000
    else printf "%s b/s", b
  }'
}

sa_created_label() {
  local raw="$1" out
  [[ -n "$raw" ]] || return 0
  out="$(date -d "$raw" '+%Y.%m.%d %H:%M:%S' 2>/dev/null || true)"
  if [[ -n "$out" ]]; then
    printf '%s' "$out"
    return 0
  fi
  printf '%s' "$raw"
}

sa_mtime_label() {
  date -r "$1" '+%Y.%m.%d %H:%M:%S' 2>/dev/null || true
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
  [[ "$base" == *-backup.* || "$base" == *-backup_* || "$base" == *_audio-swap.* || "$base" == *_audio-swap_* ]] && return 0
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

sa_format_tag() {
  local file="$1" tag="$2"
  ffprobe -v error -show_entries "format_tags=${tag}" -of default=nw=1:nk=1 -- "$file" 2>/dev/null | sa_ffprobe_one || true
}

sa_gps_of() {
  local file="$1" loc iso lat lon line
  loc="$(sa_format_tag "$file" location)"
  [[ -z "$loc" ]] && loc="$(sa_format_tag "$file" location-eng)"
  iso="$(sa_format_tag "$file" com.apple.quicktime.location.ISO6709)"
  if [[ -z "$loc" && -n "$iso" ]]; then
    loc="$iso"
  fi
  if [[ "$loc" =~ ([+-][0-9.]+)([+-][0-9.]+) ]]; then
    printf '%s, %s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return 0
  fi
  if [[ -n "$loc" ]]; then
    printf '%s' "$loc"
    return 0
  fi
  if command -v exiftool >/dev/null 2>&1; then
    lat="$(exiftool -n -s3 -GPSLatitude -- "$file" 2>/dev/null || true)"
    lon="$(exiftool -n -s3 -GPSLongitude -- "$file" 2>/dev/null || true)"
    lat="${lat//$'\r'/}"
    lon="${lon//$'\r'/}"
    if [[ -n "$lat" && -n "$lon" ]]; then
      printf '%s, %s' "$lat" "$lon"
      return 0
    fi
  fi
  return 0
}

sa_chapter_count() {
  local n
  n="$(ffprobe -v error -show_entries chapter=id -of csv=p=0 -- "$1" 2>/dev/null | grep -c . || true)"
  [[ "$n" =~ ^[0-9]+$ ]] || n=0
  printf '%s' "$n"
}

sa_load_streams() {
  local file="$1" idx ctype w h fps
  local -A seen=()
  ST_IDX=() ST_TYPE=() ST_CODEC=() ST_TAG=() ST_LANG=() ST_TITLE=()
  ST_HANDLER=() ST_CH=() ST_RATE=() ST_WH=() ST_DEF=() ST_FPS=() ST_BR=()
  AUDIO_ST=()
  SUBTITLE_ST=()

  while IFS= read -r idx; do
    idx="${idx//$'\r'/}"
    [[ "$idx" =~ ^[0-9]+$ ]] || continue
    [[ -n "${seen[$idx]+x}" ]] && continue
    seen[$idx]=1
    ctype="$(sa_probe_field "$file" "$idx" stream=codec_type)"
    w="$(sa_probe_field "$file" "$idx" stream=width)"
    h="$(sa_probe_field "$file" "$idx" stream=height)"
    fps="$(sa_probe_field "$file" "$idx" stream=r_frame_rate)"
    ST_IDX+=("$idx")
    ST_TYPE+=("$ctype")
    ST_CODEC+=("$(sa_probe_field "$file" "$idx" stream=codec_name)")
    ST_TAG+=("$(sa_probe_field "$file" "$idx" stream=codec_tag_string)")
    ST_LANG+=("$(sa_probe_field "$file" "$idx" stream_tags=language)")
    ST_TITLE+=("$(sa_probe_field "$file" "$idx" stream_tags=title)")
    ST_HANDLER+=("$(sa_probe_field "$file" "$idx" stream_tags=handler_name)")
    ST_CH+=("$(sa_probe_field "$file" "$idx" stream=channels)")
    ST_RATE+=("$(sa_probe_field "$file" "$idx" stream=sample_rate)")
    if [[ "$w" =~ ^[0-9]+$ && "$h" =~ ^[0-9]+$ && "$w" -gt 0 && "$h" -gt 0 ]]; then
      ST_WH+=("${w}x${h}")
    else
      ST_WH+=("")
    fi
    ST_FPS+=("$(sa_fps_label "$fps")")
    ST_BR+=("$(sa_rate_label "$(sa_probe_field "$file" "$idx" stream=bit_rate)")")
    ST_DEF+=("$(sa_probe_field "$file" "$idx" stream_disposition=default)")
    if [[ "${ctype,,}" == audio ]]; then
      AUDIO_ST+=("$idx")
    elif [[ "${ctype,,}" == subtitle ]]; then
      SUBTITLE_ST+=("$idx")
    fi
  done < <(ffprobe -v error -show_entries stream=index -of csv=p=0 -- "$file" 2>/dev/null || true)
}

sa_gopro_label() {
  local i tag handler
  for i in "${!ST_IDX[@]}"; do
    tag="${ST_TAG[$i],,}"
    handler="${ST_HANDLER[$i]}"
    if [[ "$tag" == gpmd || "$tag" == fdsc || "$handler" == *MET* || "$handler" == GoPro* ]]; then
      printf 'yes (%s)' "${ST_TAG[$i]:-${ST_CODEC[$i]:-gpmd}}"
      return 0
    fi
  done
  printf 'no'
}

sa_audio_order_text() {
  local i idx lang a_n=0 nums="" langs=""
  for i in "${!ST_IDX[@]}"; do
    [[ "${ST_TYPE[$i],,}" == audio ]] || continue
    (( a_n++ )) || true
    idx="${ST_IDX[$i]}"
    lang="${ST_LANG[$i]:-?}"
    [[ "${ST_DEF[$i]}" == 1 ]] && lang+=" default"
    if [[ -n "$nums" ]]; then
      nums+=", ${a_n}"
      langs+=", ${lang}"
    else
      nums="${a_n}"
      langs="${lang}"
    fi
  done
  if (( a_n == 0 )); then
    printf '—'
    return 0
  fi
  printf '%s  (%s)' "$nums" "$langs"
}

sa_load_info() {
  local file="$1" dur br
  sa_load_streams "$file"
  INFO_FILE="${file##*/}"
  INFO_SIZE="$(sa_human_size "$(sa_file_bytes "$file")")"
  dur="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 -- "$file" 2>/dev/null | sa_ffprobe_one || true)"
  INFO_DUR="$(sa_clock_from_sec "$dur")"
  br="$(ffprobe -v error -show_entries format=bit_rate -of default=nw=1:nk=1 -- "$file" 2>/dev/null | sa_ffprobe_one || true)"
  INFO_THRU="$(sa_rate_label "$br")"
  INFO_CREATED="$(sa_created_label "$(sa_format_tag "$file" creation_time)")"
  INFO_MTIME="$(sa_mtime_label "$file")"
  INFO_GPS="$(sa_gps_of "$file")"
  INFO_CHAPTERS="$(sa_chapter_count "$file")"
  INFO_GOPRO="$(sa_gopro_label)"
  INFO_AUDIO="$(sa_audio_order_text)"
}

sa_stream_detail() {
  local i="$1" type extra="" a_n="$2"
  type="${ST_TYPE[$i],,}"
  case "$type" in
    audio)
      extra="audio ${a_n}"
      [[ -n "${ST_CH[$i]}" ]] && extra+="  ${ST_CH[$i]}ch"
      [[ -n "${ST_RATE[$i]}" ]] && extra+="  ${ST_RATE[$i]} Hz"
      [[ -n "${ST_LANG[$i]}" ]] && extra+="  lang=${ST_LANG[$i]}"
      [[ -n "${ST_TITLE[$i]}" ]] && extra+="  ${ST_TITLE[$i]}"
      [[ "${ST_DEF[$i]}" == 1 ]] && extra+="  default"
      ;;
    video)
      extra="${ST_WH[$i]}"
      [[ -n "${ST_FPS[$i]}" ]] && extra+="${extra:+  }${ST_FPS[$i]}"
      [[ -n "${ST_HANDLER[$i]}" ]] && extra+="${extra:+  }${ST_HANDLER[$i]}"
      ;;
    subtitle)
      extra=""
      [[ -n "${ST_LANG[$i]}" ]] && extra="lang=${ST_LANG[$i]}"
      [[ -n "${ST_TITLE[$i]}" ]] && extra+="${extra:+  }${ST_TITLE[$i]}"
      [[ "${ST_DEF[$i]}" == 1 ]] && extra+="${extra:+  }default"
      ;;
    *)
      extra="${ST_TAG[$i]}"
      [[ -n "${ST_HANDLER[$i]}" ]] && extra+="${extra:+  }${ST_HANDLER[$i]}"
      ;;
  esac
  extra="${extra#"${extra%%[![:space:]]*}"}"
  extra="${extra%"${extra##*[![:space:]]}"}"
  printf '%s' "$extra"
}

sa_print_facts() {
  printf '  %s' "$(sa_dash "$INFO_SIZE")"
  [[ -n "$INFO_DUR" ]] && printf '  %s' "$INFO_DUR"
  [[ -n "$INFO_THRU" ]] && printf '  %s' "$INFO_THRU"
  [[ -n "$INFO_CREATED" ]] && printf '  created %s' "$INFO_CREATED"
  [[ -n "$INFO_MTIME" ]] && printf '  mtime %s' "$INFO_MTIME"
  echo
}

sa_count_type() {
  local want="$1" i n=0
  for i in "${!ST_IDX[@]}"; do
    [[ "${ST_TYPE[$i],,}" == "$want" ]] && (( n++ )) || true
  done
  printf '%s' "$n"
}

sa_has_tmcd() {
  local i
  for i in "${!ST_IDX[@]}"; do
    [[ "${ST_TAG[$i],,}" == tmcd || "${ST_HANDLER[$i]}" == *TCD* ]] && return 0
  done
  return 1
}

sa_other_data_n() {
  local i n=0 type
  for i in "${!ST_IDX[@]}"; do
    type="${ST_TYPE[$i],,}"
    case "$type" in
      video|audio|subtitle) continue ;;
    esac
    (( n++ )) || true
  done
  printf '%s' "$n"
}

sa_stream_fate() {
  local i="$1"
  if sa_stream_unmappable_mp4 "${ST_TYPE[$i]}" "${ST_CODEC[$i]}" "${ST_TAG[$i]}" "${ST_HANDLER[$i]}"; then
    printf 'present, cannot decode / cannot copy into MP4'
    return 0
  fi
  if [[ "${ST_CODEC[$i],,}" == none || "${ST_TYPE[$i],,}" == unknown ]]; then
    printf 'present, cannot decode (copied if the muxer allows it)'
    return 0
  fi
  printf 'present, copied'
}

sa_audio_verbose_line() {
  local i="$1" a_n="$2" bits
  bits="#${ST_IDX[$i]}  ${ST_CODEC[$i]:-?}"
  [[ -n "${ST_CH[$i]}" ]] && bits+="  ${ST_CH[$i]}ch"
  [[ -n "${ST_RATE[$i]}" ]] && bits+="  ${ST_RATE[$i]} Hz"
  [[ -n "${ST_BR[$i]}" ]] && bits+="  ${ST_BR[$i]}"
  [[ -n "${ST_LANG[$i]}" ]] && bits+="  ${ST_LANG[$i]}"
  [[ -n "${ST_TITLE[$i]}" ]] && bits+="  ${ST_TITLE[$i]}"
  [[ "${ST_DEF[$i]}" == 1 ]] && bits+="  default"
  printf '  A%s  %s\n' "$a_n" "$bits"
}

sa_print_verbose() {
  local i type a_n=0 def_n="—" gps_bit tel_bit tmcd_bit vid_bit sub_bits=""
  local audio_n video_n sub_n data_n ch_n
  audio_n="$(sa_count_type audio)"
  video_n="$(sa_count_type video)"
  sub_n="$(sa_count_type subtitle)"
  data_n="$(sa_other_data_n)"
  ch_n="${INFO_CHAPTERS:-0}"
  for i in "${!ST_IDX[@]}"; do
    [[ "${ST_TYPE[$i],,}" == audio ]] || continue
    (( a_n++ )) || true
    [[ "${ST_DEF[$i]}" == 1 ]] && def_n="$a_n"
  done
  a_n=0
  if [[ -n "$INFO_GPS" ]]; then
    gps_bit="yes"
  else
    gps_bit="no"
  fi
  if [[ "${INFO_GOPRO}" == no || -z "$INFO_GOPRO" ]]; then
    tel_bit="no"
  else
    tel_bit="${INFO_GOPRO}"
  fi
  if sa_has_tmcd; then
    tmcd_bit="yes"
  else
    tmcd_bit="no"
  fi
  if (( video_n > 0 )); then vid_bit=yes; else vid_bit=no; fi
  sa_print_facts
  printf '  video %s  audio %s  subs %s  chapters %s  GPS %s  GoPro %s  tmcd %s' \
    "$vid_bit" "$audio_n" "$sub_n" "$ch_n" "$gps_bit" "$tel_bit" "$tmcd_bit"
  (( data_n > 0 )) && printf '  other %s' "$data_n"
  echo
  if (( audio_n == 0 )); then
    echo "  A   none"
  else
    for i in "${!ST_IDX[@]}"; do
      [[ "${ST_TYPE[$i],,}" == audio ]] || continue
      (( a_n++ )) || true
      sa_audio_verbose_line "$i" "$a_n"
    done
  fi
  if (( video_n == 0 )); then
    echo "  V   none"
  else
    for i in "${!ST_IDX[@]}"; do
      [[ "${ST_TYPE[$i],,}" == video ]] || continue
      printf '  V   #%s  %s' "${ST_IDX[$i]}" "${ST_CODEC[$i]:-?}"
      [[ -n "${ST_WH[$i]}" ]] && printf '  %s' "${ST_WH[$i]}"
      [[ -n "${ST_FPS[$i]}" ]] && printf '  %s' "${ST_FPS[$i]}"
      [[ -n "${ST_BR[$i]}" ]] && printf '  %s' "${ST_BR[$i]}"
      echo
    done
  fi
  for i in "${!ST_IDX[@]}"; do
    type="${ST_TYPE[$i],,}"
    case "$type" in
      subtitle)
        sub_bits+="  #${ST_IDX[$i]} ${ST_CODEC[$i]:-sub} ${ST_LANG[$i]:-?}"
        [[ "${ST_DEF[$i]}" == 1 ]] && sub_bits+=" default"
        ;;
      video|audio) continue ;;
      *)
        printf '  D   #%s  %s  %s' "${ST_IDX[$i]}" "${ST_TYPE[$i]:-data}" "${ST_CODEC[$i]:-${ST_TAG[$i]:-?}}"
        [[ -n "${ST_LANG[$i]}" ]] && printf '  %s' "${ST_LANG[$i]}"
        printf '  (%s)\n' "$(sa_stream_fate "$i")"
        ;;
    esac
  done
  if (( sub_n > 0 )); then
    printf '  S  %s\n' "${sub_bits#  }"
  fi
}

sa_print_stream_table() {
  local i n type codec detail a_n=0
  n=${#ST_IDX[@]}
  printf '  %-3s %-9s %-8s %s\n' "#" "Type" "Codec" "Detail"
  if (( n == 0 )); then
    echo "  (no streams)"
    return 0
  fi
  for (( i = 0; i < n; i++ )); do
    type="${ST_TYPE[$i]:-?}"
    codec="${ST_CODEC[$i]:-${ST_TAG[$i]:-?}}"
    if [[ "${type,,}" == audio ]]; then
      (( a_n++ )) || true
    fi
    detail="$(sa_stream_detail "$i" "$a_n")"
    printf '  %-3s %-9s %-8s %s\n' "${ST_IDX[$i]}" "$type" "$codec" "$detail"
  done
}

sa_print_audio_plan() {
  local now after spec="${1:-}" sub_now sub_after
  now="$(sa_audio_order_text)"
  printf '  audio %s' "$now"
  if [[ -n "$spec" ]]; then
    after="$(sa_audio_order_after "$spec")"
    printf '  ->  %s' "$after"
  fi
  if (( ${#DROP_FAMS[@]} > 0 )); then
    printf '  drop %s' "$(sa_join_labels "${DROP_FAMS[@]}")"
  fi
  echo
  if (( SWAP_SUBS )); then
    sa_fill_kept_streams
    if (( ${#KEPT_SUBTITLE_ST[@]} == 0 && ${#SUBTITLE_ST[@]} == 0 )); then
      printf '  subs  none\n'
    elif (( ${#KEPT_SUBTITLE_ST[@]} == 0 )); then
      printf '  subs  all dropped\n'
    elif [[ -n "$spec" ]] && sub_after="$(sa_subtitle_perm "$spec")"; then
      sub_now="$(sa_subtitle_order_text)"
      printf '  subs  %s  ->  %s\n' "$sub_now" "$(sa_subtitle_order_after "$sub_after")"
    else
      printf '  subs  as they are\n'
    fi
  fi
}

sa_audio_order_after() {
  local spec="$1" expanded i slot idx lang a_n=0 nums="" langs=""
  local -a slots=() audio_ref=()
  sa_fill_kept_streams
  audio_ref=("${KEPT_AUDIO_ST[@]+"${KEPT_AUDIO_ST[@]}"}")
  (( ${#audio_ref[@]} )) || { printf '—'; return 0; }
  expanded=$(sa_expand_slots "${#audio_ref[@]}" "$spec") || { printf '—'; return 0; }
  IFS=',' read -r -a slots <<< "$expanded"
  for slot in "${slots[@]}"; do
    idx="${audio_ref[$((10#$slot - 1))]}"
    (( a_n++ )) || true
    lang="?"
    for i in "${!ST_IDX[@]}"; do
      [[ "${ST_IDX[$i]}" == "$idx" ]] || continue
      lang="${ST_LANG[$i]:-?}"
      (( a_n == 1 )) && lang+=" default"
      break
    done
    if [[ -n "$nums" ]]; then
      nums+=", ${a_n}"
      langs+=", ${lang}"
    else
      nums="${a_n}"
      langs="${lang}"
    fi
  done
  printf '%s  (%s)' "$nums" "$langs"
}

sa_lang_key() {
  local s="${1,,}"
  s="${s//$'\r'/}"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  case "$s" in
    ""|und|unk|none) printf '' ;;
    *) printf '%s' "$s" ;;
  esac
}

sa_lang_family() {
  local k
  k="$(sa_lang_key "$1")"
  [[ -n "$k" ]] || { printf ''; return 0; }
  case "$k" in
    eng|en|en-us|en-gb|en-au|english|american) printf 'eng' ;;
    pol|pl|pl-pl|polish) printf 'pol' ;;
    ger|deu|de|de-de|de-at|german) printf 'deu' ;;
    rus|ru|ru-ru|russian) printf 'rus' ;;
    ukr|uk|uk-ua|ukrainian) printf 'ukr' ;;
    spa|es|es-es|es-mx|spanish) printf 'spa' ;;
    fra|fre|fr|fr-fr|french) printf 'fra' ;;
    ita|it|it-it|italian) printf 'ita' ;;
    por|pt|pt-pt|pt-br|portuguese) printf 'por' ;;
    nld|dut|nl|dutch) printf 'nld' ;;
    ces|cze|cs|czech) printf 'ces' ;;
    slk|slo|sk|slovak) printf 'slk' ;;
    hun|hu|hungarian) printf 'hun' ;;
    ron|rum|ro|romanian) printf 'ron' ;;
    bul|bg|bulgarian) printf 'bul' ;;
    hrv|hr|croatian) printf 'hrv' ;;
    srp|sr|serbian) printf 'srp' ;;
    slv|sl|slovenian) printf 'slv' ;;
    ell|gre|el|greek) printf 'ell' ;;
    tur|tr|turkish) printf 'tur' ;;
    swe|sv|swedish) printf 'swe' ;;
    nor|nob|nno|no|norwegian) printf 'nor' ;;
    dan|da|danish) printf 'dan' ;;
    fin|fi|finnish) printf 'fin' ;;
    est|et|estonian) printf 'est' ;;
    lav|lv|latvian) printf 'lav' ;;
    lit|lt|lithuanian) printf 'lit' ;;
    jpn|ja|japanese) printf 'jpn' ;;
    kor|ko|korean) printf 'kor' ;;
    zho|chi|zh|zh-cn|zh-tw|chinese) printf 'zho' ;;
    ara|ar|arabic) printf 'ara' ;;
    heb|he|iw|hebrew) printf 'heb' ;;
    hin|hi|hindi) printf 'hin' ;;
    tha|th|thai) printf 'tha' ;;
    vie|vi|vietnamese) printf 'vie' ;;
    cat|ca|catalan) printf 'cat' ;;
    *) printf '%s' "$k" ;;
  esac
}

sa_lang_label() {
  case "$1" in
    eng) printf 'English' ;;
    pol) printf 'Polish' ;;
    deu) printf 'German' ;;
    rus) printf 'Russian' ;;
    ukr) printf 'Ukrainian' ;;
    spa) printf 'Spanish' ;;
    fra) printf 'French' ;;
    ita) printf 'Italian' ;;
    por) printf 'Portuguese' ;;
    nld) printf 'Dutch' ;;
    ces) printf 'Czech' ;;
    slk) printf 'Slovak' ;;
    hun) printf 'Hungarian' ;;
    ron) printf 'Romanian' ;;
    bul) printf 'Bulgarian' ;;
    hrv) printf 'Croatian' ;;
    srp) printf 'Serbian' ;;
    slv) printf 'Slovenian' ;;
    ell) printf 'Greek' ;;
    tur) printf 'Turkish' ;;
    swe) printf 'Swedish' ;;
    nor) printf 'Norwegian' ;;
    dan) printf 'Danish' ;;
    fin) printf 'Finnish' ;;
    est) printf 'Estonian' ;;
    lav) printf 'Latvian' ;;
    lit) printf 'Lithuanian' ;;
    jpn) printf 'Japanese' ;;
    kor) printf 'Korean' ;;
    zho) printf 'Chinese' ;;
    ara) printf 'Arabic' ;;
    heb) printf 'Hebrew' ;;
    hin) printf 'Hindi' ;;
    tha) printf 'Thai' ;;
    vie) printf 'Vietnamese' ;;
    cat) printf 'Catalan' ;;
    ""|-) printf 'unknown' ;;
    *) printf '%s' "$1" ;;
  esac
}

sa_lang_is_keep() {
  case "$1" in eng|pol|deu) return 0 ;; *) return 1 ;; esac
}

sa_lang_is_dropped() {
  local fam="$1" d
  [[ -n "$fam" && "$fam" != "-" ]] || return 1
  for d in "${DROP_FAMS[@]+"${DROP_FAMS[@]}"}"; do
    [[ "$d" == "$fam" ]] && return 0
  done
  return 1
}

sa_join_labels() {
  local out="" fam lab
  for fam in "$@"; do
    [[ -n "$fam" ]] || continue
    lab="$(sa_lang_label "$fam")"
    if [[ -z "$out" ]]; then
      out="$lab"
    else
      out+=", $lab"
    fi
  done
  printf '%s' "$out"
}

sa_stream_family_of_idx() {
  local want="$1" i
  for i in "${!ST_IDX[@]}"; do
    [[ "${ST_IDX[$i]}" == "$want" ]] || continue
    sa_lang_family "${ST_LANG[$i]}"
    return 0
  done
  printf ''
}

sa_idx_in_list() {
  local want="$1" x
  shift
  for x in "$@"; do
    [[ "$x" == "$want" ]] && return 0
  done
  return 1
}

sa_csv_fams() {
  local idx fam out=""
  for idx in "$@"; do
    fam="$(sa_stream_family_of_idx "$idx")"
    [[ -n "$fam" ]] || fam="-"
    if [[ -z "$out" ]]; then
      out="$fam"
    else
      out+=",$fam"
    fi
  done
  printf '%s' "$out"
}

sa_kept_count_csv() {
  local csv="$1" fam n=0
  local -a parts=()
  [[ -n "$csv" ]] || { printf '0'; return 0; }
  IFS=',' read -r -a parts <<< "$csv"
  for fam in "${parts[@]}"; do
    sa_lang_is_dropped "$fam" && continue
    (( n++ )) || true
  done
  printf '%s' "$n"
}

sa_drop_count_csv() {
  local csv="$1" fam n=0
  local -a parts=()
  [[ -n "$csv" ]] || { printf '0'; return 0; }
  IFS=',' read -r -a parts <<< "$csv"
  for fam in "${parts[@]}"; do
    sa_lang_is_dropped "$fam" || continue
    (( n++ )) || true
  done
  printf '%s' "$n"
}

sa_fill_kept_streams() {
  local idx fam
  KEPT_AUDIO_ST=()
  KEPT_SUBTITLE_ST=()
  for idx in "${AUDIO_ST[@]+"${AUDIO_ST[@]}"}"; do
    fam="$(sa_stream_family_of_idx "$idx")"
    sa_lang_is_dropped "$fam" && continue
    KEPT_AUDIO_ST+=("$idx")
  done
  if (( ${#KEPT_AUDIO_ST[@]} == 0 && ${#AUDIO_ST[@]} > 0 )); then
    KEPT_AUDIO_ST=("${AUDIO_ST[@]}")
  fi
  for idx in "${SUBTITLE_ST[@]+"${SUBTITLE_ST[@]}"}"; do
    fam="$(sa_stream_family_of_idx "$idx")"
    sa_lang_is_dropped "$fam" && continue
    KEPT_SUBTITLE_ST+=("$idx")
  done
}

sa_collect_all_fams() {
  local i csv fam
  local -A seen=()
  ALL_FAMS=()
  for i in "${!FILES[@]}"; do
    csv="${FILE_AUDIO_FAMS[$i]},${FILE_SUB_FAMS[$i]}"
    csv="${csv#,}"
    csv="${csv%,}"
    [[ "$csv" == "," ]] && csv=""
    local -a parts=()
    IFS=',' read -r -a parts <<< "$csv"
    for fam in "${parts[@]}"; do
      [[ -n "$fam" && "$fam" != "-" ]] || continue
      [[ -n "${seen[$fam]+x}" ]] && continue
      seen[$fam]=1
      ALL_FAMS+=("$fam")
    done
  done
}

sa_extra_fams() {
  local fam
  EXTRA_FAMS=()
  for fam in "${ALL_FAMS[@]+"${ALL_FAMS[@]}"}"; do
    sa_lang_is_keep "$fam" && continue
    EXTRA_FAMS+=("$fam")
  done
}

sa_parse_lang_token() {
  sa_lang_family "$1"
}

sa_stream_lang_of_idx() {
  local want="$1" i
  for i in "${!ST_IDX[@]}"; do
    [[ "${ST_IDX[$i]}" == "$want" ]] || continue
    sa_lang_key "${ST_LANG[$i]}"
    return 0
  done
  printf ''
}

# 1-based subtitle permutation that follows the audio-slot list by language.
# Unmatched subtitle tracks keep their old relative order at the end.
sa_subtitle_perm() {
  local audio_csv="$1"
  local -a a_slots=() used=() out=() audio_ref=() sub_ref=()
  local n_sub s slot lang sub_lang matched=0 i
  sa_fill_kept_streams
  audio_ref=("${KEPT_AUDIO_ST[@]+"${KEPT_AUDIO_ST[@]}"}")
  sub_ref=("${KEPT_SUBTITLE_ST[@]+"${KEPT_SUBTITLE_ST[@]}"}")
  n_sub=${#sub_ref[@]}
  (( SWAP_SUBS )) || return 1
  (( n_sub >= 1 )) || return 1
  IFS=',' read -r -a a_slots <<< "$audio_csv"
  for (( s = 1; s <= n_sub; s++ )); do
    used[$s]=0
  done
  for slot in "${a_slots[@]}"; do
    [[ "$slot" =~ ^[0-9]+$ ]] || return 1
    lang="$(sa_stream_family_of_idx "${audio_ref[$((10#$slot - 1))]:-}")"
    [[ -n "$lang" ]] || continue
    for (( s = 1; s <= n_sub; s++ )); do
      (( used[s] )) && continue
      sub_lang="$(sa_stream_family_of_idx "${sub_ref[$((s - 1))]}")"
      [[ "$sub_lang" == "$lang" ]] || continue
      used[$s]=1
      out+=("$s")
      (( matched++ )) || true
      break
    done
  done
  (( matched >= 1 )) || return 1
  for (( s = 1; s <= n_sub; s++ )); do
    (( used[s] )) && continue
    out+=("$s")
  done
  (( ${#out[@]} == n_sub )) || return 1
  printf '%s' "${out[0]}"
  for (( i = 1; i < n_sub; i++ )); do
    printf ',%s' "${out[$i]}"
  done
  printf '\n'
}

sa_subtitle_order_text() {
  local i idx lang a_n=0 nums="" langs=""
  for i in "${!ST_IDX[@]}"; do
    [[ "${ST_TYPE[$i],,}" == subtitle ]] || continue
    (( a_n++ )) || true
    idx="${ST_IDX[$i]}"
    lang="${ST_LANG[$i]:-?}"
    [[ "${ST_DEF[$i]}" == 1 ]] && lang+=" default"
    if [[ -n "$nums" ]]; then
      nums+=", ${a_n}"
      langs+=", ${lang}"
    else
      nums="${a_n}"
      langs="${lang}"
    fi
  done
  if (( a_n == 0 )); then
    printf '—'
    return 0
  fi
  printf '%s  (%s)' "$nums" "$langs"
}

sa_subtitle_order_after() {
  local spec="$1" i slot idx lang a_n=0 nums="" langs=""
  local -a slots=() sub_ref=()
  sa_fill_kept_streams
  sub_ref=("${KEPT_SUBTITLE_ST[@]+"${KEPT_SUBTITLE_ST[@]}"}")
  (( ${#sub_ref[@]} )) || { printf '—'; return 0; }
  IFS=',' read -r -a slots <<< "$spec"
  for slot in "${slots[@]}"; do
    idx="${sub_ref[$((10#$slot - 1))]}"
    (( a_n++ )) || true
    lang="?"
    for i in "${!ST_IDX[@]}"; do
      [[ "${ST_IDX[$i]}" == "$idx" ]] || continue
      lang="${ST_LANG[$i]:-?}"
      (( a_n == 1 )) && lang+=" default"
      break
    done
    if [[ -n "$nums" ]]; then
      nums+=", ${a_n}"
      langs+=", ${lang}"
    else
      nums="${a_n}"
      langs="${lang}"
    fi
  done
  printf '%s  (%s)' "$nums" "$langs"
}

sa_mark_cell() {
  local left="$1" right="$2" width="$3"
  if [[ "$left" == "$right" ]]; then
    printf '%-*s' "$width" "$(sa_trunc "$right" "$width")"
  else
    printf '%-*s' "$width" "$(sa_trunc "* ${right}" "$width")"
  fi
}

sa_print_compare() {
  local -n L_IDX=$1 L_TYPE=$2 L_CODEC=$3 L_DET=$4
  local -n R_IDX=$5 R_TYPE=$6 R_CODEC=$7 R_DET=$8
  local lw=42 i n ln rn idx type left right
  echo
  printf '                    %-42s  %s\n' "INPUT" "OUTPUT"
  printf '  %-18s  %-42s  %s\n' "File" "$(sa_trunc "$(sa_dash "$IN_FILE")" "$lw")" "$(sa_mark_cell "$IN_FILE" "$OUT_FILE" "$lw")"
  printf '  %-18s  %-42s  %s\n' "Size" "$(sa_trunc "$(sa_dash "$IN_SIZE")" "$lw")" "$(sa_mark_cell "$IN_SIZE" "$OUT_SIZE" "$lw")"
  printf '  %-18s  %-42s  %s\n' "Duration" "$(sa_trunc "$(sa_dash "$IN_DUR")" "$lw")" "$(sa_mark_cell "$IN_DUR" "$OUT_DUR" "$lw")"
  printf '  %-18s  %-42s  %s\n' "Created" "$(sa_trunc "$(sa_dash "$IN_CREATED")" "$lw")" "$(sa_mark_cell "$IN_CREATED" "$OUT_CREATED" "$lw")"
  printf '  %-18s  %-42s  %s\n' "File time" "$(sa_trunc "$(sa_dash "$IN_MTIME")" "$lw")" "$(sa_mark_cell "$IN_MTIME" "$OUT_MTIME" "$lw")"
  printf '  %-18s  %-42s  %s\n' "GPS" "$(sa_trunc "$(sa_dash "$IN_GPS")" "$lw")" "$(sa_mark_cell "$IN_GPS" "$OUT_GPS" "$lw")"
  printf '  %-18s  %-42s  %s\n' "Chapters" "$(sa_trunc "$(sa_dash "$IN_CHAPTERS")" "$lw")" "$(sa_mark_cell "$IN_CHAPTERS" "$OUT_CHAPTERS" "$lw")"
  printf '  %-18s  %-42s  %s\n' "GoPro telemetry" "$(sa_trunc "$(sa_dash "$IN_GOPRO")" "$lw")" "$(sa_mark_cell "$IN_GOPRO" "$OUT_GOPRO" "$lw")"
  echo
  printf '  %-3s %-6s %-42s  %s\n' "#" "Type" "INPUT" "OUTPUT"
  printf '  %-3s %-6s %-42s  %s\n' "--" "------" "------------------------------------------" "------------------------------------------"
  ln=${#L_IDX[@]}
  rn=${#R_IDX[@]}
  n=$ln
  (( rn > n )) && n=$rn
  for (( i = 0; i < n; i++ )); do
    if (( i < ln )); then
      idx="${L_IDX[$i]}"
      type="${L_TYPE[$i]}"
      left="${L_CODEC[$i]}  ${L_DET[$i]}"
    else
      idx=""
      type=""
      left="—"
    fi
    if (( i < rn )); then
      [[ -z "$idx" ]] && idx="${R_IDX[$i]}"
      [[ -z "$type" ]] && type="${R_TYPE[$i]}"
      right="${R_CODEC[$i]}  ${R_DET[$i]}"
    else
      right="—"
    fi
    left="${left%"${left##*[![:space:]]}"}"
    right="${right%"${right##*[![:space:]]}"}"
    printf '  %-3s %-6s %-42s  %s\n' "$idx" "$type" "$(sa_trunc "$left" "$lw")" "$(sa_mark_cell "$left" "$right" "$lw")"
  done
  echo
  printf '  %-18s  %-42s  %s\n' "Audio order" "$(sa_trunc "$(sa_dash "$IN_AUDIO")" "$lw")" "$(sa_mark_cell "$IN_AUDIO" "$OUT_AUDIO" "$lw")"
}

sa_copy_stream_snapshot() {
  local prefix="$1" i n a_n=0 detail
  n=${#ST_IDX[@]}
  eval "${prefix}_IDX=()"
  eval "${prefix}_TYPE=()"
  eval "${prefix}_CODEC=()"
  eval "${prefix}_DET=()"
  for (( i = 0; i < n; i++ )); do
    if [[ "${ST_TYPE[$i],,}" == audio ]]; then
      (( a_n++ )) || true
    fi
    detail="$(sa_stream_detail "$i" "$a_n")"
    eval "${prefix}_IDX+=(\"\${ST_IDX[$i]}\")"
    eval "${prefix}_TYPE+=(\"\${ST_TYPE[$i]}\")"
    eval "${prefix}_CODEC+=(\"\${ST_CODEC[$i]:-\${ST_TAG[$i]:-?}}\")"
    eval "${prefix}_DET+=(\"\$detail\")"
  done
}

sa_store_info_as() {
  local prefix="$1"
  eval "${prefix}_FILE=\"\$INFO_FILE\""
  eval "${prefix}_SIZE=\"\$INFO_SIZE\""
  eval "${prefix}_DUR=\"\$INFO_DUR\""
  eval "${prefix}_CREATED=\"\$INFO_CREATED\""
  eval "${prefix}_MTIME=\"\$INFO_MTIME\""
  eval "${prefix}_GPS=\"\$INFO_GPS\""
  eval "${prefix}_CHAPTERS=\"\$INFO_CHAPTERS\""
  eval "${prefix}_GOPRO=\"\$INFO_GOPRO\""
  eval "${prefix}_AUDIO=\"\$INFO_AUDIO\""
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

sa_backup_path() {
  local src="$1" dir base stem ext
  dir="$(dirname -- "$src")"
  base="${src##*/}"
  if [[ "$base" == *.* ]]; then
    ext="${base##*.}"
    stem="${base%.*}"
    if [[ "$dir" == . ]]; then
      printf '%s-backup.%s\n' "$stem" "$ext"
    else
      printf '%s/%s-backup.%s\n' "$dir" "$stem" "$ext"
    fi
  else
    if [[ "$dir" == . ]]; then
      printf '%s-backup\n' "$base"
    else
      printf '%s/%s-backup\n' "$dir" "$base"
    fi
  fi
}

sa_aside_restore() {
  [[ -n "${ASIDE_BACKUP:-}" && -n "${ASIDE_ORIG:-}" ]] || return 0
  if [[ -f "$ASIDE_BACKUP" && ! -e "$ASIDE_ORIG" ]]; then
    echo "$(sa_ts) Restoring original: ${ASIDE_BACKUP##*/} -> ${ASIDE_ORIG##*/}"
    mv -f -- "$ASIDE_BACKUP" "$ASIDE_ORIG" 2>/dev/null || true
  fi
  ASIDE_BACKUP=""
  ASIDE_ORIG=""
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

# Map remaining streams in original slot order; audio (and matching subtitles) take the permuted sources.
sa_build_map_args() {
  local src="$1" dest="$2" slot_csv="$3"
  local -n out_map=$4
  local -n out_note=$5
  local -n out_disp=$6
  local i type idx slot src_idx mp4=0 skipped="" sub_csv="" do_sub=0 a_out=0 s_out=0
  local -a slots=() audio_src=() sub_slots=() sub_src=() audio_ref=() sub_ref=()
  out_map=()
  out_note=""
  out_disp=()
  sa_fill_kept_streams
  audio_ref=("${KEPT_AUDIO_ST[@]+"${KEPT_AUDIO_ST[@]}"}")
  sub_ref=("${KEPT_SUBTITLE_ST[@]+"${KEPT_SUBTITLE_ST[@]}"}")
  sa_is_mp4_family "$dest" && mp4=1
  (( mp4 == 0 )) && sa_is_mp4_family "$src" && mp4=1
  (( ${#audio_ref[@]} >= 1 )) || return 1
  IFS=',' read -r -a slots <<< "$slot_csv"
  (( ${#slots[@]} == ${#audio_ref[@]} )) || return 1
  for slot in "${slots[@]}"; do
    audio_src+=("${audio_ref[$((10#$slot - 1))]}")
  done
  if sub_csv=$(sa_subtitle_perm "$slot_csv"); then
    do_sub=1
    IFS=',' read -r -a sub_slots <<< "$sub_csv"
    (( ${#sub_slots[@]} == ${#sub_ref[@]} )) || return 1
    for slot in "${sub_slots[@]}"; do
      sub_src+=("${sub_ref[$((10#$slot - 1))]}")
    done
  fi
  (( mp4 )) && out_map+=(-copy_unknown)
  slot=0
  local sub_i=0
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
      sa_idx_in_list "$idx" "${audio_ref[@]+"${audio_ref[@]}"}" || continue
      src_idx="${audio_src[$slot]}"
      (( slot++ )) || true
      out_map+=(-map "0:${src_idx}")
      (( a_out++ )) || true
    elif [[ "$type" == subtitle ]]; then
      sa_idx_in_list "$idx" "${sub_ref[@]+"${sub_ref[@]}"}" || continue
      if (( do_sub )); then
        src_idx="${sub_src[$sub_i]}"
        (( sub_i++ )) || true
        out_map+=(-map "0:${src_idx}")
      else
        out_map+=(-map "0:${idx}")
      fi
      (( s_out++ )) || true
    else
      out_map+=(-map "0:${idx}")
    fi
  done
  if (( a_out > 0 )); then
    out_disp+=(-disposition:a:0 default)
    for (( i = 1; i < a_out; i++ )); do
      out_disp+=(-disposition:a:"$i" 0)
    done
  fi
  if (( do_sub && s_out > 0 )); then
    out_disp+=(-disposition:s:0 default)
    for (( i = 1; i < s_out; i++ )); do
      out_disp+=(-disposition:s:"$i" 0)
    done
  fi
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
  local -a map_args=() disp_args=()
  tmp="$(sa_temp_path "$dest")"
  ref="$(mktemp)"
  log="$(mktemp)"
  touch -r "$src" -- "$ref" 2>/dev/null || true
  TMP_FILE="$tmp"
  sa_build_map_args "$src" "$dest" "$slot_csv" map_args note disp_args || {
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
    "${disp_args[@]}" \
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

sa_require_ffmpeg() {
  local have_ff=0 have_fp=0
  command -v ffmpeg >/dev/null 2>&1 && have_ff=1
  command -v ffprobe >/dev/null 2>&1 && have_fp=1
  (( have_ff && have_fp )) && return 0
  echo "ERROR: this script needs ffmpeg and ffprobe in PATH." >&2
  if (( have_ff )); then
    echo "  ffmpeg:  found" >&2
  else
    echo "  ffmpeg:  not found" >&2
  fi
  if (( have_fp )); then
    echo "  ffprobe: found" >&2
  else
    echo "  ffprobe: not found" >&2
  fi
  echo "Install the ffmpeg package (it includes both) and run again." >&2
  return_code=1
  exit 1
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

sa_ask_keep_copy() {
  if (( KEEP_SET )); then
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    KEEP_ORIGINAL=1
    return 0
  fi
  echo
  sa_print_question "Keep a copy of each original file?"
  echo "  [Y] Yes (default) — original becomes clip-backup.mp4; swapped file keeps the original name"
  echo "      If clip-backup.mp4 is already there, a dated copy is added and that file is left as it is"
  echo "  [n] No — replace the original with the swapped file"
  echo "  [q] Quit"
  sa_read_key "Keep a copy of the original? [Y/n/q]: " y "Yes — save original as clip-backup.mp4"
  case "$REPLY" in
    y)
      KEEP_ORIGINAL=1
      sa_print_selected "yes (original -> clip-backup.mp4; swapped file keeps the original name)"
      ;;
    n)
      KEEP_ORIGINAL=0
      sa_print_selected "no (replace the original)"
      ;;
    q) sa_quit ;;
    *) echo "$(sa_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
}

sa_apply_together() {
  TOGETHER=1
  REST_ORDER="$ORDER_SPEC"
}

sa_ask_together() {
  if (( TOGETHER_SET )); then
    (( TOGETHER )) && sa_apply_together
    return 0
  fi
  if (( DO_YES )); then
    sa_apply_together
    return 0
  fi
  if (( ! script_is_run_interactively )); then
    return 0
  fi
  echo
  sa_print_question "Ask about each file, or swap them all the same way?"
  echo "  [O] One by one (default)"
  echo "  [t] Together — same audio order for every file"
  echo "  [q] Quit"
  sa_read_key "Ask file by file? [O/t/q]: " o "One by one"
  case "$REPLY" in
    o)
      TOGETHER=0
      sa_print_selected "one by one"
      ;;
    t)
      sa_apply_together
      sa_print_selected "together (same order for every file)"
      ;;
    q) sa_quit ;;
    *) echo "$(sa_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
}

sa_ask_subtitles() {
  if (( SUBS_SET )); then
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    SWAP_SUBS=1
    return 0
  fi
  echo
  sa_print_question "Also swap subtitle tracks to the same languages as the audio?"
  echo "  [Y] Yes (default) — Italian audio with Italian subtitles, and so on"
  echo "  [n] No — leave subtitle order as it is"
  echo "  [q] Quit"
  sa_read_key "Swap matching subtitles? [Y/n/q]: " y "Yes — same language order as audio"
  case "$REPLY" in
    y)
      SWAP_SUBS=1
      sa_print_selected "yes (subtitles follow the audio languages; first subtitle becomes default)"
      ;;
    n)
      SWAP_SUBS=0
      sa_print_selected "no (leave subtitle order as it is)"
      ;;
    q) sa_quit ;;
    *) echo "$(sa_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
}

sa_set_drop_from_extras() {
  sa_collect_all_fams
  sa_extra_fams
  DROP_FAMS=("${EXTRA_FAMS[@]+"${EXTRA_FAMS[@]}"}")
}

sa_set_drop_from_spec() {
  local tok fam
  local -a parts=()
  DROP_FAMS=()
  IFS=',' read -r -a parts <<< "$1"
  for tok in "${parts[@]}"; do
    tok="${tok// /}"
    [[ -n "$tok" ]] || continue
    fam="$(sa_parse_lang_token "$tok")"
    [[ -n "$fam" ]] || continue
    sa_idx_in_list "$fam" "${DROP_FAMS[@]+"${DROP_FAMS[@]}"}" && continue
    DROP_FAMS+=("$fam")
  done
}

sa_build_lang_menu() {
  local fam
  LANG_MENU_FAM=()
  sa_collect_all_fams
  for fam in eng pol deu; do
    sa_idx_in_list "$fam" "${ALL_FAMS[@]+"${ALL_FAMS[@]}"}" || continue
    LANG_MENU_FAM+=("$fam")
  done
  for fam in "${ALL_FAMS[@]+"${ALL_FAMS[@]}"}"; do
    sa_lang_is_keep "$fam" && continue
    LANG_MENU_FAM+=("$fam")
  done
}

sa_choose_drop_langs() {
  local i fam typed="" def="" tok k
  local -a parts=() chosen=()
  sa_build_lang_menu
  (( ${#LANG_MENU_FAM[@]} )) || return 1
  echo
  echo "  Languages in these files:"
  for i in "${!LANG_MENU_FAM[@]}"; do
    fam="${LANG_MENU_FAM[$i]}"
    if sa_lang_is_keep "$fam"; then
      printf '    %s  %-12s  keep\n' "$((i + 1))" "$(sa_lang_label "$fam")"
    else
      printf '    %s  %s\n' "$((i + 1))" "$(sa_lang_label "$fam")"
      if [[ -n "$def" ]]; then
        def+=",$((i + 1))"
      else
        def="$((i + 1))"
      fi
    fi
  done
  [[ -n "$def" ]] || def=""
  echo
  printf '  Numbers to drop, comma-separated [%s]: ' "$def"
  sa_flush_stdin
  IFS= read -r typed || sa_quit
  typed="${typed// /}"
  [[ -z "$typed" ]] && typed="$def"
  if [[ -z "$typed" ]]; then
    DROP_FAMS=()
    return 0
  fi
  IFS=',' read -r -a parts <<< "$typed"
  DROP_FAMS=()
  for tok in "${parts[@]}"; do
    [[ "$tok" =~ ^[0-9]+$ ]] || return 1
    k=$((10#$tok))
    (( k >= 1 && k <= ${#LANG_MENU_FAM[@]} )) || return 1
    fam="${LANG_MENU_FAM[$((k - 1))]}"
    sa_idx_in_list "$fam" "${DROP_FAMS[@]+"${DROP_FAMS[@]}"}" && continue
    DROP_FAMS+=("$fam")
  done
  return 0
}

sa_ask_languages() {
  local extra_txt
  sa_collect_all_fams
  sa_extra_fams
  if (( LANGS_SET )); then
    case "$LANGS_MODE" in
      all) DROP_FAMS=() ;;
      drop) sa_set_drop_from_spec "$DROP_SPEC" ;;
      *) sa_set_drop_from_extras ;;
    esac
    return 0
  fi
  if (( ${#EXTRA_FAMS[@]} == 0 )); then
    DROP_FAMS=()
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    sa_set_drop_from_extras
    return 0
  fi
  extra_txt="$(sa_join_labels "${EXTRA_FAMS[@]}")"
  echo
  echo "These videos also have ${extra_txt}"
  echo "  (audio and/or subtitles)."
  echo
  sa_print_question "Leave only English, Polish and German?"
  echo "  [Y] Yes (default) — drop ${extra_txt}"
  echo "  [c] Choose which languages to drop (you can pick more than one)"
  echo "  [k] Keep every language"
  echo "  [q] Quit"
  sa_read_key "Leave English, Polish, German? [Y/c/k/q]: " y "Yes — drop ${extra_txt}"
  case "$REPLY" in
    y)
      sa_set_drop_from_extras
      sa_print_selected "yes (keep English, Polish, German; drop ${extra_txt})"
      ;;
    c)
      if sa_choose_drop_langs; then
        if (( ${#DROP_FAMS[@]} == 0 )); then
          sa_print_selected "keep every language"
        else
          sa_print_selected "drop $(sa_join_labels "${DROP_FAMS[@]}")"
        fi
      else
        echo "$(sa_ts) That is not a list of these languages. Keeping English, Polish, German."
        sa_set_drop_from_extras
      fi
      ;;
    k)
      DROP_FAMS=()
      sa_print_selected "keep every language"
      ;;
    q) sa_quit ;;
    *) echo "$(sa_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
}

sa_finalize_plan() {
  local i n kept drops_a drops_s expanded sub_csv
  SWAP_TOTAL=0
  for i in "${!FILES[@]}"; do
    n="${FILE_AUDIO_N[$i]}"
    FILE_SUB_NOTE[$i]=""
    if (( n == 0 )); then
      FILE_STATE[$i]=skip
      FILE_WHY[$i]="no audio track"
      continue
    fi
    kept="$(sa_kept_count_csv "${FILE_AUDIO_FAMS[$i]}")"
    drops_a="$(sa_drop_count_csv "${FILE_AUDIO_FAMS[$i]}")"
    drops_s="$(sa_drop_count_csv "${FILE_SUB_FAMS[$i]}")"
    if (( kept == 0 && n > 0 )); then
      kept="$n"
      drops_a=0
    fi
    if (( kept == 1 )); then
      expanded="1"
    elif ! expanded=$(sa_expand_slots "$kept" "$ORDER_SPEC"); then
      FILE_STATE[$i]=skip
      FILE_WHY[$i]="order ${ORDER_SPEC} does not fit ${kept} remaining audio tracks"
      continue
    fi
    if sa_slots_are_identity "$expanded" "$kept" && (( drops_a + drops_s == 0 )); then
      FILE_STATE[$i]=skip
      FILE_WHY[$i]="that order leaves the audio as it is"
      continue
    fi
    FILE_STATE[$i]=swap
    FILE_WHY[$i]="$expanded"
    (( SWAP_TOTAL++ )) || true
  done
}

sa_equivalent_cli() {
  local cmd out q_dir p drop_cli=""
  local -a parts=()
  cmd="$(basename -- "${BASH_SOURCE[0]:-$0}")"
  (( DO_YES )) && parts+=("--yes")
  (( DRY_RUN )) && parts+=("--dry-run")
  if [[ -n "$USE_COLORS" ]]; then
    parts+=("--colors" "$USE_COLORS")
  fi
  if (( KEEP_ORIGINAL )); then
    parts+=("--keep-original" "yes")
  else
    parts+=("--keep-original" "no")
  fi
  if (( TOGETHER )); then
    parts+=("--together")
  else
    parts+=("--one-by-one")
  fi
  if (( SWAP_SUBS )); then
    parts+=("--subtitles" "yes")
  else
    parts+=("--subtitles" "no")
  fi
  if (( ${#DROP_FAMS[@]} > 0 )); then
    drop_cli="$(IFS=','; printf '%s' "${DROP_FAMS[*]}")"
    parts+=("--drop" "$drop_cli")
  elif [[ "$LANGS_MODE" == all ]]; then
    parts+=("--languages" "all")
  else
    parts+=("--languages" "keep")
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
    echo "  -y/--yes:            given (swap without asking; an existing backup is kept, a dated copy is added)"
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
  if (( KEEP_SET )); then
    if (( KEEP_ORIGINAL )); then
      printf '  %-21s%s\n' "--keep-original:" "given (yes — original -> clip-backup.mp4)"
    else
      printf '  %-21s%s\n' "--keep-original:" "given (no — replace the original)"
    fi
  else
    if (( KEEP_ORIGINAL )); then
      printf '  %-21s%s\n' "--keep-original:" "yes (asked — original -> clip-backup.mp4)"
    else
      printf '  %-21s%s\n' "--keep-original:" "no (asked — replace the original)"
    fi
  fi
  if (( TOGETHER_SET )); then
    if (( TOGETHER )); then
      printf '  %-21s%s\n' "Files:" "together (given)"
    else
      printf '  %-21s%s\n' "Files:" "one by one (given)"
    fi
  else
    if (( TOGETHER )); then
      printf '  %-21s%s\n' "Files:" "together (asked)"
    else
      printf '  %-21s%s\n' "Files:" "one by one (default)"
    fi
  fi
  if (( SUBS_SET )); then
    if (( SWAP_SUBS )); then
      printf '  %-21s%s\n' "--subtitles:" "given (yes — same languages as audio)"
    else
      printf '  %-21s%s\n' "--subtitles:" "given (no — leave subtitle order)"
    fi
  else
    if (( SWAP_SUBS )); then
      printf '  %-21s%s\n' "--subtitles:" "yes (asked — same languages as audio)"
    else
      printf '  %-21s%s\n' "--subtitles:" "no (asked — leave subtitle order)"
    fi
  fi
  if (( ${#DROP_FAMS[@]} > 0 )); then
    printf '  %-21s%s\n' "Languages:" "drop $(sa_join_labels "${DROP_FAMS[@]}")"
  elif [[ "$LANGS_MODE" == all ]]; then
    printf '  %-21s%s\n' "Languages:" "keep every language"
  else
    printf '  %-21s%s\n' "Languages:" "keep English, Polish, German"
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
  local i src n why dest expanded total sub_csv
  total=${#FILES[@]}
  for i in "${!FILES[@]}"; do
    src="${FILES[$i]}"
    echo "$(sa_ts) Getting file info ($((i + 1))/${total}) ${src##*/}"
    FILE_STATE[$i]=skip
    FILE_WHY[$i]=""
    FILE_AUDIO_N[$i]=0
    FILE_AUDIO_FAMS[$i]=""
    FILE_SUB_FAMS[$i]=""
    FILE_SUB_NOTE[$i]=""
    FILE_DEST[$i]=""
    FILE_BACKUP[$i]=""
    sa_load_streams "$src"
    n=${#AUDIO_ST[@]}
    FILE_AUDIO_N[$i]="$n"
    FILE_AUDIO_FAMS[$i]="$(sa_csv_fams "${AUDIO_ST[@]+"${AUDIO_ST[@]}"}")"
    FILE_SUB_FAMS[$i]="$(sa_csv_fams "${SUBTITLE_ST[@]+"${SUBTITLE_ST[@]}"}")"
    FILE_DEST[$i]="$src"
    if (( KEEP_ORIGINAL )); then
      FILE_BACKUP[$i]="$(sa_backup_path "$src")"
    fi
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
    if sub_csv=$(sa_subtitle_perm "$expanded"); then
      FILE_SUB_NOTE[$i]="$sub_csv"
    fi
  done
}

sa_print_plan() {
  local i src dest n state why extra dated
  echo
  echo "Videos:"
  if (( ${#DROP_FAMS[@]} > 0 )); then
    printf '  drop %s\n' "$(sa_join_labels "${DROP_FAMS[@]}")"
  fi
  for i in "${!FILES[@]}"; do
    src="${FILES[$i]}"
    dest="${FILE_DEST[$i]}"
    n="${FILE_AUDIO_N[$i]}"
    state="${FILE_STATE[$i]}"
    why="${FILE_WHY[$i]}"
    printf '  %s\n' "${src##*/}"
    if [[ "$state" == swap ]]; then
      extra="${n} audio, order ${why}"
      if (( SWAP_SUBS )) && [[ -n "${FILE_SUB_NOTE[$i]}" ]]; then
        extra+=", subs ${FILE_SUB_NOTE[$i]}"
      fi
      if (( KEEP_ORIGINAL )) && [[ -n "${FILE_BACKUP[$i]}" ]]; then
        if [[ -e "${FILE_BACKUP[$i]}" ]]; then
          dated="$(sa_next_take_name "${FILE_BACKUP[$i]}")"
          printf '    %s is there\n' "${FILE_BACKUP[$i]##*/}"
          printf '    original copy -> %s\n' "${dated##*/}"
        else
          printf '    original -> %s\n' "${FILE_BACKUP[$i]##*/}"
        fi
        printf '    write %s\n' "${src##*/}"
      else
        printf '    replace %s\n' "${src##*/}"
      fi
      printf '    %s\n' "$extra"
    else
      printf '    skip: %s\n' "$why"
    fi
  done
  echo
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

sa_process_one() {
  local i="$1" src dest backup n order why rc=0 extra subp="" copy_aside=0
  src="${FILES[$i]}"
  dest="${FILE_DEST[$i]}"
  n="${FILE_AUDIO_N[$i]}"
  why="${FILE_WHY[$i]}"
  if [[ "${FILE_STATE[$i]}" != swap ]]; then
    SKIPPED_LIST+=("${src} (${why})")
    return 0
  fi
  sa_load_info "$src"
  sa_fill_kept_streams
  n=${#KEPT_AUDIO_ST[@]}
  if (( n == 0 )); then
    echo "$(sa_ts) No audio track left in this file. Skipping."
    SKIPPED_LIST+=("${src} (no audio track)")
    FILE_STATE[$i]=skip
    return 0
  fi
  sa_store_info_as IN
  sa_copy_stream_snapshot IN
  (( SWAP_SHOWN++ )) || true
  echo
  echo "$(sa_ts) ${src##*/}   (${SWAP_SHOWN} of ${SWAP_TOTAL})"
  if (( SWAP_SHOWN == 1 )); then
    sa_print_verbose
  else
    sa_print_facts
    sa_print_stream_table
  fi
  if (( n == 1 )); then
    why="1"
  elif ! why=$(sa_expand_slots "$n" "$ORDER_SPEC"); then
    why="${FILE_WHY[$i]}"
  fi
  sa_print_audio_plan "$why"
  order="$why"
  if (( APPLY_REST || (TOGETHER && SWAP_SHOWN > 1) )) && [[ -n "${REST_ORDER:-$ORDER_SPEC}" ]]; then
    if (( n == 1 )); then
      order="1"
    elif ! order=$(sa_expand_slots "$n" "${REST_ORDER:-$ORDER_SPEC}"); then
      echo "$(sa_ts) Order ${REST_ORDER:-$ORDER_SPEC} does not fit this file. Skipping."
      SKIPPED_LIST+=("${src} (order does not fit)")
      FILE_STATE[$i]=skip
      return 0
    fi
  elif (( ! DO_YES )) && (( script_is_run_interactively )); then
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
        if (( n < 2 )); then
          echo "$(sa_ts) Only one remaining audio track. Skipping the custom order."
          order="1"
        elif sa_ask_custom_order "$n" "$ORDER_SPEC"; then
          ORDER_SPEC="$REPLY"
          ORDER_SET=1
          order="$REPLY"
          if ! order=$(sa_expand_slots "$n" "$ORDER_SPEC"); then
            echo "$(sa_ts) That order does not fit this file. Skipping."
            SKIPPED_LIST+=("${src} (order does not fit)")
            return 0
          fi
          REST_ORDER="$ORDER_SPEC"
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
  sa_fill_kept_streams
  if sa_slots_are_identity "$order" "$n" && (( ${#KEPT_AUDIO_ST[@]} == ${#AUDIO_ST[@]} && ${#KEPT_SUBTITLE_ST[@]} == ${#SUBTITLE_ST[@]} )); then
    echo "$(sa_ts) That order leaves the audio as it is. Skipping."
    SKIPPED_LIST+=("${src} (left as it is)")
    return 0
  fi
  extra="audio order ${order}; first audio default"
  if (( ${#DROP_FAMS[@]} > 0 )); then
    extra+="; drop $(sa_join_labels "${DROP_FAMS[@]}")"
  fi
  if (( SWAP_SUBS )); then
    if subp=$(sa_subtitle_perm "$order"); then
      extra+="; subtitles ${subp}; first subtitle default"
    else
      extra+="; subtitles left as they are"
    fi
  fi
  backup="${FILE_BACKUP[$i]}"
  dest="$src"
  copy_aside=0
  if (( KEEP_ORIGINAL )) && [[ -n "$backup" && -e "$backup" ]]; then
    backup="$(sa_next_take_name "$backup")"
    FILE_BACKUP[$i]="$backup"
    copy_aside=1
  fi
  if (( DRY_RUN )); then
    if (( KEEP_ORIGINAL )); then
      if (( copy_aside )); then
        echo "$(sa_ts) Would copy ${src##*/} -> ${backup##*/}, then write ${src##*/}  (${extra})"
      else
        echo "$(sa_ts) Would move ${src##*/} -> ${backup##*/}, then write ${src##*/}  (${extra})"
      fi
    else
      echo "$(sa_ts) Would replace ${src##*/}  (${extra})"
    fi
    DONE_LIST+=("${dest} (dry run, ${order})")
    return 0
  fi
  if (( KEEP_ORIGINAL )) && (( copy_aside )); then
    echo "$(sa_ts) Existing backup kept; copying original to ${backup##*/}, writing ${src##*/}  (${extra}, copy)"
    if ! cp -f -- "$src" "$backup"; then
      echo "$(sa_ts) Could not copy ${src} to ${backup}." >&2
      FAILED_LIST+=("$src")
      return_code=1
      return 1
    fi
    sa_restore_times "$backup" "$src"
    sa_proc_begin
    if sa_remux "$src" "$dest" "$order"; then
      sa_proc_end
      echo "$(sa_ts) Wrote ${dest}  ($(sa_human_size "$(sa_file_bytes "$dest")"))"
      DONE_LIST+=("$dest")
      sa_load_info "$dest"
      sa_store_info_as OUT
      sa_copy_stream_snapshot OUT
      sa_print_compare IN_IDX IN_TYPE IN_CODEC IN_DET OUT_IDX OUT_TYPE OUT_CODEC OUT_DET
      return 0
    fi
    sa_proc_end
    echo "$(sa_ts) Could not write ${dest}." >&2
    FAILED_LIST+=("$src")
    return_code=1
    return 1
  fi
  if (( KEEP_ORIGINAL )); then
    echo "$(sa_ts) Moving original to ${backup##*/}, writing ${src##*/}  (${extra}, copy)"
    if ! mv -f -- "$src" "$backup"; then
      echo "$(sa_ts) Could not move ${src} aside." >&2
      FAILED_LIST+=("$src")
      return_code=1
      return 1
    fi
    ASIDE_ORIG="$src"
    ASIDE_BACKUP="$backup"
    sa_proc_begin
    if sa_remux "$backup" "$dest" "$order"; then
      sa_proc_end
      ASIDE_ORIG=""
      ASIDE_BACKUP=""
      echo "$(sa_ts) Wrote ${dest}  ($(sa_human_size "$(sa_file_bytes "$dest")"))"
      DONE_LIST+=("$dest")
      sa_load_info "$dest"
      sa_store_info_as OUT
      sa_copy_stream_snapshot OUT
      sa_print_compare IN_IDX IN_TYPE IN_CODEC IN_DET OUT_IDX OUT_TYPE OUT_CODEC OUT_DET
      return 0
    fi
    sa_proc_end
    sa_aside_restore
    echo "$(sa_ts) Could not write ${dest}." >&2
    FAILED_LIST+=("$src")
    return_code=1
    return 1
  fi
  echo "$(sa_ts) Replacing ${src}  (${extra}, copy)"
  sa_proc_begin
  if sa_remux "$src" "$dest" "$order"; then
    sa_proc_end
    echo "$(sa_ts) Wrote ${dest}  ($(sa_human_size "$(sa_file_bytes "$dest")"))"
    DONE_LIST+=("$dest")
    sa_load_info "$dest"
    sa_store_info_as OUT
    sa_copy_stream_snapshot OUT
    sa_print_compare IN_IDX IN_TYPE IN_CODEC IN_DET OUT_IDX OUT_TYPE OUT_CODEC OUT_DET
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
  if (( KEEP_ORIGINAL )); then
    sa_summary_kv "Originals" "kept as clip-backup.mp4; an existing backup gets a dated copy"
  else
    sa_summary_kv "Originals" "replaced"
  fi
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
  sa_aside_restore
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
    --keep-original)
      sa_need_value "$@"
      case "$2" in
        yes) KEEP_ORIGINAL=1; KEEP_SET=1 ;;
        no) KEEP_ORIGINAL=0; KEEP_SET=1 ;;
        *) echo "ERROR: --keep-original must be yes or no, not: $2" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --together) TOGETHER=1; TOGETHER_SET=1; shift ;;
    --one-by-one) TOGETHER=0; TOGETHER_SET=1; shift ;;
    --subtitles)
      sa_need_value "$@"
      case "$2" in
        yes) SWAP_SUBS=1; SUBS_SET=1 ;;
        no) SWAP_SUBS=0; SUBS_SET=1 ;;
        *) echo "ERROR: --subtitles must be yes or no, not: $2" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --languages)
      sa_need_value "$@"
      case "$2" in
        keep) LANGS_MODE=keep; LANGS_SET=1 ;;
        all) LANGS_MODE=all; LANGS_SET=1 ;;
        *) echo "ERROR: --languages must be keep or all, not: $2" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --drop)
      sa_need_value "$@"
      DROP_SPEC="${2// /}"
      LANGS_MODE=drop
      LANGS_SET=1
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
sa_require_ffmpeg
sa_ask_colors
sa_ask_keep_copy
sa_ask_together
sa_ask_subtitles

if (( ${#INPUT_ARGS[@]} == 0 )); then
  echo
  echo "$(sa_ts) Searching for videos in ."
  sa_add_directory "."
else
  echo
  if (( ${#INPUT_ARGS[@]} == 1 )); then
    _path="$(sa_unix_path "${INPUT_ARGS[0]}")"
    if [[ -d "$_path" ]]; then
      echo "$(sa_ts) Searching for videos in ${_path}"
    else
      echo "$(sa_ts) Looking at ${_path}"
    fi
  else
    echo "$(sa_ts) Searching for videos in the ${#INPUT_ARGS[@]} paths given."
  fi
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

if (( ${#FILES[@]} == 1 )); then
  echo "$(sa_ts) Found 1 video."
elif (( ${#FILES[@]} == 0 )); then
  echo "$(sa_ts) Found 0 videos."
  echo "$(sa_ts) No video files."
  exit 0
else
  echo "$(sa_ts) Found ${#FILES[@]} videos."
fi

echo
sa_probe_plan

if (( ${#FILES[@]} == 1 )); then
  echo "$(sa_ts) Read 1 video."
else
  echo "$(sa_ts) Read ${#FILES[@]} videos."
fi

sa_ask_languages
sa_finalize_plan
sa_print_plan

_skip=$(( ${#FILES[@]} - SWAP_TOTAL ))
echo "$(sa_ts) ${SWAP_TOTAL} to process, ${_skip} to skip."

if (( SWAP_TOTAL == 0 )); then
  echo "$(sa_ts) No file to swap or drop."
  exit 0
fi

sa_print_run_settings

if (( DRY_RUN )); then
  echo "$(sa_ts) Dry run: nothing written."
  for i in "${!FILES[@]}"; do
    sa_process_one "$i" || true
  done
  exit 0
fi

if (( ! DO_YES )) && (( ! script_is_run_interactively )); then
  echo "$(sa_ts) Not a terminal: nothing written. Add -y to swap without asking."
  exit 0
fi

for i in "${!FILES[@]}"; do
  sa_process_one "$i" || true
done

exit "$return_code"
