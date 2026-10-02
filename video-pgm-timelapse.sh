#!/bin/bash
# v. 20261002.092400 - an existing output is explained, then keep, replace, rename, or a new name
# v. 20261002.084500 - print the equivalent command and confirm before encoding
# v. 20261002.084000 - speed menu lists q to quit
# v. 20261002.083700 - speed menu defaults to 5× and always omits audio
# v. 20261002.081600 - keyframe sample is 2 minutes, or minutes or a percent you type
# v. 20261002.081500 - same-as-source keyframes are measured, not assumed to be 1 second
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

# 2026.10.02 - v. 0.19 - an existing output is explained, then keep, replace, rename, or a new name
# 2026.10.02 - v. 0.18 - each choice has a command-line option; show that command and confirm before encoding
# 2026.10.02 - v. 0.17 - speed menu lists q to quit
# 2026.10.02 - v. 0.16 - speed menu is 2, 5, 10, 15, 20, 25, 30, or custom; default 5×; audio is always omitted
# 2026.10.02 - v. 0.15 - same as the source reads the first 2 minutes, or a typed number of minutes or a percent
# 2026.10.02 - v. 0.14 - same as the source measures this file's keyframe gap instead of assuming 1 second
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
       [-y|--yes] [--redo] [--speed N] [--display normal|verbose]
       [--picture plain|steady|soft] [--blend-before N] [--blend-after N]
       [--fps 25|30|60] [--encoder auto|nvenc|x264|x265]
       [--gop default|source|Ns|Nf]
       [--keyframe-minutes N | --keyframe-percent N]
       [--scan-minutes 2|5|10]
       [--test-minutes 1|2|5] [--test-at N]
       [FILE|DIR ...]

Write a faster copy beside each video. A 10× copy of a two-hour drive is about
twelve minutes. The original file is not changed.

With no FILE or DIR, use the current directory. If that directory contains
*_concat.mp4 files, only those are used. Otherwise every other .mp4 in the
directory is used. Files already named *_xN.mp4 are skipped.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask. Encode with the options below.
  --speed N            Integer speed, 2 to 240. Default 5.
                       Audio is always omitted.
  --display MODE       normal (progress bar) or verbose (frames).
  --verbose            Same as --display verbose.
  --picture MODE       plain (every Nth frame at 25 fps), steady, or soft.
  --blend-before N     Frames before the kept one. 0 to 8. Soft only.
  --blend-after N      Frames after the kept one. 0 to 8. Soft only.
  --fps N              25, 30, or 60. Steady and soft only. Default 30.
  --encoder KIND       auto (default), nvenc, x264, or x265.
                       auto follows the source codec. HEVC prefers hevc_nvenc,
                       then libx265. H.264 prefers h264_nvenc, then libx264.
                       A missing or failed encoder falls through to the next.
                       nvenc, x264, and x265 force that one encoder.
  --gop SPEC           default, source, a number of seconds (2s), or frames (30f).
  --keyframe-minutes N Read this many minutes from the start when --gop source.
                       Default 2.
  --keyframe-percent N Read this percent from the start when --gop source.
                       100 is the whole file.
  --scan-minutes N     Decode 2, 5, or 10 minutes to check frame timing.
  --test-minutes N     Encode 1, 2, or 5 minutes of the result, not the whole file.
  --test-at N          Where the test starts: 0, 10, 20, 30, 50, 70, or 90.
                       0 is the beginning.
  --redo               Replace an existing *_xN.mp4.
                       Without this, an interactive run asks whether to keep,
                       replace, rename, or write a new name. -y skips the file
                       and prints which output is already there.

An interactive run asks the questions, then prints the equivalent command and
asks whether to encode. Answering no walks the questions again, and Enter
keeps each current answer. -y skips the questions and that confirmation.
A pasted command with -y encodes without asking.

Environment:
  PGM_TIMELAPSE_SPEED     Same as --speed.
  PGM_TIMELAPSE_ENCODER   Same as --encoder (auto, nvenc, x264, x265).
  PGM_TIMELAPSE_DISPLAY   normal (default) or verbose. verbose matches --verbose.

Examples:
  $(basename "$0") --speed 10 trip_concat.mp4
  $(basename "$0") -y --speed 20 --picture steady --fps 30 trip_concat.mp4
  $(basename "$0") -y --speed 5 --gop source --keyframe-minutes 2 trip_concat.mp4
  $(basename "$0")
      Ask the questions (speed defaults to 5×), then confirm before encoding.
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
  [[ "$base" =~ _x[0-9]+(_test-[0-9]+m-at[0-9]+)?(_[0-9]{8}-[0-9]{6}(_[0-9]+)?|_[0-9]+)?\.[mM][pP]4$ ]]
}

tl_human_size() {
  awk -v b="${1:-0}" 'BEGIN {
    split("B K M G T", u, " ")
    i = 1
    if (b !~ /^[0-9]+$/) b = 0
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    if (i == 1) printf "%d%s", b, u[i]
    else printf "%.1f%s", b, u[i]
  }'
}

tl_existing_note() {
  local dest="$1" bytes="" when=""
  bytes="$(stat -c %s -- "$dest" 2>/dev/null || true)"
  when="$(date -d "@$(stat -c %Y -- "$dest" 2>/dev/null || echo 0)" '+%Y.%m.%d %H:%M' 2>/dev/null || true)"
  echo "Output already exists"
  echo "  ${dest}"
  if [[ -n "$bytes" && -n "$when" ]]; then
    echo "  $(tl_human_size "$bytes"), written ${when}"
  fi
}

# Old file moved aside: same name plus the time it was written.
tl_aside_name() {
  local dest="$1" dir stem when candidate n=0
  dir="$(dirname -- "$dest")"
  stem="$(basename -- "$dest")"
  stem="${stem%.*}"
  when="$(date -d "@$(stat -c %Y -- "$dest")" '+%Y%m%d-%H%M%S')"
  candidate="${dir}/${stem}_${when}.mp4"
  while [[ -e "$candidate" ]]; do
    n=$((n + 1))
    candidate="${dir}/${stem}_${when}_${n}.mp4"
  done
  printf '%s\n' "$candidate"
}

# Next free take: stem_x5_2.mp4, then _3, and so on.
tl_next_take_name() {
  local dest="$1" dir stem n=2 candidate
  dir="$(dirname -- "$dest")"
  stem="$(basename -- "$dest")"
  stem="${stem%.*}"
  while true; do
    candidate="${dir}/${stem}_${n}.mp4"
    [[ -e "$candidate" ]] || break
    n=$((n + 1))
  done
  printf '%s\n' "$candidate"
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
  local src="$1" dest="$2" speed="$3" total_sec="${4:-}"
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
  enc_args+=(
    -an
    -filter:v "$vfilter"
    "${TL_ENC_ARGS[@]}"
  )
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
  local dest dur out_dur="" kind label label_prev="" src_codec i where gop_fps
  local -a kinds=()
  if [[ -n "${TL_DEST_OVERRIDE:-}" ]]; then
    dest="$TL_DEST_OVERRIDE"
    TL_DEST_OVERRIDE=""
  else
    dest="$(tl_output_path "$src" "$speed")"
  fi
  if [[ -e "$dest" && "$redo" -eq 0 ]]; then
    echo "$(tl_ts) Already exists, skipping: ${dest}"
    return 0
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
  echo "$(tl_ts) Audio: omitted"
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
    if tl_run_ffmpeg "$src" "$dest" "$speed" "$out_dur"; then
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

tl_speed_menu_key() {
  case "${1:-5}" in
    2) printf '1\n' ;;
    5) printf '2\n' ;;
    10) printf '3\n' ;;
    15) printf '4\n' ;;
    20) printf '5\n' ;;
    25) printf '6\n' ;;
    30) printf '7\n' ;;
    *) printf 'c\n' ;;
  esac
}

tl_test_start_key() {
  case "${1:-0}" in
    0) printf 'b\n' ;;
    10) printf '1\n' ;;
    20) printf '2\n' ;;
    30) printf '3\n' ;;
    50) printf '5\n' ;;
    70) printf '7\n' ;;
    90) printf '9\n' ;;
    *) printf 'b\n' ;;
  esac
}

tl_reset_advanced() {
  TL_ADV_ON=0
  TL_PICTURE=plain
  TL_BLEND_BEFORE=1
  TL_BLEND_AFTER=1
  TL_OUT_FPS=30
  TL_GOP_MODE=default
  TL_GOP_KIND=default
  TL_GOP_SECONDS=1
  TL_GOP_FRAMES=30
  TL_DO_SCAN=0
  TL_TEST=0
  TL_TEST_MINUTES=1
  TL_TEST_PERCENT=0
  TL_SS=""
  TL_OUT_T=""
}

tl_equivalent_command() {
  local -a cmd=()
  local f part out=""
  cmd+=("$(basename "$0")" -y --speed "${SPEED:-5}" --display "${TL_DISPLAY:-normal}")
  cmd+=(--picture "${TL_PICTURE:-plain}")
  if [[ "${TL_PICTURE:-plain}" == soft ]]; then
    cmd+=(--blend-before "${TL_BLEND_BEFORE:-1}" --blend-after "${TL_BLEND_AFTER:-1}")
  fi
  if [[ "${TL_PICTURE:-plain}" != plain ]]; then
    cmd+=(--fps "${TL_OUT_FPS:-30}")
  fi
  cmd+=(--encoder "${ENCODER:-auto}")
  case "${TL_GOP_KIND:-default}" in
    source)
      cmd+=(--gop source)
      if [[ "${TL_KF_UNIT:-minutes}" == percent ]]; then
        cmd+=(--keyframe-percent "${TL_KF_PERCENT:-10}")
      else
        cmd+=(--keyframe-minutes "${TL_KF_MINUTES:-2}")
      fi
      ;;
    seconds) cmd+=(--gop "${TL_GOP_SECONDS}s") ;;
    frames) cmd+=(--gop "${TL_GOP_FRAMES}f") ;;
    *) cmd+=(--gop default) ;;
  esac
  if (( ${TL_DO_SCAN:-0} )); then
    cmd+=(--scan-minutes "$TL_SCAN_MINUTES")
  fi
  if (( ${TL_TEST:-0} )); then
    cmd+=(--test-minutes "$TL_TEST_MINUTES" --test-at "$TL_TEST_PERCENT")
  fi
  if (( REDO )); then
    cmd+=(--redo)
  fi
  cmd+=(--)
  for f in "${TL_INPUTS[@]}"; do
    cmd+=("$f")
  done
  for part in "${cmd[@]}"; do
    printf -v part '%q' "$part"
    out+="${out:+ }${part}"
  done
  printf '%s\n' "$out"
}

tl_print_plan() {
  echo
  echo "Chosen"
  printf '  %-18s %s\n' "Speed" "${SPEED}×"
  if [[ "${TL_DISPLAY:-normal}" == verbose ]]; then
    printf '  %-18s %s\n' "Display" "verbose (frames)"
  else
    printf '  %-18s %s\n' "Display" "normal (progress bar)"
  fi
  local pic="" kf=""
  case "${TL_PICTURE:-plain}" in
    steady) pic="steady, ${TL_OUT_FPS:-30} fps" ;;
    soft) pic="soft, ${TL_BLEND_BEFORE:-1} before, ${TL_BLEND_AFTER:-1} after, ${TL_OUT_FPS:-30} fps" ;;
    *) pic="plain, every Nth frame at 25 fps" ;;
  esac
  kf="$(tl_gop_summary)"
  if [[ "${TL_GOP_KIND:-default}" == source && -n "${TL_SCAN_GAP:-}" ]]; then
    kf+=", measured ${TL_SCAN_GAP}s"
  fi
  printf '  %-18s %s\n' "Picture" "$pic"
  printf '  %-18s %s\n' "Encoder" "$ENCODER"
  printf '  %-18s %s\n' "Keyframes" "$kf"
  if (( ${TL_DO_SCAN:-0} )); then
    printf '  %-18s %s\n' "Picture scan" "first $(tl_minutes_word "$TL_SCAN_MINUTES")"
  else
    printf '  %-18s %s\n' "Picture scan" "no"
  fi
  if (( ${TL_TEST:-0} )); then
    if (( TL_TEST_PERCENT == 0 )); then
      printf '  %-18s %s\n' "Test clip" "$(tl_minutes_word "$TL_TEST_MINUTES") of output from the beginning"
    else
      printf '  %-18s %s\n' "Test clip" "$(tl_minutes_word "$TL_TEST_MINUTES") of output from ${TL_TEST_PERCENT}%"
    fi
  else
    printf '  %-18s %s\n' "Test clip" "whole file"
  fi
  echo
  echo "Command"
  echo "  $(tl_equivalent_command)"
  echo
  echo "Proceed with these choices? [Y/n/q]"
  echo "  [Y] Encode (default)"
  echo "  [n] Go through the questions again. Enter keeps each answer above."
  echo "  [q] Quit"
}

tl_prepare_unattended() {
  local src="${TL_INPUTS[0]}"
  [[ -n "$SPEED" ]] || SPEED=5
  [[ -n "$TL_DISPLAY" ]] || TL_DISPLAY=normal
  if [[ "${TL_GOP_KIND:-default}" == source ]]; then
    TL_KEYFRAME_MEASURED=0
    TL_SCAN_GAP=""
    if [[ "${TL_KF_UNIT:-minutes}" == percent ]]; then
      tl_keyframe_span_percent "$src" "${TL_KF_PERCENT:-10}"
    else
      tl_keyframe_span_minutes "$src" "${TL_KF_MINUTES:-2}"
    fi
    if tl_measure_keyframe_gap "$src" "${TL_KF_LIMIT_SEC:-}"; then
      TL_GOP_MODE=seconds
      TL_GOP_SECONDS="$(tl_gap_seconds_from_measured "$TL_SCAN_GAP")"
      echo "$(tl_ts) Most source gaps are ${TL_SCAN_GAP}s. Output keyframes: every ${TL_GOP_SECONDS}s."
    else
      echo "$(tl_ts) No keyframe spacing found. Using the encoder default."
      TL_GOP_KIND=default
      TL_GOP_MODE=default
    fi
  fi
  if (( ${TL_DO_SCAN:-0} )); then
    tl_scan_source "$src" "$TL_SCAN_MINUTES"
  fi
}

tl_prompt_speed() {
  local choice="" answer="" cur def five_note="" custom_def=5
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    SPEED="${SPEED:-${PGM_TIMELAPSE_SPEED:-5}}"
    tl_is_speed "$SPEED" || SPEED=5
    return 0
  fi
  cur="${SPEED:-5}"
  tl_is_speed "$cur" || cur=5
  def="$(tl_speed_menu_key "$cur")"
  if [[ "$def" == c ]]; then
    custom_def="$cur"
  fi
  [[ "$def" == 2 ]] && five_note=" (default)"
  echo "How much faster? [1/2/3/4/5/6/7/c/q]"
  echo
  echo "  [1]  2×"
  echo "  [2]  5×${five_note}"
  echo "  [3] 10×"
  echo "  [4] 15×"
  echo "  [5] 20×"
  echo "  [6] 25×"
  echo "  [7] 30×"
  echo "  [c] Custom  type an integer from 2 to 240"
  echo "  [q] Quit"
  echo
  tl_read_key "Speed [${def}]: " "$def"
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    1) SPEED=2 ;;
    2) SPEED=5 ;;
    3) SPEED=10 ;;
    4) SPEED=15 ;;
    5) SPEED=20 ;;
    6) SPEED=25 ;;
    7) SPEED=30 ;;
    c)
      tl_read_line "Custom speed [${custom_def}]: " "$custom_def"
      answer="$REPLY"
      if tl_is_speed "$answer"; then
        SPEED="$answer"
      elif tl_is_speed "${SPEED:-}"; then
        echo "$(tl_ts) Invalid speed: ${answer} (use an integer from 2 to 240). Keeping ${SPEED}."
      else
        echo "$(tl_ts) Invalid speed: ${answer} (use an integer from 2 to 240). Using 5."
        SPEED=5
      fi
      ;;
    q)
      echo "$(tl_ts) Quit."
      return 2
      ;;
    *)
      if tl_is_speed "${SPEED:-}"; then
        echo "$(tl_ts) Unknown choice: ${REPLY}. Keeping ${SPEED}."
      else
        echo "$(tl_ts) Unknown choice: ${REPLY}. Using 5."
        SPEED=5
      fi
      ;;
  esac
  return 0
}

tl_prompt_existing_output() {
  local dest="$1" choice="" aside="" next=""
  tl_existing_note "$dest"
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    echo "$(tl_ts) Skipping. Add --redo to replace it."
    REPLY=skip
    TL_SKIP_EXPLAINED=1
    return 0
  fi
  aside="$(tl_aside_name "$dest")"
  next="$(tl_next_take_name "$dest")"
  echo
  echo "This file was not encoded. [K/r/m/n/q]"
  echo "  [K] Keep it and skip (default)"
  echo "  [r] Replace it with this encode"
  echo "  [m] Rename it, then encode to the usual name"
  echo "      ${aside##*/}"
  echo "  [n] Leave it, and write this encode under a new name"
  echo "      ${next##*/}"
  echo "  [q] Quit"
  tl_read_key "Existing file [K/r/m/n/q]: " k
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    k)
      echo "$(tl_ts) Kept existing file: ${dest}"
      REPLY=skip
      TL_SKIP_EXPLAINED=1
      ;;
    r)
      echo "$(tl_ts) Replacing ${dest}"
      REPLY=redo
      ;;
    m)
      if ! mv -n -- "$dest" "$aside"; then
        echo "$(tl_ts) Could not rename ${dest}. Skipping." >&2
        REPLY=skip
        TL_SKIP_EXPLAINED=1
        return 0
      fi
      echo "$(tl_ts) Renamed the old file to ${aside}"
      REPLY=encode
      ;;
    n)
      TL_DEST_OVERRIDE="$next"
      echo "$(tl_ts) New file: ${next}"
      REPLY=encode
      ;;
    q)
      REPLY=quit
      ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}. Kept existing file: ${dest}"
      REPLY=skip
      TL_SKIP_EXPLAINED=1
      ;;
  esac
}

tl_prompt_file_action() {
  local n="$1" total="$2" dest="$3"
  local choice=""
  REPLY=encode
  if (( DO_YES )) || (( ENCODE_ALL )); then
    if [[ -e "$dest" && "$REDO" -eq 0 ]]; then
      tl_prompt_existing_output "$dest"
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
  case "${TL_GOP_KIND:-default}" in
    source)
      if [[ "${TL_KF_UNIT:-minutes}" == percent ]]; then
        printf 'same as the source, first %s%%' "${TL_KF_PERCENT:-10}"
      else
        printf 'same as the source, first %s minutes' "${TL_KF_MINUTES:-2}"
      fi
      ;;
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
  local side="$1" dest="$2" cur="${!2:-1}" answer=""
  printf 'Frames %s the kept frame [%s]: ' "$side" "$cur"
  IFS= read -r answer || answer=""
  if [[ -z "$answer" ]]; then
    answer="$cur"
  fi
  if [[ ! "$answer" =~ ^[0-9]+$ ]] || (( answer > 8 )); then
    echo "$(tl_ts) Invalid blend count: ${answer} (use 0 to 8). Keeping ${cur}." >&2
    answer="$cur"
  fi
  printf -v "$dest" '%s' "$answer"
}

tl_prompt_out_fps() {
  local choice="" fkey=3
  case "${TL_OUT_FPS:-30}" in
    60) fkey=6 ;;
    25) fkey=2 ;;
    *) fkey=3; TL_OUT_FPS=30 ;;
  esac
  echo
  echo "Output frames per second?"
  echo "  [3] 30 fps"
  echo "      On a 60 Hz screen each picture stays for two refreshes,"
  echo "      so the fast-slow pulse goes away."
  echo "  [6] 60 fps"
  echo "      One refresh per picture on a 60 Hz screen."
  echo "  [2] 25 fps"
  echo "      The same rate as this dashcam."
  tl_read_key "Frames per second [3/6/2]: " "$fkey"
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    3) TL_OUT_FPS=30 ;;
    6) TL_OUT_FPS=60 ;;
    2) TL_OUT_FPS=25 ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; keeping ${TL_OUT_FPS} fps."
      ;;
  esac
}

tl_prompt_picture() {
  local choice="" pkey=p
  case "${TL_PICTURE:-plain}" in
    steady) pkey=t ;;
    soft) pkey=b ;;
    *) pkey=p; TL_PICTURE=plain ;;
  esac
  echo
  echo "Picture [P/t/b]"
  echo "  [P] Plain"
  echo "      Keep one frame and drop the next ones, then play the kept"
  echo "      frames at 25 fps, the same rate as this dashcam."
  echo "  [t] Steady"
  echo "      Speed the timeline up, then lay the pictures on a chosen"
  echo "      frame rate (setpts=PTS/N,fps=…). 30 fps sits evenly on a"
  echo "      60 Hz screen."
  echo "  [b] Soft"
  echo "      Average a few frames before and after each kept picture,"
  echo "      then use that same steady frame rate. The road and the"
  echo "      camera shake smear a little instead of jumping."
  tl_read_key "Picture [P/t/b]: " "$pkey"
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    p) TL_PICTURE=plain ;;
    t) TL_PICTURE=steady ;;
    b) TL_PICTURE=soft ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; keeping ${TL_PICTURE}."
      ;;
  esac
  if [[ "$TL_PICTURE" == soft ]]; then
    echo
    echo "How many neighboring frames should be averaged?"
    echo "  Enter keeps the number in brackets."
    echo "  If the road still jumps, try 2 and 2, then 4 and 4."
    echo "  Each side can be 0 to 8."
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
  local choice="" ekey=a
  case "${ENCODER:-auto}" in
    nvenc) ekey=n ;;
    x264) ekey=4 ;;
    x265) ekey=5 ;;
    *) ekey=a; ENCODER=auto ;;
  esac
  echo
  echo "Encoder [A/n/4/5]"
  echo "  [A] Auto"
  echo "      Match the source codec. HEVC tries hevc_nvenc on the GPU,"
  echo "      then libx265 on the CPU. H.264 tries h264_nvenc, then libx264."
  echo "  [n] hevc_nvenc"
  echo "      GPU hardware. One encoder, with no CPU fallback."
  echo "  [4] libx264"
  echo "      CPU only. Writes H.264."
  echo "  [5] libx265"
  echo "      CPU only. Writes HEVC without the GPU."
  tl_read_key "Encoder [A/n/4/5]: " "$ekey"
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    a) ENCODER=auto ;;
    n) ENCODER=nvenc ;;
    4) ENCODER=x264 ;;
    5) ENCODER=x265 ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; keeping ${ENCODER}."
      ;;
  esac
}

tl_gap_seconds_from_measured() {
  awk -v g="$1" 'BEGIN {
    if (g >= 0.95 && g <= 1.05) { printf "1"; exit }
    n = int(g + 0.5)
    if (n < 1) n = 1
    printf "%d", n
  }'
}

# Read keyframe gaps from packet headers.
# $2 is how many seconds from the start to read. Empty means the whole file.
# Sets TL_SCAN_GAP to the most common gap, in seconds. Returns 1 when none are found.
# A second call reuses the first result.
tl_measure_keyframe_gap() {
  local src="$1" limit_sec="${2:-}" gap_line kf="" best="" best_n="" other=""
  local -a probe=()
  if (( ${TL_KEYFRAME_MEASURED:-0} )); then
    [[ -n "${TL_SCAN_GAP:-}" ]]
    return
  fi
  TL_KEYFRAME_MEASURED=1
  TL_SCAN_GAP=""
  echo
  echo "$(tl_ts) Reading keyframes: ${TL_KF_READ_LABEL:-the file}."
  probe=(ffprobe -v error -select_streams v:0 -show_entries packet=pts_time,flags -of csv=p=0)
  if [[ -n "$limit_sec" ]]; then
    probe+=(-read_intervals "%+${limit_sec}")
  fi
  probe+=(-- "$src")
  gap_line="$("${probe[@]}" 2>/dev/null | awk -F, '
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
  if [[ "$gap_line" == none || -z "$gap_line" ]]; then
    echo "$(tl_ts) Keyframes: none found."
    return 1
  fi
  read -r kf best best_n other <<<"$gap_line"
  if [[ "${TL_KF_PIECE:-piece}" == file ]]; then
    echo "  Keyframes: ${kf} across the whole file"
  else
    echo "  Keyframes: ${kf} in this piece"
  fi
  echo "  Most gaps: ${best}s (${best_n})"
  echo "  Other gaps: ${other} (a clip join is often shorter than the usual interval)"
  TL_SCAN_GAP="$best"
  if (( ${#TL_INPUTS[@]} > 1 )); then
    echo "  Scanned the first file. The others are assumed to be the same camera."
  fi
  return 0
}

# Sets TL_KF_LIMIT_SEC (empty = whole file), TL_KF_PIECE, and TL_KF_READ_LABEL.
tl_keyframe_span_minutes() {
  local src="$1" minutes="$2" dur="" want=0
  dur="$(tl_ffprobe_duration "$src" || true)"
  want=$(( minutes * 60 ))
  TL_KF_PIECE=piece
  TL_KF_LIMIT_SEC="$want"
  TL_KF_READ_LABEL="first $(tl_minutes_word "$minutes") of ${src##*/} (packet headers, no picture decode)"
  if [[ -n "$dur" ]] && awk -v w="$want" -v d="$dur" 'BEGIN { exit !(w + 0 >= d - 0.5) }'; then
    echo "$(tl_ts) The file is $(tl_format_seconds "$dur"), shorter than $(tl_minutes_word "$minutes"). Reading the whole file."
    TL_KF_PIECE=file
    TL_KF_LIMIT_SEC=""
    TL_KF_READ_LABEL="the whole file (packet headers, no picture decode)"
  fi
}

tl_keyframe_span_percent() {
  local src="$1" pct="$2" dur="" want=""
  dur="$(tl_ffprobe_duration "$src" || true)"
  if [[ -z "$dur" ]]; then
    echo "$(tl_ts) This file has no duration, so a percent cannot be placed. Reading the first 2 minutes."
    tl_keyframe_span_minutes "$src" 2
    return 0
  fi
  if (( pct >= 100 )); then
    TL_KF_PIECE=file
    TL_KF_LIMIT_SEC=""
    TL_KF_READ_LABEL="the whole file (packet headers, no picture decode)"
    return 0
  fi
  want="$(awk -v d="$dur" -v p="$pct" 'BEGIN { printf "%.3f", d * p / 100 }')"
  TL_KF_PIECE=piece
  TL_KF_LIMIT_SEC="$want"
  TL_KF_READ_LABEL="first ${pct}% ($(tl_format_clock "$want") of $(tl_format_clock "$dur"))"
}

tl_prompt_keyframe_span() {
  local src="$1" choice="" answer="" def=2 min_def pct_def
  min_def="${TL_KF_MINUTES:-2}"
  pct_def="${TL_KF_PERCENT:-10}"
  if [[ "${TL_KF_UNIT:-minutes}" == percent ]]; then
    def=p
  elif [[ "$min_def" != 2 ]]; then
    def=m
  fi
  echo
  echo "How much of the file should be read for keyframes? [2/m/p]"
  echo "  [2] First 2 minutes"
  echo "      From the start of the file. Packet headers only, so pictures"
  echo "      are not decoded."
  echo "  [m] Minutes"
  echo "      Type how many minutes from the start. 5 or 10 crosses more"
  echo "      dashcam clips than 2 does."
  echo "  [p] Percent"
  echo "      Type a percent of this file, again from the start."
  echo "      10 is the first tenth. 100 is the whole file."
  tl_read_key "Keyframe sample [2/m/p]: " "$def"
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    2)
      TL_KF_UNIT=minutes
      TL_KF_MINUTES=2
      tl_keyframe_span_minutes "$src" 2
      ;;
    m)
      tl_read_line "Minutes from the start [${min_def}]: " "$min_def"
      answer="$REPLY"
      if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 )); then
        TL_KF_UNIT=minutes
        TL_KF_MINUTES="$answer"
        tl_keyframe_span_minutes "$src" "$answer"
      else
        echo "$(tl_ts) Invalid minutes: ${answer}. Reading the first ${min_def} minutes."
        TL_KF_UNIT=minutes
        TL_KF_MINUTES="$min_def"
        tl_keyframe_span_minutes "$src" "$min_def"
      fi
      ;;
    p)
      tl_read_line "Percent from the start [${pct_def}]: " "$pct_def"
      answer="$REPLY"
      if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= 100 )); then
        TL_KF_UNIT=percent
        TL_KF_PERCENT="$answer"
        tl_keyframe_span_percent "$src" "$answer"
      else
        echo "$(tl_ts) Invalid percent: ${answer} (use 1 to 100). Reading the first 2 minutes."
        TL_KF_UNIT=minutes
        TL_KF_MINUTES=2
        tl_keyframe_span_minutes "$src" 2
      fi
      ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}. Reading the first 2 minutes."
      TL_KF_UNIT=minutes
      TL_KF_MINUTES=2
      tl_keyframe_span_minutes "$src" 2
      ;;
  esac
}

tl_prompt_gop() {
  local choice="" answer="" gkey=d sec_def=1 frame_def=30
  case "${TL_GOP_KIND:-default}" in
    source) gkey=s ;;
    seconds) gkey=c; sec_def="$TL_GOP_SECONDS" ;;
    frames) gkey=f; frame_def="$TL_GOP_FRAMES" ;;
    *) gkey=d ;;
  esac
  echo
  echo "Keyframe spacing [D/s/c/f]"
  echo "  [D] Encoder default"
  echo "      Leave the interval to hevc_nvenc or libx265. That is often"
  echo "      about 10 seconds. Fine when you watch straight through."
  echo "  [s] Same as the source"
  echo "      Read part of this file and use the keyframe interval it has."
  echo "      You choose 2 minutes, another number of minutes, or a percent."
  echo "      Nothing is assumed."
  echo "  [c] Custom seconds"
  echo "      Type how often, in seconds of the output, a keyframe is written."
  echo "  [f] Custom frames"
  echo "      Type a frame count of the output, not of the dashcam."
  tl_read_key "Keyframe spacing [D/s/c/f]: " "$gkey"
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    d)
      TL_GOP_KIND=default
      TL_GOP_MODE=default
      ;;
    s)
      TL_KEYFRAME_MEASURED=0
      TL_SCAN_GAP=""
      tl_prompt_keyframe_span "${TL_INPUTS[0]}"
      if tl_measure_keyframe_gap "${TL_INPUTS[0]}" "${TL_KF_LIMIT_SEC:-}"; then
        TL_GOP_KIND=source
        TL_GOP_MODE=seconds
        TL_GOP_SECONDS="$(tl_gap_seconds_from_measured "$TL_SCAN_GAP")"
        echo "$(tl_ts) Most source gaps are ${TL_SCAN_GAP}s. Output keyframes: every ${TL_GOP_SECONDS}s."
      else
        echo "$(tl_ts) No keyframe spacing found. Using the encoder default."
        TL_GOP_KIND=default
        TL_GOP_MODE=default
      fi
      ;;
    c)
      tl_read_line "Seconds between keyframes [${sec_def}]: " "$sec_def"
      answer="$REPLY"
      if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= 60 )); then
        TL_GOP_KIND=seconds
        TL_GOP_MODE=seconds
        TL_GOP_SECONDS="$answer"
      else
        echo "$(tl_ts) Invalid seconds: ${answer} (use 1 to 60). Using the encoder default."
        TL_GOP_KIND=default
        TL_GOP_MODE=default
      fi
      ;;
    f)
      tl_read_line "Frames between keyframes [${frame_def}]: " "$frame_def"
      answer="$REPLY"
      if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= 3000 )); then
        TL_GOP_KIND=frames
        TL_GOP_MODE=frames
        TL_GOP_FRAMES="$answer"
      else
        echo "$(tl_ts) Invalid frame count: ${answer} (use 1 to 3000). Using the encoder default."
        TL_GOP_KIND=default
        TL_GOP_MODE=default
      fi
      ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; keeping the current keyframe choice."
      ;;
  esac
}

# Decoded frame-timing sample. Keyframes are measured only when [s] was chosen.
tl_scan_source() {
  local src="$1" minutes="$2" sample_sec frame_line
  sample_sec=$(( minutes * 60 ))
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
  if [[ "$frame_line" == none || -z "$frame_line" ]]; then
    echo "  Frame timing: no frames decoded"
  else
    # shellcheck disable=SC2086
    set -- $frame_line
    echo "  Frame timing, first $(tl_minutes_word "$minutes"): $1 frames, most of them ${2}s (${3})"
  fi
}

tl_apply_scan_suggestion() {
  local choice="" gap_note="the encoder default (no keyframe gap was measured)"
  local suggest_seconds=""
  echo
  if [[ -n "$TL_SCAN_GAP" ]]; then
    suggest_seconds="$(tl_gap_seconds_from_measured "$TL_SCAN_GAP")"
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
    TL_GOP_KIND=seconds
    TL_GOP_MODE=seconds
    TL_GOP_SECONDS="$suggest_seconds"
  fi
  echo "$(tl_ts) Applied. Picture: $(tl_picture_summary)"
}

tl_prompt_scan() {
  local choice="" skey=n lkey=5
  if (( ${TL_DO_SCAN:-0} )); then
    skey=y
  fi
  case "${TL_SCAN_MINUTES:-5}" in
    2) lkey=2 ;;
    10) lkey=t ;;
    *) lkey=5 ;;
  esac
  echo
  echo "Scan the source before encoding? [N/y]"
  echo "  [N] Skip the scan"
  echo "      Encode with the choices above."
  echo "  [y] Read this file"
  echo "      Decodes a piece at the start to check that each frame lasts"
  echo "      the same time. Keyframe spacing is chosen above, not here."
  tl_read_key "Scan the source? [N/y]: " "$skey"
  choice="$(tl_choice "$REPLY")"
  if [[ "$choice" != y ]]; then
    TL_DO_SCAN=0
    return 0
  fi
  TL_DO_SCAN=1
  echo
  echo "How long a piece of pictures should be decoded? [2/5/t]"
  echo "  These minutes are only the piece at the start that we decode"
  echo "  to check that each frame lasts the same time."
  echo "  Keyframe spacing was already chosen above."
  echo "  [2] 2 minutes"
  echo "      A shorter look. It may still be a single clip."
  echo "  [5] 5 minutes"
  echo "      Long enough to cross several dashcam clips."
  echo "  [t] 10 minutes"
  echo "      A longer look. Decoding it takes a few minutes."
  tl_read_key "Decode length [2/5/t]: " "$lkey"
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    2) TL_SCAN_MINUTES=2 ;;
    5) TL_SCAN_MINUTES=5 ;;
    t) TL_SCAN_MINUTES=10 ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; keeping ${TL_SCAN_MINUTES} minutes."
      ;;
  esac
  tl_scan_source "${TL_INPUTS[0]}" "$TL_SCAN_MINUTES"
  tl_apply_scan_suggestion
}

tl_prompt_test_clip() {
  local choice="" tkey=n lkey=1 skey=b
  if (( ${TL_TEST:-0} )); then
    tkey=y
  fi
  case "${TL_TEST_MINUTES:-1}" in
    2) lkey=2 ;;
    5) lkey=5 ;;
    *) lkey=1 ;;
  esac
  skey="$(tl_test_start_key "${TL_TEST_PERCENT:-0}")"
  echo
  echo "Test clip instead of the whole file? [N/y]"
  echo "  [N] Whole file"
  echo "      Encode the full sped-up drive."
  echo "  [y] A short piece of the result you will watch"
  echo "      So you can judge the picture before waiting for the whole file."
  tl_read_key "Test clip? [N/y]: " "$tkey"
  choice="$(tl_choice "$REPLY")"
  if [[ "$choice" != y ]]; then
    TL_TEST=0
    return 0
  fi
  TL_TEST=1
  echo
  echo "How long should the result be? [1/2/5]"
  echo "  [1] 1 minute of output"
  echo "      At 20× this reads 20 minutes of the dashcam."
  echo "  [2] 2 minutes of output"
  echo "  [5] 5 minutes of output"
  tl_read_key "Clip length [1/2/5]: " "$lkey"
  choice="$(tl_choice "$REPLY")"
  case "$choice" in
    1) TL_TEST_MINUTES=1 ;;
    2) TL_TEST_MINUTES=2 ;;
    5) TL_TEST_MINUTES=5 ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; keeping $(tl_minutes_word "$TL_TEST_MINUTES")."
      ;;
  esac
  echo
  echo "Where should the clip start? [B/1/2/3/5/7/9]"
  echo "  [B] Beginning"
  echo "  [1] 10%   [2] 20%   [3] 30%"
  echo "  [5] 50%   [7] 70%   [9] 90%"
  echo "      The percentage is of this file. The script prints the clock time."
  tl_read_key "Start at [B/1/2/3/5/7/9]: " "$skey"
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
      echo "$(tl_ts) Unknown choice: ${REPLY}; keeping the current start."
      ;;
  esac
}

# Enter on No returns to a plain whole-file encode. Yes keeps the current answers.
tl_prompt_advanced() {
  local choice="" akey=n
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  if (( ${TL_ADV_ON:-0} )); then
    akey=y
  fi
  echo
  echo "Advanced encoding? [N/y]"
  echo "  [N] Plain"
  echo "      Every Nth frame, played at 25 fps, for the whole file."
  echo "  [y] Choose the picture, the keyframes, a source scan,"
  echo "      and an optional test clip."
  tl_read_key "Advanced encoding? [N/y]: " "$akey"
  choice="$(tl_choice "$REPLY")"
  if [[ "$choice" != y ]]; then
    tl_reset_advanced
    return 0
  fi
  TL_ADV_ON=1
  tl_prompt_picture
  tl_prompt_encoder_menu
  tl_prompt_gop
  tl_prompt_scan
  tl_prompt_test_clip
}

tl_prompt_display() {
  local choice="" dkey=n
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    [[ -n "$TL_DISPLAY" ]] || TL_DISPLAY=normal
    return 0
  fi
  if [[ "${TL_DISPLAY:-normal}" == verbose ]]; then
    dkey=v
  else
    dkey=n
    [[ -n "$TL_DISPLAY" ]] || TL_DISPLAY=normal
  fi
  echo
  echo "Encode display?"
  echo "  [N] Normal (progress bar)"
  echo "  [v] Verbose (frames)"
  tl_read_key "Display [N/v]: " "$dkey"
  choice="${REPLY,,}"
  choice="${choice//$'\r'/}"
  choice="${choice//$'\n'/}"
  case "$choice" in
    n) TL_DISPLAY=normal ;;
    v) TL_DISPLAY=verbose ;;
    *)
      echo "$(tl_ts) Unknown choice: ${REPLY}; keeping ${TL_DISPLAY}."
      ;;
  esac
}

tl_set_gop_spec() {
  local spec="${1,,}" n=""
  case "$spec" in
    default)
      TL_GOP_KIND=default
      TL_GOP_MODE=default
      ;;
    source)
      TL_GOP_KIND=source
      TL_ADV_ON=1
      ;;
    *s)
      n="${spec%s}"
      if [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= 60 )); then
        TL_GOP_KIND=seconds
        TL_GOP_MODE=seconds
        TL_GOP_SECONDS="$n"
        TL_ADV_ON=1
      else
        echo "ERROR: invalid --gop: ${1} (seconds 1 to 60, written as 2s)" >&2
        exit 1
      fi
      ;;
    *f)
      n="${spec%f}"
      if [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= 3000 )); then
        TL_GOP_KIND=frames
        TL_GOP_MODE=frames
        TL_GOP_FRAMES="$n"
        TL_ADV_ON=1
      else
        echo "ERROR: invalid --gop: ${1} (frames 1 to 3000, written as 30f)" >&2
        exit 1
      fi
      ;;
    *)
      echo "ERROR: invalid --gop: ${1} (default, source, Ns, or Nf)" >&2
      exit 1
      ;;
  esac
}

tl_require_encoder() {
  tl_load_encoders
  tl_encoder_candidates "$ENCODER" "" >/dev/null || {
    echo "$(tl_ts) No usable video encoder for '${ENCODER}'." >&2
    tl_note_encoder_probe_failure
    exit 1
  }
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
TL_GOP_KIND=default
TL_GOP_SECONDS=1
TL_GOP_FRAMES=30
TL_KF_UNIT=minutes
TL_KF_MINUTES=2
TL_KF_PERCENT=10
TL_DO_SCAN=0
TL_ADV_ON=0
TL_KEYFRAME_MEASURED=0
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
    --display)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --display" >&2; exit 1; }
      TL_DISPLAY="$2"
      TL_DISPLAY_FROM_CLI=1
      shift 2
      ;;
    --display=*)
      TL_DISPLAY="${1#--display=}"
      TL_DISPLAY_FROM_CLI=1
      shift
      ;;
    --picture)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --picture" >&2; exit 1; }
      TL_PICTURE="$2"
      [[ "$2" == plain ]] || TL_ADV_ON=1
      shift 2
      ;;
    --picture=*)
      TL_PICTURE="${1#--picture=}"
      [[ "$TL_PICTURE" == plain ]] || TL_ADV_ON=1
      shift
      ;;
    --blend-before)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --blend-before" >&2; exit 1; }
      TL_BLEND_BEFORE="$2"
      shift 2
      ;;
    --blend-before=*)
      TL_BLEND_BEFORE="${1#--blend-before=}"
      shift
      ;;
    --blend-after)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --blend-after" >&2; exit 1; }
      TL_BLEND_AFTER="$2"
      shift 2
      ;;
    --blend-after=*)
      TL_BLEND_AFTER="${1#--blend-after=}"
      shift
      ;;
    --fps)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --fps" >&2; exit 1; }
      TL_OUT_FPS="$2"
      shift 2
      ;;
    --fps=*)
      TL_OUT_FPS="${1#--fps=}"
      shift
      ;;
    --gop)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --gop" >&2; exit 1; }
      tl_set_gop_spec "$2"
      shift 2
      ;;
    --gop=*)
      tl_set_gop_spec "${1#--gop=}"
      shift
      ;;
    --keyframe-minutes)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --keyframe-minutes" >&2; exit 1; }
      TL_KF_UNIT=minutes
      TL_KF_MINUTES="$2"
      shift 2
      ;;
    --keyframe-minutes=*)
      TL_KF_UNIT=minutes
      TL_KF_MINUTES="${1#--keyframe-minutes=}"
      shift
      ;;
    --keyframe-percent)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --keyframe-percent" >&2; exit 1; }
      TL_KF_UNIT=percent
      TL_KF_PERCENT="$2"
      shift 2
      ;;
    --keyframe-percent=*)
      TL_KF_UNIT=percent
      TL_KF_PERCENT="${1#--keyframe-percent=}"
      shift
      ;;
    --scan-minutes)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --scan-minutes" >&2; exit 1; }
      TL_SCAN_MINUTES="$2"
      TL_DO_SCAN=1
      TL_ADV_ON=1
      shift 2
      ;;
    --scan-minutes=*)
      TL_SCAN_MINUTES="${1#--scan-minutes=}"
      TL_DO_SCAN=1
      TL_ADV_ON=1
      shift
      ;;
    --test-minutes)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --test-minutes" >&2; exit 1; }
      TL_TEST_MINUTES="$2"
      TL_TEST=1
      TL_ADV_ON=1
      shift 2
      ;;
    --test-minutes=*)
      TL_TEST_MINUTES="${1#--test-minutes=}"
      TL_TEST=1
      TL_ADV_ON=1
      shift
      ;;
    --test-at)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --test-at" >&2; exit 1; }
      TL_TEST_PERCENT="$2"
      TL_TEST=1
      TL_ADV_ON=1
      shift 2
      ;;
    --test-at=*)
      TL_TEST_PERCENT="${1#--test-at=}"
      TL_TEST=1
      TL_ADV_ON=1
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
    echo "ERROR: invalid --display: ${TL_DISPLAY} (normal or verbose)" >&2
    exit 1
    ;;
esac

case "$TL_PICTURE" in
  plain|steady|soft) ;;
  *)
    echo "ERROR: invalid --picture: ${TL_PICTURE} (plain, steady, or soft)" >&2
    exit 1
    ;;
esac

if [[ ! "$TL_BLEND_BEFORE" =~ ^[0-9]+$ ]] || (( TL_BLEND_BEFORE > 8 )); then
  echo "ERROR: invalid --blend-before: ${TL_BLEND_BEFORE} (0 to 8)" >&2
  exit 1
fi
if [[ ! "$TL_BLEND_AFTER" =~ ^[0-9]+$ ]] || (( TL_BLEND_AFTER > 8 )); then
  echo "ERROR: invalid --blend-after: ${TL_BLEND_AFTER} (0 to 8)" >&2
  exit 1
fi
case "$TL_OUT_FPS" in
  25|30|60) ;;
  *)
    echo "ERROR: invalid --fps: ${TL_OUT_FPS} (25, 30, or 60)" >&2
    exit 1
    ;;
esac
if [[ ! "$TL_KF_MINUTES" =~ ^[0-9]+$ ]] || (( TL_KF_MINUTES < 1 )); then
  echo "ERROR: invalid --keyframe-minutes: ${TL_KF_MINUTES} (1 or more)" >&2
  exit 1
fi
if [[ ! "$TL_KF_PERCENT" =~ ^[0-9]+$ ]] || (( TL_KF_PERCENT < 1 || TL_KF_PERCENT > 100 )); then
  echo "ERROR: invalid --keyframe-percent: ${TL_KF_PERCENT} (1 to 100)" >&2
  exit 1
fi
case "$TL_SCAN_MINUTES" in
  2|5|10) ;;
  *)
    echo "ERROR: invalid --scan-minutes: ${TL_SCAN_MINUTES} (2, 5, or 10)" >&2
    exit 1
    ;;
esac
case "$TL_TEST_MINUTES" in
  1|2|5) ;;
  *)
    echo "ERROR: invalid --test-minutes: ${TL_TEST_MINUTES} (1, 2, or 5)" >&2
    exit 1
    ;;
esac
case "$TL_TEST_PERCENT" in
  0|10|20|30|50|70|90) ;;
  *)
    echo "ERROR: invalid --test-at: ${TL_TEST_PERCENT} (0, 10, 20, 30, 50, 70, or 90)" >&2
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

tl_ask_speed() {
  tl_prompt_speed
  case $? in
    0) ;;
    2)
      return_code=0
      # shellcheck disable=SC1091
      . /root/bin/_script_footer.sh
      exit 0
      ;;
    *) exit 1 ;;
  esac
}

if (( script_is_run_interactively )) && (( ! DO_YES )); then
  tl_ask_speed
fi

tl_print_ffmpeg_version
if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
  echo "$(tl_ts) ffmpeg and ffprobe are required." >&2
  exit 1
fi

if (( script_is_run_interactively )) && (( ! DO_YES )); then
  [[ -n "$SPEED" ]] || SPEED=5
  [[ -n "$TL_DISPLAY" ]] || TL_DISPLAY=normal
  tl_prompt_display
  tl_require_encoder
  tl_prompt_advanced
  while true; do
    tl_print_plan
    tl_read_key "Proceed with these choices? [Y/n/q]: " y
    case "$(tl_choice "$REPLY")" in
      y)
        break
        ;;
      n)
        tl_ask_speed
        tl_prompt_display
        tl_prompt_advanced
        tl_require_encoder
        ;;
      q)
        echo "$(tl_ts) Quit."
        return_code=0
        # shellcheck disable=SC1091
        . /root/bin/_script_footer.sh
        exit 0
        ;;
      *)
        echo "$(tl_ts) Unknown choice: ${REPLY}. Encoding with the choices above."
        break
        ;;
    esac
  done
  ENCODE_ALL=1
else
  [[ -n "$SPEED" ]] || SPEED=5
  [[ -n "$TL_DISPLAY" ]] || TL_DISPLAY=normal
  tl_require_encoder
  if (( DO_YES )); then
    tl_prepare_unattended
  fi
fi

echo "$(tl_ts) Speed: ${SPEED}×    files: ${#TL_INPUTS[@]}    encoder request: ${ENCODER}    display: ${TL_DISPLAY}"
echo "$(tl_ts) Picture: $(tl_picture_summary)"
echo "$(tl_ts) Audio is omitted. The .gpx beside the source still uses real time."

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
      if (( ${TL_SKIP_EXPLAINED:-0} )); then
        TL_SKIP_EXPLAINED=0
      else
        echo "$(tl_ts) Skipped: ${tl_src}"
      fi
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
