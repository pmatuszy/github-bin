#!/bin/bash
# v. 20261012.151324 - a track match can be written from a preconfigured location
# v. 20261012.145108 - an arrow key or other unknown key asks the same file again
# v. 20261012.144759 - b undoes the last answer and returns to the previous file
# v. 20261012.143755 - a finished file says how long that file took
# v. 20261012.141100 - finish stops the place questions as well as the track questions
# v. 20261012.140006 - the nearest track point can be shown on a map, and place coordinates line up
# v. 20261012.135005 - a write line starts with the time, and the place name follows the coordinates
# v. 20261012.133815 - q asks whether to keep the files already accepted
# v. 20261012.133701 - reuse offers the last selected place, or a point that was typed
# v. 20261012.133132 - all subdirectories is the default directory search
# v. 20261012.131113 - a chosen location is called a manual entry
# v. 20261012.130927 - track files and chosen places are counted apart, with the address on its own line
# v. 20261012.130730 - each file says when processing starts and when it is complete
# v. 20261012.130522 - backup names are listed only in verbose mode
# v. 20261012.125257 - f stops the questions and keeps only the files already accepted
# v. 20261012.123248 - place choices are written only after the update question
# v. 20261012.123123 - the place question prints the option that was chosen
# v. 20261012.123004 - a file named like a screenshot is skipped, judging by the name
# v. 20261012.122840 - the backup question is the last one, just before the files are changed
# v. 20261012.122556 - the backup choice names the file it will be stored as
# v. 20261012.122130 - the update question follows the backup answer with no blank line
# v. 20261012.122058 - the run summary has no timestamp on each line
# v. 20261012.121909 - confirm the update, and keep a dated backup only when asked
# v. 20261012.121627 - the next file can reuse a latitude and longitude that was typed earlier
# v. 20261012.121328 - a typed latitude and longitude gets the same map links as a track point
# v. 20261012.120912 - files are updated only after the answers, and each copy checks free space plus 10%
# v. 20261012.115248 - each track point also lists Google, OpenStreetMap, Apple, and Microsoft map links
# v. 20261012.114548 - each track write is a short table of file, track, location, and place
# v. 20261012.114450 - the repeated command is introduced as the command-line equivalent
# v. 20261012.114402 - the chosen answer prints on the line under the question
# v. 20261012.114225 - the colors question is only yes, no, or quit
# v. 20261012.114001 - Enter writes the track location; n skips that file
# v. 20261012.113554 - ask about colors; file names are green, and a location is blue
# v. 20261012.113057 - the place question does not repeat the file count
# v. 20261012.112954 - Enter prints the option that was chosen
# v. 20261012.112620 - [d] is smart loading with the days you choose
# v. 20261012.112532 - each file you are asked to write is numbered, such as [1/22]
# v. 20261012.112235 - after the questions, print the command that repeats those answers
# v. 20261012.111650 - smart loading, days before and after, a year, and all years are command-line options
# v. 20261012.111440 - smart loading can use a chosen number of days before and after
# v. 20261012.111223 - smart loading reads tracks from a week before the first file to a week after the last
# v. 20261012.110839 - a looked-up place is described as near that street and town
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

# 2026.10.12 - v. 0.68 - a track match can be written from a preconfigured location
# 2026.10.12 - v. 0.67 - an arrow key or other unknown key asks the same file again
# 2026.10.12 - v. 0.66 - b undoes the last answer and returns to the previous file
# 2026.10.12 - v. 0.65 - a finished file says how long that file took
# 2026.10.12 - v. 0.64 - finish stops the place questions as well as the track questions
# 2026.10.12 - v. 0.63 - the nearest track point can be shown on a map, and place coordinates line up
# 2026.10.12 - v. 0.62 - a write line starts with the time, and the place name follows the coordinates
# 2026.10.12 - v. 0.61 - q asks whether to keep the files already accepted
# 2026.10.12 - v. 0.60 - reuse offers the last selected place, or a point that was typed
# 2026.10.12 - v. 0.59 - all subdirectories is the default directory search
# 2026.10.12 - v. 0.58 - a chosen location is called a manual entry
# 2026.10.12 - v. 0.57 - track files and chosen places are counted apart, with the address on its own line
# 2026.10.12 - v. 0.56 - each file says when processing starts and when it is complete
# 2026.10.12 - v. 0.55 - backup names are listed only in verbose mode
# 2026.10.12 - v. 0.54 - f stops the questions and keeps only the files already accepted
# 2026.10.12 - v. 0.53 - place choices are written only after the update question
# 2026.10.12 - v. 0.52 - the place question prints the option that was chosen
# 2026.10.12 - v. 0.51 - a file named like a screenshot is skipped, judging by the name
# 2026.10.12 - v. 0.50 - the backup question is the last one, just before the files are changed
# 2026.10.12 - v. 0.49 - the backup choice names the file it will be stored as
# 2026.10.12 - v. 0.48 - the update question follows the backup answer with no blank line
# 2026.10.12 - v. 0.47 - the run summary has no timestamp on each line
# 2026.10.12 - v. 0.46 - confirm the update, and keep a dated backup only when asked
# 2026.10.12 - v. 0.45 - the next file can reuse a latitude and longitude that was typed earlier
# 2026.10.12 - v. 0.44 - a typed latitude and longitude gets the same map links as a track point
# 2026.10.12 - v. 0.43 - files are updated only after the answers, and each copy checks free space plus 10%
# 2026.10.12 - v. 0.42 - each track point also lists Google, OpenStreetMap, Apple, and Microsoft map links
# 2026.10.12 - v. 0.41 - each track write is a short table of file, track, location, and place
# 2026.10.12 - v. 0.40 - the repeated command is introduced as the command-line equivalent
# 2026.10.12 - v. 0.39 - the chosen answer prints on the line under the question
# 2026.10.12 - v. 0.38 - the colors question is only yes, no, or quit
# 2026.10.12 - v. 0.37 - Enter writes the track location; n skips that file
# 2026.10.12 - v. 0.36 - ask about colors; file names are green, and a location is blue
# 2026.10.12 - v. 0.35 - the place question does not repeat the file count
# 2026.10.12 - v. 0.34 - Enter prints the option that was chosen
# 2026.10.12 - v. 0.33 - [d] is smart loading with the days you choose
# 2026.10.12 - v. 0.32 - each file you are asked to write is numbered, such as [1/22]
# 2026.10.12 - v. 0.31 - after the questions, print the command that repeats those answers
# 2026.10.12 - v. 0.30 - smart loading, days before and after, a year, and all years are command-line options
# 2026.10.12 - v. 0.29 - smart loading can use a chosen number of days before and after
# 2026.10.12 - v. 0.28 - smart loading reads tracks from a week before the first file to a week after the last
# 2026.10.12 - v. 0.27 - a looked-up place is described as near that street and town
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
       [-y|--yes] [-n|--dry-run] [--redo] [--verbose] [--colors yes|no]
       [--internet yes|no] [--backup | --no-backup]
       [--here | --recursive]
       [--tz OFFSET|auto] [--max-gap SECONDS] [--quicktime utc|local]
       [--gpx FILE|DIR ...]
       [--smart] [--days-before N] [--days-after N]
       [--year YEAR|RANGE] [--all-years] [--screenshots]
       [FILE|DIR ...]

Report which photos and videos have a location, and which do not. With no
FILE or DIR, the current directory is used. [A] includes its subdirectories.
[c] keeps that directory only. Windows paths such as P:\\video\\trip are
read as /mnt/p/video/trip.

The first question is whether to use colors. The default is yes. --colors no
turns that off. The next question is whether to list every track and every
photo or video. The default is no: the report then gives the counts.
--verbose lists each one. -y does not ask. It stays with the totals, and
with colors on.

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

A file whose name contains screenshot is skipped. That covers names such as
WhatsApp-screenshot and Signal-screenshot. The script says the file is
skipped because it is a screenshot, judging by the name. --screenshots
keeps those files.

Each file is shown first. Nothing is written until those answers are done.
Enter accepts that file. n skips it. a accepts that file and the rest.
b undoes the last answer and returns to the previous file.
f stops the questions and keeps only the files already accepted. The file
on screen is not included, and files with no close track point are not asked. q asks whether to quit without writing, or to
update the files already accepted. The default is to quit and write nothing. Then you are asked whether to update
the chosen files. The default is yes. Just before the files are changed, a
backup of each old file can be kept. The default is no. A backup is stored
as that file's name with _old- and the current date and time. --backup
keeps one. --no-backup does not. Each one is copied aside, which can take a
while. The copy needs free space for the file plus 10%. --internet yes or no
looks up place names without asking. The default is yes. Each file is numbered, such as [1/22], and shown as a
short table: the file, the track, the gap, the location, map links, and the
place name. Preconfigured locations are listed under that point. A number
writes that place instead of the track point. -n prints the report and stops. -y writes the track matches
without asking. A file that already has a location is left as it is, unless
--redo is given and a point is close enough. The write goes through
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
the timestamps and file names. The default is smart loading: one week before
the earliest file through one week after the latest. --smart does that
without asking. --days-before and --days-after change those two sides. A
side you leave out stays at 7. [d] is smart loading with the days you type.
One number is both
sides, such as 3. Two numbers are before, then after, such as 3 14.
--year 2026, or --year 2026-2027, loads only those years. [y] keeps the
year from the file names. [t] asks for a year or a range, such as 2026-2027,
2026 - 2027, or 2026 2027. --all-years loads every year.
The first year must not be newer than the second. After those answers, the
script prints how to run the same thing from the command line. Only those tracks
are read, from that directory and from the tracks next to the photos and
videos. The count printed before the report is that set. Tracks are read
only when a photo or video still has no location. The script says how many
need geotagging, and how many already have a location, before that read.

  [tracks-location]
  /mnt/p/video/geotaging-kopie

For each file with no track point you are asked which name to write. The
nearest track point is shown when it is too far, and m prints map links for
that point without writing it. The question lists every key it accepts. q quits
at once, without Enter. g asks for a latitude and longitude for that file
only, and shows the same map links as a track point. The next file can reuse
that point with r. Before the first track point or typed place, you are asked
once whether to look the point up on OpenStreetMap. The default is yes. If
OpenStreetMap cannot be reached, the coordinates are still written and later
points are not looked up. A place you pick or type is marked MANUAL. A point from a GPX or
TCX file is marked TRACK. Both are stored in GPSProcessingMethod. -y does not
pick a place for
you.

Video CreateDate is read as UTC, which is right for a GoPro. If a phone
stored local time in that field, use --quicktime local.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask. Subdirectories too, unless --here.
                       Camera offset +02:00 when --tz is omitted. Write every
                       match.
  -n, --dry-run        Print the report. Write nothing.
  --redo               Write again over a location that is already there,
                       when a track point is close enough.
  --colors yes|no      File names in green. Latitude, longitude, and height
                       in blue. Default yes. Do not ask.
  --internet yes|no    Look up a place name. Default yes. Do not ask.
  --backup             Keep each old file as name_old-YYYYMMDD_HHMMSS.
                       Do not ask.
  --no-backup          Do not keep a backup. Default. Do not ask.
  --screenshots        Also geotag a file whose name contains screenshot.
                       By default that file is skipped.
  --here               This directory only. Do not ask.
  --recursive          This directory and its subdirectories. Default. Do not ask.
  --tz OFFSET|auto     Camera clock minus UTC. Examples: +02:00, -05:30, 0.
                       auto: learn it from files that already have a GPS time.
  --max-gap SECONDS    How close in time a track point must be. Default 30.
  --quicktime utc|local
                       How to read a video CreateDate. Default utc.
  --gpx FILE|DIR       More tracks, .gpx or .tcx. Repeat for more than one.
                       A directory is read with its subdirectories.
  --smart              One week before the first file through one week
                       after the last. Do not ask.
  --days-before N      Days before the first file. The other side stays
                       7 unless --days-after is also given. Do not ask.
  --days-after N       Days after the last file. The other side stays
                       7 unless --days-before is also given. Do not ask.
  --year YEAR|RANGE    Only that year, or a range such as 2026-2027.
                       A list with a gap: 2026,2028. Do not ask.
  --all-years          Every year in the track directories. Do not ask.

Needs: python3, and exiftool (video-pgm-install-exiftool.sh). The helper
video-pgm-geotag-missing-media.py has its own selftest.

Examples:
  $(basename "$0")
      Current directory and its subdirectories. Report, then ask before writing.
  $(basename "$0") -n /mnt/p/video/trip
      Report that directory. Write nothing.
  $(basename "$0") -y --tz +02:00 /mnt/p/video/trip
      Subdirectories too. Write every close match. Camera clock is +02:00.
  $(basename "$0") --gpx /mnt/p/tracks/day.gpx --here /mnt/p/video/trip
      Use that GPX as well as any .gpx or .tcx beside the videos.
  $(basename "$0") --gpx /mnt/p/tracks/ride.tcx /mnt/p/video/trip
      Use that TCX file as the track.
  $(basename "$0") --days-before 3 --days-after 14 /mnt/p/video/trip
      Smart loading, 3 days before the first file and 14 days after the last.
  $(basename "$0") --year 2026-2027 --here /mnt/p/video/trip
      Only tracks whose names start in 2026 or 2027.
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
  printf '  %-*s  %s\n' 28 "${1}:" "$2"
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
    (( PLACE_WROTE > 0 )) && { labels+=("Tagged by manual entry"); nums+=("$PLACE_WROTE"); }
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
  echo "--- Run summary ---"
  local i
  for i in "${!labels[@]}"; do
    printf '  %-*s  %*s\n' 28 "${labels[$i]}:" "$width" "$(gm_fmt_int "${nums[$i]}")"
  done
  echo
  echo "--- Timing ---"
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
  C_B="" C_DIM="" C_G="" C_Y="" C_R="" C_C="" C_BL="" C_0=""
  if (( USE_COLOR )) && [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_B=$'\e[1m'
    C_DIM=$'\e[2m'
    C_G=$'\e[32m'
    C_Y=$'\e[33m'
    C_R=$'\e[31m'
    C_C=$'\e[36m'
    C_BL=$'\e[94m'
    C_0=$'\e[0m'
  fi
}

gm_green() {
  printf '%s%s%s' "$C_G" "$1" "$C_0"
}

gm_blue() {
  printf '%s%s%s' "$C_BL" "$1" "$C_0"
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
  while true; do
  printf '%s' "$prompt"
  while IFS= read -r -t 0.02 -n 1 discard; do :; done
  IFS= read -r -n 1 first || first=""
  if [[ "$first" == $'\e' ]]; then
    gm_swallow_escape
    echo
    echo "That is not a choice."
    continue
  fi
  break
  done
  first="${first,,}"
  if [[ "$first" == q ]]; then
    echo
    printf '  [q] Quit now, without Enter\n'
    REPLY=q
    return 0
  fi
  if [[ -z "$first" || "$first" == $'\n' ]]; then
    printf '  [S] Skip this file\n'
    REPLY=s
    return 0
  fi
  if [[ "$first" == s ]]; then
    echo
    printf '  [S] Skip this file\n'
    REPLY=s
    return 0
  fi
  if [[ "$first" == r ]]; then
    echo
    if [[ -n "$GM_LAST_LAT" && -n "$GM_LAST_LON" ]]; then
      printf '  [r] %s\n' "$(gm_reuse_text)"
    else
      printf '  [r] Reuse the previous latitude and longitude\n'
    fi
    REPLY=r
    return 0
  fi
  if [[ "$first" == g ]]; then
    echo
    printf '  [g] Type a latitude, longitude for this file\n'
    REPLY=g
    return 0
  fi
  if [[ "$first" == m ]]; then
    echo
    printf '  [m] Show map links for the nearest track point\n'
    REPLY=m
    return 0
  fi
  if [[ "$first" == f ]]; then
    echo
    printf '  [f] Finish. Write only the files already accepted\n'
    REPLY=f
    return 0
  fi
  if [[ "$first" == b ]]; then
    echo
    printf '  [b] Undo the last answer and back to the previous file\n'
    REPLY=b
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
  gm_read_key "Look up place names on the internet? [Y/n/q]: " y "Yes, use the internet"
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
    if [[ "${3:-}" != quiet ]]; then
      echo "This is near ${name}."
    fi
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
  gm_lookup_place "$1" "$2" quiet
  if [[ -n "$GM_PLACE_NAME" ]]; then
    GM_PLACE="$GM_PLACE_NAME"
  fi
  echo
  gm_write_row "Location" "$(gm_blue "$1, $2")"
  gm_map_rows "$1" "$2"
  gm_write_row "Description" "$GM_PLACE_NAME"
}

gm_remember_coord() {
  GM_LAST_LAT="$1"
  GM_LAST_LON="$2"
  GM_LAST_WHAT="$3"
}

gm_reuse_text() {
  printf 'Reuse the previous latitude and longitude: [%s] %s' "$GM_LAST_WHAT" "$(gm_blue "${GM_LAST_LAT}, ${GM_LAST_LON}")"
}

gm_use_typed() {
  gm_remember_coord "$GM_LAT" "$GM_LON" "manually entered"
  gm_describe_coord "$GM_LAT" "$GM_LON"
  gm_write_chosen "$GM_LAT" "$GM_LON" "$GM_PLACE" "$1"
}

gm_ask_coord() {
  local typed canon
  while true; do
    printf 'Latitude, longitude (for example 49.590789, 19.966572), or Enter to skip: '
    IFS= read -r typed || { echo "$(gm_ts) Quit."; return_code=0; exit 0; }
    typed="${typed#"${typed%%[![:space:]]*}"}"
    typed="${typed%"${typed##*[![:space:]]}"}"
    if [[ -z "$typed" ]]; then
      echo "  Skip this file"
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
  PLACE_Q_LAT+=("$1")
  PLACE_Q_LON+=("$2")
  PLACE_Q_NAME+=("$3")
  PLACE_Q_I+=("$4")
}

gm_flush_places() {
  local n i lat lon place
  local -a place_args
  for n in "${!PLACE_Q_I[@]}"; do
    i="${PLACE_Q_I[$n]}"
    lat="${PLACE_Q_LAT[$n]}"
    lon="${PLACE_Q_LON[$n]}"
    place="${PLACE_Q_NAME[$n]}"
    if (( n > 0 )); then
      echo
    fi
    gm_proc_begin
    place_args=(
      write-place
      --exiftool "$EXIFTOOL_BIN"
      --path "${CHOOSE_PATH[$i]}"
      --kind "${CHOOSE_KIND[$i]}"
      --lat "$lat"
      --lon "$lon"
      --gps-date "${CHOOSE_DATE[$i]}"
      --gps-time "${CHOOSE_TIME[$i]}"
      --label "${CHOOSE_SHOW[$i]}"
      --place "$place"
      --number "$(( n + 1 ))"
      --total "${#PLACE_Q_I[@]}"
    )
    if (( USE_COLOR )); then
      place_args+=(--colors)
    fi
    if (( VERBOSE )); then
      place_args+=(--verbose)
    fi
    if (( BACKUP == 1 )); then
      place_args+=(--backup --backup-stamp "$BACKUP_STAMP")
    fi
    if python3 "$PY_HELPER" "${place_args[@]}"; then
      PLACE_WROTE=$(( PLACE_WROTE + 1 ))
    else
      return_code=$?
    fi
    gm_proc_end
  done
}

gm_flush_track_places() {
  local n path label lat lon place kind
  local -a place_args
  for n in "${!TRACK_MANUAL_PATH[@]}"; do
    path="${TRACK_MANUAL_PATH[$n]}"
    label="${TRACK_MANUAL_LABEL[$n]}"
    lat="${TRACK_MANUAL_LAT[$n]}"
    lon="${TRACK_MANUAL_LON[$n]}"
    place="${TRACK_MANUAL_NAME[$n]}"
    case "${path,,}" in
      *.mp4|*.mov) kind=video ;;
      *) kind=photo ;;
    esac
    if (( n > 0 )); then
      echo
    fi
    gm_proc_begin
    place_args=(
      write-place
      --exiftool "$EXIFTOOL_BIN"
      --path "$path"
      --kind "$kind"
      --lat "$lat"
      --lon "$lon"
      --label "$label"
      --place "$place"
      --number "$(( n + 1 ))"
      --total "${#TRACK_MANUAL_PATH[@]}"
    )
    if (( USE_COLOR )); then
      place_args+=(--colors)
    fi
    if (( VERBOSE )); then
      place_args+=(--verbose)
    fi
    if (( BACKUP == 1 )); then
      place_args+=(--backup --backup-stamp "$BACKUP_STAMP")
    fi
    if python3 "$PY_HELPER" "${place_args[@]}"; then
      PLACE_WROTE=$(( PLACE_WROTE + 1 ))
    else
      return_code=$?
    fi
    gm_proc_end
  done
}

gm_swallow_escape() {
  local next=""
  IFS= read -r -t 0.05 -n 1 next || return 0
  if [[ "$next" == "[" ]]; then
    while IFS= read -r -t 0.05 -n 1 next; do
      [[ "$next" =~ [A-Za-z~] ]] && return 0
    done
  elif [[ "$next" == "O" ]]; then
    IFS= read -r -t 0.05 -n 1 next || true
  fi
}

gm_read_key() {
  local prompt="$1" default_key="${2:-}" chosen="${3:-}" answer="" discard
  while true; do
    printf '%s' "$prompt"
    while IFS= read -r -t 0.02 -n 1 discard; do :; done
    IFS= read -r -n 1 answer || answer=""
    if [[ "$answer" == $'\e' ]]; then
      gm_swallow_escape
      echo
      echo "That is not a choice."
      continue
    fi
    break
  done
  answer="${answer,,}"
  if [[ -z "$answer" && -n "$chosen" ]]; then
    printf '  [%s] %s\n' "${default_key^^}" "$chosen"
  else
    echo
  fi
  REPLY="${answer:-$default_key}"
}

gm_read_track_choice() {
  local prompt="$1" default_key="${2:-}" chosen="${3:-}" first="" rest="" discard
  while true; do
    printf '%s' "$prompt"
    while IFS= read -r -t 0.02 -n 1 discard; do :; done
    IFS= read -r -n 1 first || first=""
    if [[ "$first" == $'\e' ]]; then
      gm_swallow_escape
      echo
      echo "That is not a choice."
      continue
    fi
    break
  done
  if [[ -z "$first" || "$first" == $'\n' ]]; then
    printf '  [%s] %s\n' "${default_key^^}" "$chosen"
    REPLY="$default_key"
    return 0
  fi
  echo
  if [[ "$first" =~ [0-9] ]]; then
    IFS= read -r rest || rest=""
    REPLY="${first}${rest}"
    REPLY="${REPLY#"${REPLY%%[![:space:]]*}"}"
    REPLY="${REPLY%"${REPLY##*[![:space:]]}"}"
    return 0
  fi
  REPLY="${first,,}"
}

gm_track_prompt() {
  local has_back="$1" n count
  local -a keys=()
  count=${#PLACE_LABEL[@]}
  if (( count == 1 )); then
    keys+=(1)
  elif (( count > 1 && count <= 6 )); then
    for (( n = 1; n <= count; n++ )); do
      keys+=("$n")
    done
  elif (( count > 6 )); then
    keys+=("1-${count}")
  fi
  keys+=(Y n a)
  if [[ "$has_back" == yes ]]; then
    keys+=(b)
  fi
  keys+=(f q)
  local IFS=/
  printf '[%s]' "${keys[*]}"
}

gm_note_track_place() {
  TRACK_MANUAL_PATH+=("$1")
  TRACK_MANUAL_LABEL+=("$2")
  TRACK_MANUAL_LAT+=("$3")
  TRACK_MANUAL_LON+=("$4")
  TRACK_MANUAL_NAME+=("$5")
}

gm_undo_track_place() {
  local path="$1" n
  n=${#TRACK_MANUAL_PATH[@]}
  (( n > 0 )) || return 0
  [[ "${TRACK_MANUAL_PATH[$(( n - 1 ))]}" == "$path" ]] || return 0
  unset "TRACK_MANUAL_PATH[$(( n - 1 ))]"
  unset "TRACK_MANUAL_LABEL[$(( n - 1 ))]"
  unset "TRACK_MANUAL_LAT[$(( n - 1 ))]"
  unset "TRACK_MANUAL_LON[$(( n - 1 ))]"
  unset "TRACK_MANUAL_NAME[$(( n - 1 ))]"
}

gm_quit() {
  echo "$(gm_ts) Quit. Nothing was written."
  return_code=0
  exit 0
}

gm_accepted_count() {
  local n=0 path
  if [[ -n "${WORK:-}" && -s "${WORK}/write-only" ]]; then
    while IFS= read -r -d '' path; do
      n=$(( n + 1 ))
    done < "${WORK}/write-only"
  fi
  n=$(( n + ${#PLACE_Q_I[@]} + ${#TRACK_MANUAL_PATH[@]} ))
  printf '%s\n' "$n"
}

gm_ask_quit_or_keep() {
  local n reply
  n="$(gm_accepted_count)"
  if (( n == 0 )); then
    gm_quit
  fi
  echo
  if (( n == 1 )); then
    echo "1 file is already accepted."
  else
    echo "$(gm_fmt_int "$n") files are already accepted."
  fi
  echo "  [Q] Quit, and write nothing (default)"
  echo "  [w] Update the files already accepted"
  gm_read_key "Quit now? [Q/w]: " q "Quit, and write nothing"
  reply="$REPLY"
  case "$reply" in
    q) gm_quit ;;
    w) GM_STOP_ASKING=1; return 0 ;;
    *) echo "$(gm_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
}

gm_skip_name() {
  local base="$1"
  [[ "$base" == ._* || "$base" == *_old-* || "$base" == *.partial || "$base" == *.partial.* ]]
}

gm_screenshot_name() {
  local base="${1,,}"
  [[ "$base" == *screenshot* ]]
}

gm_note_screenshot() {
  local path="$1" base
  base="$(basename -- "$path")"
  [[ -n "${SEEN_SCREENSHOT[$path]:-}" ]] && return 0
  SEEN_SCREENSHOT[$path]=1
  echo "$(gm_ts) $(gm_green "$base") is skipped because this is a screenshot, judging by the name."
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
      if [[ "$kind" == media || "$kind" == both ]] && gm_screenshot_name "$base" && (( ! INCLUDE_SCREENSHOTS )); then
        gm_note_screenshot "$path"
      elif [[ "$kind" == media || "$kind" == both ]]; then
        gm_add_media "$path"
      fi
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

gm_ask_colors() {
  local reply
  if [[ -n "${NO_COLOR:-}" ]]; then
    USE_COLOR=0
    COLORS_SET=1
  fi
  if (( COLORS_SET )); then
    gm_colors
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    USE_COLOR=1
    gm_colors
    return 0
  fi
  echo
  echo "Use colors?"
  echo "  [Y] Yes (default)"
  echo "  [n] No"
  echo "  [q] Quit"
  gm_read_key "Choice [Y/n/q]: " y "Yes"
  reply="$REPLY"
  case "$reply" in
    y) USE_COLOR=1 ;;
    n) USE_COLOR=0 ;;
    q) gm_quit ;;
    *) echo "$(gm_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
  gm_colors
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
  gm_read_key "Verbose output? [N/v/q]: " n "No, totals only"
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
    RECURSE=1
    if (( ${#DIR_INPUTS[@]} > 1 )); then
      echo "$(gm_ts) Directories: these directories and their subdirectories. Pass --here for these directories only."
    else
      echo "$(gm_ts) Directories: this directory and its subdirectories. Pass --here for this directory only."
    fi
    return 0
  fi
  echo
  if (( ${#DIR_INPUTS[@]} > 1 )); then
    echo "Look in subdirectories of these directories too?"
    echo "  [A] All subdirectories (default)"
    echo "  [c] Current directories only"
  else
    echo "Look in subdirectories too?"
    echo "  [A] All subdirectories (default)"
    echo "  [c] Current directory only"
  fi
  echo "  [q] Quit"
  if (( ${#DIR_INPUTS[@]} > 1 )); then
    gm_read_key "Current directories or all subdirectories? [A/c/q]: " a "All subdirectories"
  else
    gm_read_key "Current directory or all subdirectories? [A/c/q]: " a "All subdirectories"
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
  gm_read_key "Camera offset from UTC? [2/0/a/q]: " 2 "+02:00"
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
  local base="$1" y day
  (( TRACK_ALL )) && return 0
  if (( TRACK_SMART )); then
    if [[ "$base" =~ ^((19|20)[0-9]{6}) ]]; then
      day="${BASH_REMATCH[1]}"
      (( 10#$day >= 10#$TRACK_FROM && 10#$day <= 10#$TRACK_TO )) && return 0
    fi
    return 1
  fi
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
  TRACK_SMART=0
  TRACK_YEAR=()
  TRACK_SPAN="all"
}

gm_set_year_span() {
  local a="$1" b="$2" y
  TRACK_ALL=0
  TRACK_SMART=0
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
  TRACK_SMART=0
  TRACK_YEAR=()
  for y in "$@"; do
    TRACK_YEAR[$y]=1
  done
  TRACK_SPAN="$(gm_year_phrase "$@")"
}

gm_apply_year_text() {
  local typed="$1" out a b
  if out=$(python3 "$PY_HELPER" year-range "$typed" 2>/dev/null); then
    IFS=$'\t' read -r a b <<< "$out"
    gm_set_year_span "$a" "$b"
    return 0
  fi
  return $?
}

gm_ask_typed_year() {
  local typed rc
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
    if gm_apply_year_text "$typed"; then
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

gm_choose_track_mode() {
  local want="$1" flag="$2" other
  if [[ -n "$TRACK_MODE" && "$TRACK_MODE" != "$want" ]]; then
    case "$TRACK_MODE" in
      smart)
        if (( CLI_DAYS_BEFORE_SET || CLI_DAYS_AFTER_SET )); then
          other="--days-before or --days-after"
        else
          other="--smart"
        fi
        ;;
      year) other="--year" ;;
      all) other="--all-years" ;;
      *) other="the other track choice" ;;
    esac
    echo "ERROR: ${flag} and ${other} cannot be used together" >&2
    exit 1
  fi
  TRACK_MODE="$want"
}

gm_say_smart_choice() {
  local before="$1" after="$2" line
  line="The photos and videos run from ${SMART_FIRST} to ${SMART_LAST}. Tracks: ${SMART_FROM} through ${SMART_TO}"
  if (( before == 7 && after == 7 )); then
    echo "$(gm_ts) ${line}."
  elif (( before == after )); then
    echo "$(gm_ts) ${line}, $(gm_day_phrase "$before") before and after."
  else
    echo "$(gm_ts) ${line}, $(gm_day_phrase "$before") before and $(gm_day_phrase "$after") after."
  fi
}

gm_load_smart_span() {
  local out before="${1:-7}" after="${2:-7}"
  SMART_FIRST=""
  SMART_LAST=""
  SMART_FROM=""
  SMART_TO=""
  [[ -s "${WORK:-}/exif.json" && -s "${WORK:-}/media" ]] || return 1
  if out=$(python3 "$PY_HELPER" smart-span --tz "$TZ_VALUE" --exif-json "$WORK/exif.json" --media-list "$WORK/media" --before "$before" --after "$after" 2>/dev/null); then
    IFS=$'\t' read -r SMART_FIRST SMART_LAST SMART_FROM SMART_TO <<< "$out"
    return 0
  fi
  return 1
}

gm_day_phrase() {
  if (( $1 == 1 )); then
    printf '1 day'
  else
    printf '%s days' "$1"
  fi
}

gm_ask_smart_days() {
  local typed raw before after
  local -a parts=()
  while true; do
    printf 'Smart loading, days before and after (for example 7, or 3 14): '
    IFS= read -r typed || gm_quit
    typed="${typed#"${typed%%[![:space:]]*}"}"
    typed="${typed%"${typed##*[![:space:]]}"}"
    if [[ -z "$typed" ]]; then
      echo "Type a number of days, or two numbers: days before, then days after."
      continue
    fi
    if [[ "${typed,,}" == q ]]; then
      gm_quit
    fi
    raw="${typed,,}"
    raw="${raw//–/ }"
    raw="${raw//—/ }"
    raw="${raw//−/ }"
    raw="${raw//-/ }"
    raw="$(printf '%s' "$raw" | tr -s '[:space:]' ' ')"
    read -r -a parts <<< "$raw"
    if (( ${#parts[@]} == 1 || ${#parts[@]} == 2 )) && [[ "${parts[0]}" =~ ^[0-9]+$ ]]; then
      before="${parts[0]}"
      after="$before"
      if (( ${#parts[@]} == 2 )); then
        [[ "${parts[1]}" =~ ^[0-9]+$ ]] || { echo "That is not a number of days. Examples: 7, 3, 3 14."; continue; }
        after="${parts[1]}"
      fi
      SMART_BEFORE="$before"
      SMART_AFTER="$after"
      return 0
    fi
    echo "That is not a number of days. Examples: 7, 3, 3 14."
  done
}

gm_set_smart_span() {
  TRACK_ALL=0
  TRACK_SMART=1
  TRACK_YEAR=()
  TRACK_FROM="${SMART_FROM//./}"
  TRACK_TO="${SMART_TO//./}"
  TRACK_SPAN="${SMART_FROM}-${SMART_TO}"
}

gm_ask_track_years() {
  local reply phrase prompt
  gm_guess_media_years
  if [[ "$TRACK_MODE" == smart ]]; then
    SMART_BEFORE="$CLI_DAYS_BEFORE"
    SMART_AFTER="$CLI_DAYS_AFTER"
    if ! gm_load_smart_span "$CLI_DAYS_BEFORE" "$CLI_DAYS_AFTER"; then
      echo "ERROR: smart loading needs a date from the file times or names." >&2
      return_code=1
      exit 1
    fi
    gm_set_smart_span
    gm_say_smart_choice "$CLI_DAYS_BEFORE" "$CLI_DAYS_AFTER"
    return 0
  fi
  if [[ "$TRACK_MODE" == year ]]; then
    if (( ${#CLI_YEAR_EXACT[@]} )); then
      gm_set_guess_years "${CLI_YEAR_EXACT[@]}"
    else
      gm_set_year_span "$CLI_YEAR_A" "$CLI_YEAR_B"
    fi
    echo "$(gm_ts) Tracks: ${TRACK_SPAN}."
    return 0
  fi
  if [[ "$TRACK_MODE" == all ]]; then
    gm_set_all_years
    echo "$(gm_ts) Tracks: all years."
    return 0
  fi
  gm_load_smart_span
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    if [[ -n "$SMART_FROM" ]]; then
      gm_set_smart_span
      echo "$(gm_ts) The photos and videos run from ${SMART_FIRST} to ${SMART_LAST}. Tracks: ${SMART_FROM} through ${SMART_TO}."
    elif (( ${#GUESS_YEARS[@]} )); then
      gm_set_guess_years "${GUESS_YEARS[@]}"
      echo "$(gm_ts) The photos and videos look like they are probably from ${TRACK_SPAN}, judging by the timestamps and file names."
    else
      gm_set_all_years
      echo "$(gm_ts) Tracks: all years."
    fi
    return 0
  fi
  echo
  if [[ -n "$SMART_FROM" ]]; then
    echo "The photos and videos run from ${SMART_FIRST} to ${SMART_LAST}."
    echo "Smart loading reads tracks from one week before that to one week after:"
    echo "${SMART_FROM} through ${SMART_TO}."
    echo "  [S] Smart loading, ${SMART_FROM} through ${SMART_TO} (default)"
    echo "  [d] Smart loading, choose the days before and after"
    prompt="S/d/t/a/q"
    if (( ${#GUESS_YEARS[@]} )); then
      phrase="$(gm_year_phrase "${GUESS_YEARS[@]}")"
      echo "  [y] ${phrase} only"
      prompt="S/d/y/t/a/q"
    fi
    echo "  [t] Type a year"
    echo "  [a] All years"
    echo "  [q] Quit"
    gm_read_key "Which tracks? [${prompt}]: " s "Smart loading, ${SMART_FROM} through ${SMART_TO}"
    reply="$REPLY"
    case "$reply" in
      s) gm_set_smart_span ;;
      d)
        gm_ask_smart_days
        if ! gm_load_smart_span "$SMART_BEFORE" "$SMART_AFTER"; then
          echo "$(gm_ts) Those days could not be used."
          return_code=1
          exit 1
        fi
        gm_set_smart_span
        if (( SMART_BEFORE == SMART_AFTER )); then
          echo "Tracks: ${SMART_FROM} through ${SMART_TO}, $(gm_day_phrase "$SMART_BEFORE") before and after."
        else
          echo "Tracks: ${SMART_FROM} through ${SMART_TO}, $(gm_day_phrase "$SMART_BEFORE") before and $(gm_day_phrase "$SMART_AFTER") after."
        fi
        ;;
      y)
        if (( ${#GUESS_YEARS[@]} )); then
          gm_set_guess_years "${GUESS_YEARS[@]}"
        else
          echo "$(gm_ts) That is not a choice. Stopping."; return_code=1; exit 1
        fi
        ;;
      t) gm_ask_typed_year ;;
      a) gm_set_all_years ;;
      q) gm_quit ;;
      *) echo "$(gm_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
    esac
    return 0
  fi
  if (( ${#GUESS_YEARS[@]} )); then
    phrase="$(gm_year_phrase "${GUESS_YEARS[@]}")"
    echo "The photos and videos look like they are probably from ${phrase}, judging by the timestamps and file names."
    echo "  [Y] ${phrase} only (default)"
    echo "  [t] Type a year"
    echo "  [a] All years"
    echo "  [q] Quit"
    gm_read_key "Which tracks? [Y/t/a/q]: " y "${phrase} only"
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
    gm_read_key "Which tracks? [A/t/q]: " a "All years"
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

gm_quote_args() {
  local part out="" sq="'" esc="'\\''"
  for part in "$@"; do
    if [[ ! "$part" =~ ^[A-Za-z0-9_./:=+,@%-]+$ ]]; then
      part="${sq}${part//${sq}/${esc}}${sq}"
    fi
    out+="${out:+ }${part}"
  done
  printf '%s\n' "$out"
}

gm_track_year_arg() {
  local -a years=()
  local y first last span n
  for y in "${!TRACK_YEAR[@]}"; do
    years+=("$y")
  done
  (( ${#years[@]} )) || return 0
  mapfile -t years < <(printf '%s\n' "${years[@]}" | sort)
  n=${#years[@]}
  if (( n == 1 )); then
    printf '%s\n' "${years[0]}"
    return 0
  fi
  first="${years[0]}"
  last="${years[n - 1]}"
  span=$(( 10#$last - 10#$first + 1 ))
  if (( span == n )); then
    printf '%s-%s\n' "$first" "$last"
    return 0
  fi
  local IFS=','
  printf '%s\n' "${years[*]}"
}

gm_equivalent_command() {
  local -a cmd=("$(basename -- "$0")")
  local g before after year_arg
  (( DO_YES )) && cmd+=(-y)
  (( DRY_RUN )) && cmd+=(-n)
  (( REDO )) && cmd+=(--redo)
  (( VERBOSE )) && cmd+=(--verbose)
  if (( USE_COLOR )); then
    cmd+=(--colors yes)
  else
    cmd+=(--colors no)
  fi
  if (( USE_NET == 1 )); then
    cmd+=(--internet yes)
  elif (( USE_NET == 0 )); then
    cmd+=(--internet no)
  fi
  if (( BACKUP == 1 )); then
    cmd+=(--backup)
  elif (( BACKUP == 0 )); then
    cmd+=(--no-backup)
  fi
  (( INCLUDE_SCREENSHOTS )) && cmd+=(--screenshots)
  if (( ${#DIR_INPUTS[@]} > 0 )); then
    if (( RECURSE )); then
      cmd+=(--recursive)
    else
      cmd+=(--here)
    fi
  fi
  if [[ -n "$TZ_VALUE" ]]; then
    cmd+=(--tz "$TZ_VALUE")
  fi
  if [[ "$MAX_GAP" != 30 ]]; then
    cmd+=(--max-gap "$MAX_GAP")
  fi
  if [[ "$QUICKTIME" != utc ]]; then
    cmd+=(--quicktime "$QUICKTIME")
  fi
  if (( TRACK_SMART )); then
    before="${SMART_BEFORE:-7}"
    after="${SMART_AFTER:-7}"
    if (( before == 7 && after == 7 )); then
      cmd+=(--smart)
    else
      cmd+=(--days-before "$before" --days-after "$after")
    fi
  elif (( TRACK_ALL )); then
    cmd+=(--all-years)
  elif (( ${#TRACK_YEAR[@]} )); then
    year_arg="$(gm_track_year_arg)"
    [[ -n "$year_arg" ]] && cmd+=(--year "$year_arg")
  fi
  for g in "${GPX_EXTRA[@]}"; do
    cmd+=(--gpx "$g")
  done
  cmd+=(--)
  if (( ${#INPUT_ARGS[@]} > 0 )); then
    cmd+=("${INPUT_ARGS[@]}")
  else
    cmd+=("$(pwd -P)")
  fi
  gm_quote_args "${cmd[@]}"
}

gm_print_equivalent() {
  echo
  printf '%s \\\n%s\n' "Equivalent, you can run the same command with the command line only by using" "$(gm_equivalent_command)"
}

gm_collect_tracks() {
  local path parent
  gm_ask_track_years
  gm_print_equivalent
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
      elif (( TRACK_SMART )); then
        echo "$(gm_ts) ${path}: ${n_here} .gpx/.tcx files from ${SMART_FROM} to ${SMART_TO}, including every subdirectory"
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
  local kind a b c d e f g h i j k
  PLACE_LABEL=()
  PLACE_LAT=()
  PLACE_LON=()
  CHOOSE_PATH=()
  CHOOSE_KIND=()
  CHOOSE_SHOW=()
  CHOOSE_DATE=()
  CHOOSE_TIME=()
  CHOOSE_STATUS=()
  CHOOSE_NEAR_PHRASE=()
  CHOOSE_NEAR_LAT=()
  CHOOSE_NEAR_LON=()
  CHOOSE_NEAR_ELE=()
  CHOOSE_NEAR_TRACK=()
  WRITE_PATH=()
  WRITE_LABEL=()
  WRITE_PLACE=()
  WRITE_HEIGHT=()
  WRITE_GAP=()
  WRITE_TRACK=()
  WRITE_METHOD=()
  WRITE_STATUS=()
  while IFS=$'\t' read -r kind a b c d e f g h i j k; do
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
        CHOOSE_STATUS+=("$f")
        CHOOSE_NEAR_PHRASE+=("$g")
        CHOOSE_NEAR_LAT+=("$h")
        CHOOSE_NEAR_LON+=("$i")
        CHOOSE_NEAR_ELE+=("$j")
        CHOOSE_NEAR_TRACK+=("$k")
        ;;
    esac
  done < <(python3 "$PY_HELPER" plan-lines --plan "$1")
}

gm_note_write() {
  printf '%s\0' "$1" >> "$WORK/write-only"
  printf '%s\0%s\0' "$1" "$2" >> "$WORK/write-address"
}

gm_undo_track_answer() {
  local path="$1" item idx n
  local -a paths=() parts=()
  [[ -s "${WORK}/write-only" ]] || return 0
  while IFS= read -r -d '' item; do
    paths+=("$item")
  done < "${WORK}/write-only"
  (( ${#paths[@]} )) || return 0
  [[ "${paths[$(( ${#paths[@]} - 1 ))]}" == "$path" ]] || return 0
  unset "paths[$(( ${#paths[@]} - 1 ))]"
  : > "${WORK}/write-only"
  if (( ${#paths[@]} )); then
    for item in "${paths[@]}"; do
      printf '%s\0' "$item" >> "${WORK}/write-only"
    done
  fi
  if [[ -s "${WORK}/write-address" ]]; then
    while IFS= read -r -d '' item; do
      parts+=("$item")
    done < "${WORK}/write-address"
  fi
  n=${#parts[@]}
  if (( n >= 2 )) && [[ "${parts[$(( n - 2 ))]}" == "$path" ]]; then
    unset "parts[$(( n - 1 ))]"
    unset "parts[$(( n - 2 ))]"
  fi
  : > "${WORK}/write-address"
  for (( idx = 0; idx < n; idx++ )); do
    [[ -v "parts[$idx]" ]] || continue
    printf '%s\0' "${parts[$idx]}" >> "${WORK}/write-address"
  done
}

gm_undo_place_answer() {
  local prev="$1" n
  n=${#PLACE_Q_I[@]}
  (( n > 0 )) || return 0
  [[ "${PLACE_Q_I[$(( n - 1 ))]}" == "$prev" ]] || return 0
  unset "PLACE_Q_I[$(( n - 1 ))]"
  unset "PLACE_Q_LAT[$(( n - 1 ))]"
  unset "PLACE_Q_LON[$(( n - 1 ))]"
  unset "PLACE_Q_NAME[$(( n - 1 ))]"
  n=${#PLACE_Q_I[@]}
  if (( n > 0 )); then
    GM_LAST_LAT="${PLACE_Q_LAT[$(( n - 1 ))]}"
    GM_LAST_LON="${PLACE_Q_LON[$(( n - 1 ))]}"
    GM_LAST_WHAT="${PLACE_Q_NAME[$(( n - 1 ))]}"
  else
    GM_LAST_LAT=""
    GM_LAST_LON=""
    GM_LAST_WHAT=""
  fi
}

gm_write_row() {
  printf '  %-22s %s\n' "$1" "$2"
}

gm_map_rows() {
  local lat="$1" lon="$2"
  gm_write_row "Google Maps" "https://www.google.com/maps/search/?api=1&query=${lat},${lon}"
  gm_write_row "OpenStreetMap" "https://www.openstreetmap.org/?mlat=${lat}&mlon=${lon}#map=18/${lat}/${lon}"
  gm_write_row "Apple Maps" "https://maps.apple.com/?q=${lat},${lon}"
  gm_write_row "Microsoft Maps" "https://www.bing.com/maps?cp=${lat}~${lon}&lvl=18"
}

gm_finish_asking() {
  local accepted="$1" left="$2" noun="${3:-file}" anoun lverb
  anoun="$noun"
  (( accepted != 1 )) && anoun="${noun}s"
  if (( left == 1 )); then
    lverb="was"
  else
    lverb="were"
  fi
  echo
  if (( accepted == 0 )); then
    echo "Finished asking. No ${noun}s will be updated. ${left} ${lverb} not asked."
  else
    echo "Finished asking. ${accepted} ${anoun} will be updated. ${left} ${lverb} not asked."
  fi
}

gm_ask_track_writes() {
  local i reply loc lat lon rest finish shown total desc status accepted path left
  local n picked prompt has_back track_n
  rest=0
  finish=0
  shown=0
  accepted=0
  total=${#WRITE_PATH[@]}
  TRACK_MANUAL_PATH=()
  TRACK_MANUAL_LABEL=()
  TRACK_MANUAL_LAT=()
  TRACK_MANUAL_LON=()
  TRACK_MANUAL_NAME=()
  : > "$WORK/write-only"
  : > "$WORK/write-address"
  if (( ${#PLACE_LABEL[@]} )); then
    gm_place_width
  fi
  gm_ask_internet
  echo
  echo "Each file is shown below. Nothing is written until these answers are done."
  i=0
  while (( i < total )); do
    shown=$(( i + 1 ))
    echo
    lat="${WRITE_PLACE[$i]%%,*}"
    lon="${WRITE_PLACE[$i]#*,}"
    lon="${lon#"${lon%%[![:space:]]*}"}"
    loc="${WRITE_PLACE[$i]}"
    if [[ -n "${WRITE_HEIGHT[$i]}" ]]; then
      loc="${loc}, ${WRITE_HEIGHT[$i]}"
    fi
    desc=""
    if [[ -n "$lat" && -n "$lon" ]]; then
      gm_lookup_place "$lat" "$lon" quiet
      desc="$GM_PLACE_NAME"
    fi
    if [[ "${WRITE_STATUS[$i]}" == replace ]]; then
      status="Already has a location"
    else
      status="No geotag"
    fi
    echo "[${shown}/${total}]"
    gm_write_row "Status" "$status"
    gm_write_row "Source file" "$(gm_green "${WRITE_LABEL[$i]}")"
    gm_write_row "Track file" "$(gm_green "${WRITE_TRACK[$i]}")"
    gm_write_row "Gap" "${WRITE_GAP[$i]}"
    gm_write_row "Location" "$(gm_blue "$loc")"
    if [[ -n "$lat" && -n "$lon" ]]; then
      gm_map_rows "$lat" "$lon"
    fi
    gm_write_row "Description" "$desc"
    gm_write_row "GPSProcessingMethod" "${WRITE_METHOD[$i]}"
    if (( rest )); then
      echo "Writing this one too."
      gm_note_write "${WRITE_PATH[$i]}" "$desc"
      i=$(( i + 1 ))
      continue
    fi
    if (( ${#PLACE_LABEL[@]} )); then
      echo
      echo "  Preconfigured locations"
      for n in "${!PLACE_LABEL[@]}"; do
        gm_print_place_line "$(( n + 1 ))" "${PLACE_LABEL[$n]}" "$(gm_blue "${PLACE_LAT[$n]}, ${PLACE_LON[$n]}")"
      done
    fi
    echo
    echo "  [Y] Write this (default)"
    echo "  [n] Skip this file"
    echo "  [a] Write this and the rest"
    if (( i > 0 )); then
      echo "  [b] Undo the last answer and back to the previous file"
    fi
    echo "  [f] Finish. Write only the files already accepted"
    echo "  [q] Quit, and write nothing"
    if (( i > 0 )); then
      has_back=yes
    else
      has_back=no
    fi
    prompt="$(gm_track_prompt "$has_back")"
    while true; do
      gm_read_track_choice "Write this location? [${shown}/${total}] ${prompt}: " y "Write this"
      reply="$REPLY"
      if [[ "$reply" =~ ^[0-9]+$ ]]; then
        if (( ${#PLACE_LABEL[@]} > 0 && 10#$reply >= 1 && 10#$reply <= ${#PLACE_LABEL[@]} )); then
          break
        fi
        echo "That is not a choice."
        continue
      fi
      case "$reply" in
        y|n|a|f|q) break ;;
        b)
          if (( i > 0 )); then
            break
          fi
          echo "That is not a choice."
          ;;
        *) echo "That is not a choice." ;;
      esac
    done
    if [[ "$reply" =~ ^[0-9]+$ ]]; then
      picked=$(( 10#$reply - 1 ))
      gm_print_place_line "$(( 10#$reply ))" "${PLACE_LABEL[$picked]}" "$(gm_blue "${PLACE_LAT[$picked]}, ${PLACE_LON[$picked]}")"
      gm_remember_coord "${PLACE_LAT[$picked]}" "${PLACE_LON[$picked]}" "${PLACE_LABEL[$picked]}"
      gm_note_track_place "${WRITE_PATH[$i]}" "${WRITE_LABEL[$i]}" "${PLACE_LAT[$picked]}" "${PLACE_LON[$picked]}" "${PLACE_LABEL[$picked]}"
      i=$(( i + 1 ))
      continue
    fi
    case "$reply" in
      y) gm_note_write "${WRITE_PATH[$i]}" "$desc" ;;
      a)
        gm_note_write "${WRITE_PATH[$i]}" "$desc"
        rest=1
        ;;
      b)
        if (( i > 0 )); then
          printf '  [b] Undo the last answer and back to the previous file\n'
          gm_undo_track_answer "${WRITE_PATH[$(( i - 1 ))]}"
          gm_undo_track_place "${WRITE_PATH[$(( i - 1 ))]}"
          i=$(( i - 1 ))
        fi
        continue
        ;;
      f)
        printf '  [f] Finish. Write only the files already accepted\n'
        finish=1
        GM_STOP_ASKING=1
        break
        ;;
      q)
        printf '  [q] Quit, and write nothing\n'
        gm_ask_quit_or_keep
        finish=1
        break
        ;;
    esac
    i=$(( i + 1 ))
  done
  if (( finish )); then
    if [[ -s "$WORK/write-only" ]]; then
      while IFS= read -r -d '' path; do
        accepted=$(( accepted + 1 ))
      done < "$WORK/write-only"
    fi
    left=$(( total - shown + 1 ))
    track_n="$accepted"
    accepted=$(( accepted + ${#TRACK_MANUAL_PATH[@]} ))
    gm_finish_asking "$accepted" "$left" file
    if (( GM_STOP_ASKING && ${#CHOOSE_SHOW[@]} )); then
      if (( ${#CHOOSE_SHOW[@]} == 1 )); then
        echo "1 file with no close track point was not asked."
      else
        echo "$(gm_fmt_int "${#CHOOSE_SHOW[@]}") files with no close track point were not asked."
      fi
    fi
    if (( track_n > 0 )); then
      WRITE_TRACKS=1
    fi
  elif [[ -s "$WORK/write-only" ]]; then
    WRITE_TRACKS=1
  elif (( ${#TRACK_MANUAL_PATH[@]} == 0 )); then
    echo "$(gm_ts) Those track matches were not written."
  fi
}

gm_ready_to_write() {
  local n=0 path
  if (( WRITE_TRACKS )); then
    if [[ -s "${WORK}/write-only" ]]; then
      while IFS= read -r -d '' path; do
        n=$(( n + 1 ))
      done < "$WORK/write-only"
    else
      n="$WRITE_N"
    fi
  fi
  n=$(( n + ${#PLACE_Q_I[@]} + ${#TRACK_MANUAL_PATH[@]} ))
  echo
  if (( n == 1 )); then
    echo "Ready to update 1 file."
  else
    echo "Ready to update ${n} files."
  fi
  echo "Each file is copied aside while the location is written, so this can take a while."
}

gm_backup_stored_name() {
  local path="$1" stamp="$2" dir base name ext candidate n=2
  dir="$(dirname -- "$path")"
  base="$(basename -- "$path")"
  if [[ "$base" == *.* ]]; then
    name="${base%.*}"
    ext=".${base##*.}"
  else
    name="$base"
    ext=""
  fi
  candidate="${name}_old-${stamp}${ext}"
  while [[ -e "${dir}/${candidate}" ]]; do
    candidate="${name}_old-${stamp}-${n}${ext}"
    n=$(( n + 1 ))
  done
  printf '%s\n' "$candidate"
}

gm_ask_backup() {
  local reply stamp path qi
  local -a paths=()
  if (( BACKUP >= 0 )); then
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    BACKUP=0
    return 0
  fi
  stamp="$(date '+%Y%m%d_%H%M%S')"
  BACKUP_STAMP="$stamp"
  if (( WRITE_TRACKS )); then
    if [[ -s "${WORK}/write-only" ]]; then
      while IFS= read -r -d '' path; do
        paths+=("$path")
      done < "$WORK/write-only"
    else
      paths+=("${WRITE_PATH[@]}")
    fi
  fi
  if (( ${#PLACE_Q_I[@]} )); then
    for qi in "${PLACE_Q_I[@]}"; do
      paths+=("${CHOOSE_PATH[$qi]}")
    done
  fi
  if (( ${#TRACK_MANUAL_PATH[@]} )); then
    paths+=("${TRACK_MANUAL_PATH[@]}")
  fi
  echo
  echo "A backup keeps the old file under a new name."
  echo "  [N] No backup (default)"
  echo "  [b] Yes, files will be stored with the current date and time"
  if (( VERBOSE && ${#paths[@]} )); then
    for path in "${paths[@]}"; do
      echo "      $(gm_backup_stored_name "$path" "$stamp")"
    done
  fi
  echo "  [q] Quit"
  gm_read_key "Backup the old files? [N/b/q]: " n "No backup"
  reply="$REPLY"
  case "$reply" in
    n) BACKUP=0 ;;
    b) BACKUP=1 ;;
    q) gm_quit ;;
    *) echo "$(gm_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
}

gm_ask_update() {
  local reply
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  echo
  echo "  [Y] Yes (default)"
  echo "  [n] No"
  echo "  [q] Quit"
  gm_read_key "Update these files? [Y/n/q]: " y "Yes"
  reply="$REPLY"
  case "$reply" in
    y) return 0 ;;
    n)
      echo "Those files were not updated."
      WRITE_TRACKS=0
      return 1
      ;;
    q) gm_quit ;;
    *) echo "$(gm_ts) That is not a choice. Stopping."; return_code=1; exit 1 ;;
  esac
}

gm_match_window() {
  local gap="${MAX_GAP:-30}"
  if (( gap < 60 )); then
    printf '%ss' "$gap"
  else
    printf '%dm' "$(( (gap + 30) / 60 ))"
  fi
}

gm_place_width() {
  local n w
  PLACE_NUM_W=1
  PLACE_LABEL_W=0
  if (( ${#PLACE_LABEL[@]} >= 10 )); then
    PLACE_NUM_W=${#PLACE_LABEL[@]}
    PLACE_NUM_W=${#PLACE_NUM_W}
  fi
  for n in "${!PLACE_LABEL[@]}"; do
    w=${#PLACE_LABEL[$n]}
    (( w > PLACE_LABEL_W )) && PLACE_LABEL_W=$w
  done
}

gm_print_place_line() {
  local num="$1" label="$2" coord="$3" pad
  pad=$(( PLACE_LABEL_W - ${#label} + 2 ))
  (( pad < 2 )) && pad=2
  printf '  [%*d] [%s]%*s%s\n' "$PLACE_NUM_W" "$num" "$label" "$pad" "" "$coord"
}

gm_place_keys() {
  local has_near="$1" n count
  local -a keys=()
  count=${#PLACE_LABEL[@]}
  if (( count == 1 )); then
    keys+=(1)
  elif (( count > 1 && count <= 6 )); then
    for (( n = 1; n <= count; n++ )); do
      keys+=("$n")
    done
  elif (( count > 6 )); then
    keys+=("1-${count}")
  fi
  if [[ -n "$GM_LAST_LAT" && -n "$GM_LAST_LON" ]]; then
    keys+=(r)
  fi
  if [[ "$2" == yes ]]; then
    keys+=(b)
  fi
  if [[ "$has_near" == yes ]]; then
    keys+=(m)
  fi
  keys+=(g S f q)
  local IFS=/
  printf '[%s]' "${keys[*]}"
}

gm_show_nearest() {
  local lat="$1" lon="$2" ele="$3" phrase="$4" track="$5" loc
  loc="${lat}, ${lon}"
  if [[ -n "$ele" && "$ele" != "-" ]]; then
    loc="${loc}, ${ele}"
  fi
  echo
  gm_write_row "Location" "$(gm_blue "$loc")"
  gm_write_row "Gap" "$phrase"
  gm_write_row "Track file" "$(gm_green "$track")"
  gm_map_rows "$lat" "$lon"
}

gm_choose_places() {
  local i n reply picked canon shown total place_prompt has_near any_other
  local near_lat near_lon near_ele near_phrase near_track
  if (( GM_STOP_ASKING )); then
    return 0
  fi
  if (( ${#CHOOSE_SHOW[@]} == 0 )); then
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    echo
    echo "$(gm_ts) ${#CHOOSE_SHOW[@]} file$( (( ${#CHOOSE_SHOW[@]} == 1 )) || printf 's' ) have no track point. A place is written only when you pick it."
    return 0
  fi
  any_other=0
  for i in "${!CHOOSE_SHOW[@]}"; do
    if [[ "${CHOOSE_STATUS[$i]:-}" != "no track" ]]; then
      any_other=1
      break
    fi
  done
  echo
  echo "These files have no GPX or TCX point close enough."
  if (( any_other )); then
    echo "A match needs a point within $(gm_match_window)."
  else
    echo "No GPX or TCX file was loaded."
  fi
  gm_ask_internet
  gm_place_width
  shown=0
  total=${#CHOOSE_SHOW[@]}
  i=0
  while (( i < total )); do
    shown=$(( i + 1 ))
    near_lat="${CHOOSE_NEAR_LAT[$i]:-}"
    near_lon="${CHOOSE_NEAR_LON[$i]:-}"
    near_ele="${CHOOSE_NEAR_ELE[$i]:-}"
    near_phrase="${CHOOSE_NEAR_PHRASE[$i]:-}"
    near_track="${CHOOSE_NEAR_TRACK[$i]:-}"
    has_near=no
    echo
    echo "[${shown}/${total}] $(gm_green "${CHOOSE_SHOW[$i]}")"
    if [[ -n "$near_lat" && "$near_lat" != "-" && -n "$near_lon" && "$near_lon" != "-" ]]; then
      has_near=yes
      echo "      The nearest point is ${near_phrase}, in $(gm_green "$near_track")."
    elif [[ "${CHOOSE_STATUS[$i]:-}" == "no time" ]]; then
      echo "      This file has no time, so there is no nearest point."
    elif [[ "${CHOOSE_STATUS[$i]:-}" == "no track" ]]; then
      echo "      No track was loaded, so there is no nearest point."
    fi
    for n in "${!PLACE_LABEL[@]}"; do
      gm_print_place_line "$(( n + 1 ))" "${PLACE_LABEL[$n]}" "$(gm_blue "${PLACE_LAT[$n]}, ${PLACE_LON[$n]}")"
    done
    if [[ -n "$GM_LAST_LAT" && -n "$GM_LAST_LON" ]]; then
      echo "  [r] $(gm_reuse_text)"
    fi
    if (( i > 0 )); then
      echo "  [b] Undo the last answer and back to the previous file"
    fi
    if [[ "$has_near" == yes ]]; then
      echo "  [m] Show map links for the nearest track point"
    fi
    echo "  [g] Type a latitude, longitude for this file"
    echo "  [S] Skip this file (default)"
    echo "  [f] Finish. Write only the files already accepted"
    echo "  [q] Quit now, without Enter"
    if (( i > 0 )); then
      place_prompt="$(gm_place_keys "$has_near" yes)"
    else
      place_prompt="$(gm_place_keys "$has_near" no)"
    fi
    while true; do
      gm_read_place_choice "Place for $(gm_green "${CHOOSE_SHOW[$i]}")? ${place_prompt}: "
      reply="$REPLY"
      if [[ "$reply" != m ]]; then
        break
      fi
      if [[ "$has_near" == yes ]]; then
        gm_show_nearest "$near_lat" "$near_lon" "$near_ele" "$near_phrase" "$near_track"
      else
        echo "There is no nearest track point."
      fi
    done
    if [[ "$reply" == b ]]; then
      if (( i > 0 )); then
        gm_undo_place_answer "$(( i - 1 ))"
        i=$(( i - 1 ))
      fi
      continue
    fi
    if [[ "$reply" == q ]]; then
      gm_ask_quit_or_keep
      gm_finish_asking "${#PLACE_Q_I[@]}" "$(( total - shown + 1 ))" place
      break
    fi
    if [[ "$reply" == f ]]; then
      gm_finish_asking "${#PLACE_Q_I[@]}" "$(( total - shown + 1 ))" place
      break
    fi
    if [[ "$reply" == s ]]; then
      i=$(( i + 1 ))
      continue
    fi
    if [[ "$reply" == r ]]; then
      if [[ -n "$GM_LAST_LAT" && -n "$GM_LAST_LON" ]]; then
        GM_LAT="$GM_LAST_LAT"
        GM_LON="$GM_LAST_LON"
        if [[ "$GM_LAST_WHAT" == "manually entered" || -z "$GM_LAST_WHAT" ]]; then
          gm_use_typed "$i"
        else
          echo
          gm_write_row "Location" "$(gm_blue "${GM_LAST_LAT}, ${GM_LAST_LON}")"
          gm_map_rows "$GM_LAST_LAT" "$GM_LAST_LON"
          gm_write_row "Description" "$GM_LAST_WHAT"
          gm_write_chosen "$GM_LAST_LAT" "$GM_LAST_LON" "$GM_LAST_WHAT" "$i"
        fi
      else
        echo "There is no previous latitude and longitude. This file was skipped."
      fi
      i=$(( i + 1 ))
      continue
    fi
    if [[ "$reply" == g ]]; then
      if gm_ask_coord; then
        gm_use_typed "$i"
      fi
      i=$(( i + 1 ))
      continue
    fi
    if canon=$(python3 "$PY_HELPER" check-coord "$reply" 2>/dev/null); then
      IFS=$'\t' read -r GM_LAT GM_LON <<< "$canon"
      printf '  Typed latitude, longitude: %s\n' "$(gm_blue "${GM_LAT}, ${GM_LON}")"
      gm_use_typed "$i"
      i=$(( i + 1 ))
      continue
    fi
    if [[ "$reply" =~ ^[0-9]+$ ]] && (( 10#$reply >= 1 && 10#$reply <= ${#PLACE_LABEL[@]} )); then
      picked=$(( 10#$reply - 1 ))
      gm_print_place_line "$(( 10#$reply ))" "${PLACE_LABEL[$picked]}" "$(gm_blue "${PLACE_LAT[$picked]}, ${PLACE_LON[$picked]}")"
      gm_remember_coord "${PLACE_LAT[$picked]}" "${PLACE_LON[$picked]}" "${PLACE_LABEL[$picked]}"
      gm_write_chosen "${PLACE_LAT[$picked]}" "${PLACE_LON[$picked]}" "${PLACE_LABEL[$picked]}" "$i"
    elif [[ ! "$reply" =~ ^[0-9]+$ ]]; then
      echo "That is not a choice."
      continue
    else
      echo "That is not one of the places. This file was skipped."
    fi
    i=$(( i + 1 ))
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
USE_COLOR=0
COLORS_SET=0
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
declare -A SEEN_SCREENSHOT=()
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
CHOOSE_STATUS=()
CHOOSE_NEAR_PHRASE=()
CHOOSE_NEAR_LAT=()
CHOOSE_NEAR_LON=()
CHOOSE_NEAR_ELE=()
CHOOSE_NEAR_TRACK=()
USE_NET=-1
INTERNET_SET=0
BACKUP=-1
BACKUP_SET=0
BACKUP_STAMP=""
INCLUDE_SCREENSHOTS=0
GM_LOOKED=0
GM_PLACE="typed"
GM_LAST_LAT=""
GM_LAST_LON=""
GM_LAST_WHAT=""
GM_STOP_ASKING=0
PLACE_WROTE=0
PLACE_Q_LAT=()
PLACE_Q_LON=()
PLACE_Q_NAME=()
PLACE_Q_I=()
TRACK_MANUAL_PATH=()
TRACK_MANUAL_LABEL=()
TRACK_MANUAL_LAT=()
TRACK_MANUAL_LON=()
TRACK_MANUAL_NAME=()
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
TRACK_SMART=0
TRACK_FROM=""
TRACK_TO=""
TRACK_SPAN=""
TRACK_MODE=""
CLI_DAYS_BEFORE=7
CLI_DAYS_AFTER=7
CLI_DAYS_BEFORE_SET=0
CLI_DAYS_AFTER_SET=0
CLI_YEAR=""
CLI_YEAR_A=""
CLI_YEAR_B=""
CLI_YEAR_EXACT=()
SMART_BEFORE=""
SMART_AFTER=""
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
    --colors)
      gm_need_value "$@"
      case "${2,,}" in
        yes|y) USE_COLOR=1 ;;
        no|n) USE_COLOR=0 ;;
        *) echo "ERROR: --colors must be yes or no, not: $2" >&2; exit 1 ;;
      esac
      COLORS_SET=1
      shift 2
      ;;
    --internet)
      gm_need_value "$@"
      if (( INTERNET_SET )); then
        echo "ERROR: --internet was given twice" >&2
        exit 1
      fi
      case "${2,,}" in
        yes|y) USE_NET=1 ;;
        no|n) USE_NET=0 ;;
        *) echo "ERROR: --internet must be yes or no, not: $2" >&2; exit 1 ;;
      esac
      INTERNET_SET=1
      shift 2
      ;;
    --backup)
      if (( BACKUP_SET )); then
        echo "ERROR: --backup and --no-backup cannot be used together" >&2
        exit 1
      fi
      BACKUP=1
      BACKUP_SET=1
      shift
      ;;
    --no-backup)
      if (( BACKUP_SET )); then
        echo "ERROR: --backup and --no-backup cannot be used together" >&2
        exit 1
      fi
      BACKUP=0
      BACKUP_SET=1
      shift
      ;;
    --screenshots)
      INCLUDE_SCREENSHOTS=1
      shift
      ;;
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
    --smart)
      gm_choose_track_mode smart "--smart"
      shift
      ;;
    --days-before)
      gm_need_value "$@"
      if [[ ! "$2" =~ ^[0-9]+$ ]]; then
        echo "ERROR: --days-before must be a number of days, not: $2" >&2
        exit 1
      fi
      gm_choose_track_mode smart "--days-before"
      CLI_DAYS_BEFORE="$2"
      CLI_DAYS_BEFORE_SET=1
      shift 2
      ;;
    --days-after)
      gm_need_value "$@"
      if [[ ! "$2" =~ ^[0-9]+$ ]]; then
        echo "ERROR: --days-after must be a number of days, not: $2" >&2
        exit 1
      fi
      gm_choose_track_mode smart "--days-after"
      CLI_DAYS_AFTER="$2"
      CLI_DAYS_AFTER_SET=1
      shift 2
      ;;
    --year)
      gm_need_value "$@"
      if [[ "$TRACK_MODE" == year ]]; then
        echo "ERROR: --year given twice" >&2
        exit 1
      fi
      if [[ "$2" == *,* ]]; then
        CLI_YEAR_EXACT=()
        IFS=',' read -ra year_parts <<< "$2"
        if (( ${#year_parts[@]} < 2 )); then
          echo "ERROR: --year must be a year or a range, not: $2" >&2
          exit 1
        fi
        for year_part in "${year_parts[@]}"; do
          year_part="${year_part// /}"
          if [[ ! "$year_part" =~ ^(19|20)[0-9]{2}$ ]]; then
            echo "ERROR: --year must be a year or a range, not: $2" >&2
            exit 1
          fi
          CLI_YEAR_EXACT+=("$year_part")
        done
        gm_choose_track_mode year "--year"
        CLI_YEAR="$2"
      else
      CLI_YEAR_EXACT=()
      year_out=$(python3 "$PY_HELPER" year-range "$2" 2>/dev/null)
      year_rc=$?
      if (( year_rc != 0 )); then
        if (( year_rc == 2 )); then
          echo "ERROR: the first year is newer than the second: $2" >&2
        else
          echo "ERROR: --year must be a year or a range, not: $2" >&2
        fi
        exit 1
      fi
      gm_choose_track_mode year "--year"
      CLI_YEAR="$2"
      IFS=$'\t' read -r CLI_YEAR_A CLI_YEAR_B <<< "$year_out"
      fi
      shift 2
      ;;
    --all-years)
      if [[ "$TRACK_MODE" == all ]]; then
        echo "ERROR: --all-years given twice" >&2
        exit 1
      fi
      gm_choose_track_mode all "--all-years"
      shift
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
gm_ask_colors
gm_ask_verbose
gm_ask_scope
gm_ask_tz

gm_proc_begin
gm_collect_media
gm_proc_end

if (( MEDIA_N == 0 )); then
  gm_print_equivalent
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
  gm_print_equivalent
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
if (( USE_COLOR )); then
  SCAN_ARGS+=(--colors)
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
fi

gm_choose_places

if (( WRITE_TRACKS || ${#PLACE_Q_I[@]} || ${#TRACK_MANUAL_PATH[@]} )); then
  gm_ready_to_write
  if gm_ask_update; then
    gm_ask_backup
    gm_print_equivalent
    if (( WRITE_TRACKS )); then
      echo
      echo "Track locations."
      echo
      gm_proc_begin
      write_args=(write --exiftool "$EXIFTOOL_BIN" --plan "$WORK/plan.json")
      if [[ -s "${WORK}/write-only" ]]; then
        write_args+=(--only-list "$WORK/write-only")
      fi
      if [[ -s "${WORK}/write-address" ]]; then
        write_args+=(--address-list "$WORK/write-address")
      fi
      if (( USE_COLOR )); then
        write_args+=(--colors)
      fi
      if (( VERBOSE )); then
        write_args+=(--verbose)
      fi
      if (( BACKUP == 1 )); then
        write_args+=(--backup --backup-stamp "$BACKUP_STAMP")
      fi
      python3 "$PY_HELPER" "${write_args[@]}" || return_code=$?
      gm_proc_end
    fi
    if (( ${#PLACE_Q_I[@]} || ${#TRACK_MANUAL_PATH[@]} )); then
      echo
      echo "Manual entry."
      echo
    fi
    gm_flush_places
    if (( ${#PLACE_Q_I[@]} && ${#TRACK_MANUAL_PATH[@]} )); then
      echo
    fi
    gm_flush_track_places
    if (( ${#PLACE_Q_I[@]} || ${#TRACK_MANUAL_PATH[@]} )); then
      echo
      if (( PLACE_WROTE == 0 )); then
        echo "No files updated by manual entry."
      elif (( PLACE_WROTE == 1 )); then
        echo "1 file updated by manual entry."
      else
        echo "$(gm_fmt_int "$PLACE_WROTE") files updated by manual entry."
      fi
    fi
  fi
fi
exit "$return_code"
