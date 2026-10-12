#!/bin/bash
# v. 20261009.160131 - also read .tcx tracks; a Trackpoint with a time and a position is used like a GPX point
# v. 20261009.151425 - report which photos and videos have no location, and write one from the nearest GPX point

# 2026.10.09 - v. 0.2 - .tcx files are read with .gpx, including from --gpx and from the directory search
# 2026.10.09 - v. 0.1 - initial release: ask this directory or all subdirectories, summarize who has a location, write a missing one from a GPX point close in time
#
# video-pgm-geotag-missing-media.sh
#
# Look through photos and videos and say which ones already have a location
# and which ones do not. A missing location can be filled from GPX or TCX
# tracks in the same place: the point closest in time to when the picture or
# video was taken, when that point is close enough (30 seconds unless you
# change it). ExifTool reads the times and writes the location. The file time
# is kept.
#
# A video gets the point at its start. Track times are UTC. A camera clock with
# no timezone is shifted by the offset you give (Polish summer time is +02:00).
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-n|--dry-run] [--redo]
       [--here | --recursive]
       [--tz OFFSET|auto] [--max-gap SECONDS] [--quicktime utc|local]
       [--gpx FILE|DIR ...]
       [FILE|DIR ...]

Report which photos and videos have a location, and which do not. With no
FILE or DIR, the current directory is used. You are asked whether that is
only this directory or this directory and its subdirectories. Windows paths
such as P:\\video\\trip are read as /mnt/p/video/trip.

Photos: .jpg .jpeg .heic .png
Videos: .mp4 .mov
Tracks: .gpx and .tcx in that same search, plus any --gpx you add. A .tcx
file is a Garmin Training Center track. A directory given with --gpx is read
with its subdirectories, and both kinds of track are taken from it.

The time in the file is the capture time (DateTimeOriginal, then video
CreateDate). If those are missing, the file time is used. The report names
which clock was used. Track times are UTC. A camera time that has no timezone
is shifted by --tz before it is compared. +02:00 means the camera clock is
two hours ahead of UTC. --tz auto learns that shift from files in the same
run that already have both a camera time and a GPS time.

A file with no location is a match when some track point is within --max-gap
seconds (default 30). The closest point is the one used. With a point every
one or two seconds, a normal match is about a second away. The report shows
the gap. A video is tagged at its start.

Nothing is written until you say so. -n prints the report and stops. -y
writes without asking. A file that already has a location is left as it is,
unless --redo is given and a point is close enough. The write goes through
ExifTool. The file time is kept.

Video CreateDate is read as UTC, which is right for a GoPro. If a phone
stored local time in that field, use --quicktime local.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask. This directory only, unless --recursive.
                       Camera offset +02:00 when --tz is omitted. Write every
                       match.
  -n, --dry-run        Print the report. Write nothing.
  --redo               Write again over a location that is already there,
                       when a track point is close enough.
  --here               This directory only. Do not ask.
  --recursive          This directory and its subdirectories. Do not ask.
  --tz OFFSET|auto     Camera clock minus UTC. Examples: +02:00, -05:30, 0.
                       auto: learn it from files that already have a GPS time.
  --max-gap SECONDS    How close in time a track point must be. Default 30.
  --quicktime utc|local
                       How to read a video CreateDate. Default utc.
  --gpx FILE|DIR       More tracks, .gpx or .tcx. Repeat for more than one.
                       A directory is read with its subdirectories.

Needs: python3, and exiftool (video-pgm-install-exiftool.sh). The helper
video-pgm-geotag-missing-media.py has its own selftest.

Examples:
  $(basename "$0")
      Current directory. Ask about subdirectories. Report, then ask before writing.
  $(basename "$0") -n /mnt/p/video/trip
      Report that directory. Write nothing.
  $(basename "$0") -y --tz +02:00 --recursive /mnt/p/video/trip
      Subdirectories too. Write every close match. Camera clock is +02:00.
  $(basename "$0") --gpx /mnt/p/tracks/day.gpx --here /mnt/p/video/trip
      Use that GPX as well as any .gpx or .tcx beside the videos.
  $(basename "$0") --gpx /mnt/p/tracks/ride.tcx /mnt/p/video/trip
      Use that TCX file as the track.
EOF
}

gm_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

gm_colors() {
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

gm_heading() {
  local title="$1" width=78 rest
  rest=$(( width - ${#title} - 4 ))
  (( rest < 3 )) && rest=3
  echo
  printf '%s══ %s %s%s\n' "$C_B$C_C" "$title" "$(printf '%*s' "$rest" '' | sed 's/ /═/g')" "$C_0"
}

gm_unix_path() {
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

gm_read_key() {
  local prompt="$1" default_key="${2:-}" answer="" discard
  printf '%s' "$prompt"
  while IFS= read -r -t 0.02 -n 1 discard; do :; done
  read -r -n 1 answer || answer=""
  echo
  answer="${answer,,}"
  REPLY="${answer:-$default_key}"
}

gm_quit() {
  echo "$(gm_ts) Quit. Nothing was written."
  return_code=0
  exit 0
}

gm_skip_name() {
  local base="$1"
  [[ "$base" == ._* || "$base" == *_old-* || "$base" == *.partial || "$base" == *.partial.* ]]
}

gm_find_exiftool() {
  local cmd
  if [[ -n "${EXIFTOOL:-}" && -x "${EXIFTOOL}" ]]; then
    printf '%s\n' "$EXIFTOOL"
    return 0
  fi
  if [[ -x /usr/local/bin/exiftool ]]; then
    printf '%s\n' /usr/local/bin/exiftool
    return 0
  fi
  if cmd=$(command -v exiftool 2>/dev/null); then
    printf '%s\n' "$cmd"
    return 0
  fi
  return 1
}

gm_check_prereqs() {
  local missing=0
  if ! command -v python3 >/dev/null 2>&1; then
    echo "$(gm_ts) ${C_R}python3 is not installed.${C_0}" >&2
    echo "  Install command: sudo apt-get install -y python3" >&2
    missing=1
  fi
  if ! EXIFTOOL_BIN=$(gm_find_exiftool); then
    echo "$(gm_ts) ${C_R}exiftool is not installed.${C_0}" >&2
    echo "  Run video-pgm-install-exiftool.sh" >&2
    echo "  or: sudo apt-get install -y libimage-exiftool-perl" >&2
    missing=1
  fi
  if (( missing )); then
    return_code=1
    exit 1
  fi
}

gm_add_media() {
  local rp="$1"
  [[ -f "$rp" && -s "$rp" ]] || return 0
  [[ -n "${SEEN_MEDIA[$rp]:-}" ]] && return 0
  SEEN_MEDIA[$rp]=1
  printf '%s\0' "$rp" >> "$WORK/media"
  MEDIA_N=$(( MEDIA_N + 1 ))
}

gm_add_gpx() {
  local rp="$1"
  [[ -f "$rp" && -s "$rp" ]] || return 0
  [[ -n "${SEEN_GPX[$rp]:-}" ]] && return 0
  SEEN_GPX[$rp]=1
  printf '%s\0' "$rp" >> "$WORK/gpx"
  GPX_N=$(( GPX_N + 1 ))
}

gm_add_root() {
  local rp="$1"
  [[ -n "$rp" ]] || return 0
  [[ -n "${SEEN_ROOT[$rp]:-}" ]] && return 0
  SEEN_ROOT[$rp]=1
  printf '%s\0' "$rp" >> "$WORK/roots"
}

gm_consider_file() {
  local path="$1" kind="$2" base ext
  base="${path##*/}"
  gm_skip_name "$base" && return 0
  ext="${base##*.}"
  ext="${ext,,}"
  case "$ext" in
    jpg|jpeg|heic|png|mp4|mov)
      [[ "$kind" == media || "$kind" == both ]] && gm_add_media "$path"
      ;;
    gpx|tcx)
      [[ "$kind" == gpx || "$kind" == both ]] && gm_add_gpx "$path"
      ;;
  esac
}

gm_walk() {
  local dir="$1" recurse="$2" kind="$3" path
  [[ -d "$dir" ]] || return 0
  if (( recurse )); then
    while IFS= read -r -d '' path; do
      gm_consider_file "$path" "$kind"
    done < <(find "$dir" \( -type d -name '.*' -prune \) -o -type f -print0)
  else
    while IFS= read -r -d '' path; do
      gm_consider_file "$path" "$kind"
    done < <(find "$dir" -maxdepth 1 -type f -print0)
  fi
}

gm_classify_inputs() {
  local arg path
  DIR_INPUTS=()
  FILE_INPUTS=()
  if (( ${#INPUT_ARGS[@]} == 0 )); then
    DIR_INPUTS+=("$(pwd)")
    return 0
  fi
  for arg in "${INPUT_ARGS[@]}"; do
    path="$(gm_unix_path "$arg")"
    if [[ -d "$path" ]]; then
      DIR_INPUTS+=("$(readlink -f -- "$path")")
    elif [[ -f "$path" ]]; then
      FILE_INPUTS+=("$(readlink -f -- "$path")")
    else
      echo "ERROR: not a file or directory: ${arg}" >&2
      return_code=1
      exit 1
    fi
  done
}

gm_ask_scope() {
  local reply
  if (( ${#DIR_INPUTS[@]} == 0 )); then
    RECURSE=0
    return 0
  fi
  if (( SCOPE_SET )); then
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    RECURSE=0
    echo "$(gm_ts) Directories: this directory only. Pass --recursive to include subdirectories."
    return 0
  fi
  echo
  if (( ${#DIR_INPUTS[@]} > 1 )); then
    echo "Look in subdirectories of these directories too?"
  else
    echo "Look in subdirectories too?"
  fi
  echo "  [T] This directory only (default)"
  echo "  [A] All subdirectories"
  echo "  [q] Quit"
  gm_read_key "This directory or all subdirectories? [T/a/q]: " t
  reply="$REPLY"
  case "$reply" in
    t) RECURSE=0 ;;
    a) RECURSE=1 ;;
    q) gm_quit ;;
    *) echo "$(gm_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
}

gm_tz_canonical() {
  local out
  if [[ "$1" == auto ]]; then
    printf '%s\n' auto
    return 0
  fi
  if out=$(python3 "$PY_HELPER" check-tz "$1" 2>/dev/null); then
    printf '%s\n' "$out"
    return 0
  fi
  return 1
}

gm_ask_tz() {
  local reply typed canon
  if [[ -n "$TZ_VALUE" ]]; then
    if ! canon=$(gm_tz_canonical "$TZ_VALUE"); then
      echo "ERROR: --tz must look like +02:00, -05:30, 0, or auto. Not: ${TZ_VALUE}" >&2
      return_code=1
      exit 1
    fi
    TZ_VALUE="$canon"
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    TZ_VALUE="+02:00"
    TZ_ASSUMED=1
    echo "$(gm_ts) Camera offset was not set. Using +02:00. Pass --tz to choose it."
    return 0
  fi
  echo
  echo "Track times are UTC. A camera time with no timezone is shifted by this offset."
  echo "Polish summer time is +02:00. Use 0 when the camera clock is already UTC."
  echo "  [2] +02:00 (default)"
  echo "  [0] camera clock is UTC"
  echo "  [a] type another offset"
  echo "  [q] Quit"
  gm_read_key "Camera offset from UTC? [2/0/a/q]: " 2
  reply="$REPLY"
  case "$reply" in
    2) TZ_VALUE="+02:00" ;;
    0) TZ_VALUE="+00:00" ;;
    q) gm_quit ;;
    a)
      while true; do
        printf 'Offset (for example +02:00, -05:30, 0): '
        IFS= read -r typed || gm_quit
        if canon=$(gm_tz_canonical "$typed"); then
          TZ_VALUE="$canon"
          break
        fi
        echo "That offset is not one I can use."
      done
      ;;
    *) echo "$(gm_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
}

gm_collect() {
  local path parent
  WORK=$(mktemp -d)
  : > "$WORK/media"
  : > "$WORK/gpx"
  : > "$WORK/roots"
  MEDIA_N=0
  GPX_N=0
  for path in "${DIR_INPUTS[@]}"; do
    gm_add_root "$path"
    gm_walk "$path" "$RECURSE" both
  done
  for path in "${FILE_INPUTS[@]}"; do
    parent="$(dirname -- "$path")"
    gm_add_root "$parent"
    gm_consider_file "$path" media
    gm_walk "$parent" 0 gpx
  done
  for path in "${GPX_EXTRA[@]}"; do
    path="$(gm_unix_path "$path")"
    if [[ -d "$path" ]]; then
      path="$(readlink -f -- "$path")"
      gm_add_root "$path"
      gm_walk "$path" 1 gpx
    elif [[ -f "$path" ]]; then
      path="$(readlink -f -- "$path")"
      gm_add_root "$(dirname -- "$path")"
      gm_add_gpx "$path"
    else
      echo "ERROR: --gpx is not a file or directory: ${path}" >&2
      return_code=1
      exit 1
    fi
  done
}

gm_scope_label() {
  if (( ${#DIR_INPUTS[@]} > 1 )); then
    if (( RECURSE )); then
      printf '%s\n' "these directories and their subdirectories"
    else
      printf '%s\n' "these directories only"
    fi
  elif (( ${#DIR_INPUTS[@]} == 1 )); then
    if (( RECURSE )); then
      printf '%s\n' "this directory and its subdirectories"
    else
      printf '%s\n' "this directory only"
    fi
  else
    printf '%s\n' "the files named on the command line"
  fi
}

gm_plan_count() {
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8")).get("write_count", 0))' "$1"
}

gm_cleanup() {
  [[ -n "${WORK:-}" && -d "${WORK}" ]] && rm -rf -- "$WORK"
}

gm_ctrl_c() {
  echo
  echo "$(gm_ts) Interrupted. Nothing more was written."
  return_code=130
  exit 130
}

# --- main -------------------------------------------------------------------

DO_YES=0
DRY_RUN=0
REDO=0
RECURSE=0
SCOPE_SET=0
TZ_VALUE=""
TZ_ASSUMED=0
MAX_GAP=30
QUICKTIME=utc
INPUT_ARGS=()
GPX_EXTRA=()
DIR_INPUTS=()
FILE_INPUTS=()
WORK=""
MEDIA_N=0
GPX_N=0
EXIFTOOL_BIN=""
return_code=0
declare -A SEEN_MEDIA=()
declare -A SEEN_GPX=()
declare -A SEEN_ROOT=()
PY_HELPER="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/video-pgm-geotag-missing-media.py"
gm_colors

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

# shellcheck disable=SC1091
. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

trap gm_cleanup EXIT
trap gm_ctrl_c INT

gm_need_value() {
  [[ $# -ge 2 && -n "$2" ]] || { echo "ERROR: missing value for $1" >&2; exit 1; }
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
    --here)
      if (( SCOPE_SET && RECURSE )); then
        echo "ERROR: --here and --recursive cannot be used together" >&2
        exit 1
      fi
      SCOPE_SET=1
      RECURSE=0
      shift
      ;;
    --recursive)
      if (( SCOPE_SET && ! RECURSE )); then
        echo "ERROR: --here and --recursive cannot be used together" >&2
        exit 1
      fi
      SCOPE_SET=1
      RECURSE=1
      shift
      ;;
    --tz)
      gm_need_value "$@"
      TZ_VALUE="$2"
      shift 2
      ;;
    --max-gap)
      gm_need_value "$@"
      if [[ ! "$2" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "ERROR: --max-gap must be a number of seconds, not: $2" >&2
        exit 1
      fi
      MAX_GAP="$2"
      shift 2
      ;;
    --quicktime)
      gm_need_value "$@"
      case "$2" in
        utc|local) QUICKTIME="$2" ;;
        *) echo "ERROR: --quicktime must be utc or local, not: $2" >&2; exit 1 ;;
      esac
      shift 2
      ;;
    --gpx)
      gm_need_value "$@"
      GPX_EXTRA+=("$2")
      shift 2
      ;;
    --) shift; INPUT_ARGS+=("$@"); break ;;
    -*) echo "ERROR: unknown option: $1 (see --help)" >&2; exit 1 ;;
    *) INPUT_ARGS+=("$1"); shift ;;
  esac
done

if [[ ! -f "$PY_HELPER" ]]; then
  echo "$(gm_ts) Missing helper: ${PY_HELPER}" >&2
  return_code=1
  exit 1
fi

gm_check_prereqs
gm_classify_inputs
gm_ask_scope
gm_ask_tz

gm_collect

if (( MEDIA_N == 0 )); then
  echo "$(gm_ts) No photos or videos."
  return_code=0
  exit 0
fi

gm_heading "Geotag"
echo "  Files: ${MEDIA_N}    Tracks: ${GPX_N}"
echo "  Scope: $(gm_scope_label)"
if [[ "$TZ_VALUE" == auto ]]; then
  echo "  Camera offset: learned from files that already have a GPS time"
else
  echo "  Camera offset: ${TZ_VALUE}"
fi
echo "  Close enough: ${MAX_GAP}s"
echo

SCAN_ARGS=(
  scan
  --tz "$TZ_VALUE"
  --max-gap "$MAX_GAP"
  --quicktime "$QUICKTIME"
  --exiftool "$EXIFTOOL_BIN"
  --media-list "$WORK/media"
  --gpx-list "$WORK/gpx"
  --root-list "$WORK/roots"
  --plan "$WORK/plan.json"
  --scope "$(gm_scope_label)"
)
if (( TZ_ASSUMED )); then
  SCAN_ARGS+=(--tz-assumed)
fi
if (( REDO )); then
  SCAN_ARGS+=(--redo)
fi

python3 "$PY_HELPER" "${SCAN_ARGS[@]}" || {
  return_code=$?
  exit "$return_code"
}

WRITE_N=$(gm_plan_count "$WORK/plan.json")

if (( DRY_RUN )); then
  echo
  echo "$(gm_ts) Dry run. Nothing written."
  return_code=0
  exit 0
fi

if (( WRITE_N == 0 )); then
  echo
  echo "$(gm_ts) Nothing to write."
  return_code=0
  exit 0
fi

if (( ! DO_YES )); then
  if (( ! script_is_run_interactively )); then
    echo
    echo "$(gm_ts) Not a terminal: nothing written. Add -y to write without asking."
    return_code=0
    exit 0
  fi
  echo
  echo "Write a location into ${WRITE_N} file$( (( WRITE_N == 1 )) || printf 's' )?"
  echo "  ExifTool rewrites each file in place. The file time is kept."
  echo "  A file that already has a location is not in this count, unless --redo."
  echo "  [y] Yes, write"
  echo "  [N] No, stop here (default)"
  echo "  [q] Quit"
  gm_read_key "Write into ${WRITE_N} file$( (( WRITE_N == 1 )) || printf 's' )? [y/N/q]: " n
  case "$REPLY" in
    y) ;;
    q) gm_quit ;;
    *) echo "$(gm_ts) Nothing written."; return_code=0; exit 0 ;;
  esac
fi

echo
python3 "$PY_HELPER" write --exiftool "$EXIFTOOL_BIN" --plan "$WORK/plan.json" || return_code=$?
exit "$return_code"
