#!/bin/bash

# 2026.06.16 - v. 0.3.3 - startup “offer normalize after scan?” defaults to yes
# 2026.06.16 - v. 0.3.2 - scan table: right-align MAX/MEAN dB columns (decimal aligned, not minus)
# 2026.06.16 - v. 0.3.1 - normalize prompts default N; [Q] quit on normalize-related prompts
# 2026.06.16 - v. 0.3.0 - no CLI flags: interactive startup; stream scan rows one-by-one (no hang)
# 2026.06.16 - v. 0.2.2 - legend: indent PERFECT dB range one column (leading minus on other rows)
# 2026.06.16 - v. 0.2.1 - align classification legend columns (label / dB / description)
# 2026.06.16 - v. 0.2 - dB cheat-sheet categories; optional loudnorm (standard / youtube-style); preserve mtime
# 2026.06.16 - v. 0.1 - initial release: scan cwd for audio/video; ffmpeg volumedetect; flag too-silent files

print_version_banner() {
  local ver=unknown date= line title verline width=60
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*) ]]; then
      date="${BASH_REMATCH[1]}"
      ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  title="$(basename "$0")"
  if [[ -n "$date" ]]; then
    verline="Version: ${ver} (${date})"
  else
    verline="Version: ${ver}"
  fi
  printf '┌%*s┐\n' "$width" '' | tr ' ' '─'
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$title"
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$verline"
  printf '└%*s┘\n' "$width" '' | tr ' ' '─'
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]
       [-n standard|youtube|none] [-y] [-- FILE ...]

Scan the current directory for audio and video files and measure loudness with
ffmpeg volumedetect (video is ignored for speed). Each file is classified by
peak level (max_volume):

  PERFECT (0.0 to -2.0 dB)     Already near digital maximum — do not normalize.
  NORMAL  (-2.0 to -6.0 dB)    Usually fine; normalize only if you want louder mix.
  TOO QUIET (-6.0 dB or lower) Prime candidates for loudnorm (quiet dialogue).

Optionally normalize TOO QUIET files in place (original modification time kept).

Supported extensions (case-insensitive):
  Video: .avi .mp4 .mkv .mov .wmv .mpeg .mpg .m4v .webm .ts
  Audio: .mp3 .flac .wav .m4a .aac .ogg .opus .wma

With FILE operands, only those paths are checked (must exist). Without FILE,
every supported file in the current working directory is scanned.

When no command-line options are given (only optional FILE operands), the script
runs in interactive mode: it asks before scanning and prints each result row as
soon as that file is measured (so a long scan does not look hung).

Normalization (TOO QUIET files only):
  standard   ffmpeg loudnorm (default filter parameters)
  youtube    loudnorm=I=-16:TP=-1.0:LRA=11  (YouTube-style targets)

Video files: audio filtered, video stream copied (-c:v copy).
After a successful in-place replace, the output file gets the original timestamps
(mtime/atime) back via touch -r.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  -n, --normalize MODE none|standard|youtube
                       Normalize TOO QUIET files (default: ask when interactive,
                       skip when not interactive unless -n is set).
  -y, --yes            Do not ask per file; normalize every TOO QUIET file when
                       -n standard or -n youtube is selected.
  --no_startup_delay   Skip random startup delay when run non-interactively
                       (see _script_header.sh).
  -- FILE              Explicit file operands (use when a name starts with -).

Environment:
  LOUDNESS_NORMALIZE   Same as -n / --normalize (CLI overrides).

Exit status:
  0  Scan OK and (if requested) normalization finished without failures.
  1  Errors, or TOO QUIET files remain after a scan-only run.

Examples:
  cd /path/to/clips && $(basename "$0")
  $(basename "$0") -n youtube -y
  $(basename "$0") -n standard -- quiet_interview.mkv
EOF
}

NORMALIZE_MODE="${LOUDNESS_NORMALIZE:-}"
AUTO_YES=0
CLI_FILES=()
ANY_CLI_OPTIONS=0

# --- parse options before sourcing the header (avoids figlet/delay on --help/--version) ---
HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      print_version_banner
      exit 0
      ;;
    --no_startup_delay)
      ANY_CLI_OPTIONS=1
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    -n|--normalize)
      ANY_CLI_OPTIONS=1
      [[ $# -ge 2 ]] || { echo "Missing value for --normalize" >&2; exit 1; }
      NORMALIZE_MODE="$2"
      shift 2
      ;;
    -y|--yes)
      ANY_CLI_OPTIONS=1
      AUTO_YES=1
      shift
      ;;
    --)
      shift
      CLI_FILES+=( "$@" )
      break
      ;;
    -*)
      echo "Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
    *)
      CLI_FILES+=( "$1" )
      shift
      ;;
  esac
done

case "${NORMALIZE_MODE,,}" in
  ''|none|standard|youtube) ;;
  *)
    echo "Invalid --normalize / LOUDNESS_NORMALIZE: ${NORMALIZE_MODE}" >&2
    echo "Use: none, standard, or youtube" >&2
    exit 1
    ;;
esac
NORMALIZE_MODE="${NORMALIZE_MODE,,}"

# No flags at all (FILE operands alone are OK): presume interactive prompts and streaming scan.
PRESUME_INTERACTIVE=0
(( ! ANY_CLI_OPTIONS )) && PRESUME_INTERACTIVE=1

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

if [[ -f "${BASH_SOURCE[0]}" ]]; then
  chmod 700 "${BASH_SOURCE[0]}" 2>/dev/null || true
fi

LOUDNESS_READ_TIMEOUT="${LOUDNESS_READ_TIMEOUT:-300}"

audio_pgm_loudness_cleanup() {
  [[ -n "${LOUDNESS_TMP_FILE:-}" && -f "${LOUDNESS_TMP_FILE}" ]] && rm -f -- "${LOUDNESS_TMP_FILE}"
  . /root/bin/_script_footer.sh
}
trap audio_pgm_loudness_cleanup EXIT

check_if_installed ffmpeg || true
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ERROR: ffmpeg is required but was not found in PATH." >&2
  echo "Try: ffmpeg-install.sh   or install the ffmpeg package." >&2
  kod_powrotu=1
  exit 1
fi

shopt -s nullglob nocaseglob

MEDIA_EXTENSIONS=(
  avi mp4 mkv mov wmv mpeg mpg m4v webm ts
  mp3 flac wav m4a aac ogg opus wma
)

LOUDNESS_TMP_FILE=""

loudness_is_interactive() {
  (( PRESUME_INTERACTIVE )) && return 0
  (( script_is_run_interactively )) && return 0
  return 1
}

loudness_quit_now() {
  echo "Quit requested."
  kod_powrotu=0
  exit 0
}

flush_stdin() {
  local discard drained=0
  while (( drained < 256 )) && IFS= read -r -t 0.02 -n 1 discard; do
    (( ++drained ))
  done
}

loudness_read_key() {
  local prompt="$1" default="${2:-N}" timeout="${3:-$LOUDNESS_READ_TIMEOUT}"
  local answer=""

  if ! loudness_is_interactive; then
    REPLY="$default"
    return 0
  fi

  printf '%s' "$prompt"
  flush_stdin
  if [[ "$timeout" =~ ^[0-9]+$ ]] && (( timeout > 0 )); then
    read -t "$timeout" -n 1 answer || answer=""
  else
    read -n 1 answer || answer=""
  fi
  echo
  if [[ -z "$answer" ]]; then
    REPLY="$default"
  else
    REPLY="$answer"
  fi
}

# Collect unique paths (sorted) from cwd or CLI operands.
collect_media_files() {
  local -a found=() f ext
  declare -A seen=()

  if (( ${#CLI_FILES[@]} > 0 )); then
    for f in "${CLI_FILES[@]}"; do
      [[ -e "$f" ]] || { echo "ERROR: file not found: $f" >&2; return 1; }
      [[ -f "$f" ]] || { echo "ERROR: not a regular file: $f" >&2; return 1; }
      if [[ -n "${seen[$f]+x}" ]]; then
        continue
      fi
      seen[$f]=1
      found+=( "$f" )
    done
  else
    for ext in "${MEDIA_EXTENSIONS[@]}"; do
      for f in *."$ext"; do
        [[ -f "$f" ]] || continue
        if [[ -n "${seen[$f]+x}" ]]; then
          continue
        fi
        seen[$f]=1
        found+=( "$f" )
      done
    done
  fi

  if (( ${#found[@]} == 0 )); then
    return 0
  fi

  mapfile -t MEDIA_FILES < <(printf '%s\n' "${found[@]}" | LC_ALL=C sort -u)
}

file_has_audio_stream() {
  local file="$1"
  ffprobe -v error -select_streams a:0 -show_entries stream=index -of csv=p=0 -- "$file" 2>/dev/null | grep -q .
}

file_has_video_stream() {
  local file="$1"
  ffprobe -v error -select_streams v:0 -show_entries stream=index -of csv=p=0 -- "$file" 2>/dev/null | grep -q .
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

measure_loudness() {
  local file="$1" stderr_blob max_db mean_db rc

  stderr_blob="$(ffmpeg -hide_banner -nostats -i "$file" -af volumedetect -vn -f null /dev/null 2>&1)" || rc=$?
  rc="${rc:-0}"

  max_db="$(parse_volumedetect_db "$stderr_blob" max_volume)"
  mean_db="$(parse_volumedetect_db "$stderr_blob" mean_volume)"

  if [[ -z "$max_db" ]]; then
    if grep -qiE 'does not contain any stream|Stream map .* matches no streams|Output file #0 does not contain any stream' <<<"$stderr_blob"; then
      return 2
    fi
    (( rc != 0 )) && return 3
    return 4
  fi

  printf '%s %s\n' "$max_db" "${mean_db:--}"
  return 0
}

# PERFECT | NORMAL | TOO_QUIET based on max_volume peak (dB).
classify_max_volume() {
  local max_db="$1"
  awk -v max="$max_db" 'BEGIN {
    if (max + 0 >= -2.0) {
      print "PERFECT"
      exit 0
    }
    if (max + 0 > -6.0) {
      print "NORMAL"
      exit 0
    }
    print "TOO_QUIET"
  }'
}

loudnorm_filter_for_mode() {
  case "$1" in
    standard) printf '%s' 'loudnorm' ;;
    youtube)  printf '%s' 'loudnorm=I=-16:TP=-1.0:LRA=11' ;;
    *) return 1 ;;
  esac
}

restore_file_timestamps_from_ref() {
  local file="$1" ref="$2"
  [[ -f "$file" && -f "$ref" ]] || return 1
  touch -r "$ref" "$file"
}

normalize_file_inplace() {
  local file="$1" filter="$2"
  local tmp ref ext ffmpeg_rc=0 ts_ref

  ext="${file##*.}"
  tmp="${file}.tmp.${ext}.$$"
  ts_ref="$(mktemp)"
  touch -r "$file" "$ts_ref"
  LOUDNESS_TMP_FILE="$tmp"

  if file_has_video_stream "$file"; then
    ffmpeg -hide_banner -nostats -y -i "$file" -filter:a "$filter" -c:v copy -- "$tmp" \
      >/dev/null 2>&1 || ffmpeg_rc=$?
  else
    ffmpeg -hide_banner -nostats -y -i "$file" -filter:a "$filter" -- "$tmp" \
      >/dev/null 2>&1 || ffmpeg_rc=$?
  fi

  if (( ffmpeg_rc != 0 )) || [[ ! -s "$tmp" ]]; then
    rm -f -- "$tmp" "$ts_ref"
    LOUDNESS_TMP_FILE=""
    return 1
  fi

  if ! mv -f -- "$tmp" "$file"; then
    rm -f -- "$tmp" "$ts_ref"
    LOUDNESS_TMP_FILE=""
    return 1
  fi
  LOUDNESS_TMP_FILE=""

  restore_file_timestamps_from_ref "$file" "$ts_ref"
  rm -f -- "$ts_ref"
  return 0
}

_table_col_width() {
  local cur="$1" text="$2"
  (( ${#text} > cur )) && printf '%s' "${#text}" || printf '%s' "$cur"
}

print_loudness_class_legend() {
  local label_w=9 range_w=18
  printf '  %-*s  %-*s  — %s\n' "$label_w" 'PERFECT'   "$range_w" ' 0.0 to -2.0 dB'   'do not normalize'
  printf '  %-*s  %-*s  — %s\n' "$label_w" 'NORMAL'    "$range_w" '-2.0 to -6.0 dB'   'usually fine'
  printf '  %-*s  %-*s  — %s\n' "$label_w" 'TOO QUIET' "$range_w" '-6.0 dB or lower' 'loudnorm candidates'
}

declare -a ROW_FILE=() ROW_MAX=() ROW_MEAN=() ROW_STATUS=()
declare -a TOO_QUIET_FILES=() TOO_QUIET_MAX=()

REPORT_FILE_W=4
REPORT_MAX_W=10
REPORT_MEAN_W=11
REPORT_STATUS_W=6

init_report_column_widths() {
  local f
  REPORT_FILE_W=4
  # Right-aligned cells: "%8.1f dB" (11 chars) so decimals line up, not the minus sign.
  REPORT_MAX_W=11
  REPORT_MEAN_W=11
  REPORT_STATUS_W=6
  for f in "${MEDIA_FILES[@]}"; do
    REPORT_FILE_W=$(_table_col_width "$REPORT_FILE_W" "$f")
  done
  REPORT_MAX_W=$(_table_col_width "$REPORT_MAX_W" 'MAX_VOLUME')
  REPORT_MEAN_W=$(_table_col_width "$REPORT_MEAN_W" 'MEAN_VOLUME')
  REPORT_STATUS_W=$(_table_col_width "$REPORT_STATUS_W" 'TOO_QUIET')
  REPORT_STATUS_W=$(_table_col_width "$REPORT_STATUS_W" 'NO AUDIO')
}

# Right-align a volumedetect dB value (or em dash) within a fixed column width.
format_scan_db_cell() {
  local value="$1" width="$2" num
  if [[ "$value" == '—' || "$value" == '-' || -z "$value" ]]; then
    printf '%*s' "$width" '—'
    return 0
  fi
  num="${value%%[[:space:]]dB*}"
  num="${num//[[:space:]]/}"
  awk -v v="$num" -v w="$width" 'BEGIN { printf "%*s", w, sprintf("%8.1f dB", v + 0) }'
}

print_report_table_header() {
  local sep
  printf '%-*s  %*s  %*s  %-*s\n' \
    "$REPORT_FILE_W" 'FILE' \
    "$REPORT_MAX_W" 'MAX_VOLUME' \
    "$REPORT_MEAN_W" 'MEAN_VOLUME' \
    "$REPORT_STATUS_W" 'STATUS'
  sep="$(printf '%*s' "$(( REPORT_FILE_W + REPORT_MAX_W + REPORT_MEAN_W + REPORT_STATUS_W + 6 ))" '' | tr ' ' '-')"
  printf '%s\n' "$sep"
}

print_report_table_row() {
  local file="$1" max_val="$2" mean_val="$3" status="$4"
  local max_cell mean_cell
  max_cell="$(format_scan_db_cell "$max_val" "$REPORT_MAX_W")"
  mean_cell="$(format_scan_db_cell "$mean_val" "$REPORT_MEAN_W")"
  printf '%-*s  %s  %s  %-*s\n' \
    "$REPORT_FILE_W" "$file" \
    "$max_cell" "$mean_cell" \
    "$REPORT_STATUS_W" "$status"
}

append_scan_row() {
  local file="$1" max_val="$2" mean_val="$3" status="$4" max_db="${5:-}"
  ROW_FILE+=( "$file" )
  ROW_MAX+=( "$max_val" )
  ROW_MEAN+=( "$mean_val" )
  ROW_STATUS+=( "$status" )
  if [[ "$status" == TOO_QUIET ]]; then
    TOO_QUIET_FILES+=( "$file" )
    TOO_QUIET_MAX+=( "$max_db" )
  fi
}

print_scan_summary() {
  local count_perfect=0 count_normal=0 count_too_quiet=0 count_no_audio=0 count_error=0 i

  for i in "${!ROW_STATUS[@]}"; do
    case "${ROW_STATUS[$i]}" in
      PERFECT)    (( ++count_perfect )) ;;
      NORMAL)     (( ++count_normal )) ;;
      TOO_QUIET)  (( ++count_too_quiet )) ;;
      'NO AUDIO') (( ++count_no_audio )) ;;
      ERROR)      (( ++count_error )) ;;
    esac
  done

  echo
  printf 'Summary: %d perfect, %d normal, %d too quiet, %d no audio, %d error(s)\n' \
    "$count_perfect" "$count_normal" "$count_too_quiet" "$count_no_audio" "$count_error"

  if (( count_error > 0 || count_no_audio > 0 )); then
    return 1
  fi
  if (( count_too_quiet > 0 )); then
    return 2
  fi
  return 0
}

scan_one_media_file() {
  local file="$1"
  local max_db mean_db status measure_rc measure_line

  if ! file_has_audio_stream "$file"; then
    append_scan_row "$file" '—' '—' 'NO AUDIO'
    print_report_table_row "$file" '—' '—' 'NO AUDIO'
    return 0
  fi

  measure_rc=0
  measure_line="$(measure_loudness "$file")" || measure_rc=$?
  if (( measure_rc != 0 )); then
    if (( measure_rc == 2 )); then
      status='NO AUDIO'
    else
      status='ERROR'
    fi
    append_scan_row "$file" '—' '—' "$status"
    print_report_table_row "$file" '—' '—' "$status"
    return 0
  fi

  read -r max_db mean_db <<<"$measure_line"
  status="$(classify_max_volume "$max_db")"

  append_scan_row "$file" "$max_db" "$mean_db" "$status" "$max_db"
  print_report_table_row "$file" "$max_db" "$mean_db" "$status"
  return 0
}

scan_media_files_with_report() {
  local file

  ROW_FILE=()
  ROW_MAX=()
  ROW_MEAN=()
  ROW_STATUS=()
  TOO_QUIET_FILES=()
  TOO_QUIET_MAX=()

  init_report_column_widths
  print_report_table_header

  for file in "${MEDIA_FILES[@]}"; do
    scan_one_media_file "$file"
  done

  print_scan_summary
}

prompt_startup_interactive() {
  local n="${#MEDIA_FILES[@]}"

  echo "Files to scan: ${n}"
  echo
  loudness_read_key "$(date '+%Y.%m.%d %H:%M:%S') Proceed with loudness scan? [Y/n/q]: " Y
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    N)
      echo "Scan skipped."
      kod_powrotu=0
      exit 0
      ;;
  esac

  echo
  loudness_read_key "$(date '+%Y.%m.%d %H:%M:%S') If too-quiet files are found, offer normalize after scan? [Y/n/q]: " Y
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    N) LOUDNESS_OFFER_NORMALIZE=0 ;;
    *) LOUDNESS_OFFER_NORMALIZE=1 ;;
  esac
  echo
}

prompt_normalize_mode() {
  local n="${#TOO_QUIET_FILES[@]}"

  echo
  echo "${n} file(s) are TOO QUIET (max_volume <= -6.0 dB)."
  echo "  [S] Standard loudnorm"
  echo "  [Y] YouTube-style loudnorm (I=-16:TP=-1.0:LRA=11)"
  echo "  [N] Skip normalization (default)"
  echo "  [Q] Quit"
  loudness_read_key "$(date '+%Y.%m.%d %H:%M:%S') Normalize? [S/y/N/q]: " N
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    S) NORMALIZE_MODE=standard ;;
    Y) NORMALIZE_MODE=youtube ;;
    *) NORMALIZE_MODE=none ;;
  esac
}

normalize_too_quiet_files() {
  local filter file max_db i norm_ok=0 norm_fail=0 norm_skip=0 answer

  filter="$(loudnorm_filter_for_mode "$NORMALIZE_MODE")" || {
    echo "ERROR: unknown normalize mode: ${NORMALIZE_MODE}" >&2
    return 1
  }

  echo
  echo "Normalization mode: ${NORMALIZE_MODE} (${filter})"
  echo "Only TOO QUIET files are processed; timestamps are preserved."
  echo

  for i in "${!TOO_QUIET_FILES[@]}"; do
    file="${TOO_QUIET_FILES[$i]}"
    max_db="${TOO_QUIET_MAX[$i]}"

    if (( ! AUTO_YES )); then
      loudness_read_key "$(date '+%Y.%m.%d %H:%M:%S') Normalize ${file} (${max_db} dB)? [y/N/q]: " N
      case "${REPLY^^}" in
        Q) echo "Quit requested." ; return 2 ;;
        Y) ;;
        *) (( ++norm_skip )) ; continue ;;
      esac
    fi

    printf 'Normalizing %s (was %s dB peak) ... ' "$file" "$max_db"
    if normalize_file_inplace "$file" "$filter"; then
      echo 'OK'
      (( ++norm_ok ))
    else
      echo 'FAILED'
      (( ++norm_fail ))
    fi
  done

  echo
  printf 'Normalization: %d OK, %d skipped, %d failed\n' "$norm_ok" "$norm_skip" "$norm_fail"
  (( norm_fail > 0 )) && return 1
  return 0
}

LOUDNESS_OFFER_NORMALIZE=1

MEDIA_FILES=()
if ! collect_media_files; then
  kod_powrotu=1
  exit 1
fi

echo "Audio loudness scan: $(pwd)"
echo "Classification (max_volume peak):"
print_loudness_class_legend
echo "Tool: ffmpeg volumedetect (-vn for video files)"
echo

if (( ${#MEDIA_FILES[@]} == 0 )); then
  echo "No supported audio/video files found in $(pwd)."
  echo "Extensions: ${MEDIA_EXTENSIONS[*]}"
  kod_powrotu=0
  exit 0
fi

if loudness_is_interactive; then
  prompt_startup_interactive
else
  echo "Files to scan: ${#MEDIA_FILES[@]}"
  echo
fi

scan_rc=0
scan_media_files_with_report || scan_rc=$?

if (( scan_rc == 1 )); then
  kod_powrotu=1
  exit 1
fi

if (( ${#TOO_QUIET_FILES[@]} == 0 )); then
  kod_powrotu=0
  exit 0
fi

if [[ -z "$NORMALIZE_MODE" ]]; then
  if loudness_is_interactive && (( LOUDNESS_OFFER_NORMALIZE )); then
    prompt_normalize_mode
  else
    NORMALIZE_MODE=none
  fi
fi

if [[ "$NORMALIZE_MODE" == none || -z "$NORMALIZE_MODE" ]]; then
  kod_powrotu=1
  exit 1
fi

if normalize_too_quiet_files; then
  kod_powrotu=0
else
  norm_rc=$?
  if (( norm_rc == 2 )); then
    kod_powrotu=130
  else
    kod_powrotu=1
  fi
fi

exit "${kod_powrotu:-0}"
