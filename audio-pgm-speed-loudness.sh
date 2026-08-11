#!/usr/bin/env bash
# v. 20260811.095711 - add --history (paged changelog via _script_header.sh print_script_history)
# v. 20260810.194016 - add -f/--format (flac|mp3|m4a|aac); warn when cover present but format cannot embed
# v. 20260810.190038 - summary: file sizes + move totals after per-file before/after block
# v. 20260810.184417 - clarify duration-saved percent as "N% shorter than input"
# v. 20260810.184308 - summary: show how much shorter output is vs total input duration
# v. 20260810.184102 - summary: total input/output duration + average max/mean dB before/after
# v. 20260810.180157 - episode zero-pad only after single-key consent [y/N/q] (default N)
# v. 20260810.175918 - zero-pad trailing _1.._9 before ext when multi-digit episodes exist
# v. 20260810.175612 - create org/ only when moving a converted source (not on empty/decline)
# v. 20260810.175506 - summary: input → output on first line, then before/after
# v. 20260810.175420 - before→after summary: before and after on separate lines
# v. 20260810.175340 - omit redundant output path line in before→after summary
# v. 20260810.173904 - drop redundant output basename on After: line
# v. 20260810.173552 - show input → output on one line per file
# v. 20260810.173421 - omit ./ prefix on cwd output paths in messages and filenames
# v. 20260810.172924 - proceed prompt: single-key [y/N/q] (like loudness)
# v. 20260810.172518 - proceed prompt prefixed with [YYYY.MM.DD HH:MM:SS] like loudness
# v. 20260810.172405 - MAX_VOLUME column width 10 (one dash less than before)
# v. 20260810.172202 - duration column width matches DURATION header (8)
# v. 20260810.171749 - align pre-scan table columns (FILE / max / mean / duration)
# v. 20260810.171439 - after pre-scan, ask to process with default [y/N] (N)
# v. 20260810.170715 - show duration before/after (ffprobe) in scan, per-file, and summary
# v. 20260810.164307 - replace spaces with underscores via mv (not only perl rename)
# v. 20260810.162410 - embed single cwd jpg/jpeg/png as cover (output .m4a when cover present)
# v. 20260810.160147 - pre-scan volumedetect table; before/after dB; end-of-run summary
# v. 20260810.152506 - rename to audio-pgm-speed-loudness.sh (drop CURRENT-DIRECTORY suffix)
# v. 20260810.152137 - add English rewrite: cwd atempo+speechnorm, fix find grouping, safe file loop
# 2024.10.20 - v. 0.7 - with ffmpeg 7.0.2, -shortest shortened outputs incorrectly; removed it
# 2024.08.13 - v. 0.6 - zero-pad _1_,_2_,_3_ to _01_,_02_,_03_ in names
# 2024.07.31 - v. 0.5 - rar-compress org/ so phone sync does not show it as an extra subfolder
# 2023.05.21 - v. 0.4 - sanitize cwd basename (spaces, Polish and odd chars); find -not at end (still buggy)
# 2022.06.14 - v. 0.3 - work correctly when directory name has spaces
# 2022.04.17 - v. 0.2 - strip Polish chars from filenames; chmod/chown/touch on org/
# 2021.05.03 - v. 0.1 - initial release
#
# audio-pgm-speed-loudness.sh
#
# In the current directory: speed up speech audio (ffmpeg atempo) and apply speechnorm,
# write mono audio (default .aac, or .m4a when embedding a cover; override with -f/--format),
# move sources into org/, then pack org/ into org.rar.
# Pre-scans loudness (volumedetect) and reports before/after dB, duration, size, plus end-of-run totals.
# If exactly one .jpg/.jpeg/.png is in the cwd and the output format supports covers, embed it.
#

set -euo pipefail

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]
                    [-f|--format FORMAT] [SPEED]

Process *.mp3, *.m4a, and *.aac in the current directory only (not subdirs).
Skips files whose names already contain SPEECHNORM_SPEEDUP.

Before converting, scan each file with ffmpeg volumedetect and ffprobe duration;
print max/mean dB and duration. Then ask whether to process with a single keypress (default No: [y/N/q]).
After each successful convert, re-measure and print before → after dB and duration.
At the end (or on Ctrl-C / q), print a run summary.

Output format (-f / --format): aac, m4a, mp3, or flac.
Default (no -f): .aac, or .m4a when embedding a cover.

If the current directory contains exactly one image (.jpg / .jpeg / .png) and the
chosen format supports album art (m4a, mp3, flac), embed it as cover. Raw .aac
cannot carry a cover — if images are present and output is aac, a warning is
printed and conversion continues without embedding. With 0 or 2+ images, no
cover is embedded (need exactly one).

For each file, run ffmpeg with:
  - mono (-ac 1)
  - atempo=SPEED (default 1.6)
  - speechnorm
  - optional cover image (when exactly one image and format supports it)
Output: <basename>_SPEECHNORM_SPEEDUP_<SPEED>.<ext>
On success: copy mode/owner/mtime from the source, move the source into org/.
After all files: zero-pad _1_.._9_ in names, then rar-pack org/ into org.rar.

Also sanitizes the cwd basename and filenames: spaces become underscores (via mv),
then commas / Polish diacritics / brackets via Debian/Ubuntu perl rename(1) on
common media/doc extensions. If the directory has multi-digit episode numbers
(e.g. _10 or _02) and a trailing single-digit sibling (_1.mp3), offers to rename
to _01.mp3 after a single-key confirm (default No: [y/N/q]).

ffmpeg resolution (first match wins):
  1. FFMPEG_BIN environment variable (if executable)
  2. /usr/local/bin/ffmpeg
  3. /usr/bin/ffmpeg
  4. ffmpeg on PATH

Required tools: ffmpeg, rename (perl File::Rename style), rar.

Options:
  -h, --help            Show this help and exit.
  -v, --version         Print script version and exit.
  --history            Print script changelog from the header and exit.
  --no_startup_delay    Skip random startup delay (see _script_header.sh).
  -f, --format FORMAT   Output format: aac | m4a | mp3 | flac
                        (default: aac, or m4a when embedding a cover)
  SPEED                 atempo factor (default: 1.6), e.g. 1.5 or 2.0

Examples:
  cd /path/to/files && $(basename "$0")
  cd /path/to/files && $(basename "$0") 1.8
  cd /path/to/files && $(basename "$0") -f flac 1.6
  cd /path/to/files && $(basename "$0") --format mp3
  FFMPEG_BIN=/opt/ffmpeg/bin/ffmpeg $(basename "$0") --no_startup_delay
EOF
}

HEADER_EXTRA_ARGS=()
SPEED_FACTOR=1.6
SPEED_SET=0
OUTPUT_FORMAT="" # empty = auto (aac, or m4a when embedding cover)

while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      if [[ -f /root/bin/_script_header.sh ]]; then
        # shellcheck source=/dev/null
        . /root/bin/_script_header.sh NO_STARTUP_DELAY
        print_version_banner
      else
        head -n1 "$0"
      fi
      exit 0
      ;;
    --history)
      if [[ -f /root/bin/_script_header.sh ]]; then
        # shellcheck source=/dev/null
        . /root/bin/_script_header.sh NO_STARTUP_DELAY
        print_script_history
      else
        echo "${0##*/}: _script_header.sh not found; cannot print history." >&2
        exit 1
      fi
      exit 0
      ;;
    -f|--format)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: $1 requires a format (aac|m4a|mp3|flac)" >&2
        exit 1
      fi
      OUTPUT_FORMAT=$2
      shift 2
      ;;
    --format=*)
      OUTPUT_FORMAT=${1#*=}
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
    *)
      if (( SPEED_SET )); then
        echo "Unexpected argument: $1" >&2
        echo "Try: $(basename "$0") --help" >&2
        exit 1
      fi
      SPEED_FACTOR=$1
      SPEED_SET=1
      shift
      ;;
  esac
done

if [[ ! "$SPEED_FACTOR" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "ERROR: SPEED must be a positive number (got: $SPEED_FACTOR)" >&2
  exit 1
fi

OUTPUT_FORMAT="${OUTPUT_FORMAT#.}"
OUTPUT_FORMAT="${OUTPUT_FORMAT,,}"
if [[ -n "$OUTPUT_FORMAT" ]]; then
  case "$OUTPUT_FORMAT" in
    aac|m4a|mp3|flac) ;;
    *)
      echo "ERROR: unsupported --format '$OUTPUT_FORMAT' (use: aac|m4a|mp3|flac)" >&2
      exit 1
      ;;
  esac
fi

if [[ -f /root/bin/_script_header.sh ]]; then
  # shellcheck source=/dev/null
  . /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"
fi

resolve_ffmpeg_bin() {
  local candidate=""

  if [[ -n "${FFMPEG_BIN:-}" && -x "${FFMPEG_BIN}" ]]; then
    printf '%s\n' "${FFMPEG_BIN}"
    return 0
  fi
  for candidate in /usr/local/bin/ffmpeg /usr/bin/ffmpeg; do
    if [[ -x "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  command -v ffmpeg 2>/dev/null || return 1
}

resolve_ffprobe_bin() {
  local candidate="" ffmpeg_dir=""

  if [[ -n "${FFPROBE_BIN:-}" && -x "${FFPROBE_BIN}" ]]; then
    printf '%s\n' "${FFPROBE_BIN}"
    return 0
  fi
  if [[ -n "${FFMPEG_BIN:-}" ]]; then
    ffmpeg_dir="$(dirname -- "${FFMPEG_BIN}")"
    if [[ -x "${ffmpeg_dir}/ffprobe" ]]; then
      printf '%s\n' "${ffmpeg_dir}/ffprobe"
      return 0
    fi
  fi
  for candidate in /usr/local/bin/ffprobe /usr/bin/ffprobe; do
    if [[ -x "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  command -v ffprobe 2>/dev/null || return 1
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  local name="$1"
  command -v "$name" >/dev/null 2>&1 || die "'$name' not found on PATH (required)."
}

# ---------------------------------------------------------------------------
# Session / summary state
# ---------------------------------------------------------------------------
SESSION_START_SEC=$SECONDS
SESSION_START_EPOCH="$(date '+%Y.%m.%d %H:%M:%S')"
SUMMARY_DONE=0
RUN_EXIT_CODE=0
RUN_OUTCOME=ok
SCAN_PROC_SEC=0
CONVERT_PROC_SEC=0
COUNT_FOUND=0
COUNT_OK=0
COUNT_FAILED=0
COUNT_SCAN_ERROR=0
CONVERT_DECLINED=0
FFMPEG_RESOLVED=""
FFPROBE_BIN=""
WORK_DIR=""
COVER_IMAGE=""
OUTPUT_EXT=aac
declare -a EPISODE_PAD_FROM=()
declare -a EPISODE_PAD_TO=()

declare -a SCAN_FILE=()
declare -a SCAN_MAX=()
declare -a SCAN_MEAN=()
declare -a SCAN_DUR=()
declare -a OUT_SRC=()
declare -a OUT_FILE=()
declare -a OUT_BEFORE_MAX=()
declare -a OUT_BEFORE_MEAN=()
declare -a OUT_BEFORE_DUR=()
declare -a OUT_BEFORE_SIZE=()
declare -a OUT_MAX=()
declare -a OUT_MEAN=()
declare -a OUT_DUR=()
declare -a OUT_SIZE=()

format_elapsed() {
  local sec="${1:-0}"
  local h m s
  if (( sec < 0 )); then
    sec=0
  fi
  h=$(( sec / 3600 ))
  m=$(( (sec % 3600) / 60 ))
  s=$(( sec % 60 ))
  if (( h > 0 )); then
    printf '%dh %02dm %02ds' "$h" "$m" "$s"
  elif (( m > 0 )); then
    printf '%dm %02ds' "$m" "$s"
  else
    printf '%ds' "$s"
  fi
}

summary_kv() {
  printf '  %-22s %s\n' "$1:" "$2"
}

format_db_cell() {
  local value="${1:-}"
  local num cell
  local width="${2:-10}"
  if [[ -z "$value" || "$value" == '—' || "$value" == '-' || "$value" == ERROR ]]; then
    printf '%*s' "$width" '—'
    return 0
  fi
  num="${value%%[[:space:]]dB*}"
  num="${num//[[:space:]]/}"
  cell="$(awk -v v="$num" 'BEGIN {
    v = v + 0
    s = sprintf("%.1f", v)
    if (s == "-0.0") s = "0.0"
    printf "%7.1f dB", s + 0
  }')"
  printf '%*s' "$width" "$cell"
}

# Seconds → "M:SS" or "H:MM:SS" (or em dash), fixed width for tables.
format_duration_cell() {
  local sec="${1:-}"
  local width="${2:-8}"
  if [[ -z "$sec" || "$sec" == '—' || "$sec" == '-' ]]; then
    printf '%*s' "$width" '—'
    return 0
  fi
  awk -v d="$sec" -v w="$width" 'BEGIN {
    if (d + 0 <= 0) { printf "%*s", w, "—"; exit }
    t = int(d + 0.5)
    h = int(t / 3600)
    m = int((t % 3600) / 60)
    s = t % 60
    if (h > 0) printf "%*s", w, sprintf("%d:%02d:%02d", h, m, s)
    else printf "%*s", w, sprintf("%d:%02d", m, s)
  }'
}

pad_center() {
  local text="$1" width="$2"
  local len=${#text} pad left right
  if (( len >= width )); then
    printf '%s' "$text"
    return 0
  fi
  pad=$(( width - len ))
  left=$(( pad / 2 ))
  right=$(( pad - left ))
  printf '%*s%s%*s' "$left" '' "$text" "$right" ''
}

dash_col() {
  local width="$1"
  printf '%*s' "$width" '' | tr ' ' '-'
}

# Sum of duration seconds from an array of numeric strings; empty skipped.
sum_duration_seconds() {
  local -n _arr=$1
  local x total=0
  for x in "${_arr[@]+"${_arr[@]}"}"; do
    [[ -n "$x" ]] || continue
    total="$(awk -v a="$total" -v b="$x" 'BEGIN { printf "%.3f", a + b }')"
  done
  printf '%s' "$total"
}

sum_integer_array() {
  local -n _arr=$1
  local x total=0
  for x in "${_arr[@]+"${_arr[@]}"}"; do
    [[ -n "$x" && "$x" =~ ^[0-9]+$ ]] || continue
    total=$(( total + x ))
  done
  printf '%s' "$total"
}

file_size_bytes() {
  local f="$1"
  stat -c '%s' -- "$f" 2>/dev/null || stat -f '%z' -- "$f" 2>/dev/null || printf ''
}

format_bytes_human() {
  local b="${1:-}"
  if [[ -z "$b" || ! "$b" =~ ^[0-9]+$ ]]; then
    printf '%s' '—'
    return 0
  fi
  if (( b >= 1099511627776 )); then
    awk -v b="$b" 'BEGIN { printf "%.2f TiB", b/1099511627776 }'
  elif (( b >= 1073741824 )); then
    awk -v b="$b" 'BEGIN { printf "%.2f GiB", b/1073741824 }'
  elif (( b >= 1048576 )); then
    awk -v b="$b" 'BEGIN { printf "%.1f MiB", b/1048576 }'
  elif (( b >= 1024 )); then
    awk -v b="$b" 'BEGIN { printf "%.1f KiB", b/1024 }'
  else
    printf '%s B' "$b"
  fi
}

# Average of numeric dB values in named array; empty if none usable. Prints bare number (e.g. -18.1).
average_db_from_array() {
  local -n _arr=$1
  local x count=0 sum=0
  for x in "${_arr[@]+"${_arr[@]}"}"; do
    [[ -n "$x" && "$x" != '—' && "$x" != '-' ]] || continue
    sum="$(awk -v a="$sum" -v b="$x" 'BEGIN { printf "%.6f", a + (b+0) }')"
    (( ++count )) || true
  done
  if (( count == 0 )); then
    printf ''
    return 1
  fi
  awk -v s="$sum" -v c="$count" 'BEGIN { printf "%.1f", s / c }'
}

media_duration_seconds() {
  local file="$1" d probe=""
  probe="${FFPROBE_BIN:-}"
  if [[ -z "$probe" || ! -x "$probe" ]]; then
    probe="$(resolve_ffprobe_bin 2>/dev/null || true)"
  fi
  [[ -n "$probe" && -x "$probe" ]] || return 1
  d="$("$probe" -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 -- "$file" 2>/dev/null)" || return 1
  [[ -n "$d" ]] || return 1
  awk -v d="$d" 'BEGIN { if (d+0 > 0) printf "%.3f\n", d+0; else exit 1 }'
}

parse_volumedetect_db() {
  local blob="$1" key="$2"
  awk -v key="$key" '
    index($0, key ":") {
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^-?[0-9]+(\.[0-9]+)?$/ && (i == NF || $(i + 1) == "dB")) {
          print $i
          exit
        }
      }
    }
  ' <<<"$blob"
}

# Ask before convert. Default No ([y/N/q]). Single keypress. Returns 0 = proceed, 1 = decline.
# q exits the script (summary via EXIT trap).
prompt_ts() {
  printf '[%s]' "$(date '+%Y.%m.%d %H:%M:%S')"
}

prompt_proceed_process() {
  local answer=""
  local cover_note=""

  if [[ -n "${COVER_IMAGE}" ]]; then
    cover_note=", cover=${COVER_IMAGE}"
  fi

  echo "About to process ${COUNT_FOUND} file(s): atempo=${SPEED_FACTOR}, speechnorm, output .${OUTPUT_EXT}${cover_note}"
  if [[ ! -t 0 ]]; then
    echo "Non-interactive stdin — defaulting to No (skip convert)."
    return 1
  fi

  printf '%s Process these files now? [y/N/q]: ' "$(prompt_ts)"
  # Discard any pending typeahead, then wait forever for one key (no Enter).
  while read -r -t 0 -n 1; do :; done 2>/dev/null || true
  read -r -n 1 answer || answer=
  echo
  # Empty / Enter → default N
  if [[ -z "${answer}" || "$answer" == $'\n' ]]; then
    answer=n
  fi
  case "${answer,,}" in
    y)
      printf '%s Selected: yes — converting.\n' "$(prompt_ts)"
      return 0
      ;;
    q)
      printf '%s Selected: quit.\n' "$(prompt_ts)"
      RUN_OUTCOME=quit
      RUN_EXIT_CODE=0
      exit 0
      ;;
    *)
      printf '%s Selected: no — skipping convert.\n' "$(prompt_ts)"
      return 1
      ;;
  esac
}

# Sets VD_MAX / VD_MEAN. Returns 0 if max_volume parsed.
measure_volumedetect() {
  local file="$1"
  local stderr_blob="" rc=0

  VD_MAX=""
  VD_MEAN=""
  stderr_blob="$("${FFMPEG_BIN}" -hide_banner -nostats -i "$file" -vn -af volumedetect -f null /dev/null 2>&1)" || rc=$?
  VD_MAX="$(parse_volumedetect_db "$stderr_blob" max_volume)"
  VD_MEAN="$(parse_volumedetect_db "$stderr_blob" mean_volume)"
  if [[ -n "$VD_MAX" ]]; then
    return 0
  fi
  # Simple fallback without -vn (some odd containers).
  stderr_blob="$("${FFMPEG_BIN}" -hide_banner -nostats -i "$file" -af volumedetect -f null /dev/null 2>&1)" || rc=$?
  VD_MAX="$(parse_volumedetect_db "$stderr_blob" max_volume)"
  VD_MEAN="$(parse_volumedetect_db "$stderr_blob" mean_volume)"
  [[ -n "$VD_MAX" ]]
}

# Fixed numeric column widths (must match header / separator / cells).
# MAX_VOLUME=10, MEAN_VOLUME=11, DURATION=8
SCAN_COL_MAX_W=10
SCAN_COL_MEAN_W=11
SCAN_COL_DUR_W=8
SCAN_COL_GAP='  '

print_scan_table_header() {
  local file_w="$1"
  printf '%-*s%s%s%s%s%s%s\n' \
    "$file_w" 'FILE' \
    "$SCAN_COL_GAP" "$(pad_center 'MAX_VOLUME' "$SCAN_COL_MAX_W")" \
    "$SCAN_COL_GAP" "$(pad_center 'MEAN_VOLUME' "$SCAN_COL_MEAN_W")" \
    "$SCAN_COL_GAP" "$(pad_center 'DURATION' "$SCAN_COL_DUR_W")"
  printf '%s%s%s%s%s%s%s\n' \
    "$(dash_col "$file_w")" \
    "$SCAN_COL_GAP" "$(dash_col "$SCAN_COL_MAX_W")" \
    "$SCAN_COL_GAP" "$(dash_col "$SCAN_COL_MEAN_W")" \
    "$SCAN_COL_GAP" "$(dash_col "$SCAN_COL_DUR_W")"
}

print_scan_table_row() {
  local file_w="$1" name="$2" max_db="$3" mean_db="$4" dur_sec="${5:-}"
  printf '%-*s%s%s%s%s%s%s\n' \
    "$file_w" "$name" \
    "$SCAN_COL_GAP" "$(format_db_cell "$max_db" "$SCAN_COL_MAX_W")" \
    "$SCAN_COL_GAP" "$(format_db_cell "$mean_db" "$SCAN_COL_MEAN_W")" \
    "$SCAN_COL_GAP" "$(format_duration_cell "$dur_sec" "$SCAN_COL_DUR_W")"
}

print_run_summary() {
  local i total_sec other_sec finished_str
  local max_b mean_b max_a mean_a dur_b dur_a size_b size_a
  local sum_before sum_after sum_size_in sum_size_out
  local avg_max_b avg_mean_b avg_max_a avg_mean_a
  local dur_diff_sec dur_pct size_diff size_pct

  (( SUMMARY_DONE == 0 )) || return 0
  SUMMARY_DONE=1

  finished_str="$(date '+%Y.%m.%d %H:%M:%S')"
  total_sec=$(( SECONDS - SESSION_START_SEC ))
  other_sec=$(( total_sec - SCAN_PROC_SEC - CONVERT_PROC_SEC ))
  if (( other_sec < 0 )); then
    other_sec=0
  fi

  echo
  echo '--- Run summary ---'
  summary_kv "Working directory" "${WORK_DIR:-$(pwd -P 2>/dev/null || pwd)}"
  summary_kv "Speed factor" "atempo=${SPEED_FACTOR}"
  if [[ -n "$OUTPUT_FORMAT" ]]; then
    summary_kv "Output format" ".${OUTPUT_EXT} (requested via --format)"
  else
    summary_kv "Output format" ".${OUTPUT_EXT} (auto)"
  fi
  if [[ -n "${FFMPEG_RESOLVED}" ]]; then
    summary_kv "ffmpeg" "$FFMPEG_RESOLVED"
  fi
  if [[ -n "${FFPROBE_BIN}" ]]; then
    summary_kv "ffprobe" "$FFPROBE_BIN"
  fi
  if [[ -n "${COVER_IMAGE}" ]]; then
    summary_kv "Cover image" "$COVER_IMAGE (embedded → .${OUTPUT_EXT})"
  else
    summary_kv "Cover image" "(none — output .${OUTPUT_EXT})"
  fi
  summary_kv "Files found" "$COUNT_FOUND"
  summary_kv "Converted OK" "$COUNT_OK"
  summary_kv "Convert failed" "$COUNT_FAILED"
  if (( CONVERT_DECLINED )); then
    summary_kv "Convert" "declined by user (default N)"
  fi
  if (( COUNT_SCAN_ERROR > 0 )); then
    summary_kv "Scan measure errors" "$COUNT_SCAN_ERROR"
  fi

  if (( COUNT_OK > 0 )); then
    echo
    echo '--- Before → after (max / mean / duration / size) ---'
    for i in "${!OUT_SRC[@]}"; do
      max_b="$(format_db_cell "${OUT_BEFORE_MAX[$i]:-}")"
      mean_b="$(format_db_cell "${OUT_BEFORE_MEAN[$i]:-}")"
      dur_b="$(format_duration_cell "${OUT_BEFORE_DUR[$i]:-}")"
      size_b="$(format_bytes_human "${OUT_BEFORE_SIZE[$i]:-}")"
      max_a="$(format_db_cell "${OUT_MAX[$i]:-}")"
      mean_a="$(format_db_cell "${OUT_MEAN[$i]:-}")"
      dur_a="$(format_duration_cell "${OUT_DUR[$i]:-}")"
      size_a="$(format_bytes_human "${OUT_SIZE[$i]:-}")"
      printf '  %s  →  %s\n' "${OUT_SRC[$i]}" "${OUT_FILE[$i]}"
      printf '    before %s / %s / %s / %s\n' "$max_b" "$mean_b" "$dur_b" "$size_b"
      printf '    after  %s / %s / %s / %s\n' "$max_a" "$mean_a" "$dur_a" "$size_a"
    done

    echo
    echo '--- Totals ---'
    sum_before="$(sum_duration_seconds OUT_BEFORE_DUR)"
    sum_after="$(sum_duration_seconds OUT_DUR)"
    summary_kv "Total input duration" "$(format_duration_cell "$sum_before" | sed 's/^[[:space:]]*//')"
    summary_kv "Total output duration" "$(format_duration_cell "$sum_after" | sed 's/^[[:space:]]*//')"
    dur_diff_sec="$(awk -v b="$sum_before" -v a="$sum_after" 'BEGIN { printf "%d", int((b + 0) - (a + 0) + 0.5) }')"
    if (( dur_diff_sec > 0 )); then
      dur_pct="$(awk -v b="$sum_before" -v d="$dur_diff_sec" 'BEGIN {
        if (b + 0 <= 0) { print ""; exit }
        printf "%.0f", 100.0 * d / b
      }')"
      if [[ -n "$dur_pct" ]]; then
        summary_kv "Shorter by" "$(format_elapsed "$dur_diff_sec")  (${dur_pct}% shorter than input)"
      else
        summary_kv "Shorter by" "$(format_elapsed "$dur_diff_sec")"
      fi
    elif (( dur_diff_sec < 0 )); then
      summary_kv "Longer by" "$(format_elapsed "$(( -dur_diff_sec ))")"
    else
      summary_kv "Shorter by" "unchanged"
    fi

    sum_size_in="$(sum_integer_array OUT_BEFORE_SIZE)"
    sum_size_out="$(sum_integer_array OUT_SIZE)"
    summary_kv "Total input size" "$(format_bytes_human "$sum_size_in")"
    summary_kv "Total output size" "$(format_bytes_human "$sum_size_out")"
    size_diff=$(( sum_size_in - sum_size_out ))
    if (( size_diff > 0 )); then
      size_pct="$(awk -v b="$sum_size_in" -v d="$size_diff" 'BEGIN {
        if (b + 0 <= 0) { print ""; exit }
        printf "%.0f", 100.0 * d / b
      }')"
      if [[ -n "$size_pct" ]]; then
        summary_kv "Smaller by" "$(format_bytes_human "$size_diff")  (${size_pct}% smaller than input)"
      else
        summary_kv "Smaller by" "$(format_bytes_human "$size_diff")"
      fi
    elif (( size_diff < 0 )); then
      summary_kv "Larger by" "$(format_bytes_human "$(( -size_diff ))")"
    else
      summary_kv "Smaller by" "unchanged"
    fi

    avg_max_b="$(average_db_from_array OUT_BEFORE_MAX || true)"
    avg_mean_b="$(average_db_from_array OUT_BEFORE_MEAN || true)"
    avg_max_a="$(average_db_from_array OUT_MAX || true)"
    avg_mean_a="$(average_db_from_array OUT_MEAN || true)"
    summary_kv "Avg max / mean before" "$(format_db_cell "$avg_max_b") / $(format_db_cell "$avg_mean_b")"
    summary_kv "Avg max / mean after" "$(format_db_cell "$avg_max_a") / $(format_db_cell "$avg_mean_a")"
  elif (( COUNT_FOUND > 0 )) && (( ${#SCAN_DUR[@]} > 0 )); then
    # Scan-only / declined convert: still report total input duration from pre-scan.
    echo
    echo '--- Totals ---'
    summary_kv "Total input duration" "$(format_duration_cell "$(sum_duration_seconds SCAN_DUR)" | sed 's/^[[:space:]]*//')"
    avg_max_b="$(average_db_from_array SCAN_MAX || true)"
    avg_mean_b="$(average_db_from_array SCAN_MEAN || true)"
    summary_kv "Avg max / mean (scan)" "$(format_db_cell "$avg_max_b") / $(format_db_cell "$avg_mean_b")"
  fi

  echo
  echo '--- Timing ---'
  summary_kv "Started" "$SESSION_START_EPOCH"
  summary_kv "Finished" "$finished_str"
  summary_kv "Total wall time" "$(format_elapsed "$total_sec")"
  summary_kv "Scan processing" "$(format_elapsed "$SCAN_PROC_SEC")  (volumedetect + duration)"
  summary_kv "Convert processing" "$(format_elapsed "$CONVERT_PROC_SEC")  (atempo+speechnorm + re-measure)"
  summary_kv "Other overhead" "$(format_elapsed "$other_sec")"
  case "$RUN_OUTCOME" in
    interrupted)
      summary_kv "Exit" "interrupted (Ctrl-C), code ${RUN_EXIT_CODE}"
      ;;
    quit)
      summary_kv "Exit" "quit (q), code ${RUN_EXIT_CODE}"
      ;;
    failed)
      summary_kv "Exit" "failed, code ${RUN_EXIT_CODE}"
      ;;
    *)
      summary_kv "Exit" "ok, code ${RUN_EXIT_CODE}"
      ;;
  esac
  echo
  echo "---- Script end   $0 ($finished_str)"
}

on_interrupt() {
  RUN_OUTCOME=interrupted
  RUN_EXIT_CODE=130
  exit 130
}

on_exit() {
  local rc=$?
  if (( RUN_EXIT_CODE == 0 )) && (( rc != 0 )); then
    RUN_EXIT_CODE=$rc
  fi
  if [[ "$RUN_OUTCOME" == ok ]] && (( RUN_EXIT_CODE != 0 )); then
    RUN_OUTCOME=failed
  fi
  print_run_summary
}

trap on_interrupt INT
trap on_exit EXIT

# Perl rename expressions applied to cwd basename and to selected files.
RENAME_EXPRS=(
  's/ /_/g'
  's/,/_/g'
  's/__/_/g'
  's/^!/_/g'
  's/!/./g'
  's|Ę|E|g'
  's|Ć|C|g'
  's|Ó|O|g'
  's|Ł|L|g'
  's|Ą|A|g'
  's|Ś|S|g'
  's|Ż|Z|g'
  's|Ź|Z|g'
  's|Ń|N|g'
  's|ę|e|g'
  's|ć|c|g'
  's|ó|o|g'
  's|ł|l|g'
  's|ą|a|g'
  's|ś|s|g'
  's|ż|z|g'
  's|ź|z|g'
  's|ń|n|g'
  's|\[|_|g'
  's|\]|_|g'
  's|\(|_|g'
  's|\)|_|g'
  's|__|_|g'
  's|_\.|\.|g'
  's|_$||g'
)

run_perl_rename() {
  # Debian/Ubuntu perl rename(1): rename 'expr' file...
  local expr=$1
  shift
  if (( $# == 0 )); then
    return 0
  fi
  rename "$expr" "$@" || true
}

# Reliable space→underscore (works even when rename(1) is util-linux, not perl).
replace_spaces_with_underscores_file() {
  local path="$1"
  local dir base new
  [[ -e "$path" ]] || return 0
  dir="$(dirname -- "$path")"
  base="$(basename -- "$path")"
  new="${base// /_}"
  if [[ "$base" == "$new" ]]; then
    return 0
  fi
  if [[ -e "${dir}/${new}" ]]; then
    echo "  skip space→underscore (target exists): $path → ${dir}/${new}" >&2
    return 0
  fi
  mv -v -- "$path" "${dir}/${new}"
}

replace_spaces_in_cwd_files() {
  local f
  while IFS= read -r -d '' f; do
    f="${f#./}"
    replace_spaces_with_underscores_file "$f"
  done < <(find . -maxdepth 1 -type f -name '* *' -print0 | sort -z)
}

sanitize_cwd_basename() {
  local cwd_name expr
  local parent new_name

  parent="$(dirname -- "$(readlink -f .)")"
  cwd_name="$(basename -- "$(readlink -f .)")"
  echo "cwd basename (before sanitize) = $cwd_name"

  # Spaces first, via mv (do not depend on perl rename).
  if [[ "$cwd_name" == *' '* ]]; then
    new_name="${cwd_name// /_}"
    if [[ ! -e "${parent}/${new_name}" ]]; then
      mv -v -- "${parent}/${cwd_name}" "${parent}/${new_name}"
      cwd_name="$new_name"
    else
      echo "  skip cwd space→underscore (target exists): ${parent}/${new_name}" >&2
    fi
    cd -- "${parent}/${cwd_name}"
  fi

  for expr in "${RENAME_EXPRS[@]}"; do
    # Skip space expr — already handled above with mv.
    [[ "$expr" == 's/ /_/g' ]] && continue
    cwd_name="$(basename -- "$(readlink -f .)")"
    (
      cd -- "$parent"
      run_perl_rename "$expr" "$cwd_name"
    )
  done

  cwd_name="$(basename -- "$(readlink -f .)")"
  echo "cwd basename (after sanitize)  = $cwd_name"
  # Refresh shell cwd if the directory was renamed under us.
  cd -- "${parent}/${cwd_name}"
}

cwd_media_doc_globs() {
  shopt -s nullglob
  local -a targets=(
    *.mp3 *.m4a *.aac *.flac *.jpg *.jpeg *.png *.doc *.pdf *.rtf *.txt
    *.MP3 *.M4A *.AAC *.FLAC *.JPG *.JPEG *.PNG *.DOC *.PDF *.RTF *.TXT
  )
  shopt -u nullglob
  printf '%s\0' "${targets[@]}"
}

# Sets COVER_IMAGE and OUTPUT_EXT.
# Exactly one jpg/jpeg/png → embed when OUTPUT_EXT supports album art.
# Default format (no -f): .aac, or .m4a when embedding a cover.
format_supports_cover() {
  case "$1" in
    m4a|mp3|flac) return 0 ;;
    *) return 1 ;;
  esac
}

resolve_cover_image() {
  local -a imgs=()
  local f

  COVER_IMAGE=""
  if [[ -n "$OUTPUT_FORMAT" ]]; then
    OUTPUT_EXT="$OUTPUT_FORMAT"
  else
    OUTPUT_EXT=aac
  fi

  mapfile -d '' -t imgs < <(
    find "${SOURCE_DIR:-.}" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
      -print0 | sort -z
  )
  if (( ${#imgs[@]} == 1 )) && [[ -z "${imgs[0]:-}" ]]; then
    imgs=()
  fi
  for i in "${!imgs[@]}"; do
    imgs[$i]="${imgs[$i]#./}"
  done

  if (( ${#imgs[@]} == 1 )); then
    if [[ -z "$OUTPUT_FORMAT" ]]; then
      OUTPUT_EXT=m4a
    fi
    if format_supports_cover "$OUTPUT_EXT"; then
      COVER_IMAGE="${imgs[0]}"
      echo "Cover image (exactly one): $COVER_IMAGE → embed in .${OUTPUT_EXT}"
    else
      echo "WARNING: cover image present (${imgs[0]}) but .${OUTPUT_EXT} does not support embedded album art — continuing without cover." >&2
      echo "         Use -f m4a, -f mp3, or -f flac to embed the cover." >&2
    fi
  elif (( ${#imgs[@]} == 0 )); then
    echo "Cover image: none found (jpg/jpeg/png) → outputs will be .${OUTPUT_EXT}"
  else
    echo "Cover image: ${#imgs[@]} images found — not embedding (need exactly one):"
    for f in "${imgs[@]}"; do
      echo "  - $f"
    done
    if ! format_supports_cover "$OUTPUT_EXT"; then
      echo "WARNING: image file(s) present but .${OUTPUT_EXT} does not support embedded album art." >&2
      echo "         Use -f m4a, -f mp3, or -f flac if you want a single cover embedded." >&2
    fi
    echo "Outputs will be .${OUTPUT_EXT}"
  fi
  echo
}

run_ffmpeg_convert() {
  local src="$1" output_file="$2"
  local -a acodec_args=()

  case "$OUTPUT_EXT" in
    mp3) acodec_args=(-c:a libmp3lame) ;;
    flac) acodec_args=(-c:a flac) ;;
    aac|m4a) acodec_args=(-c:a aac) ;;
    *) acodec_args=(-c:a aac) ;;
  esac

  if [[ -n "${COVER_IMAGE}" ]]; then
    case "$OUTPUT_EXT" in
      m4a)
        "${FFMPEG_BIN}" "${FFMPEG_COMMON_ARGS[@]}" \
          -i "$src" -i "$COVER_IMAGE" \
          -map 0:a:0 -map 1:0 \
          "${MONO_ARGS[@]}" \
          -filter:a "atempo=${SPEED_FACTOR},speechnorm" \
          "${acodec_args[@]}" \
          -c:v mjpeg -disposition:v:0 attached_pic \
          -metadata:s:v:0 title="Album cover" \
          -metadata:s:v:0 comment="Cover (front)" \
          "$output_file"
        ;;
      mp3)
        "${FFMPEG_BIN}" "${FFMPEG_COMMON_ARGS[@]}" \
          -i "$src" -i "$COVER_IMAGE" \
          -map 0:a:0 -map 1:0 \
          "${MONO_ARGS[@]}" \
          -filter:a "atempo=${SPEED_FACTOR},speechnorm" \
          "${acodec_args[@]}" \
          -c:v copy -disposition:v:0 attached_pic \
          -id3v2_version 3 \
          -metadata:s:v:0 title="Album cover" \
          -metadata:s:v:0 comment="Cover (front)" \
          "$output_file"
        ;;
      flac)
        "${FFMPEG_BIN}" "${FFMPEG_COMMON_ARGS[@]}" \
          -i "$src" -i "$COVER_IMAGE" \
          -map 0:a:0 -map 1:0 \
          "${MONO_ARGS[@]}" \
          -filter:a "atempo=${SPEED_FACTOR},speechnorm" \
          "${acodec_args[@]}" \
          -c:v copy -disposition:v:0 attached_pic \
          -metadata:s:v:0 title="Album cover" \
          -metadata:s:v:0 comment="Cover (front)" \
          "$output_file"
        ;;
      *)
        # Formats without cover support should not set COVER_IMAGE.
        "${FFMPEG_BIN}" "${FFMPEG_COMMON_ARGS[@]}" -i "$src" "${MONO_ARGS[@]}" \
          -filter:a "atempo=${SPEED_FACTOR},speechnorm" \
          "${acodec_args[@]}" "$output_file"
        ;;
    esac
  else
    "${FFMPEG_BIN}" "${FFMPEG_COMMON_ARGS[@]}" -i "$src" "${MONO_ARGS[@]}" \
      -filter:a "atempo=${SPEED_FACTOR},speechnorm" \
      "${acodec_args[@]}" "$output_file"
  fi
}

sanitize_files_in_cwd() {
  local expr
  local -a targets=()

  # Spaces first via mv (all files in cwd), then other sanitize via rename on media/docs.
  replace_spaces_in_cwd_files

  mapfile -d '' -t targets < <(cwd_media_doc_globs)
  if (( ${#targets[@]} == 1 )) && [[ -z "${targets[0]:-}" ]]; then
    targets=()
  fi
  if (( ${#targets[@]} == 0 )); then
    return 0
  fi

  for expr in "${RENAME_EXPRS[@]}"; do
    [[ "$expr" == 's/ /_/g' ]] && continue
    mapfile -d '' -t targets < <(cwd_media_doc_globs)
    if (( ${#targets[@]} == 1 )) && [[ -z "${targets[0]:-}" ]]; then
      targets=()
    fi
    if (( ${#targets[@]} == 0 )); then
      return 0
    fi
    run_perl_rename "$expr" "${targets[@]}"
  done
}

# True when cwd has a media file whose last _segment is 2+ digits (e.g. _10, _02).
cwd_has_multidigit_episode_numbers() {
  local f base stem last
  local -a files=()

  shopt -s nullglob
  files=( *.mp3 *.m4a *.aac *.flac *.MP3 *.M4A *.AAC *.FLAC )
  shopt -u nullglob
  for f in "${files[@]}"; do
    [[ "$f" == *SPEECHNORM_SPEEDUP* ]] && continue
    base="${f##*/}"
    stem="${base%.*}"
    last="${stem##*_}"
    if [[ "$last" =~ ^[0-9]{2,}$ ]]; then
      return 0
    fi
  done
  return 1
}

# Fill EPISODE_PAD_FROM / EPISODE_PAD_TO with pending _1.mp3 → _01.mp3 renames.
collect_trailing_single_digit_episode_renames() {
  local f base stem ext last new
  local -a files=()

  EPISODE_PAD_FROM=()
  EPISODE_PAD_TO=()

  if ! cwd_has_multidigit_episode_numbers; then
    return 0
  fi

  shopt -s nullglob
  files=( *.mp3 *.m4a *.aac *.flac *.MP3 *.M4A *.AAC *.FLAC )
  shopt -u nullglob

  for f in "${files[@]}"; do
    [[ "$f" == *SPEECHNORM_SPEEDUP* ]] && continue
    base="${f##*/}"
    ext="${base##*.}"
    stem="${base%.*}"
    last="${stem##*_}"
    if [[ ! "$last" =~ ^[1-9]$ ]]; then
      continue
    fi
    new="${stem%_*}_0${last}.${ext}"
    if [[ -e "$new" ]]; then
      echo "  skip zero-pad candidate (target exists): $f → $new" >&2
      continue
    fi
    EPISODE_PAD_FROM+=("$f")
    EPISODE_PAD_TO+=("$new")
  done
}

# Detect → show → ask [y/N/q] → rename only on y. Never renames without consent.
prompt_and_apply_trailing_episode_zero_pad() {
  local i answer=""

  collect_trailing_single_digit_episode_renames
  if (( ${#EPISODE_PAD_FROM[@]} == 0 )); then
    return 0
  fi

  echo "Detected trailing single-digit episode number(s) with multi-digit siblings:"
  for i in "${!EPISODE_PAD_FROM[@]}"; do
    echo "  ${EPISODE_PAD_FROM[$i]}  →  ${EPISODE_PAD_TO[$i]}"
  done
  echo

  if [[ ! -t 0 ]]; then
    echo "Non-interactive stdin — defaulting to No (skip episode zero-pad)."
    echo
    return 0
  fi

  printf '%s Zero-pad these episode number(s) now? [y/N/q]: ' "$(prompt_ts)"
  while read -r -t 0 -n 1; do :; done 2>/dev/null || true
  read -r -n 1 answer || answer=
  echo
  if [[ -z "${answer}" || "$answer" == $'\n' ]]; then
    answer=n
  fi
  case "${answer,,}" in
    y)
      printf '%s Selected: yes — renaming.\n' "$(prompt_ts)"
      for i in "${!EPISODE_PAD_FROM[@]}"; do
        if [[ -e "${EPISODE_PAD_FROM[$i]}" && ! -e "${EPISODE_PAD_TO[$i]}" ]]; then
          mv -v -- "${EPISODE_PAD_FROM[$i]}" "${EPISODE_PAD_TO[$i]}"
        fi
      done
      echo
      ;;
    q)
      printf '%s Selected: quit.\n' "$(prompt_ts)"
      RUN_OUTCOME=quit
      RUN_EXIT_CODE=0
      exit 0
      ;;
    *)
      printf '%s Selected: no — leaving names unchanged.\n' "$(prompt_ts)"
      echo
      ;;
  esac
}

ensure_org_dir() {
  if [[ -d org ]]; then
    return 0
  fi
  mkdir -p -- org
  chmod --reference=. org 2>/dev/null || true
  chown --reference=. org 2>/dev/null || true
  touch --reference=. org 2>/dev/null || true
}

zero_pad_single_digit_indices() {
  local n
  local -a targets=()

  # Middle-of-name _N_ → _0N_ (legacy; only after user already consented to process).
  for n in 1 2 3 4 5 6 7 8 9; do
    mapfile -d '' -t targets < <(cwd_media_doc_globs)
    if (( ${#targets[@]} == 1 )) && [[ -z "${targets[0]:-}" ]]; then
      targets=()
    fi
    if (( ${#targets[@]} == 0 )); then
      break
    fi
    rename --verbose "s|_${n}_|_0${n}_|g" "${targets[@]}" || true
  done
}

echo "---- Script start $0 ($(date '+%Y.%m.%d %H:%M:%S'))"

FFMPEG_BIN="$(resolve_ffmpeg_bin)" || die "ffmpeg not found (set FFMPEG_BIN or install ffmpeg)."
require_cmd rename
require_cmd rar

FFMPEG_RESOLVED="$(readlink -f "${FFMPEG_BIN}" 2>/dev/null || printf '%s' "${FFMPEG_BIN}")"
FFMPEG_VERSION="$("${FFMPEG_BIN}" -hide_banner -version 2>/dev/null | head -n1 || true)"
FFPROBE_BIN="$(resolve_ffprobe_bin 2>/dev/null || true)"
WORK_DIR="$(pwd -P 2>/dev/null || pwd)"

SOURCE_DIR="."
MONO_ARGS=( -ac 1 )
FFMPEG_COMMON_ARGS=( -y -hide_banner -loglevel error )

ls -l -- "$SOURCE_DIR"

echo "(PGM) speed factor (atempo) = $SPEED_FACTOR"
if [[ -n "$OUTPUT_FORMAT" ]]; then
  echo "(PGM) output format = .${OUTPUT_FORMAT} (requested)"
else
  echo "(PGM) output format = auto (.aac, or .m4a when embedding a cover)"
fi
echo "ffmpeg: ${FFMPEG_RESOLVED}"
if [[ -n "${FFMPEG_VERSION}" ]]; then
  echo "  ${FFMPEG_VERSION}"
fi
if [[ -n "${FFPROBE_BIN}" ]]; then
  echo "ffprobe: ${FFPROBE_BIN}"
else
  echo "ffprobe: (not found — duration columns will be —)"
fi
echo

sanitize_cwd_basename
sanitize_files_in_cwd
prompt_and_apply_trailing_episode_zero_pad
WORK_DIR="$(pwd -P 2>/dev/null || pwd)"
resolve_cover_image

mapfile -d '' -t audio_files < <(
  find "${SOURCE_DIR}" -maxdepth 1 -type f \
    \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.aac' \) \
    ! -name '*SPEECHNORM_SPEEDUP*' \
    -print0 | sort -z
)
if (( ${#audio_files[@]} == 1 )) && [[ -z "${audio_files[0]:-}" ]]; then
  audio_files=()
fi

# Normalize paths to basename-relative (drop ./)
for i in "${!audio_files[@]}"; do
  audio_files[$i]="${audio_files[$i]#./}"
done

COUNT_FOUND=${#audio_files[@]}

if (( COUNT_FOUND == 0 )); then
  echo "No .mp3 / .m4a / .aac files to process in: $WORK_DIR"
else
  # ---- Pre-scan ----
  echo "=== Pre-scan (volumedetect + duration) ==="
  file_w=4
  for src in "${audio_files[@]}"; do
    if (( ${#src} > file_w )); then
      file_w=${#src}
    fi
  done
  if (( file_w > 80 )); then
    file_w=80
  fi
  print_scan_table_header "$file_w"

  scan_t0=$SECONDS
  for src in "${audio_files[@]}"; do
    SCAN_FILE+=("$src")
    dur=""
    if [[ ! -f "$src" ]]; then
      SCAN_MAX+=("")
      SCAN_MEAN+=("")
      SCAN_DUR+=("")
      print_scan_table_row "$file_w" "$src" "" "" ""
      (( ++COUNT_SCAN_ERROR )) || true
      continue
    fi
    if dur="$(media_duration_seconds "$src")"; then
      :
    else
      dur=""
    fi
    SCAN_DUR+=("$dur")
    if measure_volumedetect "$src"; then
      SCAN_MAX+=("$VD_MAX")
      SCAN_MEAN+=("${VD_MEAN:-}")
      print_scan_table_row "$file_w" "$src" "$VD_MAX" "${VD_MEAN:-}" "$dur"
    else
      SCAN_MAX+=("")
      SCAN_MEAN+=("")
      print_scan_table_row "$file_w" "$src" "" "" "$dur"
      echo "  (volumedetect failed for $src — will still attempt convert)" >&2
      (( ++COUNT_SCAN_ERROR )) || true
    fi
  done
  SCAN_PROC_SEC=$(( SECONDS - scan_t0 ))
  echo
  echo "Pre-scan done in $(format_elapsed "$SCAN_PROC_SEC")."
  echo

  if ! prompt_proceed_process; then
    CONVERT_DECLINED=1
  else
    # ---- Convert ----
    convert_t0=$SECONDS
    for i in "${!audio_files[@]}"; do
      src="${audio_files[$i]}"
      if [[ ! -f "$src" ]]; then
        continue
      fi
      if [[ "$src" == *SPEECHNORM_SPEEDUP* ]]; then
        continue
      fi

      echo "######################################"
      echo
      ext="${src##*.}"
      base="$(basename -- "$src" ".$ext")"
      dir="$(dirname -- "$src")"
      if [[ "$dir" == "." ]]; then
        output_file="${base}_SPEECHNORM_SPEEDUP_${SPEED_FACTOR}.${OUTPUT_EXT}"
      else
        output_file="${dir}/${base}_SPEECHNORM_SPEEDUP_${SPEED_FACTOR}.${OUTPUT_EXT}"
      fi

      echo "$src  →  $output_file"
      if [[ -n "${COVER_IMAGE}" ]]; then
        echo "Cover: $COVER_IMAGE"
      fi
      echo "Before: max $(format_db_cell "${SCAN_MAX[$i]:-}")  mean $(format_db_cell "${SCAN_MEAN[$i]:-}")  duration $(format_duration_cell "${SCAN_DUR[$i]:-}")"

      if ! run_ffmpeg_convert "$src" "$output_file"; then
        echo
        echo "!!!!! ffmpeg failed for file: $src !!!!!!!!"
        echo "Exiting."
        echo
        rm -f -- "$output_file"
        (( ++COUNT_FAILED )) || true
        CONVERT_PROC_SEC=$(( SECONDS - convert_t0 ))
        RUN_OUTCOME=failed
        RUN_EXIT_CODE=2
        exit 2
      fi

      after_max=""
      after_mean=""
      after_dur=""
      if measure_volumedetect "$output_file"; then
        after_max="$VD_MAX"
        after_mean="${VD_MEAN:-}"
      else
        (( ++COUNT_SCAN_ERROR )) || true
      fi
      if after_dur="$(media_duration_seconds "$output_file")"; then
        :
      else
        after_dur=""
        (( ++COUNT_SCAN_ERROR )) || true
      fi
      echo "After:  max $(format_db_cell "$after_max")  mean $(format_db_cell "$after_mean")  duration $(format_duration_cell "$after_dur")"

      size_in="$(file_size_bytes "$src")"
      size_out="$(file_size_bytes "$output_file")"

      chmod --reference="$src" -- "$output_file" 2>/dev/null || true
      chown --reference="$src" -- "$output_file" 2>/dev/null || true
      touch --reference="$src" -- "$output_file" 2>/dev/null || true
      ensure_org_dir
      mv -v -- "$src" org/

      OUT_SRC+=("$src")
      OUT_FILE+=("$output_file")
      OUT_BEFORE_MAX+=("${SCAN_MAX[$i]:-}")
      OUT_BEFORE_MEAN+=("${SCAN_MEAN[$i]:-}")
      OUT_BEFORE_DUR+=("${SCAN_DUR[$i]:-}")
      OUT_BEFORE_SIZE+=("$size_in")
      OUT_MAX+=("$after_max")
      OUT_MEAN+=("$after_mean")
      OUT_DUR+=("$after_dur")
      OUT_SIZE+=("$size_out")
      (( ++COUNT_OK )) || true
      sleep 0.2
    done
    CONVERT_PROC_SEC=$(( SECONDS - convert_t0 ))
  fi
fi

cd -- "$SOURCE_DIR"
zero_pad_single_digit_indices

if [[ -d org ]] && compgen -G 'org/*' >/dev/null 2>&1; then
  rar m -htb -m5 org.rar org
elif [[ -d org ]]; then
  rmdir -- org 2>/dev/null || true
fi

RUN_EXIT_CODE=0
exit 0
