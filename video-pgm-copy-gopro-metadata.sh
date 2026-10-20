#!/bin/bash
# v. 20261020.192700 - Proposed copy / progress lines spell out exiftool tags vs GoPro gpmd stream
# v. 20261020.191200 - initial release: extract / copy GoPro GPS+camera metadata; fuzzy-match counterparts by name
#
# 2026.10.20 - v. 0.1.1 - Proposed copy and progress text say clearly: (1) exiftool tags including
#   GoPro:/GPS/dates/camera, and (2) best-effort ffmpeg remux of the timed gpmd stream when present
# 2026.10.20 - v. 0.1 - initial release: copy GoPro-related metadata (GPS, dates, Make/Model,
#   Keys/ItemList peers) from a source MP4/MOV (or a .gopro-meta.mie sidecar) onto a processed
#   file that lost those tags. Fuzzy name matching (Python) picks the best counterpart when
#   only one side is given — not limited to known suffixes like _rotate_180. Optional best-effort
#   remux of the gpmd timed-metadata stream via ffmpeg. -y applies without asking; --dry-run
#   prints the plan only.
#
# video-pgm-copy-gopro-metadata.sh
#
# Restore GoPro / GPS metadata after processing (rotate, re-encode, …) that stripped it.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [--dry-run] [--verbose] [--extract] [--copy] [--match-only]
       [--no-gpmd] [--min-score N]
       [FILE|DIR ...]

Copy GoPro-related metadata (GPS, camera tags, dates) from a source video
onto a processed video that lost them. Can also extract a sidecar for later
use, or only show the best name match.

Matching does not rely on fixed suffixes. A short Python scorer ranks other
.mp4/.mov names in the same folder (fuzzy similarity + shared prefix /
YYYYMMDD_HHMMSS). Example pair that scores as a strong match:

  20240327_122904_-_…_-_GOPRO7_BLACK_part_01.mp4
  20240327_122904_-_…_-_GOPRO7_BLACK_part_01_rotate_180.mp4

Modes (default is auto):
  (default)            Given one video: find the best counterpart and copy
                       (source = richer GoPro/GPS tags → dest = poorer).
                       Given two videos: decide direction and copy.
                       Given directories / no args: pair files in those dirs.
  --extract            Write FILE.gopro-meta.mie beside each source (no copy).
  --copy               Require explicit source and dest (or source + match).
  --match-only         Only print the best match and score; write nothing.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Apply without asking.
  --dry-run            Show the plan; do not write.
  --verbose            Extra detail (scores, streams, exiftool lines).
  --extract            Extract metadata sidecar(s) only.
  --copy               Copy mode (see above).
  --match-only         Match only; do not write.
  --no-gpmd            Do not try ffmpeg remux of the gpmd data stream.
  --min-score N        Minimum match score 0..1 (default 0.72).

Sidecar:
  Beside a source video: stem.gopro-meta.mie (exiftool MIE). Apply later with
  the same script by naming the .mie as the source.

Needs: exiftool, python3. ffmpeg/ffprobe optional (gpmd remux).

Examples:
  $(basename "$0") ./20240327_122904_-_…_part_01.mp4
      Guess the processed counterpart and offer to copy metadata onto it.

  $(basename "$0") ./…_part_01_rotate_180.mp4
      Guess the original with GPS and offer to copy from it.

  $(basename "$0") --extract ./…_part_01.mp4
      Write ./…_part_01.gopro-meta.mie

  $(basename "$0") -y --dry-run .
      Plan copies for every high-confidence pair in this directory.

Environment:
  CGM_EXIFTOOL / EXIFLOC / PGM_EXIFTOOL
                       Path to exiftool (else exiftool on PATH).
EOF
}

cgm_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

cgm_print_selected() {
  echo "$(cgm_ts) Selected: $*"
}

cgm_read_key() {
  local prompt="$1" default="${2:-}" answer=
  if (( ! script_is_run_interactively )); then
    REPLY="$default"
    return 0
  fi
  printf '%s %s' "$(cgm_ts)" "$prompt"
  if [[ -t 0 ]]; then
    read -n 1 answer || answer=
  else
    REPLY="$default"
    return 0
  fi
  echo
  if [[ -z "$answer" ]]; then
    REPLY="$default"
  else
    REPLY="$answer"
  fi
}

cgm_choice() {
  local c="${1,,}"
  c="${c//$'\r'/}"
  c="${c//$'\n'/}"
  printf '%s\n' "$c"
}

cgm_k() {
  local key="$1" def="$2"
  if [[ "${key,,}" == "${def,,}" ]]; then
    printf '%s' "${key^^}"
  else
    printf '%s' "$key"
  fi
}

cgm_keys() {
  local def="$1" k out=""
  shift
  for k in "$@"; do
    out+="${out:+/}$(cgm_k "$k" "$def")"
  done
  printf '%s\n' "$out"
}

cgm_find_exiftool() {
  local p
  for p in "${CGM_EXIFTOOL:-}" "${EXIFLOC:-}" "${PGM_EXIFTOOL:-}"; do
    if [[ -n "$p" && -x "$p" ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  p="$(command -v exiftool 2>/dev/null)" || return 1
  printf '%s\n' "$p"
}

cgm_is_video() {
  local base="${1##*/}" ext
  ext="${base##*.}"
  ext="${ext,,}"
  case "$ext" in
    mp4|mov|m4v) return 0 ;;
    *) return 1 ;;
  esac
}

cgm_is_sidecar() {
  local base="${1##*/}"
  [[ "$base" == *.gopro-meta.mie ]] || [[ "$base" == *.mie ]]
}

cgm_sidecar_for() {
  local f="$1" dir base stem
  dir="$(dirname -- "$f")"
  base="${f##*/}"
  stem="${base%.*}"
  printf '%s/%s.gopro-meta.mie\n' "$dir" "$stem"
}

# Richness score: higher = better source. Uses exiftool (+ optional ffprobe gpmd).
# Sets CGM_HAS_GPMD=0/1 for the last file probed.
cgm_metadata_richness() {
  local f="$1" exif raw n=0
  CGM_HAS_GPMD=0
  if cgm_is_sidecar "$f"; then
    # Sidecar counts as a full metadata source.
    printf '%s\n' 100
    return 0
  fi
  exif="$(cgm_find_exiftool 2>/dev/null)" || { printf '%s\n' 0; return 0; }
  raw="$("$exif" -api largefilesupport=1 -s3 -GPSLatitude -GPSLongitude \
    -Keys:GPSCoordinates -QuickTime:GPSCoordinates -Make -Model \
    -GoPro:CameraSerialNumber -CameraSerialNumber \
    -- "$f" 2>/dev/null | tr -d '\r')"
  while IFS= read -r line; do
    [[ -n "$line" && "$line" != "-" ]] || continue
    n=$((n + 10))
  done <<< "$raw"
  if command -v ffprobe >/dev/null 2>&1; then
    if ffprobe -v error -select_streams d \
      -show_entries stream=codec_tag_string:stream_tags=handler_name \
      -of csv=p=0 -- "$f" 2>/dev/null \
      | grep -Eiq 'gpmd|GoPro[[:space:]]*MET|GoPro MET'; then
      CGM_HAS_GPMD=1
      n=$((n + 50))
    fi
  fi
  printf '%s\n' "$n"
}

cgm_has_useful_metadata() {
  local r
  r="$(cgm_metadata_richness "$1")"
  (( r >= 10 ))
}

# Python fuzzy matcher: print "path<TAB>score" lines, best first.
# Args: query_path, candidate_path...
cgm_rank_matches() {
  local query="$1"
  shift
  (( $# )) || return 1
  QUERY="$query" MIN_SCORE="$MIN_SCORE" python3 - "$@" <<'PY'
import os, re, sys, difflib

query = os.environ["QUERY"]
min_score = float(os.environ.get("MIN_SCORE", "0.72"))
cands = sys.argv[1:]

def stem(path: str) -> str:
    base = os.path.basename(path)
    if base.lower().endswith(".gopro-meta.mie"):
        base = base[: -len(".gopro-meta.mie")]
    else:
        base = os.path.splitext(base)[0]
    return base

def norm(s: str) -> str:
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s

def stamp_prefix(s: str) -> str:
    m = re.match(r"^(\d{8}_\d{6})", s)
    return m.group(1) if m else ""

q_raw = stem(query)
q = norm(q_raw)
q_stamp = stamp_prefix(q_raw)
rows = []
for c in cands:
    if os.path.normpath(c) == os.path.normpath(query):
        continue
    c_raw = stem(c)
    cn = norm(c_raw)
    if not cn or not q:
        continue
    ratio = difflib.SequenceMatcher(None, q, cn).ratio()
    # One stem is a prefix of the other (processed suffix appended).
    if q.startswith(cn + "_") or cn.startswith(q + "_"):
        ratio = max(ratio, 0.93)
    # Long common prefix relative to the shorter name.
    common = 0
    for a, b in zip(q, cn):
        if a != b:
            break
        common += 1
    shorter = min(len(q), len(cn))
    if shorter:
        ratio = max(ratio, common / shorter * 0.98)
    c_stamp = stamp_prefix(c_raw)
    if q_stamp and c_stamp and q_stamp == c_stamp:
        ratio = min(1.0, ratio + 0.05)
    # Same part_NN token helps; different part_NN hurts.
    pq = re.search(r"part_(\d{2})", q)
    pc = re.search(r"part_(\d{2})", cn)
    if pq and pc:
        if pq.group(1) == pc.group(1):
            ratio = min(1.0, ratio + 0.03)
        else:
            ratio -= 0.25
    if ratio + 1e-9 < min_score:
        continue
    rows.append((ratio, c))

rows.sort(key=lambda t: (-t[0], t[1]))
for ratio, c in rows:
    print(f"{c}\t{ratio:.4f}")
PY
}

cgm_collect_videos_in_dir() {
  local dir="$1" f
  if (( RECURSIVE )); then
    while IFS= read -r -d '' f; do
      cgm_is_video "$f" || continue
      ALL_VIDEOS+=("$f")
    done < <(find "$dir" -type f -print0 2>/dev/null)
  else
    shopt -s nullglob nocaseglob
    for f in "$dir"/*; do
      [[ -f "$f" ]] || continue
      cgm_is_video "$f" || continue
      ALL_VIDEOS+=("$f")
    done
    shopt -u nocaseglob
  fi
}

cgm_extract_sidecar() {
  local src="$1" side exif
  side="$(cgm_sidecar_for "$src")"
  exif="$(cgm_find_exiftool)" || return 1
  if (( DRY_RUN )); then
    echo "$(cgm_ts) DRY-RUN would extract: ${side}"
    return 0
  fi
  if [[ -e "$side" ]]; then
    echo "$(cgm_ts) Sidecar already exists: ${side}"
    return 0
  fi
  if "$exif" -api largefilesupport=1 -o "$side" -- "$src" >/dev/null 2>&1; then
    echo "$(cgm_ts) Extracted: ${side}"
    return 0
  fi
  echo "$(cgm_ts) Extract failed: ${src}" >&2
  return 1
}

# Probe whether src has a GoPro timed gpmd/MET data stream. Sets CGM_HAS_GPMD.
cgm_probe_gpmd() {
  local f="$1"
  CGM_HAS_GPMD=0
  cgm_is_sidecar "$f" && return 1
  command -v ffprobe >/dev/null 2>&1 || return 1
  if ffprobe -v error -select_streams d \
    -show_entries stream=codec_tag_string:stream_tags=handler_name \
    -of csv=p=0 -- "$f" 2>/dev/null \
    | grep -Eiq 'gpmd|GoPro[[:space:]]*MET|GoPro MET'; then
    CGM_HAS_GPMD=1
    return 0
  fi
  return 1
}

# Copy: (1) exiftool tags incl. GoPro:/GPS/dates/camera, (2) optional gpmd remux.
cgm_copy_metadata() {
  local src="$1" dest="$2" exif tmp rc=0
  local src_gpmd=0 dest_gpmd=0
  exif="$(cgm_find_exiftool)" || return 1
  [[ -f "$src" && -f "$dest" ]] || return 1

  cgm_probe_gpmd "$src" && src_gpmd=1
  cgm_probe_gpmd "$dest" && dest_gpmd=1

  if (( DRY_RUN )); then
    echo "$(cgm_ts) DRY-RUN would copy:"
    echo "           from: ${src}"
    echo "           to:   ${dest}"
    echo "           (1) exiftool tags: GPS, dates, Make/Model, GoPro:all, Keys/ItemList peers"
    if (( COPY_GPMD )) && (( src_gpmd )) && (( ! dest_gpmd )) && ! cgm_is_sidecar "$src"; then
      echo "           (2) GoPro gpmd timed stream: remux via ffmpeg (source has gpmd)"
    elif (( ! COPY_GPMD )); then
      echo "           (2) GoPro gpmd timed stream: off (--no-gpmd)"
    elif cgm_is_sidecar "$src"; then
      echo "           (2) GoPro gpmd timed stream: n/a (source is a sidecar, not a video)"
    elif (( ! src_gpmd )); then
      echo "           (2) GoPro gpmd timed stream: source has no gpmd stream"
    elif (( dest_gpmd )); then
      echo "           (2) GoPro gpmd timed stream: dest already has a data stream"
    else
      echo "           (2) GoPro gpmd timed stream: not attempted"
    fi
    return 0
  fi

  echo "$(cgm_ts) Copying GoPro metadata: ${src##*/} -> ${dest##*/}"
  echo "$(cgm_ts)   (1/2) exiftool tags: GPS, dates, Make/Model, GoPro:all, Keys/ItemList …"
  if "$exif" -overwrite_original -P -api QuickTimeUTC=1 -api largefilesupport=1 \
    -TagsFromFile "$src" \
    -time:all -gps:all \
    -Make -Model -Software -Artist -Copyright \
    -Keys:Make -Keys:Model -Keys:GPSCoordinates \
    -ItemList:Make -ItemList:Model \
    -QuickTime:GPSCoordinates \
    -GoPro:all \
    -FileCreateDate -FileModifyDate \
    -- "$dest" >/dev/null 2>&1; then
    echo "$(cgm_ts)   (1/2) OK — tags written (including GoPro: group when present in source)"
  else
    # Retry without GoPro:all (older exiftool / non-GoPro source).
    if "$exif" -overwrite_original -P -api QuickTimeUTC=1 -api largefilesupport=1 \
      -TagsFromFile "$src" \
      -time:all -gps:all \
      -Make -Model \
      -Keys:Make -Keys:Model -Keys:GPSCoordinates \
      -ItemList:Make -ItemList:Model \
      -QuickTime:GPSCoordinates \
      -FileCreateDate -FileModifyDate \
      -- "$dest" >/dev/null 2>&1; then
      echo "$(cgm_ts)   (1/2) OK — GPS/dates/camera tags written (GoPro: group not available / skipped)"
    else
      echo "$(cgm_ts)   (1/2) FAILED — exiftool could not write tags" >&2
      rc=1
    fi
  fi

  if (( COPY_GPMD )) && ! cgm_is_sidecar "$src" \
    && command -v ffmpeg >/dev/null 2>&1 \
    && command -v ffprobe >/dev/null 2>&1; then
    if (( src_gpmd )); then
      if (( ! dest_gpmd )); then
        echo "$(cgm_ts)   (2/2) GoPro gpmd timed stream: remuxing into destination (ffmpeg) …"
        tmp="$(mktemp "${TMPDIR:-/tmp}/cgm-gpmd.XXXXXX.mp4")"
        if ffmpeg -y -hide_banner -loglevel error \
          -i "$dest" -i "$src" \
          -map 0 -map 1:d:0? \
          -c copy -copy_unknown -tag:d:0 gpmd \
          "$tmp" 2>/dev/null \
          && [[ -s "$tmp" ]]; then
          if mv -f -- "$tmp" "$dest"; then
            echo "$(cgm_ts)   (2/2) OK — gpmd stream copied (full GoPro telemetry track)"
          else
            rm -f -- "$tmp"
            echo "$(cgm_ts)   (2/2) FAILED — remux OK but could not replace destination" >&2
            rc=1
          fi
        else
          rm -f -- "$tmp"
          echo "$(cgm_ts)   (2/2) FAILED — gpmd remux did not succeed (exiftool tags above still apply)" >&2
          rc=1
        fi
      else
        echo "$(cgm_ts)   (2/2) GoPro gpmd timed stream: skipped (destination already has a data stream)"
      fi
    else
      echo "$(cgm_ts)   (2/2) GoPro gpmd timed stream: skipped (source has no gpmd / GoPro MET stream)"
    fi
  elif (( ! COPY_GPMD )); then
    echo "$(cgm_ts)   (2/2) GoPro gpmd timed stream: skipped (--no-gpmd)"
  elif cgm_is_sidecar "$src"; then
    echo "$(cgm_ts)   (2/2) GoPro gpmd timed stream: skipped (source is a .mie sidecar — tags only)"
  else
    echo "$(cgm_ts)   (2/2) GoPro gpmd timed stream: skipped (ffmpeg/ffprobe not available)"
  fi
  return "$rc"
}

cgm_pick_direction() {
  # Sets SRC DEST from A B by richness (and name length as tie-break: shorter stem = source).
  local a="$1" b="$2" ra rb sa sb
  ra="$(cgm_metadata_richness "$a")"
  rb="$(cgm_metadata_richness "$b")"
  if (( ra > rb )); then
    SRC="$a"; DEST="$b"
  elif (( rb > ra )); then
    SRC="$b"; DEST="$a"
  else
    sa="${a##*/}"; sa="${sa%.*}"
    sb="${b##*/}"; sb="${sb%.*}"
    if (( ${#sa} <= ${#sb} )); then
      SRC="$a"; DEST="$b"
    else
      SRC="$b"; DEST="$a"
    fi
  fi
  (( VERBOSE )) && echo "$(cgm_ts) Direction: richness ${ra} vs ${rb} -> src=${SRC##*/} dest=${DEST##*/}"
}

cgm_confirm_pair() {
  local src="$1" dest="$2" score="${3:-}" keys src_gpmd=0 dest_gpmd=0
  echo
  echo "$(cgm_ts) Proposed copy"
  echo "  Source (has metadata): ${src}"
  echo "  Dest   (receive it):   ${dest}"
  if [[ -n "$score" ]]; then
    awk -v s="$score" 'BEGIN { printf "  Match score:           %.0f%%\n", s * 100 }'
  fi
  echo "  Will copy:"
  echo "    (1) exiftool tags — GPS, dates, Make/Model, GoPro:all, Keys/ItemList peers"
  cgm_probe_gpmd "$src" && src_gpmd=1
  cgm_probe_gpmd "$dest" && dest_gpmd=1
  if (( COPY_GPMD )) && (( src_gpmd )) && (( ! dest_gpmd )) && ! cgm_is_sidecar "$src"; then
    echo "    (2) GoPro gpmd timed stream — full telemetry track via ffmpeg remux"
  elif (( ! COPY_GPMD )); then
    echo "    (2) GoPro gpmd timed stream — off (--no-gpmd); tags only"
  elif cgm_is_sidecar "$src"; then
    echo "    (2) GoPro gpmd timed stream — n/a (source is a sidecar; tags only)"
  elif (( ! src_gpmd )); then
    echo "    (2) GoPro gpmd timed stream — source has none (tags only)"
  elif (( dest_gpmd )); then
    echo "    (2) GoPro gpmd timed stream — dest already has one (tags only)"
  else
    echo "    (2) GoPro gpmd timed stream — not attempted"
  fi
  if (( DO_YES )); then
    cgm_print_selected "y = Copy (-y)"
    return 0
  fi
  if (( ! script_is_run_interactively )); then
    echo "$(cgm_ts) Non-interactive without -y: skip this pair."
    return 1
  fi
  keys="$(cgm_keys y y n q)"
  cgm_read_key "Copy GoPro metadata [${keys}]? " y
  case "$(cgm_choice "$REPLY")" in
    y)
      cgm_print_selected "y = Copy (tags + gpmd when available)"
      return 0
      ;;
    n)
      cgm_print_selected "n = Skip"
      return 1
      ;;
    q)
      cgm_print_selected "q = Quit"
      return 2
      ;;
    *)
      cgm_print_selected "n = Skip (unknown key)"
      return 1
      ;;
  esac
}

cgm_process_explicit_pair() {
  local a="$1" b="$2" score=""
  cgm_pick_direction "$a" "$b"
  cgm_confirm_pair "$SRC" "$DEST" "$score"
  case $? in
    0) cgm_copy_metadata "$SRC" "$DEST"; COPIED=$((COPIED + 1)) ;;
    2) return 2 ;;
    *) SKIPPED=$((SKIPPED + 1)) ;;
  esac
  return 0
}

cgm_best_match_for() {
  # Sets BEST_PATH BEST_SCORE from query + ALL_VIDEOS (+ sidecars in same dirs).
  local query="$1" f dir side
  local -a cands=()
  BEST_PATH=""; BEST_SCORE=""
  for f in "${ALL_VIDEOS[@]}"; do
    [[ "$(cd "$(dirname -- "$f")" && pwd)/${f##*/}" == "$(cd "$(dirname -- "$query")" && pwd)/${query##*/}" ]] && continue
    cands+=("$f")
  done
  # Also consider sidecars next to candidates / query dir.
  dir="$(dirname -- "$query")"
  shopt -s nullglob
  for side in "$dir"/*.gopro-meta.mie; do
    cands+=("$side")
  done
  shopt -u nullglob
  (( ${#cands[@]} )) || return 1
  local line path sc
  while IFS=$'\t' read -r path sc; do
    [[ -n "$path" ]] || continue
    BEST_PATH="$path"
    BEST_SCORE="$sc"
    return 0
  done < <(cgm_rank_matches "$query" "${cands[@]}")
  return 1
}

cgm_process_one_video() {
  local f="$1" rich peer_rich
  if (( MODE_EXTRACT )); then
    if cgm_has_useful_metadata "$f" || cgm_is_sidecar "$f"; then
      cgm_extract_sidecar "$f" && EXTRACTED=$((EXTRACTED + 1))
    else
      echo "$(cgm_ts) No useful metadata to extract: ${f##*/}"
      SKIPPED=$((SKIPPED + 1))
    fi
    return 0
  fi

  if (( MODE_MATCH_ONLY )); then
    if cgm_best_match_for "$f"; then
      printf '%s Match for %s\n' "$(cgm_ts)" "$f"
      printf '         -> %s  (score %s)\n' "$BEST_PATH" "$BEST_SCORE"
    else
      echo "$(cgm_ts) No match >= ${MIN_SCORE} for ${f##*/}"
    fi
    return 0
  fi

  # Auto / copy: find counterpart and copy in the right direction.
  if ! cgm_best_match_for "$f"; then
    echo "$(cgm_ts) No match >= ${MIN_SCORE} for ${f##*/}"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi
  (( VERBOSE )) && echo "$(cgm_ts) Best match for ${f##*/}: ${BEST_PATH##*/} (${BEST_SCORE})"

  if cgm_is_sidecar "$BEST_PATH"; then
    SRC="$BEST_PATH"
    DEST="$f"
  elif cgm_is_sidecar "$f"; then
    SRC="$f"
    DEST="$BEST_PATH"
    if ! cgm_is_video "$DEST"; then
      echo "$(cgm_ts) Sidecar match is not a video: ${DEST}" >&2
      SKIPPED=$((SKIPPED + 1))
      return 0
    fi
  else
    cgm_pick_direction "$f" "$BEST_PATH"
  fi

  cgm_confirm_pair "$SRC" "$DEST" "$BEST_SCORE"
  case $? in
    0)
      cgm_copy_metadata "$SRC" "$DEST"
      COPIED=$((COPIED + 1))
      # Remember pair so directory scan does not do A→B and B→A.
      DONE_KEYS+=("$(cgm_pair_key "$SRC" "$DEST")")
      ;;
    2) return 2 ;;
    *) SKIPPED=$((SKIPPED + 1)) ;;
  esac
  return 0
}

cgm_pair_key() {
  local a="$1" b="$2" x y
  x="$(cd "$(dirname -- "$a")" 2>/dev/null && printf '%s/%s\n' "$(pwd)" "${a##*/}")"
  y="$(cd "$(dirname -- "$b")" 2>/dev/null && printf '%s/%s\n' "$(pwd)" "${b##*/}")"
  if [[ "$x" < "$y" ]]; then printf '%s|%s\n' "$x" "$y"
  else printf '%s|%s\n' "$y" "$x"
  fi
}

cgm_pair_already_done() {
  local key="$1" k
  for k in "${DONE_KEYS[@]:-}"; do
    [[ "$k" == "$key" ]] && return 0
  done
  return 1
}

cgm_process_directory_pairs() {
  # Pair each video that lacks useful metadata with the best richer match.
  local f key ra
  local -a poor=() rich=()
  for f in "${ALL_VIDEOS[@]}"; do
    ra="$(cgm_metadata_richness "$f")"
    if (( ra >= 10 )); then
      rich+=("$f")
    else
      poor+=("$f")
    fi
  done
  (( VERBOSE )) && echo "$(cgm_ts) Directory: ${#rich[@]} with metadata, ${#poor[@]} without"

  if (( ${#poor[@]} == 0 )); then
    echo "$(cgm_ts) Every video already looks tagged; nothing to restore."
    echo "$(cgm_ts) Tip: pass one file to force a match, or use --extract / --match-only."
    return 0
  fi

  for f in "${poor[@]}"; do
    if ! cgm_best_match_for "$f"; then
      (( VERBOSE )) && echo "$(cgm_ts) No match for ${f##*/}"
      continue
    fi
    # Prefer a rich source when the best name match is also poor.
    if ! cgm_has_useful_metadata "$BEST_PATH" && ! cgm_is_sidecar "$BEST_PATH"; then
      (( VERBOSE )) && echo "$(cgm_ts) Best name match for ${f##*/} also lacks metadata: ${BEST_PATH##*/}"
      continue
    fi
    SRC="$BEST_PATH"
    DEST="$f"
    key="$(cgm_pair_key "$SRC" "$DEST")"
    if cgm_pair_already_done "$key"; then
      continue
    fi
    cgm_confirm_pair "$SRC" "$DEST" "$BEST_SCORE"
    case $? in
      0)
        cgm_copy_metadata "$SRC" "$DEST"
        COPIED=$((COPIED + 1))
        DONE_KEYS+=("$key")
        ;;
      2) return 2 ;;
      *) SKIPPED=$((SKIPPED + 1)) ;;
    esac
  done
  return 0
}

# --- options ---
DO_YES=0
DRY_RUN=0
VERBOSE=0
RECURSIVE=0
COPY_GPMD=1
MODE_EXTRACT=0
MODE_COPY=0
MODE_MATCH_ONLY=0
MIN_SCORE=0.72
COPIED=0
EXTRACTED=0
SKIPPED=0
ALL_VIDEOS=()
POSITIONALS=()
DONE_KEYS=()
SRC=""
DEST=""
BEST_PATH=""
BEST_SCORE=""
CGM_HAS_GPMD=0

. "${profile_location_dir:-$HOME}/bin/_script_header.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --history) print_script_history; exit 0 ;;
    -y|--yes) DO_YES=1; shift ;;
    --dry-run|-n) DRY_RUN=1; shift ;;
    --verbose) VERBOSE=1; shift ;;
    -r|--recursive) RECURSIVE=1; shift ;;
    --extract) MODE_EXTRACT=1; shift ;;
    --copy) MODE_COPY=1; shift ;;
    --match-only) MODE_MATCH_ONLY=1; shift ;;
    --no-gpmd) COPY_GPMD=0; shift ;;
    --min-score)
      MIN_SCORE="${2:-}"
      shift 2
      ;;
    --)
      shift
      POSITIONALS+=("$@")
      break
      ;;
    -*)
      echo "$(cgm_ts) Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
    *)
      POSITIONALS+=("$1")
      shift
      ;;
  esac
done

if (( MODE_EXTRACT + MODE_COPY + MODE_MATCH_ONLY > 1 )); then
  echo "$(cgm_ts) Use only one of --extract / --copy / --match-only." >&2
  exit 1
fi

print_version_banner

if ! cgm_find_exiftool >/dev/null; then
  echo "$(cgm_ts) exiftool not found (set CGM_EXIFTOOL or install exiftool)." >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "$(cgm_ts) python3 not found (needed for name matching)." >&2
  exit 1
fi

EXPLICIT_FILES=()
DIR_MODE=0

if (( ${#POSITIONALS[@]} == 0 )); then
  DIR_MODE=1
  cgm_collect_videos_in_dir .
else
  for p in "${POSITIONALS[@]}"; do
    if [[ -d "$p" ]]; then
      DIR_MODE=1
      cgm_collect_videos_in_dir "$p"
    elif [[ -f "$p" ]]; then
      if cgm_is_video "$p" || cgm_is_sidecar "$p"; then
        EXPLICIT_FILES+=("$p")
        cgm_is_video "$p" && ALL_VIDEOS+=("$p")
      else
        echo "$(cgm_ts) Not a video or .gopro-meta.mie (skipped): $p" >&2
      fi
    else
      echo "$(cgm_ts) Not found: $p" >&2
    fi
  done
fi

# Also collect sibling videos for matching when only explicit files were given.
if (( ${#EXPLICIT_FILES[@]} > 0 && DIR_MODE == 0 )); then
  for p in "${EXPLICIT_FILES[@]}"; do
    cgm_is_video "$p" || continue
    cgm_collect_videos_in_dir "$(dirname -- "$p")"
  done
fi

if (( ${#ALL_VIDEOS[@]} )); then
  mapfile -t ALL_VIDEOS < <(printf '%s\n' "${ALL_VIDEOS[@]}" | LC_ALL=C sort -u)
fi

echo
echo "$(cgm_ts) Videos in scope: ${#ALL_VIDEOS[@]}"
(( DRY_RUN )) && echo "$(cgm_ts) Dry run — nothing will be written."
(( VERBOSE )) && echo "$(cgm_ts) Verbose on; min-score=${MIN_SCORE}"
echo

rc=0
if (( ${#EXPLICIT_FILES[@]} == 2 && DIR_MODE == 0 && ! MODE_EXTRACT && ! MODE_MATCH_ONLY )); then
  # Two paths: treat as a pair (video/video or mie/video).
  a="${EXPLICIT_FILES[0]}"
  b="${EXPLICIT_FILES[1]}"
  conf_rc=0
  if cgm_is_sidecar "$a" && cgm_is_video "$b"; then
    SRC="$a"; DEST="$b"
    cgm_confirm_pair "$SRC" "$DEST"; conf_rc=$?
  elif cgm_is_sidecar "$b" && cgm_is_video "$a"; then
    SRC="$b"; DEST="$a"
    cgm_confirm_pair "$SRC" "$DEST"; conf_rc=$?
  else
    cgm_process_explicit_pair "$a" "$b"
    rc=$?
    conf_rc=-1
  fi
  if (( conf_rc >= 0 )); then
    case "$conf_rc" in
      0) cgm_copy_metadata "$SRC" "$DEST"; COPIED=$((COPIED + 1)) ;;
      2) rc=2 ;;
      *) SKIPPED=$((SKIPPED + 1)) ;;
    esac
  fi
elif (( ${#EXPLICIT_FILES[@]} > 0 && DIR_MODE == 0 )); then
  for f in "${EXPLICIT_FILES[@]}"; do
    cgm_process_one_video "$f"
    r=$?
    if (( r == 2 )); then rc=2; break; fi
  done
elif (( MODE_EXTRACT )); then
  for f in "${ALL_VIDEOS[@]}"; do
    cgm_process_one_video "$f" || true
  done
elif (( MODE_MATCH_ONLY )); then
  targets=("${EXPLICIT_FILES[@]}")
  (( ${#targets[@]} )) || targets=("${ALL_VIDEOS[@]}")
  for f in "${targets[@]}"; do
    cgm_process_one_video "$f" || true
  done
else
  # Directory auto: restore onto files that lack metadata.
  cgm_process_directory_pairs
  rc=$?
fi

echo
echo "$(cgm_ts) Done. Copied ${COPIED}; extracted ${EXTRACTED}; skipped ${SKIPPED}."
if (( COPIED == 0 && EXTRACTED == 0 && ! MODE_MATCH_ONLY && ! VERBOSE )); then
  echo "$(cgm_ts) Tip: --match-only or --verbose shows how names were scored."
fi
exit 0
