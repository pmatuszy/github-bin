#!/bin/bash
# v. 20260930.223700 - auto encoder follows the source codec
# v. 20260930.223600 - name the source video codec and the output encoder separately
# v. 20260930.222600 - encode display: normal progress bar, or verbose frames
# v. 20260930.221800 - quiet ffmpeg log; print the ffmpeg version in a box
# v. 20260930.221500 - file prompts: one key, no Enter
# v. 20260930.220400 - faster viewing copy of a merged video (2, 5, 10, 20, …)

# 2026.09.30 - v. 0.6 - auto output encoder follows the source codec (HEVC prefers hevc_nvenc, then libx265; H.264 prefers h264_nvenc, then libx264)
# 2026.09.30 - v. 0.5 - print the source video codec and label the encoder that will write the new file
# 2026.09.30 - v. 0.4 - encode display: normal is a progress bar (default); verbose keeps the ffmpeg frame line
# 2026.09.30 - v. 0.3 - encode log is errors plus the progress line; print the ffmpeg version in a box
# 2026.09.30 - v. 0.2 - file prompts read one key and do not wait for Enter
# 2026.09.30 - v. 0.1 - initial release: write stem_xN.mp4 beside an input; 2× keeps audio, faster speeds drop it; NVENC when ffmpeg lists it, else libx264
#
# video-pgm-timelapse.sh
#
# Make a faster viewing copy of a video (typically a video-pgm-merge.sh result).
# The source file and any .gpx beside it are left unchanged.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [--speed N] [--redo] [--verbose]
       [--encoder auto|nvenc|x264|x265] [FILE|DIR ...]

Write a faster copy beside each video. A 10× copy of a two-hour drive is about
twelve minutes. The original file is not changed.

With no FILE or DIR, use the current directory. If that directory contains
*_concat.mp4 files, only those are used. Otherwise every other .mp4 in the
directory is used. Files already named *_xN.mp4 are skipped.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Encode every selected file without prompts.
  --speed N            Integer speed, 2 or more (default when -y: 10).
                       2 keeps audio. 5, 10, 20, and any higher speed drop audio.
  --redo               Replace an existing *_xN.mp4.
  --encoder KIND       auto (default), nvenc, x264, or x265.
                       auto follows the source codec. HEVC prefers hevc_nvenc,
                       then libx265. H.264 prefers h264_nvenc, then libx264.
                       A missing or failed encoder falls through to the next.
                       nvenc, x264, and x265 force that one encoder.
  --verbose            Show ffmpeg frame stats instead of the progress bar.
                       -y otherwise keeps the progress bar.

Environment:
  PGM_TIMELAPSE_SPEED     Same as --speed.
  PGM_TIMELAPSE_ENCODER   Same as --encoder (auto, nvenc, x264, x265).
  PGM_TIMELAPSE_DISPLAY   normal (default) or verbose. verbose matches --verbose.

Examples:
  $(basename "$0") --speed 10 trip_concat.mp4
  $(basename "$0") --verbose --speed 10 trip_concat.mp4
  $(basename "$0") -y --speed 20 /path/to/merged/
  $(basename "$0")
      Ask for a speed, then normal or verbose display, then each file (one key, no Enter).
EOF
}

tl_ts() {
  date '+%Y.%m.%d %H:%M:%S'
}

tl_is_speed() {
  local n="$1"
  [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 2 && n <= 240 ))
}

tl_is_timelapse_output() {
  local base="${1##*/}"
  [[ "$base" =~ _x[0-9]+\.[mM][pP]4$ ]]
}

tl_is_concat_output() {
  local base="${1##*/}"
  [[ "$base" =~ _concat\.[mM][pP]4$ ]]
}

# Output path for this speed: <stem>_xN.mp4 next to the source.
tl_output_path() {
  local src="$1" speed="$2" dir stem
  dir="$(dirname -- "$src")"
  stem="$(basename -- "$src")"
  stem="${stem%.*}"
  printf '%s/%s_x%s.mp4\n' "$dir" "$stem" "$speed"
}

tl_ffprobe_duration() {
  local f="$1" dur
  dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 -- "$f" 2>/dev/null || true)"
  [[ "$dur" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
  printf '%s\n' "$dur"
}

tl_has_audio() {
  local f="$1" kind
  kind="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 -- "$f" 2>/dev/null || true)"
  [[ "$kind" == "audio" ]]
}

# Video codec stored in the source file (hevc, h264, …). Empty if unknown.
tl_source_video_codec() {
  local f="$1" codec
  codec="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 -- "$f" 2>/dev/null | awk 'NR==1 { print; exit }' || true)"
  codec="${codec//$'\r'/}"
  codec="${codec//$'\n'/}"
  printf '%s\n' "$codec"
}

tl_format_seconds() {
  local sec="$1"
  awk -v s="$sec" 'BEGIN {
    if (s < 0) s = 0
    h = int(s / 3600)
    m = int((s - h * 3600) / 60)
    x = int(s + 0.5) % 60
    if (h > 0) printf "%dh %dm %ds", h, m, x
    else if (m > 0) printf "%dm %ds", m, x
    else printf "%ds", int(s + 0.5)
  }'
}

tl_format_clock() {
  awk -v s="${1:-0}" 'BEGIN {
    if (s == "" || s < 0) s = 0
    t = int(s + 0.5)
    h = int(t / 3600)
    m = int((t % 3600) / 60)
    sec = t % 60
    printf "%02d:%02d:%02d", h, m, sec
  }'
}

# ffmpeg out_time is HH:MM:SS.microseconds. A leading minus is the preroll.
tl_out_time_seconds() {
  awk -v t="$1" 'BEGIN {
    if (t == "" || t ~ /^-/) { print 0; exit }
    n = split(t, a, ":")
    if (n != 3) { print 0; exit }
    printf "%.3f\n", (a[1] * 3600) + (a[2] * 60) + a[3]
  }'
}

# One updating line. frac is 0..1, or empty when the output length is unknown.
tl_draw_progress() {
  local frac="$1" elapsed="$2" total="$3" speedx="$4"
  local width=24 filled=0 empty bar pct el_clock tot_clock
  if [[ -n "$frac" ]]; then
    pct="$(awk -v f="$frac" 'BEGIN { p=int(f*100+0.5); if (p>100) p=100; if (p<0) p=0; printf "%3d", p }')"
    filled="$(awk -v f="$frac" -v w="$width" 'BEGIN { n=int(f*w+0.5); if (n>w) n=w; if (n<0) n=0; printf "%d", n }')"
  else
    pct=" --"
  fi
  empty=$((width - filled))
  bar="$(printf '%*s' "$filled" '' | tr ' ' '#')"
  bar+="$(printf '%*s' "$empty" '' | tr ' ' '-')"
  el_clock="$(tl_format_clock "$elapsed")"
  if [[ -n "$total" ]]; then
    tot_clock="$(tl_format_clock "$total")"
  else
    tot_clock="--:--:--"
  fi
  printf '\r[%s] %s%%  %s / %s  %s\033[K' "$bar" "$pct" "$el_clock" "$tot_clock" "$speedx"
}

# Read ffmpeg -progress blocks on stdin and redraw the bar.
tl_progress_reader() {
  local total_sec="$1"
  local line key val out_s=0 spd="--" frac=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == *=* ]] || continue
    key="${line%%=*}"
    val="${line#*=}"
    case "$key" in
      out_time) out_s="$(tl_out_time_seconds "$val")" ;;
      speed)
        spd="$val"
        [[ "$spd" == "N/A" ]] && spd="--"
        ;;
      progress)
        frac=""
        if [[ "$val" == end && -n "$total_sec" ]]; then
          frac=1
        elif [[ -n "$total_sec" ]] && awk -v t="$total_sec" 'BEGIN { exit !(t+0 > 0) }'; then
          frac="$(awk -v e="$out_s" -v t="$total_sec" 'BEGIN { f=e/t; if (f<0) f=0; if (f>1) f=1; printf "%.4f", f }')"
        fi
        tl_draw_progress "$frac" "$out_s" "$total_sec" "$spd"
        ;;
    esac
  done
  printf '\n'
}

# ffmpeg args follow total_sec. Progress is on stdout; the video path is the last arg.
tl_ffmpeg_progress() {
  local total_sec="$1"
  shift
  local rc=0
  if command -v stdbuf >/dev/null 2>&1; then
    stdbuf -oL ffmpeg "$@" | tl_progress_reader "$total_sec"
  else
    ffmpeg "$@" | tl_progress_reader "$total_sec"
  fi
  rc=${PIPESTATUS[0]}
  return "$rc"
}

# Keep 1 frame out of N, then play those frames at the source frame rate.
tl_video_filter() {
  local speed="$1"
  printf "select='not(mod(n\\,%s))',setpts=N/FRAME_RATE/TB,format=yuv420p" "$speed"
}

tl_encoder_available() {
  local name="$1"
  [[ -n "${TL_ENCODER_LIST:-}" ]] || return 1
  grep -Eq "(^|[[:space:]])${name}([[:space:]]|$)" <<<"$TL_ENCODER_LIST"
}

# First line of `ffmpeg -version`, drawn in a box when `boxes` is installed.
tl_print_ffmpeg_version() {
  local ver width bar
  ver="$(ffmpeg -version 2>/dev/null | awk 'NR==1 { print; exit }' || true)"
  [[ -n "$ver" ]] || ver="ffmpeg version unknown"
  echo
  if type -fP boxes >/dev/null 2>&1; then
    printf '%s\n' "$ver" | boxes -a c -d ada-box
  else
    width=${#ver}
    bar="$(printf '%*s' "$((width + 2))" '' | tr ' ' '-')"
    echo "+${bar}+"
    echo "| ${ver} |"
    echo "+${bar}+"
  fi
  echo
}

tl_load_encoders() {
  TL_ENCODER_LIST="$(ffmpeg -hide_banner -encoders 2>/dev/null || true)"
}

tl_set_encoder_args() {
  local kind="$1"
  TL_ENC_KIND="$kind"
  TL_ENC_ARGS=()
  case "$kind" in
    nvenc)
      TL_ENC_ARGS=(-c:v hevc_nvenc -preset p4 -rc vbr -cq 28 -tag:v hvc1)
      ;;
    h264nv)
      TL_ENC_ARGS=(-c:v h264_nvenc -preset p4 -rc vbr -cq 23 -pix_fmt yuv420p)
      ;;
    x265)
      TL_ENC_ARGS=(-c:v libx265 -preset fast -crf 28 -tag:v hvc1)
      ;;
    x264)
      TL_ENC_ARGS=(-c:v libx264 -preset veryfast -crf 22 -pix_fmt yuv420p)
      ;;
    *)
      return 1
      ;;
  esac
}

tl_codec_family() {
  local codec="${1,,}"
  case "$codec" in
    hevc|h265|hev1) printf '%s\n' hevc ;;
    h264|avc|avc1) printf '%s\n' h264 ;;
    *) printf '%s\n' other ;;
  esac
}

tl_kind_for_name() {
  case "$1" in
    hevc_nvenc) printf '%s\n' nvenc ;;
    h264_nvenc) printf '%s\n' h264nv ;;
    libx265) printf '%s\n' x265 ;;
    libx264) printf '%s\n' x264 ;;
    *) return 1 ;;
  esac
}

tl_encoder_label() {
  case "$1" in
    nvenc) printf '%s\n' hevc_nvenc ;;
    h264nv) printf '%s\n' h264_nvenc ;;
    x265) printf '%s\n' libx265 ;;
    x264) printf '%s\n' libx264 ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# One kind per line, in the order to try. Returns 1 when none of them exist.
tl_encoder_candidates() {
  local want="$1" codec="${2:-}" family name kind printed=0
  local -a names=()
  case "$want" in
    auto)
      family="$(tl_codec_family "$codec")"
      case "$family" in
        hevc) names=(hevc_nvenc libx265 libx264) ;;
        h264) names=(h264_nvenc libx264 hevc_nvenc libx265) ;;
        *)    names=(hevc_nvenc libx264 libx265) ;;
      esac
      ;;
    nvenc) names=(hevc_nvenc) ;;
    x264)  names=(libx264) ;;
    x265)  names=(libx265) ;;
    *) return 1 ;;
  esac
  for name in "${names[@]}"; do
    tl_encoder_available "$name" || continue
    kind="$(tl_kind_for_name "$name")" || continue
    printf '%s\n' "$kind"
    printed=1
  done
  (( printed )) || return 1
}

tl_cleanup_partial() {
  if [[ -n "${TL_PARTIAL:-}" && -e "$TL_PARTIAL" ]]; then
    rm -f -- "$TL_PARTIAL"
    echo "$(tl_ts) Removed incomplete output: ${TL_PARTIAL}"
  fi
  TL_PARTIAL=""
}

# Encode one file at SPEED into its _xN sibling. Uses TL_ENC_ARGS.
# On failure removes the partial file and returns 1.
# total_sec is the expected output length (input duration / speed).
tl_run_ffmpeg() {
  local src="$1" dest="$2" speed="$3" keep_audio="$4" total_sec="${5:-}"
  local vfilter partial rc
  local -a enc_args=()
  vfilter="$(tl_video_filter "$speed")"
  partial="${dest}.partial.$$.mp4"
  TL_PARTIAL="$partial"
  enc_args=(-i "$src")
  if (( keep_audio )); then
    enc_args+=(
      -filter_complex "[0:v]${vfilter}[v];[0:a]atempo=${speed}.0[a]"
      -map "[v]" -map "[a]"
      "${TL_ENC_ARGS[@]}"
      -c:a aac -b:a 128k
    )
  else
    enc_args+=(
      -an
      -filter:v "$vfilter"
      "${TL_ENC_ARGS[@]}"
    )
  fi
  enc_args+=(-movflags +faststart)
  if [[ "$TL_DISPLAY" == verbose ]]; then
    ffmpeg -y -hide_banner -loglevel error -stats "${enc_args[@]}" "$partial"
    rc=$?
  elif [[ -t 1 ]]; then
    tl_ffmpeg_progress "$total_sec" -y -hide_banner -loglevel error -nostats \
      -progress pipe:1 "${enc_args[@]}" "$partial"
    rc=$?
  else
    ffmpeg -y -hide_banner -loglevel error -nostats "${enc_args[@]}" "$partial"
    rc=$?
  fi
  if (( rc != 0 )) || [[ ! -s "$partial" ]]; then
    rm -f -- "$partial"
    TL_PARTIAL=""
    return 1
  fi
  if ! mv -f -- "$partial" "$dest"; then
    rm -f -- "$partial"
    TL_PARTIAL=""
    return 1
  fi
  TL_PARTIAL=""
  return 0
}

tl_encode_one() {
  local src="$1" speed="$2" redo="$3" encoder_want="$4"
  local dest dur out_dur="" kind keep_audio=0 label label_prev="" src_codec i
  local -a kinds=()
  dest="$(tl_output_path "$src" "$speed")"
  if [[ -e "$dest" && "$redo" -eq 0 ]]; then
    echo "$(tl_ts) Already exists, skipping: ${dest}"
    return 0
  fi
  if tl_has_audio "$src" && (( speed == 2 )); then
    keep_audio=1
  fi
  dur="$(tl_ffprobe_duration "$src" || true)"
  echo
  echo "$(tl_ts) Source: ${src}"
  if [[ -n "$dur" ]]; then
    out_dur="$(awk -v d="$dur" -v s="$speed" 'BEGIN{printf "%.3f", d/s}')"
    echo "$(tl_ts) Duration: $(tl_format_seconds "$dur") → $(tl_format_seconds "$out_dur") at ${speed}×"
  fi
  if (( keep_audio )); then
    echo "$(tl_ts) Audio: kept, played at ${speed}×"
  else
    echo "$(tl_ts) Audio: omitted"
  fi
  echo "$(tl_ts) Output: ${dest}"
  src_codec="$(tl_source_video_codec "$src")"
  if [[ -n "$src_codec" ]]; then
    echo "$(tl_ts) Source video codec: ${src_codec}"
  else
    echo "$(tl_ts) Source video codec: unknown"
  fi
  mapfile -t kinds < <(tl_encoder_candidates "$encoder_want" "$src_codec")
  if (( ${#kinds[@]} == 0 )); then
    echo "$(tl_ts) No usable video encoder for '${encoder_want}'." >&2
    return 1
  fi
  for i in "${!kinds[@]}"; do
    kind="${kinds[$i]}"
    tl_set_encoder_args "$kind" || return 1
    label="$(tl_encoder_label "$kind")"
    if (( i > 0 )); then
      echo "$(tl_ts) ${label_prev} failed; retrying with ${label}."
    fi
    echo "$(tl_ts) Output encoder: ${label}"
    if tl_run_ffmpeg "$src" "$dest" "$speed" "$keep_audio" "$out_dur"; then
      echo "$(tl_ts) Done: ${dest}"
      return 0
    fi
    label_prev="$label"
  done
  echo "$(tl_ts) Encode failed: ${src}" >&2
  return 1
}

tl_add_mp4_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  tl_is_timelapse_output "$f" && return 0
  TL_INPUTS+=("$f")
}

# Directory: *_concat.mp4 when any exist, otherwise every other .mp4.
tl_add_directory() {
  local dir="$1" f
  local -a found=() concats=()
  shopt -s nullglob nocaseglob
  found=( "$dir"/*.mp4 )
  shopt -u nullglob nocaseglob
  (( ${#found[@]} == 0 )) && return 0
  for f in "${found[@]}"; do
    tl_is_timelapse_output "$f" && continue
    if tl_is_concat_output "$f"; then
      concats+=("$f")
    fi
  done
  if (( ${#concats[@]} > 0 )); then
    mapfile -t concats < <(printf '%s\n' "${concats[@]}" | LC_ALL=C sort)
    TL_INPUTS+=("${concats[@]}")
    return 0
  fi
  mapfile -t found < <(printf '%s\n' "${found[@]}" | LC_ALL=C sort)
  for f in "${found[@]}"; do
    tl_add_mp4_file "$f"
  done
}

tl_flush_stdin() {
  local discard drained=0
  while (( drained < 256 )) && IFS= read -r -t 0.02 -n 1 discard; do
    (( drained++ )) || true
  done
}

# One key, no Enter. Sets REPLY. An empty read uses default_key.
tl_read_key() {
  local prompt="$1" default_key="${2:-}" answer=""
  printf '%s' "$prompt"
  tl_flush_stdin
  read -n 1 answer || answer=""
  echo
  if [[ -z "$answer" ]]; then
    REPLY="$default_key"
  else
    REPLY="$answer"
  fi
}

tl_prompt_speed() {
  local answer=""
  local default="${PGM_TIMELAPSE_SPEED:-10}"
  tl_is_speed "$default" || default=10
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    SPEED="$default"
    return 0
  fi
  echo "How much faster?"
  echo "  2   keeps audio"
  echo "  5, 10, 20, or any integer from 2 to 240   picture only"
  printf 'Speed [%s]: ' "$default"
  IFS= read -r answer || answer=""
  if [[ -z "$answer" ]]; then
    SPEED="$default"
  else
    SPEED="$answer"
  fi
  if ! tl_is_speed "$SPEED"; then
    echo "$(tl_ts) Invalid speed: ${SPEED} (use an integer from 2 to 240)" >&2
    return 1
  fi
  return 0
}

tl_prompt_file_action() {
  local n="$1" total="$2" dest="$3"
  local choice=""
  REPLY=encode
  if (( DO_YES )) || (( ENCODE_ALL )); then
    if [[ -e "$dest" && "$REDO" -eq 0 ]]; then
      REPLY=skip
    else
      REPLY=encode
    fi
    return 0
  fi
  if (( SKIP_ALL )); then
    REPLY=skip
    return 0
  fi
  if (( ! script_is_run_interactively )); then
    echo "$(tl_ts) Non-interactive: skipping (use -y to encode)."
    REPLY=skip
    return 0
  fi
  if [[ -e "$dest" && "$REDO" -eq 0 ]]; then
    echo "  [N] Skip — keep existing file (default)"
    echo "  [r] Redo — replace ${dest##*/}"
    echo "  [a] Skip all remaining"
    echo "  [q] Quit"
    tl_read_key "Already exists — file ${n}/${total} [N/r/a/q]: " n
    choice="${REPLY,,}"
    case "$choice" in
      ''|n) REPLY=skip ;;
      r)    REPLY=redo ;;
      a)    REPLY=skip_all ;;
      q)    REPLY=quit ;;
      *)    echo "$(tl_ts) Unknown choice: ${choice}"; REPLY=skip ;;
    esac
    return 0
  fi
  echo "  [Y] Encode this file (default)"
  echo "  [n] Skip this file"
  echo "  [a] Skip all remaining"
  echo "  [m] Encode all remaining"
  echo "  [q] Quit"
  tl_read_key "File ${n}/${total} [Y/n/a/m/q]: " y
  choice="${REPLY,,}"
  case "$choice" in
    ''|y) REPLY=encode ;;
    n)    REPLY=skip ;;
    a)    REPLY=skip_all ;;
    m)    REPLY=encode_all ;;
    q)    REPLY=quit ;;
    *)    echo "$(tl_ts) Unknown choice: ${choice}"; REPLY=skip ;;
  esac
}

tl_prompt_display() {
  local choice=""
  if (( TL_DISPLAY_FROM_CLI )) || [[ -n "$TL_DISPLAY" ]]; then
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    TL_DISPLAY=normal
    return 0
  fi
  echo
  echo "Encode display?"
  echo "  [N] Normal (progress bar) (default)"
  echo "  [v] Verbose (frames)"
  tl_read_key "Display [N/v]: " n
  choice="${REPLY,,}"
  choice="${choice//$'\r'/}"
  choice="${choice//$'\n'/}"
  case "$choice" in
    ''|n) TL_DISPLAY=normal ;;
    v)    TL_DISPLAY=verbose ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; using normal (progress bar)."
      TL_DISPLAY=normal
      ;;
  esac
}

# --- parse options (header sourced first so -v can call print_version_banner) ---
# shellcheck disable=SC1091
. /root/bin/_script_header.sh

DO_YES=0
REDO=0
ENCODE_ALL=0
SKIP_ALL=0
SPEED="${PGM_TIMELAPSE_SPEED:-}"
ENCODER="${PGM_TIMELAPSE_ENCODER:-auto}"
TL_DISPLAY="${PGM_TIMELAPSE_DISPLAY:-}"
TL_DISPLAY_FROM_CLI=0
SPEED_FROM_CLI=0
TL_INPUTS=()
TL_PARTIAL=""
TL_ENC_ARGS=()
TL_ENC_KIND=""
TL_ENCODER_LIST=""
POSITIONALS=()

trap tl_cleanup_partial EXIT

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
    --history)
      print_script_history
      exit 0
      ;;
    -y|--yes)
      DO_YES=1
      shift
      ;;
    --redo)
      REDO=1
      shift
      ;;
    --speed)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --speed" >&2; exit 1; }
      SPEED="$2"
      SPEED_FROM_CLI=1
      shift 2
      ;;
    --speed=*)
      SPEED="${1#--speed=}"
      SPEED_FROM_CLI=1
      shift
      ;;
    --encoder)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --encoder" >&2; exit 1; }
      ENCODER="$2"
      shift 2
      ;;
    --encoder=*)
      ENCODER="${1#--encoder=}"
      shift
      ;;
    --verbose)
      TL_DISPLAY=verbose
      TL_DISPLAY_FROM_CLI=1
      shift
      ;;
    --)
      shift
      POSITIONALS+=("$@")
      break
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      exit 1
      ;;
    *)
      POSITIONALS+=("$1")
      shift
      ;;
  esac
done

case "$ENCODER" in
  auto|nvenc|x264|x265) ;;
  *)
    echo "ERROR: invalid --encoder: ${ENCODER} (auto, nvenc, x264, x265)" >&2
    exit 1
    ;;
esac

if [[ -n "$SPEED" ]] && ! tl_is_speed "$SPEED"; then
  echo "ERROR: invalid speed: ${SPEED} (integer from 2 to 240)" >&2
  exit 1
fi

case "$TL_DISPLAY" in
  ''|normal|verbose) ;;
  *)
    echo "ERROR: invalid PGM_TIMELAPSE_DISPLAY: ${TL_DISPLAY} (normal or verbose)" >&2
    exit 1
    ;;
esac

if (( ${#POSITIONALS[@]} == 0 )); then
  tl_add_directory "."
else
  for _tl_path in "${POSITIONALS[@]}"; do
    if [[ -d "$_tl_path" ]]; then
      tl_add_directory "$_tl_path"
    elif [[ -f "$_tl_path" ]]; then
      tl_add_mp4_file "$_tl_path"
    else
      echo "ERROR: not a file or directory: ${_tl_path}" >&2
      exit 1
    fi
  done
fi

if (( ${#TL_INPUTS[@]} == 0 )); then
  echo "$(tl_ts) No input videos."
  return_code=0
  # shellcheck disable=SC1091
  . /root/bin/_script_footer.sh
  exit 0
fi

if [[ -z "$SPEED" ]]; then
  tl_prompt_speed || exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
  echo "$(tl_ts) ffmpeg and ffprobe are required." >&2
  exit 1
fi
tl_print_ffmpeg_version
tl_prompt_display
tl_load_encoders
tl_encoder_candidates "$ENCODER" "" >/dev/null || {
  echo "$(tl_ts) No usable video encoder for '${ENCODER}'." >&2
  exit 1
}

echo "$(tl_ts) Speed: ${SPEED}×    files: ${#TL_INPUTS[@]}    encoder request: ${ENCODER}    display: ${TL_DISPLAY}"
if (( SPEED == 2 )); then
  echo "$(tl_ts) Audio is kept at 2×. The .gpx beside the source still uses real time."
else
  echo "$(tl_ts) Audio is omitted. The .gpx beside the source still uses real time."
fi

return_code=0
tl_i=0
tl_total=${#TL_INPUTS[@]}
for tl_src in "${TL_INPUTS[@]}"; do
  (( tl_i++ )) || true
  tl_dest="$(tl_output_path "$tl_src" "$SPEED")"
  echo
  echo "=== $(basename -- "$tl_src") ==="
  tl_prompt_file_action "$tl_i" "$tl_total" "$tl_dest"
  case "$REPLY" in
    encode)
      tl_encode_one "$tl_src" "$SPEED" "$REDO" "$ENCODER" || return_code=1
      ;;
    redo)
      tl_encode_one "$tl_src" "$SPEED" 1 "$ENCODER" || return_code=1
      ;;
    skip)
      echo "$(tl_ts) Skipped: ${tl_src}"
      ;;
    skip_all)
      SKIP_ALL=1
      echo "$(tl_ts) Skipping remaining files."
      ;;
    encode_all)
      ENCODE_ALL=1
      tl_encode_one "$tl_src" "$SPEED" "$REDO" "$ENCODER" || return_code=1
      ;;
    quit)
      echo "$(tl_ts) Quit."
      break
      ;;
  esac
done

# shellcheck disable=SC1091
. /root/bin/_script_footer.sh
exit "$return_code"
