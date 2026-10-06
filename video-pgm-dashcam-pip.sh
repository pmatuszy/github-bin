#!/bin/bash
# v. 20261006.091500 - pair FrontCam and BackCam by filename clock, print the plan, render picture-in-picture

# 2026.10.06 - v. 0.1 - initial release: find FrontCam and BackCam files, pair them by the clock in their names, delay each back file by its real start difference divided by the speed (x5), print the plan, and after a yes render front full frame with back in a corner on hevc_nvenc (libx265 fallback)
#
# video-pgm-dashcam-pip.sh
#
# Put the rear dashcam picture in a corner of the front dashcam picture.
# Front and back files are paired by the start and end clock in their names
# (for example 20260926_110627-20260926-130427-...-FrontCam-concat-x5.mp4).
# A front file can have several back files; each one is delayed to its own start.
# The sources and their .gpx tracks are not changed.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-n|--dry-run] [--redo]
       [--pip-scale N] [--corner tl|tr|bl|br] [--margin PX]
       [--encoder auto|nvenc|x265|x264] [--quality N]
       [--from TIME] [--length TIME] [--shift SECONDS]
       [--no-audio] [--no-gpx]
       [FILE|DIR ...]

Find front and back dashcam videos, pair them, print what will be rendered,
and after you agree write one picture-in-picture video per front file:
the front camera fills the frame and the back camera sits in a corner.

With no FILE or DIR, the current directory is used. A file is recognized when
its name starts with the start and end clock and contains FrontCam or BackCam:
  20260926_110627-20260926-130427-Raclawicka-Bonow-70mai-A510-FrontCam-concat-x5.mp4
  20260926_110627-20260926_130427_-_-_70mai-A510_FrontCam_concat.mp4
  20260926-110627_20260926-130427_70mai-A510_BackCam_concat.mp4
Windows paths such as P:\\video\\trip are read as /mnt/p/video/trip.

How the files are lined up
  - A back file belongs to the front file whose time it overlaps most.
    Front and back must have the same speed (-x5, _x5, or none).
  - The back file is delayed by (back start - front start) / speed.
    A back file 25 minutes after the front in an x5 file starts at 5:00.
  - A back file that starts before the front has its beginning cut.
  - When the back picture ends, the front keeps playing and the corner is
    empty until the next back file starts. The plan lists those gaps.
  - The clock comes from the file names. Both cameras use the same clock,
    so no GPS is needed. The GPS points start a few seconds after the name
    clock; that is normal.
  - Front and back .gpx files are the same track. Only the front one is
    copied beside the output (same name, .gpx). It is in real time, so it
    does not follow the sped-up video. --no-gpx skips the copy.

Output
  The front name with FrontCam replaced by PiP, in the front file's folder:
    ...-70mai-A510-PiP-concat-x5.mp4
  A short try (--from or --length) adds -test-from-1m00s-len-2m00s.
  An existing output is skipped unless --redo is given.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask. Render everything in the plan.
  -n, --dry-run        Print the plan and the ffmpeg commands, render nothing.
  --redo               Replace outputs that already exist.
  --pip-scale N        Back picture is 1/N of its width and height. 2 to 8.
                       Default 2 (half size).
  --corner C           tl (top left, default), tr, bl, or br.
  --margin PX          Gap between the back picture and the frame edge.
                       Default 0 (flush in the corner).
  --encoder KIND       auto (default): hevc_nvenc on the GPU, then libx265 on
                       the CPU if NVENC is missing or fails.
                       nvenc, x265, or x264 force that one encoder.
  --quality N          hevc_nvenc -cq, or libx265/libx264 -crf. Lower is sharper
                       and larger. Default 22 for HEVC, 20 for libx264.
  --from TIME          Start the output this far into the front video.
                       Seconds (90), M:SS (1:30), or H:MM:SS.
  --length TIME        Render only this much output. Same formats.
  --shift SECONDS      Move every back file later (+) or earlier (-) by real
                       seconds, if the cameras' clocks were not the same.
  --no-audio           Do not copy the front camera's audio.
  --no-gpx             Do not copy the front .gpx beside the output.

Examples:
  $(basename "$0")
      Read the current directory, print the plan, ask before rendering.
  $(basename "$0") --length 1:00 --from 1:00
      One minute of every route, starting one minute in.
  $(basename "$0") -y --pip-scale 3 --corner tr --margin 20 /mnt/p/video/trip
  $(basename "$0") -n 'P:\\video\\20260926-Bonow-Deblin\\_samochod-jazda'
EOF
}

pip_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

pip_colors() {
  C_B="" C_DIM="" C_G="" C_Y="" C_R="" C_C="" C_0=""
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_B=$'\e[1m'
    C_DIM=$'\e[2m'
    C_G=$'\e[32m'
    C_Y=$'\e[33m'
    C_R=$'\e[31m'
    C_C=$'\e[36m'
    C_0=$'\e[0m'
  fi
}

pip_rule() {
  local ch="${1:-─}" width="${2:-78}"
  printf '%*s' "$width" '' | sed "s/ /${ch}/g"
}

# ══ Title ═══════════…
pip_heading() {
  local title="$1" width=78 rest
  rest=$(( width - ${#title} - 4 ))
  (( rest < 3 )) && rest=3
  echo
  printf '%s══ %s %s%s\n' "$C_B$C_C" "$title" "$(pip_rule '═' "$rest")" "$C_0"
}

pip_print_box_lines() {
  local -a lines=("$@")
  local line width=0
  (( ${#lines[@]} == 0 )) && return 0
  for line in "${lines[@]}"; do
    (( ${#line} > width )) && width=${#line}
  done
  printf '┌%s┐\n' "$(pip_rule '─' $(( width + 2 )))"
  for line in "${lines[@]}"; do
    printf '│ %-*s │\n' "$width" "$line"
  done
  printf '└%s┘\n' "$(pip_rule '─' $(( width + 2 )))"
}

# Seconds → M:SS or H:MM:SS. A tenth is shown only when it is not zero.
pip_clock() {
  awk -v s="${1:-0}" 'BEGIN {
    neg = ""
    if (s < 0) { neg = "-"; s = -s }
    t = int(s * 10 + 0.5) / 10
    h = int(t / 3600)
    m = int((t - h * 3600) / 60)
    x = t - h * 3600 - m * 60
    if (x - int(x) >= 0.05) xs = sprintf("%04.1f", x)
    else xs = sprintf("%02d", int(x + 0.5))
    if (h > 0) printf "%s%d:%02d:%s", neg, h, m, xs
    else printf "%s%d:%s", neg, m, xs
  }'
}

# Seconds → 1m00s or 1h02m03s, for file names.
pip_name_clock() {
  awk -v s="${1:-0}" 'BEGIN {
    t = int(s + 0.5)
    h = int(t / 3600)
    m = int((t % 3600) / 60)
    x = t % 60
    if (h > 0) printf "%dh%02dm%02ds", h, m, x
    else printf "%dm%02ds", m, x
  }'
}

pip_calc() {
  awk "BEGIN { printf \"%.3f\", $1 }"
}

pip_gt() {
  awk -v a="$1" -v b="$2" 'BEGIN { exit !(a + 0 > b + 0) }'
}

# 90, 90s, 2m, 1:30, 1:02:03 → seconds.
pip_parse_time() {
  local v="${1,,}"
  if [[ "$v" =~ ^[0-9]+([.][0-9]+)?s?$ ]]; then
    printf '%s\n' "${v%s}"
  elif [[ "$v" =~ ^([0-9]+)m$ ]]; then
    printf '%s\n' $(( BASH_REMATCH[1] * 60 ))
  elif [[ "$v" =~ ^([0-9]+):([0-9]{1,2}([.][0-9]+)?)$ ]]; then
    pip_calc "${BASH_REMATCH[1]} * 60 + ${BASH_REMATCH[2]}"
  elif [[ "$v" =~ ^([0-9]+):([0-9]{1,2}):([0-9]{1,2}([.][0-9]+)?)$ ]]; then
    pip_calc "${BASH_REMATCH[1]} * 3600 + ${BASH_REMATCH[2]} * 60 + ${BASH_REMATCH[3]}"
  else
    return 1
  fi
}

pip_human_size() {
  awk -v b="${1:-0}" 'BEGIN {
    split("B KiB MiB GiB TiB", u, " ")
    i = 1
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    if (i == 1) printf "%d %s", b, u[i]
    else printf "%.1f %s", b, u[i]
  }'
}

# P:\video\trip → /mnt/p/video/trip when that mount exists.
pip_unix_path() {
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

pip_epoch() {
  local d="$1" t="$2"
  date -d "${d:0:4}-${d:4:2}-${d:6:2} ${t:0:2}:${t:2:2}:${t:4:2}" +%s 2>/dev/null
}

# Sets P_CAM (front|back), P_START, P_END (epoch from the name), P_SPEED,
# P_DAY (YYYY.MM.DD), P_CLOCK_START, P_CLOCK_END.
pip_parse_name() {
  local base="${1##*/}" rest d1 t1 d2 t2
  P_CAM="" P_START="" P_END="" P_SPEED=1 P_DAY="" P_CLOCK_START="" P_CLOCK_END=""
  [[ "$base" =~ \.[mM][pP]4$ ]] || return 1
  [[ "$base" =~ ^([0-9]{8})[-_]([0-9]{6})[-_]([0-9]{8})[-_]([0-9]{6}) ]] || return 1
  d1="${BASH_REMATCH[1]}" t1="${BASH_REMATCH[2]}" d2="${BASH_REMATCH[3]}" t2="${BASH_REMATCH[4]}"
  if [[ "$base" =~ [-_]FrontCam([-_.]|$) ]]; then
    P_CAM=front
    rest="${base#*FrontCam}"
  elif [[ "$base" =~ [-_]BackCam([-_.]|$) ]]; then
    P_CAM=back
    rest="${base#*BackCam}"
  else
    return 1
  fi
  if [[ "$rest" =~ [-_][xX]([0-9]+)[-_.] ]]; then
    P_SPEED="${BASH_REMATCH[1]}"
    (( P_SPEED >= 1 )) || P_SPEED=1
  fi
  P_START="$(pip_epoch "$d1" "$t1")" || return 1
  P_END="$(pip_epoch "$d2" "$t2")" || return 1
  [[ -n "$P_START" && -n "$P_END" ]] || return 1
  P_DAY="${d1:0:4}.${d1:4:2}.${d1:6:2}"
  P_CLOCK_START="${t1:0:2}:${t1:2:2}:${t1:4:2}"
  P_CLOCK_END="${t2:0:2}:${t2:2:2}:${t2:4:2}"
  return 0
}

pip_ffprobe_duration() {
  local dur
  dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 -- "$1" 2>/dev/null || true)"
  dur="${dur//$'\r'/}"
  [[ "$dur" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
  printf '%s\n' "$dur"
}

pip_add_file() {
  local f="$1" explicit="${2:-0}" i
  for i in "${!F_PATH[@]}"; do
    [[ "${F_PATH[$i]}" == "$f" ]] && return 0
  done
  if ! pip_parse_name "$f"; then
    if (( explicit )); then
      echo "$(pip_ts) ${C_Y}Not a FrontCam/BackCam file with a start-end clock, ignored:${C_0} ${f}" >&2
    fi
    return 0
  fi
  F_PATH+=("$f")
  F_CAM+=("$P_CAM")
  F_START+=("$P_START")
  F_NAME_END+=("$P_END")
  F_SPEED+=("$P_SPEED")
  F_DAY+=("$P_DAY")
  F_CLOCK_START+=("$P_CLOCK_START")
  F_CLOCK_END+=("$P_CLOCK_END")
  F_DUR+=("")
}

pip_add_directory() {
  local dir="${1%/}" f
  local -a found=()
  [[ -n "$dir" ]] || dir="/"
  shopt -s nullglob nocaseglob
  found=( "$dir"/*.mp4 )
  shopt -u nullglob nocaseglob
  (( ${#found[@]} == 0 )) && return 0
  mapfile -t found < <(printf '%s\n' "${found[@]}" | LC_ALL=C sort)
  for f in "${found[@]}"; do
    [[ -n "$f" ]] && pip_add_file "$f" 0
  done
}

pip_read_durations() {
  local i n=${#F_PATH[@]} dur
  (( n == 0 )) && return 0
  printf '%s Reading the length of %d video(s)...' "$(pip_ts)" "$n"
  for i in "${!F_PATH[@]}"; do
    dur="$(pip_ffprobe_duration "${F_PATH[$i]}" || true)"
    F_DUR[$i]="$dur"
  done
  echo " done."
}

# Real end of a file: start + length × speed. Without a length, name end + 1 minute.
pip_real_end() {
  local i="$1"
  if [[ -n "${F_DUR[$i]}" ]]; then
    pip_calc "${F_START[$i]} + ${F_DUR[$i]} * ${F_SPEED[$i]}"
  else
    printf '%s\n' $(( F_NAME_END[$i] + 60 ))
  fi
}

pip_overlap() {
  awk -v a1="$1" -v a2="$2" -v b1="$3" -v b2="$4" 'BEGIN {
    s = (a1 > b1) ? a1 : b1
    e = (a2 < b2) ? a2 : b2
    printf "%.3f", (e > s) ? e - s : 0
  }'
}

# Fills FRONTS, R_BACKS[front], B_FRONT[back], ORPHAN_IDX and ORPHAN_WHY.
pip_pair() {
  local i j best best_ov ov other_speed be fe
  FRONTS=()
  ORPHAN_IDX=()
  ORPHAN_WHY=()
  for i in "${!F_PATH[@]}"; do
    if [[ "${F_CAM[$i]}" == front ]]; then
      FRONTS+=("$i")
      R_BACKS[$i]=""
    fi
  done
  for i in "${!F_PATH[@]}"; do
    [[ "${F_CAM[$i]}" == back ]] || continue
    be="$(pip_real_end "$i")"
    best="" best_ov=0 other_speed=""
    for j in "${FRONTS[@]}"; do
      fe="$(pip_real_end "$j")"
      ov="$(pip_overlap "${F_START[$i]}" "$be" "${F_START[$j]}" "$fe")"
      pip_gt "$ov" 0 || continue
      if [[ "${F_SPEED[$j]}" != "${F_SPEED[$i]}" ]]; then
        other_speed="x${F_SPEED[$j]}"
        continue
      fi
      if pip_gt "$ov" "$best_ov"; then
        best="$j"
        best_ov="$ov"
      fi
    done
    if [[ -n "$best" ]]; then
      B_FRONT[$i]="$best"
      R_BACKS[$best]+="${R_BACKS[$best]:+ }${i}"
    else
      ORPHAN_IDX+=("$i")
      if [[ -n "$other_speed" ]]; then
        ORPHAN_WHY+=("the front file at that time is ${other_speed}, this one is x${F_SPEED[$i]}")
      else
        ORPHAN_WHY+=("no front file covers ${F_CLOCK_START[$i]} - ${F_CLOCK_END[$i]}")
      fi
    fi
  done
  for j in "${FRONTS[@]}"; do
    if [[ -z "${R_BACKS[$j]}" ]]; then
      ORPHAN_IDX+=("$j")
      ORPHAN_WHY+=("no back file at that time, nothing to put in the corner")
    fi
  done
}

# Delay of a back file inside its front's output, in output seconds.
pip_back_delay() {
  local b="$1" f="$2"
  pip_calc "(${F_START[$b]} - ${F_START[$f]} + ${SHIFT}) / ${F_SPEED[$f]}"
}

pip_output_path() {
  local f="$1" dir base stem sep="-" out
  dir="$(dirname -- "${F_PATH[$f]}")"
  base="$(basename -- "${F_PATH[$f]}")"
  stem="${base%.*}"
  if [[ "$stem" =~ ([-_])FrontCam ]]; then
    sep="${BASH_REMATCH[1]}"
  fi
  stem="${stem/FrontCam/PiP}"
  out="$stem"
  if (( TEST )); then
    out+="${sep}test-from-$(pip_name_clock "$FROM")"
    if [[ -n "$LENGTH" ]]; then
      out+="-len-$(pip_name_clock "$LENGTH")"
    fi
  fi
  printf '%s/%s.mp4\n' "$dir" "$out"
}

pip_find_gpx() {
  local mp4="$1" dir stem cand
  dir="$(dirname -- "$mp4")"
  stem="$(basename -- "$mp4")"
  stem="${stem%.*}"
  for cand in "$stem" "$(sed -E 's/[-_][xX][0-9]+([-_][0-9]{8}-[0-9]{6})?$//' <<<"$stem")"; do
    if [[ -f "${dir}/${cand}.gpx" ]]; then
      printf '%s\n' "${dir}/${cand}.gpx"
      return 0
    fi
  done
  return 1
}

pip_overlay_xy() {
  local m="$MARGIN"
  case "$CORNER" in
    tr) printf 'W-w-%s:%s' "$m" "$m" ;;
    bl) printf '%s:H-h-%s' "$m" "$m" ;;
    br) printf 'W-w-%s:H-h-%s' "$m" "$m" ;;
    *)  printf '%s:%s' "$m" "$m" ;;
  esac
}

pip_corner_label() {
  case "$CORNER" in
    tr) printf 'top right' ;;
    bl) printf 'bottom left' ;;
    br) printf 'bottom right' ;;
    *)  printf 'top left' ;;
  esac
}

pip_size_label() {
  if (( PIP_SCALE == 2 )); then
    printf 'half width and height'
  else
    printf '1/%s of width and height' "$PIP_SCALE"
  fi
}

# Window of the output being rendered, in output seconds: WIN_START, WIN_END.
pip_window() {
  local f="$1" fdur="${F_DUR[$1]}"
  WIN_START="$FROM"
  if [[ -n "$LENGTH" ]]; then
    WIN_END="$(pip_calc "$FROM + $LENGTH")"
    if [[ -n "$fdur" ]] && pip_gt "$WIN_END" "$fdur"; then
      WIN_END="$fdur"
    fi
  else
    WIN_END="${fdur:-}"
  fi
}

# For one route, decide which back files are in the window and how each is fed.
# Sets USE_B, USE_DELAY (in the rendered output), USE_SEEK (into the back file).
pip_route_inputs() {
  local f="$1" b d bdur bend
  USE_B=()
  USE_DELAY=()
  USE_SEEK=()
  pip_window "$f"
  for b in ${R_BACKS[$f]}; do
    d="$(pip_back_delay "$b" "$f")"
    bdur="${F_DUR[$b]}"
    if [[ -n "$bdur" ]]; then
      bend="$(pip_calc "$d + $bdur")"
      pip_gt "$bend" "$WIN_START" || continue
    fi
    if [[ -n "$WIN_END" ]] && ! pip_gt "$WIN_END" "$d"; then
      continue
    fi
    USE_B+=("$b")
    if pip_gt "$WIN_START" "$d"; then
      USE_SEEK+=("$(pip_calc "$WIN_START - $d")")
      USE_DELAY+=("0")
    else
      USE_SEEK+=("0")
      USE_DELAY+=("$(pip_calc "$d - $WIN_START")")
    fi
  done
}

# ffmpeg arguments for one route, after pip_route_inputs. Output path last.
pip_build_ffmpeg_args() {
  local f="$1" out="$2" k n filter="" xy prev cur
  xy="$(pip_overlay_xy)"
  FF_ARGS=()
  if pip_gt "$FROM" 0; then
    FF_ARGS+=(-ss "$FROM")
  fi
  FF_ARGS+=(-i "${F_PATH[$f]}")
  for k in "${!USE_B[@]}"; do
    if pip_gt "${USE_SEEK[$k]}" 0; then
      FF_ARGS+=(-ss "${USE_SEEK[$k]}")
    fi
    FF_ARGS+=(-i "${F_PATH[${USE_B[$k]}]}")
  done
  n=${#USE_B[@]}
  filter="[0:v]setpts=PTS-STARTPTS[main]"
  prev="main"
  for k in "${!USE_B[@]}"; do
    filter+=";[$(( k + 1 )):v]setpts=PTS-STARTPTS"
    if pip_gt "${USE_DELAY[$k]}" 0; then
      filter+="+${USE_DELAY[$k]}/TB"
    fi
    filter+=",scale=iw/${PIP_SCALE}:-2[pip$(( k + 1 ))]"
    if (( k + 1 == n )); then
      cur="v"
      filter+=";[${prev}][pip$(( k + 1 ))]overlay=${xy}:eof_action=pass,format=yuv420p[${cur}]"
    else
      cur="tmp$(( k + 1 ))"
      filter+=";[${prev}][pip$(( k + 1 ))]overlay=${xy}:eof_action=pass[${cur}]"
    fi
    prev="$cur"
  done
  if (( n == 0 )); then
    filter="[0:v]setpts=PTS-STARTPTS,format=yuv420p[v]"
  fi
  FF_ARGS+=(-filter_complex "$filter" -map '[v]')
  if (( AUDIO )); then
    FF_ARGS+=(-map '0:a?' -c:a aac -b:a 160k)
  else
    FF_ARGS+=(-an)
  fi
  FF_ARGS+=("${ENC_ARGS[@]}" -movflags +faststart)
  if [[ -n "$LENGTH" ]]; then
    FF_ARGS+=(-t "$LENGTH")
  fi
  FF_ARGS+=("$out")
}

# Shell-safe words stay bare; anything else is put in single quotes.
pip_quote_args() {
  local part out="" sq="'" esc="'\\''"
  for part in "$@"; do
    if [[ ! "$part" =~ ^[A-Za-z0-9_./:=+,@%-]+$ ]]; then
      part="${sq}${part//${sq}/${esc}}${sq}"
    fi
    out+="${out:+ }${part}"
  done
  printf '%s\n' "$out"
}

# --- encoders ---------------------------------------------------------------

pip_encoder_available() {
  grep -Eq "(^|[[:space:]])$1([[:space:]]|$)" <<<"${ENCODER_LIST:-}"
}

pip_encoder_candidates() {
  case "$ENCODER" in
    nvenc) pip_encoder_available hevc_nvenc && echo nvenc ;;
    x265)  pip_encoder_available libx265 && echo x265 ;;
    x264)  pip_encoder_available libx264 && echo x264 ;;
    *)
      pip_encoder_available hevc_nvenc && echo nvenc
      pip_encoder_available libx265 && echo x265
      if ! pip_encoder_available hevc_nvenc && ! pip_encoder_available libx265; then
        pip_encoder_available libx264 && echo x264
      fi
      ;;
  esac
  return 0
}

pip_set_encoder_args() {
  local q="$QUALITY"
  case "$1" in
    nvenc)
      [[ -n "$q" ]] || q=22
      ENC_ARGS=(-c:v hevc_nvenc -preset p5 -rc vbr -cq "$q" -b:v 0 -tag:v hvc1)
      ENC_LABEL="hevc_nvenc (GPU), cq ${q}"
      ;;
    x265)
      [[ -n "$q" ]] || q=22
      ENC_ARGS=(-c:v libx265 -preset medium -crf "$q" -tag:v hvc1)
      ENC_LABEL="libx265 (CPU), crf ${q}"
      ;;
    x264)
      [[ -n "$q" ]] || q=20
      ENC_ARGS=(-c:v libx264 -preset medium -crf "$q")
      ENC_LABEL="libx264 (CPU), crf ${q}"
      ;;
  esac
}

pip_print_ffmpeg_box() {
  local ver gpu="none"
  ver="$(ffmpeg -version 2>&1 | awk '/^ffmpeg version / { print $1, $2, $3; exit }')"
  [[ -n "$ver" ]] || ver="ffmpeg version unknown"
  if pip_encoder_available hevc_nvenc; then
    gpu="hevc_nvenc"
  fi
  echo
  pip_print_box_lines "$ver" "GPU HEVC encoder: ${gpu}"
}

# --- progress ---------------------------------------------------------------

pip_out_time_seconds() {
  awk -v t="$1" 'BEGIN {
    if (t == "" || t ~ /^-/) { print 0; exit }
    n = split(t, a, ":")
    if (n != 3) { print 0; exit }
    printf "%.3f\n", a[1] * 3600 + a[2] * 60 + a[3]
  }'
}

pip_draw_progress() {
  local done_s="$1" total="$2" speedx="$3" label="$4"
  local width=40 filled=0 pct=" --" bar left="--" spd="${speedx%x}"
  if [[ -n "$total" ]] && pip_gt "$total" 0; then
    pct="$(awk -v e="$done_s" -v t="$total" 'BEGIN { p = int(e / t * 100 + 0.5); if (p > 100) p = 100; printf "%3d", p }')"
    filled="$(awk -v e="$done_s" -v t="$total" -v w="$width" 'BEGIN { n = int(e / t * w + 0.5); if (n > w) n = w; printf "%d", n }')"
    if [[ "$spd" =~ ^[0-9]+([.][0-9]+)?$ ]] && pip_gt "$spd" 0; then
      left="$(pip_clock "$(pip_calc "($total - $done_s) / $spd")")"
    fi
  fi
  bar="$(printf '%*s' "$filled" '' | tr ' ' '#')$(printf '%*s' $(( width - filled )) '' | tr ' ' '-')"
  printf '\r%s [%s] %s%%  %s / %s  %s  left %s\033[K' \
    "$label" "$bar" "$pct" "$(pip_clock "$done_s")" "$(pip_clock "${total:-0}")" "$speedx" "$left"
}

pip_progress_reader() {
  local total="$1" label="$2" line key val out_s=0 spd="--"
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == *=* ]] || continue
    key="${line%%=*}"
    val="${line#*=}"
    case "$key" in
      out_time) out_s="$(pip_out_time_seconds "$val")" ;;
      speed) spd="$val"; [[ "$spd" == N/A ]] && spd="--" ;;
      progress)
        [[ "$val" == end && -n "$total" ]] && out_s="$total"
        pip_draw_progress "$out_s" "$total" "$spd" "$label"
        ;;
    esac
  done
  printf '\n'
}

pip_cleanup_partial() {
  if [[ -n "${PARTIAL:-}" && -e "$PARTIAL" ]]; then
    rm -f -- "$PARTIAL"
    echo "$(pip_ts) Removed incomplete output: ${PARTIAL}"
  fi
  PARTIAL=""
}

# --- plan -------------------------------------------------------------------

pip_print_route() {
  local n="$1" total="$2" f="$3" b d bdur bend cursor=0 fdur out out_note gpx
  local k s e real_after
  local -a gaps=() notes=()
  fdur="${F_DUR[$f]}"
  out="$(pip_output_path "$f")"
  ROUTE_OUT[$f]="$out"

  pip_heading "Route ${n} of ${total}   ${F_DAY[$f]}  ${F_CLOCK_START[$f]} - ${F_CLOCK_END[$f]}   x${F_SPEED[$f]}"
  printf '  %sFront%s  full frame\n' "$C_B" "$C_0"
  printf '         %s\n' "$(basename -- "${F_PATH[$f]}")"
  if [[ -n "$fdur" ]]; then
    printf '         %svideo length %s%s\n' "$C_DIM" "$(pip_clock "$fdur")" "$C_0"
  else
    printf '         %svideo length unknown (ffprobe could not read it)%s\n' "$C_Y" "$C_0"
  fi
  printf '  %sBack%s   %s, %s, margin %spx\n' "$C_B" "$C_0" "$(pip_corner_label)" "$(pip_size_label)" "$MARGIN"
  k=0
  for b in ${R_BACKS[$f]}; do
    (( k++ )) || true
    d="$(pip_back_delay "$b" "$f")"
    bdur="${F_DUR[$b]}"
    printf '    %s[%d]%s %s\n' "$C_C" "$k" "$C_0" "$(basename -- "${F_PATH[$b]}")"
    printf '        %s - %s on the clock\n' "${F_CLOCK_START[$b]}" "${F_CLOCK_END[$b]}"
    if pip_gt 0.05 "$(awk -v x="$d" 'BEGIN { printf "%.3f", (x < 0) ? -x : x }')"; then
      printf '        %sstarts with the front, offset 0%s\n' "$C_G" "$C_0"
    elif pip_gt "$d" 0; then
      real_after="$(pip_calc "$d * ${F_SPEED[$f]}")"
      printf '        %sstarts at %s in the video%s  (%s real time after the front)\n' \
        "$C_G" "$(pip_clock "$d")" "$C_0" "$(pip_clock "$real_after")"
    else
      printf '        %sstarts %s before the front; that part is cut%s\n' \
        "$C_Y" "$(pip_clock "$(pip_calc "-1 * $d")")" "$C_0"
    fi
    if [[ -n "$bdur" ]]; then
      s="$d"
      e="$(pip_calc "$d + $bdur")"
      pip_gt "$s" 0 || s=0
      if [[ -n "$fdur" ]] && pip_gt "$e" "$fdur"; then
        if pip_gt "$e" "$(pip_calc "$fdur + 0.5")"; then
          notes+=("Back [${k}] runs $(pip_clock "$(pip_calc "$e - $fdur")") past the end of the front; that part is cut.")
        fi
        e="$fdur"
      fi
      printf '        shown %s - %s\n' "$(pip_clock "$s")" "$(pip_clock "$e")"
      if pip_gt "$s" "$(pip_calc "$cursor + 0.5")"; then
        gaps+=("$(pip_clock "$cursor") - $(pip_clock "$s")")
      elif pip_gt "$(pip_calc "$cursor - 0.5")" "$s" && (( k > 1 )); then
        notes+=("Back [${k}] overlaps the one before it by $(pip_clock "$(pip_calc "$cursor - $s")"); the later file is drawn on top.")
      fi
      pip_gt "$e" "$cursor" && cursor="$e"
    else
      printf '        %slength unknown, cannot tell where it ends%s\n' "$C_Y" "$C_0"
    fi
  done
  if [[ -n "$fdur" ]] && pip_gt "$(pip_calc "$fdur - 0.5")" "$cursor"; then
    gaps+=("$(pip_clock "$cursor") - $(pip_clock "$fdur")")
  fi
  if (( ${#gaps[@]} > 0 )); then
    printf '  %sCorner empty%s  %s\n' "$C_Y" "$C_0" "$(IFS=,; printf '%s' "${gaps[*]}" | sed 's/,/, /g')"
  fi
  for s in "${notes[@]}"; do
    printf '  %sNote%s  %s\n' "$C_Y" "$C_0" "$s"
  done
  if (( TEST )); then
    pip_window "$f"
    printf '  %sRender%s  only %s - %s of the video\n' "$C_B" "$C_0" "$(pip_clock "$WIN_START")" "$(pip_clock "${WIN_END:-0}")"
  fi
  out_note="${C_G}new${C_0}"
  ROUTE_STATE[$f]=render
  if [[ -e "$out" ]]; then
    if (( REDO )); then
      out_note="${C_Y}exists, will be replaced${C_0}"
    else
      out_note="${C_Y}exists ($(pip_human_size "$(stat -c %s -- "$out" 2>/dev/null || echo 0)")), skipped; --redo replaces it${C_0}"
      ROUTE_STATE[$f]=exists
      (( EXISTING++ )) || true
    fi
  fi
  printf '  %sOutput%s  %s\n' "$C_B" "$C_0" "$(basename -- "$out")"
  printf '          %s\n' "$out_note"
  ROUTE_GPX[$f]=""
  if (( GPX )) && (( ! TEST )); then
    if gpx="$(pip_find_gpx "${F_PATH[$f]}")"; then
      ROUTE_GPX[$f]="$gpx"
      printf '  %sGPS%s     copy %s\n' "$C_B" "$C_0" "$(basename -- "$gpx")"
      printf '          %s(real time; the back .gpx is the same track and is not used)%s\n' "$C_DIM" "$C_0"
    fi
  fi
}

pip_print_orphans() {
  local k i
  (( ${#ORPHAN_IDX[@]} == 0 )) && return 0
  pip_heading "Not used"
  for k in "${!ORPHAN_IDX[@]}"; do
    i="${ORPHAN_IDX[$k]}"
    printf '  %s%-5s%s %s\n' "$C_Y" "${F_CAM[$i]}" "$C_0" "$(basename -- "${F_PATH[$i]}")"
    printf '        %s\n' "${ORPHAN_WHY[$k]}"
  done
}

pip_equivalent_command() {
  local -a cmd=("$(basename "$0")" -y)
  (( REDO )) && cmd+=(--redo)
  (( PIP_SCALE != 2 )) && cmd+=(--pip-scale "$PIP_SCALE")
  [[ "$CORNER" != tl ]] && cmd+=(--corner "$CORNER")
  (( MARGIN != 0 )) && cmd+=(--margin "$MARGIN")
  [[ "$ENCODER" != auto ]] && cmd+=(--encoder "$ENCODER")
  [[ -n "$QUALITY" ]] && cmd+=(--quality "$QUALITY")
  pip_gt "$FROM" 0 && cmd+=(--from "$(pip_clock "$FROM")")
  [[ -n "$LENGTH" ]] && cmd+=(--length "$(pip_clock "$LENGTH")")
  [[ "$SHIFT" != 0 ]] && cmd+=(--shift "$SHIFT")
  (( AUDIO )) || cmd+=(--no-audio)
  (( GPX )) || cmd+=(--no-gpx)
  cmd+=(--)
  if (( ${#INPUT_ARGS[@]} > 0 )); then
    cmd+=("${INPUT_ARGS[@]}")
  else
    cmd+=("$(pwd -P)")
  fi
  pip_quote_args "${cmd[@]}"
}

pip_print_plan() {
  local n=0 f total=${#FRONTS[@]}
  ROUTES=()
  EXISTING=0
  for f in "${FRONTS[@]}"; do
    [[ -n "${R_BACKS[$f]}" ]] && ROUTES+=("$f")
  done
  total=${#ROUTES[@]}
  for f in "${ROUTES[@]}"; do
    (( n++ )) || true
    pip_print_route "$n" "$total" "$f"
  done
  pip_print_orphans
  pip_heading "Settings"
  printf '  %-14s %s\n' "Back picture" "$(pip_size_label), $(pip_corner_label), margin ${MARGIN}px"
  printf '  %-14s %s\n' "Encoder" "$ENC_LABEL"
  if (( AUDIO )); then
    printf '  %-14s %s\n' "Audio" "from the front camera, if it has any"
  else
    printf '  %-14s %s\n' "Audio" "none"
  fi
  if (( TEST )); then
    printf '  %-14s %s\n' "Render" "from $(pip_clock "$FROM")${LENGTH:+, $(pip_clock "$LENGTH") long}"
  else
    printf '  %-14s %s\n' "Render" "whole front files"
  fi
  if [[ "$SHIFT" != 0 ]]; then
    printf '  %-14s %s\n' "Clock shift" "back files moved ${SHIFT}s (real time)"
  fi
  printf '  %-14s %s\n' "Command" "$(pip_equivalent_command)"
  TO_RENDER=0
  for f in "${ROUTES[@]}"; do
    [[ "${ROUTE_STATE[$f]}" == render ]] && (( TO_RENDER++ )) || true
  done
  echo
  printf '%s%d route(s), %d to render%s' "$C_B" "$total" "$TO_RENDER" "$C_0"
  (( EXISTING > 0 )) && printf ', %d already rendered' "$EXISTING"
  echo
}

# --- prompts ----------------------------------------------------------------

pip_read_key() {
  local prompt="$1" default_key="${2:-}" answer="" discard
  printf '%s' "$prompt"
  while IFS= read -r -t 0.02 -n 1 discard; do :; done
  read -r -n 1 answer || answer=""
  echo
  answer="${answer,,}"
  REPLY="${answer:-$default_key}"
}

pip_read_line() {
  local prompt="$1" default="$2" answer=""
  printf '%s' "$prompt"
  IFS= read -r answer || answer=""
  REPLY="${answer:-$default}"
}

pip_quit() {
  echo "$(pip_ts) Quit. Nothing more was rendered."
  STOPPED=yes
  return_code=0
  exit 0
}

pip_prompt_test() {
  local v
  echo
  echo "Short try: how much video? [1/2/5/w/q]"
  echo "  [1] 1 minute (default)"
  echo "  [2] 2 minutes"
  echo "  [5] 5 minutes"
  echo "  [w] To the end of each front file"
  echo "  [q] Quit"
  pip_read_key "Length [1/2/5/w/q]: " 1
  case "$REPLY" in
    1) LENGTH=60 ;;
    2) LENGTH=120 ;;
    5) LENGTH=300 ;;
    w) LENGTH="" ;;
    q) pip_quit ;;
    *) echo "$(pip_ts) Unknown choice: ${REPLY}. Using 1 minute."; LENGTH=60 ;;
  esac
  pip_read_line "Start how far into the video? M:SS or seconds [$(pip_clock "$FROM")] (q quits): " "$(pip_clock "$FROM")"
  [[ "${REPLY,,}" == q ]] && pip_quit
  if v="$(pip_parse_time "$REPLY")"; then
    FROM="$v"
  else
    echo "$(pip_ts) Not a time: ${REPLY}. Keeping $(pip_clock "$FROM")."
  fi
  TEST=0
  if pip_gt "$FROM" 0 || [[ -n "$LENGTH" ]]; then
    TEST=1
  fi
}

pip_prompt_plan() {
  while true; do
    echo
    printf '%sRender now? [Y/c/t/r/q]%s\n' "$C_B" "$C_0"
    echo "  [Y] Render all ${TO_RENDER} (default)"
    echo "  [c] Choose route by route"
    echo "  [t] Render a short try instead (asks length and start)"
    if (( EXISTING > 0 )); then
      echo "  [r] Also replace the ${EXISTING} output(s) that already exist"
    fi
    echo "  [q] Quit, render nothing"
    pip_read_key "Render now? [Y/c/t/r/q]: " y
    case "$REPLY" in
      y) CHOOSE=0; return 0 ;;
      c) CHOOSE=1; return 0 ;;
      t) pip_prompt_test; pip_print_plan ;;
      r) REDO=1; pip_print_plan ;;
      n|q) pip_quit ;;
      *) echo "$(pip_ts) Unknown choice: ${REPLY}." ;;
    esac
  done
}

# --- render -----------------------------------------------------------------

pip_render_route() {
  local n="$1" total="$2" f="$3" out label kind rc tries=0 start_s end_s gpx_out total_out
  local -a kinds=()
  out="${ROUTE_OUT[$f]}"
  pip_route_inputs "$f"
  label="${n}/${total}"
  pip_window "$f"
  total_out=""
  if [[ -n "$WIN_END" ]]; then
    total_out="$(pip_calc "$WIN_END - $WIN_START")"
  fi
  pip_heading "Rendering ${label}  $(basename -- "$out")"
  mapfile -t kinds < <(pip_encoder_candidates)
  for kind in "${kinds[@]}"; do
    (( tries++ )) || true
    pip_set_encoder_args "$kind"
    PARTIAL="${out%.mp4}.partial.$$.mp4"
    pip_build_ffmpeg_args "$f" "$PARTIAL"
    echo "$(pip_ts) Encoder: ${ENC_LABEL}"
    printf '%s ffmpeg %s%s%s\n' "$(pip_ts)" "$C_DIM" "$(pip_quote_args "${FF_ARGS[@]}")" "$C_0"
    start_s=$(date +%s)
    if [[ -t 1 ]]; then
      ffmpeg -y -hide_banner -loglevel error -nostats -progress pipe:1 "${FF_ARGS[@]}" \
        | pip_progress_reader "$total_out" "$label"
      rc=${PIPESTATUS[0]}
    else
      ffmpeg -y -hide_banner -loglevel error -nostats "${FF_ARGS[@]}"
      rc=$?
    fi
    end_s=$(date +%s)
    if (( rc == 0 )) && [[ -s "$PARTIAL" ]] && mv -f -- "$PARTIAL" "$out"; then
      PARTIAL=""
      echo "$(pip_ts) ${C_G}Done${C_0} in $(pip_clock $(( end_s - start_s ))): ${out}"
      if [[ -n "${ROUTE_GPX[$f]}" ]]; then
        gpx_out="${out%.mp4}.gpx"
        if cp -f -- "${ROUTE_GPX[$f]}" "$gpx_out"; then
          echo "$(pip_ts) GPS track: ${gpx_out}"
        fi
      fi
      DONE_LIST+=("$out")
      return 0
    fi
    pip_cleanup_partial
    echo "$(pip_ts) ${C_R}ffmpeg failed with ${ENC_LABEL}.${C_0}" >&2
  done
  if (( tries == 0 )); then
    echo "$(pip_ts) ${C_R}No usable encoder for '${ENCODER}'.${C_0}" >&2
  fi
  FAILED_LIST+=("$out")
  return 1
}

pip_print_summary() {
  local item end_s
  end_s=$(date +%s)
  pip_heading "Summary"
  printf '  %-12s %d\n' "Rendered" "${#DONE_LIST[@]}"
  for item in "${DONE_LIST[@]}"; do
    printf '    %s\n' "$item"
  done
  if (( ${#SKIPPED_LIST[@]} > 0 )); then
    printf '  %-12s %d\n' "Skipped" "${#SKIPPED_LIST[@]}"
    for item in "${SKIPPED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  if (( ${#FAILED_LIST[@]} > 0 )); then
    printf '  %s%-12s %d%s\n' "$C_R" "Failed" "${#FAILED_LIST[@]}" "$C_0"
    for item in "${FAILED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  printf '  %-12s %s\n' "Wall time" "$(pip_clock $(( end_s - SCRIPT_START )))"
  [[ "$STOPPED" == yes ]] && printf '  %-12s %s\n' "Stopped" "yes"
  echo
}

pip_on_exit() {
  pip_cleanup_partial
  if (( SUMMARY )) && (( ! SUMMARY_DONE )); then
    SUMMARY_DONE=1
    pip_print_summary
  fi
  if [[ -r /root/bin/_script_footer.sh ]]; then
    # shellcheck disable=SC1091
    . /root/bin/_script_footer.sh
  fi
}

pip_ctrl_c() {
  STOPPED=yes
  echo
  echo "$(pip_ts) Interrupted."
  return_code=130
  exit 130
}

# --- main -------------------------------------------------------------------

SCRIPT_START=$(date +%s)
# shellcheck disable=SC1091
. /root/bin/_script_header.sh

DO_YES=0
DRY_RUN=0
REDO=0
PIP_SCALE=2
CORNER=tl
MARGIN=0
ENCODER=auto
QUALITY=""
FROM=0
LENGTH=""
SHIFT=0
AUDIO=1
GPX=1
TEST=0
CHOOSE=0
INPUT_ARGS=()
F_PATH=() F_CAM=() F_START=() F_NAME_END=() F_SPEED=() F_DAY=() F_CLOCK_START=() F_CLOCK_END=() F_DUR=()
FRONTS=() ROUTES=() ORPHAN_IDX=() ORPHAN_WHY=()
declare -A R_BACKS=() B_FRONT=() ROUTE_OUT=() ROUTE_STATE=() ROUTE_GPX=()
USE_B=() USE_DELAY=() USE_SEEK=() FF_ARGS=() ENC_ARGS=()
ENC_LABEL="" ENCODER_LIST="" PARTIAL="" EXISTING=0 TO_RENDER=0
DONE_LIST=() SKIPPED_LIST=() FAILED_LIST=()
SUMMARY=0 SUMMARY_DONE=0 STOPPED=no
pip_colors

trap pip_on_exit EXIT
trap pip_ctrl_c INT

pip_need_value() {
  [[ $# -ge 2 && -n "$2" ]] || { echo "ERROR: missing value for $1" >&2; exit 1; }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --history) print_script_history; exit 0 ;;
    -y|--yes) DO_YES=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    --redo) REDO=1; shift ;;
    --pip-scale) pip_need_value "$@"; PIP_SCALE="$2"; shift 2 ;;
    --pip-scale=*) PIP_SCALE="${1#*=}"; shift ;;
    --corner) pip_need_value "$@"; CORNER="${2,,}"; shift 2 ;;
    --corner=*) CORNER="${1#*=}"; CORNER="${CORNER,,}"; shift ;;
    --margin) pip_need_value "$@"; MARGIN="$2"; shift 2 ;;
    --margin=*) MARGIN="${1#*=}"; shift ;;
    --encoder) pip_need_value "$@"; ENCODER="${2,,}"; shift 2 ;;
    --encoder=*) ENCODER="${1#*=}"; ENCODER="${ENCODER,,}"; shift ;;
    --quality) pip_need_value "$@"; QUALITY="$2"; shift 2 ;;
    --quality=*) QUALITY="${1#*=}"; shift ;;
    --from) pip_need_value "$@"; FROM_ARG="$2"; shift 2 ;;
    --from=*) FROM_ARG="${1#*=}"; shift ;;
    --length) pip_need_value "$@"; LENGTH_ARG="$2"; shift 2 ;;
    --length=*) LENGTH_ARG="${1#*=}"; shift ;;
    --shift) pip_need_value "$@"; SHIFT="$2"; shift 2 ;;
    --shift=*) SHIFT="${1#*=}"; shift ;;
    --no-audio) AUDIO=0; shift ;;
    --no-gpx) GPX=0; shift ;;
    --) shift; INPUT_ARGS+=("$@"); break ;;
    -*) echo "ERROR: unknown option: $1 (see --help)" >&2; exit 1 ;;
    *) INPUT_ARGS+=("$1"); shift ;;
  esac
done

[[ "$PIP_SCALE" =~ ^[2-8]$ ]] || { echo "ERROR: --pip-scale must be 2 to 8 (got ${PIP_SCALE})" >&2; exit 1; }
case "$CORNER" in tl|tr|bl|br) ;; *) echo "ERROR: --corner must be tl, tr, bl, or br (got ${CORNER})" >&2; exit 1 ;; esac
[[ "$MARGIN" =~ ^[0-9]+$ ]] || { echo "ERROR: --margin must be whole pixels (got ${MARGIN})" >&2; exit 1; }
case "$ENCODER" in auto|nvenc|x265|x264) ;; *) echo "ERROR: --encoder must be auto, nvenc, x265, or x264 (got ${ENCODER})" >&2; exit 1 ;; esac
if [[ -n "$QUALITY" ]] && { [[ ! "$QUALITY" =~ ^[0-9]+$ ]] || (( QUALITY > 51 )); }; then
  echo "ERROR: --quality must be 0 to 51 (got ${QUALITY})" >&2
  exit 1
fi
[[ "$SHIFT" =~ ^[-+]?[0-9]+([.][0-9]+)?$ ]] || { echo "ERROR: --shift must be seconds, for example 2 or -1.5 (got ${SHIFT})" >&2; exit 1; }
SHIFT="${SHIFT#+}"
if [[ -n "${FROM_ARG:-}" ]]; then
  FROM="$(pip_parse_time "$FROM_ARG")" || { echo "ERROR: --from is not a time: ${FROM_ARG}" >&2; exit 1; }
fi
if [[ -n "${LENGTH_ARG:-}" ]]; then
  LENGTH="$(pip_parse_time "$LENGTH_ARG")" || { echo "ERROR: --length is not a time: ${LENGTH_ARG}" >&2; exit 1; }
  pip_gt "$LENGTH" 0 || { echo "ERROR: --length must be more than 0" >&2; exit 1; }
fi
if pip_gt "$FROM" 0 || [[ -n "$LENGTH" ]]; then
  TEST=1
fi

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
  echo "$(pip_ts) ffmpeg and ffprobe are required." >&2
  exit 1
fi

if (( ${#INPUT_ARGS[@]} == 0 )); then
  pip_add_directory "."
else
  for _arg in "${INPUT_ARGS[@]}"; do
    _path="$(pip_unix_path "$_arg")"
    if [[ -d "$_path" ]]; then
      pip_add_directory "$_path"
    elif [[ -f "$_path" ]]; then
      pip_add_file "$_path" 1
    else
      echo "ERROR: not a file or directory: ${_arg}" >&2
      exit 1
    fi
  done
fi

SUMMARY=1
if (( ${#F_PATH[@]} == 0 )); then
  echo "$(pip_ts) No FrontCam or BackCam videos with a start-end clock in the name."
  return_code=0
  exit 0
fi

ENCODER_LIST="$(ffmpeg -hide_banner -encoders 2>/dev/null || true)"
pip_print_ffmpeg_box
mapfile -t _kinds < <(pip_encoder_candidates)
if (( ${#_kinds[@]} == 0 )); then
  echo "$(pip_ts) ${C_R}No usable video encoder for '${ENCODER}' in this ffmpeg.${C_0}" >&2
  exit 1
fi
pip_set_encoder_args "${_kinds[0]}"
if [[ "$ENCODER" == auto && "${_kinds[0]}" != nvenc ]]; then
  echo "$(pip_ts) ${C_Y}hevc_nvenc is not in this ffmpeg; using ${ENC_LABEL}.${C_0}"
fi

pip_read_durations
pip_pair
pip_print_plan

if (( ${#ROUTES[@]} == 0 )); then
  echo "$(pip_ts) No front file has a back file at the same time. Nothing to render."
  return_code=0
  exit 0
fi

if (( DRY_RUN )); then
  SUMMARY=0
  pip_heading "ffmpeg commands (dry run)"
  for f in "${ROUTES[@]}"; do
    [[ "${ROUTE_STATE[$f]}" == render ]] || continue
    pip_route_inputs "$f"
    pip_build_ffmpeg_args "$f" "${ROUTE_OUT[$f]}"
    echo
    echo "ffmpeg -y $(pip_quote_args "${FF_ARGS[@]}")"
  done
  echo
  return_code=0
  exit 0
fi

if (( ! DO_YES )); then
  if (( ! script_is_run_interactively )); then
    echo "$(pip_ts) Not a terminal: nothing rendered. Add -y to render without asking."
    return_code=0
    exit 0
  fi
  pip_prompt_plan
fi

return_code=0
_n=0
_total=0
for f in "${ROUTES[@]}"; do
  [[ "${ROUTE_STATE[$f]}" == render ]] && (( _total++ )) || true
done
for f in "${ROUTES[@]}"; do
  if [[ "${ROUTE_STATE[$f]}" != render ]]; then
    SKIPPED_LIST+=("${ROUTE_OUT[$f]} (already exists)")
    continue
  fi
  (( _n++ )) || true
  if (( CHOOSE )); then
    echo
    printf '%sRoute %d/%d%s  %s\n' "$C_B" "$_n" "$_total" "$C_0" "$(basename -- "${ROUTE_OUT[$f]}")"
    pip_read_key "Render this one? [Y/n/a/q]  (a = all the rest): " y
    case "$REPLY" in
      y) ;;
      a) CHOOSE=0 ;;
      n) SKIPPED_LIST+=("${ROUTE_OUT[$f]} (you chose no)"); continue ;;
      q) STOPPED=yes; break ;;
      *) SKIPPED_LIST+=("${ROUTE_OUT[$f]} (unknown answer ${REPLY})"); continue ;;
    esac
  fi
  pip_render_route "$_n" "$_total" "$f" || return_code=1
done

exit "$return_code"
