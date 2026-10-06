#!/bin/bash
# v. 20261006.114500 - render only part of each route: any length, counted from the beginning, from the end, or the middle
# v. 20261006.113900 - typed answers list [Enter] and [q] like the one-key questions, and every prompt line shows q
# v. 20261006.113100 - summary: input and output sizes per route and in total, like the timelapse script
# v. 20261006.112900 - summary: per-route encode time and speed, and a timing block like the other video scripts
# v. 20261006.110000 - every question lists each key with what it does
# v. 20261006.105000 - route by route: print the route's plan again before asking whether to render it
# v. 20261006.104500 - progress bar: whole seconds, time left and arrival clock, no 1/N for a single file
# v. 20261006.103000 - more choices: inset size, corner, four margins, mirror, crop, border, caption, swap, black gap box, output width
# v. 20261006.091500 - pair FrontCam and BackCam by filename clock, print the plan, render picture-in-picture

# 2026.10.06 - v. 0.9 - [t] renders a part of each route: all, 1, 2, 5 minutes or a custom length, from the beginning, back from the end, or the middle; --from-end and --middle; the plan shows each route's exact part
# 2026.10.06 - v. 0.8 - every question offers q to quit, shown both in its key list and on the prompt line
# 2026.10.06 - v. 0.7 - summary shows input and output size for each route, and totals in MB, MiB, GB, and GiB with output as a percent of input
# 2026.10.06 - v. 0.6 - summary lists each rendered route's video length, encode time, speed, and encoder; then Started, Finished, total wall, processing, and wait time
# 2026.10.06 - v. 0.5 - every question explains each key or what to type, marks the current default, and says that Enter keeps and q quits
# 2026.10.06 - v. 0.4 - [c] route by route prints that route's plan (front, back files, offsets, gaps, inset, output, GPS) before "Render this one?"
# 2026.10.06 - v. 0.3 - progress bar shows whole seconds (HH:MM:SS), time left and the local arrival clock; the 1/N prefix only when more than one file is rendered
# 2026.10.06 - v. 0.2 - "More choices?" menu and options: --pip-size (1/2, 40%, 960px), --corner tl/tr/ll/lr, --margin, --margin-x, --margin-y, --margin-top/-bottom/-left/-right, --mirror, --crop-top, --crop-bottom, --border, --border-color, --label, --swap, --gap-fill black, --out-width
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
       [--pip-size SIZE] [--corner tl|tr|ll|lr]
       [--margin PX] [--margin-x PX] [--margin-y PX]
       [--margin-top PX] [--margin-bottom PX] [--margin-left PX] [--margin-right PX]
       [--mirror] [--crop-top PX] [--crop-bottom PX]
       [--border PX] [--border-color COLOR] [--label TEXT]
       [--swap] [--gap-fill none|black] [--out-width PX]
       [--encoder auto|nvenc|x265|x264] [--quality N]
       [--length TIME] [--from TIME | --from-end TIME | --middle] [--shift SECONDS]
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

An interactive run first asks "More choices?" (default no). Yes walks through
the inset size, corner, margins, mirror, crop, border, caption, swap, the black
gap box, and the output width. Enter keeps each current answer.

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
  A short try adds -test-from-1m00s-len-2m00s (--from), -test-end-0m00s-len-2m00s
  (--from-end), or -test-middle-len-2m00s (--middle), so a full render is kept.
  An existing output is skipped unless --redo is given.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask. Render everything in the plan.
  -n, --dry-run        Print the plan and the ffmpeg commands, render nothing.
  --redo               Replace outputs that already exist.

 Inset (the small picture)
  --pip-size SIZE      1/2 (default) or 1/3: that part of its own width and height.
                       40%: that percent of the full frame's width.
                       960px: that many pixels wide.
                       The height follows the picture's shape.
  --pip-scale N        Same as --pip-size 1/N.
  --corner C           tl top left (default), tr top right,
                       ll lower left, lr lower right. bl and br also work.
  --margin PX          Gap on all four sides. Default 0, flush in the corner.
  --margin-x PX        Left and right gap.
  --margin-y PX        Top and bottom gap.
  --margin-top PX, --margin-bottom PX, --margin-left PX, --margin-right PX
                       One side. Only the two sides at the chosen corner matter.
  --mirror             Flip the rear picture left to right, like a rear-view mirror.
  --crop-top PX        Cut this many pixels off the top of the rear picture
                       before it is scaled, for example its own timestamp bar.
  --crop-bottom PX     Cut this many pixels off the bottom of the rear picture.
  --border PX          Frame around the inset. Default 0 (none).
  --border-color C     white (default), black, any ffmpeg color name, or #RRGGBB.
  --label TEXT         Caption at the bottom of the inset, for example REAR.
                       Not allowed: ' \\ : % , ; = [ ]
                       Needs ffmpeg's drawtext filter; without it the caption
                       is skipped with a warning.
  --swap               Rear camera full frame, front camera in the corner.
                       While no rear file plays, the front fills the frame and
                       the corner is empty.
  --gap-fill MODE      none (default) or black: a black box where the inset
                       would be while no rear file plays. Ignored with --swap.
  --out-width PX       Scale the finished video to this width. Default: keep
                       the front camera's size (for example 2592x1944).

 Encoding and timing
  --encoder KIND       auto (default): hevc_nvenc on the GPU, then libx265 on
                       the CPU if NVENC is missing or fails.
                       nvenc, x265, or x264 force that one encoder.
  --quality N          hevc_nvenc -cq, or libx265/libx264 -crf. Lower is sharper
                       and larger. Default 22 for HEVC, 20 for libx264.
  By default each route is rendered whole, from its start to its end.
  --length TIME        Render only this much of each route.
                       Seconds (90), M:SS (1:30), or H:MM:SS.
  --from TIME          The part starts this far into the front video.
  --from-end TIME      The part ends this far before the end of each route.
                       --from-end 0 --length 2:00 is the last two minutes.
  --middle             The part is the middle of each route. Needs --length.
                       A route shorter than --length is rendered whole.
  --shift SECONDS      Move every back file later (+) or earlier (-) by real
                       seconds, if the cameras' clocks were not the same.
  --no-audio           Do not copy the front camera's audio.
  --no-gpx             Do not copy the front .gpx beside the output.

Examples:
  $(basename "$0")
      Read the current directory, print the plan, ask before rendering.
  $(basename "$0") --length 1:00 --from 1:00
      One minute of every route, starting one minute in.
  $(basename "$0") --length 2:00 --from-end 0
      The last two minutes of every route.
  $(basename "$0") -y --pip-size 35% --corner tr --margin 24 --border 4 --label REAR
  $(basename "$0") -y --mirror --crop-bottom 60 --gap-fill black --out-width 1920
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

pip_now_ns() {
  date +%s.%N
}

# Wall-clock span for the summary. Hundredths of a second, or 0s.
pip_format_elapsed() {
  awk -v s="${1:-0}" 'BEGIN {
    if (s < 0) s = 0
    if (s < 0.005) { printf "0s"; exit }
    h = int(s / 3600)
    m = int((s - h * 3600) / 60)
    x = s - h * 3600 - m * 60
    if (h > 0) printf "%dh %02dm %05.2fs", h, m, x
    else if (m > 0) printf "%dm %05.2fs", m, x
    else printf "%.2fs", x
  }'
}

pip_format_wall_clock() {
  date -d "@${1%.*}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null || date '+%Y.%m.%d %H:%M:%S'
}

# Probing and encoding count as processing; everything else is waiting.
pip_proc_begin() {
  PROC_SLICE_START="$(pip_now_ns)"
}

pip_proc_end() {
  [[ -n "${PROC_SLICE_START:-}" ]] || return 0
  PROC_SEC="$(awk -v a="${PROC_SEC:-0}" -v t0="$PROC_SLICE_START" -v t1="$(pip_now_ns)" \
    'BEGIN { d = t1 - t0; if (d < 0) d = 0; printf "%.6f", a + d }')"
  PROC_SLICE_START=""
}

pip_summary_kv() {
  printf '  %-*s  %s\n' 18 "${1}:" "$2"
}

pip_file_bytes() {
  local n=0
  [[ -f "$1" ]] && n=$(stat -c %s -- "$1" 2>/dev/null || printf '0')
  [[ "$n" =~ ^[0-9]+$ ]] || n=0
  printf '%s\n' "$n"
}

# One short size for the per-route lines: ~812 MiB or ~3.4 GiB.
pip_size_short() {
  awk -v b="${1:-0}" 'BEGIN {
    if (b >= 1073741824) { x = b / 1073741824; u = "GiB" } else { x = b / 1048576; u = "MiB" }
    n = (x >= 100) ? sprintf("%.0f", x) : sprintf("%.1f", x)
    sub(/\.0$/, "", n)
    printf "~%s %s", n, u
  }'
}

# Two lines, input then output. Each | sits in the same column on both lines.
# Nearest short number, marked approximate. 100 and above are whole; smaller values keep one decimal.
pip_format_size_pair() {
  awk -v ib="${1:-0}" -v ob="${2:-0}" '
    function approx(x,    n) {
      if (x < 0) x = 0
      if (x >= 100) n = sprintf("%.0f", x)
      else n = sprintf("%.1f", x)
      sub(/\.0$/, "", n)
      return "~" n
    }
    function wider(a, b) {
      return length(a) > length(b) ? length(a) : length(b)
    }
    BEGIN {
      split("1000000 1048576 1000000000 1073741824", divs)
      split("MB MiB GB GiB", units)
      for (i = 1; i <= 4; i++) {
        inn[i] = approx(ib / divs[i]) " " units[i]
        outt[i] = approx(ob / divs[i]) " " units[i]
        w[i] = wider(inn[i], outt[i])
      }
      printf "%-*s | %-*s | %-*s | %s\n", w[1], inn[1], w[2], inn[2], w[3], inn[3], inn[4]
      printf "%-*s | %-*s | %-*s | %s\n", w[1], outt[1], w[2], outt[2], w[3], outt[3], outt[4]
    }'
}

pip_gt() {
  awk -v a="$1" -v b="$2" 'BEGIN { exit !(a + 0 > b + 0) }'
}

# Nearest even whole number, at least 2. Video sizes must be even.
pip_even() {
  awk -v x="$1" 'BEGIN { n = int(x / 2 + 0.5) * 2; if (n < 2) n = 2; printf "%d", n }'
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

# --- option values ----------------------------------------------------------

pip_is_px() {
  [[ "$1" =~ ^[0-9]+$ ]] && (( 10#$1 <= 4000 ))
}

# 1/2, 2/5, 40%, 960px, 960 → SIZE_KIND frac|pct|px and its numbers.
pip_set_size() {
  local v="${1,,}" a b
  v="${v// /}"
  if [[ "$v" =~ ^([0-9]+)/([0-9]+)$ ]]; then
    a=$(( 10#${BASH_REMATCH[1]} )) b=$(( 10#${BASH_REMATCH[2]} ))
    (( a >= 1 && b >= 1 && a <= b && b <= 20 )) || return 1
    SIZE_KIND=frac SIZE_A=$a SIZE_B=$b SIZE_SPEC="${a}/${b}"
  elif [[ "$v" =~ ^([0-9]+)%$ ]]; then
    a=$(( 10#${BASH_REMATCH[1]} ))
    (( a >= 5 && a <= 100 )) || return 1
    SIZE_KIND=pct SIZE_A=$a SIZE_SPEC="${a}%"
  elif [[ "$v" =~ ^([0-9]+)(px)?$ ]]; then
    a=$(( 10#${BASH_REMATCH[1]} ))
    (( a >= 16 && a <= 8000 )) || return 1
    SIZE_KIND=px SIZE_A=$a SIZE_SPEC="${a}px"
  else
    return 1
  fi
}

pip_size_label() {
  case "$SIZE_KIND" in
    frac)
      if [[ "$SIZE_SPEC" == 1/2 ]]; then
        printf 'half its own size'
      else
        printf '%s of its own size' "$SIZE_SPEC"
      fi
      ;;
    pct) printf '%s%% of the frame width' "$SIZE_A" ;;
    px)  printf '%s px wide' "$SIZE_A" ;;
  esac
}

pip_set_corner() {
  case "${1,,}" in
    tl|top-left) CORNER=tl ;;
    tr|top-right) CORNER=tr ;;
    ll|bl|lower-left|bottom-left) CORNER=ll ;;
    lr|br|lower-right|bottom-right) CORNER=lr ;;
    *) return 1 ;;
  esac
}

pip_corner_label() {
  case "$CORNER" in
    tr) printf 'top right' ;;
    ll) printf 'lower left' ;;
    lr) printf 'lower right' ;;
    *)  printf 'top left' ;;
  esac
}

# white, black, #RRGGBB, 0xRRGGBB → a color ffmpeg accepts.
pip_set_border_color() {
  local v="$1"
  if [[ "$v" =~ ^(#|0x|0X)?([0-9A-Fa-f]{6})$ ]] && [[ "$v" == \#* || "$v" == 0[xX]* ]]; then
    BORDER_COLOR="0x${BASH_REMATCH[2]}"
  elif [[ "$v" =~ ^[A-Za-z]+$ ]]; then
    BORDER_COLOR="${v,,}"
  else
    return 1
  fi
}

pip_label_ok() {
  local t="$1"
  [[ -n "$t" && ${#t} -le 60 ]] || return 1
  case "$t" in
    *"'"*|*'\'*|*:*|*%*|*,*|*';'*|*=*|*'['*|*']'*) return 1 ;;
  esac
  return 0
}

pip_margins_label() {
  if (( M_TOP == M_BOTTOM && M_TOP == M_LEFT && M_TOP == M_RIGHT )); then
    printf '%spx' "$M_TOP"
  else
    printf 'top %s, bottom %s, left %s, right %s px' "$M_TOP" "$M_BOTTOM" "$M_LEFT" "$M_RIGHT"
  fi
}

# Extras on one line, or "none".
pip_extras_label() {
  local -a e=()
  (( MIRROR )) && e+=("mirrored")
  (( CROP_TOP > 0 || CROP_BOTTOM > 0 )) && e+=("rear cut ${CROP_TOP}px top, ${CROP_BOTTOM}px bottom")
  (( BORDER > 0 )) && e+=("${BORDER}px ${BORDER_COLOR} border")
  if [[ -n "$LABEL" ]]; then
    if (( HAVE_DRAWTEXT )); then
      e+=("caption \"${LABEL}\"")
    else
      e+=("caption \"${LABEL}\" SKIPPED (this ffmpeg has no drawtext filter)")
    fi
  fi
  [[ "$GAP_FILL" == black && $SWAP -eq 0 ]] && e+=("black box in gaps")
  if (( ${#e[@]} == 0 )); then
    printf 'none'
  else
    local IFS=';'
    printf '%s' "${e[*]}" | sed 's/;/, /g'
  fi
}

# --- file names and probing -------------------------------------------------

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
    P_SPEED=$(( 10#${BASH_REMATCH[1]} ))
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

# Sets PR_DUR, PR_W, PR_H (empty when unknown).
pip_probe() {
  local k v
  PR_DUR="" PR_W="" PR_H=""
  while IFS='=' read -r k v; do
    v="${v//$'\r'/}"
    case "$k" in
      width)    [[ -z "$PR_W" && "$v" =~ ^[0-9]+$ ]] && PR_W="$v" ;;
      height)   [[ -z "$PR_H" && "$v" =~ ^[0-9]+$ ]] && PR_H="$v" ;;
      duration) [[ "$v" =~ ^[0-9]+([.][0-9]+)?$ ]] && PR_DUR="$v" ;;
    esac
  done < <(ffprobe -v error -select_streams v:0 -show_entries stream=width,height:format=duration \
             -of default=nw=1 -- "$1" 2>/dev/null || true)
  return 0
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
  F_W+=("")
  F_H+=("")
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
  local i n=${#F_PATH[@]}
  (( n == 0 )) && return 0
  printf '%s Reading the length and size of %d video(s)...' "$(pip_ts)" "$n"
  pip_proc_begin
  for i in "${!F_PATH[@]}"; do
    pip_probe "${F_PATH[$i]}"
    F_DUR[$i]="$PR_DUR"
    F_W[$i]="$PR_W"
    F_H[$i]="$PR_H"
  done
  pip_proc_end
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

# Fills FRONTS, R_BACKS[front], ORPHAN_IDX and ORPHAN_WHY.
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

# Delay of a back file inside its front's video, in video seconds.
pip_back_delay() {
  local b="$1" f="$2"
  pip_calc "(${F_START[$b]} - ${F_START[$f]} + ${SHIFT}) / ${F_SPEED[$f]}"
}

# Where each back file shows inside the front video (video seconds).
# Sets BK_IDX, BK_D, BK_S, BK_E (BK_E empty when its length is unknown),
# COV_S/COV_E (merged, rear shown), GAP_S/GAP_E (no rear), COVER_KNOWN, COVER_NOTES.
pip_route_cover() {
  local f="$1" fdur="${F_DUR[$1]}" b d s e cursor=0 k=0 laste=""
  BK_IDX=() BK_D=() BK_S=() BK_E=() COV_S=() COV_E=() GAP_S=() GAP_E=() COVER_NOTES=()
  COVER_KNOWN=1
  [[ -n "$fdur" ]] || COVER_KNOWN=0
  for b in ${R_BACKS[$f]}; do
    (( k++ )) || true
    d="$(pip_back_delay "$b" "$f")"
    BK_IDX+=("$b")
    BK_D+=("$d")
    s="$d"
    pip_gt "$s" 0 || s=0
    if [[ -z "${F_DUR[$b]}" ]]; then
      COVER_KNOWN=0
      BK_S+=("$s")
      BK_E+=("")
      continue
    fi
    e="$(pip_calc "$d + ${F_DUR[$b]}")"
    if [[ -n "$fdur" ]] && pip_gt "$e" "$fdur"; then
      if pip_gt "$e" "$(pip_calc "$fdur + 0.5")"; then
        COVER_NOTES+=("Back [${k}] runs $(pip_clock "$(pip_calc "$e - $fdur")") past the end of the front; that part is cut.")
      fi
      e="$fdur"
    fi
    BK_S+=("$s")
    BK_E+=("$e")
    if pip_gt "$s" "$(pip_calc "$cursor + 0.5")"; then
      GAP_S+=("$cursor")
      GAP_E+=("$s")
    elif (( k > 1 )) && pip_gt "$(pip_calc "$cursor - 0.5")" "$s"; then
      COVER_NOTES+=("Back [${k}] overlaps the one before it by $(pip_clock "$(pip_calc "$cursor - $s")"); the later file is drawn on top.")
    fi
    if [[ -n "$laste" ]] && ! pip_gt "$s" "$(pip_calc "$laste + 0.5")"; then
      pip_gt "$e" "$laste" && laste="$e"
      COV_E[$(( ${#COV_E[@]} - 1 ))]="$laste"
    else
      COV_S+=("$s")
      COV_E+=("$e")
      laste="$e"
    fi
    pip_gt "$e" "$cursor" && cursor="$e"
  done
  if [[ -n "$fdur" ]] && pip_gt "$(pip_calc "$fdur - 0.5")" "$cursor"; then
    GAP_S+=("$cursor")
    GAP_E+=("$fdur")
  fi
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
    case "$FROM_MODE" in
      end)    out+="${sep}test-end-$(pip_name_clock "$FROM")" ;;
      middle) out+="${sep}test-middle" ;;
      *)      out+="${sep}test-from-$(pip_name_clock "$FROM")" ;;
    esac
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

# --- picture layout ---------------------------------------------------------

# Inset size for a source picture w×h with crop_top/crop_bottom, in a frame frame_w wide.
# Sets INS_W, INS_H (scaled picture) and BOX_W, BOX_H (with the border).
pip_inset_size() {
  local w="$1" h="$2" ct="$3" cb="$4" frame_w="$5" ch
  ch=$(( h - ct - cb ))
  case "$SIZE_KIND" in
    frac) INS_W="$(pip_even "$(pip_calc "$w * $SIZE_A / $SIZE_B")")" ;;
    pct)  INS_W="$(pip_even "$(pip_calc "$frame_w * $SIZE_A / 100")")" ;;
    *)    INS_W="$(pip_even "$SIZE_A")" ;;
  esac
  INS_H="$(pip_even "$(pip_calc "$INS_W * $ch / $w")")"
  BOX_W=$(( INS_W + 2 * BORDER ))
  BOX_H=$(( INS_H + 2 * BORDER ))
}

# Whether this route's pictures can be laid out. Sets LAYOUT_ERR.
pip_layout_check() {
  local f="$1" b
  LAYOUT_ERR=""
  if [[ -z "${F_W[$f]}" || -z "${F_H[$f]}" ]]; then
    LAYOUT_ERR="ffprobe could not read the front picture size"
    return 1
  fi
  for b in ${R_BACKS[$f]}; do
    if [[ -z "${F_W[$b]}" || -z "${F_H[$b]}" ]]; then
      LAYOUT_ERR="ffprobe could not read the size of $(basename -- "${F_PATH[$b]}")"
      return 1
    fi
    if (( CROP_TOP + CROP_BOTTOM >= F_H[$b] - 16 )); then
      LAYOUT_ERR="--crop-top + --crop-bottom leaves almost nothing of the ${F_W[$b]}x${F_H[$b]} rear picture"
      return 1
    fi
  done
  if (( SWAP )); then
    pip_inset_size "${F_W[$f]}" "${F_H[$f]}" 0 0 "${F_W[$f]}"
  else
    b="${R_BACKS[$f]%% *}"
    pip_inset_size "${F_W[$b]}" "${F_H[$b]}" "$CROP_TOP" "$CROP_BOTTOM" "${F_W[$f]}"
  fi
  if (( BOX_W + M_LEFT + M_RIGHT > F_W[$f] || BOX_H + M_TOP + M_BOTTOM > F_H[$f] )); then
    LAYOUT_ERR="the ${BOX_W}x${BOX_H} inset plus margins does not fit in the ${F_W[$f]}x${F_H[$f]} frame"
    return 1
  fi
  return 0
}

pip_overlay_xy() {
  case "$CORNER" in
    tr) printf 'W-w-%s:%s' "$M_RIGHT" "$M_TOP" ;;
    ll) printf '%s:H-h-%s' "$M_LEFT" "$M_BOTTOM" ;;
    lr) printf 'W-w-%s:H-h-%s' "$M_RIGHT" "$M_BOTTOM" ;;
    *)  printf '%s:%s' "$M_LEFT" "$M_TOP" ;;
  esac
}

# Top-left pixel of a box_w×box_h inset in a frame_w×frame_h frame. Sets BOX_X, BOX_Y.
pip_box_xy() {
  local box_w="$1" box_h="$2" frame_w="$3" frame_h="$4"
  case "$CORNER" in
    tr) BOX_X=$(( frame_w - box_w - M_RIGHT )); BOX_Y=$M_TOP ;;
    ll) BOX_X=$M_LEFT; BOX_Y=$(( frame_h - box_h - M_BOTTOM )) ;;
    lr) BOX_X=$(( frame_w - box_w - M_RIGHT )); BOX_Y=$(( frame_h - box_h - M_BOTTOM )) ;;
    *)  BOX_X=$M_LEFT; BOX_Y=$M_TOP ;;
  esac
}

# Crop and mirror for the rear picture, ending in a comma, or empty.
pip_rear_pre() {
  local pre=""
  if (( CROP_TOP > 0 || CROP_BOTTOM > 0 )); then
    pre+="crop=iw:ih-${CROP_TOP}-${CROP_BOTTOM}:0:${CROP_TOP},"
  fi
  (( MIRROR )) && pre+="hflip,"
  printf '%s' "$pre"
}

# Scale, caption, and border for an inset made from a w×h picture.
pip_inset_chain() {
  local w="$1" h="$2" ct="$3" cb="$4" frame_w="$5" chain
  pip_inset_size "$w" "$h" "$ct" "$cb" "$frame_w"
  chain="scale=${INS_W}:${INS_H},setsar=1"
  if [[ -n "$LABEL" ]] && (( HAVE_DRAWTEXT )); then
    chain+=",drawtext=font=Sans:text='${LABEL}':fontcolor=white:fontsize=h/9"
    chain+=":x=(w-text_w)/2:y=h-text_h-h/25:box=1:boxcolor=black@0.5:boxborderw=6"
  fi
  if (( BORDER > 0 )); then
    chain+=",pad=${BOX_W}:${BOX_H}:${BORDER}:${BORDER}:color=${BORDER_COLOR}"
  fi
  printf '%s' "$chain"
}

# between(t,a,b)+… for intervals shifted to the rendered window, or empty.
pip_enable_expr() {
  local -n _s="$1" _e="$2"
  local k out="" a b
  for k in "${!_s[@]}"; do
    a="$(pip_calc "${_s[$k]} - $WIN_START")"
    b="$(pip_calc "${_e[$k]} - $WIN_START")"
    out+="${out:++}between(t,${a},${b})"
  done
  printf '%s' "$out"
}

# --- render window ----------------------------------------------------------

# Window of the output being rendered, in video seconds: WIN_START, WIN_END.
# FROM_MODE begin: the part starts FROM in. end: it ends FROM before the end.
# middle: it is centred. WIN_LEN is the -t value, WIN_NOTE says why it was shortened.
pip_window() {
  local f="$1" fdur="${F_DUR[$1]}" mode="$FROM_MODE"
  WIN_NOTE=""
  if [[ -z "$fdur" && "$mode" != begin ]]; then
    mode=begin
    WIN_NOTE="video length unknown, counted from the beginning"
  fi
  if [[ "$mode" == begin && -n "$fdur" ]] && ! pip_gt "$fdur" "$FROM"; then
    mode=end
    WIN_NOTE="the offset is past the end of this route, so its end is used"
  fi
  case "$mode" in
    end)
      WIN_END="$(pip_calc "$fdur - $FROM")"
      if [[ "$FROM_MODE" == end ]] && ! pip_gt "$WIN_END" 0; then
        WIN_END="$fdur"
        WIN_NOTE="the offset is longer than this route, so its end is used"
      elif [[ "$FROM_MODE" != end ]]; then
        WIN_END="$fdur"
      fi
      WIN_START=0
      if [[ -n "$LENGTH" ]]; then
        WIN_START="$(pip_calc "$WIN_END - $LENGTH")"
        if ! pip_gt "$WIN_START" 0; then
          WIN_START=0
          if [[ -n "$WIN_NOTE" ]]; then
            :
          elif ! pip_gt "$fdur" "$WIN_END"; then
            WIN_NOTE="whole route, $(pip_clock "$fdur") is shorter than $(pip_clock "$LENGTH")"
          else
            WIN_NOTE="starts at 0:00, there is less than $(pip_clock "$LENGTH") before that point"
          fi
        fi
      fi
      ;;
    middle)
      WIN_START=0
      WIN_END="$fdur"
      if [[ -n "$LENGTH" ]] && pip_gt "$fdur" "$LENGTH"; then
        WIN_START="$(pip_calc "($fdur - $LENGTH) / 2")"
        WIN_END="$(pip_calc "$WIN_START + $LENGTH")"
      elif [[ -n "$LENGTH" ]]; then
        WIN_NOTE="whole route, $(pip_clock "$fdur") is shorter than $(pip_clock "$LENGTH")"
      fi
      ;;
    *)
      WIN_START="$FROM"
      if [[ -n "$LENGTH" ]]; then
        WIN_END="$(pip_calc "$FROM + $LENGTH")"
        if [[ -n "$fdur" ]] && pip_gt "$WIN_END" "$fdur"; then
          WIN_END="$fdur"
          [[ -z "$WIN_NOTE" ]] && WIN_NOTE="stops at the end of the route, less than $(pip_clock "$LENGTH") is left"
          ! pip_gt "$FROM" 0 && WIN_NOTE="whole route, $(pip_clock "$fdur") is shorter than $(pip_clock "$LENGTH")"
        fi
      else
        WIN_END="${fdur:-}"
      fi
      ;;
  esac
  if [[ -n "$WIN_END" ]]; then
    WIN_LEN="$(pip_calc "$WIN_END - $WIN_START")"
  else
    WIN_LEN="$LENGTH"
  fi
}

# How the part is chosen, in words, for the settings and the questions.
pip_part_label() {
  if (( ! TEST )); then
    printf 'whole front files'
    return 0
  fi
  case "$FROM_MODE" in
    end)
      if [[ -n "$LENGTH" ]]; then
        if pip_gt "$FROM" 0; then
          printf '%s, ending %s before the end of each route' "$(pip_clock "$LENGTH")" "$(pip_clock "$FROM")"
        else
          printf 'the last %s of each route' "$(pip_clock "$LENGTH")"
        fi
      else
        printf 'from the start to %s before the end of each route' "$(pip_clock "$FROM")"
      fi
      ;;
    middle)
      printf 'the middle %s of each route' "$(pip_clock "${LENGTH:-0}")"
      ;;
    *)
      if [[ -n "$LENGTH" ]]; then
        if pip_gt "$FROM" 0; then
          printf '%s, starting %s in' "$(pip_clock "$LENGTH")" "$(pip_clock "$FROM")"
        else
          printf 'the first %s of each route' "$(pip_clock "$LENGTH")"
        fi
      else
        printf 'from %s to the end of each route' "$(pip_clock "$FROM")"
      fi
      ;;
  esac
}

pip_update_test() {
  TEST=0
  if pip_gt "$FROM" 0 || [[ -n "$LENGTH" || "$FROM_MODE" != begin ]]; then
    TEST=1
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
  local f="$1" out="$2" k n filter="" xy prev cur pre delay en b fw fh
  fw="${F_W[$f]}" fh="${F_H[$f]}"
  xy="$(pip_overlay_xy)"
  pre="$(pip_rear_pre)"
  pip_route_cover "$f"
  FF_ARGS=()
  if pip_gt "$WIN_START" 0; then
    FF_ARGS+=(-ss "$WIN_START")
  fi
  FF_ARGS+=(-i "${F_PATH[$f]}")
  for k in "${!USE_B[@]}"; do
    if pip_gt "${USE_SEEK[$k]}" 0; then
      FF_ARGS+=(-ss "${USE_SEEK[$k]}")
    fi
    FF_ARGS+=(-i "${F_PATH[${USE_B[$k]}]}")
  done
  n=${#USE_B[@]}

  if (( SWAP && n == 0 )); then
    filter="[0:v]setpts=PTS-STARTPTS[base0]"
    cur="base0"
  elif (( SWAP )); then
    filter="[0:v]setpts=PTS-STARTPTS,split=2[base0][fsrc]"
    prev="base0"
    for k in "${!USE_B[@]}"; do
      delay=""
      pip_gt "${USE_DELAY[$k]}" 0 && delay="+${USE_DELAY[$k]}/TB"
      filter+=";[$(( k + 1 )):v]setpts=PTS-STARTPTS${delay},${pre}"
      filter+="scale=${fw}:${fh}:force_original_aspect_ratio=decrease,"
      filter+="pad=${fw}:${fh}:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1[full$(( k + 1 ))]"
      filter+=";[${prev}][full$(( k + 1 ))]overlay=0:0:eof_action=pass[base$(( k + 1 ))]"
      prev="base$(( k + 1 ))"
    done
    filter+=";[fsrc]$(pip_inset_chain "$fw" "$fh" 0 0 "$fw")[ins]"
    en=""
    if (( COVER_KNOWN )) && (( ${#GAP_S[@]} > 0 )); then
      en="$(pip_enable_expr COV_S COV_E)"
    fi
    filter+=";[${prev}][ins]overlay=${xy}${en:+:enable='${en}'}[ov]"
    cur="ov"
  else
    filter="[0:v]setpts=PTS-STARTPTS"
    if [[ "$GAP_FILL" == black ]] && (( COVER_KNOWN )) && (( ${#GAP_S[@]} > 0 )); then
      b="${R_BACKS[$f]%% *}"
      pip_inset_size "${F_W[$b]}" "${F_H[$b]}" "$CROP_TOP" "$CROP_BOTTOM" "$fw"
      pip_box_xy "$BOX_W" "$BOX_H" "$fw" "$fh"
      filter+=",drawbox=x=${BOX_X}:y=${BOX_Y}:w=${BOX_W}:h=${BOX_H}:color=black:t=fill"
      filter+=":enable='$(pip_enable_expr GAP_S GAP_E)'"
    fi
    filter+="[main]"
    prev="main"
    for k in "${!USE_B[@]}"; do
      b="${USE_B[$k]}"
      delay=""
      pip_gt "${USE_DELAY[$k]}" 0 && delay="+${USE_DELAY[$k]}/TB"
      filter+=";[$(( k + 1 )):v]setpts=PTS-STARTPTS${delay},${pre}"
      filter+="$(pip_inset_chain "${F_W[$b]}" "${F_H[$b]}" "$CROP_TOP" "$CROP_BOTTOM" "$fw")[pip$(( k + 1 ))]"
      cur="ov$(( k + 1 ))"
      filter+=";[${prev}][pip$(( k + 1 ))]overlay=${xy}:eof_action=pass[${cur}]"
      prev="$cur"
    done
    cur="$prev"
  fi
  filter+=";[${cur}]"
  if [[ -n "$OUT_WIDTH" ]]; then
    filter+="scale=${OUT_WIDTH}:-2,"
  fi
  filter+="format=yuv420p[v]"

  FF_ARGS+=(-filter_complex "$filter" -map '[v]')
  if (( AUDIO )); then
    FF_ARGS+=(-map '0:a?' -c:a aac -b:a 160k)
  else
    FF_ARGS+=(-an)
  fi
  FF_ARGS+=("${ENC_ARGS[@]}" -movflags +faststart)
  if (( TEST )) && [[ -n "$WIN_LEN" ]]; then
    FF_ARGS+=(-t "$WIN_LEN")
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

pip_clock_whole() {
  awk -v s="${1:-0}" 'BEGIN {
    if (s < 0) s = 0
    t = int(s + 0.5)
    printf "%02d:%02d:%02d", int(t / 3600), int((t % 3600) / 60), t % 60
  }'
}

# Wall-clock time still to wait. Under an hour: "6m 7s". From one hour: "1h 2m".
pip_eta_left() {
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
pip_eta_arrival() {
  local now arrival
  now="$(date +%s)"
  arrival="$(awk -v n="$now" -v r="$1" 'BEGIN {
    a = int(n + r + 0.5)
    s = a % 60
    if (s >= 30) a += 60 - s
    else a -= s
    printf "%d", a
  }')"
  if [[ "$(date -d "@${arrival}" '+%Y.%m.%d')" == "$(date '+%Y.%m.%d')" ]]; then
    printf 'at %s' "$(date -d "@${arrival}" '+%H:%M')"
  else
    printf 'at %s' "$(date -d "@${arrival}" '+%Y.%m.%d %H:%M')"
  fi
}

pip_draw_progress() {
  local done_s="$1" total="$2" speedx="$3" label="$4"
  local width=40 filled=0 pct=" --" bar eta="left --  at --" spd="${speedx%x}" remain tot_clock="--:--:--"
  if [[ -n "$total" ]] && pip_gt "$total" 0; then
    pct="$(awk -v e="$done_s" -v t="$total" 'BEGIN { p = int(e / t * 100 + 0.5); if (p > 100) p = 100; printf "%3d", p }')"
    filled="$(awk -v e="$done_s" -v t="$total" -v w="$width" 'BEGIN { n = int(e / t * w + 0.5); if (n > w) n = w; printf "%d", n }')"
    tot_clock="$(pip_clock_whole "$total")"
    if [[ "$spd" =~ ^[0-9]+([.][0-9]+)?$ ]] && pip_gt "$spd" 0; then
      remain="$(awk -v e="$done_s" -v t="$total" -v s="$spd" 'BEGIN { r = (t - e) / s; if (r < 0) r = 0; printf "%.3f", r }')"
      eta="left $(pip_eta_left "$remain")  $(pip_eta_arrival "$remain")"
    fi
  fi
  bar="$(printf '%*s' "$filled" '' | tr ' ' '#')$(printf '%*s' $(( width - filled )) '' | tr ' ' '-')"
  printf '\r%s[%s] %s%%  %s / %s  %s  %s\033[K' \
    "${label:+${label} }" "$bar" "$pct" "$(pip_clock_whole "$done_s")" "$tot_clock" "$speedx" "$eta"
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

pip_join_gaps() {
  local k out=""
  for k in "${!GAP_S[@]}"; do
    out+="${out:+, }$(pip_clock "${GAP_S[$k]}") - $(pip_clock "${GAP_E[$k]}")"
  done
  printf '%s' "$out"
}

pip_print_route() {
  local n="$1" total="$2" f="$3" b d k fdur out out_note gpx real_after note out_size
  fdur="${F_DUR[$f]}"
  out="$(pip_output_path "$f")"
  ROUTE_OUT[$f]="$out"
  pip_route_cover "$f"

  pip_heading "Route ${n} of ${total}   ${F_DAY[$f]}  ${F_CLOCK_START[$f]} - ${F_CLOCK_END[$f]}   x${F_SPEED[$f]}"
  if (( SWAP )); then
    printf '  %sFront%s  in the corner\n' "$C_B" "$C_0"
  else
    printf '  %sFront%s  full frame\n' "$C_B" "$C_0"
  fi
  printf '         %s\n' "$(basename -- "${F_PATH[$f]}")"
  if [[ -n "$fdur" ]]; then
    printf '         %s%s, video length %s%s\n' "$C_DIM" "${F_W[$f]:-?}x${F_H[$f]:-?}" "$(pip_clock "$fdur")" "$C_0"
  else
    printf '         %svideo length unknown (ffprobe could not read it)%s\n' "$C_Y" "$C_0"
  fi
  if (( SWAP )); then
    printf '  %sBack%s   full frame, fitted inside %sx%s with black bars if its shape differs\n' \
      "$C_B" "$C_0" "${F_W[$f]:-?}" "${F_H[$f]:-?}"
  else
    printf '  %sBack%s   in the corner\n' "$C_B" "$C_0"
  fi
  for k in "${!BK_IDX[@]}"; do
    b="${BK_IDX[$k]}"
    d="${BK_D[$k]}"
    printf '    %s[%d]%s %s\n' "$C_C" $(( k + 1 )) "$C_0" "$(basename -- "${F_PATH[$b]}")"
    printf '        %s - %s on the clock, %s\n' "${F_CLOCK_START[$b]}" "${F_CLOCK_END[$b]}" "${F_W[$b]:-?}x${F_H[$b]:-?}"
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
    if [[ -n "${BK_E[$k]}" ]]; then
      printf '        shown %s - %s\n' "$(pip_clock "${BK_S[$k]}")" "$(pip_clock "${BK_E[$k]}")"
    else
      printf '        %slength unknown, cannot tell where it ends%s\n' "$C_Y" "$C_0"
    fi
  done
  if (( ${#GAP_S[@]} > 0 )); then
    if (( SWAP )); then
      printf '  %sNo rear%s  %s  (front full frame, no inset)\n' "$C_Y" "$C_0" "$(pip_join_gaps)"
    elif [[ "$GAP_FILL" == black ]]; then
      printf '  %sCorner black%s  %s\n' "$C_Y" "$C_0" "$(pip_join_gaps)"
    else
      printf '  %sCorner empty%s  %s\n' "$C_Y" "$C_0" "$(pip_join_gaps)"
    fi
  fi
  for note in "${COVER_NOTES[@]}"; do
    printf '  %sNote%s  %s\n' "$C_Y" "$C_0" "$note"
  done

  ROUTE_STATE[$f]=render
  if pip_layout_check "$f"; then
    pip_box_xy "$BOX_W" "$BOX_H" "${F_W[$f]}" "${F_H[$f]}"
    printf '  %sInset%s   %sx%s at x %s, y %s (%s, %s)\n' "$C_B" "$C_0" "$BOX_W" "$BOX_H" "$BOX_X" "$BOX_Y" \
      "$(pip_corner_label)" "$(pip_size_label)"
    out_size="${F_W[$f]}x${F_H[$f]}"
    if [[ -n "$OUT_WIDTH" ]]; then
      out_size="${OUT_WIDTH}x$(pip_even "$(pip_calc "$OUT_WIDTH * ${F_H[$f]} / ${F_W[$f]}")")"
    fi
  else
    printf '  %sCannot render%s  %s\n' "$C_R" "$C_0" "$LAYOUT_ERR"
    ROUTE_STATE[$f]=bad
    out_size="?"
  fi
  if (( TEST )); then
    pip_window "$f"
    printf '  %sRender%s  part: %s - %s of %s\n' "$C_B" "$C_0" "$(pip_clock "$WIN_START")" \
      "$(pip_clock "${WIN_END:-0}")" "$(pip_clock "${F_DUR[$f]:-0}")"
    [[ -n "$WIN_NOTE" ]] && printf '          %s%s%s\n' "$C_Y" "$WIN_NOTE" "$C_0"
  fi
  out_note="${C_G}new${C_0}"
  if [[ -e "$out" ]]; then
    if (( REDO )); then
      out_note="${C_Y}exists, will be replaced${C_0}"
    else
      out_note="${C_Y}exists ($(pip_human_size "$(stat -c %s -- "$out" 2>/dev/null || echo 0)")), skipped; --redo replaces it${C_0}"
      [[ "${ROUTE_STATE[$f]}" == render ]] && ROUTE_STATE[$f]=exists
      (( EXISTING++ )) || true
    fi
  fi
  printf '  %sOutput%s  %s\n' "$C_B" "$C_0" "$(basename -- "$out")"
  printf '          %s, %s\n' "$out_size" "$out_note"
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
  [[ "$SIZE_SPEC" != 1/2 ]] && cmd+=(--pip-size "$SIZE_SPEC")
  [[ "$CORNER" != tl ]] && cmd+=(--corner "$CORNER")
  if (( M_TOP == M_BOTTOM && M_TOP == M_LEFT && M_TOP == M_RIGHT )); then
    (( M_TOP != 0 )) && cmd+=(--margin "$M_TOP")
  else
    (( M_TOP != 0 )) && cmd+=(--margin-top "$M_TOP")
    (( M_BOTTOM != 0 )) && cmd+=(--margin-bottom "$M_BOTTOM")
    (( M_LEFT != 0 )) && cmd+=(--margin-left "$M_LEFT")
    (( M_RIGHT != 0 )) && cmd+=(--margin-right "$M_RIGHT")
  fi
  (( MIRROR )) && cmd+=(--mirror)
  (( CROP_TOP != 0 )) && cmd+=(--crop-top "$CROP_TOP")
  (( CROP_BOTTOM != 0 )) && cmd+=(--crop-bottom "$CROP_BOTTOM")
  (( BORDER != 0 )) && cmd+=(--border "$BORDER")
  (( BORDER != 0 )) && [[ "$BORDER_COLOR" != white ]] && cmd+=(--border-color "$BORDER_COLOR")
  [[ -n "$LABEL" ]] && cmd+=(--label "$LABEL")
  (( SWAP )) && cmd+=(--swap)
  [[ "$GAP_FILL" != none ]] && cmd+=(--gap-fill "$GAP_FILL")
  [[ -n "$OUT_WIDTH" ]] && cmd+=(--out-width "$OUT_WIDTH")
  [[ "$ENCODER" != auto ]] && cmd+=(--encoder "$ENCODER")
  [[ -n "$QUALITY" ]] && cmd+=(--quality "$QUALITY")
  case "$FROM_MODE" in
    end)    cmd+=(--from-end "$(pip_clock "$FROM")") ;;
    middle) cmd+=(--middle) ;;
    *)      pip_gt "$FROM" 0 && cmd+=(--from "$(pip_clock "$FROM")") ;;
  esac
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
  local n=0 f total
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
  if (( SWAP )); then
    printf '  %-14s %s\n' "Layout" "swapped: rear full frame, front in the corner"
  else
    printf '  %-14s %s\n' "Layout" "front full frame, rear in the corner"
  fi
  printf '  %-14s %s, %s\n' "Inset" "$(pip_size_label)" "$(pip_corner_label)"
  printf '  %-14s %s\n' "Margins" "$(pip_margins_label)"
  printf '  %-14s %s\n' "Extras" "$(pip_extras_label)"
  if [[ -n "$OUT_WIDTH" ]]; then
    printf '  %-14s %s\n' "Output size" "${OUT_WIDTH} px wide"
  else
    printf '  %-14s %s\n' "Output size" "same as the front camera"
  fi
  printf '  %-14s %s\n' "Encoder" "$ENC_LABEL"
  if (( AUDIO )); then
    printf '  %-14s %s\n' "Audio" "from the front camera, if it has any"
  else
    printf '  %-14s %s\n' "Audio" "none"
  fi
  printf '  %-14s %s\n' "Render" "$(pip_part_label)"
  if [[ "$SHIFT" != 0 ]]; then
    printf '  %-14s %s\n' "Clock shift" "back files moved ${SHIFT}s (real time)"
  fi
  printf '  %-14s %s\n' "Command" "$(pip_equivalent_command)"
  TO_RENDER=0
  BAD=0
  for f in "${ROUTES[@]}"; do
    case "${ROUTE_STATE[$f]}" in
      render) (( TO_RENDER++ )) || true ;;
      bad) (( BAD++ )) || true ;;
    esac
  done
  echo
  printf '%s%d route(s), %d to render%s' "$C_B" "$total" "$TO_RENDER" "$C_0"
  (( EXISTING > 0 )) && printf ', %d already rendered' "$EXISTING"
  (( BAD > 0 )) && printf ', %s%d cannot be rendered with these settings%s' "$C_R" "$BAD" "$C_0"
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

# Typed answer with Enter and q listed like the one-key questions. q quits.
pip_ask_line() {
  local name="$1" cur="$2"
  echo "  [Enter] Keep the current answer: ${cur}"
  echo "  [q]     Quit the script, render nothing more"
  pip_read_line "${name} [${cur}] (q = quit): " "$cur"
  [[ "${REPLY,,}" == q ]] && pip_quit
  return 0
}

# Question, current 0/1, what yes means, what no means.
pip_yes_no() {
  local question="$1" cur="$2" yes_text="$3" no_text="$4" def=n keys="y/N/q" ydef="" ndef=" (current, default)"
  if (( cur )); then
    def=y keys="Y/n/q" ydef=" (current, default)" ndef=""
  fi
  printf '%s [%s]\n' "$question" "$keys"
  echo "  [y] Yes${ydef}"
  echo "      ${yes_text}"
  echo "  [n] No${ndef}"
  echo "      ${no_text}"
  echo "  [q] Quit the script, render nothing more"
  pip_read_key "${question%\?} [${keys}]: " "$def"
  case "$REPLY" in
    y) REPLY=1 ;;
    n) REPLY=0 ;;
    q) pip_quit ;;
    *) echo "$(pip_ts) Unknown choice. Keeping the current answer."; REPLY="$cur" ;;
  esac
}

pip_first_back_size() {
  local i
  for i in "${!F_CAM[@]}"; do
    if [[ "${F_CAM[$i]}" == back && -n "${F_W[$i]}" ]]; then
      printf ' The rear picture is %sx%s.' "${F_W[$i]}" "${F_H[$i]}"
      return 0
    fi
  done
}

pip_prompt_more() {
  local v key
  local -a w=()
  pip_heading "More choices"
  echo "  Enter keeps the answer in brackets. q quits."

  echo
  echo "Inset size: how big is the small picture?"
  echo "  1/2 or 1/3   that part of its own width and height (1/2 is the default)"
  echo "  40%          that percent of the full frame's width"
  echo "  960px        that many pixels wide"
  echo "  The height always follows the picture's shape."
  pip_ask_line "Size" "$SIZE_SPEC"
  pip_set_size "$REPLY" || echo "$(pip_ts) ${C_Y}Not a size: ${REPLY}. Keeping ${SIZE_SPEC}.${C_0}"

  echo
  case "$CORNER" in tr) key=2 ;; ll) key=3 ;; lr) key=4 ;; *) key=1 ;; esac
  echo "Which corner of the frame should the inset sit in? [1/2/3/4/q]"
  echo "  The margins asked next are measured from that corner's two edges."
  echo "  [1] Top left$([[ $key == 1 ]] && printf ' (current, default)')"
  echo "  [2] Top right$([[ $key == 2 ]] && printf ' (current, default)')"
  echo "  [3] Lower left$([[ $key == 3 ]] && printf ' (current, default)')"
  echo "  [4] Lower right$([[ $key == 4 ]] && printf ' (current, default)')"
  echo "  [q] Quit the script, render nothing more"
  pip_read_key "Corner [1/2/3/4/q] (Enter = ${key}): " "$key"
  case "$REPLY" in
    1) CORNER=tl ;;
    2) CORNER=tr ;;
    3) CORNER=ll ;;
    4) CORNER=lr ;;
    q) pip_quit ;;
    *) echo "$(pip_ts) Unknown choice: ${REPLY}. Keeping $(pip_corner_label)." ;;
  esac

  echo
  echo "Margins: gap in pixels between the inset and the frame edges"
  echo "  one number      all four sides (0 is flush in the corner)"
  echo "  two numbers     top and bottom, then left and right"
  echo "  four numbers    top bottom left right"
  echo "  Only the two edges at the chosen corner matter."
  pip_ask_line "Margins" "${M_TOP} ${M_BOTTOM} ${M_LEFT} ${M_RIGHT}"
  read -r -a w <<<"$REPLY"
  if (( ${#w[@]} == 1 )) && pip_is_px "${w[0]}"; then
    M_TOP=$(( 10#${w[0]} )) M_BOTTOM=$M_TOP M_LEFT=$M_TOP M_RIGHT=$M_TOP
  elif (( ${#w[@]} == 2 )) && pip_is_px "${w[0]}" && pip_is_px "${w[1]}"; then
    M_TOP=$(( 10#${w[0]} )) M_BOTTOM=$M_TOP M_LEFT=$(( 10#${w[1]} )) M_RIGHT=$M_LEFT
  elif (( ${#w[@]} == 4 )) && pip_is_px "${w[0]}" && pip_is_px "${w[1]}" && pip_is_px "${w[2]}" && pip_is_px "${w[3]}"; then
    M_TOP=$(( 10#${w[0]} )) M_BOTTOM=$(( 10#${w[1]} )) M_LEFT=$(( 10#${w[2]} )) M_RIGHT=$(( 10#${w[3]} ))
  else
    echo "$(pip_ts) ${C_Y}Not 1, 2, or 4 whole numbers: ${REPLY}. Keeping $(pip_margins_label).${C_0}"
  fi

  echo
  pip_yes_no "Mirror the rear picture?" "$MIRROR" \
    "Flip it left to right, so it reads like a rear-view mirror. Its own text and timestamp read backwards." \
    "Keep it as the rear camera recorded it."
  MIRROR="$REPLY"

  echo
  echo "Cut pixels off the rear picture before it is scaled"
  echo "  Useful to remove the rear camera's own timestamp bar or the car's roof."
  echo "  Type two whole numbers: pixels from the top, then pixels from the bottom."
  echo "  0 0 cuts nothing.$(pip_first_back_size)"
  pip_ask_line "Top and bottom" "${CROP_TOP} ${CROP_BOTTOM}"
  read -r -a w <<<"$REPLY"
  if (( ${#w[@]} == 2 )) && pip_is_px "${w[0]}" && pip_is_px "${w[1]}"; then
    CROP_TOP=$(( 10#${w[0]} )) CROP_BOTTOM=$(( 10#${w[1]} ))
  else
    echo "$(pip_ts) ${C_Y}Not two whole numbers: ${REPLY}. Keeping ${CROP_TOP} ${CROP_BOTTOM}.${C_0}"
  fi

  echo
  echo "Border around the inset"
  echo "  A frame drawn around the small picture so it stands out from the road."
  echo "  Type its width in pixels, 0 to 100. 0 means no border."
  pip_ask_line "Border width" "$BORDER"
  if [[ "$REPLY" =~ ^[0-9]+$ ]] && (( 10#$REPLY <= 100 )); then
    BORDER=$(( 10#$REPLY ))
  else
    echo "$(pip_ts) ${C_Y}Not 0 to 100: ${REPLY}. Keeping ${BORDER}.${C_0}"
  fi
  if (( BORDER > 0 )); then
    echo
    echo "Border color"
    echo "  A color name such as white, black, red, yellow, or a hex value like #ffcc00."
    pip_ask_line "Border color" "$BORDER_COLOR"
    pip_set_border_color "$REPLY" || echo "$(pip_ts) ${C_Y}Not a color: ${REPLY}. Keeping ${BORDER_COLOR}.${C_0}"
  fi

  echo
  echo "Caption on the inset"
  echo "  Text written at the bottom of the small picture, for example REAR or TYL."
  echo "  Type the text. - removes the caption."
  echo "  Not allowed: ' \\ : % , ; = [ ]"
  if (( ! HAVE_DRAWTEXT )); then
    echo "  ${C_Y}This ffmpeg has no drawtext filter, so a caption is skipped when rendering.${C_0}"
  fi
  pip_ask_line "Caption" "${LABEL:--}"
  if [[ "$REPLY" == - ]]; then
    LABEL=""
  elif pip_label_ok "$REPLY"; then
    LABEL="$REPLY"
  else
    echo "$(pip_ts) ${C_Y}A caption cannot contain ' \\ : % , ; = [ ]. Keeping ${LABEL:-none}.${C_0}"
  fi

  echo
  pip_yes_no "Swap the cameras?" "$SWAP" \
    "Rear camera full frame (black bars if its shape differs), front camera in the corner. While no rear file plays, the front fills the frame." \
    "Front camera full frame, rear camera in the corner."
  SWAP="$REPLY"

  if (( ! SWAP )); then
    echo
    local gap_cur=0
    [[ "$GAP_FILL" == black ]] && gap_cur=1
    pip_yes_no "Fill the corner while no rear file plays?" "$gap_cur" \
      "Draw a black box of the inset's size during each gap, so the corner never jumps between road and picture." \
      "Leave the corner empty: the front picture shows through until the next rear file starts."
    if (( REPLY )); then GAP_FILL=black; else GAP_FILL=none; fi
  fi

  echo
  echo "Output width"
  echo "  Scale the finished video to this many pixels wide; the height follows."
  echo "  1920 makes a smaller file that plays on more devices."
  echo "  0 keeps the front camera's size (for example 2592x1944)."
  pip_ask_line "Output width" "${OUT_WIDTH:-0}"
  if [[ "$REPLY" =~ ^[0-9]+$ ]]; then
    v=$(( 10#$REPLY ))
    if (( v == 0 )); then
      OUT_WIDTH=""
    elif (( v >= 160 && v <= 8000 )); then
      OUT_WIDTH="$(pip_even "$v")"
    else
      echo "$(pip_ts) ${C_Y}Not 0 or 160 to 8000: ${REPLY}. Keeping ${OUT_WIDTH:-the front size}.${C_0}"
    fi
  else
    echo "$(pip_ts) ${C_Y}Not a number: ${REPLY}. Keeping ${OUT_WIDTH:-the front size}.${C_0}"
  fi
}

pip_prompt_more_first() {
  echo
  printf '%sMore choices? [N/y/q]%s\n' "$C_B" "$C_0"
  echo "  [N] Keep the current layout (default)"
  echo "      $(pip_size_label), $(pip_corner_label), margins $(pip_margins_label), extras: $(pip_extras_label)."
  echo "      The plan is printed next, and nothing is rendered before you agree."
  echo "  [y] Change the layout first"
  echo "      Asks, one at a time: inset size, corner, margins, mirror, crop,"
  echo "      border, caption, swap, black gap box, and output width."
  echo "      Enter keeps each current answer."
  echo "  [q] Quit the script, render nothing"
  pip_read_key "More choices? [N/y/q]: " n
  case "$REPLY" in
    y) pip_prompt_more ;;
    q) pip_quit ;;
  esac
}

# " (current, default)" when the two keys match.
pip_cur_mark() {
  [[ "$1" == "$2" ]] && printf ' (current, default)'
  return 0
}

pip_prompt_test() {
  local v key len_txt
  if [[ -z "$LENGTH" ]] && (( ! TEST )); then
    key=a
  elif [[ -z "$LENGTH" ]]; then
    key=c
  else
    case "$(pip_calc "$LENGTH")" in
      60.000) key=1 ;; 120.000) key=2 ;; 300.000) key=5 ;; *) key=c ;;
    esac
  fi
  echo
  echo "How much of each route should be rendered? [A/1/2/5/c/q]"
  echo "  A part is saved under its own -test-… name, so a full render is kept."
  echo "  [A] All of it, start to end$(pip_cur_mark a "$key")"
  echo "  [1] 1 minute$(pip_cur_mark 1 "$key")"
  echo "  [2] 2 minutes$(pip_cur_mark 2 "$key")"
  echo "  [5] 5 minutes$(pip_cur_mark 5 "$key")"
  echo "  [c] Custom length, typed next$(pip_cur_mark c "$key")"
  echo "      For example 0:30, 10:00, 1:02:00, or 90 for seconds."
  echo "  [q] Quit the script, render nothing more"
  pip_read_key "Length [A/1/2/5/c/q]: " "$key"
  case "$REPLY" in
    a) LENGTH="" FROM=0 FROM_MODE=begin; pip_update_test; return 0 ;;
    1) LENGTH=60 ;;
    2) LENGTH=120 ;;
    5) LENGTH=300 ;;
    c)
      echo
      echo "Custom length of each part"
      echo "  Time in the sped-up video, as M:SS (4:40), H:MM:SS, or seconds (280)."
      len_txt="$(pip_clock "${LENGTH:-60}")"
      pip_ask_line "Length" "$len_txt"
      if v="$(pip_parse_time "$REPLY")" && pip_gt "$v" 0; then
        LENGTH="$v"
      else
        echo "$(pip_ts) ${C_Y}Not a time above 0: ${REPLY}. Using ${len_txt}.${C_0}"
        LENGTH="$(pip_parse_time "$len_txt")"
      fi
      ;;
    q) pip_quit ;;
    *) echo "$(pip_ts) Unknown choice: ${REPLY}. Using 1 minute."; LENGTH=60 ;;
  esac

  case "$FROM_MODE" in end) key=e ;; middle) key=m ;; *) key=b ;; esac
  echo
  echo "Where should that part be taken from? [B/E/M/q]"
  echo "  [B] Counted from the beginning$(pip_cur_mark b "$key")"
  echo "      0:00 starts at the very start."
  echo "  [E] Counted back from the end$(pip_cur_mark e "$key")"
  echo "      0:00 means the last $(pip_clock "$LENGTH") of each route."
  echo "  [M] The middle of each route$(pip_cur_mark m "$key")"
  echo "      No offset is asked."
  echo "  [q] Quit the script, render nothing more"
  pip_read_key "From [B/E/M/q]: " "$key"
  case "$REPLY" in
    b) [[ "$FROM_MODE" != begin ]] && FROM=0; FROM_MODE=begin ;;
    e) [[ "$FROM_MODE" != end ]] && FROM=0; FROM_MODE=end ;;
    m) FROM=0 FROM_MODE=middle ;;
    q) pip_quit ;;
    *) echo "$(pip_ts) Unknown choice: ${REPLY}. Keeping the current one." ;;
  esac

  if [[ "$FROM_MODE" != middle ]]; then
    echo
    if [[ "$FROM_MODE" == end ]]; then
      echo "Offset from the end"
      echo "  How far before the end of each route the part stops."
      echo "  0:00 is the last $(pip_clock "$LENGTH"); 1:00 stops one minute before the end."
    else
      echo "Offset from the beginning"
      echo "  How far into each route the part starts. 0:00 is the very start."
    fi
    echo "  Time in the sped-up video, as M:SS (4:40), H:MM:SS, or seconds (280)."
    pip_ask_line "Offset" "$(pip_clock "$FROM")"
    if v="$(pip_parse_time "$REPLY")"; then
      FROM="$v"
    else
      echo "$(pip_ts) ${C_Y}Not a time: ${REPLY}. Keeping $(pip_clock "$FROM").${C_0}"
    fi
  fi
  pip_update_test
}

pip_prompt_plan() {
  while true; do
    echo
    printf '%sRender now? [Y/c/m/t/r/q]%s\n' "$C_B" "$C_0"
    echo "  [Y] Render all ${TO_RENDER} route(s) listed above as new (default)"
    echo "      One after another, without asking again."
    echo "  [c] Choose route by route"
    echo "      Each route's plan is printed again, then you say yes or no to it."
    echo "  [m] Change the layout"
    echo "      Inset size, corner, margins, mirror, crop, border, caption, swap,"
    echo "      black gap box, output width. The plan is printed again afterwards."
    echo "  [t] Render only part of each route (for a test)"
    echo "      Pick how long, and where it starts: from the beginning, from the end,"
    echo "      or the middle. Now: $(pip_part_label)."
    if (( EXISTING > 0 )); then
      echo "  [r] Also replace the ${EXISTING} output(s) that already exist"
      echo "      They are marked \"exists\" above. The plan is printed again."
    fi
    echo "  [q] Quit the script, render nothing"
    pip_read_key "Render now? [Y/c/m/t/r/q]: " y
    case "$REPLY" in
      y) CHOOSE=0; return 0 ;;
      c) CHOOSE=1; return 0 ;;
      m) pip_prompt_more; pip_print_plan ;;
      t) pip_prompt_test; pip_print_plan ;;
      r) REDO=1; pip_print_plan ;;
      n|q) pip_quit ;;
      *) echo "$(pip_ts) Unknown choice: ${REPLY}." ;;
    esac
  done
}

# --- render -----------------------------------------------------------------

pip_render_route() {
  local n="$1" total="$2" f="$3" out label kind rc tries=0 start_s end_s gpx_out total_out route_t0 in_b b
  local -a kinds=()
  out="${ROUTE_OUT[$f]}"
  pip_route_inputs "$f"
  label=""
  (( total > 1 )) && label="${n}/${total}"
  total_out=""
  if [[ -n "$WIN_END" ]]; then
    total_out="$(pip_calc "$WIN_END - $WIN_START")"
  fi
  pip_heading "Rendering ${label:+${label}  }$(basename -- "$out")"
  mapfile -t kinds < <(pip_encoder_candidates)
  pip_proc_begin
  route_t0="$(pip_now_ns)"
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
      pip_proc_end
      pip_probe "$out"
      DONE_LIST+=("$out")
      DONE_SEC+=("$(pip_calc "$(pip_now_ns) - $route_t0")")
      DONE_VID+=("${PR_DUR:-0}")
      DONE_ENC+=("$ENC_LABEL")
      in_b=$(pip_file_bytes "${F_PATH[$f]}")
      for b in "${USE_B[@]}"; do
        in_b=$(( in_b + $(pip_file_bytes "${F_PATH[$b]}") ))
      done
      DONE_IN_B+=("$in_b")
      DONE_IN_N+=("$(( 1 + ${#USE_B[@]} ))")
      DONE_OUT_B+=("$(pip_file_bytes "$out")")
      return 0
    fi
    pip_cleanup_partial
    echo "$(pip_ts) ${C_R}ffmpeg failed with ${ENC_LABEL}.${C_0}" >&2
  done
  pip_proc_end
  if (( tries == 0 )); then
    echo "$(pip_ts) ${C_R}No usable encoder for '${ENCODER}'.${C_0}" >&2
  fi
  FAILED_LIST+=("$out")
  return 1
}

pip_print_summary() {
  local item i end_ns total_sec wait_sec vid_sum=0 enc_sum=0 in_sum=0 in_files=0 out_sum=0
  local -a size_lines=()
  pip_proc_end
  end_ns="$(pip_now_ns)"
  pip_heading "Summary"
  pip_summary_kv "Rendered" "${#DONE_LIST[@]} route(s)"
  for i in "${!DONE_LIST[@]}"; do
    printf '    %s\n' "${DONE_LIST[$i]}"
    printf '      %s%s video in %s, %sx real time, %s%s\n' "$C_DIM" \
      "$(pip_clock "${DONE_VID[$i]}")" "$(pip_format_elapsed "${DONE_SEC[$i]}")" \
      "$(awk -v v="${DONE_VID[$i]}" -v s="${DONE_SEC[$i]}" 'BEGIN { printf "%.2f", (s > 0 ? v / s : 0) }')" \
      "${DONE_ENC[$i]}" "$C_0"
    printf '      %sinput %s (%d file(s)), output %s%s\n' "$C_DIM" \
      "$(pip_size_short "${DONE_IN_B[$i]}")" "${DONE_IN_N[$i]}" \
      "$(pip_size_short "${DONE_OUT_B[$i]}")" "$C_0"
    vid_sum="$(pip_calc "$vid_sum + ${DONE_VID[$i]}")"
    enc_sum="$(pip_calc "$enc_sum + ${DONE_SEC[$i]}")"
    in_sum=$(( in_sum + DONE_IN_B[i] ))
    in_files=$(( in_files + DONE_IN_N[i] ))
    out_sum=$(( out_sum + DONE_OUT_B[i] ))
  done
  if (( ${#SKIPPED_LIST[@]} > 0 )); then
    pip_summary_kv "Skipped" "${#SKIPPED_LIST[@]} route(s)"
    for item in "${SKIPPED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  if (( ${#FAILED_LIST[@]} > 0 )); then
    printf '%s' "$C_R"
    pip_summary_kv "Failed" "${#FAILED_LIST[@]} route(s)"
    printf '%s' "$C_0"
    for item in "${FAILED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  if (( ${#DONE_LIST[@]} > 0 )); then
    pip_summary_kv "Video written" "$(pip_clock "$vid_sum")"
    pip_summary_kv "Encode time" "$(pip_format_elapsed "$enc_sum")  ($(awk -v v="$vid_sum" -v s="$enc_sum" \
      'BEGIN { printf "%.2f", (s > 0 ? v / s : 0) }')x real time on average)"
    mapfile -t size_lines < <(pip_format_size_pair "$in_sum" "$out_sum")
    pip_summary_kv "Input files" "${in_files} (front and rear files read)"
    pip_summary_kv "Input size" "${size_lines[0]}"
    pip_summary_kv "Output size" "${size_lines[1]}  ($(awk -v i="$in_sum" -v o="$out_sum" \
      'BEGIN { printf "%.0f", (i > 0 ? o * 100 / i : 0) }')% of input)"
  fi
  pip_heading "Timing"
  total_sec="$(awk -v s0="$SCRIPT_START_NS" -v s1="$end_ns" 'BEGIN { printf "%.6f", s1 - s0 }')"
  wait_sec="$(awk -v t="$total_sec" -v p="${PROC_SEC:-0}" 'BEGIN { w = t - p; if (w < 0) w = 0; printf "%.6f", w }')"
  pip_summary_kv "Started" "$(pip_format_wall_clock "$SCRIPT_START_NS")"
  pip_summary_kv "Finished" "$(date '+%Y.%m.%d %H:%M:%S')"
  pip_summary_kv "Total wall time" "$(pip_format_elapsed "$total_sec")"
  pip_summary_kv "Processing time" "$(pip_format_elapsed "${PROC_SEC:-0}")  (reading files, encoding)"
  pip_summary_kv "Other/wait time" "$(pip_format_elapsed "$wait_sec")  (prompts, startup, overhead)"
  [[ "$STOPPED" == yes ]] && pip_summary_kv "Stopped by user" "yes"
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

SCRIPT_START_NS=$(date +%s.%N)
PROC_SEC=0
PROC_SLICE_START=""
DONE_SEC=() DONE_VID=() DONE_ENC=() DONE_IN_B=() DONE_IN_N=() DONE_OUT_B=()
# shellcheck disable=SC1091
. /root/bin/_script_header.sh

DO_YES=0
DRY_RUN=0
REDO=0
SIZE_KIND=frac SIZE_A=1 SIZE_B=2 SIZE_SPEC=1/2
CORNER=tl
M_TOP=0 M_BOTTOM=0 M_LEFT=0 M_RIGHT=0
MIRROR=0
CROP_TOP=0 CROP_BOTTOM=0
BORDER=0 BORDER_COLOR=white
LABEL=""
SWAP=0
GAP_FILL=none
OUT_WIDTH=""
ENCODER=auto
QUALITY=""
FROM=0
FROM_MODE=begin
LENGTH=""
WIN_LEN="" WIN_NOTE=""
SHIFT=0
AUDIO=1
GPX=1
TEST=0
CHOOSE=0
MORE_FROM_CLI=0
INPUT_ARGS=()
F_PATH=() F_CAM=() F_START=() F_NAME_END=() F_SPEED=() F_DAY=() F_CLOCK_START=() F_CLOCK_END=()
F_DUR=() F_W=() F_H=()
FRONTS=() ROUTES=() ORPHAN_IDX=() ORPHAN_WHY=()
declare -A R_BACKS=() ROUTE_OUT=() ROUTE_STATE=() ROUTE_GPX=()
BK_IDX=() BK_D=() BK_S=() BK_E=() COV_S=() COV_E=() GAP_S=() GAP_E=() COVER_NOTES=() COVER_KNOWN=1
USE_B=() USE_DELAY=() USE_SEEK=() FF_ARGS=() ENC_ARGS=()
INS_W=0 INS_H=0 BOX_W=0 BOX_H=0 BOX_X=0 BOX_Y=0 LAYOUT_ERR="" WIN_START=0 WIN_END=""
HAVE_DRAWTEXT=0
ENC_LABEL="" ENCODER_LIST="" PARTIAL="" EXISTING=0 TO_RENDER=0 BAD=0
DONE_LIST=() SKIPPED_LIST=() FAILED_LIST=()
SUMMARY=0 SUMMARY_DONE=0 STOPPED=no
pip_colors

trap pip_on_exit EXIT
trap pip_ctrl_c INT

pip_need_value() {
  [[ $# -ge 2 && -n "$2" ]] || { echo "ERROR: missing value for $1" >&2; exit 1; }
}

pip_need_px() {
  pip_is_px "$2" || { echo "ERROR: $1 must be whole pixels, 0 to 4000 (got $2)" >&2; exit 1; }
  printf '%d\n' $(( 10#$2 ))
}

while [[ $# -gt 0 ]]; do
  opt="$1"
  val=""
  case "$opt" in
    --*=*) val="${opt#*=}"; opt="${opt%%=*}"; set -- "$opt" "$val" "${@:2}" ;;
  esac
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --history) print_script_history; exit 0 ;;
    -y|--yes) DO_YES=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    --redo) REDO=1; shift ;;
    --pip-size)
      pip_need_value "$@"
      pip_set_size "$2" || { echo "ERROR: --pip-size must be like 1/2, 40%, or 960px (got $2)" >&2; exit 1; }
      MORE_FROM_CLI=1; shift 2 ;;
    --pip-scale)
      pip_need_value "$@"
      [[ "$2" =~ ^[2-9]$|^1[0-9]$|^20$ ]] || { echo "ERROR: --pip-scale must be 2 to 20 (got $2)" >&2; exit 1; }
      pip_set_size "1/$2"; MORE_FROM_CLI=1; shift 2 ;;
    --corner)
      pip_need_value "$@"
      pip_set_corner "$2" || { echo "ERROR: --corner must be tl, tr, ll, or lr (got $2)" >&2; exit 1; }
      MORE_FROM_CLI=1; shift 2 ;;
    --margin)
      pip_need_value "$@"; v="$(pip_need_px "$1" "$2")" || exit 1
      M_TOP=$v M_BOTTOM=$v M_LEFT=$v M_RIGHT=$v; MORE_FROM_CLI=1; shift 2 ;;
    --margin-x)
      pip_need_value "$@"; v="$(pip_need_px "$1" "$2")" || exit 1
      M_LEFT=$v M_RIGHT=$v; MORE_FROM_CLI=1; shift 2 ;;
    --margin-y)
      pip_need_value "$@"; v="$(pip_need_px "$1" "$2")" || exit 1
      M_TOP=$v M_BOTTOM=$v; MORE_FROM_CLI=1; shift 2 ;;
    --margin-top)    pip_need_value "$@"; M_TOP="$(pip_need_px "$1" "$2")" || exit 1; MORE_FROM_CLI=1; shift 2 ;;
    --margin-bottom) pip_need_value "$@"; M_BOTTOM="$(pip_need_px "$1" "$2")" || exit 1; MORE_FROM_CLI=1; shift 2 ;;
    --margin-left)   pip_need_value "$@"; M_LEFT="$(pip_need_px "$1" "$2")" || exit 1; MORE_FROM_CLI=1; shift 2 ;;
    --margin-right)  pip_need_value "$@"; M_RIGHT="$(pip_need_px "$1" "$2")" || exit 1; MORE_FROM_CLI=1; shift 2 ;;
    --mirror) MIRROR=1; MORE_FROM_CLI=1; shift ;;
    --crop-top)    pip_need_value "$@"; CROP_TOP="$(pip_need_px "$1" "$2")" || exit 1; MORE_FROM_CLI=1; shift 2 ;;
    --crop-bottom) pip_need_value "$@"; CROP_BOTTOM="$(pip_need_px "$1" "$2")" || exit 1; MORE_FROM_CLI=1; shift 2 ;;
    --border)
      pip_need_value "$@"
      [[ "$2" =~ ^[0-9]+$ ]] && (( 10#$2 <= 100 )) || { echo "ERROR: --border must be 0 to 100 pixels (got $2)" >&2; exit 1; }
      BORDER=$(( 10#$2 )); MORE_FROM_CLI=1; shift 2 ;;
    --border-color)
      pip_need_value "$@"
      pip_set_border_color "$2" || { echo "ERROR: --border-color must be a color name or #RRGGBB (got $2)" >&2; exit 1; }
      MORE_FROM_CLI=1; shift 2 ;;
    --label)
      pip_need_value "$@"
      pip_label_ok "$2" || { echo "ERROR: --label cannot contain ' \\ : % , ; = [ ] (got $2)" >&2; exit 1; }
      LABEL="$2"; MORE_FROM_CLI=1; shift 2 ;;
    --swap) SWAP=1; MORE_FROM_CLI=1; shift ;;
    --gap-fill)
      pip_need_value "$@"
      case "${2,,}" in none|black) GAP_FILL="${2,,}" ;; *) echo "ERROR: --gap-fill must be none or black (got $2)" >&2; exit 1 ;; esac
      MORE_FROM_CLI=1; shift 2 ;;
    --out-width)
      pip_need_value "$@"
      [[ "$2" =~ ^[0-9]+$ ]] && (( 10#$2 == 0 || (10#$2 >= 160 && 10#$2 <= 8000) )) \
        || { echo "ERROR: --out-width must be 0 or 160 to 8000 pixels (got $2)" >&2; exit 1; }
      if (( 10#$2 == 0 )); then OUT_WIDTH=""; else OUT_WIDTH="$(pip_even "$2")"; fi
      MORE_FROM_CLI=1; shift 2 ;;
    --encoder)
      pip_need_value "$@"; ENCODER="${2,,}"
      case "$ENCODER" in auto|nvenc|x265|x264) ;; *) echo "ERROR: --encoder must be auto, nvenc, x265, or x264 (got $2)" >&2; exit 1 ;; esac
      shift 2 ;;
    --quality)
      pip_need_value "$@"
      [[ "$2" =~ ^[0-9]+$ ]] && (( 10#$2 <= 51 )) || { echo "ERROR: --quality must be 0 to 51 (got $2)" >&2; exit 1; }
      QUALITY=$(( 10#$2 )); shift 2 ;;
    --from)
      pip_need_value "$@"
      FROM="$(pip_parse_time "$2")" || { echo "ERROR: --from is not a time: $2" >&2; exit 1; }
      FROM_MODE=begin; shift 2 ;;
    --from-end)
      pip_need_value "$@"
      FROM="$(pip_parse_time "$2")" || { echo "ERROR: --from-end is not a time: $2" >&2; exit 1; }
      FROM_MODE=end; shift 2 ;;
    --middle)
      FROM=0 FROM_MODE=middle; shift ;;
    --length)
      pip_need_value "$@"
      LENGTH="$(pip_parse_time "$2")" || { echo "ERROR: --length is not a time: $2" >&2; exit 1; }
      pip_gt "$LENGTH" 0 || { echo "ERROR: --length must be more than 0" >&2; exit 1; }
      shift 2 ;;
    --shift)
      pip_need_value "$@"
      [[ "$2" =~ ^[-+]?[0-9]+([.][0-9]+)?$ ]] || { echo "ERROR: --shift must be seconds, for example 2 or -1.5 (got $2)" >&2; exit 1; }
      SHIFT="${2#+}"; shift 2 ;;
    --no-audio) AUDIO=0; shift ;;
    --no-gpx) GPX=0; shift ;;
    --) shift; INPUT_ARGS+=("$@"); break ;;
    -*) echo "ERROR: unknown option: $1 (see --help)" >&2; exit 1 ;;
    *) INPUT_ARGS+=("$1"); shift ;;
  esac
done

if [[ "$FROM_MODE" == middle && -z "$LENGTH" ]]; then
  echo "ERROR: --middle needs --length" >&2
  exit 1
fi
pip_update_test

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
if ffmpeg -hide_banner -filters 2>/dev/null | grep -Eq '^ *[A-Z.|]+ +drawtext '; then
  HAVE_DRAWTEXT=1
fi
pip_print_ffmpeg_box
if [[ -n "$LABEL" ]] && (( ! HAVE_DRAWTEXT )); then
  echo "$(pip_ts) ${C_Y}This ffmpeg has no drawtext filter (built without libfreetype/libharfbuzz); the caption \"${LABEL}\" is skipped.${C_0}"
fi
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

_interactive=0
if (( ! DO_YES && ! DRY_RUN )) && (( script_is_run_interactively )); then
  _interactive=1
fi
if (( _interactive )) && (( ! MORE_FROM_CLI )); then
  pip_prompt_more_first
fi

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
_ri=0
for f in "${ROUTES[@]}"; do
  (( _ri++ )) || true
  case "${ROUTE_STATE[$f]}" in
    exists) SKIPPED_LIST+=("${ROUTE_OUT[$f]} (already exists)"); continue ;;
    bad) SKIPPED_LIST+=("${ROUTE_OUT[$f]} (cannot be laid out with these settings)"); continue ;;
  esac
  (( _n++ )) || true
  if (( CHOOSE )); then
    pip_print_route "$_ri" "${#ROUTES[@]}" "$f"
    echo
    printf '%sRender route %d of %d? [Y/n/a/q]%s  %s\n' "$C_B" "$_ri" "${#ROUTES[@]}" "$C_0" "$(basename -- "${ROUTE_OUT[$f]}")"
    echo "  [Y] Yes, render this route now (default)"
    echo "      Then the next route is shown and asked about."
    echo "  [n] No, skip this route"
    echo "      Nothing is written for it. The next route is shown and asked about."
    echo "  [a] All: render this route and every remaining one"
    echo "      No more questions; each is rendered in turn."
    echo "  [q] Quit: stop here and render nothing more"
    echo "      Routes already rendered in this run are kept."
    pip_read_key "Render route ${_ri} of ${#ROUTES[@]}? [Y/n/a/q]: " y
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
