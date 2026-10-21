#!/bin/bash
# v. 20261021.140100 - note: python helper 0.2 drops whole teleport clusters
# v. 20261021.135400 - clean noisy GPX tracks via gpx_clean.py (spikes + stationary jitter)

# 2026.10.21 - v. 0.2 - companion gpx_clean.py 0.2: jump filter removes multi-point teleports
# 2026.10.21 - v. 0.1 - initial release: check python3 (ask apt-get install when interactive),
#                        convert Windows paths, pass options through to gpx_clean.py beside this file
#
# gpx_clean.sh
#
# Clean a noisy GPX track: drop impossible speed spikes, collapse stationary
# GPS jitter, optional short coordinate smooth. The original file is left
# alone; the default output is INPUT_cleaned.gpx beside it.
# Processing is done by gpx_clean.py next to this script.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-n|--dry-run] [-o FILE]
       [--max-jump KMH] [--stop-kmh KMH] [--stop-radius M] [--smooth S]
       FILE.gpx

Clean a noisy GPX track (speed spikes and stationary spiderweb jitter).
Writes FILE_cleaned.gpx by default (or -o FILE). The input is not changed.
Windows paths such as O:\\video\\track.gpx are read as /mnt/o/video/track.gpx
when that mount exists.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask before writing (still asks before apt install
                       unless there is no terminal; then it only prints the command).
  -n, --dry-run        Print the plan and stats; write nothing.
  -o, --output FILE    Output .gpx path (default: INPUT_cleaned.gpx).
  --max-jump KMH       Drop single points faster than this (default 200; 0 keeps all).
  --stop-kmh KMH       Collapse slower movement as stopped jitter (default 3; <0 off).
  --stop-radius M      Max radius of a stop cluster in metres (default 25).
  --smooth S           Seconds of coordinate smooth after cleaning (default 2; 0 off).

Needs: python3. When it is missing the script lists it and asks whether to
install it with apt-get (with sudo when not root). With -y or without a
terminal it only prints the install command.
The helper gpx_clean.py has its own -h, -v, and --history.

Examples:
  $(basename "$0") track.gpx
  $(basename "$0") -n --max-jump 180 'O:\\video\\trip\\track.gpx'
  $(basename "$0") -y -o clean.gpx --smooth 3 track.gpx
EOF
}

gc_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

gc_colors() {
  C_B="" C_DIM="" C_G="" C_Y="" C_R="" C_C="" C_0=""
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_B=$'\e[1m'
    C_DIM=$'\e[2m'
    C_G=$'\e[32m'
    C_Y=$'\e[33m'
    C_R=$'\e[31m'
    C_C=$'\e[36m'
    C_0=$'\e[0m'
  fi
}

gc_rule() {
  local ch="${1:-─}" width="${2:-78}"
  printf '%*s' "$width" '' | sed "s/ /${ch}/g"
}

gc_heading() {
  local title="$1" width=78 rest
  rest=$(( width - ${#title} - 4 ))
  (( rest < 3 )) && rest=3
  echo
  printf '%s══ %s %s%s\n' "$C_B$C_C" "$title" "$(gc_rule '═' "$rest")" "$C_0"
}

gc_quote_args() {
  local part out="" sq="'" esc="'\\''"
  for part in "$@"; do
    if [[ ! "$part" =~ ^[A-Za-z0-9_./:=+,@%-]+$ ]]; then
      part="${sq}${part//${sq}/${esc}}${sq}"
    fi
    out+="${out:+ }${part}"
  done
  printf '%s\n' "$out"
}

gc_unix_path() {
  local p="$1" re='^([A-Za-z]):[\\/](.*)$' drive rest
  if [[ "$p" =~ $re ]]; then
    drive="${BASH_REMATCH[1],,}"
    rest="${BASH_REMATCH[2]//\\//}"
    if [[ -d "/mnt/${drive}" ]]; then
      printf '/mnt/%s/%s\n' "$drive" "$rest"
      return 0
    fi
  fi
  printf '%s\n' "$p"
}

gc_read_key() {
  local prompt="$1" default_key="${2:-}" answer="" discard
  printf '%s' "$prompt"
  while IFS= read -r -t 0.02 -n 1 discard; do :; done
  read -r -n 1 answer || answer=""
  echo
  answer="${answer,,}"
  REPLY="${answer:-$default_key}"
}

gc_missing_prereqs() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3|Python 3: cleans the GPX track (gpx_clean.py)"
  fi
  return 0
}

gc_check_prereqs() {
  local line rc=0
  local -a missing=() pkgs=() cmd=()
  mapfile -t missing < <(gc_missing_prereqs)
  (( ${#missing[@]} == 0 )) && return 0
  for line in "${missing[@]}"; do
    pkgs+=("${line%%|*}")
  done
  cmd=(apt-get install -y "${pkgs[@]}")
  (( EUID != 0 )) && cmd=(sudo "${cmd[@]}")
  gc_heading "Missing programs"
  echo "  This script needs these, and they are not installed:"
  for line in "${missing[@]}"; do
    printf '  %-12s %s\n' "${line%%|*}" "${line#*|}"
  done
  echo "  Install command: $(gc_quote_args "${cmd[@]}")"
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "$(gc_ts) ${C_R}apt-get is not available here; install them with this system's package manager.${C_0}" >&2
    exit 1
  fi
  if (( EUID != 0 )) && ! command -v sudo >/dev/null 2>&1; then
    echo "$(gc_ts) ${C_R}Not root and no sudo: run the install command as root, then start this script again.${C_0}" >&2
    exit 1
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    echo "$(gc_ts) ${C_Y}Nothing is installed without asking. Run the install command, or start this script in a terminal without -y.${C_0}" >&2
    exit 1
  fi
  echo
  printf '%sInstall them now? [Y/n/q]%s\n' "$C_B" "$C_0"
  echo "  [Y] Yes, install with the command above, then continue (default)"
  echo "  [n] No, stop here"
  echo "  [q] Quit the script"
  gc_read_key "Install them now? [Y/n/q]: " y
  case "$REPLY" in
    y) ;;
    *) echo "$(gc_ts) Nothing installed."; exit 1 ;;
  esac
  "${cmd[@]}" || rc=$?
  if (( rc != 0 )); then
    echo "$(gc_ts) Install failed; refreshing the package lists and trying again."
    if (( EUID != 0 )); then
      sudo apt-get update || true
    else
      apt-get update || true
    fi
    rc=0
    "${cmd[@]}" || rc=$?
  fi
  mapfile -t missing < <(gc_missing_prereqs)
  if (( rc != 0 || ${#missing[@]} > 0 )); then
    echo "$(gc_ts) ${C_R}Still missing after the install.${C_0}" >&2
    exit 1
  fi
  echo "$(gc_ts) ${C_G}Installed.${C_0} Continuing."
}

gc_default_out() {
  local inp="$1" base ext
  base="${inp%.*}"
  ext="${inp##*.}"
  if [[ "${ext,,}" == gpx ]]; then
    printf '%s_cleaned.gpx\n' "$base"
  else
    printf '%s_cleaned.gpx\n' "$inp"
  fi
}

gc_on_exit() {
  if [[ -r "${profile_location_dir:-$HOME}/bin/_script_footer.sh" ]]; then
    # shellcheck disable=SC1091
    . "${profile_location_dir:-$HOME}/bin/_script_footer.sh"
  fi
}

gc_ctrl_c() {
  echo
  echo "$(gc_ts) Interrupted."
  return_code=130
  exit 130
}

# --- main -------------------------------------------------------------------

DO_YES=0
DRY_RUN=0
OUT_FILE=""
MAX_JUMP=""
STOP_KMH=""
STOP_RADIUS=""
SMOOTH=""
INPUT_RAW=""
return_code=0

SCRIPT_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
PY_HELPER="${SCRIPT_DIR}/gpx_clean.py"
gc_colors

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

# shellcheck disable=SC1091
. "${profile_location_dir:-$HOME}/bin/_script_header.sh" "${HEADER_EXTRA_ARGS[@]}"

trap gc_on_exit EXIT
trap gc_ctrl_c INT

gc_need_value() {
  [[ $# -ge 2 && -n "$2" ]] || { echo "ERROR: missing value for $1" >&2; exit 1; }
}

while [[ $# -gt 0 ]]; do
  opt="$1"
  val=""
  case "$opt" in
    --*=*) val="${opt#*=}"; opt="${opt%%=*}"; set -- "$opt" "$val" "${@:2}" ;;
  esac
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --history) print_script_history; exit 0 ;;
    -y|--yes) DO_YES=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -o|--output)
      gc_need_value "$@"
      OUT_FILE="$2"
      shift 2 ;;
    --max-jump)
      gc_need_value "$@"
      MAX_JUMP="$2"
      shift 2 ;;
    --stop-kmh)
      gc_need_value "$@"
      STOP_KMH="$2"
      shift 2 ;;
    --stop-radius)
      gc_need_value "$@"
      STOP_RADIUS="$2"
      shift 2 ;;
    --smooth)
      gc_need_value "$@"
      SMOOTH="$2"
      shift 2 ;;
    --) shift; break ;;
    -*) echo "ERROR: unknown option: $1 (see --help)" >&2; exit 1 ;;
    *)
      if [[ -n "$INPUT_RAW" ]]; then
        echo "ERROR: only one input .gpx is accepted (see --help)" >&2
        exit 1
      fi
      INPUT_RAW="$1"
      shift ;;
  esac
done

while [[ $# -gt 0 ]]; do
  if [[ -n "$INPUT_RAW" ]]; then
    echo "ERROR: only one input .gpx is accepted (see --help)" >&2
    exit 1
  fi
  INPUT_RAW="$1"
  shift
done

if [[ ! -f "$PY_HELPER" ]]; then
  echo "$(gc_ts) Missing helper: ${PY_HELPER}" >&2
  exit 1
fi

gc_check_prereqs

if [[ -z "$INPUT_RAW" ]]; then
  echo "ERROR: input .gpx is required (see --help)" >&2
  exit 1
fi

INPUT_PATH="$(gc_unix_path "$INPUT_RAW")"
if [[ ! -f "$INPUT_PATH" ]]; then
  echo "ERROR: not a file: ${INPUT_RAW}" >&2
  exit 1
fi

if [[ -n "$OUT_FILE" ]]; then
  OUT_PATH="$(gc_unix_path "$OUT_FILE")"
else
  OUT_PATH="$(gc_default_out "$INPUT_PATH")"
fi

PY_ARGS=( "$PY_HELPER" --output "$OUT_PATH" )
[[ -n "$MAX_JUMP" ]] && PY_ARGS+=( --max-jump "$MAX_JUMP" )
[[ -n "$STOP_KMH" ]] && PY_ARGS+=( --stop-kmh "$STOP_KMH" )
[[ -n "$STOP_RADIUS" ]] && PY_ARGS+=( --stop-radius "$STOP_RADIUS" )
[[ -n "$SMOOTH" ]] && PY_ARGS+=( --smooth "$SMOOTH" )
(( DRY_RUN )) && PY_ARGS+=( --dry-run )
PY_ARGS+=( "$INPUT_PATH" )

gc_heading "Plan"
echo "  Input:  ${INPUT_PATH}"
echo "  Output: ${OUT_PATH}"
echo "  Mode:   $( (( DRY_RUN )) && echo dry-run || echo write )"
[[ -n "$MAX_JUMP" ]] && echo "  max-jump: ${MAX_JUMP} km/h" || echo "  max-jump: 200 km/h (default)"
[[ -n "$STOP_KMH" ]] && echo "  stop-kmh: ${STOP_KMH}" || echo "  stop-kmh: 3 (default)"
[[ -n "$STOP_RADIUS" ]] && echo "  stop-radius: ${STOP_RADIUS} m" || echo "  stop-radius: 25 m (default)"
[[ -n "$SMOOTH" ]] && echo "  smooth: ${SMOOTH} s" || echo "  smooth: 2 s (default)"
echo "  Command: $(gc_quote_args python3 "${PY_ARGS[@]}")"

if (( DRY_RUN )); then
  echo
  python3 "${PY_ARGS[@]}" || return_code=$?
  exit "$return_code"
fi

if (( ! DO_YES )); then
  if (( ! script_is_run_interactively )); then
    echo "$(gc_ts) Not a terminal: nothing written. Add -y to write without asking."
    exit 0
  fi
  echo
  printf '%sWrite the cleaned track now? [Y/n/q]%s\n' "$C_B" "$C_0"
  echo "  [Y] Yes, write ${OUT_PATH} (default)"
  echo "  [n] No, stop here"
  echo "  [q] Quit"
  gc_read_key "Write the cleaned track now? [Y/n/q]: " y
  case "$REPLY" in
    y) ;;
    *) echo "$(gc_ts) Nothing written."; exit 0 ;;
  esac
fi

echo
python3 "${PY_ARGS[@]}" || return_code=$?
if (( return_code == 0 )); then
  echo "$(gc_ts) ${C_G}Done.${C_0} ${OUT_PATH}"
else
  echo "$(gc_ts) ${C_R}Failed.${C_0}" >&2
fi
exit "$return_code"
