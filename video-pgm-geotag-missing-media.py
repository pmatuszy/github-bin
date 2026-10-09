#!/usr/bin/env python3
# v. 20261009.160131 - also read .tcx tracks; a Trackpoint with a time and a position joins the same search as GPX
# v. 20261009.151425 - match a photo or video time to the nearest GPX point and write that location with exiftool

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
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

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


def use_color():
    return sys.stdout.isatty() and not os.environ.get("NO_COLOR")


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
        if status == "tagged" and pos:
            detail = fmt_pos(pos[0], pos[1], pos[2])
        elif status in ("match", "replace") and chosen:
            detail = "gap %s, %s, %s" % (fmt_gap(gap), fmt_pos(chosen[1], chosen[2], chosen[3]), os.path.basename(chosen[4]))
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
            "detail": detail,
            "epoch": when["epoch"] if when else None,
            "basis": when["basis"] if when else "",
            "signed": signed,
            "kind": kind_of(path),
            "warn": warn,
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
            }
        rows.append(row)
    return rows


def print_report(rows, gpx_info, gpx_errors, offset_seconds, tz_note, assumed, max_gap, scope, quicktime, redo):
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
        for item in gpx_info:
            if item["points"]:
                span = "%s to %s UTC" % (fmt_utc(item["start"]), fmt_utc(item["end"]))
            else:
                span = "no points with a time and a position"
            extra = ""
            if item["skipped"]:
                extra = ", %s without a time or a position" % fmt_int(item["skipped"])
            print("  %s  %s points, %s%s  %s" % (item["kind"], fmt_int(item["points"]), span, extra, item["label"]))
    else:
        print("Tracks: none.")
    for err in gpx_errors:
        print("  Could not read %s: %s" % (err[0], err[1]))
    far_rows = [row for row in rows if row["status"] == "too far" and row["signed"] is not None]
    hint = clock_hint(far_rows, count("match") + count("replace"), offset_seconds, quicktime, max_gap)
    if hint:
        print(paint(hint, "33"))
    sections = (
        ("match", "Can add a location"),
        ("replace", "Will replace the location already in the file"),
        ("too far", "No point within %s" % (fmt_gap(max_gap) if max_gap >= 10 else ("%gs" % max_gap))),
        ("no time", "No time to compare"),
        ("no track", "No track point to compare"),
        ("unread", "Could not be read"),
        ("tagged", "Already have a location"),
    )
    for status, title in sections:
        chosen = [row for row in rows if row["status"] == status]
        if not chosen:
            continue
        print("")
        print(paint("%s (%s)" % (title, fmt_int(len(chosen))), "1"))
        chosen.sort(key=lambda row: (row["epoch"] is None, row["epoch"] or 0, row["show"]))
        for row in chosen:
            label = "%-8s" % status
            label = paint(label, STATUS_COLOR.get(status))
            bits = [row["show"]]
            if row["wall"]:
                bits.append(row["wall"])
            if row["source"]:
                bits.append(row["source"])
            if row["detail"]:
                bits.append(row["detail"])
            print("  %s  %s" % (label, "   ".join(bits)))
    if redo:
        print("")
        print("--redo is set: a file that already has a location is written again when a point is close enough.")


def photo_args(item):
    lat = item["lat"]
    lon = item["lon"]
    args = [
        "-GPSLatitude=%s" % abs(lat),
        "-GPSLatitudeRef=%s" % ("N" if lat >= 0 else "S"),
        "-GPSLongitude=%s" % abs(lon),
        "-GPSLongitudeRef=%s" % ("E" if lon >= 0 else "W"),
        "-GPSDateStamp=%s" % item["gps_date"],
        "-GPSTimeStamp=%s" % item["gps_time"],
    ]
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
    return [
        "-Keys:GPSCoordinates=%s" % coord,
        "-UserData:GPSCoordinates=%s" % coord,
        "-ItemList:GPSCoordinates=%s" % coord,
    ]


def write_one(exiftool, item):
    if item["kind"] == "video":
        args = video_args(item)
    else:
        args = photo_args(item)
    cmd = [
        exiftool, "-overwrite_original", "-P", "-m",
        "-api", "LargeFileSupport=1",
    ]
    cmd.extend(args)
    cmd.append(item["path"])
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out = proc.stdout.decode("utf-8", "replace").strip()
    err = proc.stderr.decode("utf-8", "replace").strip()
    if proc.returncode != 0:
        return False, err or out or "exiftool failed"
    return True, ""


def cmd_check_tz(argv):
    if len(argv) != 1:
        return 1
    try:
        seconds = parse_tz_seconds(argv[0])
    except ValueError:
        return 1
    print(fmt_offset(seconds))
    return 0


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
    parser.add_argument("--plan", required=True)
    parser.add_argument("--scope", required=True)
    parser.add_argument("--redo", action="store_true")
    args = parser.parse_args(argv)
    if args.max_gap < 0:
        eprint("--max-gap must be zero or more.")
        return 1
    media = read_paths(args.media_list)
    gpx_paths = read_paths(args.gpx_list)
    roots = read_paths(args.root_list)
    points = []
    gpx_info = []
    gpx_errors = []
    for path in gpx_paths:
        loaded, err = load_track(path)
        if err:
            gpx_errors.append((os.path.basename(path), err))
            eprint("Could not read %s: %s" % (path, err))
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
        if file_points:
            eprint("%s  %s points  %s to %s UTC  %s" % (
                info["kind"], fmt_int(len(file_points)), fmt_utc(file_points[0][0]), fmt_utc(file_points[-1][0]),
                os.path.basename(path),
            ))
        else:
            eprint("%s  no points with a time and a position  %s" % (info["kind"], os.path.basename(path)))
    points.sort(key=lambda item: (item[0], item[4]))
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
        args.max_gap, args.scope, args.quicktime, args.redo,
    )
    writes = []
    for row in rows:
        if "write" in row:
            item = row["write"]
            item["label"] = row["show"]
            writes.append(item)
    plan = {"write_count": len(writes), "writes": writes}
    with open(args.plan, "w", encoding="utf-8") as handle:
        json.dump(plan, handle)
    return 0


def cmd_write(argv):
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--exiftool", required=True)
    parser.add_argument("--plan", required=True)
    args = parser.parse_args(argv)
    with open(args.plan, encoding="utf-8") as handle:
        plan = json.load(handle)
    writes = plan.get("writes") or []
    if not writes:
        print("Nothing to write.")
        return 0
    failed = 0
    total = len(writes)
    width = len(str(total))
    for number, item in enumerate(writes, 1):
        ok, message = write_one(args.exiftool, item)
        prefix = "[%*d/%d]" % (width, number, total)
        if ok:
            print("%s %s  %s" % (prefix, item.get("label") or os.path.basename(item["path"]), fmt_pos(item["lat"], item["lon"], item.get("ele"))))
        else:
            failed += 1
            print("%s %s  could not write" % (prefix, item.get("label") or item["path"]))
            if message:
                print("    %s" % message.splitlines()[-1])
    print("Wrote %s file%s." % (fmt_int(total - failed), "" if total - failed == 1 else "s"))
    if failed:
        print("%s file%s could not be written." % (fmt_int(failed), "" if failed == 1 else "s"))
        return 1
    return 0


def selftest():
    assert parse_tz_seconds("+02:00") == 7200
    assert parse_tz_seconds("-05:30") == -(5 * 3600 + 30 * 60)
    assert parse_tz_seconds("0") == 0
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
        print("Usage: video-pgm-geotag-missing-media.py scan|write|check-tz|selftest")
        print("The shell script video-pgm-geotag-missing-media.sh is the way to run this.")
        return 0
    cmd = argv[1]
    if cmd == "selftest":
        return selftest()
    if cmd == "check-tz":
        return cmd_check_tz(argv[2:])
    if cmd == "scan":
        return cmd_scan(argv[2:])
    if cmd == "write":
        return cmd_write(argv[2:])
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
