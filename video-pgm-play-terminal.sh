#!/bin/bash

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
       [--no_startup_delay] FILE

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

Examples:
  $(basename "$0") clip.mp4
  $(basename "$0") --silent clip.mp4
  $(basename "$0") -- -odd-name.mkv
EOF
}

# --- parse options before sourcing the header (avoids figlet/delay on --help/--version) ---
HEADER_EXTRA_ARGS=()
MEDIA_FILE=""
PLAY_SILENT="${VIDEO_PGM_PLAY_SILENT:-1}"
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

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

if [[ -f "${BASH_SOURCE[0]}" ]]; then
  chmod 700 "${BASH_SOURCE[0]}" 2>/dev/null || true
fi

check_if_installed mpv

MPV_BIN="${MPV_BIN:-mpv}"
if ! command -v "$MPV_BIN" >/dev/null 2>&1; then
  echo "ERROR: mpv is required but was not found (MPV_BIN=${MPV_BIN})." >&2
  echo "Try: apt install mpv   or set MPV_BIN=/path/to/mpv" >&2
  kod_powrotu=1
  exit 1
fi

if [[ ! -e "$MEDIA_FILE" ]]; then
  echo "ERROR: file not found: $MEDIA_FILE" >&2
  kod_powrotu=1
  exit 1
fi

if [[ ! -f "$MEDIA_FILE" ]]; then
  echo "ERROR: not a regular file: $MEDIA_FILE" >&2
  kod_powrotu=1
  exit 1
fi

if [[ ! -r "$MEDIA_FILE" ]]; then
  echo "ERROR: file is not readable: $MEDIA_FILE" >&2
  kod_powrotu=1
  exit 1
fi

MEDIA_FILE="$(realpath "$MEDIA_FILE" 2>/dev/null || echo "$MEDIA_FILE")"

mpv_resolved="$(command -v "$MPV_BIN")"
mpv_resolved="$(readlink -f "$mpv_resolved" 2>/dev/null || echo "$mpv_resolved")"
mpv_version_line="$("$MPV_BIN" --version 2>/dev/null | head -n1)"

declare -a MPV_ARGS=( --vo=tct )
if (( PLAY_SILENT )); then
  MPV_ARGS+=( --no-terminal --profile=sw-fast )
fi

if (( ! PLAY_SILENT )); then
  echo "Playing: $MEDIA_FILE"
  echo "mpv: ${mpv_resolved}"
  [[ -n "$mpv_version_line" ]] && echo "  ${mpv_version_line}"
  echo -n "Command: $MPV_BIN"
  for arg in "${MPV_ARGS[@]}"; do
    printf ' %q' "$arg"
  done
  printf ' -- %q\n' "$MEDIA_FILE"
  echo
fi

"$MPV_BIN" "${MPV_ARGS[@]}" -- "$MEDIA_FILE"
kod_powrotu=$?

. /root/bin/_script_footer.sh
exit "$kod_powrotu"
