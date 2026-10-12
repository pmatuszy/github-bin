#!/bin/bash
# v. 20261012.110653 - a track point is named from OpenStreetMap, and the guess says how close that point is
# v. 20261012.110358 - a track write names the file, the track, and how far the point is
# v. 20261012.110129 - the Geotag heading counts files with a location and files without one
# v. 20261012.110006 - verbose file lines give altitude its own height column
# v. 20261012.105829 - verbose file lines name each column and keep those columns aligned
# v. 20261012.105648 - tracks are loaded only after a file is found that still needs a location
# v. 20261012.105141 - file-by-file report lines are shown only when verbose is on
# v. 20261012.105042 - the track list is totals only unless verbose is asked or passed
# v. 20261012.104935 - the year is stated from the file names, and [C] means the current directory
# v. 20261012.104451 - places are printed in alphabetical order of the name
# v. 20261012.104348 - a chosen year limits the tracks loaded from [tracks-location], and that count is the one printed
# v. 20261012.104010 - tracks are loaded in alphabetical order of the file name
# v. 20261012.103728 - a typed track year may be a range, and the first year must not be newer than the second
# v. 20261012.102745 - when profile_location_dir is set, also read that directory and its etc and conf
# v. 20261012.102638 - .conf is read from /etc, $HOME, $HOME/etc, and $HOME/conf, and every copy is merged
# v. 20261012.102243 - read every .conf in the allowed places, including $HOME/conf; do not stop at the first
# v. 20261012.101840 - GPSProcessingMethod is TRACK for a GPX or TCX point and MANUAL for a chosen place
# v. 20261012.100144 - the closing summary right-aligns file, location, and track counts in one column
# v. 20261012.095919 - a typed latitude and longitude can be named from OpenStreetMap when the internet is allowed
# v. 20261012.095355 - [tracks-location] is searched through every subdirectory, and that count is printed first
# v. 20261012.094641 - [tracks-location] in the .conf is another directory of GPX and TCX tracks
# v. 20261012.094407 - q on a place question quits at once, and a latitude and longitude can be typed for that file
# v. 20261012.092540 - print .conf errors, and merge entries that are the same location
# v. 20261012.092157 - merge named places from every .conf found from here up to /, and in $HOME and $HOME/etc
# v. 20261009.160131 - also read .tcx tracks; a Trackpoint with a time and a position is used like a GPX point
# v. 20261009.151425 - report which photos and videos have no location, and write one from the nearest GPX point

# 2026.10.12 - v. 0.26 - a track point is named from OpenStreetMap, and the guess says how close that point is
# 2026.10.12 - v. 0.25 - a track write names the file, the track, and how far the point is
# 2026.10.12 - v. 0.24 - the Geotag heading counts files with a location and files without one
# 2026.10.12 - v. 0.23 - verbose file lines give altitude its own height column
# 2026.10.12 - v. 0.22 - verbose file lines name each column and keep those columns aligned
# 2026.10.12 - v. 0.21 - tracks are loaded only after a file is found that still needs a location
# 2026.10.12 - v. 0.20 - file-by-file report lines are shown only when verbose is on
# 2026.10.12 - v. 0.19 - the track list is totals only unless verbose is asked or passed
# 2026.10.12 - v. 0.18 - the year is stated from the file names, and [C] means the current directory
# 2026.10.12 - v. 0.17 - places are printed in alphabetical order of the name
# 2026.10.12 - v. 0.16 - a chosen year limits the tracks loaded from [tracks-location], and that count is the one printed
# 2026.10.12 - v. 0.15 - tracks are loaded in alphabetical order of the file name
# 2026.10.12 - v. 0.14 - track years can be typed as 2026, 2026-2027, or 2026 2027; a reversed range is refused
# 2026.10.12 - v. 0.13 - when profile_location_dir is set, also merge the .conf in that directory and in its etc and conf
# 2026.10.12 - v. 0.12 - .conf files are read from /etc, $HOME, $HOME/etc, and $HOME/conf, and every copy is merged
# 2026.10.12 - v. 0.11 - every .conf in the allowed places is merged, including $HOME/conf; the search does not stop at the first file
# 2026.10.12 - v. 0.10 - a track point is marked TRACK and a place you pick or type is marked MANUAL, in GPSProcessingMethod
# 2026.10.12 - v. 0.9 - the run summary at the end right-aligns how many files, locations, tracks, and track points
# 2026.10.12 - v. 0.8 - a typed latitude and longitude is looked up on OpenStreetMap when you allow the internet; the default is yes
# 2026.10.12 - v. 0.7 - [tracks-location] reads .gpx and .tcx from that directory and every subdirectory, and the count is shown before the report
# 2026.10.12 - v. 0.6 - [tracks-location] adds that directory, and the folders inside it, to the GPX and TCX search
# 2026.10.12 - v. 0.5 - on the place question, q quits without Enter; g asks for a latitude and longitude for that file
# 2026.10.12 - v. 0.4 - .conf problems are printed; the same coordinates are one place, and one name with two different coordinates is an error
# 2026.10.12 - v. 0.3 - a file with no track point can be tagged from [place] labels in video-pgm-geotag-missing-media.conf; every conf found is merged, and the paths are printed first
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
# A file with no track point can take a named place from
# video-pgm-geotag-missing-media.conf. Every copy found is merged, from
# /etc, $HOME, $HOME/etc, and $HOME/conf. When profile_location_dir is set,
# also that directory, profile_location_dir/etc, and profile_location_dir/conf.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-n|--dry-run] [--redo] [--verbose]
       [--here | --recursive]
       [--tz OFFSET|auto] [--max-gap SECONDS] [--quicktime utc|local]
       [--gpx FILE|DIR ...]
       [FILE|DIR ...]

Report which photos and videos have a location, and which do not. With no
FILE or DIR, the current directory is used. [C] keeps that directory only.
[a] includes its subdirectories. Windows paths such as P:\\video\\trip are
read as /mnt/p/video/trip.

The first question is whether to list every track and every photo or video.
The default is no: the report then gives the counts. --verbose lists each
one. -y does not ask and stays with the totals.

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

Nothing is written until you say so. Each file is named, with the track and
how far that point is. -n prints the report and stops. -y writes the track
matches without asking. A file that already has a location is left as it is,
unless --redo is given and a point is close enough. The write goes through
ExifTool. The file time is kept.

A file with no GPX or TCX point close enough can be tagged from a named
place. The names come from video-pgm-geotag-missing-media.conf. The script
reads every copy it finds and does not stop at the first one. The directories
are /etc, $HOME, $HOME/etc, and $HOME/conf. When profile_location_dir is
set, also profile_location_dir/etc, profile_location_dir/conf, and
profile_location_dir. Places and [tracks-location] entries from all of those files are used together. The paths are printed at
the start. A broken line, a name with no coordinates, or a name
that has two different locations is printed under Config errors. The same
coordinates are one place: a repeated name is listed once, and two names
for that point are joined. When one name has two different coordinates, the
earlier file is the one that is kept.
Each place is a line in brackets and the latitude, longitude under it:

  [Ponice 221]
  49.59078922757009, 19.966572075569914

A track directory is the same kind of heading, with a path under it. Every
subdirectory is searched, not only the files sitting in that folder. The
script says which year the photos and videos are probably from, judging by
the timestamps and file names. That year is the default. [t] asks for a year
or a range, such as 2026-2027, 2026 - 2027, or 2026 2027. The first year
must not be newer than the second. Only those years
are read, from that directory and from the tracks next to the photos and
videos. The count printed before the report is that set. Tracks are read
only when a photo or video still has no location. The script says how many
need geotagging, and how many already have a location, before that read.

  [tracks-location]
  /mnt/p/video/geotaging-kopie

For each file with no track point you are asked which name to write. q quits
at once, without Enter. g asks for a latitude and longitude for that file
only. Before the first track point or typed place, you are asked once whether
to look the point up on OpenStreetMap. The default is yes. If OpenStreetMap
cannot be reached, the coordinates are still written and later points are not
looked up. A place you pick or type is marked MANUAL. A point from a GPX or
TCX file is marked TRACK. Both are stored in GPSProcessingMethod. -y does not
pick a place for
you.

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

gm_now() {
  date +%s.%N
}

gm_proc_begin() {
  GM_PROC_SLICE="$(gm_now)"
}

gm_proc_end() {
  [[ -n "${GM_PROC_SLICE:-}" ]] || return 0
  GM_PROC_SEC="$(awk -v acc="${GM_PROC_SEC:-0}" -v t0="$GM_PROC_SLICE" -v t1="$(gm_now)" \
    'BEGIN { printf "%.6f", acc + (t1 - t0) }')"
  GM_PROC_SLICE=""
}

gm_fmt_int() {
  awk -v n="${1:-0}" 'BEGIN {
    s = sprintf("%d", n + 0)
    if (s ~ /^-/) { sign = "-"; s = substr(s, 2) } else sign = ""
    t = ""
    while (length(s) > 3) {
      t = "," substr(s, length(s) - 2, 3) t
      s = substr(s, 1, length(s) - 3)
    }
    printf "%s%s%s", sign, s, t
  }'
}

gm_format_elapsed() {
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

gm_format_wall() {
  local ns="${1:-}"
  date -d "@${ns%.*}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null \
    || date '+%Y.%m.%d %H:%M:%S'
}

gm_summary_kv() {
  printf '%s %-*s  %s\n' "$(gm_ts)" 28 "${1}:" "$2"
}

gm_load_counts() {
  [[ -n "${WORK:-}" && -f "${WORK}/plan.json" ]] || return 0
  IFS=$'\t' read -r SUM_FILES SUM_ALREADY SUM_UNMATCHED SUM_UNREAD SUM_TRACKS SUM_POINTS SUM_WROTE < <(
    python3 -c 'import json,sys
p=json.load(open(sys.argv[1], encoding="utf-8"))
c=p.get("counts") or {}
keys=("files","already","unmatched","unread","tracks","points")
vals=[str(int(c.get(k) or 0)) for k in keys]
vals.append(str(int(p.get("wrote_tracks") or 0)))
print("\t".join(vals))' "$WORK/plan.json"
  ) || return 0
  SUM_READY=1
}

gm_print_summary() {
  local end_ns total_sec wait_sec left width text
  local -a labels=() nums=()
  (( GM_SUMMARY )) || return 0
  (( GM_SUMMARY_DONE )) && return 0
  GM_SUMMARY_DONE=1
  gm_proc_end
  gm_load_counts
  if (( SUM_READY )); then
    left=$(( SUM_UNMATCHED - PLACE_WROTE ))
    (( left < 0 )) && left=0
    labels+=("Files"); nums+=("$SUM_FILES")
    (( SUM_ALREADY > 0 )) && { labels+=("Already had a location"); nums+=("$SUM_ALREADY"); }
    (( SUM_WROTE > 0 )) && { labels+=("Tagged from a track"); nums+=("$SUM_WROTE"); }
    (( PLACE_WROTE > 0 )) && { labels+=("Tagged from a place"); nums+=("$PLACE_WROTE"); }
    (( left > 0 )) && { labels+=("Left without a location"); nums+=("$left"); }
    (( SUM_UNREAD > 0 )) && { labels+=("Could not be read"); nums+=("$SUM_UNREAD"); }
    labels+=("Tracks"); nums+=("$SUM_TRACKS")
    labels+=("Track points"); nums+=("$SUM_POINTS")
  else
    labels+=("Files"); nums+=("${MEDIA_N:-0}")
    labels+=("Tracks"); nums+=("${GPX_N:-0}")
  fi
  width=1
  for text in "${nums[@]}"; do
    text="$(gm_fmt_int "$text")"
    (( ${#text} > width )) && width=${#text}
  done
  echo
  echo "$(gm_ts) --- Run summary ---"
  local i
  for i in "${!labels[@]}"; do
    printf '%s %-*s  %*s\n' "$(gm_ts)" 28 "${labels[$i]}:" "$width" "$(gm_fmt_int "${nums[$i]}")"
  done
  echo
  echo "$(gm_ts) --- Timing ---"
  end_ns="$(gm_now)"
  total_sec="$(awk -v s0="${GM_START_NS:-0}" -v s1="$end_ns" 'BEGIN { printf "%.6f", s1 - s0 }')"
  wait_sec="$(awk -v t="$total_sec" -v p="${GM_PROC_SEC:-0}" 'BEGIN { w = t - p; if (w < 0) w = 0; printf "%.6f", w }')"
  gm_summary_kv "Started" "$(gm_format_wall "${GM_START_NS:-}")"
  gm_summary_kv "Finished" "$(date '+%Y.%m.%d %H:%M:%S')"
  gm_summary_kv "Total wall time" "$(gm_format_elapsed "$total_sec")"
  gm_summary_kv "Processing time" "$(gm_format_elapsed "${GM_PROC_SEC:-0}")  (tracks, file times, writing)"
  gm_summary_kv "Other/wait time" "$(gm_format_elapsed "$wait_sec")  (prompts, startup, overhead)"
  echo
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

gm_read_place_choice() {
  local prompt="$1" first="" rest="" discard
  printf '%s' "$prompt"
  while IFS= read -r -t 0.02 -n 1 discard; do :; done
  IFS= read -r -n 1 first || first=""
  first="${first,,}"
  if [[ "$first" == q ]]; then
    echo
    echo "$(gm_ts) Quit."
    return_code=0
    exit 0
  fi
  if [[ -z "$first" || "$first" == $'\n' || "$first" == s ]]; then
    echo
    REPLY=s
    return 0
  fi
  if [[ "$first" == g ]]; then
    echo
    REPLY=g
    return 0
  fi
  if [[ "$first" =~ [0-9] ]]; then
    IFS= read -r rest || rest=""
    REPLY="${first}${rest}"
    REPLY="${REPLY,,}"
    REPLY="${REPLY#"${REPLY%%[![:space:]]*}"}"
    REPLY="${REPLY%"${REPLY##*[![:space:]]}"}"
    return 0
  fi
  echo
  REPLY="$first"
}

gm_ask_internet() {
  local reply
  if (( USE_NET >= 0 )); then
    return 0
  fi
  echo
  echo "A track point or a typed latitude and longitude can be named from OpenStreetMap."
  echo "  [Y] Yes, use the internet (default)"
  echo "  [n] No"
  echo "  [q] Quit"
  gm_read_key "Look up place names on the internet? [Y/n/q]: " y
  reply="$REPLY"
  case "$reply" in
    y) USE_NET=1 ;;
    n) USE_NET=0; echo "$(gm_ts) Place names will not be looked up." ;;
    q)
      echo "$(gm_ts) Quit."
      return_code=0
      exit 0
      ;;
    *) USE_NET=0; echo "$(gm_ts) Place names will not be looked up." ;;
  esac
}

gm_lookup_place() {
  local lat="$1" lon="$2" name rc
  GM_PLACE_NAME=""
  (( USE_NET == 1 )) || return 0
  if (( GM_LOOKED )); then
    sleep 1
  fi
  GM_LOOKED=1
  if name=$(python3 "$PY_HELPER" reverse "$lat" "$lon" 2>/dev/null); then
    GM_PLACE_NAME="$name"
    echo "That place is ${name}."
    return 0
  fi
  rc=$?
  if (( rc == 2 )); then
    USE_NET=2
    echo "$(gm_ts) Cannot reach OpenStreetMap. Place names will not be looked up."
  else
    echo "OpenStreetMap has no place name for that point."
  fi
}

gm_describe_coord() {
  GM_PLACE="typed"
  gm_lookup_place "$1" "$2"
  if [[ -n "$GM_PLACE_NAME" ]]; then
    GM_PLACE="$GM_PLACE_NAME"
  fi
}

gm_ask_coord() {
  local typed canon
  while true; do
    printf 'Latitude, longitude (for example 49.590789, 19.966572), or Enter to skip: '
    IFS= read -r typed || { echo "$(gm_ts) Quit."; return_code=0; exit 0; }
    typed="${typed#"${typed%%[![:space:]]*}"}"
    typed="${typed%"${typed##*[![:space:]]}"}"
    if [[ -z "$typed" ]]; then
      return 1
    fi
    if [[ "${typed,,}" == q ]]; then
      echo "$(gm_ts) Quit."
      return_code=0
      exit 0
    fi
    if canon=$(python3 "$PY_HELPER" check-coord "$typed" 2>/dev/null); then
      IFS=$'\t' read -r GM_LAT GM_LON <<< "$canon"
      return 0
    fi
    echo "That is not a latitude, longitude."
  done
}

gm_write_chosen() {
  local lat="$1" lon="$2" place="$3" i="$4"
  gm_proc_begin
  if python3 "$PY_HELPER" write-place \
    --exiftool "$EXIFTOOL_BIN" \
    --path "${CHOOSE_PATH[$i]}" \
    --kind "${CHOOSE_KIND[$i]}" \
    --lat "$lat" \
    --lon "$lon" \
    --gps-date "${CHOOSE_DATE[$i]}" \
    --gps-time "${CHOOSE_TIME[$i]}" \
    --label "${CHOOSE_SHOW[$i]}" \
    --place "$place"; then
    PLACE_WROTE=$(( PLACE_WROTE + 1 ))
  else
    return_code=$?
  fi
  gm_proc_end
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
  local rp="$1" base
  [[ -f "$rp" && -s "$rp" ]] || return 1
  base="${rp##*/}"
  gm_track_year_ok "$base" || return 1
  [[ -n "${SEEN_GPX[$rp]:-}" ]] && return 1
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

gm_ask_verbose() {
  local reply
  if (( VERBOSE_SET )); then
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    VERBOSE=0
    return 0
  fi
  echo
  echo "The report can list every track, and every photo or video."
  echo "  [N] No, totals only (default)"
  echo "  [v] Yes, list each file"
  echo "  [q] Quit"
  gm_read_key "Verbose output? [N/v/q]: " n
  reply="$REPLY"
  case "$reply" in
    n) VERBOSE=0 ;;
    v) VERBOSE=1 ;;
    q) gm_quit ;;
    *) echo "$(gm_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
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
    echo "$(gm_ts) Directories: current directory only. Pass --recursive to include subdirectories."
    return 0
  fi
  echo
  if (( ${#DIR_INPUTS[@]} > 1 )); then
    echo "Look in subdirectories of these directories too?"
  else
    echo "Look in subdirectories too?"
  fi
  if (( ${#DIR_INPUTS[@]} > 1 )); then
    echo "  [C] Current directories only (default)"
  else
    echo "  [C] Current directory only (default)"
  fi
  echo "  [a] All subdirectories"
  echo "  [q] Quit"
  if (( ${#DIR_INPUTS[@]} > 1 )); then
    gm_read_key "Current directories or all subdirectories? [C/a/q]: " c
  else
    gm_read_key "Current directory or all subdirectories? [C/a/q]: " c
  fi
  reply="$REPLY"
  case "$reply" in
    c) RECURSE=0 ;;
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

gm_track_year_ok() {
  local base="$1" y
  (( TRACK_ALL )) && return 0
  if [[ "$base" =~ ^((19|20)[0-9]{2}) ]]; then
    y="${BASH_REMATCH[1]}"
    [[ -n "${TRACK_YEAR[$y]:-}" ]] && return 0
  fi
  return 1
}

gm_year_phrase() {
  local n="$#" first last span
  if (( n <= 0 )); then
    printf '%s\n' "all years"
    return 0
  fi
  if (( n == 1 )); then
    printf '%s\n' "$1"
    return 0
  fi
  if (( n == 2 )); then
    printf '%s and %s\n' "$1" "$2"
    return 0
  fi
  first="$1"
  last="${!#}"
  span=$(( 10#$last - 10#$first + 1 ))
  if (( span == n )); then
    printf '%s-%s\n' "$first" "$last"
    return 0
  fi
  local out="$1" y
  shift
  for y in "$@"; do
    out="${out}, ${y}"
  done
  printf '%s\n' "$out"
}

gm_guess_media_years() {
  local f base y
  local -A seen=()
  GUESS_YEARS=()
  [[ -s "${WORK:-}/media" ]] || return 0
  while IFS= read -r -d '' f; do
    base="${f##*/}"
    if [[ "$base" =~ ^((19|20)[0-9]{2}) ]]; then
      y="${BASH_REMATCH[1]}"
      seen[$y]=1
    fi
  done < "$WORK/media"
  if (( ${#seen[@]} )); then
    mapfile -t GUESS_YEARS < <(printf '%s\n' "${!seen[@]}" | sort)
  fi
}

gm_set_all_years() {
  TRACK_ALL=1
  TRACK_YEAR=()
  TRACK_SPAN="all"
}

gm_set_year_span() {
  local a="$1" b="$2" y
  TRACK_ALL=0
  TRACK_YEAR=()
  for (( y = 10#$a; y <= 10#$b; y++ )); do
    TRACK_YEAR[$y]=1
  done
  if (( 10#$a == 10#$b )); then
    TRACK_SPAN="$a"
  else
    TRACK_SPAN="${a}-${b}"
  fi
}

gm_set_guess_years() {
  local y
  TRACK_ALL=0
  TRACK_YEAR=()
  for y in "$@"; do
    TRACK_YEAR[$y]=1
  done
  TRACK_SPAN="$(gm_year_phrase "$@")"
}

gm_ask_typed_year() {
  local typed out rc a b
  while true; do
    printf 'Year: '
    IFS= read -r typed || gm_quit
    typed="${typed#"${typed%%[![:space:]]*}"}"
    typed="${typed%"${typed##*[![:space:]]}"}"
    if [[ -z "$typed" ]]; then
      echo "Type a year, or a range such as 2026-2027."
      continue
    fi
    if [[ "${typed,,}" == q ]]; then
      gm_quit
    fi
    if out=$(python3 "$PY_HELPER" year-range "$typed" 2>/dev/null); then
      IFS=$'\t' read -r a b <<< "$out"
      gm_set_year_span "$a" "$b"
      return 0
    fi
    rc=$?
    if (( rc == 2 )); then
      echo "The first year is newer than the second."
    else
      echo "That is not a year or a range. Examples: 2026, 2026-2027, 2026 2027."
    fi
  done
}

gm_ask_track_years() {
  local reply phrase
  gm_guess_media_years
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    if (( ${#GUESS_YEARS[@]} )); then
      gm_set_guess_years "${GUESS_YEARS[@]}"
      echo "$(gm_ts) The photos and videos look like they are probably from ${TRACK_SPAN}, judging by the timestamps and file names."
    else
      gm_set_all_years
      echo "$(gm_ts) Tracks: all years."
    fi
    return 0
  fi
  echo
  if (( ${#GUESS_YEARS[@]} )); then
    phrase="$(gm_year_phrase "${GUESS_YEARS[@]}")"
    echo "The photos and videos look like they are probably from ${phrase}, judging by the timestamps and file names."
    echo "  [Y] ${phrase} only (default)"
    echo "  [t] Type a year"
    echo "  [a] All years"
    echo "  [q] Quit"
    gm_read_key "Which tracks? [Y/t/a/q]: " y
    reply="$REPLY"
    case "$reply" in
      y) gm_set_guess_years "${GUESS_YEARS[@]}" ;;
      t) gm_ask_typed_year ;;
      a) gm_set_all_years ;;
      q) gm_quit ;;
      *) echo "$(gm_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
    esac
  else
    echo "No year in these file names."
    echo "  [A] All years (default)"
    echo "  [t] Type a year"
    echo "  [q] Quit"
    gm_read_key "Which tracks? [A/t/q]: " a
    reply="$REPLY"
    case "$reply" in
      a) gm_set_all_years ;;
      t) gm_ask_typed_year ;;
      q) gm_quit ;;
      *) echo "$(gm_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
    esac
  fi
}

gm_say_geotag_need() {
  local need="$1" already="$2" unread="$3" line
  if (( need == 1 )); then
    line="1 file needs geotagging."
  else
    line="${need} files need geotagging."
  fi
  if (( already == 1 )); then
    line="${line} 1 already has a location."
  else
    line="${line} ${already} already have a location."
  fi
  echo "$(gm_ts) ${line}"
  if (( unread == 1 )); then
    echo "$(gm_ts) 1 file could not be read."
  elif (( unread > 0 )); then
    echo "$(gm_ts) ${unread} files could not be read."
  fi
}

gm_collect_media() {
  local path parent
  WORK=$(mktemp -d)
  : > "$WORK/media"
  : > "$WORK/gpx"
  : > "$WORK/roots"
  : > "$WORK/confs"
  MEDIA_N=0
  GPX_N=0
  for path in "${DIR_INPUTS[@]}"; do
    gm_add_root "$path"
    gm_walk "$path" "$RECURSE" media
  done
  for path in "${FILE_INPUTS[@]}"; do
    parent="$(dirname -- "$path")"
    gm_add_root "$parent"
    gm_consider_file "$path" media
  done
}

gm_collect_tracks() {
  local path parent
  gm_ask_track_years
  for path in "${DIR_INPUTS[@]}"; do
    gm_walk "$path" "$RECURSE" gpx
  done
  for path in "${FILE_INPUTS[@]}"; do
    parent="$(dirname -- "$path")"
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
  gm_find_confs
  gm_add_conf_tracks
}

gm_note_conf_dir() {
  local dir="$1" rp f
  [[ -n "$dir" && -d "$dir" ]] || return 0
  rp="$(readlink -f -- "$dir" 2>/dev/null || printf '%s' "$dir")"
  [[ -n "${SEEN_CONF_DIR[$rp]:-}" ]] && return 0
  SEEN_CONF_DIR[$rp]=1
  f="${rp}/${CONF_NAME}"
  [[ -f "$f" ]] || return 0
  printf '%s\0' "$f" >> "$WORK/confs"
}

gm_find_confs() {
  local dir
  : > "$WORK/confs"
  for dir in /etc "${HOME:-}" "${HOME:-}/etc" "${HOME:-}/conf"; do
    gm_note_conf_dir "$dir"
  done
  if [[ -n "${profile_location_dir:-}" ]]; then
    gm_note_conf_dir "${profile_location_dir}/etc"
    gm_note_conf_dir "${profile_location_dir}/conf"
    gm_note_conf_dir "${profile_location_dir}"
  fi
}

gm_add_conf_tracks() {
  local path f base ext n_here
  [[ -s "$WORK/confs" ]] || return 0
  python3 "$PY_HELPER" track-roots --conf-list "$WORK/confs" > "$WORK/track-roots" || {
    echo "ERROR: could not read [tracks-location] from the .conf files." >&2
    return_code=1
    exit 1
  }
  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -n "$path" ]] || continue
    if [[ -d "$path" ]]; then
      path="$(readlink -f -- "$path" 2>/dev/null || printf '%s' "$path")"
      gm_add_root "$path"
      n_here=0
      while IFS= read -r -d '' f; do
        base="${f##*/}"
        gm_skip_name "$base" && continue
        ext="${base##*.}"
        ext="${ext,,}"
        if [[ "$ext" == gpx || "$ext" == tcx ]]; then
          gm_add_gpx "$f" && n_here=$(( n_here + 1 ))
        fi
      done < <(find "$path" \( -type d -name '.*' -prune \) -o -type f -print0)
      if (( TRACK_ALL )); then
        echo "$(gm_ts) ${path}: ${n_here} .gpx/.tcx files, including every subdirectory"
      else
        echo "$(gm_ts) ${path}: ${n_here} .gpx/.tcx files from ${TRACK_SPAN}, including every subdirectory"
      fi
    elif [[ -f "$path" ]]; then
      path="$(readlink -f -- "$path" 2>/dev/null || printf '%s' "$path")"
      gm_add_root "$(dirname -- "$path")"
      gm_add_gpx "$path"
      echo "$(gm_ts) Track file: ${path}"
    fi
  done < "$WORK/track-roots"
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

gm_load_plan() {
  local kind a b c d e f g h
  PLACE_LABEL=()
  PLACE_LAT=()
  PLACE_LON=()
  CHOOSE_PATH=()
  CHOOSE_KIND=()
  CHOOSE_SHOW=()
  CHOOSE_DATE=()
  CHOOSE_TIME=()
  WRITE_PATH=()
  WRITE_LABEL=()
  WRITE_PLACE=()
  WRITE_HEIGHT=()
  WRITE_GAP=()
  WRITE_TRACK=()
  WRITE_METHOD=()
  WRITE_STATUS=()
  while IFS=$'\t' read -r kind a b c d e f g h; do
    [[ -n "$kind" ]] || continue
    case "$kind" in
      PLACE)
        PLACE_LABEL+=("$a")
        PLACE_LAT+=("$b")
        PLACE_LON+=("$c")
        ;;
      WRITE)
        WRITE_PATH+=("$a")
        WRITE_LABEL+=("$b")
        WRITE_PLACE+=("$c")
        WRITE_HEIGHT+=("$d")
        WRITE_GAP+=("$e")
        WRITE_TRACK+=("$f")
        WRITE_METHOD+=("$g")
        WRITE_STATUS+=("$h")
        ;;
      CHOOSE)
        CHOOSE_PATH+=("$a")
        CHOOSE_KIND+=("$b")
        CHOOSE_SHOW+=("$c")
        CHOOSE_DATE+=("$d")
        CHOOSE_TIME+=("$e")
        ;;
    esac
  done < <(python3 "$PY_HELPER" plan-lines --plan "$1")
}

gm_ask_track_writes() {
  local i reply loc lat lon rest
  rest=0
  : > "$WORK/write-only"
  gm_ask_internet
  for i in "${!WRITE_PATH[@]}"; do
    echo
    lat="${WRITE_PLACE[$i]%%,*}"
    lon="${WRITE_PLACE[$i]#*,}"
    lon="${lon#"${lon%%[![:space:]]*}"}"
    loc="${WRITE_PLACE[$i]}"
    if [[ -n "${WRITE_HEIGHT[$i]}" ]]; then
      loc="${loc}, ${WRITE_HEIGHT[$i]}"
    fi
    if [[ "${WRITE_STATUS[$i]}" == replace ]]; then
      echo "${WRITE_LABEL[$i]} already has a location."
      echo "A point in ${WRITE_TRACK[$i]} is ${WRITE_GAP[$i]} away, so that location can probably replace it."
    else
      echo "${WRITE_LABEL[$i]} has no geotag."
      echo "It can probably be geotagged from ${WRITE_TRACK[$i]}, because the nearest point is ${WRITE_GAP[$i]} away and that point has a location."
    fi
    echo "  ${loc}"
    if [[ -n "$lat" && -n "$lon" ]]; then
      gm_lookup_place "$lat" "$lon"
    fi
    echo "  GPSProcessingMethod ${WRITE_METHOD[$i]}"
    if (( rest )); then
      echo "Writing this one too."
      printf '%s\0' "${WRITE_PATH[$i]}" >> "$WORK/write-only"
      continue
    fi
    echo
    echo "  [y] Write this"
    echo "  [N] Skip this file (default)"
    echo "  [a] Write this and the rest"
    echo "  [q] Quit"
    gm_read_key "Write this location? [y/N/a/q]: " n
    reply="$REPLY"
    case "$reply" in
      y) printf '%s\0' "${WRITE_PATH[$i]}" >> "$WORK/write-only" ;;
      a)
        printf '%s\0' "${WRITE_PATH[$i]}" >> "$WORK/write-only"
        rest=1
        ;;
      q) gm_quit ;;
    esac
  done
  if [[ -s "$WORK/write-only" ]]; then
    WRITE_TRACKS=1
  else
    echo "$(gm_ts) Those track matches were not written."
  fi
}

gm_choose_places() {
  local i n reply picked
  if (( ${#CHOOSE_SHOW[@]} == 0 )); then
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    echo
    echo "$(gm_ts) ${#CHOOSE_SHOW[@]} file$( (( ${#CHOOSE_SHOW[@]} == 1 )) || printf 's' ) have no track point. A place is written only when you pick it."
    return 0
  fi
  echo
  echo "These files have no GPX or TCX point close enough."
  gm_ask_internet
  for i in "${!CHOOSE_SHOW[@]}"; do
    echo
    echo "${CHOOSE_SHOW[$i]}"
    for n in "${!PLACE_LABEL[@]}"; do
      printf '  [%d] [%s]   %s, %s\n' "$(( n + 1 ))" "${PLACE_LABEL[$n]}" "${PLACE_LAT[$n]}" "${PLACE_LON[$n]}"
    done
    echo "  [g] Type a latitude, longitude for this file"
    echo "  [S] Skip this file (default)"
    echo "  [q] Quit now, without Enter"
    gm_read_place_choice "Place for ${CHOOSE_SHOW[$i]}? [S]: "
    reply="$REPLY"
    if [[ "$reply" == s ]]; then
      continue
    fi
    if [[ "$reply" == g ]]; then
      if gm_ask_coord; then
        gm_describe_coord "$GM_LAT" "$GM_LON"
        gm_write_chosen "$GM_LAT" "$GM_LON" "$GM_PLACE" "$i"
      fi
      continue
    fi
    if canon=$(python3 "$PY_HELPER" check-coord "$reply" 2>/dev/null); then
      IFS=$'\t' read -r GM_LAT GM_LON <<< "$canon"
      gm_describe_coord "$GM_LAT" "$GM_LON"
      gm_write_chosen "$GM_LAT" "$GM_LON" "$GM_PLACE" "$i"
      continue
    fi
    if [[ "$reply" =~ ^[0-9]+$ ]] && (( 10#$reply >= 1 && 10#$reply <= ${#PLACE_LABEL[@]} )); then
      picked=$(( 10#$reply - 1 ))
      gm_write_chosen "${PLACE_LAT[$picked]}" "${PLACE_LON[$picked]}" "${PLACE_LABEL[$picked]}" "$i"
    else
      echo "That is not one of the places. This file was skipped."
    fi
  done
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
VERBOSE=0
VERBOSE_SET=0
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
declare -A SEEN_CONF_DIR=()
PY_HELPER="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/video-pgm-geotag-missing-media.py"
CONF_NAME="$(basename -- "${BASH_SOURCE[0]}" .sh).conf"
PLACE_LABEL=()
PLACE_LAT=()
PLACE_LON=()
CHOOSE_PATH=()
CHOOSE_KIND=()
CHOOSE_SHOW=()
CHOOSE_DATE=()
CHOOSE_TIME=()
USE_NET=-1
GM_LOOKED=0
GM_PLACE="typed"
PLACE_WROTE=0
SUM_READY=0
SUM_FILES=0
SUM_ALREADY=0
SUM_UNMATCHED=0
SUM_UNREAD=0
SUM_TRACKS=0
SUM_POINTS=0
SUM_WROTE=0
GM_SUMMARY=0
GM_SUMMARY_DONE=0
GM_START_NS=""
GM_PROC_SEC=0
GM_PROC_SLICE=""
TRACK_ALL=0
TRACK_SPAN=""
GUESS_YEARS=()
declare -A TRACK_YEAR=()
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

trap gm_on_exit EXIT
trap gm_ctrl_c INT

gm_on_exit() {
  gm_print_summary
  gm_cleanup
}

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
    --verbose) VERBOSE=1; VERBOSE_SET=1; shift ;;
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
GM_START_NS="$(gm_now)"
GM_SUMMARY=1
gm_classify_inputs
gm_ask_verbose
gm_ask_scope
gm_ask_tz

gm_proc_begin
gm_collect_media
gm_proc_end

if (( MEDIA_N == 0 )); then
  echo "$(gm_ts) No photos or videos."
  return_code=0
  exit 0
fi

gm_proc_begin
GEO_OUT=$(python3 "$PY_HELPER" need-geotag \
  --exiftool "$EXIFTOOL_BIN" \
  --quicktime "$QUICKTIME" \
  --media-list "$WORK/media" \
  --exif-json "$WORK/exif.json") || {
  return_code=$?
  gm_proc_end
  exit "$return_code"
}
gm_proc_end
IFS=$'\t' read -r GEO_NEED GEO_ALREADY GEO_UNREAD <<< "$GEO_OUT"
gm_say_geotag_need "$GEO_NEED" "$GEO_ALREADY" "$GEO_UNREAD"
if (( GEO_NEED == 0 && ! REDO )); then
  echo "$(gm_ts) Tracks were not loaded."
else
  if (( GEO_NEED == 0 )); then
    echo "$(gm_ts) --redo will compare the files that already have a location."
  fi
  gm_proc_begin
  gm_collect_tracks
  gm_proc_end
fi

gm_heading "Geotag"
echo "  Files: ${MEDIA_N}    Tracks: ${GPX_N}"
echo "  Geotagged: ${GEO_ALREADY}    No location: ${GEO_NEED}"
if (( GEO_UNREAD > 0 )); then
  echo "  Could not read: ${GEO_UNREAD}"
fi
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
  --conf-list "$WORK/confs"
  --plan "$WORK/plan.json"
  --scope "$(gm_scope_label)"
  --track-span "$TRACK_SPAN"
  --exif-json "$WORK/exif.json"
)
if (( VERBOSE )); then
  SCAN_ARGS+=(--verbose)
fi
if (( TZ_ASSUMED )); then
  SCAN_ARGS+=(--tz-assumed)
fi
if (( REDO )); then
  SCAN_ARGS+=(--redo)
fi

gm_proc_begin
python3 "$PY_HELPER" "${SCAN_ARGS[@]}" || {
  return_code=$?
  exit "$return_code"
}
gm_proc_end

WRITE_N=$(gm_plan_count "$WORK/plan.json")
gm_load_plan "$WORK/plan.json"
WRITE_TRACKS=0

if (( DRY_RUN )); then
  echo
  echo "$(gm_ts) Dry run. Nothing written."
  return_code=0
  exit 0
fi

if (( WRITE_N == 0 && ${#CHOOSE_SHOW[@]} == 0 )); then
  echo
  echo "$(gm_ts) Nothing to write."
  return_code=0
  exit 0
fi

if (( WRITE_N > 0 )); then
  if (( DO_YES )); then
    WRITE_TRACKS=1
  elif (( ! script_is_run_interactively )); then
    echo
    echo "$(gm_ts) Not a terminal: nothing written. Add -y to write track matches without asking."
  else
    gm_ask_track_writes
  fi
  if (( WRITE_TRACKS )); then
    echo
    gm_proc_begin
    if [[ -s "${WORK}/write-only" ]]; then
      python3 "$PY_HELPER" write --exiftool "$EXIFTOOL_BIN" --plan "$WORK/plan.json" --only-list "$WORK/write-only" || return_code=$?
    else
      python3 "$PY_HELPER" write --exiftool "$EXIFTOOL_BIN" --plan "$WORK/plan.json" || return_code=$?
    fi
    gm_proc_end
  fi
fi

gm_choose_places
exit "$return_code"
