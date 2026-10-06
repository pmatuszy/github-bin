#!/bin/bash
# v. 20261006.124200 - the default key is the capital one, in the key list and on each option line
# v. 20261006.123500 - map choices: north up (default) or track up; --north-up, --track-up
# v. 20261006.122600 - default zoom 17 (about 800 m across) instead of 16
# v. 20261006.122200 - smooth the GPS track (asked at the start, default yes), with a tweak menu (default no)
# v. 20261006.121000 - no speed on the map by default (the dashcam picture shows it); --show-speed adds it
# v. 20261006.114923 - help says the drawing helper has its own -h, -v, and --history
# v. 20261006.114500 - missing ffmpeg, python3, or Pillow: list them and ask whether to install them with apt-get
# v. 20261006.113823 - moving OpenStreetMap map video from each video's GPX track, same length as the video

# 2026.10.06 - v. 0.8 - only the default key is a capital letter, in the [..] key list, on its option line, and on the prompt line: yes/no questions ([Y] Yes when yes is the default), Tweak the smoothing [N] No, map direction N/T, length A/1/2/5/c, old file K/d
# 2026.10.06 - v. 0.7 - "Map direction [N/t/q]" in the map choices: north up (default) or track up, where the map turns so the road ahead is up and a compass shows north; --north-up, --track-up; the plan's Map row says which
# 2026.10.06 - v. 0.6 - default zoom 17: about 800 m across 1080 px instead of 1.6 km; about twice the tiles; --zoom 16 for the old view
# 2026.10.06 - v. 0.5 - GPS smoothing, on by default: "Smooth the GPS track? [Y/n/q]" at the start, then "Tweak the smoothing? [y/N/q]" for line seconds, map seconds, jump limit, and curved movement; plan shows dropped jumps and a GPS track row; --no-smooth, --smooth, --smooth-map, --max-jump, --no-curve (any of them skips the questions)
# 2026.10.06 - v. 0.4 - the speed is left off the map by default, as the dashcam picture shows it; --show-speed or [y] in the map choices adds it; --no-speed is still accepted
# 2026.10.06 - v. 0.3 - help: the drawing helper video-pgm-create-map-video-from-gpx.py has its own -h, -v, and --history
# 2026.10.06 - v. 0.2 - missing prerequisites (ffmpeg/ffprobe, python3, Pillow) are listed with what each is for and the apt-get command; in a terminal the script asks [Y/n/q] and installs them (sudo when not root), refreshing the package lists if the first try fails; with -y or no terminal it only prints the command
# 2026.10.06 - v. 0.1 - initial release: find each FrontCam video and its .gpx, print the plan (track, tiles, output), ask, download and cache the map tiles, render a north-up map centred on the car with the driven and remaining track, speed and clock; hevc_nvenc with libx265 fallback; existing outputs skipped, or rendered again with the old file kept as _old-YYYYMMDD_HHMMSS or deleted
#
# video-pgm-create-map-video-from-gpx.sh
#
# Make a video of a moving map for each dashcam video that has a .gpx track.
# The map follows the car (north up or track up, zoomed in), shows the road already driven
# and the road ahead, and the clock (the speed only with --show-speed, as the
# dashcam picture shows it already). It is exactly as long as the
# video and has the same frame rate, so it can be played beside it or put into
# a corner later. Map data: OpenStreetMap tiles, downloaded once and cached.
# The drawing is done by video-pgm-create-map-video-from-gpx.py next to this file.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [options] [DIR|VIDEO ...]
       [-y|--yes] [-n|--dry-run] [--redo] [--old keep|delete]
       [--size WxH|N] [--zoom N] [--north-up|--track-up] [--fps N|same] [--show-speed] [--no-clock]
       [--no-smooth] [--smooth S] [--smooth-map S] [--max-jump KMH] [--no-curve]
       [--gpx FILE] [--start 'YYYY-MM-DD HH:MM:SS'] [--speed N] [--tz-shift HOURS]
       [--tile-url URL] [--attribution TEXT] [--cache DIR]
       [--encoder auto|nvenc|x265|x264] [--quality N] [--from TIME] [--length TIME]

Make a moving-map video for each video that has a GPS track.

With no paths, the current directory is read. A directory gives its FrontCam
videos; a video file can also be named directly. The track is the .gpx with the
same name, or the same name without the -x5 speed part, for example:
  ...-FrontCam-concat-x5.mp4  uses  ...-FrontCam-concat.gpx

How the map follows the video
  - The start clock and the speed come from the video name
    (20260926_110627-20260926-130427-...-x5.mp4: starts 11:06:27, 5 times faster).
    Video time t is real time  start + t x speed.
  - GPX times are UTC; the name clock is local time. Both are turned into the
    same clock. If the track is whole hours off (a camera set to the wrong time
    zone), it is moved by those hours and the plan says so. --tz-shift sets it.
  - Before the first GPS point the car waits at the start ("waiting for GPS");
    after the last one it stays at the end. A gap of more than a minute between
    points shows "no GPS here".
  - The track is smoothed first (see GPS smoothing below): single wild points
    are dropped, the zigzag is averaged out, and the car moves on a curve.
  - The map is north up (or track up with --track-up) and centred on the car.
    Zoom 17 shows about 800 m across a 1080 px picture in Poland.

Map tiles
  Tiles come from tile.openstreetmap.org and are kept in the cache, so each
  tile is downloaded once for all videos and runs. The plan shows how many are
  needed and how many are already there. Two downloads at a time, as the
  OpenStreetMap tile policy asks. The picture says "© OpenStreetMap contributors".
  A whole 130 km route at 1080x1080 needs about 5,000 tiles at zoom 17 and
  about 2,500 at zoom 16.

Output
  The video name with FrontCam replaced by Map, beside the video:
    ...-70mai-A510-Map-concat-x5.mp4
  Other names get -Map before .mp4. A short try (--from or --length) adds
  -test-from-1m00s-len-2m00s. A video that already has its map is listed at the
  start; it is skipped, or rendered again with the old file renamed to
  ..._old-YYYYMMDD_HHMMSS.mp4 (the time it was made) or deleted.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask. Download the tiles and render everything new.
  -n, --dry-run        Print the plan and the commands; download and render nothing.
  --redo               Render videos that already have a map video again.
  --old keep|delete    What happens to the old map video when the new one is done.
                       keep (default): renamed to ..._old-YYYYMMDD_HHMMSS.mp4.

 Picture
  --size WxH|N         Picture size. Default 1080x1080. 720 means 720x720.
  --zoom N             Map zoom, 12 to 18. Default 17. One step out shows twice
                       as much: 16 or 15 for motorways at x5, 18 for towns.
  --north-up           North at the top (default).
  --track-up           The map turns so the road ahead is up, like a car
                       navigation; a small compass shows north. About 4
                       times slower to render (roughly real time).
  --fps N|same         Frames per second. Default: same as the video.
                       The length is the same either way.
  --show-speed         Also show the speed (km/h). Off by default: the dashcam
                       picture shows it already. --no-speed keeps it off.
  --no-clock           Leave out the clock.

 GPS smoothing (on by default; asked at the start unless one of these is given)
  --no-smooth          Use the GPS points as recorded, joined by straight lines.
  --smooth S           Seconds of driving each point of the line is averaged
                       over. Default 4. 0 keeps the line on every point.
  --smooth-map S       Seconds for the calmer path the map centre and the arrow
                       direction follow. Default 8, never less than --smooth.
  --max-jump KMH       Leave out single points that mean driving faster than
                       this. Default 250. 0 keeps every point.
  --no-curve           Straight lines between points instead of a curve.
                       The .gpx file is never changed.

 Track and time
  --gpx FILE           Use this track (only with one video).
  --start 'YYYY-MM-DD HH:MM:SS'
                       Local time at the start of the video, for a video
                       without a clock in its name (only with one video).
  --speed N            Real seconds per video second. Default: from the name
                       (-x5 is 5), otherwise 1.
  --tz-shift HOURS     Add this many hours to the GPX times instead of guessing.

 Tiles
  --tile-url URL       Tile address with {z} {x} {y} (and {s} for a, b, c).
                       Default https://tile.openstreetmap.org/{z}/{x}/{y}.png
  --attribution TEXT   Credit in the corner. Default "© OpenStreetMap contributors".
  --cache DIR          Tile cache. Default ~/.cache/video-pgm-map-tiles/<server>.

 Encoding and timing
  --encoder KIND       auto (default): hevc_nvenc on the GPU, then libx265.
                       nvenc, x265, or x264 force one encoder.
  --quality N          hevc_nvenc -cq or libx265/libx264 -crf. Default 24.
  --from TIME          Start this far into the video. Seconds, M:SS, or H:MM:SS.
  --length TIME        Render only this much.

Needs: python3 with Pillow (python3-pil), ffmpeg, ffprobe, and internet for tiles
that are not cached yet. When something is missing the script lists it and asks
whether to install it with apt-get (with sudo when not root). With -y or without
a terminal it only prints the install command.
The drawing helper video-pgm-create-map-video-from-gpx.py has its own -h, -v,
and --history.

Examples:
  $(basename "$0")
      Read the current directory, print the plan, ask before rendering.
  $(basename "$0") --length 1:00 --from 10:00
      One minute of every map, ten minutes in, to check how it looks.
  $(basename "$0") -y --zoom 15 --size 1280x720
  $(basename "$0") -n 'P:\\video\\20260926-Bonow-Deblin\\_samochod-jazda'
EOF
}

mv_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

mv_colors() {
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

mv_rule() {
  local ch="${1:-─}" width="${2:-78}"
  printf '%*s' "$width" '' | sed "s/ /${ch}/g"
}

mv_heading() {
  local title="$1" width=78 rest
  rest=$(( width - ${#title} - 4 ))
  (( rest < 3 )) && rest=3
  echo
  printf '%s══ %s %s%s\n' "$C_B$C_C" "$title" "$(mv_rule '═' "$rest")" "$C_0"
}

mv_print_box_lines() {
  local -a lines=("$@")
  local line width=0
  for line in "${lines[@]}"; do
    (( ${#line} > width )) && width=${#line}
  done
  printf '┌%s┐\n' "$(mv_rule '─' $(( width + 2 )))"
  for line in "${lines[@]}"; do
    printf '│ %-*s │\n' "$width" "$line"
  done
  printf '└%s┘\n' "$(mv_rule '─' $(( width + 2 )))"
}

# Seconds → M:SS or H:MM:SS. A tenth is shown only when it is not zero.
mv_clock() {
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
mv_name_clock() {
  awk -v s="${1:-0}" 'BEGIN {
    t = int(s + 0.5)
    h = int(t / 3600)
    m = int((t % 3600) / 60)
    x = t % 60
    if (h > 0) printf "%dh%02dm%02ds", h, m, x
    else printf "%dm%02ds", m, x
  }'
}

mv_calc() {
  awk "BEGIN { printf \"%.3f\", $1 }"
}

mv_gt() {
  awk -v a="$1" -v b="$2" 'BEGIN { exit !(a + 0 > b + 0) }'
}

mv_now_ns() {
  date +%s.%N
}

mv_format_elapsed() {
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

mv_format_wall_clock() {
  date -d "@${1%.*}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null || date '+%Y.%m.%d %H:%M:%S'
}

# Downloading and rendering count as processing; everything else is waiting.
mv_proc_begin() {
  PROC_SLICE_START="$(mv_now_ns)"
}

mv_proc_end() {
  [[ -n "${PROC_SLICE_START:-}" ]] || return 0
  PROC_SEC="$(awk -v a="${PROC_SEC:-0}" -v t0="$PROC_SLICE_START" -v t1="$(mv_now_ns)" \
    'BEGIN { d = t1 - t0; if (d < 0) d = 0; printf "%.6f", a + d }')"
  PROC_SLICE_START=""
}

mv_summary_kv() {
  printf '  %-*s  %s\n' 18 "${1}:" "$2"
}

mv_file_bytes() {
  local n=0
  [[ -f "$1" ]] && n=$(stat -c %s -- "$1" 2>/dev/null || printf '0')
  [[ "$n" =~ ^[0-9]+$ ]] || n=0
  printf '%s\n' "$n"
}

mv_human_size() {
  awk -v b="${1:-0}" 'BEGIN {
    split("B KiB MiB GiB TiB", u, " ")
    i = 1
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    if (i == 1) printf "%d %s", b, u[i]
    else printf "%.1f %s", b, u[i]
  }'
}

# Rounded, marked approximate: ~812 MB | ~775 MiB | ~0.8 GB | ~0.8 GiB
mv_size_line() {
  awk -v b="${1:-0}" '
    function approx(x,    n) {
      n = (x >= 100) ? sprintf("%.0f", x) : sprintf("%.1f", x)
      sub(/\.0$/, "", n)
      return "~" n
    }
    BEGIN {
      printf "%s MB | %s MiB | %s GB | %s GiB", approx(b / 1e6), approx(b / 1048576), \
        approx(b / 1e9), approx(b / 1073741824)
    }'
}

# 90, 90s, 2m, 1:30, 1:02:03 → seconds.
mv_parse_time() {
  local v="${1,,}"
  if [[ "$v" =~ ^[0-9]+([.][0-9]+)?s?$ ]]; then
    printf '%s\n' "${v%s}"
  elif [[ "$v" =~ ^([0-9]+)m$ ]]; then
    printf '%s\n' $(( BASH_REMATCH[1] * 60 ))
  elif [[ "$v" =~ ^([0-9]+):([0-9]{1,2}([.][0-9]+)?)$ ]]; then
    mv_calc "${BASH_REMATCH[1]} * 60 + ${BASH_REMATCH[2]}"
  elif [[ "$v" =~ ^([0-9]+):([0-9]{1,2}):([0-9]{1,2}([.][0-9]+)?)$ ]]; then
    mv_calc "${BASH_REMATCH[1]} * 3600 + ${BASH_REMATCH[2]} * 60 + ${BASH_REMATCH[3]}"
  else
    return 1
  fi
}

# P:\video\trip → /mnt/p/video/trip when that mount exists.
mv_unix_path() {
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

# 1080x1080, 1280x720, 720 → MAP_W MAP_H (even, 160 to 4000).
mv_set_size() {
  local v="${1,,}" w h
  v="${v// /}"
  if [[ "$v" =~ ^([0-9]+)x([0-9]+)$ ]]; then
    w=$(( 10#${BASH_REMATCH[1]} )) h=$(( 10#${BASH_REMATCH[2]} ))
  elif [[ "$v" =~ ^([0-9]+)$ ]]; then
    w=$(( 10#${BASH_REMATCH[1]} )) h=$w
  else
    return 1
  fi
  (( w >= 160 && w <= 4000 && h >= 160 && h <= 4000 )) || return 1
  MAP_W=$(( w / 2 * 2 )) MAP_H=$(( h / 2 * 2 ))
}

mv_zoom_ok() {
  [[ "$1" =~ ^[0-9]+$ ]] && (( 10#$1 >= 12 && 10#$1 <= 18 ))
}

# --- files ------------------------------------------------------------------

mv_epoch() {
  local d="$1" t="$2"
  date -d "${d:0:4}-${d:4:2}-${d:6:2} ${t:0:2}:${t:2:2}:${t:4:2}" +%s 2>/dev/null
}

# Sets N_START, N_END (epoch, empty when the name has no clock), N_SPEED,
# N_DAY, N_CLOCK_START, N_CLOCK_END.
mv_parse_name() {
  local base="${1##*/}" d1 t1 d2 t2
  N_START="" N_END="" N_SPEED=1 N_DAY="" N_CLOCK_START="" N_CLOCK_END=""
  if [[ "$base" =~ [-_][xX]([0-9]+)([-_.]) ]]; then
    N_SPEED=$(( 10#${BASH_REMATCH[1]} ))
    (( N_SPEED >= 1 )) || N_SPEED=1
  fi
  [[ "$base" =~ ^([0-9]{8})[-_]([0-9]{6})[-_]([0-9]{8})[-_]([0-9]{6}) ]] || return 1
  d1="${BASH_REMATCH[1]}" t1="${BASH_REMATCH[2]}" d2="${BASH_REMATCH[3]}" t2="${BASH_REMATCH[4]}"
  N_START="$(mv_epoch "$d1" "$t1")" || return 1
  N_END="$(mv_epoch "$d2" "$t2")" || return 1
  N_DAY="${d1:0:4}.${d1:4:2}.${d1:6:2}"
  N_CLOCK_START="${t1:0:2}:${t1:2:2}:${t1:4:2}"
  N_CLOCK_END="${t2:0:2}:${t2:2:2}:${t2:4:2}"
}

mv_is_output_name() {
  local base="${1##*/}"
  [[ "$base" =~ [-_](PiP|Map)([-_.]|$) || "$base" =~ [-_]BackCam([-_.]|$) || "$base" == *_old-* || "$base" == *.partial.* ]]
}

mv_find_gpx() {
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

mv_output_path() {
  local vid="$1" dir stem out
  dir="$(dirname -- "$vid")"
  stem="$(basename -- "$vid")"
  stem="${stem%.*}"
  if [[ "$stem" =~ [-_]FrontCam ]]; then
    out="${stem/FrontCam/Map}"
  else
    out="${stem}-Map"
  fi
  if (( TEST )); then
    out+="-test-from-$(mv_name_clock "$FROM")"
    [[ -n "$LENGTH" ]] && out+="-len-$(mv_name_clock "$LENGTH")"
  fi
  printf '%s/%s.mp4\n' "$dir" "$out"
}

mv_add_video() {
  local f="$1" explicit="${2:-0}" i
  for i in "${!J_VID[@]}"; do
    [[ "${J_VID[$i]}" == "$f" ]] && return 0
  done
  if mv_is_output_name "$f"; then
    (( explicit )) && echo "$(mv_ts) ${C_Y}A BackCam, PiP, Map, or old file, ignored:${C_0} ${f}" >&2
    return 0
  fi
  mv_parse_name "$f" || true
  if [[ -z "$N_START" && -z "$START_OVERRIDE" ]]; then
    (( explicit )) && echo "$(mv_ts) ${C_Y}No start clock in the name (use --start), ignored:${C_0} ${f}" >&2
    return 0
  fi
  J_VID+=("$f")
  J_START+=("${START_OVERRIDE:-$N_START}")
  J_NAME_END+=("${N_END}")
  J_SPEED+=("${SPEED_OVERRIDE:-$N_SPEED}")
  J_DAY+=("${N_DAY:-$(date -d "@${START_OVERRIDE:-0}" '+%Y.%m.%d')}")
  J_CLOCK+=("${N_CLOCK_START:+${N_CLOCK_START} - ${N_CLOCK_END}}")
}

mv_add_directory() {
  local dir="${1%/}" f
  local -a found=()
  [[ -n "$dir" ]] || dir="/"
  shopt -s nullglob nocaseglob
  found=( "$dir"/*FrontCam*.mp4 )
  shopt -u nullglob nocaseglob
  (( ${#found[@]} == 0 )) && return 0
  mapfile -t found < <(printf '%s\n' "${found[@]}" | LC_ALL=C sort)
  for f in "${found[@]}"; do
    [[ -n "$f" ]] && mv_add_video "$f" 0
  done
}

# Sets PR_DUR, PR_FPS.
mv_probe() {
  local k v
  PR_DUR="" PR_FPS=""
  while IFS='=' read -r k v; do
    v="${v//$'\r'/}"
    case "$k" in
      r_frame_rate) [[ -z "$PR_FPS" && "$v" =~ ^[0-9]+/[0-9]+$ && "$v" != 0/0 ]] && PR_FPS="$v" ;;
      duration) [[ "$v" =~ ^[0-9]+([.][0-9]+)?$ ]] && PR_DUR="$v" ;;
    esac
  done < <(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate:format=duration \
             -of default=nw=1 -- "$1" 2>/dev/null || true)
  return 0
}

mv_fps_label() {
  awk -v f="$1" 'BEGIN {
    n = split(f, a, "/")
    v = (n == 2 && a[2] > 0) ? a[1] / a[2] : f + 0
    if (v == int(v)) printf "%d", v
    else printf "%.3f", v
  }'
}

mv_job_fps() {
  if [[ "$FPS" == same ]]; then
    printf '%s\n' "${J_FPS[$1]:-25/1}"
  else
    printf '%s\n' "$FPS"
  fi
}

# --- python helper ----------------------------------------------------------

mv_py_args() {
  local i="$1"
  PY_ARGS=(--gpx "${J_GPX[$i]}" --start-epoch "${J_START[$i]}" --speed "${J_SPEED[$i]}"
           --duration "${J_DUR[$i]}" --width "$MAP_W" --height "$MAP_H" --zoom "$ZOOM"
           --cache "$CACHE_DIR" --tile-url "$TILE_URL" --attribution "$ATTRIBUTION")
  mv_gt "$FROM" 0 && PY_ARGS+=(--from "$FROM")
  [[ -n "$LENGTH" ]] && PY_ARGS+=(--length "$LENGTH")
  [[ -n "$TZ_SHIFT" ]] && PY_ARGS+=(--tz-shift "$TZ_SHIFT")
  (( SHOW_SPEED )) && PY_ARGS+=(--show-speed)
  (( SHOW_CLOCK )) || PY_ARGS+=(--no-clock)
  (( TRACK_UP )) && PY_ARGS+=(--track-up)
  if (( SMOOTH )); then
    PY_ARGS+=(--smooth "$SMOOTH_LINE" --smooth-map "$SMOOTH_MAP" --max-jump "$MAX_JUMP")
    (( CURVE )) || PY_ARGS+=(--no-curve)
  else
    PY_ARGS+=(--no-smooth)
  fi
  return 0
}

# Fills J_POINTS ... J_LAT for one job from "python info".
mv_job_info() {
  local i="$1" k v out
  J_POINTS[$i]="" J_SHIFT[$i]=0 J_FIRST[$i]="" J_LAST[$i]="" J_OVERLAP[$i]=0
  J_DIST[$i]="" J_VMAX[$i]="" J_TILES[$i]=0 J_CACHED[$i]=0 J_LAT[$i]="" J_ERR[$i]="" J_DROPPED[$i]=0
  mv_py_args "$i"
  if ! out="$(python3 "$PY_HELPER" info "${PY_ARGS[@]}" 2>&1)"; then
    J_ERR[$i]="$(tail -1 <<<"$out")"
    return 1
  fi
  while IFS='=' read -r k v; do
    case "$k" in
      points) J_POINTS[$i]="$v" ;;
      dropped) J_DROPPED[$i]="$v" ;;
      tz_shift) J_SHIFT[$i]="$v" ;;
      first_fix) J_FIRST[$i]="$v" ;;
      last_fix) J_LAST[$i]="$v" ;;
      overlap) J_OVERLAP[$i]="$v" ;;
      distance_km) J_DIST[$i]="$v" ;;
      max_kmh) J_VMAX[$i]="$v" ;;
      tiles_needed) J_TILES[$i]="$v" ;;
      tiles_cached) J_CACHED[$i]="$v" ;;
      lat) J_LAT[$i]="$v" ;;
    esac
  done <<<"$out"
}

mv_read_all_info() {
  local i n=0
  for i in "${!J_VID[@]}"; do
    [[ -n "${J_GPX[$i]}" ]] && (( n++ )) || true
  done
  (( n == 0 )) && return 0
  printf '%s Reading %d GPS track(s) and working out the map tiles...' "$(mv_ts)" "$n"
  mv_proc_begin
  for i in "${!J_VID[@]}"; do
    [[ -n "${J_GPX[$i]}" ]] && { mv_job_info "$i" || true; }
  done
  mv_proc_end
  echo " done."
}

# --- encoders ---------------------------------------------------------------

mv_encoder_available() {
  grep -Eq "(^|[[:space:]])$1([[:space:]]|$)" <<<"${ENCODER_LIST:-}"
}

mv_encoder_candidates() {
  case "$ENCODER" in
    nvenc) mv_encoder_available hevc_nvenc && echo nvenc ;;
    x265)  mv_encoder_available libx265 && echo x265 ;;
    x264)  mv_encoder_available libx264 && echo x264 ;;
    *)
      mv_encoder_available hevc_nvenc && echo nvenc
      mv_encoder_available libx265 && echo x265
      if ! mv_encoder_available hevc_nvenc && ! mv_encoder_available libx265; then
        mv_encoder_available libx264 && echo x264
      fi
      ;;
  esac
  return 0
}

mv_set_encoder_args() {
  local q="$QUALITY"
  case "$1" in
    nvenc)
      [[ -n "$q" ]] || q=24
      ENC_ARGS=(-c:v hevc_nvenc -preset p5 -rc vbr -cq "$q" -b:v 0 -tag:v hvc1)
      ENC_LABEL="hevc_nvenc (GPU), cq ${q}"
      ;;
    x265)
      [[ -n "$q" ]] || q=24
      ENC_ARGS=(-c:v libx265 -preset medium -crf "$q" -tag:v hvc1)
      ENC_LABEL="libx265 (CPU), crf ${q}"
      ;;
    x264)
      [[ -n "$q" ]] || q=22
      ENC_ARGS=(-c:v libx264 -preset medium -crf "$q")
      ENC_LABEL="libx264 (CPU), crf ${q}"
      ;;
  esac
}

# --- old outputs ------------------------------------------------------------

mv_old_name() {
  local out="$1" stamp cand n=2
  stamp="$(date -r "$out" '+%Y%m%d_%H%M%S' 2>/dev/null || date '+%Y%m%d_%H%M%S')"
  cand="${out%.mp4}_old-${stamp}.mp4"
  while [[ -e "$cand" ]]; do
    cand="${out%.mp4}_old-${stamp}-${n}.mp4"
    (( n++ ))
  done
  printf '%s\n' "$cand"
}

mv_existing_info() {
  printf '%s, made %s' "$(mv_human_size "$(mv_file_bytes "$1")")" \
    "$(date -r "$1" '+%Y.%m.%d %H:%M' 2>/dev/null || echo '?')"
}

mv_retire_old() {
  local out="$1" old sz
  [[ -e "$out" ]] || return 0
  sz=$(mv_file_bytes "$out")
  if [[ "$OLD_MODE" == delete ]]; then
    rm -f -- "$out" || return 1
    OLD_DELETED+=("${out}|${sz}")
    echo "$(mv_ts) Old file deleted: ${out}"
  else
    old="$(mv_old_name "$out")"
    mv -- "$out" "$old" || return 1
    OLD_KEPT+=("${old}|${sz}")
    echo "$(mv_ts) Old file kept as: ${old}"
  fi
}

# --- plan -------------------------------------------------------------------

mv_print_existing() {
  local i n=0 out
  local -a found=()
  for i in "${!J_VID[@]}"; do
    (( n++ )) || true
    out="$(mv_output_path "${J_VID[$i]}")"
    [[ -e "$out" ]] && found+=("${n}|${out}")
  done
  (( ${#found[@]} == 0 )) && return 0
  mv_heading "Already rendered"
  printf '  %d of %d video(s) already have a map video:\n' "${#found[@]}" "$n"
  for i in "${found[@]}"; do
    printf '  Map %-2s %s\n' "${i%%|*}" "$(basename -- "${i#*|}")"
    printf '         %s\n' "$(mv_existing_info "${i#*|}")"
  done
  if (( REDO )); then
    echo "  --redo: they are rendered again; the old files are $([[ "$OLD_MODE" == delete ]] && echo deleted || echo kept as ..._old-YYYYMMDD_HHMMSS.mp4)."
  elif (( DO_YES || DRY_RUN )); then
    echo "  They are skipped; --redo renders them again."
  else
    echo "  Before anything is rendered you choose whether to skip them or render them again."
  fi
}

mv_window_label() {
  if (( ! TEST )); then
    printf 'whole videos'
  elif [[ -n "$LENGTH" ]]; then
    printf '%s, starting %s in' "$(mv_clock "$LENGTH")" "$(mv_clock "$FROM")"
  else
    printf 'from %s to the end' "$(mv_clock "$FROM")"
  fi
}

mv_across_label() {
  awk -v lat="${1:-52}" -v z="$ZOOM" -v w="$MAP_W" 'BEGIN {
    pi = atan2(0, -1)
    m = 156543.03392 * cos(lat * pi / 180) / (2 ^ z) * w
    if (m >= 1000) printf "about %.1f km across", m / 1000
    else printf "about %d m across", int(m / 10 + 0.5) * 10
  }'
}

mv_print_job() {
  local n="$1" total="$2" i="$3" out out_note shift_h len fps
  out="$(mv_output_path "${J_VID[$i]}")"
  J_OUT[$i]="$out"
  J_STATE[$i]=render
  mv_heading "Map ${n} of ${total}   ${J_DAY[$i]}  ${J_CLOCK[$i]:-from --start}   x${J_SPEED[$i]}"
  printf '  %sVideo%s   %s\n' "$C_B" "$C_0" "$(basename -- "${J_VID[$i]}")"
  fps="$(mv_job_fps "$i")"
  if [[ -n "${J_DUR[$i]}" ]]; then
    printf '          video length %s, %s fps\n' "$(mv_clock "${J_DUR[$i]}")" "$(mv_fps_label "${J_FPS[$i]:-25}")"
  else
    printf '          %scannot read its length%s\n' "$C_R" "$C_0"
    J_STATE[$i]=bad
  fi
  if [[ -n "${J_NAME_END[$i]}" && -n "${J_DUR[$i]}" ]]; then
    len="$(mv_calc "(${J_NAME_END[$i]} - ${J_START[$i]}) / ${J_SPEED[$i]}")"
    if mv_gt "$(awk -v a="$len" -v b="${J_DUR[$i]}" 'BEGIN { d = a - b; if (d < 0) d = -d; print d }')" \
        "$(mv_calc "${J_DUR[$i]} * 0.02 + 5")"; then
      printf '  %sNote%s  the name clock says %s of video, the file is %s; the map may drift\n' \
        "$C_Y" "$C_0" "$(mv_clock "$len")" "$(mv_clock "${J_DUR[$i]}")"
    fi
  fi
  if [[ -z "${J_GPX[$i]}" ]]; then
    printf '  %sTrack%s   %sno .gpx with the same name%s\n' "$C_B" "$C_0" "$C_R" "$C_0"
    J_STATE[$i]=bad
  elif [[ -n "${J_ERR[$i]}" || -z "${J_POINTS[$i]}" ]]; then
    printf '  %sTrack%s   %s\n' "$C_B" "$C_0" "$(basename -- "${J_GPX[$i]}")"
    printf '          %scannot be read: %s%s\n' "$C_R" "${J_ERR[$i]:-unknown error}" "$C_0"
    J_STATE[$i]=bad
  else
    printf '  %sTrack%s   %s\n' "$C_B" "$C_0" "$(basename -- "${J_GPX[$i]}")"
    printf '          %s points, %s km, top speed %s km/h' "${J_POINTS[$i]}" "${J_DIST[$i]}" "${J_VMAX[$i]}"
    if (( SMOOTH )); then
      (( J_DROPPED[$i] > 0 )) && printf '; %d jump(s) dropped' "${J_DROPPED[$i]}"
      printf ', smoothed'
    fi
    printf '\n'
    printf '          first fix at %s in the video, last at %s\n' "$(mv_clock "${J_FIRST[$i]}")" "$(mv_clock "${J_LAST[$i]}")"
    if [[ "${J_SHIFT[$i]}" != 0 ]]; then
      shift_h="$(awk -v s="${J_SHIFT[$i]}" 'BEGIN { printf "%+d", s / 3600 }')"
      printf '  %sNote%s  GPX times moved %s h to match the name clock (--tz-shift sets it)\n' "$C_Y" "$C_0" "$shift_h"
    fi
    if (( ! J_OVERLAP[$i] )); then
      printf '  %sCannot render%s  the track does not overlap this part of the video\n' "$C_R" "$C_0"
      J_STATE[$i]=bad
    fi
    printf '  %sTiles%s   %s needed, %s in the cache' "$C_B" "$C_0" "${J_TILES[$i]}" "${J_CACHED[$i]}"
    if (( J_TILES[$i] > J_CACHED[$i] )); then
      printf ', %s%d to download%s\n' "$C_Y" $(( J_TILES[$i] - J_CACHED[$i] )) "$C_0"
    else
      printf '\n'
    fi
  fi
  if (( TEST )) && [[ -n "${J_DUR[$i]}" ]]; then
    printf '  %sRender%s  part: %s - %s of %s\n' "$C_B" "$C_0" "$(mv_clock "$FROM")" \
      "$(mv_clock "$(awk -v f="$FROM" -v l="${LENGTH:-0}" -v d="${J_DUR[$i]}" 'BEGIN { e = (l > 0) ? f + l : d; if (e > d) e = d; print e }')")" \
      "$(mv_clock "${J_DUR[$i]}")"
  fi
  out_note="${C_G}new${C_0}"
  if [[ -e "$out" ]]; then
    (( EXISTING++ )) || true
    if (( REDO )); then
      out_note="${C_Y}exists ($(mv_existing_info "$out")), will be rendered again${C_0}"
    else
      out_note="${C_Y}exists ($(mv_existing_info "$out")), skipped unless you choose to render it again${C_0}"
      [[ "${J_STATE[$i]}" == render ]] && J_STATE[$i]=exists
    fi
  fi
  printf '  %sOutput%s  %s\n' "$C_B" "$C_0" "$(basename -- "$out")"
  printf '          %sx%s, %s fps, %s\n' "$MAP_W" "$MAP_H" "$(mv_fps_label "$fps")" "$out_note"
  if [[ -e "$out" ]] && (( REDO )); then
    if [[ "$OLD_MODE" == delete ]]; then
      printf '          %sthe old file is deleted once the new one is done%s\n' "$C_Y" "$C_0"
    else
      printf '          %sthe old file is kept as %s%s\n' "$C_Y" "$(basename -- "$(mv_old_name "$out")")" "$C_0"
    fi
  fi
}

mv_equivalent_command() {
  local -a cmd=("$(basename "$0")" -y)
  (( REDO )) && cmd+=(--redo)
  (( REDO )) && [[ "$OLD_MODE" == delete ]] && cmd+=(--old delete)
  [[ "${MAP_W}x${MAP_H}" != 1080x1080 ]] && cmd+=(--size "${MAP_W}x${MAP_H}")
  [[ "$ZOOM" != 17 ]] && cmd+=(--zoom "$ZOOM")
  (( TRACK_UP )) && cmd+=(--track-up)
  [[ "$FPS" != same ]] && cmd+=(--fps "$FPS")
  (( SHOW_SPEED )) && cmd+=(--show-speed)
  (( SHOW_CLOCK )) || cmd+=(--no-clock)
  if (( SMOOTH )); then
    [[ "$SMOOTH_LINE" != 4 ]] && cmd+=(--smooth "$SMOOTH_LINE")
    [[ "$SMOOTH_MAP" != 8 ]] && cmd+=(--smooth-map "$SMOOTH_MAP")
    [[ "$MAX_JUMP" != 250 ]] && cmd+=(--max-jump "$MAX_JUMP")
    (( CURVE )) || cmd+=(--no-curve)
  else
    cmd+=(--no-smooth)
  fi
  [[ -n "$GPX_OVERRIDE" ]] && cmd+=(--gpx "$GPX_OVERRIDE")
  [[ -n "$START_TEXT" ]] && cmd+=(--start "$START_TEXT")
  [[ -n "$SPEED_OVERRIDE" ]] && cmd+=(--speed "$SPEED_OVERRIDE")
  [[ -n "$TZ_SHIFT" ]] && cmd+=(--tz-shift "$TZ_SHIFT")
  [[ "$TILE_URL" != "$DEFAULT_TILE_URL" ]] && cmd+=(--tile-url "$TILE_URL")
  [[ "$ATTRIBUTION" != "$DEFAULT_ATTRIBUTION" ]] && cmd+=(--attribution "$ATTRIBUTION")
  (( CACHE_FROM_CLI )) && cmd+=(--cache "$CACHE_DIR")
  [[ "$ENCODER" != auto ]] && cmd+=(--encoder "$ENCODER")
  [[ -n "$QUALITY" ]] && cmd+=(--quality "$QUALITY")
  mv_gt "$FROM" 0 && cmd+=(--from "$(mv_clock "$FROM")")
  [[ -n "$LENGTH" ]] && cmd+=(--length "$(mv_clock "$LENGTH")")
  cmd+=(--)
  if (( ${#INPUT_ARGS[@]} > 0 )); then
    cmd+=("${INPUT_ARGS[@]}")
  else
    cmd+=("$(pwd -P)")
  fi
  mv_quote_args "${cmd[@]}"
}

mv_quote_args() {
  local a out="" q="'"
  for a in "$@"; do
    if [[ "$a" =~ ^[A-Za-z0-9_./:=,+@%-]+$ ]]; then
      out+="${out:+ }${a}"
    else
      out+="${out:+ }${q}${a//${q}/${q}\\${q}${q}}${q}"
    fi
  done
  printf '%s' "$out"
}

mv_print_plan() {
  local i n=0 total=${#J_VID[@]} lat=""
  EXISTING=0
  for i in "${!J_VID[@]}"; do
    (( n++ )) || true
    mv_print_job "$n" "$total" "$i"
    [[ -z "$lat" && -n "${J_LAT[$i]}" ]] && lat="${J_LAT[$i]}"
  done
  mv_heading "Settings"
  printf '  %-14s %s\n' "Map" "${MAP_W}x${MAP_H}, zoom ${ZOOM} ($(mv_across_label "$lat")), $(mv_orient_label), centred on the car"
  printf '  %-14s %s\n' "Shown" "$(mv_overlay_label)"
  printf '  %-14s %s\n' "GPS track" "$(mv_smooth_label)"
  if [[ "$FPS" == same ]]; then
    printf '  %-14s %s\n' "Frame rate" "same as each video"
  else
    printf '  %-14s %s\n' "Frame rate" "$(mv_fps_label "$FPS") fps"
  fi
  printf '  %-14s %s\n' "Tiles" "$TILE_URL"
  printf '  %-14s %s\n' "Tile cache" "$CACHE_DIR"
  printf '  %-14s %s\n' "Encoder" "$ENC_LABEL"
  printf '  %-14s %s\n' "Render" "$(mv_window_label)"
  printf '  %-14s %s\n' "Command" "$(mv_equivalent_command)"
  TO_RENDER=0 BAD=0 DOWNLOAD=0
  for i in "${!J_VID[@]}"; do
    case "${J_STATE[$i]}" in
      render)
        (( TO_RENDER++ )) || true
        DOWNLOAD=$(( DOWNLOAD + J_TILES[$i] - J_CACHED[$i] ))
        ;;
      bad) (( BAD++ )) || true ;;
    esac
  done
  echo
  printf '%s%d video(s), %d to render%s' "$C_B" "$total" "$TO_RENDER" "$C_0"
  if (( EXISTING > 0 && REDO )); then
    printf ', %d of them already rendered and done again' "$EXISTING"
  elif (( EXISTING > 0 )); then
    printf ', %d already rendered (skipped for now)' "$EXISTING"
  fi
  (( BAD > 0 )) && printf ', %s%d cannot be rendered%s' "$C_R" "$BAD" "$C_0"
  (( DOWNLOAD > 0 )) && printf ', up to %d tiles to download' "$DOWNLOAD"
  echo
}

mv_orient_label() {
  if (( TRACK_UP )); then
    printf 'track up (the map turns, compass top right)'
  else
    printf 'north up'
  fi
}

mv_smooth_label() {
  local out
  if (( ! SMOOTH )); then
    printf 'as recorded (no smoothing)'
    return 0
  fi
  out="smoothed: line ${SMOOTH_LINE} s, map ${SMOOTH_MAP} s, "
  if [[ "$MAX_JUMP" == 0 ]]; then
    out+="no jump filter, "
  else
    out+="jumps over ${MAX_JUMP} km/h dropped, "
  fi
  if (( CURVE )); then
    out+="curved"
  else
    out+="straight between points"
  fi
  printf '%s' "$out"
}

mv_overlay_label() {
  local out="driven road red, road ahead purple, arrow for the car"
  (( SHOW_SPEED )) && out+=", speed"
  (( SHOW_CLOCK )) && out+=", clock"
  printf '%s' "$out"
}

# --- prompts ----------------------------------------------------------------

mv_read_key() {
  local prompt="$1" default_key="${2:-}" answer="" discard
  printf '%s' "$prompt"
  while IFS= read -r -t 0.02 -n 1 discard; do :; done
  read -r -n 1 answer || answer=""
  echo
  answer="${answer,,}"
  REPLY="${answer:-$default_key}"
}

mv_read_line() {
  local prompt="$1" default="$2" answer=""
  printf '%s' "$prompt"
  IFS= read -r answer || answer=""
  REPLY="${answer:-$default}"
}

mv_quit() {
  echo "$(mv_ts) Quit. Nothing more was rendered."
  STOPPED=yes
  return_code=0
  exit 0
}

mv_ask_line() {
  local name="$1" cur="$2"
  echo "  [Enter] Keep the current answer: ${cur}"
  echo "  [q]     Quit the script, render nothing more"
  mv_read_line "${name} [${cur}] (q = quit): " "$cur"
  [[ "${REPLY,,}" == q ]] && mv_quit
  return 0
}

# The key, capital when it is the default: mv_k y y -> Y, mv_k n y -> n.
mv_k() {
  if [[ "$1" == "$2" ]]; then
    printf '%s' "${1^^}"
  else
    printf '%s' "$1"
  fi
}

# Keys for a prompt line with the default in capitals: mv_keys n y n q -> y/N/q.
mv_keys() {
  local def="$1" k out=""
  shift
  for k in "$@"; do
    out+="${out:+/}$(mv_k "$k" "$def")"
  done
  printf '%s' "$out"
}

mv_cur_mark() {
  [[ "$1" == "$2" ]] && printf ' (current, default)'
  return 0
}

mv_yes_no() {
  local question="$1" cur="$2" yes_text="$3" no_text="$4" def=n keys
  (( cur )) && def=y
  keys="$(mv_keys "$def" y n q)"
  printf '%s [%s]\n' "$question" "$keys"
  echo "  [$(mv_k y "$def")] Yes$(mv_cur_mark y "$def")"
  echo "      ${yes_text}"
  echo "  [$(mv_k n "$def")] No$(mv_cur_mark n "$def")"
  echo "      ${no_text}"
  echo "  [q] Quit the script, render nothing more"
  mv_read_key "${question%\?} [${keys}]: " "$def"
  case "$REPLY" in
    y) REPLY=1 ;;
    n) REPLY=0 ;;
    q) mv_quit ;;
    *) echo "$(mv_ts) Unknown choice. Keeping the current answer."; REPLY="$cur" ;;
  esac
}

mv_prompt_more() {
  local v
  mv_heading "Map choices"
  echo "  Enter keeps the answer in brackets. q quits."

  echo
  echo "Picture size: width x height in pixels"
  echo "  1080x1080   square, good beside a 4:3 dashcam picture (default)"
  echo "  720         720x720, smaller and faster"
  echo "  1280x720    wide; the map shows more to the left and right"
  mv_ask_line "Size" "${MAP_W}x${MAP_H}"
  mv_set_size "$REPLY" || echo "$(mv_ts) ${C_Y}Not a size: ${REPLY}. Keeping ${MAP_W}x${MAP_H}.${C_0}"

  echo
  echo "Map zoom: how close the map is"
  echo "  15   about 3 km across at 1080 px; motorways and long roads"
  echo "  16   about 1.6 km across; calmer on motorways at x5"
  echo "  17   about 800 m across; most driving, streets readable (default)"
  echo "  18   about 400 m across; towns and side streets"
  echo "  Any whole number from 12 to 18. More zoom needs more tiles."
  mv_ask_line "Zoom" "$ZOOM"
  if mv_zoom_ok "$REPLY"; then
    ZOOM=$(( 10#$REPLY ))
  else
    echo "$(mv_ts) ${C_Y}Not 12 to 18: ${REPLY}. Keeping ${ZOOM}.${C_0}"
  fi

  echo
  local ddef=n nkeys
  (( TRACK_UP )) && ddef=t
  nkeys="$(mv_keys "$ddef" n t q)"
  printf 'Map direction [%s]\n' "$nkeys"
  echo "  [$(mv_k n "$ddef")] North up$(mv_cur_mark n "$ddef")"
  echo "      North is always at the top, like a paper map; the arrow turns with the road."
  echo "  [$(mv_k t "$ddef")] Track up$(mv_cur_mark t "$ddef")"
  echo "      The map turns so the road ahead is always up and the arrow points up,"
  echo "      like a car navigation. A small compass in the top right shows north."
  echo "      Renders about 4 times slower (every frame is rotated): about real time."
  echo "  [q] Quit the script, render nothing more"
  mv_read_key "Map direction [${nkeys}]: " "$ddef"
  case "$REPLY" in
    n) TRACK_UP=0 ;;
    t) TRACK_UP=1 ;;
    q) mv_quit ;;
    *) echo "$(mv_ts) Unknown choice. Keeping $(mv_orient_label)." ;;
  esac

  echo
  mv_yes_no "Show the speed?" "$SHOW_SPEED" \
    "km/h in the top left corner, worked out from the GPS points." \
    "No speed on the map; the dashcam picture shows it already (default)."
  SHOW_SPEED="$REPLY"

  echo
  mv_yes_no "Show the clock?" "$SHOW_CLOCK" \
    "The local time of day in the top left corner, as it was when that moment was filmed." \
    "No clock on the picture."
  SHOW_CLOCK="$REPLY"

  echo
  echo "Frames per second"
  echo "  same   the same as each video, frame for frame (default)"
  echo "  10     a smaller number renders faster; a map moves slowly, so 10 still looks smooth"
  echo "  The length is the same either way."
  mv_ask_line "Frame rate" "$FPS"
  v="${REPLY,,}"
  if [[ "$v" == same ]]; then
    FPS=same
  elif [[ "$v" =~ ^[0-9]+([.][0-9]+)?$ ]] && mv_gt "$v" 0 && ! mv_gt "$v" 120; then
    FPS="$v"
  else
    echo "$(mv_ts) ${C_Y}Not same or a number up to 120: ${REPLY}. Keeping ${FPS}.${C_0}"
  fi
}

mv_seconds_ok() {
  [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]] && ! mv_gt "$1" 60
}

mv_prompt_smooth() {
  mv_heading "GPS track"
  mv_yes_no "Smooth the GPS track?" "$SMOOTH" \
    "Bad points that would mean an impossible jump are dropped, the small zigzags
      of the GPS are averaged out over a few seconds of driving, and the arrow
      moves along a curve between points instead of jerking from point to point.
      The .gpx file is not changed; only the map video uses the smoothed track." \
    "Use the GPS points exactly as recorded, joined by straight lines."
  SMOOTH="$REPLY"
  (( SMOOTH )) || return 0

  echo
  printf 'Tweak the smoothing? [y/N/q]\n'
  echo "  [y] Yes"
  echo "      Set how strong the smoothing is, one value at a time."
  echo "  [N] No (current, default)"
  echo "      Keep: $(mv_smooth_label | sed 's/^smoothed: //')."
  echo "  [q] Quit the script, render nothing more"
  mv_read_key "Tweak the smoothing [y/N/q]: " n
  case "$REPLY" in
    y) ;;
    q) mv_quit ;;
    n) return 0 ;;
    *) echo "$(mv_ts) Unknown choice. Keeping the smoothing as it is."; return 0 ;;
  esac

  echo
  echo "Track line smoothing: how many seconds of driving each point is averaged over"
  echo "  0    off, the line goes through every GPS point"
  echo "  2    light; removes only the small zigzag"
  echo "  4    medium; straight roads look straight, corners stay on the road (default)"
  echo "  8    strong; very calm line, but tight corners and roundabouts get cut"
  mv_ask_line "Line smoothing" "$SMOOTH_LINE"
  if mv_seconds_ok "$REPLY"; then
    SMOOTH_LINE="$REPLY"
  else
    echo "$(mv_ts) ${C_Y}Not 0 to 60 seconds: ${REPLY}. Keeping ${SMOOTH_LINE}.${C_0}"
  fi

  echo
  echo "Map movement smoothing: how calmly the map follows the car, in seconds"
  echo "  The map centre and the arrow direction follow a calmer path than the line,"
  echo "  so the picture does not shake. It is at least the line smoothing."
  echo "  4    follows the car closely"
  echo "  8    calm (default)"
  echo "  15   very calm; the car moves a little away from the centre in turns"
  mv_ask_line "Map smoothing" "$SMOOTH_MAP"
  if mv_seconds_ok "$REPLY"; then
    SMOOTH_MAP="$REPLY"
  else
    echo "$(mv_ts) ${C_Y}Not 0 to 60 seconds: ${REPLY}. Keeping ${SMOOTH_MAP}.${C_0}"
  fi
  if mv_gt "$SMOOTH_LINE" "$SMOOTH_MAP"; then
    echo "$(mv_ts) The map smoothing is raised to the line smoothing: ${SMOOTH_LINE}."
    SMOOTH_MAP="$SMOOTH_LINE"
  fi

  echo
  echo "Drop jumps faster than: km/h"
  echo "  A point that would mean driving faster than this from its neighbours is a"
  echo "  GPS error and is left out. 0 keeps every point."
  echo "  250  (default)"
  mv_ask_line "Drop jumps over" "$MAX_JUMP"
  if [[ "$REPLY" =~ ^[0-9]+$ ]] && (( 10#$REPLY == 0 || (10#$REPLY >= 50 && 10#$REPLY <= 2000) )); then
    MAX_JUMP=$(( 10#$REPLY ))
  else
    echo "$(mv_ts) ${C_Y}Not 0 or 50 to 2000 km/h: ${REPLY}. Keeping ${MAX_JUMP}.${C_0}"
  fi

  echo
  mv_yes_no "Curved movement between points?" "$CURVE" \
    "The arrow and the map glide along a curve through the points." \
    "Straight lines from point to point, as before."
  CURVE="$REPLY"
}

mv_prompt_test() {
  local v key len_txt
  if [[ -z "$LENGTH" ]] && (( ! TEST )); then
    key=a
  elif [[ -z "$LENGTH" ]]; then
    key=c
  else
    case "$(mv_calc "$LENGTH")" in
      60.000) key=1 ;; 120.000) key=2 ;; 300.000) key=5 ;; *) key=c ;;
    esac
  fi
  echo
  echo "How much of each video should get its map? [$(mv_keys "$key" a 1 2 5 c q)]"
  echo "  A part is saved under its own -test-… name, so a full map video is kept."
  echo "  [$(mv_k a "$key")] All of it, start to end$(mv_cur_mark a "$key")"
  echo "  [1] 1 minute$(mv_cur_mark 1 "$key")"
  echo "  [2] 2 minutes$(mv_cur_mark 2 "$key")"
  echo "  [5] 5 minutes$(mv_cur_mark 5 "$key")"
  echo "  [$(mv_k c "$key")] Custom length, typed next$(mv_cur_mark c "$key")"
  echo "  [q] Quit the script, render nothing more"
  mv_read_key "Length [$(mv_keys "$key" a 1 2 5 c q)]: " "$key"
  case "$REPLY" in
    a) LENGTH="" FROM=0; mv_update_test; return 0 ;;
    1) LENGTH=60 ;;
    2) LENGTH=120 ;;
    5) LENGTH=300 ;;
    c)
      echo
      echo "Custom length"
      echo "  Time in the sped-up video, as M:SS (4:40), H:MM:SS, or seconds (280)."
      len_txt="$(mv_clock "${LENGTH:-60}")"
      mv_ask_line "Length" "$len_txt"
      if v="$(mv_parse_time "$REPLY")" && mv_gt "$v" 0; then
        LENGTH="$v"
      else
        echo "$(mv_ts) ${C_Y}Not a time above 0: ${REPLY}. Using ${len_txt}.${C_0}"
        LENGTH="$(mv_parse_time "$len_txt")"
      fi
      ;;
    q) mv_quit ;;
    *) echo "$(mv_ts) Unknown choice: ${REPLY}. Using 1 minute."; LENGTH=60 ;;
  esac
  echo
  echo "Where should it start?"
  echo "  How far into each video, as M:SS (4:40), H:MM:SS, or seconds (280). 0:00 is the start."
  mv_ask_line "Start at" "$(mv_clock "$FROM")"
  if v="$(mv_parse_time "$REPLY")"; then
    FROM="$v"
  else
    echo "$(mv_ts) ${C_Y}Not a time: ${REPLY}. Keeping $(mv_clock "$FROM").${C_0}"
  fi
  mv_update_test
}

mv_update_test() {
  TEST=0
  if mv_gt "$FROM" 0 || [[ -n "$LENGTH" ]]; then
    TEST=1
  fi
}

mv_prompt_old() {
  local key=k
  (( OLD_ASKED )) && return 0
  OLD_ASKED=1
  [[ "$OLD_MODE" == delete ]] && key=d
  echo
  echo "What should happen to the old map video when the new one is done? [$(mv_keys "$key" k d q)]"
  echo "  The new video is written to a .partial file first; the old file is"
  echo "  only touched after the new one has finished without errors."
  echo "  [$(mv_k k "$key")] Keep it, renamed with the date and time it was made$(mv_cur_mark k "$key")"
  echo "      For example ..._old-20261005_221400.mp4 beside the new file."
  echo "  [$(mv_k d "$key")] Delete it$(mv_cur_mark d "$key")"
  echo "  [q] Quit the script, render nothing more"
  mv_read_key "Old file [$(mv_keys "$key" k d q)]: " "$key"
  case "$REPLY" in
    k) OLD_MODE=keep ;;
    d) OLD_MODE=delete ;;
    q) mv_quit ;;
    *) echo "$(mv_ts) Unknown choice: ${REPLY}. Keeping old files."; OLD_MODE=keep ;;
  esac
}

mv_prompt_existing() {
  local i skip=0
  for i in "${!J_VID[@]}"; do
    [[ "${J_STATE[$i]}" == exists ]] && (( skip++ )) || true
  done
  (( skip == 0 )) && return 0
  echo
  printf '%s%d video(s) already have a map video. What should happen to them? [S/r/q]%s\n' "$C_B" "$skip" "$C_0"
  echo "  [S] Skip them, keep the old files as they are (default)"
  if (( TO_RENDER > 0 )); then
    echo "      Only the ${TO_RENDER} new map video(s) are rendered."
  else
    echo "      Nothing is rendered."
  fi
  echo "  [r] Render them again too"
  echo "      What happens to each old file is asked next."
  echo "  [q] Quit the script, render nothing"
  mv_read_key "Already rendered [S/r/q]: " s
  case "$REPLY" in
    s) ;;
    r) REDO=1; mv_prompt_old ;;
    q) mv_quit ;;
    *) echo "$(mv_ts) Unknown choice: ${REPLY}. Skipping them." ;;
  esac
}

mv_prompt_plan() {
  while true; do
    echo
    printf '%sRender now? [Y/m/t/q]%s\n' "$C_B" "$C_0"
    if (( TO_RENDER == 0 && EXISTING > 0 && ! REDO )); then
      echo "  [Y] Go on (default): there are no new map videos"
    else
      echo "  [Y] Download the missing tiles and render the ${TO_RENDER} map video(s) marked above (default)"
    fi
    if (( EXISTING > 0 && ! REDO )); then
      echo "      Then you are asked what to do with the ${EXISTING} already rendered."
    else
      echo "      One after another, without asking again."
    fi
    echo "  [m] Change the map"
    echo "      Picture size, zoom, north up or track up, speed, clock, frame rate. The plan is printed again."
    echo "  [t] Render only part of each video (for a test)"
    echo "      Pick how long and where it starts. Now: $(mv_window_label)."
    echo "  [q] Quit the script, render nothing"
    mv_read_key "Render now? [Y/m/t/q]: " y
    case "$REPLY" in
      y)
        if (( REDO )); then
          (( EXISTING > 0 )) && mv_prompt_old
        else
          mv_prompt_existing
        fi
        return 0 ;;
      m) mv_prompt_more; mv_read_all_info; mv_print_plan ;;
      t) mv_prompt_test; mv_read_all_info; mv_print_plan ;;
      n|q) mv_quit ;;
      *) echo "$(mv_ts) Unknown choice: ${REPLY}." ;;
    esac
  done
}

# --- render -----------------------------------------------------------------

mv_fetch_tiles() {
  local i k v out need=0 n=0
  for i in "${!J_VID[@]}"; do
    [[ "${J_STATE[$i]}" == render ]] || continue
    (( J_TILES[$i] > J_CACHED[$i] )) && (( need++ )) || true
  done
  (( need == 0 )) && return 0
  mv_heading "Map tiles"
  echo "$(mv_ts) Downloading into ${CACHE_DIR}"
  mv_proc_begin
  for i in "${!J_VID[@]}"; do
    [[ "${J_STATE[$i]}" == render ]] || continue
    (( J_TILES[$i] > J_CACHED[$i] )) || continue
    (( n++ )) || true
    echo "$(mv_ts) $(basename -- "${J_GPX[$i]}")"
    mv_py_args "$i"
    out="$(python3 "$PY_HELPER" fetch "${PY_ARGS[@]}")" || true
    while IFS='=' read -r k v; do
      case "$k" in
        downloaded) TILES_DOWNLOADED=$(( TILES_DOWNLOADED + v )) ;;
        failed)
          TILES_FAILED=$(( TILES_FAILED + v ))
          (( v > 0 )) && echo "$(mv_ts) ${C_Y}${v} tile(s) could not be downloaded; they show as grey squares.${C_0}"
          ;;
      esac
    done <<<"$out"
  done
  mv_proc_end
}

mv_cleanup_partial() {
  if [[ -n "${PARTIAL:-}" && -e "$PARTIAL" ]]; then
    rm -f -- "$PARTIAL"
    echo "$(mv_ts) Removed incomplete output: ${PARTIAL}"
  fi
  PARTIAL=""
}

mv_render_job() {
  local n="$1" total="$2" i="$3" out label kind rc tries=0 t0 fps
  local -a kinds=()
  out="${J_OUT[$i]}"
  label=""
  (( total > 1 )) && label="${n}/${total}"
  fps="$(mv_job_fps "$i")"
  mv_heading "Rendering ${label:+${label}  }$(basename -- "$out")"
  mapfile -t kinds < <(mv_encoder_candidates)
  mv_py_args "$i"
  mv_proc_begin
  t0="$(mv_now_ns)"
  for kind in "${kinds[@]}"; do
    (( tries++ )) || true
    mv_set_encoder_args "$kind"
    PARTIAL="${out%.mp4}.partial.$$.mp4"
    echo "$(mv_ts) Encoder: ${ENC_LABEL}"
    rc=0
    python3 "$PY_HELPER" render "${PY_ARGS[@]}" --fps "$fps" --out "$PARTIAL" --label "$label" \
      -- "${ENC_ARGS[@]}" || rc=$?
    if (( rc == 130 )); then
      mv_proc_end
      STOPPED=yes
      return 130
    fi
    if (( rc == 0 )) && [[ -s "$PARTIAL" ]] && ! mv_retire_old "$out"; then
      echo "$(mv_ts) ${C_R}Could not move the old file aside. The new video is left as ${PARTIAL}${C_0}" >&2
      FAILED_LIST+=("${out} (old file not moved; new video is ${PARTIAL})")
      PARTIAL=""
      mv_proc_end
      return 1
    fi
    if (( rc == 0 )) && [[ -s "$PARTIAL" ]] && mv -f -- "$PARTIAL" "$out"; then
      PARTIAL=""
      mv_proc_end
      echo "$(mv_ts) ${C_G}Done${C_0} in $(mv_format_elapsed "$(mv_calc "$(mv_now_ns) - $t0")"): ${out}"
      DONE_LIST+=("$out")
      DONE_SEC+=("$(mv_calc "$(mv_now_ns) - $t0")")
      DONE_VID+=("$(awk -v f="$FROM" -v l="${LENGTH:-0}" -v d="${J_DUR[$i]}" 'BEGIN { e = (l > 0) ? f + l : d; if (e > d) e = d; printf "%.3f", e - f }')")
      DONE_ENC+=("$ENC_LABEL")
      DONE_OUT_B+=("$(mv_file_bytes "$out")")
      return 0
    fi
    mv_cleanup_partial
    if (( rc == 2 )); then
      echo "$(mv_ts) ${C_R}The track could not be drawn.${C_0}" >&2
      break
    fi
    echo "$(mv_ts) ${C_R}ffmpeg failed with ${ENC_LABEL}.${C_0}" >&2
  done
  mv_proc_end
  (( tries == 0 )) && echo "$(mv_ts) ${C_R}No usable encoder for '${ENCODER}'.${C_0}" >&2
  FAILED_LIST+=("$out")
  return 1
}

# --- summary ----------------------------------------------------------------

mv_print_summary() {
  local item i end_ns total_sec wait_sec vid_sum=0 enc_sum=0 out_sum=0
  mv_proc_end
  end_ns="$(mv_now_ns)"
  mv_heading "Summary"
  mv_summary_kv "Rendered" "${#DONE_LIST[@]} map video(s)"
  for i in "${!DONE_LIST[@]}"; do
    printf '    %s\n' "${DONE_LIST[$i]}"
    printf '      %s%s video in %s, %sx real time, %s, %s%s\n' "$C_DIM" \
      "$(mv_clock "${DONE_VID[$i]}")" "$(mv_format_elapsed "${DONE_SEC[$i]}")" \
      "$(awk -v v="${DONE_VID[$i]}" -v s="${DONE_SEC[$i]}" 'BEGIN { printf "%.2f", (s > 0 ? v / s : 0) }')" \
      "${DONE_ENC[$i]}" "$(mv_human_size "${DONE_OUT_B[$i]}")" "$C_0"
    vid_sum="$(mv_calc "$vid_sum + ${DONE_VID[$i]}")"
    enc_sum="$(mv_calc "$enc_sum + ${DONE_SEC[$i]}")"
    out_sum=$(( out_sum + DONE_OUT_B[i] ))
  done
  if (( ${#SKIPPED_LIST[@]} > 0 )); then
    mv_summary_kv "Skipped" "${#SKIPPED_LIST[@]}"
    for item in "${SKIPPED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  if (( ${#FAILED_LIST[@]} > 0 )); then
    printf '%s' "$C_R"
    mv_summary_kv "Failed" "${#FAILED_LIST[@]}"
    printf '%s' "$C_0"
    for item in "${FAILED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  if (( ${#OLD_KEPT[@]} > 0 )); then
    mv_summary_kv "Old files kept" "${#OLD_KEPT[@]} (renamed with the date and time they were made)"
    for item in "${OLD_KEPT[@]}"; do
      printf '    %s  %s(%s)%s\n' "${item%|*}" "$C_DIM" "$(mv_human_size "${item##*|}")" "$C_0"
    done
  fi
  if (( ${#OLD_DELETED[@]} > 0 )); then
    mv_summary_kv "Old files deleted" "${#OLD_DELETED[@]}"
    for item in "${OLD_DELETED[@]}"; do
      printf '    %s  %s(%s)%s\n' "${item%|*}" "$C_DIM" "$(mv_human_size "${item##*|}")" "$C_0"
    done
  fi
  if (( TILES_DOWNLOADED > 0 || TILES_FAILED > 0 )); then
    mv_summary_kv "Tiles downloaded" "${TILES_DOWNLOADED}$( (( TILES_FAILED > 0 )) && printf ', %d failed' "$TILES_FAILED")"
  fi
  if (( ${#DONE_LIST[@]} > 0 )); then
    mv_summary_kv "Video written" "$(mv_clock "$vid_sum")"
    mv_summary_kv "Render time" "$(mv_format_elapsed "$enc_sum")  ($(awk -v v="$vid_sum" -v s="$enc_sum" \
      'BEGIN { printf "%.2f", (s > 0 ? v / s : 0) }')x real time on average)"
    mv_summary_kv "Output size" "$(mv_size_line "$out_sum")"
  fi
  mv_heading "Timing"
  total_sec="$(awk -v s0="$SCRIPT_START_NS" -v s1="$end_ns" 'BEGIN { printf "%.6f", s1 - s0 }')"
  wait_sec="$(awk -v t="$total_sec" -v p="${PROC_SEC:-0}" 'BEGIN { w = t - p; if (w < 0) w = 0; printf "%.6f", w }')"
  mv_summary_kv "Started" "$(mv_format_wall_clock "$SCRIPT_START_NS")"
  mv_summary_kv "Finished" "$(date '+%Y.%m.%d %H:%M:%S')"
  mv_summary_kv "Total wall time" "$(mv_format_elapsed "$total_sec")"
  mv_summary_kv "Processing time" "$(mv_format_elapsed "${PROC_SEC:-0}")  (tracks, tiles, rendering)"
  mv_summary_kv "Other/wait time" "$(mv_format_elapsed "$wait_sec")  (prompts, startup, overhead)"
  [[ "$STOPPED" == yes ]] && mv_summary_kv "Stopped by user" "yes"
  echo
}

mv_on_exit() {
  mv_cleanup_partial
  if (( SUMMARY )) && (( ! SUMMARY_DONE )); then
    SUMMARY_DONE=1
    mv_print_summary
  fi
  if [[ -r /root/bin/_script_footer.sh ]]; then
    # shellcheck disable=SC1091
    . /root/bin/_script_footer.sh
  fi
}

mv_ctrl_c() {
  STOPPED=yes
  echo
  echo "$(mv_ts) Interrupted."
  return_code=130
  exit 130
}

# --- main -------------------------------------------------------------------

SCRIPT_START_NS=$(date +%s.%N)
PROC_SEC=0
PROC_SLICE_START=""
DONE_SEC=() DONE_VID=() DONE_ENC=() DONE_OUT_B=()
OLD_KEPT=() OLD_DELETED=()
# shellcheck disable=SC1091
. /root/bin/_script_header.sh

DEFAULT_TILE_URL="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
DEFAULT_ATTRIBUTION="© OpenStreetMap contributors"
DO_YES=0
DRY_RUN=0
REDO=0
OLD_MODE=keep OLD_ASKED=0
MAP_W=1080 MAP_H=1080
ZOOM=17
TRACK_UP=0
FPS=same
SHOW_SPEED=0 SHOW_CLOCK=1
SMOOTH=1 SMOOTH_LINE=4 SMOOTH_MAP=8 MAX_JUMP=250 CURVE=1 SMOOTH_FROM_CLI=0
GPX_OVERRIDE="" START_OVERRIDE="" START_TEXT="" SPEED_OVERRIDE="" TZ_SHIFT=""
TILE_URL="$DEFAULT_TILE_URL"
ATTRIBUTION="$DEFAULT_ATTRIBUTION"
CACHE_DIR="" CACHE_FROM_CLI=0
ENCODER=auto
QUALITY=""
FROM=0
LENGTH=""
TEST=0
INPUT_ARGS=()
J_VID=() J_START=() J_NAME_END=() J_SPEED=() J_DAY=() J_CLOCK=() J_GPX=() J_DUR=() J_FPS=()
J_OUT=() J_STATE=() J_POINTS=() J_SHIFT=() J_FIRST=() J_LAST=() J_OVERLAP=() J_DIST=() J_VMAX=()
J_TILES=() J_CACHED=() J_LAT=() J_ERR=() J_DROPPED=()
PY_ARGS=() ENC_ARGS=()
ENC_LABEL="" ENCODER_LIST="" PARTIAL="" EXISTING=0 TO_RENDER=0 BAD=0 DOWNLOAD=0
TILES_DOWNLOADED=0 TILES_FAILED=0
DONE_LIST=() SKIPPED_LIST=() FAILED_LIST=()
SUMMARY=0 SUMMARY_DONE=0 STOPPED=no
PY_HELPER="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/video-pgm-create-map-video-from-gpx.py"
mv_colors

trap mv_on_exit EXIT
trap mv_ctrl_c INT

# Missing programs as "package|what it is for" lines.
mv_missing_prereqs() {
  if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
    echo "ffmpeg|ffmpeg and ffprobe: read the videos and encode the map video"
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3|Python 3: runs the drawing helper"
    echo "python3-pil|Pillow (Python imaging library): draws the map frames"
  elif ! python3 -c 'import PIL' 2>/dev/null; then
    echo "python3-pil|Pillow (Python imaging library): draws the map frames"
  fi
  return 0
}

mv_check_prereqs() {
  local line rc=0
  local -a missing=() pkgs=() cmd=()
  mapfile -t missing < <(mv_missing_prereqs)
  (( ${#missing[@]} == 0 )) && return 0
  for line in "${missing[@]}"; do
    pkgs+=("${line%%|*}")
  done
  cmd=(apt-get install -y "${pkgs[@]}")
  if (( EUID != 0 )); then
    cmd=(sudo "${cmd[@]}")
  fi
  mv_heading "Missing programs"
  echo "  This script needs these, and they are not installed:"
  for line in "${missing[@]}"; do
    printf '  %-12s %s\n' "${line%%|*}" "${line#*|}"
  done
  if [[ " ${pkgs[*]} " == *" ffmpeg "* ]]; then
    echo "  (ffmpeg-install.sh in this repository builds a newer ffmpeg instead of the Ubuntu one.)"
  fi
  echo "  Install command: $(mv_quote_args "${cmd[@]}")"
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "$(mv_ts) ${C_R}apt-get is not available here; install them with this system's package manager.${C_0}" >&2
    exit 1
  fi
  if (( EUID != 0 )) && ! command -v sudo >/dev/null 2>&1; then
    echo "$(mv_ts) ${C_R}Not root and no sudo: run the install command as root, then start this script again.${C_0}" >&2
    exit 1
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    echo "$(mv_ts) ${C_Y}Nothing is installed without asking. Run the install command, or start this script in a terminal without -y.${C_0}" >&2
    exit 1
  fi
  echo
  printf '%sInstall them now? [Y/n/q]%s\n' "$C_B" "$C_0"
  echo "  [Y] Yes, install with the command above, then continue (default)"
  echo "      If that fails, the package lists are refreshed (apt-get update) and it tries once more."
  echo "  [n] No, stop here; install them yourself and start this script again"
  echo "  [q] Quit the script"
  mv_read_key "Install them now? [Y/n/q]: " y
  case "$REPLY" in
    y) ;;
    *) echo "$(mv_ts) Nothing installed."; exit 1 ;;
  esac
  echo "$(mv_ts) $(mv_quote_args "${cmd[@]}")"
  "${cmd[@]}" || rc=$?
  if (( rc != 0 )); then
    echo "$(mv_ts) Install failed; refreshing the package lists and trying again."
    if (( EUID != 0 )); then
      sudo apt-get update || true
    else
      apt-get update || true
    fi
    rc=0
    "${cmd[@]}" || rc=$?
  fi
  mapfile -t missing < <(mv_missing_prereqs)
  if (( rc != 0 || ${#missing[@]} > 0 )); then
    echo "$(mv_ts) ${C_R}Still missing after the install:${C_0}" >&2
    for line in "${missing[@]}"; do
      printf '  %s\n' "${line%%|*}" >&2
    done
    exit 1
  fi
  echo "$(mv_ts) ${C_G}Installed.${C_0} Continuing."
}

mv_need_value() {
  [[ $# -ge 2 && -n "$2" ]] || { echo "ERROR: missing value for $1" >&2; exit 1; }
}

while [[ $# -gt 0 ]]; do
  opt="$1"
  case "$opt" in
    --*=*) set -- "${opt%%=*}" "${opt#*=}" "${@:2}" ;;
  esac
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --history) print_script_history; exit 0 ;;
    -y|--yes) DO_YES=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    --redo) REDO=1; shift ;;
    --old)
      mv_need_value "$@"
      case "$2" in
        keep|delete) OLD_MODE="$2"; OLD_ASKED=1 ;;
        *) echo "ERROR: --old must be keep or delete, not: $2" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --size)
      mv_need_value "$@"
      mv_set_size "$2" || { echo "ERROR: --size must be WxH or N, 160 to 4000 (got $2)" >&2; exit 1; }
      shift 2 ;;
    --zoom)
      mv_need_value "$@"
      mv_zoom_ok "$2" || { echo "ERROR: --zoom must be 12 to 18 (got $2)" >&2; exit 1; }
      ZOOM=$(( 10#$2 )); shift 2 ;;
    --fps)
      mv_need_value "$@"
      if [[ "${2,,}" == same ]]; then
        FPS=same
      elif [[ "$2" =~ ^[0-9]+([.][0-9]+)?$ ]] && mv_gt "$2" 0 && ! mv_gt "$2" 120; then
        FPS="$2"
      else
        echo "ERROR: --fps must be same or a number up to 120 (got $2)" >&2; exit 1
      fi
      shift 2 ;;
    --track-up) TRACK_UP=1; shift ;;
    --north-up) TRACK_UP=0; shift ;;
    --no-smooth) SMOOTH=0; SMOOTH_FROM_CLI=1; shift ;;
    --smooth|--smooth-map)
      mv_need_value "$@"
      mv_seconds_ok "$2" || { echo "ERROR: $1 must be 0 to 60 seconds (got $2)" >&2; exit 1; }
      if [[ "$1" == --smooth ]]; then SMOOTH_LINE="$2"; else SMOOTH_MAP="$2"; fi
      SMOOTH_FROM_CLI=1; shift 2 ;;
    --max-jump)
      mv_need_value "$@"
      [[ "$2" =~ ^[0-9]+$ ]] && (( 10#$2 == 0 || (10#$2 >= 50 && 10#$2 <= 2000) )) \
        || { echo "ERROR: --max-jump must be 0 or 50 to 2000 km/h (got $2)" >&2; exit 1; }
      MAX_JUMP=$(( 10#$2 )); SMOOTH_FROM_CLI=1; shift 2 ;;
    --no-curve) CURVE=0; SMOOTH_FROM_CLI=1; shift ;;
    --show-speed) SHOW_SPEED=1; shift ;;
    --no-speed) SHOW_SPEED=0; shift ;;
    --no-clock) SHOW_CLOCK=0; shift ;;
    --gpx) mv_need_value "$@"; GPX_OVERRIDE="$(mv_unix_path "$2")"; shift 2 ;;
    --start)
      mv_need_value "$@"
      START_OVERRIDE="$(date -d "$2" +%s 2>/dev/null)" || { echo "ERROR: --start is not a date and time: $2" >&2; exit 1; }
      START_TEXT="$2"; shift 2 ;;
    --speed)
      mv_need_value "$@"
      [[ "$2" =~ ^[0-9]+([.][0-9]+)?$ ]] && mv_gt "$2" 0 || { echo "ERROR: --speed must be a number above 0 (got $2)" >&2; exit 1; }
      SPEED_OVERRIDE="$2"; shift 2 ;;
    --tz-shift)
      mv_need_value "$@"
      [[ "$2" =~ ^[-+]?[0-9]+([.][0-9]+)?$ ]] || { echo "ERROR: --tz-shift must be hours, for example 2 or -1 (got $2)" >&2; exit 1; }
      TZ_SHIFT="$2"; shift 2 ;;
    --tile-url)
      mv_need_value "$@"
      [[ "$2" == *"{z}"* && "$2" == *"{x}"* && "$2" == *"{y}"* ]] || { echo "ERROR: --tile-url needs {z}, {x}, and {y}" >&2; exit 1; }
      TILE_URL="$2"; shift 2 ;;
    --attribution) mv_need_value "$@"; ATTRIBUTION="$2"; shift 2 ;;
    --cache) mv_need_value "$@"; CACHE_DIR="$(mv_unix_path "$2")"; CACHE_FROM_CLI=1; shift 2 ;;
    --encoder)
      mv_need_value "$@"
      case "$2" in
        auto|nvenc|x265|x264) ENCODER="$2" ;;
        *) echo "ERROR: --encoder must be auto, nvenc, x265, or x264" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --quality)
      mv_need_value "$@"
      [[ "$2" =~ ^[0-9]+$ ]] && (( 10#$2 <= 51 )) || { echo "ERROR: --quality must be 0 to 51" >&2; exit 1; }
      QUALITY=$(( 10#$2 )); shift 2 ;;
    --from)
      mv_need_value "$@"
      FROM="$(mv_parse_time "$2")" || { echo "ERROR: --from is not a time: $2" >&2; exit 1; }
      shift 2 ;;
    --length)
      mv_need_value "$@"
      LENGTH="$(mv_parse_time "$2")" || { echo "ERROR: --length is not a time: $2" >&2; exit 1; }
      mv_gt "$LENGTH" 0 || { echo "ERROR: --length must be more than 0" >&2; exit 1; }
      shift 2 ;;
    --) shift; INPUT_ARGS+=("$@"); break ;;
    -*) echo "ERROR: unknown option: $1 (see --help)" >&2; exit 1 ;;
    *) INPUT_ARGS+=("$1"); shift ;;
  esac
done
mv_update_test
mv_gt "$SMOOTH_LINE" "$SMOOTH_MAP" && SMOOTH_MAP="$SMOOTH_LINE"

if [[ ! -r "$PY_HELPER" ]]; then
  echo "ERROR: the drawing helper is missing: ${PY_HELPER}" >&2
  echo "       Copy video-pgm-create-map-video-from-gpx.py next to this script." >&2
  exit 1
fi
mv_check_prereqs
if [[ -z "$CACHE_DIR" ]]; then
  _host="$(sed -E 's#^[a-z]+://##; s#/.*##; s#\{s\}\.##; s#[^A-Za-z0-9.-]#_#g' <<<"$TILE_URL")"
  CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/video-pgm-map-tiles/${_host:-tiles}"
fi

if (( ${#INPUT_ARGS[@]} == 0 )); then
  mv_add_directory "."
else
  for _arg in "${INPUT_ARGS[@]}"; do
    _path="$(mv_unix_path "$_arg")"
    if [[ -d "$_path" ]]; then
      mv_add_directory "$_path"
    elif [[ -f "$_path" ]]; then
      mv_add_video "$_path" 1
    else
      echo "ERROR: not a file or directory: ${_arg}" >&2
      exit 1
    fi
  done
fi

if (( ${#J_VID[@]} == 0 )); then
  echo "$(mv_ts) No FrontCam video with a start clock in its name. Name a video file, with --start if needed."
  exit 0
fi
if (( ${#J_VID[@]} > 1 )) && [[ -n "$GPX_OVERRIDE" || -n "$START_OVERRIDE" ]]; then
  echo "ERROR: --gpx and --start work with one video only (found ${#J_VID[@]})." >&2
  exit 1
fi
SUMMARY=1

ENCODER_LIST="$(ffmpeg -hide_banner -encoders 2>/dev/null || true)"
mapfile -t _kinds < <(mv_encoder_candidates)
if (( ${#_kinds[@]} == 0 )); then
  echo "$(mv_ts) ${C_R}No usable video encoder for '${ENCODER}' in this ffmpeg.${C_0}" >&2
  exit 1
fi
mv_set_encoder_args "${_kinds[0]}"
echo
mv_print_box_lines "$(ffmpeg -version 2>&1 | awk '/^ffmpeg version / { print $1, $2, $3; exit }')" \
  "GPU HEVC encoder: $(mv_encoder_available hevc_nvenc && echo hevc_nvenc || echo none)" \
  "Python: $(python3 -c 'import sys, PIL; print("%d.%d.%d, Pillow %s" % (sys.version_info[:3] + (PIL.__version__,)))')"

printf '%s Reading the length of %d video(s)...' "$(mv_ts)" "${#J_VID[@]}"
for _i in "${!J_VID[@]}"; do
  mv_probe "${J_VID[$_i]}"
  J_DUR[$_i]="$PR_DUR"
  J_FPS[$_i]="${PR_FPS:-25/1}"
  J_OUT[$_i]="" J_STATE[$_i]=bad J_POINTS[$_i]="" J_SHIFT[$_i]=0 J_FIRST[$_i]="" J_LAST[$_i]=""
  J_OVERLAP[$_i]=0 J_DIST[$_i]="" J_VMAX[$_i]="" J_TILES[$_i]=0 J_CACHED[$_i]=0 J_LAT[$_i]="" J_ERR[$_i]=""
  J_DROPPED[$_i]=0
  if [[ -n "$GPX_OVERRIDE" ]]; then
    J_GPX[$_i]="$GPX_OVERRIDE"
  else
    J_GPX[$_i]="$(mv_find_gpx "${J_VID[$_i]}" || true)"
  fi
done
echo " done."
if (( ! DO_YES && ! DRY_RUN && ! SMOOTH_FROM_CLI )) && (( script_is_run_interactively )); then
  mv_prompt_smooth
fi
mv_read_all_info
mv_print_existing
mv_print_plan

if (( DRY_RUN )); then
  SUMMARY=0
  mv_heading "Commands (dry run)"
  for _i in "${!J_VID[@]}"; do
    [[ "${J_STATE[$_i]}" == render ]] || continue
    mv_py_args "$_i"
    echo
    echo "python3 $(mv_quote_args "$PY_HELPER" render "${PY_ARGS[@]}" --fps "$(mv_job_fps "$_i")" --out "${J_OUT[$_i]}" -- "${ENC_ARGS[@]}")"
  done
  echo
  exit 0
fi

if (( ! DO_YES )); then
  if (( ! script_is_run_interactively )); then
    echo "$(mv_ts) Not a terminal: nothing rendered. Add -y to render without asking."
    exit 0
  fi
  mv_prompt_plan
fi

for _i in "${!J_VID[@]}"; do
  if [[ "${J_STATE[$_i]}" == exists ]] && (( REDO )); then
    J_STATE[$_i]=render
  fi
done
return_code=0
mv_fetch_tiles
_total=0
for _i in "${!J_VID[@]}"; do
  [[ "${J_STATE[$_i]}" == render ]] && (( _total++ )) || true
done
_n=0
for _i in "${!J_VID[@]}"; do
  case "${J_STATE[$_i]}" in
    exists) SKIPPED_LIST+=("${J_OUT[$_i]} (already exists)"); continue ;;
    bad) SKIPPED_LIST+=("${J_VID[$_i]} (no usable track)"); continue ;;
  esac
  (( _n++ )) || true
  _rc=0
  mv_render_job "$_n" "$_total" "$_i" || _rc=$?
  (( _rc == 130 )) && { return_code=130; exit 130; }
  (( _rc != 0 )) && return_code=1
done

exit "$return_code"
