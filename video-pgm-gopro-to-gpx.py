#!/usr/bin/env python3
# v. 20261006.210617 - read the GoPro GPS stream (GPS5 and GPS9) and write a GPX track

# 2026.10.06 - v. 0.1 - initial release: info and write; GPS5 (older cameras, time from GPSU) and GPS9 (time in each sample, days since 2000); points without a fix are left out
"""GPX track from a GoPro video, for video-pgm-gopro-to-gpx.sh.

The GPS is not a GPX file inside the video. It is the GoPro metadata stream
(handler "GoPro MET", codec gpmd). ffmpeg copies that stream out; this program
reads it.

Subcommands:
  info FILE       One line: ok, none, nogopro, or error.
  write FILE OUT  Write the GPX. The video is not changed.
  selftest        Check the reader on a made-up stream. No video and no ffmpeg.
"""

import argparse
import json
import os
import re
import shutil
import struct
import subprocess
import sys
from datetime import datetime, timedelta, timezone

VERSION = "0.1"
VERSION_LINE = re.compile(r"^# v\. (\d{8})\.(\d{6}) - (.*)$")
HISTORY_LINE = re.compile(r"^# (\d{4}\.\d{2}\.\d{2} - v\. \S+ - .*)$")

TYPE_SIZE = {
    "b": 1, "B": 1, "c": 1, "s": 2, "S": 2, "l": 4, "L": 4,
    "f": 4, "q": 4, "j": 8, "J": 8, "d": 8, "F": 4, "U": 16, "G": 16,
}
TYPE_CODE = {
    "b": "b", "B": "B", "s": "h", "S": "H", "l": "i", "L": "I",
    "f": "f", "q": "i", "j": "q", "J": "Q", "d": "d", "F": "4s",
}


def history_lines():
    lines = []
    try:
        with open(os.path.realpath(__file__), encoding="utf-8") as handle:
            for n, line in enumerate(handle):
                line = line.rstrip("\n")
                if n == 0 and line.startswith("#!"):
                    continue
                if VERSION_LINE.match(line) or HISTORY_LINE.match(line):
                    lines.append(line[2:])
                elif line.startswith("#") or not line.strip():
                    continue
                else:
                    break
    except OSError:
        pass
    return lines


def print_version_banner():
    title = os.path.basename(__file__)
    verline = "Version: unknown"
    for line in history_lines():
        match = VERSION_LINE.match("# " + line)
        if match:
            day, clock = match.group(1), match.group(2)
            verline = "Version: %s.%s (%s.%s.%s %s:%s:%s)" % (
                day, clock, day[0:4], day[4:6], day[6:8], clock[0:2], clock[2:4], clock[4:6])
            break
    width = 60
    print("\u250c" + "\u2500" * width + "\u2510")
    for text in (title, verline):
        print("\u2502 %-*.*s \u2502" % (width - 2, width - 2, text))
    print("\u2514" + "\u2500" * width + "\u2518")


def read_tty_key(tty, timeout):
    import select
    import termios
    import tty as ttymod
    fd = tty.fileno()
    old = termios.tcgetattr(fd)
    try:
        ttymod.setcbreak(fd)
        ready, _, _ = select.select([fd], [], [], timeout)
        return os.read(fd, 1).decode(errors="replace") if ready else ""
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


def print_script_history():
    lines = history_lines()
    name = os.path.basename(__file__)
    if not lines:
        print("%s: no changelog entries found in header." % name, file=sys.stderr)
        return 1
    print("%s changelog (%d %s):" % (name, len(lines), "entry" if len(lines) == 1 else "entries"))
    tty = None
    if sys.stdout.isatty():
        try:
            tty = open("/dev/tty", "rb", buffering=0)
        except OSError:
            tty = None
    if tty is None:
        print("\n".join(lines))
        return 0
    rows = shutil.get_terminal_size((80, 24)).lines
    page = 5 if rows < 8 else rows - 3
    i = 0
    with tty:
        while i < len(lines):
            print("\n".join(lines[i:i + page]))
            i += page
            if i >= len(lines):
                break
            sys.stdout.write("[%s] More history? [Y/n/q] (%d/%d shown): " % (
                datetime.now().strftime("%Y.%m.%d %H:%M:%S"), i, len(lines)))
            sys.stdout.flush()
            key = read_tty_key(tty, 3600).lower()
            print()
            if key in ("n", "q"):
                break
    return 0


def iter_klv(buf, start, end):
    """Yield (key, type, size, repeat, payload, nested) inside buf[start:end]."""
    off = start
    while off + 8 <= end:
        key = buf[off:off + 4]
        if key == b"\x00\x00\x00\x00" or not all(32 <= b < 127 for b in key):
            break
        typ = buf[off + 4]
        size = buf[off + 5]
        repeat = int.from_bytes(buf[off + 6:off + 8], "big")
        data_len = size * repeat
        padded = (data_len + 3) & ~3
        next_off = off + 8 + padded
        if next_off > end:
            break
        payload = buf[off + 8:off + 8 + data_len]
        nested = typ == 0
        yield key.decode("ascii", "replace"), typ, size, repeat, payload, nested
        off = next_off


def type_string_of(payload):
    text = payload.split(b"\x00", 1)[0].decode("ascii", "replace")
    return "".join(ch for ch in text if ch in TYPE_SIZE)


def unpack_values(payload, typ, struct_size, repeat, complex_type):
    """Flat list of numbers (or strings) from one KLV."""
    if typ == 0:
        return []
    if typ == ord("?"):
        chars = complex_type or ""
    elif typ == ord("c") or typ == ord("U"):
        return [payload.split(b"\x00", 1)[0]]
    else:
        base = chr(typ) if 32 <= typ < 127 else ""
        if base not in TYPE_SIZE or TYPE_SIZE[base] == 0:
            return []
        count = struct_size // TYPE_SIZE[base] if struct_size else 1
        if count < 1:
            count = 1
        chars = base * count
    if not chars or any(ch not in TYPE_CODE for ch in chars):
        return []
    sample_size = sum(TYPE_SIZE[ch] for ch in chars)
    if sample_size <= 0:
        return []
    fmt = ">" + "".join(TYPE_CODE[ch] for ch in chars)
    out = []
    for i in range(repeat):
        chunk = payload[i * sample_size:(i + 1) * sample_size]
        if len(chunk) < sample_size:
            break
        for value in struct.unpack(fmt, chunk):
            if isinstance(value, bytes):
                continue
            out.append(value)
    return out


def apply_scale(values, scale, width):
    if width < 1:
        width = 1
    rows = []
    for i in range(0, len(values) - width + 1, width):
        row = []
        for j in range(width):
            value = float(values[i + j])
            if scale:
                div = scale[j] if j < len(scale) else scale[-1]
                if div not in (0, 1):
                    value /= float(div)
            row.append(value)
        rows.append(row)
    return rows


def parse_gpsu(raw):
    if isinstance(raw, bytes):
        text = raw.decode("ascii", "replace")
    else:
        text = str(raw)
    text = text.strip("\x00 ").strip()
    if len(text) < 13:
        return None
    try:
        year = 2000 + int(text[0:2])
        month = int(text[2:4])
        day = int(text[4:6])
        hour = int(text[6:8])
        minute = int(text[8:10])
        sec = float(text[10:])
    except ValueError:
        return None
    whole = int(sec)
    micro = int(round((sec - whole) * 1_000_000))
    if micro >= 1_000_000:
        whole += 1
        micro -= 1_000_000
    try:
        return datetime(year, month, day, hour, minute, whole, micro, tzinfo=timezone.utc)
    except ValueError:
        return None


def gps9_time(days, secs):
    """days since 2000-01-01, secs since midnight. Milliseconds if still too big."""
    if secs > 86400:
        secs = secs / 1000.0
    whole = int(secs)
    micro = int(round((secs - whole) * 1_000_000))
    if micro >= 1_000_000:
        whole += 1
        micro -= 1_000_000
    try:
        return datetime(2000, 1, 1, tzinfo=timezone.utc) + timedelta(days=int(days), seconds=whole, microseconds=micro)
    except (OverflowError, ValueError):
        return None


def usable(lat, lon):
    if abs(lat) > 90 or abs(lon) > 180:
        return False
    if abs(lat) < 1e-8 and abs(lon) < 1e-8:
        return False
    return True


def streams_of(buf):
    """Each STRM as a list of (key, typ, size, repeat, payload)."""
    found = []

    def collect(buf_part):
        for key, _typ, _size, _repeat, payload, nested in iter_klv(buf_part, 0, len(buf_part)):
            if not nested:
                continue
            if key == "STRM":
                found.append([
                    (k, t, s, r, p) for k, t, s, r, p, _n in iter_klv(payload, 0, len(payload))
                ])
            else:
                collect(payload)

    collect(buf)
    return found


def klv_numbers(item, complex_type):
    key, typ, size, repeat, payload = item
    return unpack_values(payload, typ, size, repeat, complex_type)


def points_from_gpmf(buf):
    """(points, kind). points are (datetime, lat, lon, alt). kind is GPS5, GPS9, or ''."""
    gps5 = []
    gps9 = []
    for stream in streams_of(buf):
        complex_type = ""
        scale = []
        gpsu = None
        gpsf = None
        samples5 = []
        samples9 = []
        for item in stream:
            key = item[0]
            if key == "TYPE":
                complex_type = type_string_of(item[4])
            elif key == "SCAL":
                scale = klv_numbers(item, complex_type)
            elif key == "GPSU":
                raw = item[4]
                gpsu = parse_gpsu(raw)
            elif key == "GPSF":
                nums = klv_numbers(item, "")
                if nums:
                    gpsf = nums[0]
            elif key == "GPS5":
                samples5 = klv_numbers(item, "")
            elif key == "GPS9":
                samples9 = klv_numbers(item, complex_type)
        if gpsf == 0:
            continue
        if samples9:
            width = len(complex_type) if complex_type else 9
            if width < 7:
                width = 9
            for row in apply_scale(samples9, scale, width):
                if len(row) < 7:
                    continue
                fix = row[8] if len(row) > 8 else 3
                if fix == 0:
                    continue
                when = gps9_time(row[5], row[6])
                if when is None or not usable(row[0], row[1]):
                    continue
                alt = row[2] if len(row) > 2 else 0.0
                gps9.append((when, row[0], row[1], alt))
        elif samples5 and gpsu is not None:
            rows = apply_scale(samples5, scale, 5)
            kept = [(lat, lon, alt) for lat, lon, alt, _s2, _s3 in (
                (r + [0, 0, 0, 0, 0])[:5] for r in rows
            ) if usable(lat, lon)]
            if kept:
                gps5.append((gpsu, kept))
    if gps9:
        kind = "GPS9"
        points = gps9
    elif gps5:
        kind = "GPS5"
        points = []
        gps5.sort(key=lambda item: item[0])
        for i, (when, rows) in enumerate(gps5):
            count = len(rows)
            if i + 1 < len(gps5) and count:
                step = (gps5[i + 1][0] - when) / count
            elif i > 0 and len(gps5[i - 1][1]):
                step = (when - gps5[i - 1][0]) / len(gps5[i - 1][1])
            else:
                step = timedelta(milliseconds=100)
            if step.total_seconds() <= 0:
                step = timedelta(milliseconds=100)
            for j, (lat, lon, alt) in enumerate(rows):
                points.append((when + step * j, lat, lon, alt))
    else:
        return [], ""
    points.sort(key=lambda item: item[0])
    clean = []
    for point in points:
        if clean and point[0] <= clean[-1][0]:
            continue
        clean.append(point)
    return clean, kind


def gopro_stream_index(path):
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-show_streams", "-of", "json", path],
        capture_output=True)
    if probe.returncode != 0:
        raise RuntimeError(probe.stderr.decode("utf-8", "replace").strip() or "ffprobe failed")
    try:
        data = json.loads(probe.stdout.decode("utf-8", "replace") or "{}")
    except json.JSONDecodeError as exc:
        raise RuntimeError("ffprobe did not return stream info") from exc
    found = None
    for stream in data.get("streams") or []:
        tag = (stream.get("codec_tag_string") or "").lower()
        handler = ((stream.get("tags") or {}).get("handler_name") or "")
        if tag == "gpmd" or "gopro" in handler.lower():
            found = stream.get("index")
            if "gopro" in handler.lower():
                return found
    return found


def read_gpmf(path):
    index = gopro_stream_index(path)
    if index is None:
        return None
    proc = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-map", "0:%d" % index,
         "-c", "copy", "-f", "rawvideo", "pipe:1"],
        capture_output=True)
    if proc.returncode != 0:
        err = proc.stderr.decode("utf-8", "replace").strip()
        raise RuntimeError(err or "ffmpeg could not copy the GoPro metadata")
    if not proc.stdout:
        raise RuntimeError("the GoPro metadata stream is empty")
    return proc.stdout


def fmt_time(when):
    return when.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def describe(points, kind):
    return "points=%d first=%s last=%s kind=%s" % (
        len(points), fmt_time(points[0][0]), fmt_time(points[-1][0]), kind)


def load_points(path):
    blob = read_gpmf(path)
    if blob is None:
        return None, ""
    return points_from_gpmf(blob)


def write_gpx(path, points, source_name):
    def num(value, digits):
        text = ("%." + str(digits) + "f") % value
        return text

    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<gpx version="1.1" creator="video-pgm-gopro-to-gpx %s" xmlns="http://www.topografix.com/GPX/1/1">' % VERSION,
        "  <trk>",
        "    <name>%s</name>" % xml_escape(source_name),
        "    <trkseg>",
    ]
    for when, lat, lon, alt in points:
        lines.append(
            '      <trkpt lat="%s" lon="%s"><ele>%s</ele><time>%s</time></trkpt>' % (
                num(lat, 7), num(lon, 7), num(alt, 1), fmt_time(when)))
    lines += ["    </trkseg>", "  </trk>", "</gpx>", ""]
    tmp = path + ".partial"
    with open(tmp, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines))
    os.replace(tmp, path)


def xml_escape(text):
    return (text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace('"', "&quot;"))


def cmd_info(path):
    try:
        points, kind = load_points(path)
    except RuntimeError as exc:
        print("error %s" % exc)
        return 1
    if points is None:
        print("nogopro")
        return 0
    if not points:
        print("none")
        return 0
    print("ok " + describe(points, kind))
    return 0


def cmd_write(path, out):
    try:
        points, kind = load_points(path)
    except RuntimeError as exc:
        print("error %s" % exc, file=sys.stderr)
        return 1
    if points is None:
        print("nogopro", file=sys.stderr)
        return 2
    if len(points) < 2:
        print("none", file=sys.stderr)
        return 2
    write_gpx(out, points, os.path.basename(path))
    print(describe(points, kind))
    return 0


def klv_bytes(key, typ, size, repeat, payload):
    pad = (-len(payload)) % 4
    return key + bytes([typ, size]) + repeat.to_bytes(2, "big") + payload + b"\x00" * pad


def nest(key, payload):
    return klv_bytes(key, 0, 1, len(payload), payload)


def selftest():
    scal = struct.pack(">5i", 10000000, 10000000, 1000, 100, 100)
    gpsu1 = b"260926090000.000"
    gpsu2 = b"260926090001.000"
    s1 = struct.pack(">5i", 523000000, 210000000, 120000, 1000, 1000)
    s2 = struct.pack(">5i", 523010000, 210010000, 121000, 1100, 1100)
    s3 = struct.pack(">5i", 0, 0, 0, 0, 0)
    s4 = struct.pack(">5i", 523020000, 210020000, 122000, 1200, 1200)

    def gps5_stream(gpsu, samples):
        payload = b"".join((
            klv_bytes(b"SCAL", ord("l"), 4, 5, scal),
            klv_bytes(b"GPSU", ord("U"), 16, 1, gpsu),
            klv_bytes(b"GPS5", ord("l"), 20, len(samples) // 20, samples),
        ))
        return nest(b"STRM", payload)

    blob = nest(b"DEVC", gps5_stream(gpsu1, s1 + s2) + gps5_stream(gpsu2, s3 + s4))
    points, kind = points_from_gpmf(blob)
    if kind != "GPS5" or len(points) != 3:
        raise SystemExit("GPS5 selftest: got %s %d" % (kind, len(points)))
    if abs(points[0][1] - 52.3) > 1e-6 or abs(points[0][2] - 21.0) > 1e-6:
        raise SystemExit("GPS5 selftest: bad lat/lon %s" % (points[0],))
    if points[0][0] != datetime(2026, 9, 26, 9, 0, 0, tzinfo=timezone.utc):
        raise SystemExit("GPS5 selftest: bad time %s" % points[0][0])
    if points[1][0] <= points[0][0] or points[2][0] <= points[1][0]:
        raise SystemExit("GPS5 selftest: times not increasing")

    # GPS9: one locked point and one with no fix. secs stored as milliseconds, scale 1000.
    type_s = b"lllssllSS"
    scale9 = struct.pack(">7i2H", 10000000, 10000000, 1000, 100, 100, 1, 1000, 1, 1)
    days = (datetime(2026, 9, 26) - datetime(2000, 1, 1)).days
    secs_ms = 9 * 3600 * 1000
    locked = struct.pack(">3i2h2i2H", 501234567, 190123456, 85000, 500, 500, days, secs_ms, 120, 3)
    nofix = struct.pack(">3i2h2i2H", 501234567, 190123456, 85000, 0, 0, days, secs_ms + 1000, 9999, 0)
    payload = b"".join((
        klv_bytes(b"TYPE", ord("c"), 1, len(type_s), type_s),
        klv_bytes(b"SCAL", ord("l"), 4, 7, scale9[:28]),
        klv_bytes(b"GPS9", ord("?"), 28, 2, locked + nofix),
    ))
    # SCAL above is awkward because mixed types. Rebuild scale as the parser sees per-field
    # values from a simple int list: pack 9 int32 scale factors instead.
    scale9 = struct.pack(">9i", 10000000, 10000000, 1000, 100, 100, 1, 1000, 1, 1)
    payload = b"".join((
        klv_bytes(b"TYPE", ord("c"), 1, len(type_s), type_s),
        klv_bytes(b"SCAL", ord("l"), 4, 9, scale9),
        klv_bytes(b"GPS9", ord("?"), 28, 2, locked + nofix),
    ))
    points, kind = points_from_gpmf(nest(b"DEVC", nest(b"STRM", payload)))
    if kind != "GPS9" or len(points) != 1:
        raise SystemExit("GPS9 selftest: got %s %d" % (kind, len(points)))
    if abs(points[0][1] - 50.1234567) > 1e-6 or abs(points[0][3] - 85.0) > 1e-6:
        raise SystemExit("GPS9 selftest: bad values %s" % (points[0],))
    if points[0][0] != datetime(2026, 9, 26, 9, 0, 0, tzinfo=timezone.utc):
        raise SystemExit("GPS9 selftest: bad time %s" % points[0][0])
    print("selftest ok")
    return 0


def main():
    parser = argparse.ArgumentParser(
        prog="video-pgm-gopro-to-gpx.py",
        description="Read a GoPro video's GPS metadata and write a GPX track. The video is not changed.")
    parser.add_argument("-v", "--version", action="store_true")
    parser.add_argument("--history", action="store_true")
    sub = parser.add_subparsers(dest="cmd")
    info = sub.add_parser("info")
    info.add_argument("file")
    write = sub.add_parser("write")
    write.add_argument("file")
    write.add_argument("out")
    sub.add_parser("selftest")
    args = parser.parse_args()
    if args.version:
        print_version_banner()
        return 0
    if args.history:
        return print_script_history()
    if args.cmd == "info":
        return cmd_info(args.file)
    if args.cmd == "write":
        return cmd_write(args.file, args.out)
    if args.cmd == "selftest":
        return selftest()
    parser.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
