#!/bin/bash
# v. 20261006.210617 - GoPro GPS metadata written as a .gpx file beside each video

# 2026.10.06 - v. 0.1 - initial release: find GoPro videos, read the GPS metadata stream (GPS5 and GPS9), write a .gpx with the same name beside the video; the video is not changed; an existing .gpx is skipped or written again, and the old file is kept as _old-YYYYMMDD_HHMMSS or deleted
#
# video-pgm-gopro-to-gpx.sh
#
# Read the GPS track stored inside a GoPro video and save it as a .gpx file
# next to that video. GoPro does not keep a GPX file in the video: the track
# is a metadata stream. ffmpeg copies that stream out, and
# video-pgm-gopro-to-gpx.py turns it into GPX. The video is not changed.
#
# video-pgm-create-map-video-from-gpx.sh finds a .gpx with the same name as
# the video, so a renamed GoPro file can be used for a map afterwards.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-n|--dry-run] [--redo] [--old keep|delete]
       [FILE|DIR ...]

Read the GPS track inside each GoPro video and write a .gpx file beside it:
  GX010123.mp4  ->  GX010123.gpx
The video is not changed. With no FILE or DIR, the current directory is used.
A directory's videos are the .mp4 and .mov files in that directory, not in
folders inside it. Windows paths such as P:\\video\\trip are read as
/mnt/p/video/trip.

The track comes from the GoPro metadata stream in the video (GPS5 on older
cameras, GPS9 on newer ones). A video without that stream is not a GoPro
video, or it was saved without GPS. A video whose GPS never got a fix
produces no .gpx. Times in the file are UTC.

A .gpx that is already there is listed at the start. With -y it is skipped
unless --redo is given; otherwise you choose: skip, or write it again. A
replaced file is kept as ..._old-YYYYMMDD_HHMMSS.gpx (the time the old file
was made), or deleted with --old delete. The old file is only touched after
the new one has been written.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask. Write every track that is not there yet.
  -n, --dry-run        Print the plan; write nothing.
  --redo               Write again where a .gpx is already there.
  --old keep|delete    What happens to that old .gpx. keep (default): renamed
                       to ..._old-YYYYMMDD_HHMMSS.gpx. delete: removed.

Needs: ffmpeg, ffprobe, and python3. When something is missing the script
lists it and asks whether to install it with apt-get (with sudo when not
root). With -y or without a terminal it only prints the install command.
The helper video-pgm-gopro-to-gpx.py has its own -h, -v, and --history.

Examples:
  $(basename "$0")
      Read the current directory, print the plan, ask before writing.
  $(basename "$0") -n /mnt/p/video/gopro
  $(basename "$0") -y --redo --old keep GX010123.mp4
EOF
}

gg_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

gg_colors() {
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

gg_rule() {
  local ch="${1:-─}" width="${2:-78}"
  printf '%*s' "$width" '' | sed "s/ /${ch}/g"
}

gg_heading() {
  local title="$1" width=78 rest
  rest=$(( width - ${#title} - 4 ))
  (( rest < 3 )) && rest=3
  echo
  printf '%s══ %s %s%s\n' "$C_B$C_C" "$title" "$(gg_rule '═' "$rest")" "$C_0"
}

gg_quote_args() {
  local part out="" sq="'" esc="'\\''"
  for part in "$@"; do
    if [[ ! "$part" =~ ^[A-Za-z0-9_./:=+,@%-]+$ ]]; then
      part="${sq}${part//${sq}/${esc}}${sq}"
    fi
    out+="${out:+ }${part}"
  done
  printf '%s\n' "$out"
}

gg_unix_path() {
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

gg_human_size() {
  awk -v b="${1:-0}" 'BEGIN {
    split("B KiB MiB GiB TiB", u, " ")
    i = 1
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    if (i == 1) printf "%d %s", b, u[i]
    else printf "%.1f %s", b, u[i]
  }'
}

gg_file_bytes() {
  local n=0
  [[ -f "$1" ]] && n=$(stat -c %s -- "$1" 2>/dev/null || printf '0')
  [[ "$n" =~ ^[0-9]+$ ]] || n=0
  printf '%s\n' "$n"
}

gg_k() {
  if [[ "$1" == "$2" ]]; then
    printf '%s' "${1^^}"
  else
    printf '%s' "$1"
  fi
}

gg_keys() {
  local def="$1" k out=""
  shift
  for k in "$@"; do
    out+="${out:+/}$(gg_k "$k" "$def")"
  done
  printf '%s' "$out"
}

gg_cur_mark() {
  [[ "$1" == "$2" ]] && printf ' (current, default)'
  return 0
}

gg_read_key() {
  local prompt="$1" default_key="${2:-}" answer="" discard
  printf '%s' "$prompt"
  while IFS= read -r -t 0.02 -n 1 discard; do :; done
  read -r -n 1 answer || answer=""
  echo
  answer="${answer,,}"
  REPLY="${answer:-$default_key}"
}

gg_quit() {
  echo "$(gg_ts) Quit. Nothing more was written."
  STOPPED=yes
  return_code=0
  exit 0
}

gg_skip_name() {
  local base="${1##*/}"
  [[ "$base" == *_old-* || "$base" == *.partial.* || "$base" == *.partial ]]
}

gg_is_video() {
  local base="${1##*/}"
  [[ "$base" =~ \.[mM][pP]4$ || "$base" =~ \.[mM][oO][vV]$ ]]
}

gg_add_file() {
  local f="$1" explicit="${2:-0}"
  [[ -f "$f" ]] || return 0
  if ! gg_is_video "$f"; then
    if (( explicit )); then
      echo "$(gg_ts) ${C_Y}Not an .mp4 or .mov file, ignored:${C_0} $f" >&2
    fi
    return 0
  fi
  if gg_skip_name "$f"; then
    return 0
  fi
  V_PATH+=("$f")
  V_EXPLICIT+=("$explicit")
}

gg_add_directory() {
  local dir="${1%/}" f
  local -a found=()
  [[ -n "$dir" ]] || dir="/"
  shopt -s nullglob nocaseglob
  found=( "$dir"/*.mp4 "$dir"/*.mov )
  shopt -u nullglob nocaseglob
  (( ${#found[@]} == 0 )) && return 0
  mapfile -t found < <(printf '%s\n' "${found[@]}" | LC_ALL=C sort -u)
  for f in "${found[@]}"; do
    [[ -n "$f" ]] && gg_add_file "$f" 0
  done
}

gg_gpx_path() {
  local f="$1" base
  base="$(basename -- "$f")"
  printf '%s/%s.gpx\n' "$(dirname -- "$f")" "${base%.*}"
}

gg_old_name() {
  local out="$1" stamp cand n=2
  stamp="$(date -r "$out" '+%Y%m%d_%H%M%S' 2>/dev/null || date '+%Y%m%d_%H%M%S')"
  cand="${out%.gpx}_old-${stamp}.gpx"
  while [[ -e "$cand" ]]; do
    cand="${out%.gpx}_old-${stamp}-${n}.gpx"
    (( n++ ))
  done
  printf '%s\n' "$cand"
}

gg_existing_info() {
  printf '%s, made %s' "$(gg_human_size "$(gg_file_bytes "$1")")" \
    "$(date -r "$1" '+%Y.%m.%d %H:%M' 2>/dev/null || echo '?')"
}

gg_retire_old() {
  local out="$1" old
  [[ -e "$out" ]] || return 0
  if [[ "$OLD_MODE" == delete ]]; then
    rm -f -- "$out" || return 1
    echo "$(gg_ts) Old file deleted: ${out}"
  else
    old="$(gg_old_name "$out")"
    mv -- "$out" "$old" || return 1
    echo "$(gg_ts) Old file kept as: ${old}"
  fi
}

gg_missing_prereqs() {
  if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
    echo "ffmpeg|ffmpeg and ffprobe: copy the GoPro GPS stream out of the video"
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3|Python 3: turns that stream into a GPX file"
  fi
  return 0
}

gg_check_prereqs() {
  local line rc=0
  local -a missing=() pkgs=() cmd=()
  mapfile -t missing < <(gg_missing_prereqs)
  (( ${#missing[@]} == 0 )) && return 0
  for line in "${missing[@]}"; do
    pkgs+=("${line%%|*}")
  done
  cmd=(apt-get install -y "${pkgs[@]}")
  (( EUID != 0 )) && cmd=(sudo "${cmd[@]}")
  gg_heading "Missing programs"
  echo "  This script needs these, and they are not installed:"
  for line in "${missing[@]}"; do
    printf '  %-12s %s\n' "${line%%|*}" "${line#*|}"
  done
  echo "  Install command: $(gg_quote_args "${cmd[@]}")"
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "$(gg_ts) ${C_R}apt-get is not available here; install them with this system's package manager.${C_0}" >&2
    exit 1
  fi
  if (( EUID != 0 )) && ! command -v sudo >/dev/null 2>&1; then
    echo "$(gg_ts) ${C_R}Not root and no sudo: run the install command as root, then start this script again.${C_0}" >&2
    exit 1
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    echo "$(gg_ts) ${C_Y}Nothing is installed without asking. Run the install command, or start this script in a terminal without -y.${C_0}" >&2
    exit 1
  fi
  echo
  printf '%sInstall them now? [Y/n/q]%s\n' "$C_B" "$C_0"
  echo "  [Y] Yes, install with the command above, then continue (default)"
  echo "  [n] No, stop here"
  echo "  [q] Quit the script"
  gg_read_key "Install them now? [Y/n/q]: " y
  case "$REPLY" in
    y) ;;
    *) echo "$(gg_ts) Nothing installed."; exit 1 ;;
  esac
  "${cmd[@]}" || rc=$?
  if (( rc != 0 )); then
    echo "$(gg_ts) Install failed; refreshing the package lists and trying again."
    if (( EUID != 0 )); then
      sudo apt-get update || true
    else
      apt-get update || true
    fi
    rc=0
    "${cmd[@]}" || rc=$?
  fi
  mapfile -t missing < <(gg_missing_prereqs)
  if (( rc != 0 || ${#missing[@]} > 0 )); then
    echo "$(gg_ts) ${C_R}Still missing after the install.${C_0}" >&2
    exit 1
  fi
  echo "$(gg_ts) ${C_G}Installed.${C_0} Continuing."
}

gg_utc_label() {
  local t="${1%.???Z}"
  t="${t%Z}"
  printf '%s.%s.%s %s' "${t:0:4}" "${t:5:2}" "${t:8:2}" "${t:11:8}"
}

gg_track_label() {
  local rest="$1" points first last kind
  points="${rest#points=}"
  points="${points%% *}"
  first="${rest#*first=}"
  first="${first%% *}"
  last="${rest#*last=}"
  last="${last%% *}"
  kind="${rest##*kind=}"
  printf '%s points, %s to %s UTC, %s' "$points" "$(gg_utc_label "$first")" "$(gg_utc_label "$last")" "$kind"
}

gg_probe() {
  local i n=${#V_PATH[@]} line status rest
  (( n == 0 )) && return 0
  printf '%s Reading %d video(s)...' "$(gg_ts)" "$n"
  for i in "${!V_PATH[@]}"; do
    V_OUT[$i]="$(gg_gpx_path "${V_PATH[$i]}")"
    line="$(python3 "$PY_HELPER" info -- "${V_PATH[$i]}" 2>/dev/null || true)"
    status="${line%% *}"
    rest="${line#* }"
    case "$status" in
      ok)
        V_KIND[$i]="${rest##*kind=}"
        V_INFO[$i]="$(gg_track_label "$rest")"
        if [[ -e "${V_OUT[$i]}" ]]; then
          if (( REDO )); then
            V_STATE[$i]=redo
          else
            V_STATE[$i]=exists
          fi
        else
          V_STATE[$i]=write
        fi
        ;;
      none)
        V_STATE[$i]=nogps
        V_KIND[$i]=""
        V_INFO[$i]="GoPro video, but the GPS never got a fix"
        ;;
      nogopro)
        V_STATE[$i]=nogopro
        V_KIND[$i]=""
        V_INFO[$i]="no GoPro GPS stream"
        ;;
      *)
        V_STATE[$i]=bad
        V_KIND[$i]=""
        V_INFO[$i]="${line#error }"
        [[ -n "${V_INFO[$i]}" ]] || V_INFO[$i]="could not read the video"
        ;;
    esac
  done
  echo " done."
}

gg_equivalent_command() {
  local -a cmd=("$(basename "$0")" -y)
  (( REDO )) && cmd+=(--redo)
  (( REDO )) && [[ "$OLD_MODE" == delete ]] && cmd+=(--old delete)
  cmd+=(--)
  if (( ${#INPUT_ARGS[@]} > 0 )); then
    cmd+=("${INPUT_ARGS[@]}")
  else
    cmd+=("$(pwd -P)")
  fi
  gg_quote_args "${cmd[@]}"
}

gg_print_plan() {
  local i n=0 other=0 exists=0
  TO_WRITE=0
  EXISTING=0
  gg_heading "GoPro videos"
  for i in "${!V_PATH[@]}"; do
    case "${V_STATE[$i]}" in
      write|exists|redo)
        (( n++ )) || true
        printf '  %s%s%s\n' "$C_B" "$(basename -- "${V_PATH[$i]}")" "$C_0"
        printf '    %s%s%s\n' "$C_DIM" "${V_INFO[$i]}" "$C_0"
        if [[ "${V_STATE[$i]}" == write ]]; then
          printf '    %swrite %s%s\n' "$C_G" "$(basename -- "${V_OUT[$i]}")" "$C_0"
          (( TO_WRITE++ )) || true
        elif [[ "${V_STATE[$i]}" == redo ]]; then
          printf '    %swrite again %s%s\n' "$C_Y" "$(basename -- "${V_OUT[$i]}")" "$C_0"
          printf '    %s%s%s\n' "$C_Y" "$(gg_existing_info "${V_OUT[$i]}")" "$C_0"
          (( TO_WRITE++ )) || true
          (( EXISTING++ )) || true
        else
          printf '    %sexists %s (%s), skipped unless you choose to write it again%s\n' \
            "$C_Y" "$(basename -- "${V_OUT[$i]}")" "$(gg_existing_info "${V_OUT[$i]}")" "$C_0"
          (( EXISTING++ )) || true
          (( exists++ )) || true
        fi
        ;;
      nogopro)
        (( V_EXPLICIT[i] == 0 )) && (( other++ )) || true
        ;;
    esac
  done
  if (( n == 0 )); then
    echo "  None."
  fi
  if (( other > 0 )); then
    echo
    printf '  %d other video(s) in the folder have no GoPro GPS stream.\n' "$other"
  fi
  local shown=0
  for i in "${!V_PATH[@]}"; do
    case "${V_STATE[$i]}" in
      nogps|bad) ;;
      nogopro) (( V_EXPLICIT[i] == 1 )) || continue ;;
      *) continue ;;
    esac
    if (( shown == 0 )); then
      gg_heading "Not used"
    fi
    shown=1
    printf '  %s%s%s\n' "$C_Y" "$(basename -- "${V_PATH[$i]}")" "$C_0"
    printf '    %s\n' "${V_INFO[$i]}"
  done
  gg_heading "Settings"
  printf '  %-14s %s\n' "Output" "same name, .gpx, beside the video"
  if (( REDO && EXISTING > 0 )); then
    if [[ "$OLD_MODE" == delete ]]; then
      printf '  %-14s %s\n' "Old .gpx" "deleted after the new one is written"
    else
      printf '  %-14s %s\n' "Old .gpx" "kept as ..._old-YYYYMMDD_HHMMSS.gpx"
    fi
  fi
  printf '  %-14s %s\n' "Command" "$(gg_equivalent_command)"
  echo
  printf '%s%d GoPro video(s) with a track, %d to write%s' "$C_B" "$n" "$TO_WRITE" "$C_0"
  (( exists > 0 )) && printf ', %d already written (skipped for now)' "$exists"
  echo
}

gg_prompt_old() {
  local key=k
  (( OLD_ASKED )) && return 0
  OLD_ASKED=1
  [[ "$OLD_MODE" == delete ]] && key=d
  echo
  echo "What should happen to the old .gpx when the new one is written? [$(gg_keys "$key" k d q)]"
  echo "  The new file is written beside it first. The old file is only touched after that succeeds."
  echo "  [$(gg_k k "$key")] Keep it, renamed with the date and time it was made$(gg_cur_mark k "$key")"
  echo "      For example ..._old-20261006_210000.gpx beside the new file."
  echo "  [$(gg_k d "$key")] Delete it$(gg_cur_mark d "$key")"
  echo "  [q] Quit the script, write nothing more"
  gg_read_key "Old file [$(gg_keys "$key" k d q)]: " "$key"
  case "$REPLY" in
    k) OLD_MODE=keep ;;
    d) OLD_MODE=delete ;;
    q) gg_quit ;;
    *) echo "$(gg_ts) Unknown choice: ${REPLY}. Keeping old files."; OLD_MODE=keep ;;
  esac
}

gg_prompt_existing() {
  local skip=0 i
  for i in "${!V_PATH[@]}"; do
    [[ "${V_STATE[$i]}" == exists ]] && (( skip++ )) || true
  done
  (( skip == 0 )) && return 0
  echo
  printf '%s%d video(s) already have a .gpx. What should happen to them? [S/r/q]%s\n' "$C_B" "$skip" "$C_0"
  echo "  [S] Skip them, keep the old files as they are (default)"
  echo "  [r] Write them again too"
  echo "      What happens to each old file is asked next."
  echo "  [q] Quit the script, write nothing"
  gg_read_key "Already written [S/r/q]: " s
  case "$REPLY" in
    s) ;;
    r)
      REDO=1
      for i in "${!V_PATH[@]}"; do
        [[ "${V_STATE[$i]}" == exists ]] && V_STATE[$i]=redo
      done
      gg_prompt_old
      ;;
    q) gg_quit ;;
    *) echo "$(gg_ts) Unknown choice: ${REPLY}. Skipping them." ;;
  esac
}

gg_prompt_plan() {
  echo
  printf '%sWrite the tracks now? [Y/n/q]%s\n' "$C_B" "$C_0"
  echo "  [Y] Write the ${TO_WRITE} track(s) marked above (default)"
  (( EXISTING > 0 && ! REDO )) && echo "      Then you are asked about the ${EXISTING} .gpx file(s) that are already there."
  echo "  [n] No, write nothing"
  echo "  [q] Quit the script"
  gg_read_key "Write the tracks now? [Y/n/q]: " y
  case "$REPLY" in
    y)
      if (( REDO )); then
        (( EXISTING > 0 )) && gg_prompt_old
      else
        gg_prompt_existing
      fi
      ;;
    *) gg_quit ;;
  esac
}

gg_write_one() {
  local i="$1" out="${V_OUT[$1]}" partial line rc=0
  partial="${out}.partial.$$"
  gg_heading "Writing $(basename -- "$out")"
  echo "$(gg_ts) $(basename -- "${V_PATH[$i]}")"
  if ! line="$(python3 "$PY_HELPER" write -- "${V_PATH[$i]}" "$partial")"; then
    rc=$?
    rm -f -- "$partial"
    echo "$(gg_ts) ${C_R}Could not write the track (${line:-python failed}).${C_0}" >&2
    FAILED_LIST+=("${out} (${line:-python failed})")
    return 1
  fi
  if ! gg_retire_old "$out"; then
    echo "$(gg_ts) ${C_R}Could not move the old file aside. The new track is left as ${partial}${C_0}" >&2
    FAILED_LIST+=("${out} (old file not moved)")
    return 1
  fi
  if mv -f -- "$partial" "$out"; then
    echo "$(gg_ts) ${C_G}Wrote${C_0} ${out}"
    echo "    ${line}"
    DONE_LIST+=("$out")
    return 0
  fi
  echo "$(gg_ts) ${C_R}Could not put the new file in place.${C_0}" >&2
  FAILED_LIST+=("$out")
  return 1
}

gg_print_summary() {
  local item
  gg_heading "Summary"
  printf '  %-18s %s\n' "Written:" "${#DONE_LIST[@]} track(s)"
  for item in "${DONE_LIST[@]}"; do
    printf '    %s\n' "$item"
  done
  if (( ${#SKIPPED_LIST[@]} > 0 )); then
    printf '  %-18s %s\n' "Skipped:" "${#SKIPPED_LIST[@]}"
    for item in "${SKIPPED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  if (( ${#FAILED_LIST[@]} > 0 )); then
    printf '%s  %-18s %s%s\n' "$C_R" "Failed:" "${#FAILED_LIST[@]}" "$C_0"
    for item in "${FAILED_LIST[@]}"; do
      printf '    %s\n' "$item"
    done
  fi
  [[ "$STOPPED" == yes ]] && printf '  %-18s %s\n' "Stopped by user:" "yes"
  echo
}

gg_on_exit() {
  if (( SUMMARY )) && (( ! SUMMARY_DONE )); then
    SUMMARY_DONE=1
    gg_print_summary
  fi
  if [[ -r /root/bin/_script_footer.sh ]]; then
    # shellcheck disable=SC1091
    . /root/bin/_script_footer.sh
  fi
}

gg_ctrl_c() {
  STOPPED=yes
  echo
  echo "$(gg_ts) Interrupted."
  return_code=130
  exit 130
}

# --- main -------------------------------------------------------------------

DO_YES=0
DRY_RUN=0
REDO=0
OLD_MODE=keep
OLD_ASKED=0
INPUT_ARGS=()
V_PATH=()
V_EXPLICIT=()
V_OUT=()
V_STATE=()
V_INFO=()
V_KIND=()
TO_WRITE=0
EXISTING=0
DONE_LIST=()
SKIPPED_LIST=()
FAILED_LIST=()
SUMMARY=0
SUMMARY_DONE=0
STOPPED=no
return_code=0
PY_HELPER="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/video-pgm-gopro-to-gpx.py"
gg_colors

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

# shellcheck disable=SC1091
. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

trap gg_on_exit EXIT
trap gg_ctrl_c INT

gg_need_value() {
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
    --redo) REDO=1; shift ;;
    --old)
      gg_need_value "$@"
      case "$2" in
        keep|delete) OLD_MODE="$2"; OLD_ASKED=1 ;;
        *) echo "ERROR: --old must be keep or delete, not: $2" >&2; exit 1 ;;
      esac
      shift 2 ;;
    --) shift; INPUT_ARGS+=("$@"); break ;;
    -*) echo "ERROR: unknown option: $1 (see --help)" >&2; exit 1 ;;
    *) INPUT_ARGS+=("$1"); shift ;;
  esac
done

if [[ ! -f "$PY_HELPER" ]]; then
  echo "$(gg_ts) Missing helper: ${PY_HELPER}" >&2
  exit 1
fi

gg_check_prereqs

if (( ${#INPUT_ARGS[@]} == 0 )); then
  gg_add_directory "."
else
  for _arg in "${INPUT_ARGS[@]}"; do
    _path="$(gg_unix_path "$_arg")"
    if [[ -d "$_path" ]]; then
      gg_add_directory "$_path"
    elif [[ -f "$_path" ]]; then
      gg_add_file "$_path" 1
    else
      echo "ERROR: not a file or directory: ${_arg}" >&2
      exit 1
    fi
  done
fi

SUMMARY=1
if (( ${#V_PATH[@]} == 0 )); then
  echo "$(gg_ts) No .mp4 or .mov files."
  SUMMARY=0
  return_code=0
  exit 0
fi

gg_probe
gg_print_plan

gopro_n=0
for i in "${!V_PATH[@]}"; do
  case "${V_STATE[$i]}" in
    write|exists|redo) (( gopro_n++ )) || true ;;
  esac
done
if (( gopro_n == 0 )); then
  echo "$(gg_ts) No GoPro video with a GPS track. Nothing to write."
  SUMMARY=0
  return_code=0
  exit 0
fi

if (( DRY_RUN )); then
  SUMMARY=0
  return_code=0
  exit 0
fi

if (( ! DO_YES )); then
  if (( ! script_is_run_interactively )); then
    echo "$(gg_ts) Not a terminal: nothing written. Add -y to write without asking."
    SUMMARY=0
    return_code=0
    exit 0
  fi
  gg_prompt_plan
fi

for i in "${!V_PATH[@]}"; do
  case "${V_STATE[$i]}" in
    write|redo) gg_write_one "$i" || return_code=1 ;;
    exists) SKIPPED_LIST+=("${V_OUT[$i]} (already exists)") ;;
  esac
done

exit "$return_code"
