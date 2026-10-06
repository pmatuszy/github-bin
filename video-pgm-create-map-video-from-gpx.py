#!/usr/bin/env python3
# v. 20261006.115200 - -v/--version prints the same box as the bash scripts; --history pages in a terminal like them
# v. 20261006.114917 - -h/--help describes every option, -v/--version, --history
# v. 20261006.113346 - moving OpenStreetMap map that follows a GPX track, same length as its video

# 2026.10.06 - v. 0.3 - -v/--version: boxed name and "Version: YYYYMMDD.HHMMSS (YYYY.MM.DD HH:MM:SS)" from the newest # v. line, like print_version_banner; --history: one page at a time in a terminal with "More history? [Y/n/q]", whole list when piped
# 2026.10.06 - v. 0.2 - help text for every option, examples and exit codes; -v/--version prints the header version; --history prints the changelog
# 2026.10.06 - v. 0.1 - initial release: info, fetch, and render subcommands; north-up map centred on the car, driven and remaining track, speed and clock panel, tile cache
"""Moving-map video from a GPX track, for video-pgm-create-map-video-from-gpx.sh.

Subcommands:
  info    Print key=value facts about the track and the tiles it needs.
  fetch   Download the missing map tiles into the cache.
  render  Draw every frame and pipe it into ffmpeg. Encoder options follow "--".

Video time v maps to real time  start + v * speed  (x5 files: speed 5).
"""

import argparse
import bisect
import collections
import concurrent.futures
import fractions
import math
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

VERSION = "0.3"
TILE = 256
USER_AGENT = ("video-pgm-create-map-video-from-gpx/" + VERSION
              + " (+https://github.com/pmatuszy/github-bin)")
DEFAULT_URL = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
FONT_DIRS = ("/usr/share/fonts/truetype/dejavu", "/usr/share/fonts/dejavu")

COL_AHEAD = (90, 70, 210)
COL_DONE = (225, 35, 35)
COL_ARROW = (25, 25, 25)
COL_NOFIX = (130, 130, 130)
COL_EMPTY = (226, 226, 226)


# --- track ------------------------------------------------------------------

def parse_time(text):
    text = text.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    t = datetime.fromisoformat(text)
    if t.tzinfo is None:
        t = t.replace(tzinfo=timezone.utc)
    return t.timestamp()


def world_xy(lat, lon, zoom):
    n = TILE * (1 << zoom)
    lat = max(min(lat, 85.05112878), -85.05112878)
    s = math.sin(math.radians(lat))
    x = (lon + 180.0) / 360.0 * n
    y = (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * n
    return x, y


def haversine(lat1, lon1, lat2, lon2):
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = p2 - p1
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(min(1.0, math.sqrt(a)))


class Track:
    """GPX points with times in epoch seconds, world pixels, speed, and heading."""

    def __init__(self, path, zoom):
        pts = []
        root = ET.parse(path).getroot()
        for el in root.iter():
            if not el.tag.endswith("trkpt"):
                continue
            when = None
            for child in el:
                if child.tag.endswith("time") and child.text:
                    when = parse_time(child.text)
            if when is None:
                continue
            pts.append((when, float(el.get("lat")), float(el.get("lon"))))
        pts.sort()
        clean = []
        for p in pts:
            if clean and p[0] <= clean[-1][0]:
                continue
            clean.append(p)
        if len(clean) < 2:
            raise ValueError("fewer than two timed track points")
        self.t = [p[0] for p in clean]
        self.lat = [p[1] for p in clean]
        self.lon = [p[2] for p in clean]
        self.x = []
        self.y = []
        for la, lo in zip(self.lat, self.lon):
            x, y = world_xy(la, lo, zoom)
            self.x.append(x)
            self.y.append(y)
        self._speed_heading()

    def shift(self, seconds):
        if seconds:
            self.t = [t + seconds for t in self.t]

    def _speed_heading(self, half=5.0, max_span=40.0, min_kmh=5.0):
        n = len(self.t)
        self.v = [None] * n
        self.h = [None] * n
        k = j = 0
        for i in range(n):
            while k < i and self.t[i] - self.t[k + 1] >= half:
                k += 1
            if j < i:
                j = i
            while j < n - 1 and self.t[j] - self.t[i] < half:
                j += 1
            dt = self.t[j] - self.t[k]
            if 0 < dt <= max_span:
                d = haversine(self.lat[k], self.lon[k], self.lat[j], self.lon[j])
                self.v[i] = d / dt
                dx, dy = self.x[j] - self.x[k], self.y[j] - self.y[k]
                if self.v[i] * 3.6 >= min_kmh and (dx or dy):
                    self.h[i] = math.atan2(dx, -dy)
        last = None
        for i in range(n):
            if self.h[i] is None:
                self.h[i] = last
            else:
                last = self.h[i]
        first = next((h for h in self.h if h is not None), 0.0)
        self.h = [first if h is None else h for h in self.h]

    def at(self, when):
        """(x, y, index of the last point passed, state, speed m/s or None, heading)."""
        t = self.t
        if when <= t[0]:
            return self.x[0], self.y[0], -1, "before", None, self.h[0]
        if when >= t[-1]:
            return self.x[-1], self.y[-1], len(t) - 1, "after", None, self.h[-1]
        i = bisect.bisect_right(t, when) - 1
        span = t[i + 1] - t[i]
        f = (when - t[i]) / span
        x = self.x[i] + f * (self.x[i + 1] - self.x[i])
        y = self.y[i] + f * (self.y[i + 1] - self.y[i])
        v = None
        if self.v[i] is not None and self.v[i + 1] is not None:
            v = self.v[i] + f * (self.v[i + 1] - self.v[i])
        state = "gap" if span > 60 else "ok"
        return x, y, i, state, v, self.h[i]


def video_window(args):
    start = args.from_s
    length = args.length if args.length is not None else max(0.0, args.duration - start)
    return start, min(length, max(0.0, args.duration - start))


def auto_shift(track, args):
    if args.tz_shift is not None:
        return int(round(args.tz_shift * 3600))
    real_end = args.start_epoch + args.duration * args.speed
    overlaps = track.t[0] < real_end and track.t[-1] > args.start_epoch
    d = track.t[0] - args.start_epoch
    if overlaps and abs(d) < 2700:
        return 0
    hours = int(round(d / 3600.0))
    if hours == 0 or abs(hours) > 14:
        return 0
    return -hours * 3600


# --- tiles ------------------------------------------------------------------

class Tiles:
    def __init__(self, cache, url, zoom):
        self.cache = cache
        self.url = url
        self.zoom = zoom
        self.n = 1 << zoom
        self.mem = collections.OrderedDict()
        self.filler = None

    def key(self, tx, ty):
        return tx % self.n, ty

    def path(self, tx, ty):
        tx, ty = self.key(tx, ty)
        return os.path.join(self.cache, str(self.zoom), str(tx), "%d.png" % ty)

    def cached(self, tx, ty):
        return os.path.isfile(self.path(tx, ty))

    def tile_url(self, tx, ty):
        tx, ty = self.key(tx, ty)
        s = "abc"[(tx + ty) % 3]
        return self.url.format(z=self.zoom, x=tx, y=ty, s=s)

    def download(self, tx, ty):
        dest = self.path(tx, ty)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        req = urllib.request.Request(self.tile_url(tx, ty), headers={"User-Agent": USER_AGENT})
        delay = 2.0
        for attempt in range(4):
            try:
                with urllib.request.urlopen(req, timeout=30) as r:
                    kind = r.headers.get("Content-Type", "")
                    data = r.read()
                if "image" not in kind or not data:
                    raise ValueError("not an image (%s)" % kind)
                tmp = dest + ".part%d" % os.getpid()
                with open(tmp, "wb") as fh:
                    fh.write(data)
                os.replace(tmp, dest)
                return True
            except urllib.error.HTTPError as e:
                if e.code in (404, 403) or attempt == 3:
                    return False
                time.sleep(delay * (4 if e.code in (429, 503) else 1))
            except (urllib.error.URLError, OSError, ValueError):
                if attempt == 3:
                    return False
                time.sleep(delay)
            delay *= 2
        return False

    def get(self, tx, ty):
        from PIL import Image
        if ty < 0 or ty >= self.n:
            return self.empty()
        k = self.key(tx, ty)
        img = self.mem.get(k)
        if img is not None:
            self.mem.move_to_end(k)
            return img
        p = self.path(tx, ty)
        if os.path.isfile(p):
            try:
                with Image.open(p) as im:
                    img = im.convert("RGB")
            except OSError:
                img = None
        if img is None:
            return self.empty()
        self.mem[k] = img
        if len(self.mem) > 400:
            self.mem.popitem(last=False)
        return img

    def empty(self):
        from PIL import Image
        if self.filler is None:
            self.filler = Image.new("RGB", (TILE, TILE), COL_EMPTY)
        return self.filler


def needed_tiles(track, args):
    v0, vlen = video_window(args)
    t0 = args.start_epoch + v0 * args.speed
    t1 = args.start_epoch + (v0 + vlen) * args.speed
    pad = 64
    hw, hh = args.width / 2.0 + pad, args.height / 2.0 + pad
    found = set()
    times = []
    t = t0
    while t <= t1:
        times.append(t)
        t += 2.0
    times.append(t1)
    lo = bisect.bisect_left(track.t, t0)
    hi = bisect.bisect_right(track.t, t1)
    times.extend(track.t[lo:hi])
    for when in times:
        x, y = track.at(when)[:2]
        for tx in range(int(math.floor((x - hw) / TILE)), int(math.floor((x + hw) / TILE)) + 1):
            for ty in range(int(math.floor((y - hh) / TILE)), int(math.floor((y + hh) / TILE)) + 1):
                found.add((tx % (1 << args.zoom), ty))
    return sorted(found)


# --- drawing ----------------------------------------------------------------

def load_font(size, bold=True):
    from PIL import ImageFont
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    for d in FONT_DIRS:
        p = os.path.join(d, name)
        if os.path.isfile(p):
            return ImageFont.truetype(p, size)
    try:
        return ImageFont.load_default(size)
    except TypeError:
        return ImageFont.load_default()


class Canvas:
    """Tiles and the whole track drawn around the car; rebuilt when the view nears its edge."""

    def __init__(self, tiles, track, width, height, line):
        self.tiles = tiles
        self.track = track
        self.w = width
        self.h = height
        self.margin = max(384, (max(width, height) // 2 // TILE + 1) * TILE)
        self.line = line
        self.img = None
        self.draw = None
        self.ox = self.oy = 0
        self.cw = width + 2 * self.margin
        self.ch = height + 2 * self.margin
        self.done = -1

    def ensure(self, cx, cy, idx):
        left, top = cx - self.w / 2.0, cy - self.h / 2.0
        if (self.img is None or left < self.ox or top < self.oy
                or left + self.w > self.ox + self.cw or top + self.h > self.oy + self.ch):
            self.build(cx, cy, idx)
        elif idx > self.done:
            self.extend(idx)

    def _xy(self, i):
        return self.track.x[i] - self.ox, self.track.y[i] - self.oy

    def _runs(self, upto=None):
        tr = self.track
        last = len(tr.t) - 1 if upto is None else upto
        pad = 200
        x0, y0 = self.ox - pad, self.oy - pad
        x1, y1 = self.ox + self.cw + pad, self.oy + self.ch + pad
        run = []
        for i in range(0, last + 1):
            if x0 <= tr.x[i] <= x1 and y0 <= tr.y[i] <= y1:
                run.append(self._xy(i))
            else:
                if len(run) > 1:
                    yield run
                run = []
        if len(run) > 1:
            yield run

    def build(self, cx, cy, idx):
        from PIL import Image, ImageDraw
        self.ox = int(cx - self.cw / 2.0)
        self.oy = int(cy - self.ch / 2.0)
        img = Image.new("RGB", (self.cw, self.ch), COL_EMPTY)
        for tx in range(self.ox // TILE, (self.ox + self.cw - 1) // TILE + 1):
            for ty in range(self.oy // TILE, (self.oy + self.ch - 1) // TILE + 1):
                img.paste(self.tiles.get(tx, ty), (tx * TILE - self.ox, ty * TILE - self.oy))
        draw = ImageDraw.Draw(img)
        for run in self._runs():
            draw.line(run, fill=COL_AHEAD, width=self.line, joint="curve")
        if idx >= 1:
            for run in self._runs(idx):
                draw.line(run, fill=COL_DONE, width=self.line + 2, joint="curve")
        self.img, self.draw, self.done = img, draw, idx

    def extend(self, idx):
        start = max(self.done, 0)
        if idx > start:
            pts = [self._xy(i) for i in range(start, idx + 1)]
            self.draw.line(pts, fill=COL_DONE, width=self.line + 2, joint="curve")
        self.done = idx

    def view(self, cx, cy):
        left = int(round(cx - self.w / 2.0 - self.ox))
        top = int(round(cy - self.h / 2.0 - self.oy))
        return self.img.crop((left, top, left + self.w, top + self.h)), left + self.ox, top + self.oy


def draw_marker(draw, cx, cy, heading, size, moving):
    if not moving:
        r = size * 0.55
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=COL_NOFIX, outline=(255, 255, 255),
                     width=max(2, size // 7))
        return
    fx, fy = math.sin(heading), -math.cos(heading)
    rx, ry = math.cos(heading), math.sin(heading)
    tip = (cx + fx * size, cy + fy * size)
    back = size * 0.65
    side = size * 0.62
    notch = (cx - fx * back * 0.45, cy - fy * back * 0.45)
    left = (cx - fx * back - rx * side, cy - fy * back - ry * side)
    right = (cx - fx * back + rx * side, cy - fy * back + ry * side)
    draw.polygon([tip, right, notch, left], fill=COL_ARROW, outline=(255, 255, 255),
                 width=max(2, size // 7))


def panel(frame, box, alpha, light=False):
    from PIL import Image
    region = frame.crop(box).convert("RGBA")
    shade = (255, 255, 255, alpha) if light else (0, 0, 0, alpha)
    region = Image.alpha_composite(region, Image.new("RGBA", region.size, shade))
    frame.paste(region.convert("RGB"), box[:2])


class Overlay:
    def __init__(self, args):
        h = args.height
        self.big = load_font(max(18, h // 16))
        self.small = load_font(max(12, h // 32))
        self.tiny = load_font(max(10, h // 64), bold=False)
        self.show_speed = not args.no_speed
        self.show_clock = not args.no_clock
        self.attribution = args.attribution
        self.pad = max(8, h // 70)

    def text_size(self, font, text):
        b = font.getbbox(text)
        return b[2] - b[0], b[3] - b[1], b[1]

    def draw(self, frame, when, speed, state):
        from PIL import ImageDraw
        pad = self.pad
        lines = []
        if self.show_speed:
            if state in ("before", "after", "gap") or speed is None:
                lines.append((self.big, "-- km/h"))
            else:
                lines.append((self.big, "%d km/h" % int(round(speed * 3.6))))
        if self.show_clock:
            lines.append((self.small, time.strftime("%H:%M:%S", time.localtime(when))))
        if state == "before":
            lines.append((self.small, "waiting for GPS"))
        elif state == "after":
            lines.append((self.small, "GPS track ended"))
        elif state == "gap":
            lines.append((self.small, "no GPS here"))
        if lines:
            sizes = [self.text_size(f, s) for f, s in lines]
            w = max(s[0] for s in sizes) + 2 * pad
            h = sum(s[1] for s in sizes) + pad * (len(lines) + 1)
            box = (pad, pad, pad + w, pad + h)
            panel(frame, box, 150)
            d = ImageDraw.Draw(frame)
            y = pad * 2
            for (font, text), (tw, th, off) in zip(lines, sizes):
                d.text((pad * 2, y - off), text, font=font, fill=(255, 255, 255))
                y += th + pad
        if self.attribution:
            tw, th, off = self.text_size(self.tiny, self.attribution)
            x1, y1 = frame.width - 4, frame.height - 4
            box = (x1 - tw - 12, y1 - th - 10, x1, y1)
            panel(frame, box, 170, light=True)
            ImageDraw.Draw(frame).text((box[0] + 6, box[1] + 5 - off), self.attribution,
                                       font=self.tiny, fill=(40, 40, 40))


# --- progress ---------------------------------------------------------------

def clock_whole(s):
    t = int(max(0, s) + 0.5)
    return "%02d:%02d:%02d" % (t // 3600, (t % 3600) // 60, t % 60)


def eta_left(s):
    t = int(max(0, s) + 0.5)
    h, m, sec = t // 3600, (t % 3600) // 60, t % 60
    if h:
        return "%dh %dm" % (h, m)
    if m:
        return "%dm %ds" % (m, sec)
    return "%ds" % sec


def eta_at(remain):
    a = int(time.time() + remain + 30) // 60 * 60
    if time.strftime("%Y%m%d", time.localtime(a)) == time.strftime("%Y%m%d"):
        return "at " + time.strftime("%H:%M", time.localtime(a))
    return "at " + time.strftime("%Y.%m.%d %H:%M", time.localtime(a))


def draw_progress(done_s, total_s, wall, label):
    width = 40
    frac = min(1.0, done_s / total_s) if total_s > 0 else 0.0
    filled = int(frac * width + 0.5)
    speedx = done_s / wall if wall > 0 else 0.0
    eta = "left --  at --"
    if speedx > 0:
        remain = (total_s - done_s) / speedx
        eta = "left %s  %s" % (eta_left(remain), eta_at(remain))
    sys.stderr.write("\r%s[%s%s] %3d%%  %s / %s  %.2fx  %s\033[K" % (
        label + " " if label else "", "#" * filled, "-" * (width - filled), int(frac * 100 + 0.5),
        clock_whole(done_s), clock_whole(total_s), speedx, eta))
    sys.stderr.flush()


# --- subcommands ------------------------------------------------------------

def load_track(args):
    track = Track(args.gpx, args.zoom)
    shift = auto_shift(track, args)
    track.shift(shift)
    return track, shift


def cmd_info(args):
    track, shift = load_track(args)
    v0, vlen = video_window(args)
    t0 = args.start_epoch + v0 * args.speed
    t1 = args.start_epoch + (v0 + vlen) * args.speed
    dist = 0.0
    vmax = 0.0
    for i in range(1, len(track.t)):
        if t0 <= track.t[i] <= t1:
            dist += haversine(track.lat[i - 1], track.lon[i - 1], track.lat[i], track.lon[i])
            if track.v[i] is not None:
                vmax = max(vmax, track.v[i])
    tiles = Tiles(args.cache, args.tile_url, args.zoom)
    need = needed_tiles(track, args)
    cached = sum(1 for tx, ty in need if tiles.cached(tx, ty))
    first_v = (track.t[0] - args.start_epoch) / args.speed
    last_v = (track.t[-1] - args.start_epoch) / args.speed
    out = {
        "points": len(track.t),
        "tz_shift": shift,
        "first_fix": "%.3f" % first_v,
        "last_fix": "%.3f" % last_v,
        "overlap": int(last_v > v0 and first_v < v0 + vlen),
        "distance_km": "%.1f" % (dist / 1000.0),
        "max_kmh": "%d" % int(round(vmax * 3.6)),
        "tiles_needed": len(need),
        "tiles_cached": cached,
        "lat": "%.5f" % track.lat[0],
    }
    for k, v in out.items():
        print("%s=%s" % (k, v))
    return 0


def cmd_fetch(args):
    track, _ = load_track(args)
    tiles = Tiles(args.cache, args.tile_url, args.zoom)
    missing = [t for t in needed_tiles(track, args) if not tiles.cached(*t)]
    total = len(missing)
    if total == 0:
        return 0
    ok = bad = 0
    t_start = time.time()

    def show():
        width = 40
        n = ok + bad
        filled = int(n / total * width + 0.5)
        rate = n / max(0.001, time.time() - t_start)
        left = (total - n) / rate if rate > 0 else 0
        sys.stderr.write("\rTiles [%s%s] %3d%%  %d / %d  failed %d  left %s\033[K" % (
            "#" * filled, "-" * (width - filled), int(n / total * 100 + 0.5), n, total, bad, eta_left(left)))
        sys.stderr.flush()

    show()
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(tiles.download, tx, ty) for tx, ty in missing]
        for fut in concurrent.futures.as_completed(futures):
            if fut.result():
                ok += 1
            else:
                bad += 1
            show()
    sys.stderr.write("\n")
    print("downloaded=%d" % ok)
    print("failed=%d" % bad)
    return 0 if bad == 0 else 4


def cmd_render(args, enc):
    from PIL import ImageDraw
    track, _ = load_track(args)
    tiles = Tiles(args.cache, args.tile_url, args.zoom)
    fps = fractions.Fraction(args.fps).limit_denominator(1001)
    v0, vlen = video_window(args)
    frames = int(round(vlen * fps))
    if frames < 1:
        sys.stderr.write("Nothing to render: the window is empty.\n")
        return 2
    cmd = [args.ffmpeg, "-y", "-hide_banner", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", "%dx%d" % (args.width, args.height),
           "-r", "%d/%d" % (fps.numerator, fps.denominator), "-i", "-"]
    cmd += enc + ["-pix_fmt", "yuv420p", "-movflags", "+faststart", args.out]
    line = max(4, args.height // 160)
    canvas = Canvas(tiles, track, args.width, args.height, line)
    overlay = Overlay(args)
    marker = max(16, args.height // 27)
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    t_start = time.time()
    last_draw = 0.0
    tty = sys.stderr.isatty()
    try:
        for n in range(frames):
            v = v0 + n / float(fps)
            when = args.start_epoch + v * args.speed
            x, y, idx, state, speed, heading = track.at(when)
            canvas.ensure(x, y, idx)
            frame, left, top = canvas.view(x, y)
            d = ImageDraw.Draw(frame)
            cx, cy = x - left, y - top
            if idx >= 0 and state in ("ok", "gap"):
                d.line([(track.x[idx] - left, track.y[idx] - top), (cx, cy)],
                       fill=COL_DONE, width=line + 2)
            draw_marker(d, cx, cy, heading, marker, state == "ok")
            overlay.draw(frame, when, speed, state)
            proc.stdin.write(frame.tobytes())
            now = time.time()
            if tty and (now - last_draw >= 0.5 or n == frames - 1):
                last_draw = now
                draw_progress((n + 1) / float(fps), vlen, now - t_start, args.label)
        proc.stdin.close()
    except BrokenPipeError:
        if tty:
            sys.stderr.write("\n")
        proc.wait()
        return 3
    except KeyboardInterrupt:
        if tty:
            sys.stderr.write("\n")
        proc.kill()
        proc.wait()
        return 130
    if tty:
        sys.stderr.write("\n")
    rc = proc.wait()
    return 0 if rc == 0 else 3


VERSION_LINE = re.compile(r"^# v\. ([0-9]{8})\.([0-9]{6})\s*-")
HISTORY_LINE = re.compile(r"^# [0-9]{4}\.[0-9]{2}\.[0-9]{2}\s*-\s*v\.")


def history_lines():
    """Changelog lines from the header, the same ones _script_header.sh collects."""
    lines = []
    try:
        with open(os.path.realpath(__file__), encoding="utf-8") as f:
            for n, line in enumerate(f):
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
        m = VERSION_LINE.match("# " + line)
        if m:
            d, t = m.group(1), m.group(2)
            verline = "Version: %s.%s (%s.%s.%s %s:%s:%s)" % (
                d, t, d[0:4], d[4:6], d[6:8], t[0:2], t[2:4], t[4:6])
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
            sys.stdout.write("[%s] More history? [Y/n/q] (%d/%d shown): "
                             % (time.strftime("%Y.%m.%d %H:%M:%S"), i, len(lines)))
            sys.stdout.flush()
            answer = read_tty_key(tty, 200).upper() or "Y"
            print()
            stamp = time.strftime("%Y.%m.%d %H:%M:%S")
            if answer == "Q":
                print("[%s] Selected: quit" % stamp)
                break
            if answer == "N":
                print("[%s] Selected: no (stop)" % stamp)
                break
            print("[%s] Selected: yes (more)" % stamp)
    return 0


EPILOG = """\
Normally run by video-pgm-create-map-video-from-gpx.sh, which works out all of
these values from the video and its name. Run that script with --help for the
everyday options.

Example:
  %(prog)s info --gpx route.gpx --start-epoch 1790413587 --speed 5 \\
      --duration 1460.6 --cache ~/.cache/video-pgm-map-tiles/tile.openstreetmap.org

Exit codes: 0 ok, 2 track problem, 3 ffmpeg failed, 4 some tiles failed to
download, 130 interrupted.
"""


def main():
    argv = sys.argv[1:]
    if any(a in ("-v", "--version") for a in argv):
        print_version_banner()
        return 0
    if "--history" in argv:
        return print_script_history()
    enc = []
    if "--" in argv:
        k = argv.index("--")
        argv, enc = argv[:k], argv[k + 1:]
    ap = argparse.ArgumentParser(description=__doc__, epilog=EPILOG,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=("info", "fetch", "render"),
                    help="info: facts about the track; fetch: download tiles; render: write the video")
    ap.add_argument("-v", "--version", action="store_true", help="print the version and exit")
    ap.add_argument("--history", action="store_true", help="print the changelog from the header and exit")
    ap.add_argument("--gpx", required=True, help="GPX track file")
    ap.add_argument("--start-epoch", type=float, required=True,
                    help="real time at video 0:00, seconds since 1970 (UTC)")
    ap.add_argument("--speed", type=float, default=1.0,
                    help="real seconds per video second (default 1; x5 files: 5)")
    ap.add_argument("--duration", type=float, required=True, help="video length in seconds")
    ap.add_argument("--from", dest="from_s", type=float, default=0.0,
                    help="start this many video seconds in (default 0)")
    ap.add_argument("--length", type=float, default=None,
                    help="render only this many video seconds (default: to the end)")
    ap.add_argument("--width", type=int, default=1080, help="picture width (default 1080)")
    ap.add_argument("--height", type=int, default=1080, help="picture height (default 1080)")
    ap.add_argument("--zoom", type=int, default=16, help="map zoom 12-18 (default 16)")
    ap.add_argument("--fps", default="25", help="frame rate, a number or a fraction like 30000/1001 (default 25)")
    ap.add_argument("--cache", required=True, help="tile cache directory")
    ap.add_argument("--tile-url", default=DEFAULT_URL,
                    help="tile address with {z} {x} {y}, and {s} for a/b/c (default %(default)s)")
    ap.add_argument("--attribution", default="\u00a9 OpenStreetMap contributors",
                    help="credit drawn in the corner (default: %(default)s)")
    ap.add_argument("--tz-shift", type=float, default=None,
                    help="hours added to GPX times (default: guessed from the overlap)")
    ap.add_argument("--no-speed", action="store_true", help="leave out the speed")
    ap.add_argument("--no-clock", action="store_true", help="leave out the clock")
    ap.add_argument("--out", help="output video (render)")
    ap.add_argument("--label", default="", help="name shown on the progress line")
    ap.add_argument("--ffmpeg", default="ffmpeg", help="ffmpeg program (default ffmpeg)")
    args = ap.parse_args(argv)
    if args.speed <= 0:
        args.speed = 1.0
    try:
        if args.command == "info":
            return cmd_info(args)
        if args.command == "fetch":
            return cmd_fetch(args)
        if not args.out:
            ap.error("render needs --out")
        try:
            import PIL  # noqa: F401
        except ImportError:
            sys.stderr.write("Python Pillow is missing: apt install python3-pil\n")
            return 2
        return cmd_render(args, enc)
    except (OSError, ValueError, ET.ParseError) as e:
        sys.stderr.write("ERROR: %s: %s\n" % (args.gpx, e))
        return 2
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
