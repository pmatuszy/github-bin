#!/usr/bin/env python3
# v. 20261021.140100 - jump filter skips whole teleport clusters, not only single spikes
# v. 20261021.135400 - clean GPX tracks: drop speed spikes, collapse stationary jitter, optional smooth

# 2026.10.21 - v. 0.2 - drop any point too fast from the last kept fix so a multi-point GPS teleport is removed, not only a one-point spike
# 2026.10.21 - v. 0.1 - initial release: read a .gpx, drop impossible jumps by speed, collapse near-zero
#                        movement clusters, optional short-window coordinate smooth; write a new .gpx
"""Clean noisy GPX tracks (spikes and stationary jitter).

Used by gpx_clean.sh. Needs only Python 3 (stdlib).
"""

from __future__ import annotations

import argparse
import math
import os
import re
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from typing import List, Optional, Sequence, Tuple

VERSION = "0.2"
VERSION_LINE = re.compile(r"^# v\. (\d{8})\.(\d{6}) - (.*)$")
HISTORY_LINE = re.compile(r"^# (\d{4}\.\d{2}\.\d{2} - v\. \S+ - .*)$")

Point = Tuple[float, float, Optional[float], Optional[float]]  # lat, lon, ele, epoch


def history_lines() -> List[str]:
    lines: List[str] = []
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


def print_version_banner() -> None:
    title = os.path.basename(__file__)
    verline = "Version: unknown"
    for line in history_lines():
        match = VERSION_LINE.match("# " + line)
        if match:
            day, clock = match.group(1), match.group(2)
            verline = "Version: %s.%s (%s.%s.%s %s:%s:%s)" % (
                day,
                clock,
                day[0:4],
                day[4:6],
                day[6:8],
                clock[0:2],
                clock[2:4],
                clock[4:6],
            )
            break
    width = 60
    print("\u250c" + "\u2500" * width + "\u2510")
    for text in (title, verline):
        print("\u2502 %-*.*s \u2502" % (width - 2, width - 2, text))
    print("\u2514" + "\u2500" * width + "\u2518")


def print_history() -> None:
    for line in history_lines():
        print(line)


def parse_time(text: str) -> Optional[float]:
    if not text:
        return None
    s = text.strip()
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(s)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.timestamp()


def format_time(epoch: float) -> str:
    dt = datetime.fromtimestamp(epoch, tz=timezone.utc)
    ms = int(round(dt.microsecond / 1000.0))
    if ms == 1000:
        dt = datetime.fromtimestamp(epoch + 0.001, tz=timezone.utc)
        ms = 0
    base = dt.strftime("%Y-%m-%dT%H:%M:%S")
    if ms or dt.microsecond:
        return "%s.%03dZ" % (base, ms)
    return base + "Z"


def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dlat = p2 - p1
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlon / 2) ** 2
    return 2 * r * math.asin(math.sqrt(min(1.0, a)))


def local_tag(el: ET.Element) -> str:
    if "}" in el.tag:
        return el.tag.rsplit("}", 1)[-1]
    return el.tag


def read_points(path: str) -> Tuple[List[Point], Optional[str]]:
    root = ET.parse(path).getroot()
    ns = None
    if root.tag.startswith("{"):
        ns = root.tag.split("}")[0].strip("{")
    pts: List[Point] = []
    for el in root.iter():
        if local_tag(el) != "trkpt":
            continue
        lat = float(el.attrib["lat"])
        lon = float(el.attrib["lon"])
        ele = None
        when = None
        for child in el:
            tag = local_tag(child)
            if tag == "ele" and child.text:
                try:
                    ele = float(child.text)
                except ValueError:
                    ele = None
            elif tag == "time" and child.text:
                when = parse_time(child.text)
        pts.append((lat, lon, ele, when))
    return pts, ns


def track_length_m(pts: Sequence[Point]) -> float:
    total = 0.0
    for i in range(1, len(pts)):
        total += haversine_m(pts[i - 1][0], pts[i - 1][1], pts[i][0], pts[i][1])
    return total


def drop_jumps(pts: Sequence[Point], max_kmh: float, gap_s: float = 60.0) -> Tuple[List[Point], int]:
    """Drop points that jump from the last kept fix faster than max_kmh.

    Compared to "spike only if both sides are fast", this also skips a whole
    wrong cluster after a teleport: each far point stays too fast vs the last
    good fix until the track returns nearby.
    """
    if max_kmh <= 0 or len(pts) < 2:
        return list(pts), 0
    limit = max_kmh / 3.6

    def too_fast(a: Point, b: Point) -> bool:
        dist = haversine_m(a[0], a[1], b[0], b[1])
        if a[3] is None or b[3] is None:
            # No time: hard cap ≈ distance covered at max_kmh in 2 s.
            return dist > limit * 2.0
        dt = b[3] - a[3]
        if dt <= 0:
            return dist > 1.0
        if dt > gap_s:
            return False
        return dist > limit * dt

    kept: List[Point] = [pts[0]]
    dropped = 0
    for i in range(1, len(pts)):
        p = pts[i]
        if too_fast(kept[-1], p):
            dropped += 1
            continue
        kept.append(p)
    return kept, dropped


def collapse_stops(
    pts: Sequence[Point],
    stop_kmh: float,
    stop_radius_m: float,
    min_points: int = 5,
) -> Tuple[List[Point], int]:
    """Collapse dense near-stationary clusters to first + last point of each cluster."""
    if stop_kmh < 0 or len(pts) < min_points:
        return list(pts), 0
    limit = stop_kmh / 3.6
    out: List[Point] = []
    removed = 0
    i = 0
    n = len(pts)
    while i < n:
        j = i + 1
        while j < n:
            a, b = pts[j - 1], pts[j]
            dist = haversine_m(a[0], a[1], b[0], b[1])
            if a[3] is not None and b[3] is not None:
                dt = b[3] - a[3]
                if dt > 0 and dist / dt > limit:
                    break
            elif dist > stop_radius_m:
                break
            # Still "stopped" only while cluster stays near the cluster origin.
            if haversine_m(pts[i][0], pts[i][1], b[0], b[1]) > stop_radius_m:
                break
            j += 1
        cluster = pts[i:j]
        if len(cluster) >= min_points:
            out.append(cluster[0])
            if cluster[-1] is not cluster[0]:
                out.append(cluster[-1])
            removed += len(cluster) - (2 if cluster[-1] is not cluster[0] else 1)
        else:
            out.extend(cluster)
        i = j
    return out, removed


def smooth_coords(pts: Sequence[Point], window_s: float) -> List[Point]:
    """Gaussian-weighted local line fit on lat/lon over window_s (not across gaps)."""
    if window_s <= 0 or len(pts) < 3:
        return list(pts)
    times = [p[3] if p[3] is not None else float(i) for i, p in enumerate(pts)]
    half = window_s / 2.0
    sigma = max(window_s / 4.0, 1e-6)

    def segments() -> List[Tuple[int, int]]:
        out = []
        start = 0
        for i in range(1, len(times)):
            if times[i] - times[i - 1] > 60.0:
                out.append((start, i - 1))
                start = i
        out.append((start, len(times) - 1))
        return out

    lats = [p[0] for p in pts]
    lons = [p[1] for p in pts]
    out_lat = list(lats)
    out_lon = list(lons)
    for a, b in segments():
        k = a
        for i in range(a, b + 1):
            while times[i] - times[k] > half:
                k += 1
            for values, dest in ((lats, out_lat), (lons, out_lon)):
                s0 = s1 = s2 = r0 = r1 = 0.0
                base = values[i]
                j = k
                while j <= b and times[j] - times[i] <= half:
                    d = times[j] - times[i]
                    w = math.exp(-0.5 * (d / sigma) ** 2)
                    v = values[j] - base
                    s0 += w
                    s1 += w * d
                    s2 += w * d * d
                    r0 += w * v
                    r1 += w * d * v
                    j += 1
                den = s0 * s2 - s1 * s1
                if den > 1e-9 * s0 * s0:
                    dest[i] = base + (s2 * r0 - s1 * r1) / den
                elif s0 > 0:
                    dest[i] = base + r0 / s0
    return [
        (out_lat[i], out_lon[i], pts[i][2], pts[i][3]) for i in range(len(pts))
    ]


def write_gpx(path: str, pts: Sequence[Point], ns: Optional[str], name: str) -> None:
    if ns:
        ET.register_namespace("", ns)
        root = ET.Element("{%s}gpx" % ns, attrib={"version": "1.1", "creator": "gpx_clean.py"})
        trk = ET.SubElement(root, "{%s}trk" % ns)
        ET.SubElement(trk, "{%s}name" % ns).text = name
        seg = ET.SubElement(trk, "{%s}trkseg" % ns)
        for lat, lon, ele, when in pts:
            trkpt = ET.SubElement(seg, "{%s}trkpt" % ns, attrib={"lat": "%.7f" % lat, "lon": "%.7f" % lon})
            if ele is not None:
                ET.SubElement(trkpt, "{%s}ele" % ns).text = "%.1f" % ele
            if when is not None:
                ET.SubElement(trkpt, "{%s}time" % ns).text = format_time(when)
    else:
        root = ET.Element("gpx", attrib={"version": "1.1", "creator": "gpx_clean.py"})
        trk = ET.SubElement(root, "trk")
        ET.SubElement(trk, "name").text = name
        seg = ET.SubElement(trk, "trkseg")
        for lat, lon, ele, when in pts:
            trkpt = ET.SubElement(seg, "trkpt", attrib={"lat": "%.7f" % lat, "lon": "%.7f" % lon})
            if ele is not None:
                ET.SubElement(trkpt, "ele").text = "%.1f" % ele
            if when is not None:
                ET.SubElement(trkpt, "time").text = format_time(when)

    tree = ET.ElementTree(root)
    if hasattr(ET, "indent"):
        ET.indent(tree, space="  ")
    tmp = path + ".partial"
    tree.write(tmp, encoding="utf-8", xml_declaration=True)
    os.replace(tmp, path)


def default_out_path(inp: str) -> str:
    base, ext = os.path.splitext(inp)
    if ext.lower() != ".gpx":
        return inp + "_cleaned.gpx"
    return base + "_cleaned.gpx"


def clean(
    pts: Sequence[Point],
    max_jump: float,
    stop_kmh: float,
    stop_radius: float,
    smooth: float,
) -> Tuple[List[Point], dict]:
    stats = {
        "input": len(pts),
        "dropped_jumps": 0,
        "collapsed_stop": 0,
        "output": 0,
        "length_in_km": track_length_m(pts) / 1000.0,
        "length_out_km": 0.0,
    }
    cur, n = drop_jumps(pts, max_jump)
    stats["dropped_jumps"] = n
    cur, n = collapse_stops(cur, stop_kmh, stop_radius)
    stats["collapsed_stop"] = n
    cur = smooth_coords(cur, smooth)
    stats["output"] = len(cur)
    stats["length_out_km"] = track_length_m(cur) / 1000.0
    return cur, stats


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(
        description="Clean a noisy GPX track (speed spikes and stationary jitter).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Example:\n  %(prog)s track.gpx\n  %(prog)s -o clean.gpx --max-jump 200 --smooth 3 track.gpx",
    )
    ap.add_argument("-v", "--version", action="store_true", help="print version banner and exit")
    ap.add_argument("--history", action="store_true", help="print changelog from the header and exit")
    ap.add_argument("-n", "--dry-run", action="store_true", help="print stats; write nothing")
    ap.add_argument("-o", "--output", help="output .gpx (default: INPUT_cleaned.gpx)")
    ap.add_argument(
        "--max-jump",
        type=float,
        default=200.0,
        metavar="KMH",
        help="drop single points implying faster than this (default 200; 0 keeps all)",
    )
    ap.add_argument(
        "--stop-kmh",
        type=float,
        default=3.0,
        metavar="KMH",
        help="treat slower movement as stopped for jitter collapse (default 3; <0 disables)",
    )
    ap.add_argument(
        "--stop-radius",
        type=float,
        default=25.0,
        metavar="M",
        help="max radius of a stop cluster in metres (default 25)",
    )
    ap.add_argument(
        "--smooth",
        type=float,
        default=2.0,
        metavar="S",
        help="seconds of coordinate smooth after cleaning (default 2; 0 disables)",
    )
    ap.add_argument("input", nargs="?", help="input .gpx file")
    args = ap.parse_args(argv)

    if args.version:
        print_version_banner()
        return 0
    if args.history:
        print_history()
        return 0
    if not args.input:
        ap.error("input .gpx is required (see -h)")

    inp = args.input
    if not os.path.isfile(inp):
        print("ERROR: not a file: %s" % inp, file=sys.stderr)
        return 1

    pts, ns = read_points(inp)
    if not pts:
        print("ERROR: no track points in %s" % inp, file=sys.stderr)
        return 1

    cleaned, stats = clean(pts, args.max_jump, args.stop_kmh, args.stop_radius, args.smooth)
    out = args.output or default_out_path(inp)

    print(
        "points_in=%d points_out=%d dropped_jumps=%d collapsed_stop=%d "
        "length_in_km=%.3f length_out_km=%.3f"
        % (
            stats["input"],
            stats["output"],
            stats["dropped_jumps"],
            stats["collapsed_stop"],
            stats["length_in_km"],
            stats["length_out_km"],
        )
    )
    print("output=%s" % out)

    if args.dry_run:
        return 0
    if len(cleaned) < 2:
        print("ERROR: fewer than 2 points left after cleaning", file=sys.stderr)
        return 1

    name = os.path.splitext(os.path.basename(out))[0]
    write_gpx(out, cleaned, ns, name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
