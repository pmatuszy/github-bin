#!/usr/bin/env python3
# v. 20261012.152905 - a place number is taken as soon as the digit is pressed
# v. 20261012.152350 - the verbose question is asked only when no options were given
# v. 20261012.151810 - the internet question is asked before the equivalent command
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
# v. 20261012.103728 - year-range accepts one year or a range, and refuses a first year newer than the second
# v. 20261012.102745 - the missing-conf message includes profile_location_dir when that variable is set
# v. 20261012.102638 - the missing-conf message names /etc, $HOME, $HOME/etc, and $HOME/conf
# v. 20261012.102243 - the missing-conf message includes $HOME/conf; every found .conf is merged
# v. 20261012.101840 - GPSProcessingMethod is TRACK for a GPX or TCX point and MANUAL for a chosen place
# v. 20261012.100144 - the plan records file, location, track, and point counts for the closing summary
# v. 20261012.095919 - reverse names a typed point from OpenStreetMap, or reports that it cannot be reached
# v. 20261012.095355 - [tracks-location] is searched through every subdirectory, and that count is printed first
# v. 20261012.094641 - [tracks-location] in the .conf is another directory of GPX and TCX tracks
# v. 20261012.094407 - q on a place question quits at once, and a latitude and longitude can be typed for that file
# v. 20261012.092540 - print .conf errors, and merge entries that are the same location
# v. 20261012.092157 - merge named places from every .conf and offer them when no track point matches
# v. 20261009.160131 - also read .tcx tracks; a Trackpoint with a time and a position joins the same search as GPX
# v. 20261009.151425 - match a photo or video time to the nearest GPX point and write that location with exiftool

# 2026.10.12 - v. 0.71 - a place number is taken as soon as the digit is pressed
# 2026.10.12 - v. 0.70 - the verbose question is asked only when no options were given
# 2026.10.12 - v. 0.69 - the internet question is asked before the equivalent command
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
# 2026.10.12 - v. 0.14 - year-range reads 2026, 2026-2027, and 2026 2027, and refuses a reversed range
# 2026.10.12 - v. 0.13 - the missing-conf message mentions profile_location_dir when that variable is set
# 2026.10.12 - v. 0.12 - the missing-conf message names /etc, $HOME, $HOME/etc, and $HOME/conf
# 2026.10.12 - v. 0.11 - the missing-conf message names $HOME/conf; every found .conf is merged
# 2026.10.12 - v. 0.10 - GPSProcessingMethod records TRACK or MANUAL with the coordinates
# 2026.10.12 - v. 0.9 - scan stores how many files, locations, tracks, and track points the closing summary prints
# 2026.10.12 - v. 0.8 - reverse asks OpenStreetMap for a street, city, and country, and returns a separate code when the network fails
# 2026.10.12 - v. 0.7 - [tracks-location] reads .gpx and .tcx from that directory and every subdirectory, and the count is shown before the report
# 2026.10.12 - v. 0.6 - [tracks-location] adds that directory, and the folders inside it, to the GPX and TCX search
# 2026.10.12 - v. 0.5 - check-coord reads a typed latitude, longitude for one file
# 2026.10.12 - v. 0.4 - .conf problems are printed; the same coordinates are one place, and one name with two different coordinates is an error
# 2026.10.12 - v. 0.3 - named places from video-pgm-geotag-missing-media.conf are merged and offered for a file with no track point
# 2026.10.09 - v. 0.2 - .tcx files (Garmin Training Center) are read with .gpx; Trackpoints without a position are left out
# 2026.10.09 - v. 0.1 - initial release: read GPX, read file times with exiftool, report, write one location
"""Find a GPX or TCX point close in time to a photo or video, for video-pgm-geotag-missing-media.sh.

Subcommands:
  scan        Read the lists, print the report, write a plan file.
  write       Write the locations in that plan. Files already tagged are not in the plan.
  check-tz    Print the offset in +HH:MM form, or exit 1.
  selftest    Check the clock and the matcher. No exiftool and no media files.
"""

import argparse
import calendar
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import date, datetime, timedelta, timezone

VERSION = "0.1"
DISAGREE_METRES = 300

DT_RE = re.compile(
    r"^(\d{4})[:\-](\d{2})[:\-](\d{2})[ T](\d{2}):(\d{2}):(\d{2})(\.\d+)?"
    r"(Z|[+-]\d{2}:?\d{2})?$"
)
TZ_RE = re.compile(r"^([+-])(\d{1,2})(?::?(\d{2}))?$")
ISO6709_RE = re.compile(
    r"^([+-]\d+(?:\.\d+)?)([+-]\d+(?:\.\d+)?)([+-]\d+(?:\.\d+)?)?$"
)
COORD_RE = re.compile(r"^([+-]?\d+(?:\.\d+)?)\s*,\s*([+-]?\d+(?:\.\d+)?)\s*$")
UNMATCHED = ("too far", "no time", "no track")

TIME_ORDER = (
    "SubSecDateTimeOriginal",
    "DateTimeOriginal",
    "CreationDate",
    "CreateDate",
    "MediaCreateDate",
    "TrackCreateDate",
    "FileCreateDate",
    "FileModifyDate",
)
TIME_LABEL = {
    "SubSecDateTimeOriginal": "DateTimeOriginal",
    "DateTimeOriginal": "DateTimeOriginal",
    "CreationDate": "CreationDate",
    "CreateDate": "CreateDate",
    "MediaCreateDate": "MediaCreateDate",
    "TrackCreateDate": "TrackCreateDate",
    "FileCreateDate": "file created",
    "FileModifyDate": "file modified",
}
CAMERA_TAGS = {"SubSecDateTimeOriginal", "DateTimeOriginal", "CreationDate"}
QUICK_TAGS = {"CreateDate", "MediaCreateDate", "TrackCreateDate"}
GROUP_RANK = {
    "EXIF": 0,
    "XMP": 1,
    "QuickTime": 2,
    "Keys": 3,
    "ItemList": 4,
    "UserData": 5,
    "Composite": 6,
    "System": 7,
}
STATUS_COLOR = {
    "match": "36",
    "replace": "33",
    "tagged": "32",
    "too far": "33",
    "no time": "31",
    "no track": "31",
    "unread": "31",
}


COLOR_ENABLED = False


def use_color():
    return COLOR_ENABLED and sys.stdout.isatty() and not os.environ.get("NO_COLOR")


def take_colors(args):
    global COLOR_ENABLED
    COLOR_ENABLED = bool(getattr(args, "colors", False))


def paint(text, code):
    if not use_color() or not code:
        return text
    return "\033[%sm%s\033[0m" % (code, text)


def eprint(text):
    print(text, file=sys.stderr, flush=True)


def read_paths(path):
    with open(path, "rb") as handle:
        data = handle.read()
    found = []
    for raw in data.split(b"\0"):
        if raw:
            found.append(os.fsdecode(raw))
    return found


def norm_key(path):
    return os.path.normcase(os.path.normpath(os.path.abspath(path)))


def flatten(value):
    if isinstance(value, list):
        return value[0] if value else None
    return value


def parse_tz_seconds(text):
    raw = text.strip().upper().replace(" ", "")
    if raw in ("0", "Z", "UTC", "+0", "+00", "+00:00", "+0000", "-0", "-00", "-00:00"):
        return 0
    match = TZ_RE.match(raw)
    if not match:
        raise ValueError("bad offset")
    hours = int(match.group(2))
    minutes = int(match.group(3) or "0")
    if hours > 14 or minutes > 59:
        raise ValueError("bad offset")
    sign = 1 if match.group(1) == "+" else -1
    return sign * (hours * 3600 + minutes * 60)


def fmt_offset(seconds):
    sign = "+" if seconds >= 0 else "-"
    total = abs(int(round(seconds)))
    hour, minute = divmod(total // 60, 60)
    return "%s%02d:%02d" % (sign, hour, minute)


def round_half_up(value):
    return int(math.floor(float(value) + 0.5))


def near_phrase(signed):
    """How far the nearest track point is from the file, in plain time."""
    size = abs(float(signed))
    way = "ahead" if float(signed) >= 0 else "ago"
    if size < 60:
        count = round_half_up(size)
        if count < 1:
            count = 1
        unit = "second" if count == 1 else "seconds"
        return "%d %s %s" % (count, unit, way)
    if size < 3600:
        count = round_half_up(size / 60.0)
        if count >= 60:
            count = 1
            unit = "hour"
            return "about %d %s %s" % (count, unit, way)
        if count < 1:
            count = 1
        unit = "minute" if count == 1 else "minutes"
        return "about %d %s %s" % (count, unit, way)
    count = round_half_up(size / 3600.0)
    if count < 1:
        count = 1
    unit = "hour" if count == 1 else "hours"
    return "about %d %s %s" % (count, unit, way)


def one_line(value):
    text = str("" if value is None else value)
    text = text.replace("\t", " ").replace("\r", " ").replace("\n", " ").strip()
    return text or "-"


def fmt_gap(seconds):
    size = abs(seconds)
    if size < 10:
        return "%.1fs" % size
    if size < 60:
        return "%ds" % int(round(size))
    if size < 3600:
        minute = int(size // 60)
        second = int(round(size - minute * 60))
        if second == 60:
            minute += 1
            second = 0
        return "%dm %ds" % (minute, second)
    hour = int(size // 3600)
    minute = int(round((size - hour * 3600) / 60.0))
    if minute == 60:
        hour += 1
        minute = 0
    return "%dh %dm" % (hour, minute)


def fmt_int(number):
    return "{:,}".format(number)


def fmt_utc(epoch):
    return datetime.fromtimestamp(epoch, timezone.utc).strftime("%Y.%m.%d %H:%M:%S")


def fmt_metres(metres):
    if metres < 1000:
        return "%dm" % int(round(metres))
    return "%.1fkm" % (metres / 1000.0)


def fmt_pos(lat, lon, ele):
    text = "%.6f, %.6f" % (lat, lon)
    if ele is None:
        return text
    return "%s, %.0fm" % (text, ele)


def clock_stamp(moment=None):
    when = moment or datetime.now()
    return when.strftime("[ %Y.%m.%d %H:%M:%S ]")


def progress_mark(number, total):
    total = max(total, 1)
    width = len(str(total))
    return "[%*d/%d]" % (width, number, total)


def place_suffix(address):
    text = (address or "").strip()
    if not text or text.lower() == "typed":
        return ""
    return " (%s)" % text


def took_phrase(elapsed):
    return "Took %s." % fmt_left(elapsed)


def print_processing(number, total, name, action, elapsed=None):
    mark = progress_mark(number, total)
    if elapsed is not None:
        action = "%s %s" % (action, took_phrase(elapsed))
    print("%s %s %s - %s" % (clock_stamp(), mark, name, action), flush=True)
    return mark


def print_written_place(mark, lat, lon, ele, address):
    indent = " " * (len(clock_stamp()) + 1 + len(mark) + 1)
    print(
        "%s%s%s" % (indent, paint(fmt_pos(lat, lon, ele), "94"), place_suffix(address)),
        flush=True,
    )


def read_address_pairs(path):
    pairs = {}
    with open(path, "rb") as handle:
        parts = handle.read().split(b"\0")
    index = 0
    while index + 1 < len(parts):
        key = os.fsdecode(parts[index])
        value = os.fsdecode(parts[index + 1])
        if key:
            pairs[norm_key(key)] = value
        index += 2
    return pairs


def fmt_height(ele):
    if ele is None:
        return ""
    return "%.0fm" % ele


def null_island(lat, lon):
    return abs(lat) < 1e-7 and abs(lon) < 1e-7


def parse_time_epoch(text):
    """Return (epoch, has_zone). A zoned value is already UTC. A naive value is the clock digits as UTC."""
    match = DT_RE.match(text.strip())
    if not match:
        return None
    parts = [int(match.group(i)) for i in range(1, 7)]
    frac = float(match.group(7)) if match.group(7) else 0.0
    zone = match.group(8)
    try:
        clock = datetime(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5])
    except ValueError:
        return None
    epoch = calendar.timegm(clock.timetuple()) + frac
    if not zone:
        return epoch, False
    if zone == "Z":
        return epoch, True
    zmatch = re.match(r"^([+-])(\d{2}):?(\d{2})$", zone)
    if not zmatch:
        return None
    off = int(zmatch.group(2)) * 3600 + int(zmatch.group(3)) * 60
    if zmatch.group(1) == "-":
        off = -off
    return epoch - off, True


def wall_label(raw):
    match = DT_RE.match(raw.strip())
    if not match:
        return raw.strip()
    return "%s.%s.%s %s:%s:%s" % (
        match.group(1), match.group(2), match.group(3),
        match.group(4), match.group(5), match.group(6),
    )


def values_named(info, name):
    found = []
    for key, value in info.items():
        if key == name or key.endswith(":" + name):
            flat = flatten(value)
            if flat not in (None, "", "undef", "-"):
                group = key.split(":")[0] if ":" in key else ""
                found.append((group, flat))
    return found


def best_time_value(info, name):
    found = []
    for group, raw in values_named(info, name):
        if not isinstance(raw, str):
            raw = str(raw)
        parsed = parse_time_epoch(raw.strip())
        if not parsed:
            continue
        found.append((parsed[1], GROUP_RANK.get(group, 50), parsed, raw.strip()))
    if not found:
        return None
    zoned = [item for item in found if item[0]]
    pool = zoned or found
    pool.sort(key=lambda item: item[1])
    return pool[0]


def offset_tag_seconds(info):
    for name in ("OffsetTimeOriginal", "OffsetTime"):
        for _group, raw in values_named(info, name):
            try:
                return parse_tz_seconds(str(raw)), str(raw).strip()
            except ValueError:
                continue
    return None, None


def pick_time(info, offset_seconds):
    for name in TIME_ORDER:
        got = best_time_value(info, name)
        if not got:
            continue
        _has, _rank, parsed, raw = got
        epoch, has_zone = parsed
        basis = "zoned" if has_zone else "naive"
        label = TIME_LABEL[name]
        if not has_zone and (name in CAMERA_TAGS or name in QUICK_TAGS):
            own, _own_text = offset_tag_seconds(info)
            if own is not None:
                epoch = epoch - own
                basis = "zoned"
                label = "%s %s" % (TIME_LABEL[name], fmt_offset(own))
            else:
                epoch = epoch - offset_seconds
        elif not has_zone:
            # A file time is the computer's clock. Leave those digits as UTC
            # and keep them out of the camera-offset hint.
            basis = "file"
        return {"epoch": epoch, "source": label, "wall": wall_label(raw), "basis": basis}
    return None


def as_float(value):
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value.strip())
        except ValueError:
            return None
    return None


def first_number(info, name):
    found = []
    for group, raw in values_named(info, name):
        number = as_float(raw)
        if number is not None:
            found.append((GROUP_RANK.get(group, 50), number))
    if not found:
        return None
    found.sort(key=lambda item: item[0])
    return found[0][1]


def parse_gps_coordinates(value):
    if isinstance(value, (int, float)):
        return None
    text = str(value).strip().rstrip("/")
    if not text:
        return None
    numbers = []
    for part in re.split(r"[\s,]+", text):
        number = as_float(part)
        if number is None:
            numbers = []
            break
        numbers.append(number)
    if len(numbers) >= 2:
        ele = numbers[2] if len(numbers) >= 3 else None
        return numbers[0], numbers[1], ele
    match = ISO6709_RE.match(text)
    if not match:
        return None
    ele = float(match.group(3)) if match.group(3) else None
    return float(match.group(1)), float(match.group(2)), ele


def position_from_tags(info):
    lat = first_number(info, "GPSLatitude")
    lon = first_number(info, "GPSLongitude")
    if lat is not None and lon is not None and not null_island(lat, lon):
        if abs(lat) <= 90 and abs(lon) <= 180:
            return lat, lon, first_number(info, "GPSAltitude")
    for _group, raw in values_named(info, "GPSCoordinates"):
        parsed = parse_gps_coordinates(raw)
        if not parsed:
            continue
        lat, lon, ele = parsed
        if null_island(lat, lon) or abs(lat) > 90 or abs(lon) > 180:
            continue
        return lat, lon, ele
    return None


def gps_epoch(info):
    for _group, raw in values_named(info, "GPSDateTime"):
        if not isinstance(raw, str):
            raw = str(raw)
        parsed = parse_time_epoch(raw.strip())
        if parsed:
            # A GPS clock with no zone is UTC.
            return parsed[0]
    date_raw = None
    for _group, raw in values_named(info, "GPSDateStamp"):
        date_raw = str(raw).strip()
        break
    tod = None
    for _group, raw in values_named(info, "GPSTimeStamp"):
        tod = raw
        break
    if not date_raw or tod is None:
        return None
    date_match = re.match(r"^(\d{4}):(\d{2}):(\d{2})$", date_raw)
    if not date_match:
        return None
    seconds = as_float(tod)
    if seconds is None and isinstance(tod, str):
        tmatch = re.match(r"^(\d{1,2}):(\d{2}):(\d{2})(\.\d+)?$", tod.strip())
        if not tmatch:
            return None
        seconds = int(tmatch.group(1)) * 3600 + int(tmatch.group(2)) * 60 + float(tmatch.group(3) + (tmatch.group(4) or ""))
    if seconds is None:
        return None
    hour = int(seconds // 3600)
    minute = int((seconds % 3600) // 60)
    second = seconds % 60
    if hour > 23 or minute > 59:
        return None
    try:
        base = datetime(
            int(date_match.group(1)), int(date_match.group(2)), int(date_match.group(3)),
            hour, minute, int(second), tzinfo=timezone.utc,
        )
    except ValueError:
        return None
    return base.timestamp() + (second - int(second))


def camera_naive_epoch(info):
    for name in ("SubSecDateTimeOriginal", "DateTimeOriginal"):
        got = best_time_value(info, name)
        if not got:
            continue
        has_zone, _rank, parsed, _raw = got
        if has_zone:
            continue
        return parsed[0]
    return None


def learn_offset(infos):
    diffs = []
    for info in infos:
        naive = camera_naive_epoch(info)
        gps = gps_epoch(info)
        if naive is None or gps is None:
            continue
        diffs.append(naive - gps)
    if not diffs:
        return None, "No file has both a camera time and a GPS time, so the offset cannot be learned. Pass --tz +02:00, or 0 if the camera clock is UTC."
    diffs.sort()
    spread = diffs[-1] - diffs[0]
    if spread > 5 * 60:
        return None, "The files that already have a GPS time do not agree on the camera offset (they differ by %s). Pass --tz yourself." % fmt_gap(spread)
    mid = len(diffs) // 2
    if len(diffs) % 2:
        med = diffs[mid]
    else:
        med = (diffs[mid - 1] + diffs[mid]) / 2.0
    learned = int(round(med / 60.0)) * 60
    note = "from %d file%s that already store a GPS time" % (len(diffs), "" if len(diffs) == 1 else "s")
    return learned, note


def local_tag(tag):
    if "}" in tag:
        return tag.rsplit("}", 1)[1]
    return tag


def open_xml(path):
    try:
        handle = open(path, "rb")
    except OSError as exc:
        return None, str(exc)
    if handle.read(3) != b"\xef\xbb\xbf":
        handle.seek(0)
    return handle, None


def finish_point(points, lat_raw, lon_raw, when, ele, path):
    """Add one point. Return 'ok', 'skip' (place without time, or time without place), or 'drop'."""
    if lat_raw is None or lon_raw is None or not when:
        if (lat_raw is not None and lon_raw is not None and not when) or (when and (lat_raw is None or lon_raw is None)):
            return "skip"
        return "drop"
    try:
        lat = float(lat_raw)
        lon = float(lon_raw)
    except (TypeError, ValueError):
        return "drop"
    if null_island(lat, lon) or abs(lat) > 90 or abs(lon) > 180:
        return "drop"
    parsed = parse_time_epoch(str(when).strip())
    if not parsed:
        return "drop"
    # A track time with no zone is UTC. parse_time_epoch already reads a naive clock that way.
    ele_num = None
    if ele is not None and str(ele).strip() != "":
        try:
            ele_num = float(ele)
        except ValueError:
            ele_num = None
    points.append((parsed[0], lat, lon, ele_num, path))
    return "ok"


def load_gpx(path):
    points = []
    skipped = 0
    handle, err = open_xml(path)
    if err:
        return None, err
    try:
        for _event, elem in ET.iterparse(handle, events=("end",)):
            tag = local_tag(elem.tag)
            if tag not in ("trkpt", "rtept", "wpt"):
                continue
            lat_raw = elem.get("lat")
            lon_raw = elem.get("lon")
            when = None
            ele = None
            for child in list(elem):
                child_tag = local_tag(child.tag)
                if child_tag == "time" and child.text:
                    when = child.text
                elif child_tag == "ele" and child.text:
                    ele = child.text
            elem.clear()
            state = finish_point(points, lat_raw, lon_raw, when, ele, path)
            if state == "skip":
                skipped += 1
    except ET.ParseError as exc:
        return None, "not valid XML (%s)" % exc
    finally:
        handle.close()
    points.sort(key=lambda item: item[0])
    return (points, skipped), None


def load_tcx(path):
    """Garmin Training Center. Activity laps and courses both store Trackpoint elements."""
    points = []
    skipped = 0
    handle, err = open_xml(path)
    if err:
        return None, err
    try:
        for _event, elem in ET.iterparse(handle, events=("end",)):
            if local_tag(elem.tag) != "Trackpoint":
                continue
            when = None
            lat_raw = None
            lon_raw = None
            ele = None
            for child in list(elem):
                child_tag = local_tag(child.tag)
                if child_tag == "Time" and child.text:
                    when = child.text
                elif child_tag == "AltitudeMeters" and child.text:
                    ele = child.text
                elif child_tag == "Position":
                    for sub in list(child):
                        sub_tag = local_tag(sub.tag)
                        if sub_tag == "LatitudeDegrees" and sub.text:
                            lat_raw = sub.text
                        elif sub_tag == "LongitudeDegrees" and sub.text:
                            lon_raw = sub.text
            elem.clear()
            state = finish_point(points, lat_raw, lon_raw, when, ele, path)
            if state == "skip":
                skipped += 1
    except ET.ParseError as exc:
        return None, "not valid XML (%s)" % exc
    finally:
        handle.close()
    points.sort(key=lambda item: item[0])
    return (points, skipped), None


def load_track(path):
    if path.lower().endswith(".tcx"):
        return load_tcx(path)
    return load_gpx(path)


def track_label(path):
    if path.lower().endswith(".tcx"):
        return "TCX"
    return "GPX"


def nearest_index(points, epoch):
    if not points:
        return None
    lo = 0
    hi = len(points)
    while lo < hi:
        mid = (lo + hi) // 2
        if points[mid][0] < epoch:
            lo = mid + 1
        else:
            hi = mid
    cands = []
    if lo < len(points):
        cands.append(lo)
    if lo > 0:
        cands.append(lo - 1)
    return min(cands, key=lambda index: (abs(points[index][0] - epoch), index))


def haversine_m(lat1, lon1, lat2, lon2):
    radius = 6371000.0
    p1 = math.radians(lat1)
    p2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lon2 - lon1)
    aa = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * radius * math.asin(min(1.0, math.sqrt(aa)))


def other_track(points, chosen_i, epoch, max_gap):
    chosen = points[chosen_i]
    best = None
    for step in (-1, 1):
        index = chosen_i + step
        while 0 <= index < len(points) and abs(points[index][0] - epoch) <= max_gap:
            if points[index][4] != chosen[4]:
                gap = abs(points[index][0] - epoch)
                dist = haversine_m(chosen[1], chosen[2], points[index][1], points[index][2])
                if best is None or gap < best[0]:
                    best = (gap, dist, points[index][4])
            index += step
    if best and best[1] > DISAGREE_METRES:
        return best
    return None


def kind_of(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in (".mp4", ".mov"):
        return "video"
    return "photo"


def display_path(path, roots):
    absolute = os.path.abspath(path)
    best = None
    for root in roots:
        root_abs = os.path.abspath(root)
        try:
            rel = os.path.relpath(absolute, root_abs)
        except ValueError:
            continue
        if rel.startswith(".."):
            continue
        rel = rel.replace("\\", "/")
        if best is None or len(rel) < len(best):
            best = rel
    if best:
        return best
    return absolute


def clock_hint(far_rows, match_count, offset_seconds, quicktime, max_gap):
    if match_count or len(far_rows) < 3:
        return None
    signed = [row["signed"] for row in far_rows]
    if max(signed) - min(signed) > 15 * 60:
        return None
    ordered = sorted(signed)
    mid = len(ordered) // 2
    if len(ordered) % 2:
        med = ordered[mid]
    else:
        med = (ordered[mid - 1] + ordered[mid]) / 2.0
    if abs(med) <= max_gap:
        return None
    place = "before" if med < 0 else "after"
    text = "The closest points are all about %s %s the time taken from the files. That is a fixed clock difference. " % (
        fmt_gap(abs(med)), place,
    )
    naive = sum(1 for row in far_rows if row["basis"] == "naive")
    zoned = sum(1 for row in far_rows if row["basis"] == "zoned")
    if naive * 2 >= len(far_rows):
        suggested = int(round((offset_seconds - med) / 60.0)) * 60
        text += "These times have no timezone of their own. A camera offset of %s lines them up with the track." % fmt_offset(suggested)
    elif zoned * 2 >= len(far_rows) and quicktime == "utc":
        text += "Video CreateDate is read as UTC. If the camera stored local time there, run again with --quicktime local."
    elif zoned * 2 >= len(far_rows):
        text += "These times were read as local camera time. If the video clock is actually UTC, run again with --quicktime utc."
    return text.rstrip()


def run_exiftool_json(exiftool, paths, quicktime):
    if not paths:
        return []
    folder = tempfile.mkdtemp(prefix="geotag-missing-")
    argfile = os.path.join(folder, "files.txt")
    try:
        with open(argfile, "wb") as handle:
            for path in paths:
                handle.write(os.fsencode(path))
                handle.write(b"\n")
        cmd = [
            exiftool, "-m", "-json", "-n", "-a", "-G1",
            "-charset", "filename=utf8",
            "-api", "LargeFileSupport=1",
        ]
        if quicktime == "utc":
            cmd.extend(["-api", "QuickTimeUTC=1"])
        tags = [
            "DateTimeOriginal", "SubSecDateTimeOriginal", "OffsetTimeOriginal", "OffsetTime",
            "CreationDate", "CreateDate", "MediaCreateDate", "TrackCreateDate",
            "FileCreateDate", "FileModifyDate",
            "GPSLatitude", "GPSLongitude", "GPSAltitude",
            "GPSDateStamp", "GPSTimeStamp", "GPSDateTime", "GPSCoordinates",
        ]
        for tag in tags:
            cmd.append("-" + tag)
        cmd.extend(["-@", argfile])
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    finally:
        shutil.rmtree(folder, ignore_errors=True)
    stdout = proc.stdout.decode("utf-8", "replace").strip()
    stderr = proc.stderr.decode("utf-8", "replace").strip()
    if not stdout.startswith("["):
        if stderr:
            eprint(stderr)
        elif stdout:
            eprint(stdout)
        else:
            eprint("exiftool returned nothing.")
        return None
    if proc.returncode not in (0, 1) and stderr:
        eprint(stderr)
    try:
        return json.loads(stdout)
    except ValueError:
        eprint("exiftool did not return a file list.")
        return None


def count_geotag_need(media, infos):
    """Files with no location need a geotag. A location already stored does not."""
    by_key = {}
    for info in infos:
        source = info.get("SourceFile")
        if source:
            by_key[norm_key(source)] = info
    need = 0
    already = 0
    unread = 0
    for path in media:
        info = by_key.get(norm_key(path))
        if info is None or info.get("Error"):
            unread += 1
            continue
        if position_from_tags(info) is None:
            need += 1
        else:
            already += 1
    return need, already, unread


def match_files(media, infos, points, offset_seconds, max_gap, redo):
    by_key = {}
    for info in infos:
        source = info.get("SourceFile")
        if source:
            by_key[norm_key(source)] = info
    rows = []
    for path in media:
        info = by_key.get(norm_key(path))
        if info is None or info.get("Error"):
            rows.append({
                "path": path,
                "status": "unread",
                "wall": "",
                "source": "",
                "detail": (info or {}).get("Error") or "exiftool did not read this file",
                "epoch": None,
                "basis": "",
                "signed": None,
                "kind": kind_of(path),
            })
            continue
        when = pick_time(info, offset_seconds)
        pos = position_from_tags(info)
        chosen = None
        gap = None
        signed = None
        warn = None
        point = None
        if when and points:
            index = nearest_index(points, when["epoch"])
            point = points[index]
            gap = abs(point[0] - when["epoch"])
            signed = point[0] - when["epoch"]
            if gap <= max_gap:
                chosen = point
                extra = other_track(points, index, when["epoch"], max_gap)
                if extra:
                    warn = "%s is %s away" % (os.path.basename(extra[2]), fmt_metres(extra[1]))
        has_gps = pos is not None
        close = chosen is not None
        if has_gps and redo and close:
            status = "replace"
        elif has_gps:
            status = "tagged"
        elif when is None:
            status = "no time"
        elif not points:
            status = "no track"
        elif close:
            status = "match"
        else:
            status = "too far"
        place = ""
        height = ""
        if status == "tagged" and pos:
            place = fmt_pos(pos[0], pos[1], None)
            height = fmt_height(pos[2])
            detail = ""
        elif status in ("match", "replace") and chosen:
            place = fmt_pos(chosen[1], chosen[2], None)
            height = fmt_height(chosen[3])
            detail = "gap %s, %s" % (fmt_gap(gap), os.path.basename(chosen[4]))
            if warn:
                detail += " (%s)" % warn
        elif status == "too far":
            detail = "nearest %s, point %s UTC" % (fmt_gap(gap), fmt_utc(points[nearest_index(points, when["epoch"])][0]))
        elif status == "no time":
            detail = "no time in the file"
        elif status == "no track":
            detail = "no track point with a time"
        else:
            detail = ""
        row = {
            "path": path,
            "status": status,
            "wall": when["wall"] if when else "",
            "source": when["source"] if when else "",
            "place": place,
            "height": height,
            "detail": detail,
            "epoch": when["epoch"] if when else None,
            "basis": when["basis"] if when else "",
            "signed": signed,
            "kind": kind_of(path),
            "warn": warn,
            "near": None,
        }
        if status == "too far" and point is not None:
            row["near"] = {
                "phrase": near_phrase(signed),
                "lat": "%.6f" % point[1],
                "lon": "%.6f" % point[2],
                "ele": fmt_height(point[3]),
                "track": os.path.basename(point[4]),
            }
        if status in ("match", "replace") and chosen:
            stamp = datetime.fromtimestamp(chosen[0], timezone.utc)
            row["write"] = {
                "path": path,
                "kind": row["kind"],
                "lat": chosen[1],
                "lon": chosen[2],
                "ele": chosen[3],
                "gps_date": stamp.strftime("%Y:%m:%d"),
                "gps_time": stamp.strftime("%H:%M:%S"),
                "label": os.path.basename(path),
                "method": "TRACK",
                "gap": fmt_gap(gap) if gap is not None else "",
                "track": os.path.basename(chosen[4]),
                "place": place,
                "height": height,
                "status": status,
            }
        rows.append(row)
    return rows


def parse_conf(path):
    places = []
    track_dirs = []
    errors = []
    pending = None
    pending_line = 0
    pending_got = False
    try:
        handle = open(path, encoding="utf-8")
    except OSError as exc:
        return [], [], ["%s: %s" % (path, exc)]
    with handle:
        lines = handle.read().splitlines()

    def close_pending():
        if not pending or pending_got:
            return
        if pending.lower() == "tracks-location":
            errors.append("%s:%d: [tracks-location] has no directory" % (path, pending_line))
        else:
            errors.append("%s:%d: [%s] has no coordinates" % (path, pending_line, pending))

    for number, line in enumerate(lines, 1):
        text = line.strip()
        if not text or text.startswith("#"):
            continue
        if text.startswith("[") and text.endswith("]"):
            close_pending()
            pending = text[1:-1].strip()
            pending_line = number
            pending_got = False
            if not pending:
                errors.append("%s:%d: empty name" % (path, number))
                pending = None
            continue
        if pending and pending.lower() == "tracks-location":
            track_dirs.append({"path": text.strip().strip('"').strip("'"), "source": path, "line": number})
            pending_got = True
            continue
        match = COORD_RE.match(text)
        if pending and match:
            lat = float(match.group(1))
            lon = float(match.group(2))
            if abs(lat) > 90 or abs(lon) > 180 or null_island(lat, lon):
                errors.append("%s:%d: coordinates are out of range" % (path, number))
            else:
                places.append({
                    "label": pending, "lat": lat, "lon": lon,
                    "source": path, "line": number,
                })
            pending = None
            pending_got = False
            continue
        errors.append("%s:%d: not a [name] or latitude, longitude" % (path, number))
    close_pending()
    return places, track_dirs, errors


def coord_key(lat, lon):
    """About 0.1 m. Copies of one place written with a slightly different rounding still match."""
    return (round(lat, 6), round(lon, 6))


def where_place(place):
    return "%s:%s" % (place["source"], place.get("line") or "?")


def resolve_track_path(raw, conf_path):
    text = raw.strip().strip('"').strip("'")
    match = re.match(r"^([A-Za-z]):[\\/](.*)$", text)
    if match:
        drive = match.group(1).lower()
        rest = match.group(2).replace("\\", "/")
        if os.path.isdir("/mnt/%s" % drive):
            text = "/mnt/%s/%s" % (drive, rest)
    if not os.path.isabs(text):
        text = os.path.join(os.path.dirname(os.path.abspath(conf_path)), text)
    return os.path.normpath(text)


def skip_track_name(name):
    return name.startswith("._") or "_old-" in name or name.endswith(".partial") or ".partial." in name


def chosen_under(root, paths):
    """How many of the already chosen track files sit in root."""
    root_key = norm_key(root)
    if os.path.isfile(root):
        return 1 if any(norm_key(path) == root_key for path in paths) else 0
    prefix = root_key.rstrip("\\/") + os.sep
    count = 0
    for path in paths:
        key = norm_key(path)
        if key == root_key or key.startswith(prefix):
            count += 1
    return count


def tracks_under(root):
    """GPX and TCX files in root and in every subdirectory under it."""
    if os.path.isfile(root):
        name = os.path.basename(root)
        if name.lower().endswith((".gpx", ".tcx")) and not skip_track_name(name):
            return [root]
        return []
    if not os.path.isdir(root):
        return None
    found = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [item for item in dirnames if not item.startswith(".")]
        for name in filenames:
            if skip_track_name(name):
                continue
            if name.lower().endswith((".gpx", ".tcx")):
                found.append(os.path.join(dirpath, name))
    found.sort()
    return found


def merge_confs(paths):
    """Same coordinates are one place. The same name with two different coordinates is an error.

    Files are listed closest directory first, so that copy is the one that is kept.
    """
    places = []
    by_name = {}
    by_coord = {}
    notes = []
    errors = []
    track_roots = []
    seen_roots = set()
    for path in paths:
        found, tracks, problems = parse_conf(path)
        errors.extend(problems)
        for item in tracks:
            resolved = resolve_track_path(item["path"], path)
            key = os.path.normcase(os.path.abspath(resolved))
            if key in seen_roots:
                continue
            seen_roots.add(key)
            if not os.path.exists(resolved):
                errors.append("%s:%d: track directory is not there: %s" % (path, item["line"], item["path"]))
                continue
            track_roots.append(resolved)
        for place in found:
            key = coord_key(place["lat"], place["lon"])
            name = place["label"]
            if name in by_name:
                prev = places[by_name[name]]
                if coord_key(prev["lat"], prev["lon"]) == key:
                    continue
                errors.append(
                    "[%s] has two locations: %s (%s) and %s (%s). The one in %s is used."
                    % (
                        name,
                        fmt_pos(prev["lat"], prev["lon"], None), where_place(prev),
                        fmt_pos(place["lat"], place["lon"], None), "%s:%s" % (path, place.get("line") or "?"),
                        where_place(prev),
                    )
                )
                continue
            if key in by_coord:
                prev = places[by_coord[key]]
                if name not in prev["names"]:
                    prev["names"].append(name)
                    prev["label"] = " / ".join(prev["names"])
                    notes.append(
                        "Same location, merged: %s at %s."
                        % (", ".join("[%s]" % item for item in prev["names"]), fmt_pos(prev["lat"], prev["lon"], None))
                    )
                by_name[name] = by_coord[key]
                continue
            place["names"] = [name]
            places.append(place)
            index = len(places) - 1
            by_name[name] = index
            by_coord[key] = index
    return places, notes, errors, track_roots


def sort_places(places):
    places.sort(key=lambda place: place["label"].casefold())


def print_place_banner(paths, places, notes, errors, track_roots, gpx_paths, track_span):
    if not paths:
        extra = ""
        profile = os.environ.get("profile_location_dir")
        if profile:
            extra = " Also %s, %s/etc, and %s/conf." % (profile, profile, profile)
        print("Places: no video-pgm-geotag-missing-media.conf in /etc, $HOME, $HOME/etc, or $HOME/conf.%s" % extra)
        print("")
        return
    print("Places from %s config file%s:" % (len(paths), "" if len(paths) == 1 else "s"))
    for path in paths:
        print("  %s" % path)
    if errors:
        print(paint("Config errors:", "31"))
        for err in errors:
            print(paint("  %s" % err, "31"))
    if places:
        print("  " + "  ".join("[%s]" % place["label"] for place in places))
    else:
        print("  No places in those files.")
    if track_roots:
        print("Tracks also from (this directory and every subdirectory):")
        for root in track_roots:
            count = chosen_under(root, gpx_paths)
            print("  %s" % root)
            if track_span and track_span != "all":
                print("    %s .gpx/.tcx files from %s" % (fmt_int(count), track_span))
            else:
                print("    %s .gpx/.tcx files" % fmt_int(count))
    for note in notes:
        print("  %s" % note)
    print("")


def stamp_from_epoch(epoch):
    if epoch is None:
        return "", ""
    when = datetime.fromtimestamp(epoch, timezone.utc)
    return when.strftime("%Y:%m:%d"), when.strftime("%H:%M:%S")


def cell(text, width, code=""):
    text = text or ""
    pad = " " * max(0, width - len(text))
    if code and text:
        return paint(text, code) + pad
    return text + pad


def print_file_rows(rows, status):
    """Same columns as file_table, with the file in green and the location in blue."""
    last = {
        "match": "gap, track",
        "replace": "gap, track",
        "too far": "nearest point",
        "unread": "problem",
    }.get(status, "detail")
    show_last = any(row.get("detail") for row in rows)
    file_w = max([len("file")] + [len(row.get("show") or "") for row in rows])
    time_w = max([len("time")] + [len(row.get("wall") or "") for row in rows])
    from_w = max([len("from")] + [len(row.get("source") or "") for row in rows])
    place_w = max([len("location")] + [len(row.get("place") or "") for row in rows])
    height_w = max([len("height")] + [len(row.get("height") or "") for row in rows])
    header = "  %-8s  %-*s   %-*s   %-*s   %-*s   %-*s" % (
        "status", file_w, "file", time_w, "time", from_w, "from", place_w, "location", height_w, "height",
    )
    if show_last:
        header += "   %s" % last
    print(header)
    status_code = STATUS_COLOR.get(status, "")
    for row in rows:
        status_cell = "%-8s" % status
        if status_code:
            status_cell = paint(status_cell, status_code)
        line = "  %s  %s   %s   %s   %s   %s" % (
            status_cell,
            cell(row.get("show") or "", file_w, "32"),
            cell(row.get("wall") or "", time_w),
            cell(row.get("source") or "", from_w),
            cell(row.get("place") or "", place_w, "94"),
            cell(row.get("height") or "", height_w, "94"),
        )
        if show_last:
            line += "   %s" % (row.get("detail") or "")
        print(line)


def file_table(rows, status):
    """One header and one aligned line per file."""
    last = {
        "match": "gap, track",
        "replace": "gap, track",
        "too far": "nearest point",
        "unread": "problem",
    }.get(status, "detail")
    show_last = any(row.get("detail") for row in rows)
    file_w = max([len("file")] + [len(row.get("show") or "") for row in rows])
    time_w = max([len("time")] + [len(row.get("wall") or "") for row in rows])
    from_w = max([len("from")] + [len(row.get("source") or "") for row in rows])
    place_w = max([len("location")] + [len(row.get("place") or "") for row in rows])
    height_w = max([len("height")] + [len(row.get("height") or "") for row in rows])

    def line(status_text, show, wall, source, place, height, detail):
        text = "  %-8s  %-*s   %-*s   %-*s   %-*s   %-*s" % (
            status_text, file_w, show, time_w, wall, from_w, source, place_w, place, height_w, height,
        )
        if show_last:
            text += "   %s" % detail
        return text

    header = line("status", "file", "time", "from", "location", "height", last if show_last else "")
    body = [
        line(
            status,
            row.get("show") or "",
            row.get("wall") or "",
            row.get("source") or "",
            row.get("place") or "",
            row.get("height") or "",
            row.get("detail") or "",
        )
        for row in rows
    ]
    return header, body


def print_report(rows, gpx_info, gpx_errors, offset_seconds, tz_note, assumed, max_gap, scope, quicktime, redo, places, verbose):
    counts = {}
    for row in rows:
        counts[row["status"]] = counts.get(row["status"], 0) + 1

    def count(name):
        return counts.get(name, 0)

    bits = ["%s files" % fmt_int(len(rows))]
    bits.append("%s already have a location" % fmt_int(count("tagged")))
    if count("match"):
        bits.append("%s can be tagged" % fmt_int(count("match")))
    if count("replace"):
        bits.append("%s will be replaced" % fmt_int(count("replace")))
    if count("too far"):
        bits.append("%s are too far" % fmt_int(count("too far")))
    if count("no time"):
        bits.append("%s have no time" % fmt_int(count("no time")))
    if count("no track"):
        bits.append("%s have nothing to compare" % fmt_int(count("no track")))
    if count("unread"):
        bits.append("%s could not be read" % fmt_int(count("unread")))
    print(paint(".  ".join(bits) + ".", "1"))
    print("Scope: %s.  A match is a track point within %s." % (scope, fmt_gap(max_gap) if max_gap >= 10 else ("%gs" % max_gap)))
    if assumed:
        clock = "Camera offset: %s (this was assumed; pass --tz to choose it)." % fmt_offset(offset_seconds)
    elif tz_note:
        clock = "Camera offset: %s (%s)." % (fmt_offset(offset_seconds), tz_note)
    else:
        clock = "Camera offset: %s. A camera time with no timezone of its own is this far from UTC." % fmt_offset(offset_seconds)
    print(clock)
    if quicktime == "utc":
        print("Video CreateDate is read as UTC.")
    else:
        print("Video CreateDate is read as local camera time, then the camera offset is applied.")
    print("Track times are UTC. One location is written: the point closest to the start of the file.")
    if gpx_info:
        total = sum(item["points"] for item in gpx_info)
        print("Tracks: %s file%s, %s points." % (
            fmt_int(len(gpx_info)), "" if len(gpx_info) == 1 else "s", fmt_int(total),
        ))
        if verbose:
            for item in gpx_info:
                if item["points"]:
                    span = "%s to %s UTC" % (fmt_utc(item["start"]), fmt_utc(item["end"]))
                else:
                    span = "no points with a time and a position"
                extra = ""
                if item["skipped"]:
                    extra = ", %s without a time or a position" % fmt_int(item["skipped"])
                print("  %s  %s points, %s%s  %s" % (
                    item["kind"], fmt_int(item["points"]), span, extra, paint(item["label"], "32"),
                ))
    else:
        print("Tracks: none.")
    for err in gpx_errors:
        print("  Could not read %s: %s" % (err[0], err[1]))
    far_rows = [row for row in rows if row["status"] == "too far" and row["signed"] is not None]
    hint = clock_hint(far_rows, count("match") + count("replace"), offset_seconds, quicktime, max_gap)
    if hint:
        print(paint(hint, "33"))
    if verbose:
        sections = (
            ("match", "Can add a location"),
            ("replace", "Will replace the location already in the file"),
            ("too far", "No point within %s" % (fmt_gap(max_gap) if max_gap >= 10 else ("%gs" % max_gap))),
            ("no time", "No time to compare"),
            ("no track", "No track point to compare"),
            ("unread", "Could not be read"),
            ("tagged", "Already have a location"),
        )
        told_places = False
        for status, title in sections:
            chosen = [row for row in rows if row["status"] == status]
            if not chosen:
                continue
            print("")
            print(paint("%s (%s)" % (title, fmt_int(len(chosen))), "1"))
            if places and status in UNMATCHED and not told_places:
                print("  These files have no track point. The place names above are the choices.")
                told_places = True
            chosen.sort(key=lambda row: (row["epoch"] is None, row["epoch"] or 0, row["show"]))
            print_file_rows(chosen, status)
    if redo:
        print("")
        print("--redo is set: a file that already has a location is written again when a point is close enough.")


def method_of(item):
    method = item.get("method") or "TRACK"
    if method not in ("TRACK", "MANUAL"):
        return "TRACK"
    return method


def photo_args(item):
    lat = item["lat"]
    lon = item["lon"]
    args = [
        "-GPSLatitude=%s" % abs(lat),
        "-GPSLatitudeRef=%s" % ("N" if lat >= 0 else "S"),
        "-GPSLongitude=%s" % abs(lon),
        "-GPSLongitudeRef=%s" % ("E" if lon >= 0 else "W"),
        "-GPSProcessingMethod=%s" % method_of(item),
    ]
    if item.get("gps_date") and item.get("gps_time") and item.get("gps_date") != "-" and item.get("gps_time") != "-":
        args.append("-GPSDateStamp=%s" % item["gps_date"])
        args.append("-GPSTimeStamp=%s" % item["gps_time"])
    ele = item.get("ele")
    if ele is not None:
        args.append("-GPSAltitude=%s" % abs(ele))
        args.append("-GPSAltitudeRef=%s" % ("Above Sea Level" if ele >= 0 else "Below Sea Level"))
    return args


def video_coord(item):
    if item.get("ele") is None:
        return "%.7f, %.7f" % (item["lat"], item["lon"])
    return "%.7f, %.7f, %.3f" % (item["lat"], item["lon"], item["ele"])


def video_args(item):
    coord = video_coord(item)
    method = method_of(item)
    return [
        "-Keys:GPSCoordinates=%s" % coord,
        "-UserData:GPSCoordinates=%s" % coord,
        "-ItemList:GPSCoordinates=%s" % coord,
        "-XMP-exif:GPSProcessingMethod=%s" % method,
    ]


def fmt_bytes(n):
    if n >= 1024 ** 3:
        return "%.1f GB" % (n / 1024 ** 3)
    if n >= 1024 ** 2:
        return "%.1f MB" % (n / 1024 ** 2)
    if n >= 1024:
        return "%.1f kB" % (n / 1024)
    return "%d bytes" % n


def copy_space_needed(size):
    """A full copy of the file, plus 10%."""
    return size + size // 10


def room_for_copy(path):
    try:
        size = os.path.getsize(path)
    except OSError as exc:
        return False, "Cannot read the file size: %s" % exc
    need = copy_space_needed(size)
    folder = os.path.dirname(path) or "."
    try:
        free = shutil.disk_usage(folder).free
    except OSError as exc:
        return False, "Cannot read free space: %s" % exc
    if free >= need:
        return True, ""
    return False, (
        "Not enough free space to copy this file aside. "
        "Need %s (the file plus 10%%). %s is free."
        % (fmt_bytes(need), fmt_bytes(free))
    )


KEEP_BACKUP = False
BACKUP_STAMP = ""


def take_backup(args):
    global KEEP_BACKUP, BACKUP_STAMP
    KEEP_BACKUP = bool(getattr(args, "backup", False))
    BACKUP_STAMP = getattr(args, "backup_stamp", "") or ""


def backup_filename(name, stamp):
    base, ext = os.path.splitext(name)
    return "%s_old-%s%s" % (base, stamp, ext)


def unique_backup(path):
    folder, name = os.path.split(path)
    stamp = BACKUP_STAMP or datetime.now().strftime("%Y%m%d_%H%M%S")
    candidate = os.path.join(folder, backup_filename(name, stamp))
    n = 2
    while os.path.exists(candidate):
        base, ext = os.path.splitext(name)
        candidate = os.path.join(folder, "%s_old-%s-%d%s" % (base, stamp, n, ext))
        n += 1
    return candidate


def keep_old_file(path):
    sidecar = path + "_original"
    if not os.path.isfile(sidecar):
        return ""
    dest = unique_backup(path)
    os.replace(sidecar, dest)
    return dest


def write_one(exiftool, item):
    ok, message = room_for_copy(item["path"])
    if not ok:
        return False, message
    if item["kind"] == "video":
        args = video_args(item)
    else:
        args = photo_args(item)
    cmd = [exiftool, "-P", "-m", "-api", "LargeFileSupport=1"]
    if not KEEP_BACKUP:
        cmd.append("-overwrite_original")
    cmd.extend(args)
    cmd.append(item["path"])
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out = proc.stdout.decode("utf-8", "replace").strip()
    err = proc.stderr.decode("utf-8", "replace").strip()
    if proc.returncode != 0:
        return False, err or out or "exiftool failed"
    if KEEP_BACKUP:
        return True, keep_old_file(item["path"])
    return True, ""


def parse_user_coord(text):
    match = COORD_RE.match(text.strip())
    if not match:
        return None
    lat = float(match.group(1))
    lon = float(match.group(2))
    if abs(lat) > 90 or abs(lon) > 180 or null_island(lat, lon):
        return None
    return match.group(1), match.group(2)


def parse_year_range(text):
    """One year, or a range. Spaces and dashes are the same separator.

    Returns ((start, end), None), or (None, "order") when the first year is newer,
    or (None, "bad") when the text is not a year.
    """
    raw = text.strip().lower()
    raw = raw.replace("–", " ").replace("—", " ").replace("−", " ").replace("-", " ")
    raw = re.sub(r"\bto\b", " ", raw)
    raw = re.sub(r"\s+", " ", raw).strip()
    if not raw:
        return None, "bad"
    parts = raw.split(" ")
    if not all(re.fullmatch(r"\d{4}", part) for part in parts):
        return None, "bad"
    if len(parts) == 1:
        year = int(parts[0])
        return (year, year), None
    if len(parts) == 2:
        start, end = int(parts[0]), int(parts[1])
        if start > end:
            return None, "order"
        return (start, end), None
    return None, "bad"


def cmd_year_range(argv):
    if len(argv) != 1:
        return 1
    span, err = parse_year_range(argv[0])
    if err == "order":
        return 2
    if not span:
        return 1
    print("%s\t%s" % span)
    return 0


def cmd_check_coord(argv):
    if len(argv) != 1:
        return 1
    parsed = parse_user_coord(argv[0])
    if not parsed:
        return 1
    print("%s\t%s" % parsed)
    return 0


def place_line(payload):
    address = payload.get("address") or {}
    road = address.get("road") or address.get("pedestrian") or address.get("footway") or address.get("path")
    number = address.get("house_number")
    if road and number:
        road = "%s %s" % (road, number)
    locality = (
        address.get("city") or address.get("town") or address.get("village")
        or address.get("hamlet") or address.get("municipality")
    )
    country = address.get("country")
    parts = [part for part in (road, locality, country) if part]
    if parts:
        return ", ".join(parts)
    display = (payload.get("display_name") or "").strip()
    bits = [part.strip() for part in display.split(",") if part.strip()]
    return ", ".join(bits[:3])


def reverse_place(lat, lon, timeout=12):
    query = urllib.parse.urlencode({
        "lat": lat,
        "lon": lon,
        "format": "jsonv2",
        "addressdetails": "1",
        "zoom": "18",
    })
    request = urllib.request.Request(
        "https://nominatim.openstreetmap.org/reverse?%s" % query,
        headers={
            "User-Agent": "video-pgm-geotag-missing-media (local media geotag)",
            "Accept-Language": "pl,en",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as handle:
            payload = json.loads(handle.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, OSError, json.JSONDecodeError, ValueError):
        return None
    if not isinstance(payload, dict) or payload.get("error"):
        return ""
    return place_line(payload)


def cmd_reverse(argv):
    if len(argv) != 2:
        return 1
    try:
        lat = float(argv[0])
        lon = float(argv[1])
    except ValueError:
        return 1
    if abs(lat) > 90 or abs(lon) > 180 or null_island(lat, lon):
        return 1
    line = reverse_place(argv[0], argv[1])
    if line is None:
        return 2
    if not line:
        return 1
    print(line)
    return 0


def cmd_track_roots(argv):
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--conf-list", required=True)
    args = parser.parse_args(argv)
    _places, _notes, _errors, track_roots = merge_confs(read_paths(args.conf_list))
    for root in track_roots:
        print(root)
    return 0


def cmd_check_tz(argv):
    if len(argv) != 1:
        return 1
    try:
        seconds = parse_tz_seconds(argv[0])
    except ValueError:
        return 1
    print(fmt_offset(seconds))
    return 0


def fmt_left(seconds):
    t = int(seconds + 0.5)
    if t < 1:
        return "0s"
    hours = t // 3600
    minutes = (t % 3600) // 60
    secs = t % 60
    if hours:
        return "%dh %dm" % (hours, minutes)
    if minutes:
        return "%dm %ds" % (minutes, secs)
    return "%ds" % secs


def fmt_arrival(remain):
    when = datetime.now() + timedelta(seconds=remain)
    if when.second >= 30:
        when = when.replace(second=0, microsecond=0) + timedelta(minutes=1)
    else:
        when = when.replace(second=0, microsecond=0)
    if when.date() == datetime.now().date():
        return "at %s" % when.strftime("%H:%M")
    return "at %s" % when.strftime("%Y.%m.%d %H:%M")


def track_progress(done, total, started, points, span, final=False):
    if total <= 0:
        return
    width = 40
    pct = int(round(100.0 * done / total))
    if pct > 100:
        pct = 100
    filled = int(round(width * done / float(total)))
    if filled > width:
        filled = width
    bar = "#" * filled + "-" * (width - filled)
    label = "Tracks" if not span or span == "all" else "Tracks %s" % span
    elapsed = time.time() - started
    if final:
        tail = "%s  %s points" % (fmt_left(elapsed), fmt_int(points))
    elif done > 0 and done < total:
        remain = elapsed / done * (total - done)
        tail = "left %s  %s" % (fmt_left(remain), fmt_arrival(remain))
    else:
        tail = "left --  at --"
    text = "%s [%s] %3d%%  %s/%s files  %s" % (
        label, bar, pct, fmt_int(done), fmt_int(total), tail,
    )
    sys.stderr.write("\r%s\033[K" % text)
    if final:
        sys.stderr.write("\n")
    sys.stderr.flush()


def cmd_scan(argv):
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--tz", required=True)
    parser.add_argument("--tz-assumed", action="store_true")
    parser.add_argument("--max-gap", type=float, required=True)
    parser.add_argument("--quicktime", choices=("utc", "local"), required=True)
    parser.add_argument("--exiftool", required=True)
    parser.add_argument("--media-list", required=True)
    parser.add_argument("--gpx-list", required=True)
    parser.add_argument("--root-list", required=True)
    parser.add_argument("--conf-list", default="")
    parser.add_argument("--plan", required=True)
    parser.add_argument("--scope", required=True)
    parser.add_argument("--track-span", default="")
    parser.add_argument("--exif-json", default="")
    parser.add_argument("--redo", action="store_true")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--colors", action="store_true")
    args = parser.parse_args(argv)
    take_colors(args)
    if args.max_gap < 0:
        eprint("--max-gap must be zero or more.")
        return 1
    conf_paths = read_paths(args.conf_list) if args.conf_list else []
    places, notes, conf_errors, track_roots = merge_confs(conf_paths)
    sort_places(places)
    media = read_paths(args.media_list)
    gpx_paths = read_paths(args.gpx_list)
    roots = read_paths(args.root_list)
    print_place_banner(conf_paths, places, notes, conf_errors, track_roots, gpx_paths, args.track_span)
    for root in track_roots:
        if os.path.isdir(root):
            roots.append(root)
        elif os.path.isfile(root):
            roots.append(os.path.dirname(root))
    gpx_paths.sort(key=lambda path: (os.path.basename(path).casefold(), os.path.normcase(path)))
    points = []
    gpx_info = []
    gpx_errors = []
    track_total = len(gpx_paths)
    track_done = 0
    point_total = 0
    track_started = time.time()
    if track_total:
        track_progress(0, track_total, track_started, 0, args.track_span)
    for path in gpx_paths:
        loaded, err = load_track(path)
        track_done += 1
        finished = track_done == track_total
        if err:
            gpx_errors.append((os.path.basename(path), err))
            sys.stderr.write("\n")
            eprint("Could not read %s: %s" % (path, err))
            track_progress(track_done, track_total, track_started, point_total, args.track_span, finished)
            continue
        file_points, skipped = loaded
        info = {
            "path": path,
            "kind": track_label(path),
            "label": display_path(path, roots) if roots else os.path.basename(path),
            "points": len(file_points),
            "skipped": skipped,
            "start": file_points[0][0] if file_points else None,
            "end": file_points[-1][0] if file_points else None,
        }
        gpx_info.append(info)
        points.extend(file_points)
        point_total += len(file_points)
        track_progress(track_done, track_total, track_started, point_total, args.track_span, finished)
    points.sort(key=lambda item: (item[0], item[4]))
    infos = None
    if args.exif_json and os.path.isfile(args.exif_json) and os.path.getsize(args.exif_json) > 0:
        try:
            with open(args.exif_json, encoding="utf-8") as handle:
                infos = json.load(handle)
        except (OSError, ValueError):
            infos = None
    if infos is None:
        eprint("Reading times and locations from %s file%s..." % (fmt_int(len(media)), "" if len(media) == 1 else "s"))
        infos = run_exiftool_json(args.exiftool, media, args.quicktime)
    if infos is None:
        return 1
    assumed = args.tz_assumed
    tz_note = ""
    if args.tz == "auto":
        learned, note = learn_offset(infos)
        if learned is None:
            eprint(note)
            return 1
        offset_seconds = learned
        tz_note = note
        assumed = False
        eprint("Camera offset %s, %s." % (fmt_offset(offset_seconds), note))
    else:
        try:
            offset_seconds = parse_tz_seconds(args.tz)
        except ValueError:
            eprint("Camera offset is not one I can use: %s" % args.tz)
            eprint("Examples: +02:00, -05:30, 0, auto.")
            return 1
    rows = match_files(media, infos, points, offset_seconds, args.max_gap, args.redo)
    for row in rows:
        row["show"] = display_path(row["path"], roots) if roots else row["path"]
    gpx_info.sort(key=lambda item: (item["start"] is None, item["start"] or 0, item["label"]))
    print_report(
        rows, gpx_info, gpx_errors, offset_seconds, tz_note, assumed,
        args.max_gap, args.scope, args.quicktime, args.redo, places, args.verbose,
    )
    writes = []
    choose = []
    for row in rows:
        if "write" in row:
            item = row["write"]
            item["label"] = row["show"]
            writes.append(item)
        if row["status"] in UNMATCHED:
            gps_date, gps_time = stamp_from_epoch(row["epoch"])
            near = row.get("near") or {}
            choose.append({
                "path": row["path"],
                "kind": row["kind"],
                "show": row["show"],
                "gps_date": gps_date,
                "gps_time": gps_time,
                "status": row["status"],
                "near_phrase": near.get("phrase") or "",
                "near_lat": near.get("lat") or "",
                "near_lon": near.get("lon") or "",
                "near_ele": near.get("ele") or "",
                "near_track": near.get("track") or "",
            })
    plan = {
        "write_count": len(writes),
        "writes": writes,
        "places": [{"label": place["label"], "lat": place["lat"], "lon": place["lon"]} for place in places],
        "choose": choose,
        "counts": {
            "files": len(rows),
            "already": sum(1 for row in rows if row["status"] == "tagged"),
            "unmatched": sum(1 for row in rows if row["status"] in UNMATCHED),
            "unread": sum(1 for row in rows if row["status"] == "unread"),
            "tracks": len(gpx_info),
            "points": sum(item["points"] for item in gpx_info),
        },
    }
    with open(args.plan, "w", encoding="utf-8") as handle:
        json.dump(plan, handle)
    return 0


def smart_window(media, infos, offset_seconds, before_days=7, after_days=7):
    """Earliest and latest file time, then the chosen days before and after those dates."""
    by_key = {}
    for info in infos or []:
        source = info.get("SourceFile")
        if source:
            by_key[norm_key(source)] = info
    dated = []
    for path in media:
        info = by_key.get(norm_key(path))
        when = None
        if info and not info.get("Error"):
            when = pick_time(info, offset_seconds)
        if when:
            match = re.match(r"^(\d{4})\.(\d{2})\.(\d{2})(?: (\d{2}:\d{2}))?", when.get("wall") or "")
            if match:
                try:
                    day = date(int(match.group(1)), int(match.group(2)), int(match.group(3)))
                except ValueError:
                    day = None
                if day is not None:
                    shown = "%s.%s.%s" % match.group(1, 2, 3)
                    if match.group(4):
                        shown = "%s %s" % (shown, match.group(4))
                    dated.append((day, shown))
                    continue
        name = re.match(r"^((?:19|20)\d{2})(\d{2})(\d{2})", os.path.basename(path))
        if not name:
            continue
        try:
            day = date(int(name.group(1)), int(name.group(2)), int(name.group(3)))
        except ValueError:
            continue
        dated.append((day, "%04d.%02d.%02d" % (day.year, day.month, day.day)))
    if not dated:
        return None
    dated.sort()
    first_day, first_text = dated[0]
    last_day, last_text = dated[-1]
    return first_text, last_text, first_day - timedelta(days=before_days), last_day + timedelta(days=after_days)


def cmd_smart_span(argv):
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--tz", required=True)
    parser.add_argument("--exif-json", required=True)
    parser.add_argument("--media-list", required=True)
    parser.add_argument("--before", type=int, default=7)
    parser.add_argument("--after", type=int, default=7)
    args = parser.parse_args(argv)
    if args.before < 0 or args.after < 0:
        return 1
    if args.tz == "auto":
        offset_seconds = 0
    else:
        try:
            offset_seconds = parse_tz_seconds(args.tz)
        except ValueError:
            return 1
    infos = []
    if os.path.isfile(args.exif_json) and os.path.getsize(args.exif_json) > 0:
        try:
            with open(args.exif_json, encoding="utf-8") as handle:
                infos = json.load(handle)
        except (OSError, ValueError):
            return 1
    got = smart_window(read_paths(args.media_list), infos, offset_seconds, args.before, args.after)
    if not got:
        return 1
    first, last, start, end = got

    def show(day):
        return "%04d.%02d.%02d" % (day.year, day.month, day.day)

    print("%s\t%s\t%s\t%s" % (first, last, show(start), show(end)))
    return 0


def cmd_need_geotag(argv):
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--exiftool", required=True)
    parser.add_argument("--quicktime", choices=("utc", "local"), required=True)
    parser.add_argument("--media-list", required=True)
    parser.add_argument("--exif-json", required=True)
    args = parser.parse_args(argv)
    media = read_paths(args.media_list)
    eprint("Reading times and locations from %s file%s..." % (fmt_int(len(media)), "" if len(media) == 1 else "s"))
    infos = run_exiftool_json(args.exiftool, media, args.quicktime)
    if infos is None:
        return 1
    with open(args.exif_json, "w", encoding="utf-8") as handle:
        json.dump(infos, handle)
    need, already, unread = count_geotag_need(media, infos)
    print("%d\t%d\t%d" % (need, already, unread))
    return 0


def cmd_write(argv):
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--exiftool", required=True)
    parser.add_argument("--plan", required=True)
    parser.add_argument("--only-list", default="")
    parser.add_argument("--address-list", default="")
    parser.add_argument("--colors", action="store_true")
    parser.add_argument("--backup", action="store_true")
    parser.add_argument("--backup-stamp", default="")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args(argv)
    take_colors(args)
    take_backup(args)
    with open(args.plan, encoding="utf-8") as handle:
        plan = json.load(handle)
    writes = plan.get("writes") or []
    if args.only_list:
        keep = set(norm_key(path) for path in read_paths(args.only_list))
        writes = [item for item in writes if norm_key(item["path"]) in keep]
    if not writes:
        plan["wrote_tracks"] = 0
        with open(args.plan, "w", encoding="utf-8") as handle:
            json.dump(plan, handle)
        print("Nothing to write.")
        return 0
    failed = 0
    wrote = 0
    total = len(writes)
    addresses = read_address_pairs(args.address_list) if args.address_list else {}
    for number, item in enumerate(writes, 1):
        if number > 1:
            print()
        name = paint(item.get("label") or os.path.basename(item["path"]), "32")
        print_processing(number, total, name, "start processing")
        started = time.monotonic()
        ok, message = write_one(args.exiftool, item)
        elapsed = time.monotonic() - started
        if ok:
            wrote += 1
            mark = print_processing(number, total, name, "processing is complete.", elapsed)
            print_written_place(
                mark, item["lat"], item["lon"], item.get("ele"),
                addresses.get(norm_key(item["path"]), ""),
            )
            if message and args.verbose:
                print("    Old file kept as: %s" % message, flush=True)
        else:
            failed += 1
            print_processing(number, total, name, "processing could not be completed.", elapsed)
            if message:
                print("    %s" % message.splitlines()[-1], flush=True)
    plan["wrote_tracks"] = wrote
    with open(args.plan, "w", encoding="utf-8") as handle:
        json.dump(plan, handle)
    print()
    if wrote == 0:
        print("No files updated from tracks.")
    elif wrote == 1:
        print("1 file updated from a track.")
    else:
        print("%s files updated from tracks." % fmt_int(wrote))
    if failed:
        print("%s file%s could not be written." % (fmt_int(failed), "" if failed == 1 else "s"))
        return 1
    return 0


def cmd_plan_lines(argv):
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--plan", required=True)
    args = parser.parse_args(argv)
    with open(args.plan, encoding="utf-8") as handle:
        plan = json.load(handle)
    for place in plan.get("places") or []:
        label = str(place["label"]).replace("\t", " ")
        print("PLACE\t%s\t%s\t%s" % (label, place["lat"], place["lon"]))
    for item in plan.get("writes") or []:
        print("WRITE\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s" % (
            item["path"],
            str(item.get("label") or "").replace("\t", " "),
            str(item.get("place") or "").replace("\t", " "),
            str(item.get("height") or "").replace("\t", " "),
            str(item.get("gap") or "").replace("\t", " "),
            str(item.get("track") or "").replace("\t", " "),
            str(item.get("method") or "TRACK").replace("\t", " "),
            str(item.get("status") or "match").replace("\t", " "),
        ))
    for item in plan.get("choose") or []:
        show = str(item.get("show") or "").replace("\t", " ")
        print("CHOOSE\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s" % (
            one_line(item["path"]), one_line(item["kind"]), one_line(show),
            one_line(item.get("gps_date")),
            one_line(item.get("gps_time")),
            one_line(item.get("status")),
            one_line(item.get("near_phrase")),
            one_line(item.get("near_lat")),
            one_line(item.get("near_lon")),
            one_line(item.get("near_ele")),
            one_line(item.get("near_track")),
        ))
    return 0


def cmd_write_place(argv):
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--exiftool", required=True)
    parser.add_argument("--path", required=True)
    parser.add_argument("--kind", required=True)
    parser.add_argument("--lat", type=float, required=True)
    parser.add_argument("--lon", type=float, required=True)
    parser.add_argument("--gps-date", default="")
    parser.add_argument("--gps-time", default="")
    parser.add_argument("--label", default="")
    parser.add_argument("--place", default="")
    parser.add_argument("--colors", action="store_true")
    parser.add_argument("--backup", action="store_true")
    parser.add_argument("--backup-stamp", default="")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--number", type=int, default=1)
    parser.add_argument("--total", type=int, default=1)
    args = parser.parse_args(argv)
    take_colors(args)
    take_backup(args)
    item = {
        "path": args.path,
        "kind": args.kind,
        "lat": args.lat,
        "lon": args.lon,
        "ele": None,
        "gps_date": args.gps_date,
        "gps_time": args.gps_time,
        "label": args.label or os.path.basename(args.path),
        "method": "MANUAL",
    }
    shown = paint(args.label or os.path.basename(args.path), "32")
    print_processing(args.number, args.total, shown, "start processing")
    started = time.monotonic()
    ok, message = write_one(args.exiftool, item)
    elapsed = time.monotonic() - started
    if ok:
        mark = print_processing(args.number, args.total, shown, "processing is complete.", elapsed)
        print_written_place(mark, args.lat, args.lon, None, args.place)
        if message and args.verbose:
            print("    Old file kept as: %s" % message, flush=True)
        return 0
    print_processing(args.number, args.total, shown, "processing could not be completed.", elapsed)
    if message:
        print("    %s" % message.splitlines()[-1], flush=True)
    return 1


def selftest():
    assert took_phrase(4) == "Took 4s."
    assert took_phrase(65) == "Took 1m 5s."
    assert took_phrase(0.2) == "Took 0s."
    assert near_phrase(45) == "45 seconds ahead"
    assert near_phrase(-45) == "45 seconds ago"
    assert near_phrase(1) == "1 second ahead"
    assert near_phrase(60) == "about 1 minute ahead"
    assert near_phrase(89) == "about 1 minute ahead"
    assert near_phrase(90) == "about 2 minutes ahead"
    assert near_phrase(120) == "about 2 minutes ahead"
    assert near_phrase(-300) == "about 5 minutes ago"
    assert near_phrase(3600) == "about 1 hour ahead"
    assert near_phrase(-(3 * 3600)) == "about 3 hours ago"
    assert near_phrase(150) == "about 3 minutes ahead"
    assert clock_stamp(datetime(2026, 10, 12, 13, 47, 18)) == "[ 2026.10.12 13:47:18 ]"
    assert place_suffix("Ponice, Polska") == " (Ponice, Polska)"
    assert place_suffix("typed") == ""
    assert place_suffix("  ") == ""
    assert fmt_pos(49.590316, 19.966978, 515) + place_suffix("Ponice, Polska") == "49.590316, 19.966978, 515m (Ponice, Polska)"
    assert copy_space_needed(1000) == 1100
    assert copy_space_needed(0) == 0
    assert backup_filename("clip.mp4", "20261012_121700") == "clip_old-20261012_121700.mp4"
    assert parse_tz_seconds("+02:00") == 7200
    window = smart_window(
        ["20260824_a.mp4", "20260827_b.mp4"],
        [
            {"SourceFile": "20260824_a.mp4", "EXIF:DateTimeOriginal": "2026:08:24 16:51:10"},
            {"SourceFile": "20260827_b.mp4", "EXIF:DateTimeOriginal": "2026:08:27 19:30:00"},
        ],
        7200,
    )
    assert window[0] == "2026.08.24 16:51"
    assert window[1] == "2026.08.27 19:30"
    assert window[2] == date(2026, 8, 17)
    assert window[3] == date(2026, 9, 3)
    tight = smart_window(
        ["20260824_a.mp4", "20260827_b.mp4"],
        [
            {"SourceFile": "20260824_a.mp4", "EXIF:DateTimeOriginal": "2026:08:24 16:51:10"},
            {"SourceFile": "20260827_b.mp4", "EXIF:DateTimeOriginal": "2026:08:27 19:30:00"},
        ],
        7200, 3, 1,
    )
    assert tight[2] == date(2026, 8, 21)
    assert tight[3] == date(2026, 8, 28)
    named = smart_window(["20260824_only.mp4"], [], 0)
    assert named[2] == date(2026, 8, 17)
    assert named[3] == date(2026, 8, 31)
    assert smart_window(["clip.mp4"], [], 0) is None
    header, body = file_table(
        [
            {"show": "short.jpg", "wall": "2026.08.24 16:51:10", "source": "DateTimeOriginal", "place": "49.609049, 19.965396", "height": "534m", "detail": ""},
            {"show": "a-longer-name.jpg", "wall": "2026.08.24 17:20:29", "source": "CreateDate", "place": "49.608870, 19.968328", "height": "", "detail": ""},
        ],
        "tagged",
    )
    assert header.index("file") == body[0].index("short.jpg") == body[1].index("a-longer-name.jpg")
    assert header.index("time") == body[0].index("2026.08.24 16:51:10") == body[1].index("2026.08.24 17:20:29")
    assert header.index("from") == body[0].index("DateTimeOriginal") == body[1].index("CreateDate")
    assert header.index("location") == body[0].index("49.609049, 19.965396") == body[1].index("49.608870, 19.968328")
    height_at = header.index("height")
    assert body[0][height_at:height_at + 4] == "534m"
    assert body[1][height_at] == " "
    assert count_geotag_need(
        ["a.jpg", "b.jpg", "c.jpg"],
        [
            {"SourceFile": "a.jpg", "EXIF:GPSLatitude": 50.0, "EXIF:GPSLongitude": 19.0},
            {"SourceFile": "b.jpg"},
        ],
    ) == (1, 1, 1)
    assert parse_tz_seconds("-05:30") == -(5 * 3600 + 30 * 60)
    assert parse_tz_seconds("0") == 0
    assert parse_user_coord("49.59078922757009, 19.966572075569914") == ("49.59078922757009", "19.966572075569914")
    assert parse_user_coord("0, 0") is None
    assert parse_user_coord("Ponice") is None
    assert parse_year_range("2026") == ((2026, 2026), None)
    assert parse_year_range("2026-2027") == ((2026, 2027), None)
    assert parse_year_range("2026 - 2027") == ((2026, 2027), None)
    assert parse_year_range("2026- 2027") == ((2026, 2027), None)
    assert parse_year_range("2026  2027") == ((2026, 2027), None)
    assert parse_year_range("2026 to 2027") == ((2026, 2027), None)
    assert parse_year_range("2026–2027") == ((2026, 2027), None)
    assert parse_year_range("2027-2026") == (None, "order")
    assert parse_year_range("nope") == (None, "bad")
    assert place_line({
        "address": {"road": "Racławicka", "house_number": "146", "city": "Warszawa", "country": "Polska"},
    }) == "Racławicka 146, Warszawa, Polska"
    assert place_line({"display_name": "Racławicka, Ochota, Warszawa, Mazowieckie, Polska"}) == "Racławicka, Ochota, Warszawa"
    assert place_line({}) == ""
    assert fmt_offset(7200) == "+02:00"
    assert fmt_offset(-(3600 + 1800)) == "-01:30"
    naive = parse_time_epoch("2026:08:01 16:00:00")
    assert naive == (calendar.timegm(datetime(2026, 8, 1, 16, 0, 0).timetuple()), False)
    assert naive[0] - 7200 == calendar.timegm(datetime(2026, 8, 1, 14, 0, 0).timetuple())
    zoned = parse_time_epoch("2026:08:01 16:00:00+02:00")
    assert zoned[1] is True
    assert zoned[0] == calendar.timegm(datetime(2026, 8, 1, 14, 0, 0).timetuple())
    gpx_time = parse_time_epoch("2026-08-01T16:00:00+02:00")
    assert gpx_time[0] == zoned[0]
    assert parse_time_epoch("2026-08-01T14:00:00Z")[0] == zoned[0]

    t0 = calendar.timegm(datetime(2026, 8, 1, 14, 0, 0).timetuple())
    points = [
        (t0, 50.0, 19.0, 200.0, "day.gpx"),
        (t0 + 2, 50.1, 19.1, 201.0, "day.gpx"),
    ]
    index = nearest_index(points, t0 + 0.4)
    assert index == 0
    assert abs(points[index][0] - (t0 + 0.4)) < 0.5
    far = nearest_index(points, t0 + 3600)
    assert abs(points[far][0] - (t0 + 3600)) > 30
    points_two = points + [(t0, 51.0, 19.0, 10.0, "other.gpx")]
    points_two.sort(key=lambda item: (item[0], item[4]))
    # The two points at t0 sort by path: day.gpx then other.gpx.
    chosen = nearest_index(points_two, t0)
    warn = other_track(points_two, chosen, t0, 30)
    assert warn is not None
    assert warn[1] > 1000

    picked = pick_time({
        "EXIF:DateTimeOriginal": "2026:08:01 16:00:00",
        "EXIF:OffsetTimeOriginal": "+02:00",
    }, 0)
    assert abs(picked["epoch"] - t0) < 0.01
    assert picked["basis"] == "zoned"

    picked_naive = pick_time({"EXIF:DateTimeOriginal": "2026:08:01 16:00:00"}, 7200)
    assert abs(picked_naive["epoch"] - t0) < 0.01
    assert picked_naive["basis"] == "naive"

    # A zoned QuickTime time wins over a naive EXIF CreateDate of the same tag name.
    both = best_time_value({
        "EXIF:CreateDate": "2026:08:01 16:00:00",
        "QuickTime:CreateDate": "2026:08:01 16:00:00+02:00",
    }, "CreateDate")
    assert both[0] is True
    assert abs(both[2][0] - t0) < 0.01

    assert position_from_tags({"EXIF:GPSLatitude": 0, "EXIF:GPSLongitude": 0}) is None
    pos = position_from_tags({"Keys:GPSCoordinates": "50.5, 19.25, 10"})
    assert pos[:2] == (50.5, 19.25)
    iso = parse_gps_coordinates("+50.5+019.25+010/")
    assert iso[0] == 50.5 and abs(iso[1] - 19.25) < 1e-9

    hint = clock_hint(
        [{"signed": -7200, "basis": "naive"}, {"signed": -7200, "basis": "naive"}, {"signed": -7260, "basis": "naive"}],
        0, 0, "utc", 30,
    )
    assert hint and "+02:00" in hint
    assert clock_hint([{"signed": -7200, "basis": "naive"}], 0, 0, "utc", 30) is None
    assert clock_hint(
        [{"signed": -7200, "basis": "naive"}, {"signed": -7200, "basis": "naive"}, {"signed": -7200, "basis": "naive"}],
        2, 0, "utc", 30,
    ) is None

    learned, note = learn_offset([
        {"EXIF:DateTimeOriginal": "2026:08:01 16:00:00", "EXIF:GPSDateStamp": "2026:08:01", "EXIF:GPSTimeStamp": 14 * 3600},
        {"EXIF:DateTimeOriginal": "2026:08:01 17:00:00", "Composite:GPSDateTime": "2026:08:01 15:00:00Z"},
    ])
    assert learned == 7200
    assert "2 file" in note

    folder = tempfile.mkdtemp(prefix="geotag-selftest-")
    try:
        gpx_path = os.path.join(folder, "day.gpx")
        with open(gpx_path, "w", encoding="utf-8") as handle:
            handle.write(
                "<?xml version='1.0' encoding='UTF-8'?>\n"
                "<gpx version='1.1' xmlns='http://www.topografix.com/GPX/1/1'>\n"
                "<trk><trkseg>\n"
                "<trkpt lat='50.0' lon='19.0'><ele>200</ele><time>2026-08-01T14:00:00Z</time></trkpt>\n"
                "<trkpt lat='0' lon='0'><time>2026-08-01T14:00:01Z</time></trkpt>\n"
                "<trkpt lat='50.2' lon='19.2'><ele>210</ele></trkpt>\n"
                "<trkpt lat='50.1' lon='19.1'><ele>205</ele><time>2026-08-01T14:00:02Z</time></trkpt>\n"
                "</trkseg></trk></gpx>\n"
            )
        loaded, err = load_gpx(gpx_path)
        assert err is None
        file_points, skipped = loaded
        assert skipped == 1
        assert len(file_points) == 2
        assert file_points[0][1] == 50.0
        assert abs(file_points[0][0] - t0) < 0.01
        rows = match_files(
            [os.path.join(folder, "clip.mp4"), os.path.join(folder, "pic.jpg")],
            [
                {"SourceFile": os.path.join(folder, "clip.mp4"), "QuickTime:CreateDate": "2026:08:01 14:00:01Z"},
                {"SourceFile": os.path.join(folder, "pic.jpg"), "EXIF:DateTimeOriginal": "2026:08:01 18:00:00", "EXIF:GPSLatitude": 51.0, "EXIF:GPSLongitude": 20.0},
            ],
            file_points, 7200, 30, False,
        )
        by_name = {os.path.basename(row["path"]): row for row in rows}
        assert by_name["clip.mp4"]["status"] == "match"
        assert by_name["clip.mp4"]["write"]["lat"] == 50.0
        assert by_name["clip.mp4"]["write"]["method"] == "TRACK"
        assert "-GPSProcessingMethod=MANUAL" in photo_args({"lat": 50.0, "lon": 19.0, "method": "MANUAL"})
        assert "-XMP-exif:GPSProcessingMethod=TRACK" in video_args({"lat": 50.0, "lon": 19.0, "ele": None, "method": "TRACK"})
        assert by_name["pic.jpg"]["status"] == "tagged"
        redone = match_files(
            [os.path.join(folder, "pic.jpg")],
            [{"SourceFile": os.path.join(folder, "pic.jpg"), "EXIF:DateTimeOriginal": "2026:08:01 16:00:00", "EXIF:GPSLatitude": 51.0, "EXIF:GPSLongitude": 20.0}],
            file_points, 7200, 30, True,
        )
        assert redone[0]["status"] == "replace"

        tcx_path = os.path.join(folder, "ride.tcx")
        with open(tcx_path, "w", encoding="utf-8") as handle:
            handle.write(
                "<?xml version='1.0' encoding='UTF-8'?>\n"
                "<TrainingCenterDatabase xmlns='http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2'>\n"
                "<Activities><Activity Sport='Biking'><Lap StartTime='2026-08-01T14:00:00Z'><Track>\n"
                "<Trackpoint><Time>2026-08-01T14:00:00Z</Time><Position>"
                "<LatitudeDegrees>50.0</LatitudeDegrees><LongitudeDegrees>19.0</LongitudeDegrees>"
                "</Position><AltitudeMeters>200</AltitudeMeters></Trackpoint>\n"
                "<Trackpoint><Time>2026-08-01T14:00:02Z</Time><Position>"
                "<LatitudeDegrees>50.1</LatitudeDegrees><LongitudeDegrees>19.1</LongitudeDegrees>"
                "</Position><AltitudeMeters>205</AltitudeMeters></Trackpoint>\n"
                "<Trackpoint><Time>2026-08-01T14:00:03Z</Time></Trackpoint>\n"
                "</Track></Lap></Activity></Activities>\n"
                "<Courses><Course><Track><Trackpoint><Time>2026-08-01T14:00:04Z</Time><Position>"
                "<LatitudeDegrees>50.3</LatitudeDegrees><LongitudeDegrees>19.3</LongitudeDegrees>"
                "</Position></Trackpoint></Track></Course></Courses>\n"
                "</TrainingCenterDatabase>\n"
            )
        loaded, err = load_track(tcx_path)
        assert err is None
        file_points, skipped = loaded
        assert skipped == 1
        assert len(file_points) == 3
        assert file_points[0][1] == 50.0
        assert abs(file_points[0][0] - t0) < 0.01
        assert file_points[0][3] == 200.0
        assert file_points[2][1] == 50.3
        assert track_label(tcx_path) == "TCX"
        tcx_rows = match_files(
            [os.path.join(folder, "from-tcx.jpg")],
            [{"SourceFile": os.path.join(folder, "from-tcx.jpg"), "EXIF:DateTimeOriginal": "2026:08:01 16:00:01"}],
            file_points, 7200, 30, False,
        )
        assert tcx_rows[0]["status"] == "match"
        assert tcx_rows[0]["write"]["lat"] == 50.0
        assert tcx_rows[0]["write"]["ele"] == 200.0

        near = os.path.join(folder, "near.conf")
        far_conf = os.path.join(folder, "home.conf")
        track_dir = os.path.join(folder, "tracks")
        nested = os.path.join(track_dir, "day")
        os.makedirs(nested)
        with open(os.path.join(nested, "day.gpx"), "w", encoding="utf-8") as handle:
            handle.write("<gpx></gpx>\n")
        with open(os.path.join(track_dir, "skip.txt"), "w", encoding="utf-8") as handle:
            handle.write("nope\n")
        with open(near, "w", encoding="utf-8") as handle:
            handle.write(
                "[Ponice 221]\n"
                "49.59078922757009, 19.966572075569914\n\n"
                "[Shared]\n"
                "50.0, 19.0\n"
                "[tracks-location]\n"
                "%s\n" % track_dir
            )
        with open(far_conf, "w", encoding="utf-8") as handle:
            handle.write(
                "[Raclawicka 146]\n"
                "52.19856710851843, 20.980003905723805\n"
                "[Shared]\n"
                "51.0, 20.0\n"
                "[Home]\n"
                "50.0, 19.0\n"
                "[Ponice 221]\n"
                "49.59078922757009, 19.966572075569914\n"
                "[Broken]\n"
                "not-coords\n"
                "[tracks-location]\n"
                "/no/such/tracks\n"
            )
        merged, notes, errors, track_roots = merge_confs([near, far_conf])
        labels = [place["label"] for place in merged]
        assert labels == ["Ponice 221", "Shared / Home", "Raclawicka 146"]
        sort_places(merged)
        assert [place["label"] for place in merged] == ["Ponice 221", "Raclawicka 146", "Shared / Home"]
        assert next(place["lat"] for place in merged if place["label"] == "Shared / Home") == 50.0
        assert any("Shared" in note and "Home" in note for note in notes)
        assert any("Broken" in err for err in errors)
        assert any(err.startswith("[Shared] has two locations") for err in errors)
        assert not any(err.startswith("[Ponice 221] has two locations") for err in errors)
        assert track_roots == [os.path.normpath(track_dir)]
        assert any("not there" in err for err in errors)
        found_tracks = tracks_under(track_dir)
        assert len(found_tracks) == 1
        assert found_tracks[0].endswith("day.gpx")
        assert chosen_under(track_dir, found_tracks) == 1
        assert chosen_under(track_dir, []) == 0
    finally:
        shutil.rmtree(folder, ignore_errors=True)

    exiftool = shutil.which("exiftool")
    if exiftool:
        folder = tempfile.mkdtemp(prefix="geotag-exif-")
        try:
            jpg = os.path.join(folder, "one.jpg")
            # 1x1 JPEG.
            jpg_bytes = bytes.fromhex(
                "ffd8ffe000104a46494600010100000100010000ffdb004300080606070605080707070909080a0c140d0c0b0b0c1912130f141d1a1f1e1d1a1c1c20242e2720222c231c1c2837292c30313434341f27393d38323c2e333432ffc0000b080001000101011100ffc4001f0000010501010101010100000000000000000102030405060708090a0bffc400b5100002010303020403050504040000017d01020300041105122131410613516107227114328191a1082342b1c11552d1f02433627282090a161718191a25262728292a3435363738393a434445464748494a535455565758595a636465666768696a737475767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae1e2e3e4e5e6e7e8e9eaf1f2f3f4f5f6f7f8f9faffda00080001000100003f00fbffd9"
            )
            with open(jpg, "wb") as handle:
                handle.write(jpg_bytes)
            item = {
                "path": jpg, "kind": "photo", "lat": 50.061234, "lon": 19.9401, "ele": 200.0,
                "gps_date": "2026:08:01", "gps_time": "14:00:02", "label": "one.jpg",
            }
            ok, message = write_one(exiftool, item)
            assert ok, message
            infos = run_exiftool_json(exiftool, [jpg], "utc")
            assert infos
            got = position_from_tags(infos[0])
            assert got is not None
            assert abs(got[0] - 50.061234) < 1e-5
            assert abs(got[1] - 19.9401) < 1e-5
        finally:
            shutil.rmtree(folder, ignore_errors=True)
    print("selftest ok")
    return 0


def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print("Usage: video-pgm-geotag-missing-media.py scan|write|write-place|plan-lines|check-tz|check-coord|reverse|year-range|track-roots|need-geotag|smart-span|selftest")
        print("The shell script video-pgm-geotag-missing-media.sh is the way to run this.")
        return 0
    cmd = argv[1]
    if cmd == "selftest":
        return selftest()
    if cmd == "check-tz":
        return cmd_check_tz(argv[2:])
    if cmd == "check-coord":
        return cmd_check_coord(argv[2:])
    if cmd == "reverse":
        return cmd_reverse(argv[2:])
    if cmd == "year-range":
        return cmd_year_range(argv[2:])
    if cmd == "track-roots":
        return cmd_track_roots(argv[2:])
    if cmd == "need-geotag":
        return cmd_need_geotag(argv[2:])
    if cmd == "smart-span":
        return cmd_smart_span(argv[2:])
    if cmd == "scan":
        return cmd_scan(argv[2:])
    if cmd == "write":
        return cmd_write(argv[2:])
    if cmd == "write-place":
        return cmd_write_place(argv[2:])
    if cmd == "plan-lines":
        return cmd_plan_lines(argv[2:])
    eprint("Unknown command: %s" % cmd)
    return 1


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except KeyboardInterrupt:
        eprint("Interrupted.")
        sys.exit(130)
    except BrokenPipeError:
        sys.exit(0)
