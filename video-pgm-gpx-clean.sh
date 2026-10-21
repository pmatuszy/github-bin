#!/bin/bash
# v. 20261021.141500 - rename to video-pgm-gpx-clean; match video-pgm plan/summary/old-file flow
# v. 20261021.141200 - interactive: pick .gpx files, ask cleaning parameters, handle existing outputs
# v. 20261021.140100 - note: python helper drops whole teleport clusters
# v. 20261021.135400 - clean noisy GPX tracks via helper (spikes + stationary jitter)

# 2026.10.21 - v. 0.4 - renamed to video-pgm-gpx-clean.sh/.py like the other video-pgm tools; plan,
#                        equivalent command, write-to-.partial then retire old, summary on EXIT
# 2026.10.21 - v. 0.3 - interactive run: scan dirs for .gpx, pick files, ask max-jump / stop / smooth,
#                        ask what to do with an existing *_cleaned.gpx; -y and CLI flags skip questions
# 2026.10.21 - v. 0.2 - companion helper 0.2: jump filter removes multi-point teleports
# 2026.10.21 - v. 0.1 - initial release: check python3 (ask apt-get install when interactive),
#                        convert Windows paths, pass options through to the python helper beside this file
#
# video-pgm-gpx-clean.sh
#
# Clean a noisy GPX track: drop impossible speed spikes, collapse stationary
# GPS jitter, optional short coordinate smooth. The original file is left
# alone; the default output is INPUT_cleaned.gpx beside it.
# Processing is done by video-pgm-gpx-clean.py next to this script.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-n|--dry-run] [-o FILE] [--redo] [--old keep|delete]
       [--max-jump KMH] [--stop-kmh KMH] [--stop-radius M] [--smooth S]
       [FILE.gpx|DIR ...]

Clean noisy GPX tracks (speed spikes and stationary spiderweb jitter).
Writes FILE_cleaned.gpx beside each input (or -o FILE with exactly one input).
The input is not changed.
With no FILE or DIR, the current directory is used. A directory's tracks are
the .gpx files in that directory, not in folders inside it. Already cleaned
(*_cleaned.gpx) and kept-old (*_old-*.gpx) names are skipped when scanning.
Windows paths such as O:\\video\\track.gpx are read as /mnt/o/video/track.gpx
when that mount exists.

In a terminal the script asks which files to clean (when there is more than
one), whether to tweak the cleaning numbers, and what to do if a cleaned file
is already there. -y and any cleaning flag on the command line skip those
questions (defaults or the flags you gave are used).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Do not ask. Clean every selected track that is not there
                       yet (still asks before apt install unless there is no
                       terminal; then it only prints the command).
  -n, --dry-run        Print the plan and stats; write nothing.
  -o, --output FILE    Output .gpx (only with one input file).
  --redo               Write again where a cleaned .gpx is already there.
  --old keep|delete    What happens to that old cleaned file. keep (default):
                       renamed to ..._old-YYYYMMDD_HHMMSS.gpx. delete: removed.
                       The old file is only touched after the new one is written.
  --max-jump KMH       Drop points faster than this from the last good fix
                       (default 200; 0 keeps all).
  --stop-kmh KMH       Collapse slower movement as stopped jitter (default 3; <0 off).
  --stop-radius M      Max radius of a stop cluster in metres (default 25).
  --smooth S           Seconds of coordinate smooth after cleaning (default 2; 0 off).

Needs: python3. When it is missing the script lists it and asks whether to
install it with apt-get (with sudo when not root). With -y or without a
terminal it only prints the install command.
The helper video-pgm-gpx-clean.py has its own -h, -v, and --history.

Examples:
  $(basename "$0")
      Read the current directory, print the plan, ask before writing.
  $(basename "$0") -n /mnt/o/video/trip
  $(basename "$0") -y --max-jump 180 track.gpx
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

gc_k() {
  if [[ "$1" == "$2" ]]; then
    printf '%s' "${1^^}"
  else
    printf '%s' "$1"
  fi
}

gc_keys() {
  local def="$1" k out=""
  shift
  for k in "$@"; do
    out+="${out:+/}$(gc_k "$k" "$def")"
  done
  printf '%s' "$out"
}

gc_cur_mark() {
  [[ "$1" == "$2" ]] && printf ' (current, default)'
  return 0
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

gc_read_line() {
  local prompt="$1" default="$2" answer=""
  printf '%s' "$prompt"
  IFS= read -r answer || answer=""
  REPLY="${answer:-$default}"
}

gc_quit() {
  echo "$(gc_ts) Quit. Nothing more was written."
  STOPPED=yes
  return_code=0
  exit 0
}

gc_ask_line() {
  local name="$1" cur="$2"
  echo "  [Enter] Keep the current answer: ${cur}"
  echo "  [q]     Quit the script, write nothing more"
  gc_read_line "${name} [${cur}] (q = quit): " "$cur"
  [[ "${REPLY,,}" == q ]] && gc_quit
  return 0
}

gc_human_size() {
  awk -v b="${1:-0}" 'BEGIN {
    split("B KiB MiB GiB TiB", u, " ")
    i = 1
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    if (i == 1) printf "%d %s", b, u[i]
    else printf "%.1f %s", b, u[i]
  }'
}

gc_file_bytes() {
  local n=0
  [[ -f "$1" ]] && n=$(stat -c %s -- "$1" 2>/dev/null || printf '0')
  [[ "$n" =~ ^[0-9]+$ ]] || n=0
  printf '%s\n' "$n"
}

gc_existing_info() {
  printf '%s, made %s' "$(gc_human_size "$(gc_file_bytes "$1")")" \
    "$(date -r "$1" '+%Y.%m.%d %H:%M' 2>/dev/null || echo '?')"
}

gc_missing_prereqs() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3|Python 3: cleans the GPX track (video-pgm-gpx-clean.py)"
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

gc_skip_name() {
  local base="${1##*/}"
  [[ "$base" == *_cleaned.gpx || "$base" == *_cleaned.GPX ]] && return 0
  [[ "$base" == *_old-* ]] && return 0
  [[ "$base" == *.partial.* || "$base" == *.partial ]] && return 0
  return 1
}

gc_is_gpx() {
  local base="${1##*/}"
  [[ "$base" =~ \.[gG][pP][xX]$ ]]
}

gc_add_file() {
  local f="$1" explicit="${2:-0}" i
  [[ -f "$f" ]] || return 0
  if ! gc_is_gpx "$f"; then
    if (( explicit )); then
      echo "$(gc_ts) ${C_Y}Not a .gpx file, ignored:${C_0} $f" >&2
    fi
    return 0
  fi
  if gc_skip_name "$f"; then
    if (( explicit )); then
      echo "$(gc_ts) ${C_Y}Skipped cleaned/old/partial name:${C_0} $f" >&2
    fi
    return 0
  fi
  for i in "${!F_PATH[@]}"; do
    [[ "${F_PATH[$i]}" == "$f" ]] && return 0
  done
  F_PATH+=("$f")
  F_EXPLICIT+=("$explicit")
}

gc_add_directory() {
  local dir="${1%/}" f
  local -a found=()
  [[ -n "$dir" ]] || dir="/"
  shopt -s nullglob nocaseglob
  found=( "$dir"/*.gpx )
  shopt -u nullglob nocaseglob
  (( ${#found[@]} == 0 )) && return 0
  mapfile -t found < <(printf '%s\n' "${found[@]}" | LC_ALL=C sort -u)
  for f in "${found[@]}"; do
    [[ -n "$f" ]] && gc_add_file "$f" 0
  done
}

gc_pick_files() {
  local i n mark answer
  local -a marks=()
  n=${#F_PATH[@]}
  (( n <= 1 )) && return 0
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  for (( i = 0; i < n; i++ )); do
    marks[i]=1
  done
  gc_heading "Files"
  echo "  Number toggles one file. A=all, N=none, D=done (default)."
  while true; do
    echo
    for (( i = 0; i < n; i++ )); do
      if (( marks[i] )); then mark='x'; else mark=' '; fi
      printf '  %2d) [%s] %s\n' "$((i + 1))" "$mark" "$(basename -- "${F_PATH[i]}")"
    done
    gc_read_line "Pick [1-${n}/A/N/D/q], Enter keeps D: " d
    answer="${REPLY,,}"
    case "$answer" in
      q) gc_quit ;;
      a)
        for (( i = 0; i < n; i++ )); do marks[i]=1; done
        ;;
      n)
        for (( i = 0; i < n; i++ )); do marks[i]=0; done
        ;;
      d|'')
        break
        ;;
      *)
        if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= n )); then
          i=$((answer - 1))
          if (( marks[i] )); then marks[i]=0; else marks[i]=1; fi
        else
          echo "$(gc_ts) Unknown choice: ${REPLY}."
        fi
        ;;
    esac
  done
  local -a keep_path=() keep_explicit=()
  for (( i = 0; i < n; i++ )); do
    if (( marks[i] )); then
      keep_path+=("${F_PATH[i]}")
      keep_explicit+=("${F_EXPLICIT[i]}")
    fi
  done
  F_PATH=("${keep_path[@]}")
  F_EXPLICIT=("${keep_explicit[@]}")
}

gc_number_ok() {
  [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

gc_prompt_params() {
  if (( DO_YES )) || (( PARAMS_SET )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  gc_heading "Cleaning settings"
  echo "  Defaults are for a car / GoPro track. Enter keeps the value in brackets."
  echo
  printf 'Tweak the cleaning settings? [y/N/q]\n'
  echo "  [y] Yes — set max jump, stop collapse, and smooth, one value at a time"
  echo "  [N] No (default) — keep: max-jump ${MAX_JUMP} km/h, stop ${STOP_KMH} km/h / ${STOP_RADIUS} m, smooth ${SMOOTH} s"
  echo "  [q] Quit"
  gc_read_key "Tweak the cleaning settings [y/N/q]: " n
  case "$REPLY" in
    y) ;;
    q) gc_quit ;;
    n) return 0 ;;
    *) echo "$(gc_ts) Unknown choice. Keeping the defaults."; return 0 ;;
  esac

  echo
  echo "Drop jumps faster than: km/h"
  echo "  A point that would mean moving faster than this from the last good fix"
  echo "  is treated as a GPS error and left out. 0 keeps every point."
  echo "  200  car / GoPro (default)   80  bike   25  walk   250  motorway"
  gc_ask_line "Drop jumps over" "$MAX_JUMP"
  if [[ "$REPLY" =~ ^[0-9]+$ ]] && (( 10#$REPLY == 0 || (10#$REPLY >= 10 && 10#$REPLY <= 2000) )); then
    MAX_JUMP=$(( 10#$REPLY ))
  else
    echo "$(gc_ts) ${C_Y}Not 0 or 10 to 2000 km/h: ${REPLY}. Keeping ${MAX_JUMP}.${C_0}"
  fi

  echo
  echo "Stop speed: km/h — slower movement is collapsed as stationary jitter"
  echo "  3   default   0   only exact standstill   use a negative number to turn off"
  gc_ask_line "Stop speed" "$STOP_KMH"
  if [[ "$REPLY" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    STOP_KMH="$REPLY"
  else
    echo "$(gc_ts) ${C_Y}Not a number: ${REPLY}. Keeping ${STOP_KMH}.${C_0}"
  fi

  echo
  echo "Stop cluster radius: metres — how far a stop spiderweb may spread"
  echo "  25  default   10  tight   50  loose urban canyon"
  gc_ask_line "Stop radius" "$STOP_RADIUS"
  if gc_number_ok "$REPLY" && awk -v v="$REPLY" 'BEGIN { exit !(v >= 0 && v <= 500) }'; then
    STOP_RADIUS="$REPLY"
  else
    echo "$(gc_ts) ${C_Y}Not 0 to 500 m: ${REPLY}. Keeping ${STOP_RADIUS}.${C_0}"
  fi

  echo
  echo "Coordinate smooth: seconds after the filters"
  echo "  0   off   2   light (default)   4   medium   8   strong"
  gc_ask_line "Smooth" "$SMOOTH"
  if gc_number_ok "$REPLY" && awk -v v="$REPLY" 'BEGIN { exit !(v >= 0 && v <= 60) }'; then
    SMOOTH="$REPLY"
  else
    echo "$(gc_ts) ${C_Y}Not 0 to 60 seconds: ${REPLY}. Keeping ${SMOOTH}.${C_0}"
  fi
}

gc_old_name() {
  local out="$1" stamp cand n=2
  stamp="$(date -r "$out" '+%Y%m%d_%H%M%S' 2>/dev/null || date '+%Y%m%d_%H%M%S')"
  cand="${out%.gpx}_old-${stamp}.gpx"
  while [[ -e "$cand" ]]; do
    cand="${out%.gpx}_old-${stamp}-${n}.gpx"
    (( n++ ))
  done
  printf '%s\n' "$cand"
}

gc_retire_old() {
  local out="$1" old
  [[ -e "$out" ]] || return 0
  if [[ "$OLD_MODE" == delete ]]; then
    rm -f -- "$out" || return 1
    echo "$(gc_ts) Old file deleted: ${out}"
  else
    old="$(gc_old_name "$out")"
    mv -- "$out" "$old" || return 1
    echo "$(gc_ts) Old file kept as: ${old}"
  fi
}

gc_classify() {
  local i out
  F_OUT=()
  F_STATE=()
  for i in "${!F_PATH[@]}"; do
    if [[ -n "$OUT_FILE" ]]; then
      out="$(gc_unix_path "$OUT_FILE")"
    else
      out="$(gc_default_out "${F_PATH[$i]}")"
    fi
    F_OUT+=("$out")
    if [[ -e "$out" ]]; then
      if (( REDO )); then
        F_STATE+=("redo")
      else
        F_STATE+=("exists")
      fi
    else
      F_STATE+=("write")
    fi
  done
}

gc_equivalent_command() {
  local -a cmd=("$(basename "$0")" -y)
  (( REDO )) && cmd+=(--redo)
  (( REDO )) && [[ "$OLD_MODE" == delete ]] && cmd+=(--old delete)
  [[ -n "$OUT_FILE" ]] && cmd+=(-o "$OUT_FILE")
  cmd+=(--max-jump "$MAX_JUMP" --stop-kmh "$STOP_KMH" --stop-radius "$STOP_RADIUS" --smooth "$SMOOTH")
  cmd+=(--)
  if (( ${#INPUT_ARGS[@]} > 0 )); then
    cmd+=("${INPUT_ARGS[@]}")
  else
    cmd+=("$(pwd -P)")
  fi
  gc_quote_args "${cmd[@]}"
}

gc_print_plan() {
  local i n=0 exists=0
  TO_WRITE=0
  EXISTING=0
  gc_heading "GPX tracks"
  for i in "${!F_PATH[@]}"; do
    (( n++ )) || true
    printf '  %s%s%s\n' "$C_B" "$(basename -- "${F_PATH[$i]}")" "$C_0"
    printf '    %s%s%s\n' "$C_DIM" "${F_PATH[$i]}" "$C_0"
    case "${F_STATE[$i]}" in
      write)
        printf '    %swrite %s%s\n' "$C_G" "$(basename -- "${F_OUT[$i]}")" "$C_0"
        (( TO_WRITE++ )) || true
        ;;
      redo)
        printf '    %swrite again %s%s\n' "$C_Y" "$(basename -- "${F_OUT[$i]}")" "$C_0"
        printf '    %s%s%s\n' "$C_Y" "$(gc_existing_info "${F_OUT[$i]}")" "$C_0"
        (( TO_WRITE++ )) || true
        (( EXISTING++ )) || true
        ;;
      exists)
        printf '    %sexists %s (%s), skipped unless you choose to write it again%s\n' \
          "$C_Y" "$(basename -- "${F_OUT[$i]}")" "$(gc_existing_info "${F_OUT[$i]}")" "$C_0"
        (( EXISTING++ )) || true
        (( exists++ )) || true
        ;;
    esac
  done
  if (( n == 0 )); then
    echo "  None."
  fi
  gc_heading "Settings"
  if [[ -n "$OUT_FILE" ]]; then
    printf '  %-14s %s\n' "Output" "$OUT_FILE"
  else
    printf '  %-14s %s\n' "Output" "same name + _cleaned.gpx, beside the input"
  fi
  printf '  %-14s %s\n' "Max jump" "${MAX_JUMP} km/h"
  printf '  %-14s %s\n' "Stop" "${STOP_KMH} km/h within ${STOP_RADIUS} m"
  printf '  %-14s %s\n' "Smooth" "${SMOOTH} s"
  if (( DRY_RUN )); then
    printf '  %-14s %s\n' "Mode" "dry-run (write nothing)"
  fi
  if (( REDO && EXISTING > 0 )); then
    if [[ "$OLD_MODE" == delete ]]; then
      printf '  %-14s %s\n' "Old cleaned" "deleted after the new one is written"
    else
      printf '  %-14s %s\n' "Old cleaned" "kept as ..._old-YYYYMMDD_HHMMSS.gpx"
    fi
  fi
  printf '  %-14s %s\n' "Command" "$(gc_equivalent_command)"
  echo
  printf '%s%d track(s), %d to write%s' "$C_B" "$n" "$TO_WRITE" "$C_0"
  (( exists > 0 )) && printf ', %d already cleaned (skipped for now)' "$exists"
  echo
}

gc_prompt_old() {
  local key=k
  (( OLD_ASKED )) && return 0
  OLD_ASKED=1
  [[ "$OLD_MODE" == delete ]] && key=d
  echo
  echo "What should happen to the old cleaned .gpx when the new one is written? [$(gc_keys "$key" k d q)]"
  echo "  The new file is written beside it first. The old file is only touched after that succeeds."
  echo "  [$(gc_k k "$key")] Keep it, renamed with the date and time it was made$(gc_cur_mark k "$key")"
  echo "      For example ..._cleaned_old-20261021_140000.gpx beside the new file."
  echo "  [$(gc_k d "$key")] Delete it$(gc_cur_mark d "$key")"
  echo "  [q] Quit the script, write nothing more"
  gc_read_key "Old file [$(gc_keys "$key" k d q)]: " "$key"
  case "$REPLY" in
    k) OLD_MODE=keep ;;
    d) OLD_MODE=delete ;;
    q) gc_quit ;;
    *) echo "$(gc_ts) Unknown choice: ${REPLY}. Keeping old files."; OLD_MODE=keep ;;
  esac
}

gc_prompt_existing() {
  local skip=0 i
  for i in "${!F_PATH[@]}"; do
    [[ "${F_STATE[$i]}" == exists ]] && (( skip++ )) || true
  done
  (( skip == 0 )) && return 0
  echo
  printf '%s%d track(s) already have a cleaned .gpx. What should happen to them? [S/r/q]%s\n' "$C_B" "$skip" "$C_0"
  echo "  [S] Skip them, keep the old files as they are (default)"
  echo "  [r] Write them again too"
  echo "      What happens to each old file is asked next."
  echo "  [q] Quit the script, write nothing"
  gc_read_key "Already written [S/r/q]: " s
  case "$REPLY" in
    s) ;;
    r)
      REDO=1
      for i in "${!F_PATH[@]}"; do
        if [[ "${F_STATE[$i]}" == exists ]]; then
          F_STATE[$i]=redo
          (( TO_WRITE++ )) || true
        fi
      done
      gc_prompt_old
      ;;
    q) gc_quit ;;
    *) echo "$(gc_ts) Unknown choice: ${REPLY}. Skipping them." ;;
  esac
}

gc_prompt_plan() {
  if (( TO_WRITE == 0 )); then
    echo
    if (( EXISTING > 0 && ! REDO )); then
      echo "$(gc_ts) Nothing new to write — all ${EXISTING} track(s) already have a cleaned .gpx."
      gc_prompt_existing
    elif (( EXISTING > 0 && REDO )); then
      echo "$(gc_ts) Nothing new; --redo will rewrite the existing cleaned file(s)."
      gc_prompt_old
    else
      echo "$(gc_ts) Nothing to write."
      gc_quit
    fi
    return 0
  fi

  echo
  printf '%sWrite the cleaned tracks now? [Y/n/q]%s\n' "$C_B" "$C_0"
  echo "  [Y] Write the ${TO_WRITE} track(s) listed above (default)"
  (( EXISTING > 0 && ! REDO )) && echo "      After that you are asked about the ${EXISTING} cleaned file(s) that are already there."
  echo "  [n] No, write nothing (also leave existing cleaned files alone)"
  echo "  [q] Quit the script"
  gc_read_key "Write the cleaned tracks now? [Y/n/q]: " y
  case "$REPLY" in
    y)
      if (( REDO )); then
        (( EXISTING > 0 )) && gc_prompt_old
      else
        gc_prompt_existing
      fi
      ;;
    n|q) gc_quit ;;
    *) echo "$(gc_ts) Unknown choice: ${REPLY}."; gc_quit ;;
  esac
}

gc_write_one() {
  local i="$1" out partial line rc=0
  local -a py_args=()
  out="${F_OUT[$i]}"
  case "${F_STATE[$i]}" in
    write|redo) ;;
    *) return 0 ;;
  esac
  echo
  echo "$(gc_ts) Cleaning: $(basename -- "${F_PATH[$i]}")"
  py_args=( "$PY_HELPER"
    --max-jump "$MAX_JUMP" --stop-kmh "$STOP_KMH"
    --stop-radius "$STOP_RADIUS" --smooth "$SMOOTH" )
  if (( DRY_RUN )); then
    py_args+=( --dry-run --output "$out" "${F_PATH[$i]}" )
    if line="$(python3 "${py_args[@]}" 2>&1)"; then
      printf '    %s\n' "$line"
      return 0
    fi
    echo "$(gc_ts) ${C_R}Dry-run failed.${C_0}" >&2
    printf '    %s\n' "$line" >&2
    FAILED_LIST+=("${out} (dry-run failed)")
    return 1
  fi
  partial="${out}.partial"
  rm -f -- "$partial"
  py_args+=( --output "$partial" "${F_PATH[$i]}" )
  if ! line="$(python3 "${py_args[@]}" 2>&1)"; then
    rc=$?
    rm -f -- "$partial"
    echo "$(gc_ts) ${C_R}Could not write the cleaned track (${line:-python failed}).${C_0}" >&2
    FAILED_LIST+=("${out} (${line:-python failed})")
    return 1
  fi
  if ! gc_retire_old "$out"; then
    echo "$(gc_ts) ${C_R}Could not move the old file aside. The new track is left as ${partial}${C_0}" >&2
    FAILED_LIST+=("${out} (old file not moved)")
    return 1
  fi
  if mv -f -- "$partial" "$out"; then
    echo "$(gc_ts) ${C_G}Wrote${C_0} ${out}"
    printf '    %s\n' "$line"
    DONE_LIST+=("$out")
    return 0
  fi
  echo "$(gc_ts) ${C_R}Could not put the new file in place.${C_0}" >&2
  FAILED_LIST+=("$out")
  return 1
}

gc_print_summary() {
  local item
  gc_heading "Summary"
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

gc_on_exit() {
  if (( SUMMARY )) && (( ! SUMMARY_DONE )); then
    SUMMARY_DONE=1
    gc_print_summary
  fi
  if [[ -r "${profile_location_dir:-$HOME}/bin/_script_footer.sh" ]]; then
    # shellcheck disable=SC1091
    . "${profile_location_dir:-$HOME}/bin/_script_footer.sh"
  fi
}

gc_ctrl_c() {
  STOPPED=yes
  echo
  echo "$(gc_ts) Interrupted."
  return_code=130
  exit 130
}

# --- main -------------------------------------------------------------------

DO_YES=0
DRY_RUN=0
REDO=0
OLD_MODE=keep
OLD_ASKED=0
PARAMS_SET=0
OUT_FILE=""
MAX_JUMP=200
STOP_KMH=3
STOP_RADIUS=25
SMOOTH=2
INPUT_ARGS=()
F_PATH=()
F_EXPLICIT=()
F_OUT=()
F_STATE=()
TO_WRITE=0
EXISTING=0
DONE_LIST=()
SKIPPED_LIST=()
FAILED_LIST=()
STOPPED=no
SUMMARY=0
SUMMARY_DONE=0
return_code=0

SCRIPT_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
PY_HELPER="${SCRIPT_DIR}/video-pgm-gpx-clean.py"
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
    --redo) REDO=1; shift ;;
    --old)
      gc_need_value "$@"
      case "$2" in
        keep|delete) OLD_MODE="$2"; OLD_ASKED=1 ;;
        *) echo "ERROR: --old must be keep or delete, not: $2" >&2; exit 1 ;;
      esac
      shift 2 ;;
    -o|--output)
      gc_need_value "$@"
      OUT_FILE="$2"
      shift 2 ;;
    --max-jump)
      gc_need_value "$@"
      MAX_JUMP="$2"
      PARAMS_SET=1
      shift 2 ;;
    --stop-kmh)
      gc_need_value "$@"
      STOP_KMH="$2"
      PARAMS_SET=1
      shift 2 ;;
    --stop-radius)
      gc_need_value "$@"
      STOP_RADIUS="$2"
      PARAMS_SET=1
      shift 2 ;;
    --smooth)
      gc_need_value "$@"
      SMOOTH="$2"
      PARAMS_SET=1
      shift 2 ;;
    --) shift; INPUT_ARGS+=("$@"); break ;;
    -*) echo "ERROR: unknown option: $1 (see --help)" >&2; exit 1 ;;
    *) INPUT_ARGS+=("$1"); shift ;;
  esac
done

if [[ ! -f "$PY_HELPER" ]]; then
  echo "$(gc_ts) Missing helper: ${PY_HELPER}" >&2
  exit 1
fi

gc_check_prereqs

if (( ${#INPUT_ARGS[@]} == 0 )); then
  gc_add_directory "."
else
  for _arg in "${INPUT_ARGS[@]}"; do
    _path="$(gc_unix_path "$_arg")"
    if [[ -d "$_path" ]]; then
      gc_add_directory "$_path"
    elif [[ -f "$_path" ]]; then
      gc_add_file "$_path" 1
    else
      echo "ERROR: not a file or directory: ${_arg}" >&2
      exit 1
    fi
  done
fi

if (( ${#F_PATH[@]} == 0 )); then
  echo "$(gc_ts) No .gpx files to clean."
  exit 0
fi

if [[ -n "$OUT_FILE" && ${#F_PATH[@]} -gt 1 ]]; then
  echo "ERROR: -o/--output works with only one input file (${#F_PATH[@]} found)" >&2
  exit 1
fi

gc_pick_files

if (( ${#F_PATH[@]} == 0 )); then
  echo "$(gc_ts) No files selected."
  exit 0
fi

gc_prompt_params
gc_classify
SUMMARY=1
gc_print_plan

if (( DRY_RUN )); then
  for i in "${!F_PATH[@]}"; do
    case "${F_STATE[$i]}" in
      write|redo) gc_write_one "$i" || return_code=1 ;;
      exists) SKIPPED_LIST+=("${F_OUT[$i]} (already exists)") ;;
    esac
  done
  exit "$return_code"
fi

if (( ! DO_YES )); then
  if (( ! script_is_run_interactively )); then
    echo "$(gc_ts) Not a terminal: nothing written. Add -y to write without asking."
    SUMMARY=0
    exit 0
  fi
  gc_prompt_plan
fi

for i in "${!F_PATH[@]}"; do
  case "${F_STATE[$i]}" in
    write|redo) gc_write_one "$i" || return_code=1 ;;
    exists) SKIPPED_LIST+=("${F_OUT[$i]} (already exists)") ;;
  esac
done

exit "$return_code"
