#!/bin/bash
# v. 20261002.080800 - scan messages separate whole-file keyframes from the decoded piece
# v. 20261002.075200 - advanced encoding menu: picture, keyframes, scan, test clip
# v. 20261002.073700 - output encoder line says GPU hardware or CPU only
# v. 20261002.065500 - progress bar is 48 characters wide
# v. 20261001.230600 - progress bar shows time left and the arrival clock
# v. 20261001.221000 - ffmpeg probe shows the real error, not "version unknown"
# v. 20261001.220200 - startup box: ffmpeg version and GPU encoders in this build
# v. 20260930.223700 - auto encoder follows the source codec
# v. 20260930.223600 - name the source video codec and the output encoder separately
# v. 20260930.222600 - encode display: normal progress bar, or verbose frames
# v. 20260930.221800 - quiet ffmpeg log; print the ffmpeg version in a box
# v. 20260930.221500 - file prompts: one key, no Enter
# v. 20260930.220400 - faster viewing copy of a merged video (2, 5, 10, 20, …)

# 2026.10.02 - v. 0.13 - scan says keyframes are the whole file, and the 2/5/10 minutes are only the decoded piece
# 2026.10.02 - v. 0.12 - advanced encoding menu, default no: steady or blended picture, keyframe spacing, a source scan, and a short test clip
# 2026.10.02 - v. 0.11 - output encoder line says GPU hardware or CPU only
# 2026.10.02 - v. 0.10 - progress bar is twice as wide (48 characters)
# 2026.10.01 - v. 0.9 - progress bar adds time left and the local arrival clock (date only when it is not today)
# 2026.10.01 - v. 0.8 - ffmpeg probe shows the real error, not "version unknown"
# 2026.10.01 - v. 0.7 - startup box adds which GPU encoders this ffmpeg was built with
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

An interactive run asks for advanced encoding after the speed. Enter means no:
the current picture (every Nth frame at 25 fps), the whole file. Yes asks for
a steady or blended picture, keyframe spacing, an optional source scan, and
an optional short test clip. -y skips that menu.

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
  [[ "$base" =~ _x[0-9]+(_test-[0-9]+m-at[0-9]+)?\.[mM][pP]4$ ]]
}

tl_is_concat_output() {
  local base="${1##*/}"
  [[ "$base" =~ _concat\.[mM][pP]4$ ]]
}

# Output path for this speed: <stem>_xN.mp4 next to the source.
# A test clip is <stem>_xN_test-1m-at20.mp4 so it does not replace the full file.
tl_output_path() {
  local src="$1" speed="$2" dir stem
  dir="$(dirname -- "$src")"
  stem="$(basename -- "$src")"
  stem="${stem%.*}"
  if (( ${TL_TEST:-0} )); then
    printf '%s/%s_x%s_test-%sm-at%s.mp4\n' \
      "$dir" "$stem" "$speed" "$TL_TEST_MINUTES" "$TL_TEST_PERCENT"
  else
    printf '%s/%s_x%s.mp4\n' "$dir" "$stem" "$speed"
  fi
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

# Wall-clock time still to wait, from output seconds left and ffmpeg's speed.
# Under an hour: "6m 7s". From one hour: "1h 2m" (no seconds).
tl_eta_left() {
  awk -v s="$1" 'BEGIN {
    if (s < 0) s = 0
    t = int(s + 0.5)
    h = int(t / 3600)
    m = int((t % 3600) / 60)
    sec = t % 60
    if (h > 0) printf "%dh %dm", h, m
    else if (m > 0) printf "%dm %ds", m, sec
    else printf "%ds", sec
  }'
}

# Local arrival, rounded to the nearest minute. Date only when that minute is not today.
tl_eta_arrival() {
  local remain="$1"
  local now arrival today day clock
  now="$(date +%s)"
  arrival="$(awk -v n="$now" -v r="$remain" 'BEGIN {
    a = int(n + r + 0.5)
    s = a % 60
    if (s >= 30) a += 60 - s
    else a -= s
    printf "%d", a
  }')"
  today="$(date '+%Y.%m.%d')"
  day="$(date -d "@${arrival}" '+%Y.%m.%d')"
  clock="$(date -d "@${arrival}" '+%H:%M')"
  if [[ "$day" == "$today" ]]; then
    printf 'at %s' "$clock"
  else
    printf 'at %s %s' "$day" "$clock"
  fi
}

# "left 6m 7s  at 22:41", or "left --  at --" until speed and length are known.
tl_eta_phrase() {
  local elapsed="$1" total="$2" speedx="$3"
  local spd="${speedx%x}" remain=""
  spd="${spd%X}"
  if [[ -z "$total" ]] || [[ ! "$spd" =~ ^[0-9]+([.][0-9]+)?$ ]] \
      || ! awk -v s="$spd" 'BEGIN { exit !(s+0 > 0) }'; then
    printf 'left --  at --'
    return 0
  fi
  remain="$(awk -v e="$elapsed" -v t="$total" -v s="$spd" 'BEGIN {
    r = (t - e) / s
    if (r < 0) r = 0
    printf "%.3f", r
  }')"
  printf 'left %s  %s' "$(tl_eta_left "$remain")" "$(tl_eta_arrival "$remain")"
}

# One updating line. frac is 0..1, or empty when the output length is unknown.
tl_draw_progress() {
  local frac="$1" elapsed="$2" total="$3" speedx="$4"
  local width=48 filled=0 empty bar pct el_clock tot_clock eta
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
  eta="$(tl_eta_phrase "$elapsed" "$total" "$speedx")"
  printf '\r[%s] %s%%  %s / %s  %s  %s\033[K' "$bar" "$pct" "$el_clock" "$tot_clock" "$speedx" "$eta"
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

# Plain keeps every Nth frame at the source rate.
# Steady and soft speed the timeline up and land on TL_OUT_FPS.
# Soft averages TL_BLEND_BEFORE frames before the kept frame and
# TL_BLEND_AFTER frames after it, then shifts the timestamp back
# onto that center frame.
tl_video_filter() {
  local speed="$1"
  local fps blend
  case "${TL_PICTURE:-plain}" in
    steady)
      fps="${TL_OUT_FPS:-30}"
      printf 'setpts=(PTS-STARTPTS)/%s,fps=%s,format=yuv420p' "$speed" "$fps"
      ;;
    soft)
      fps="${TL_OUT_FPS:-30}"
      blend=$(( ${TL_BLEND_BEFORE:-1} + ${TL_BLEND_AFTER:-1} + 1 ))
      if (( blend <= 1 )); then
        printf 'setpts=(PTS-STARTPTS)/%s,fps=%s,format=yuv420p' "$speed" "$fps"
        return 0
      fi
      printf 'tmix=frames=%s,setpts=(PTS-STARTPTS-%s/(FRAME_RATE*TB))/%s,fps=%s,format=yuv420p' \
        "$blend" "${TL_BLEND_AFTER:-1}" "$speed" "$fps"
      ;;
    *)
      printf "select='not(mod(n\\,%s))',setpts=N/FRAME_RATE/TB,format=yuv420p" "$speed"
      ;;
  esac
}

tl_source_fps() {
  local f="$1" rate
  rate="$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of csv=p=0 -- "$f" 2>/dev/null | awk 'NR==1 { print; exit }' || true)"
  rate="${rate//$'\r'/}"
  awk -v r="$rate" 'BEGIN {
    if (r ~ /^[0-9]+\/[0-9]+$/) {
      split(r, a, "/")
      if (a[2] + 0 > 0) { printf "%.6f", a[1] / a[2]; exit }
    }
    if (r + 0 > 0) { printf "%.6f", r + 0; exit }
    printf "25"
  }'
}

# Output frame rate used for a "one second" keyframe interval.
tl_gop_fps() {
  local src="$1"
  if [[ "${TL_PICTURE:-plain}" == plain ]]; then
    tl_source_fps "$src"
  else
    printf '%s\n' "${TL_OUT_FPS:-30}"
  fi
}

# Add a fixed keyframe interval when the menu asked for one.
tl_append_gop_args() {
  local kind="$1" fps="$2" n=""
  case "${TL_GOP_MODE:-default}" in
    seconds)
      n="$(awk -v f="$fps" -v s="$TL_GOP_SECONDS" 'BEGIN {
        n = int(f * s + 0.5)
        if (n < 1) n = 1
        printf "%d", n
      }')"
      ;;
    frames)
      n="$TL_GOP_FRAMES"
      ;;
    *)
      return 0
      ;;
  esac
  case "$kind" in
    nvenc|h264nv)
      TL_ENC_ARGS+=(-g "$n" -forced-idr 1)
      ;;
    x265)
      TL_ENC_ARGS+=(-x265-params "keyint=${n}:min-keyint=${n}:scenecut=0")
      ;;
    x264)
      TL_ENC_ARGS+=(-g "$n" -keyint_min "$n" -sc_threshold 0)
      ;;
  esac
}

tl_encoder_available() {
  local name="$1"
  [[ -n "${TL_ENCODER_LIST:-}" ]] || return 1
  grep -Eq "(^|[[:space:]])${name}([[:space:]]|$)" <<<"$TL_ENCODER_LIST"
}

# First line of `ffmpeg -version`, plus which GPU encoders this build has.
tl_print_box_lines() {
  local -a lines=("$@")
  local line width=0 bar
  if (( ${#lines[@]} == 0 )); then
    return 0
  fi
  if type -fP boxes >/dev/null 2>&1; then
    printf '%s\n' "${lines[@]}" | boxes -a c -d ada-box
    return 0
  fi
  for line in "${lines[@]}"; do
    (( ${#line} > width )) && width=${#line}
  done
  bar="$(printf '%*s' "$((width + 2))" '' | tr ' ' '-')"
  echo "+${bar}+"
  for line in "${lines[@]}"; do
    printf '| %-*s |\n' "$width" "$line"
  done
  echo "+${bar}+"
}

tl_ffmpeg_capture() {
  ffmpeg "$@" 2>&1 || true
}

tl_ffmpeg_gpu_encoder_line() {
  local list name out=""
  local -a want=(
    hevc_nvenc h264_nvenc
    hevc_vaapi h264_vaapi
    hevc_qsv h264_qsv
    hevc_amf h264_amf
  )
  list="$(tl_ffmpeg_capture -hide_banner -encoders)"
  for name in "${want[@]}"; do
    grep -Eq "(^|[[:space:]])${name}([[:space:]]|$)" <<<"$list" || continue
    if [[ -n "$out" ]]; then
      out+=", ${name}"
    else
      out="$name"
    fi
  done
  if [[ -n "$out" ]]; then
    printf 'GPU encoders: %s\n' "$out"
  else
    printf '%s\n' "GPU encoders: none"
  fi
}

tl_print_ffmpeg_version() {
  local ver out bin
  local -a lines=()
  echo
  if ! command -v ffmpeg >/dev/null 2>&1; then
    lines=("ffmpeg: not found")
  else
    bin="$(command -v ffmpeg)"
    out="$(tl_ffmpeg_capture -version)"
    ver="$(printf '%s\n' "$out" | awk '/^ffmpeg version / { print; exit }')"
    if [[ -z "$ver" ]]; then
      ver="$(printf '%s\n' "$out" | awk 'NF { print; exit }')"
      if [[ -n "$ver" ]]; then
        ver="ffmpeg (${bin}): ${ver}"
      else
        ver="ffmpeg version unknown (${bin})"
      fi
    fi
    lines=("$ver" "$(tl_ffmpeg_gpu_encoder_line)")
  fi
  tl_print_box_lines "${lines[@]}"
  echo
}

tl_load_encoders() {
  TL_ENCODER_LIST="$(tl_ffmpeg_capture -hide_banner -encoders)"
}

tl_note_encoder_probe_failure() {
  local hint=""
  if [[ "${TL_ENCODER_LIST:-}" != *Encoders:* ]]; then
    hint="$(printf '%s\n' "${TL_ENCODER_LIST:-}" | awk 'NF { print; exit }')"
  fi
  if [[ -n "$hint" ]]; then
    echo "$(tl_ts) ${hint}" >&2
  fi
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

# nvenc runs on the GPU. libx264 and libx265 run on the CPU.
tl_encoder_where() {
  case "$1" in
    nvenc|h264nv) printf '%s\n' "GPU hardware" ;;
    x265|x264) printf '%s\n' "CPU only" ;;
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
  enc_args=()
  if [[ -n "${TL_SS:-}" ]]; then
    enc_args+=(-ss "$TL_SS")
  fi
  enc_args+=(-i "$src")
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
  if [[ -n "${TL_OUT_T:-}" ]]; then
    enc_args+=(-t "$TL_OUT_T")
  fi
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
  local dest dur out_dur="" kind keep_audio=0 label label_prev="" src_codec i where gop_fps
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
  if (( ${TL_TEST:-0} )); then
    tl_set_test_window "$dur" "$speed" || return 1
    out_dur="$TL_TEST_OUT_DUR"
  else
    TL_SS=""
    TL_OUT_T=""
  fi
  if (( keep_audio )); then
    echo "$(tl_ts) Audio: kept, played at ${speed}×"
  else
    echo "$(tl_ts) Audio: omitted"
  fi
  echo "$(tl_ts) Output: ${dest}"
  echo "$(tl_ts) Picture: $(tl_picture_summary)"
  src_codec="$(tl_source_video_codec "$src")"
  if [[ -n "$src_codec" ]]; then
    echo "$(tl_ts) Source video codec: ${src_codec}"
  else
    echo "$(tl_ts) Source video codec: unknown"
  fi
  mapfile -t kinds < <(tl_encoder_candidates "$encoder_want" "$src_codec")
  if (( ${#kinds[@]} == 0 )); then
    echo "$(tl_ts) No usable video encoder for '${encoder_want}'." >&2
    tl_note_encoder_probe_failure
    return 1
  fi
  gop_fps="$(tl_gop_fps "$src")"
  for i in "${!kinds[@]}"; do
    kind="${kinds[$i]}"
    tl_set_encoder_args "$kind" || return 1
    tl_append_gop_args "$kind" "$gop_fps"
    label="$(tl_encoder_label "$kind")"
    where="$(tl_encoder_where "$kind")"
    if [[ -n "$where" ]]; then
      label="${label} (${where})"
    fi
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

tl_choice() {
  local c="${1,,}"
  c="${c//$'\r'/}"
  c="${c//$'\n'/}"
  printf '%s\n' "$c"
}

tl_read_line() {
  local prompt="$1" default="$2" answer=""
  printf '%s' "$prompt"
  IFS= read -r answer || answer=""
  if [[ -z "$answer" ]]; then
    REPLY="$default"
  else
    REPLY="$answer"
  fi
}

tl_minutes_word() {
  if [[ "$1" == "1" ]]; then
    printf '1 minute'
  else
    printf '%s minutes' "$1"
  fi
}

tl_picture_summary() {
  case "${TL_PICTURE:-plain}" in
    steady)
      printf 'steady %s fps, %s' "${TL_OUT_FPS:-30}" "$(tl_gop_summary)"
      ;;
    soft)
      printf 'soft %s before, %s after, %s fps, %s' \
        "${TL_BLEND_BEFORE:-1}" "${TL_BLEND_AFTER:-1}" "${TL_OUT_FPS:-30}" "$(tl_gop_summary)"
      ;;
    *)
      printf 'plain, %s' "$(tl_gop_summary)"
      ;;
  esac
}

tl_gop_summary() {
  case "${TL_GOP_MODE:-default}" in
    seconds)
      printf 'keyframe every %ss' "$TL_GOP_SECONDS"
      ;;
    frames)
      printf 'keyframe every %s frames' "$TL_GOP_FRAMES"
      ;;
    *)
      printf 'encoder keyframe default'
      ;;
  esac
}

# Place a test clip. Sets TL_SS, TL_OUT_T, and TL_TEST_OUT_DUR.
tl_set_test_window() {
  local dur="$1" speed="$2"
  local start span_src span_out remain
  if [[ -z "$dur" ]]; then
    echo "$(tl_ts) Test clip needs a duration, and this file has none." >&2
    return 1
  fi
  start="$(awk -v d="$dur" -v p="$TL_TEST_PERCENT" 'BEGIN { printf "%.3f", d * p / 100 }')"
  span_out=$(( TL_TEST_MINUTES * 60 ))
  span_src="$(awk -v o="$span_out" -v s="$speed" 'BEGIN { printf "%.3f", o * s }')"
  remain="$(awk -v d="$dur" -v a="$start" 'BEGIN { printf "%.3f", d - a }')"
  if ! awk -v r="$remain" 'BEGIN { exit !(r + 0 > 1) }'; then
    echo "$(tl_ts) Test clip starts past the end of the file." >&2
    return 1
  fi
  if awk -v a="$span_src" -v r="$remain" 'BEGIN { exit !(a > r) }'; then
    span_src="$remain"
    span_out="$(awk -v r="$remain" -v s="$speed" 'BEGIN { printf "%.3f", r / s }')"
    echo "$(tl_ts) Test clip shortened to the time left in the file."
  fi
  if awk -v a="$start" 'BEGIN { exit !(a >= 0.05) }'; then
    TL_SS="$start"
  else
    TL_SS=""
  fi
  TL_OUT_T="$span_out"
  TL_TEST_OUT_DUR="$span_out"
  if (( TL_TEST_PERCENT == 0 )); then
    echo "$(tl_ts) Test clip: $(tl_minutes_word "$TL_TEST_MINUTES") of output from the beginning (reading $(tl_format_seconds "$span_src"))."
  else
    echo "$(tl_ts) Test clip: $(tl_minutes_word "$TL_TEST_MINUTES") of output from ${TL_TEST_PERCENT}% (source $(tl_format_clock "$start"), reading $(tl_format_seconds "$span_src"))."
  fi
}

tl_prompt_blend_count() {
  local side="$1" dest="$2" answer=""
  printf 'Frames %s the kept frame [1]: ' "$side"
  IFS= read -r answer || answer=""
  if [[ -z "$answer" ]]; then
    answer=1
  fi
  if [[ ! "$answer" =~ ^[0-9]+$ ]] || (( answer > 8 )); then
    echo "$(tl_ts) Invalid blend count: ${answer} (use 0 to 8). Using 1." >&2
    answer=1
  fi
  printf -v "$dest" '%s' "$answer"
}

tl_prompt_out_fps() {
  local choice=""
  echo
  echo "Output frames per second?"
  echo "  [3] 30 fps (default)"
  echo "      On a 60 Hz screen each picture stays for two refreshes,"
  echo "      so the fast-slow pulse goes away."
  echo "  [6] 60 fps"
  echo "      One refresh per picture on a 60 Hz screen."
  echo "  [2] 25 fps"
  echo "      The same rate as this dashcam."
  tl_read_key "Frames per second [3/6/2]: " 3
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    3) TL_OUT_FPS=30 ;;
    6) TL_OUT_FPS=60 ;;
    2) TL_OUT_FPS=25 ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; using 30 fps."
      TL_OUT_FPS=30
      ;;
  esac
}

tl_prompt_picture() {
  local choice=""
  echo
  echo "Picture [P/t/b]"
  echo "  [P] Plain (default)"
  echo "      Keep one frame and drop the next ones, then play the kept"
  echo "      frames at 25 fps, the same rate as this dashcam."
  echo "      Enter leaves the encode as it is today."
  echo "  [t] Steady"
  echo "      Speed the timeline up, then lay the pictures on a chosen"
  echo "      frame rate (setpts=PTS/N,fps=…). 30 fps sits evenly on a"
  echo "      60 Hz screen."
  echo "  [b] Soft"
  echo "      Average a few frames before and after each kept picture,"
  echo "      then use that same steady frame rate. The road and the"
  echo "      camera shake smear a little instead of jumping."
  tl_read_key "Picture [P/t/b]: " p
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    p) TL_PICTURE=plain ;;
    t) TL_PICTURE=steady ;;
    b) TL_PICTURE=soft ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; using plain."
      TL_PICTURE=plain
      ;;
  esac
  if [[ "$TL_PICTURE" == soft ]]; then
    echo
    echo "How many neighboring frames should be averaged?"
    echo "  Enter uses 1 before and 1 after (0.12 seconds at 25 fps)."
    echo "  If the road still jumps, try 2 and 2, then 4 and 4."
    echo "  Each side can be 0 to 8."
    TL_BLEND_BEFORE=1
    TL_BLEND_AFTER=1
    tl_prompt_blend_count before TL_BLEND_BEFORE
    tl_prompt_blend_count after TL_BLEND_AFTER
    if (( TL_BLEND_BEFORE == 0 && TL_BLEND_AFTER == 0 )); then
      echo "$(tl_ts) No frames to blend. Using steady instead."
      TL_PICTURE=steady
    fi
  fi
  if [[ "$TL_PICTURE" != plain ]]; then
    tl_prompt_out_fps
  fi
}

tl_prompt_encoder_menu() {
  local choice=""
  if (( ENCODER_FROM_CLI )); then
    return 0
  fi
  echo
  echo "Encoder [A/n/4/5]"
  echo "  [A] Auto (default)"
  echo "      Match the source codec. HEVC tries hevc_nvenc on the GPU,"
  echo "      then libx265 on the CPU. H.264 tries h264_nvenc, then libx264."
  echo "  [n] hevc_nvenc"
  echo "      GPU hardware. One encoder, with no CPU fallback."
  echo "  [4] libx264"
  echo "      CPU only. Writes H.264."
  echo "  [5] libx265"
  echo "      CPU only. Writes HEVC without the GPU."
  tl_read_key "Encoder [A/n/4/5]: " a
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    a) ENCODER=auto ;;
    n) ENCODER=nvenc ;;
    4) ENCODER=x264 ;;
    5) ENCODER=x265 ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; using auto."
      ENCODER=auto
      ;;
  esac
}

tl_prompt_gop() {
  local choice="" answer=""
  echo
  echo "Keyframe spacing [D/s/c/f]"
  echo "  [D] Encoder default"
  echo "      Leave the interval to hevc_nvenc or libx265. That is often"
  echo "      about 10 seconds. Fine when you watch straight through."
  echo "      Enter keeps this."
  echo "  [s] Same as the source"
  echo "      This dashcam places a keyframe every 1 second. The output"
  echo "      gets that same one second. At 30 fps that is 30 frames;"
  echo "      at 25 fps it is 25 frames."
  echo "  [c] Custom seconds"
  echo "      Type how often, in seconds of the output, a keyframe is written."
  echo "  [f] Custom frames"
  echo "      Type a frame count of the output, not of the dashcam."
  tl_read_key "Keyframe spacing [D/s/c/f]: " d
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    d)
      TL_GOP_MODE=default
      ;;
    s)
      TL_GOP_MODE=seconds
      TL_GOP_SECONDS=1
      ;;
    c)
      tl_read_line "Seconds between keyframes [1]: " 1
      answer="$REPLY"
      if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= 60 )); then
        TL_GOP_MODE=seconds
        TL_GOP_SECONDS="$answer"
      else
        echo "$(tl_ts) Invalid seconds: ${answer} (use 1 to 60). Using the encoder default."
        TL_GOP_MODE=default
      fi
      ;;
    f)
      tl_read_line "Frames between keyframes [30]: " 30
      answer="$REPLY"
      if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= 3000 )); then
        TL_GOP_MODE=frames
        TL_GOP_FRAMES="$answer"
      else
        echo "$(tl_ts) Invalid frame count: ${answer} (use 1 to 3000). Using the encoder default."
        TL_GOP_MODE=default
      fi
      ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; using the encoder default."
      TL_GOP_MODE=default
      ;;
  esac
}

# Whole-file keyframe gaps from packet headers, plus a decoded timing sample.
tl_scan_source() {
  local src="$1" minutes="$2" sample_sec gap_line frame_line
  sample_sec=$(( minutes * 60 ))
  echo
  echo "$(tl_ts) Keyframes: the whole file, from packet headers. This does not decode pictures, and it is not limited to the $(tl_minutes_word "$minutes") you chose."
  gap_line="$(ffprobe -v error -select_streams v:0 -show_entries packet=pts_time,flags -of csv=p=0 -- "$src" 2>/dev/null | awk -F, '
    $1 ~ /^[0-9]/ && $2 ~ /K/ {
      if (have) {
        d = $1 - prev
        if (d >= 0.05) {
          key = sprintf("%.3f", d)
          count[key]++
          n++
          if (count[key] > best_n) { best_n = count[key]; best = key }
        }
      }
      prev = $1
      have = 1
      kf++
    }
    END {
      if (kf + 0 == 0) { print "none"; exit }
      other = n - best_n
      printf "%d %s %d %d\n", kf, best, best_n, other
    }' || true)"
  echo "$(tl_ts) Pictures: decoding the first $(tl_minutes_word "$minutes") you chose, to check frame timing..."
  frame_line="$(ffprobe -v error -select_streams v:0 -show_entries frame=duration_time -of csv=p=0 -read_intervals "%+${sample_sec}" -- "$src" 2>/dev/null | awk '
    $1 ~ /^[0-9]/ {
      key = sprintf("%.3f", $1 + 0)
      count[key]++
      n++
      if (count[key] > best_n) { best_n = count[key]; best = key }
    }
    END {
      if (n + 0 == 0) { print "none"; exit }
      printf "%d %s %d\n", n, best, best_n
    }' || true)"
  echo
  echo "Scan of ${src##*/}"
  TL_SCAN_GAP=""
  if [[ "$gap_line" == none || -z "$gap_line" ]]; then
    echo "  Keyframes: none found"
  else
    # shellcheck disable=SC2086
    set -- $gap_line
    echo "  Keyframes: $1 across the whole file"
    echo "  Most gaps: ${2}s (${3})"
    echo "  Other gaps: ${4} (a clip join is often shorter than the camera interval)"
    TL_SCAN_GAP="$2"
  fi
  if [[ "$frame_line" == none || -z "$frame_line" ]]; then
    echo "  Frame timing: no frames decoded"
  else
    # shellcheck disable=SC2086
    set -- $frame_line
    echo "  Frame timing, first $(tl_minutes_word "$minutes"): $1 frames, most of them ${2}s (${3})"
  fi
  if (( ${#TL_INPUTS[@]} > 1 )); then
    echo "  Scanned the first file. The others are assumed to be the same camera."
  fi
}

tl_apply_scan_suggestion() {
  local choice="" gap_note="the encoder default (no keyframe gap was measured)"
  local suggest_seconds=""
  echo
  if [[ -n "$TL_SCAN_GAP" ]]; then
    suggest_seconds="$(awk -v g="$TL_SCAN_GAP" 'BEGIN {
      if (g >= 0.95 && g <= 1.05) { printf "1"; exit }
      n = int(g + 0.5)
      if (n < 1) n = 1
      printf "%d", n
    }')"
    gap_note="every ${suggest_seconds}s, like the source"
  fi
  if [[ "$TL_PICTURE" == soft ]]; then
    echo "Suggestion: keep the blend, use ${TL_OUT_FPS:-30} fps, keyframe ${gap_note}."
  else
    echo "Suggestion: steady 30 fps, keyframe ${gap_note}."
    echo "  30 fps is the rate that sits evenly on a 60 Hz screen."
  fi
  echo "  [N] Keep the choices you already made (default)"
  echo "  [y] Apply this suggestion"
  tl_read_key "Apply suggestion? [N/y]: " n
  choice="$(tl_choice "$REPLY")"
  if [[ "$choice" != y ]]; then
    echo "$(tl_ts) Keeping the choices already made."
    return 0
  fi
  if [[ "$TL_PICTURE" != soft ]]; then
    TL_PICTURE=steady
    TL_OUT_FPS=30
  fi
  if [[ -n "$suggest_seconds" ]]; then
    TL_GOP_MODE=seconds
    TL_GOP_SECONDS="$suggest_seconds"
  fi
  echo "$(tl_ts) Applied. Picture: $(tl_picture_summary)"
}

tl_prompt_scan() {
  local choice=""
  echo
  echo "Scan the source before encoding? [N/y]"
  echo "  [N] Skip the scan (default)"
  echo "      Encode with the choices above."
  echo "  [y] Read this file"
  echo "      Keyframe spacing comes from the whole file, without decoding"
  echo "      pictures. Frame timing is decoded for a piece at the start."
  tl_read_key "Scan the source? [N/y]: " n
  choice="$(tl_choice "$REPLY")"
  if [[ "$choice" != y ]]; then
    return 0
  fi
  echo
  echo "How long a piece of pictures should be decoded? [2/5/t]"
  echo "  Keyframe spacing is a separate pass over the whole file."
  echo "  It reads packet headers and does not decode pictures."
  echo "  These minutes are only the piece at the start that we decode"
  echo "  to check that each frame lasts the same time."
  echo "  [2] 2 minutes"
  echo "      A shorter look. It may still be a single clip."
  echo "  [5] 5 minutes (default)"
  echo "      Long enough to cross several dashcam clips."
  echo "  [t] 10 minutes"
  echo "      A longer look. Decoding it takes a few minutes."
  tl_read_key "Decode length [2/5/t]: " 5
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    2) TL_SCAN_MINUTES=2 ;;
    5) TL_SCAN_MINUTES=5 ;;
    t) TL_SCAN_MINUTES=10 ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; using 5 minutes."
      TL_SCAN_MINUTES=5
      ;;
  esac
  tl_scan_source "${TL_INPUTS[0]}" "$TL_SCAN_MINUTES"
  tl_apply_scan_suggestion
}

tl_prompt_test_clip() {
  local choice=""
  echo
  echo "Test clip instead of the whole file? [N/y]"
  echo "  [N] Whole file (default)"
  echo "      Encode the full sped-up drive."
  echo "  [y] A short piece of the result you will watch"
  echo "      So you can judge the picture before waiting for the whole file."
  tl_read_key "Test clip? [N/y]: " n
  choice="$(tl_choice "$REPLY")"
  if [[ "$choice" != y ]]; then
    TL_TEST=0
    return 0
  fi
  TL_TEST=1
  echo
  echo "How long should the result be? [1/2/5]"
  echo "  [1] 1 minute of output (default)"
  echo "      At 20× this reads 20 minutes of the dashcam."
  echo "  [2] 2 minutes of output"
  echo "  [5] 5 minutes of output"
  tl_read_key "Clip length [1/2/5]: " 1
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    1) TL_TEST_MINUTES=1 ;;
    2) TL_TEST_MINUTES=2 ;;
    5) TL_TEST_MINUTES=5 ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; using 1 minute."
      TL_TEST_MINUTES=1
      ;;
  esac
  echo
  echo "Where should the clip start? [B/1/2/3/5/7/9]"
  echo "  [B] Beginning (default)"
  echo "  [1] 10%   [2] 20%   [3] 30%"
  echo "  [5] 50%   [7] 70%   [9] 90%"
  echo "      The percentage is of this file. The script prints the clock time."
  tl_read_key "Start at [B/1/2/3/5/7/9]: " b
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    b) TL_TEST_PERCENT=0 ;;
    1) TL_TEST_PERCENT=10 ;;
    2) TL_TEST_PERCENT=20 ;;
    3) TL_TEST_PERCENT=30 ;;
    5) TL_TEST_PERCENT=50 ;;
    7) TL_TEST_PERCENT=70 ;;
    9) TL_TEST_PERCENT=90 ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; starting at the beginning."
      TL_TEST_PERCENT=0
      ;;
  esac
}

# Asked once. Enter keeps today's encode: every Nth frame, the whole file.
tl_prompt_advanced() {
  local choice=""
  TL_PICTURE=plain
  TL_BLEND_BEFORE=1
  TL_BLEND_AFTER=1
  TL_OUT_FPS=30
  TL_GOP_MODE=default
  TL_GOP_SECONDS=1
  TL_GOP_FRAMES=30
  TL_TEST=0
  TL_TEST_MINUTES=1
  TL_TEST_PERCENT=0
  TL_SS=""
  TL_OUT_T=""
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  echo
  echo "Advanced encoding? [N/y]"
  echo "  [N] Plain (default)"
  echo "      Every Nth frame, played at 25 fps, for the whole file."
  echo "  [y] Choose the picture, the keyframes, a source scan,"
  echo "      and an optional test clip."
  tl_read_key "Advanced encoding? [N/y]: " n
  choice="$(tl_choice "$REPLY")"
  if [[ "$choice" != y ]]; then
    return 0
  fi
  tl_prompt_picture
  tl_prompt_encoder_menu
  tl_prompt_gop
  tl_prompt_scan
  tl_prompt_test_clip
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
ENCODER_FROM_CLI=0
if [[ -n "${PGM_TIMELAPSE_ENCODER:-}" ]]; then
  ENCODER_FROM_CLI=1
fi
TL_DISPLAY="${PGM_TIMELAPSE_DISPLAY:-}"
TL_DISPLAY_FROM_CLI=0
SPEED_FROM_CLI=0
TL_INPUTS=()
TL_PARTIAL=""
TL_ENC_ARGS=()
TL_ENC_KIND=""
TL_ENCODER_LIST=""
TL_PICTURE=plain
TL_BLEND_BEFORE=1
TL_BLEND_AFTER=1
TL_OUT_FPS=30
TL_GOP_MODE=default
TL_GOP_SECONDS=1
TL_GOP_FRAMES=30
TL_SCAN_GAP=""
TL_SCAN_MINUTES=5
TL_TEST=0
TL_TEST_MINUTES=1
TL_TEST_PERCENT=0
TL_TEST_OUT_DUR=""
TL_SS=""
TL_OUT_T=""
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
      ENCODER_FROM_CLI=1
      shift 2
      ;;
    --encoder=*)
      ENCODER="${1#--encoder=}"
      ENCODER_FROM_CLI=1
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

tl_print_ffmpeg_version
if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
  echo "$(tl_ts) ffmpeg and ffprobe are required." >&2
  exit 1
fi
tl_prompt_display
tl_load_encoders
tl_prompt_advanced
tl_encoder_candidates "$ENCODER" "" >/dev/null || {
  echo "$(tl_ts) No usable video encoder for '${ENCODER}'." >&2
  tl_note_encoder_probe_failure
  exit 1
}

echo "$(tl_ts) Speed: ${SPEED}×    files: ${#TL_INPUTS[@]}    encoder request: ${ENCODER}    display: ${TL_DISPLAY}"
echo "$(tl_ts) Picture: $(tl_picture_summary)"
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
