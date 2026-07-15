#!/bin/bash

# 2026.06.23 - v. 0.6.1 - accept --start=SEC and --length=SEC (equals form)
# 2026.06.23 - v. 0.6 - --start and --length for playing a segment (mpv seek + clip length)
# 2026.06.23 - v. 0.5 - print full mpv command line before countdown / playback
# 2026.06.23 - v. 0.4 - autodetect terminal size (default); countdown before playback
# 2026.06.23 - v. 0.3 - --width/-w and --height/-H: tct size; one dimension from video aspect ratio
# 2026.06.23 - v. 0.2 - --silent: hide mpv status on terminal (mpv --no-terminal); --profile=sw-fast
# 2026.06.23 - v. 0.1 - initial release: play one media file in the terminal with mpv --vo=tct

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
Usage: $(basename "$0") [-h|--help] [-v|--version] [--silent] [--no-silent]
       [--autodetect] [--no-autodetect] [--countdown SEC] [--no-countdown]
       [--start SEC] [--length SEC]
       [-w|--width COLS] [--height|-H ROWS] [--no_startup_delay] FILE

Play one audio or video file in the terminal using mpv with the True Color
Terminal video output driver (tct).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --silent             Quiet mpv playback: no status line (e.g. Dropped: N) over
                       the video. Uses mpv --no-terminal and --profile=sw-fast.
                       Recommended for tct over SSH/PuTTY. Default unless
                       VIDEO_PGM_PLAY_SILENT=0 or --no-silent.
  --no-silent          Show mpv progress/status on the terminal (noisier tct).
  --autodetect         Use terminal columns x rows for tct size (default when
                       neither --width nor --height is set).
  --no-autodetect      Do not read terminal size; mpv picks tct size itself (no
                       countdown).
  --countdown SEC      Seconds to wait after showing autodetected size (default
                       3). Only with autodetect.
  --no-countdown       Start playback immediately after autodetect info.
  --start SEC          Start playback at this position in the file (seconds; mpv
                       --start=). Use with --length for a short clip.
  --length SEC         Stop after this many seconds of playback (mpv --length=).
  -w, --width COLS     tct output width in terminal character cells (mpv
                       --vo-tct-width). With --height omitted, height is
                       computed from the video aspect ratio.
  --height ROWS        tct output height in terminal character rows (mpv
                       --vo-tct-height). With --width omitted, width is computed
                       from the video aspect ratio.
  -H ROWS              Short form of --height (-h is reserved for --help).
  --no_startup_delay   Skip random startup delay when run non-interactively
                       (see _script_header.sh).

Arguments:
  FILE                 Path to the media file to play (required). Use -- before
                       FILE when the name starts with '-'.

Environment:
  MPV_BIN              mpv executable (default: mpv from PATH).
  VIDEO_PGM_PLAY_SILENT
                       1 / yes (default): same as --silent.
                       0 / no: same as --no-silent.
  VIDEO_PGM_PLAY_WIDTH   Same as --width (terminal columns).
  VIDEO_PGM_PLAY_HEIGHT  Same as --height (terminal rows).
  VIDEO_PGM_PLAY_AUTODETECT
                       1 / yes (default when size unset): autodetect terminal.
                       0 / no: same as --no-autodetect.
  VIDEO_PGM_PLAY_COUNTDOWN
                       Countdown seconds before playback with autodetect
                       (default: 3).
  VIDEO_PGM_PLAY_START   Same as --start (seconds).
  VIDEO_PGM_PLAY_LENGTH  Same as --length (seconds).

Examples:
  $(basename "$0") clip.mp4
  $(basename "$0") --start 495 --length 9 clip.mp4
  $(basename "$0") --countdown 5 clip.mp4
  $(basename "$0") -w 80 clip.mp4
  $(basename "$0") --height 24 clip.mp4
  $(basename "$0") -w 120 -H 30 clip.mp4
  $(basename "$0") --no-autodetect clip.mp4
  $(basename "$0") -- -odd-name.mkv
EOF
}

video_pgm_positive_int() {
  [[ "${1:-}" =~ ^[1-9][0-9]*$ ]]
}

video_pgm_invalid_dimension() {
  echo "ERROR: invalid $1: ${2:-<empty>} (use a positive integer)" >&2
  exit 1
}

video_pgm_valid_seconds() {
  [[ "${1:-}" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

video_pgm_invalid_seconds() {
  echo "ERROR: invalid $1: ${2:-<empty>} (use 0 or a non-negative number)" >&2
  exit 1
}

# Print video width and height in pixels (first video stream), or fail.
video_pgm_probe_video_dimensions() {
  local file="$1" wh vw vh

  wh="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
    -of csv=p=0:s=x -- "$file" 2>/dev/null)" || return 1
  vw="${wh%x*}"
  vh="${wh#*x}"
  [[ -n "$vw" && -n "$vh" && "$vw" =~ ^[0-9]+$ && "$vh" =~ ^[0-9]+$ && "$vw" -gt 0 && "$vh" -gt 0 ]] || return 1
  printf '%s %s\n' "$vw" "$vh"
}

# Fill missing TCT_WIDTH or TCT_HEIGHT from the other and video aspect ratio.
# tct half-blocks use two pixel rows per terminal row.
video_pgm_resolve_tct_dimensions() {
  local vw vh

  if [[ -z "$TCT_WIDTH" && -z "$TCT_HEIGHT" ]]; then
    return 0
  fi
  if [[ -n "$TCT_WIDTH" && -n "$TCT_HEIGHT" ]]; then
    return 0
  fi

  check_if_installed ffprobe || true
  if ! command -v ffprobe >/dev/null 2>&1; then
    echo "ERROR: ffprobe is required to compute the missing tct dimension." >&2
    echo "Install ffmpeg/ffprobe, or pass both --width and --height." >&2
    return_code=1
    exit 1
  fi

  read -r vw vh < <(video_pgm_probe_video_dimensions "$MEDIA_FILE") || {
    echo "ERROR: could not read video dimensions from: $MEDIA_FILE" >&2
    echo "Pass both --width and --height for audio-only files." >&2
    return_code=1
    exit 1
  }

  if [[ -n "$TCT_WIDTH" ]]; then
    TCT_HEIGHT=$(( (TCT_WIDTH * vh + vw) / (2 * vw) ))
    (( TCT_HEIGHT < 1 )) && TCT_HEIGHT=1
  else
    TCT_WIDTH=$(( (2 * TCT_HEIGHT * vw + vh) / vh ))
    (( TCT_WIDTH < 1 )) && TCT_WIDTH=1
  fi
}

# Read terminal size in character cells (columns x rows).
video_pgm_detect_terminal_dimensions() {
  local cols="" lines=""

  if [[ -r /dev/tty ]] 2>/dev/null; then
    cols="$(tput cols </dev/tty 2>/dev/null || true)"
    lines="$(tput lines </dev/tty 2>/dev/null || true)"
  fi
  [[ -z "$cols" ]] && cols="$(tput cols 2>/dev/null || true)"
  [[ -z "$lines" ]] && lines="$(tput lines 2>/dev/null || true)"
  [[ -z "$cols" || ! "$cols" =~ ^[0-9]+$ || "$cols" -lt 1 ]] && cols="${COLUMNS:-80}"
  [[ -z "$lines" || ! "$lines" =~ ^[0-9]+$ || "$lines" -lt 1 ]] && lines="${LINES:-25}"

  TCT_WIDTH="$cols"
  TCT_HEIGHT="$lines"
}

video_pgm_print_autodetect_info() {
  echo
  echo "Terminal autodetect:"
  echo "  columns (width):  ${TCT_WIDTH}"
  echo "  rows (height):    ${TCT_HEIGHT}"
  echo "  tct playback:     ${TCT_WIDTH} x ${TCT_HEIGHT} terminal cells"
  echo
}

video_pgm_playback_countdown() {
  local sec="${1:-3}" i

  (( sec > 0 )) || return 0
  for (( i = sec; i >= 1; i-- )); do
    echo "Starting playback in ${i}..."
    sleep 1
  done
  echo
}

video_pgm_print_command_line() {
  echo "Playing: $MEDIA_FILE"
  echo "mpv: ${mpv_resolved}"
  [[ -n "$mpv_version_line" ]] && echo "  ${mpv_version_line}"
  if [[ -n "$TCT_WIDTH" || -n "$TCT_HEIGHT" ]]; then
    echo "tct size: ${TCT_WIDTH:-auto} x ${TCT_HEIGHT:-auto} (terminal cells)"
  fi
  if [[ -n "$PLAY_START" ]]; then
    echo "start:  ${PLAY_START} s"
  fi
  if [[ -n "$PLAY_LENGTH" ]]; then
    echo "length: ${PLAY_LENGTH} s"
  fi
  echo -n "Command: $MPV_BIN"
  for arg in "${MPV_ARGS[@]}"; do
    printf ' %q' "$arg"
  done
  printf ' -- %q\n' "$MEDIA_FILE"
  echo
}

# --- parse options before sourcing the header (avoids figlet/delay on --help/--version) ---
HEADER_EXTRA_ARGS=()
MEDIA_FILE=""
PLAY_SILENT="${VIDEO_PGM_PLAY_SILENT:-1}"
TCT_WIDTH="${VIDEO_PGM_PLAY_WIDTH:-}"
TCT_HEIGHT="${VIDEO_PGM_PLAY_HEIGHT:-}"
TCT_AUTODETECT="${VIDEO_PGM_PLAY_AUTODETECT:-}"
PLAY_COUNTDOWN="${VIDEO_PGM_PLAY_COUNTDOWN:-3}"
PLAY_START="${VIDEO_PGM_PLAY_START:-}"
PLAY_LENGTH="${VIDEO_PGM_PLAY_LENGTH:-}"
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
    --autodetect)
      TCT_AUTODETECT=1
      shift
      ;;
    --no-autodetect)
      TCT_AUTODETECT=0
      shift
      ;;
    --countdown)
      [[ $# -ge 2 ]] || { echo "ERROR: missing value for --countdown" >&2; exit 1; }
      [[ "$2" =~ ^[0-9]+$ ]] || { echo "ERROR: invalid --countdown: $2 (use 0 or a positive integer)" >&2; exit 1; }
      PLAY_COUNTDOWN="$2"
      shift 2
      ;;
    --no-countdown)
      PLAY_COUNTDOWN=0
      shift
      ;;
    --start)
      [[ $# -ge 2 ]] || video_pgm_invalid_seconds "start" ""
      video_pgm_valid_seconds "$2" || video_pgm_invalid_seconds "start" "$2"
      PLAY_START="$2"
      shift 2
      ;;
    --start=*)
      PLAY_START="${1#*=}"
      video_pgm_valid_seconds "$PLAY_START" || video_pgm_invalid_seconds "start" "$PLAY_START"
      shift
      ;;
    --length)
      [[ $# -ge 2 ]] || video_pgm_invalid_seconds "length" ""
      video_pgm_valid_seconds "$2" || video_pgm_invalid_seconds "length" "$2"
      PLAY_LENGTH="$2"
      shift 2
      ;;
    --length=*)
      PLAY_LENGTH="${1#*=}"
      video_pgm_valid_seconds "$PLAY_LENGTH" || video_pgm_invalid_seconds "length" "$PLAY_LENGTH"
      shift
      ;;
    -w|--width)
      [[ $# -ge 2 ]] || video_pgm_invalid_dimension "width" ""
      video_pgm_positive_int "$2" || video_pgm_invalid_dimension "width" "$2"
      TCT_WIDTH="$2"
      shift 2
      ;;
    --height)
      [[ $# -ge 2 ]] || video_pgm_invalid_dimension "height" ""
      video_pgm_positive_int "$2" || video_pgm_invalid_dimension "height" "$2"
      TCT_HEIGHT="$2"
      shift 2
      ;;
    -H)
      [[ $# -ge 2 ]] || video_pgm_invalid_dimension "height" ""
      video_pgm_positive_int "$2" || video_pgm_invalid_dimension "height" "$2"
      TCT_HEIGHT="$2"
      shift 2
      ;;
    --silent)
      PLAY_SILENT=1
      shift
      ;;
    --no-silent)
      PLAY_SILENT=0
      shift
      ;;
    --no_startup_delay)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    --)
      shift
      [[ $# -eq 1 ]] || {
        echo "ERROR: expected exactly one FILE after --" >&2
        exit 1
      }
      MEDIA_FILE="$1"
      shift
      break
      ;;
    -*)
      echo "Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
    *)
      if [[ -n "$MEDIA_FILE" ]]; then
        echo "ERROR: expected exactly one FILE (got extra argument: $1)" >&2
        echo "Try: $(basename "$0") --help" >&2
        exit 1
      fi
      MEDIA_FILE="$1"
      shift
      ;;
  esac
done

if [[ -z "$MEDIA_FILE" ]]; then
  echo "ERROR: missing FILE argument." >&2
  echo "Try: $(basename "$0") --help" >&2
  exit 1
fi

if [[ $# -gt 0 ]]; then
  echo "ERROR: unexpected extra argument(s): $*" >&2
  echo "Try: $(basename "$0") --help" >&2
  exit 1
fi

case "${PLAY_SILENT,,}" in
  1|yes|true|y) PLAY_SILENT=1 ;;
  0|no|false|n) PLAY_SILENT=0 ;;
  *)
    echo "ERROR: invalid VIDEO_PGM_PLAY_SILENT: ${VIDEO_PGM_PLAY_SILENT}" >&2
    exit 1
    ;;
esac

if [[ -z "$TCT_WIDTH" && -z "$TCT_HEIGHT" ]]; then
  case "${TCT_AUTODETECT,,}" in
    ''|1|yes|true|y|auto) TCT_AUTODETECT=1 ;;
    0|no|false|n) TCT_AUTODETECT=0 ;;
    *)
      echo "ERROR: invalid VIDEO_PGM_PLAY_AUTODETECT: ${VIDEO_PGM_PLAY_AUTODETECT}" >&2
      exit 1
      ;;
  esac
else
  TCT_AUTODETECT=0
fi

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

if [[ -f "${BASH_SOURCE[0]}" ]]; then
  chmod 700 "${BASH_SOURCE[0]}" 2>/dev/null || true
fi

check_if_installed mpv

MPV_BIN="${MPV_BIN:-mpv}"
if ! command -v "$MPV_BIN" >/dev/null 2>&1; then
  echo "ERROR: mpv is required but was not found (MPV_BIN=${MPV_BIN})." >&2
  echo "Try: apt install mpv   or set MPV_BIN=/path/to/mpv" >&2
  return_code=1
  exit 1
fi

if [[ ! -e "$MEDIA_FILE" ]]; then
  echo "ERROR: file not found: $MEDIA_FILE" >&2
  return_code=1
  exit 1
fi

if [[ ! -f "$MEDIA_FILE" ]]; then
  echo "ERROR: not a regular file: $MEDIA_FILE" >&2
  return_code=1
  exit 1
fi

if [[ ! -r "$MEDIA_FILE" ]]; then
  echo "ERROR: file is not readable: $MEDIA_FILE" >&2
  return_code=1
  exit 1
fi

MEDIA_FILE="$(realpath "$MEDIA_FILE" 2>/dev/null || echo "$MEDIA_FILE")"

if (( TCT_AUTODETECT )); then
  video_pgm_detect_terminal_dimensions
  video_pgm_print_autodetect_info
else
  video_pgm_resolve_tct_dimensions
fi

mpv_resolved="$(command -v "$MPV_BIN")"
mpv_resolved="$(readlink -f "$mpv_resolved" 2>/dev/null || echo "$mpv_resolved")"
mpv_version_line="$("$MPV_BIN" --version 2>/dev/null | head -n1)"

declare -a MPV_ARGS=( --vo=tct )
if (( PLAY_SILENT )); then
  MPV_ARGS+=( --no-terminal --profile=sw-fast )
fi
if [[ -n "$TCT_WIDTH" ]]; then
  MPV_ARGS+=( --vo-tct-width="$TCT_WIDTH" )
fi
if [[ -n "$TCT_HEIGHT" ]]; then
  MPV_ARGS+=( --vo-tct-height="$TCT_HEIGHT" )
fi
if [[ -n "$PLAY_START" ]]; then
  MPV_ARGS+=( --start="$PLAY_START" )
fi
if [[ -n "$PLAY_LENGTH" ]]; then
  MPV_ARGS+=( --length="$PLAY_LENGTH" )
fi

video_pgm_print_command_line

if (( TCT_AUTODETECT )); then
  video_pgm_playback_countdown "$PLAY_COUNTDOWN"
fi

"$MPV_BIN" "${MPV_ARGS[@]}" -- "$MEDIA_FILE"
return_code=$?

. /root/bin/_script_footer.sh
exit "$return_code"
