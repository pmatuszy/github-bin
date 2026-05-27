#!/bin/bash

# 2026.05.27 - v. 0.7 - interactive GoPro chapter groups (part_01→02→…); -y merges all without prompts
# 2026.05.26 - v. 0.6 - on Ctrl-C remove incomplete _concat.mp4 output during merge
# 2026.05.26 - v. 0.5 - source _script_header.sh / _script_footer.sh like other bin scripts
# 2026.05.26 - v. 0.4 - enforce owner-only mode 700 on this script when run on Linux
# 2026.05.26 - v. 0.3 - add -h/--help and -u/--update (install mp4_merge from gyroflow/mp4-merge)
# 2026.05.26 - v. 0.2 - renamed from gopro-mp4-merge.sh
# 2026.05.26 - v. 0.1 - merge GoPro chapter MP4s (Windows merge-gopro batch port)

MP4_MERGE_REPO="${MP4_MERGE_REPO:-gyroflow/mp4-merge}"

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-u|--update] [-v|--version] [-y|--yes] [NO_STARTUP_DELAY]

Merge chapter MP4 files in the current directory (e.g. GoPro splits) into one
file using mp4_merge from https://github.com/gyroflow/mp4-merge

Options:
  -h, --help           Show this help and exit.
  -u, --update         Download or update mp4_merge for this OS/CPU into the install
                       directory (default: directory containing this script).
  -v, --version        Print script version and exit.
  -y, --yes            Merge every detected multi-part group without prompts (for cron).
  NO_STARTUP_DELAY     Skip random startup delay when run non-interactively (see
                       _script_header.sh).

Merge behaviour (no options):
  - Collects *.mp4 in the current working directory (case-insensitive), except
    existing *_concat.mp4 outputs.
  - Detects GoPro-style chapter sequences (_part_01, _part_02, … with the same
    camera token, e.g. GOPRO7_BLACK). A new recording starts when part resets to 01.
  - Shows each multi-part group and asks whether to merge (interactive session).
  - Output file per group: <last_chapter_basename>_concat.mp4
  - Single-part files are listed but not merged unless you group them manually.

mp4_merge lookup (merge mode):
  1. MP4_MERGE_BIN if set and executable
  2. ./mp4_merge-linux64, ./mp4_merge-linux-arm64, ./mp4_merge-linux32,
     ./mp4_merge-linux, ./mp4_merge
  3. Same names in the script directory

Environment:
  MP4_MERGE_BIN           Path to mp4_merge binary (overrides search paths).
  MP4_MERGE_INSTALL_DIR   Target directory for -u/--update (default: script dir).
  MP4_MERGE_REPO          GitHub repo for releases (default: gyroflow/mp4-merge).

Examples:
  $(basename "$0") -u
      Install or refresh mp4_merge for this machine.

  cd /path/to/chapters && $(basename "$0")
      Merge all chapter MP4s in that folder.

  $(basename "$0") -y NO_STARTUP_DELAY
      Merge all chapter groups without prompts (cron).

  $(basename "$0") NO_STARTUP_DELAY
      Interactive merge plan with per-group prompts.

Upstream: https://github.com/gyroflow/mp4-merge
EOF
}

script_version() {
  local ver=unknown date=
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*) ]]; then
      date="${BASH_REMATCH[1]}"
      ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  if [[ -n "$date" ]]; then
    printf '%s version %s (%s)\n' "$(basename "$0")" "$ver" "$date"
  else
    printf '%s version %s\n' "$(basename "$0")" "$ver"
  fi
}

# Print gyroflow/mp4-merge asset basename for this host (stdout) or return 1.
detect_mp4_merge_asset() {
  local os arch
  os=$(uname -s)
  arch=$(uname -m)
  case "$os" in
    Linux)
      case "$arch" in
        x86_64|amd64)     printf '%s\n' mp4_merge-linux64 ;;
        aarch64|arm64)    printf '%s\n' mp4_merge-linux-arm64 ;;
        i686|i386)        printf '%s\n' mp4_merge-linux32 ;;
        *) return 1 ;;
      esac
      ;;
    Darwin)
      case "$arch" in
        arm64)            printf '%s\n' mp4_merge-mac-arm64 ;;
        x86_64)           printf '%s\n' mp4_merge-mac64 ;;
        *) return 1 ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac
}

fetch_latest_release_tag() {
  local api_url="https://api.github.com/repos/${MP4_MERGE_REPO}/releases/latest"
  local json tag
  if ! json=$(/usr/bin/curl -fsSL --max-time 120 "${api_url}" 2>/dev/null); then
    echo "(PGM) Failed to fetch release metadata from ${api_url}" >&2
    return 1
  fi
  tag=$(printf '%s\n' "$json" | grep -m1 '"tag_name"' | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
  if [[ -z "$tag" ]]; then
    echo "(PGM) Could not parse latest release tag from GitHub API." >&2
    return 1
  fi
  printf '%s\n' "$tag"
}

update_mp4_merge() {
  local asset tag dest tmp url
  check_if_installed curl

  if ! asset=$(detect_mp4_merge_asset); then
    echo "(PGM) Unsupported OS/arch for mp4_merge: $(uname -s) $(uname -m)" >&2
    return 1
  fi
  if ! tag=$(fetch_latest_release_tag); then
    return 1
  fi
  mkdir -p "${MP4_MERGE_INSTALL_DIR}"
  dest="${MP4_MERGE_INSTALL_DIR}/${asset}"
  tmp="${dest}.tmp.$$"
  url="https://github.com/${MP4_MERGE_REPO}/releases/download/${tag}/${asset}"

  echo "(PGM) Installing ${asset} (${tag}) ..."
  echo "(PGM) From: ${url}"
  echo "(PGM) To:   ${dest}"
  echo

  if ! /usr/bin/curl -fsSL --max-time 600 -o "${tmp}" "${url}"; then
    rm -f "${tmp}"
    echo "(PGM) Download failed." >&2
    return 1
  fi
  chmod 755 "${tmp}"
  mv -f "${tmp}" "${dest}"

  if [[ "${asset}" != mp4_merge ]]; then
    ln -sf "${asset}" "${MP4_MERGE_INSTALL_DIR}/mp4_merge"
  fi

  echo "(PGM) Installed: ${dest}"
  if [[ -x "${dest}" ]]; then
    echo "(PGM) $(file -b "${dest}" 2>/dev/null || echo 'binary ready')"
  fi
  return 0
}

find_merger() {
  if [[ -n "${MP4_MERGE_BIN:-}" && -x "${MP4_MERGE_BIN}" ]]; then
    printf '%s\n' "${MP4_MERGE_BIN}"
    return 0
  fi
  local name
  for name in mp4_merge-linux64 mp4_merge-linux-arm64 mp4_merge-linux32 mp4_merge-linux mp4_merge; do
    if [[ -x "./${name}" ]]; then
      printf '%s\n' "./${name}"
      return 0
    fi
    if [[ -x "${SCRIPT_DIR}/${name}" ]]; then
      printf '%s\n' "${SCRIPT_DIR}/${name}"
      return 0
    fi
  done
  return 1
}

# Set by do_merge; used by trap on Ctrl-C to drop a partial output file.
VIDEO_MERGE_OUT_FILE=""

video_merge_ctrl_c() {
  if [[ -n "${VIDEO_MERGE_OUT_FILE}" && -e "${VIDEO_MERGE_OUT_FILE}" ]]; then
    rm -f "${VIDEO_MERGE_OUT_FILE}"
    echo "(PGM) Removed incomplete output: ${VIDEO_MERGE_OUT_FILE}"
  fi
  ctrl_c
}

# True if basename is an existing merge output (skip as input).
is_concat_output_basename() {
  local base="${1%.*}"
  [[ "${base}" == *_concat ]]
}

# Print decimal part number to stdout, or return 1 if not a _part_XX chapter name.
chapter_part_from_basename() {
  local base="$1"
  if [[ "$base" =~ _part_([0-9]{2})(_Proxy)?\.[mM][pP]4$ ]]; then
    printf '%d\n' "$((10#${BASH_REMATCH[1]}))"
    return 0
  fi
  return 1
}

chapter_camera_from_basename() {
  local base="$1"
  if [[ "$base" =~ _-__-_([^/]+)_part_[0-9]{2} ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

# 0 = next file continues the same multi-part recording.
chapter_continues_sequence() {
  local last_base="$1" new_base="$2"
  local last_part new_part last_cam new_cam
  last_part=$(chapter_part_from_basename "$last_base") || return 1
  new_part=$(chapter_part_from_basename "$new_base") || return 1
  last_cam=$(chapter_camera_from_basename "$last_base" 2>/dev/null) || last_cam=
  new_cam=$(chapter_camera_from_basename "$new_base" 2>/dev/null) || new_cam=
  if [[ -n "$last_cam" && -n "$new_cam" && "$last_cam" != "$new_cam" ]]; then
    return 1
  fi
  (( new_part == last_part + 1 ))
}

# Build merge groups: each element of GROUP_BLOBS is a newline-separated file list (sorted).
build_chapter_groups() {
  local -a sorted=("$@")
  GROUP_BLOBS=()
  local current_blob="" f base last_base last_file
  for f in "${sorted[@]}"; do
    base="${f##*/}"
    if is_concat_output_basename "$base"; then
      continue
    fi
    if [[ -z "$current_blob" ]]; then
      current_blob="$f"
      last_base="$base"
      continue
    fi
    last_file="${current_blob##*$'\n'}"
    last_base="${last_file##*/}"
    if chapter_continues_sequence "$last_base" "$base"; then
      current_blob+=$'\n'"$f"
    else
      GROUP_BLOBS+=("$current_blob")
      current_blob="$f"
    fi
    last_base="$base"
  done
  if [[ -n "$current_blob" ]]; then
    GROUP_BLOBS+=("$current_blob")
  fi
}

group_files_to_array() {
  local blob="$1"
  local -n _out=$2
  mapfile -t _out <<< "$blob"
  if ((${#_out[@]})) && [[ -z "${_out[-1]}" ]]; then
    unset '_out[-1]'
  fi
}

print_group_plan() {
  local gidx=0 mergeable=0 standalone=0
  local -a files=()
  local f base part cam blob
  echo "(PGM) Chapter plan in $(pwd):"
  echo
  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    (( ${#files[@]} >= 2 )) && (( mergeable++ )) || true
  done
  if (( mergeable > 0 )); then
    echo "Merge candidates:"
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} < 2 )) && continue
      (( gidx++ )) || true
      printf '  [group %d/%d] %d parts → %s_concat.mp4\n' \
        "$gidx" "$mergeable" "${#files[@]}" "${files[-1]%.*}"
      for f in "${files[@]}"; do
        base="${f##*/}"
        if part=$(chapter_part_from_basename "$base" 2>/dev/null); then
          printf '      part %02d  %s\n' "$part" "$base"
        else
          printf '              %s\n' "$base"
        fi
      done
      echo
    done
  fi
  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    (( ${#files[@]} < 2 )) && (( standalone++ )) || true
  done
  if (( standalone > 0 )); then
    echo "Standalone (single chapter, will not merge):"
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} >= 2 )) && continue
      base="${files[0]##*/}"
      part=$(chapter_part_from_basename "$base" 2>/dev/null) || part=
      cam=$(chapter_camera_from_basename "$base" 2>/dev/null) || cam=
      printf '      '
      [[ -n "$part" ]] && printf 'part %02d  ' "$part"
      [[ -n "$cam" ]] && printf '%s  ' "$cam"
      printf '%s\n' "$base"
    done
    echo
  fi
  echo "(PGM) Summary: ${mergeable} merge group(s), ${standalone} standalone file(s)."
  echo
}

group_output_file() {
  local -a files=("$@")
  printf '%s_concat.mp4\n' "${files[-1]%.*}"
}

run_merge_group() {
  local merger="$1"
  shift
  local -a files=("$@")
  local output_file rc
  output_file=$(group_output_file "${files[@]}")
  if [[ -e "$output_file" ]]; then
    echo "(PGM) Output already exists, skipping: ${output_file}"
    return 0
  fi
  VIDEO_MERGE_OUT_FILE="${output_file}"
  echo "(PGM) Merging ${#files[@]} chapter(s) → ${output_file}"
  trap video_merge_ctrl_c INT
  "${merger}" "${files[@]}" --out "${output_file}"
  rc=$?
  trap ctrl_c INT
  VIDEO_MERGE_OUT_FILE=""
  if (( rc == 0 )); then
    echo "(PGM) Done: ${output_file}"
  else
    echo "(PGM) Merge failed (exit ${rc})." >&2
  fi
  return "${rc}"
}

# Sets REPLY to: merge | skip | skip_all | merge_all | quit
prompt_merge_group_action() {
  local group_num="$1" group_total="$2"
  REPLY=skip
  if (( DO_YES )); then
    REPLY=merge
    return 0
  fi
  if (( MERGE_ALL_REMAINING )); then
    REPLY=merge
    return 0
  fi
  if (( SKIP_ALL_REMAINING )); then
    REPLY=skip
    return 0
  fi
  if (( ! script_is_run_interactively )); then
    echo "(PGM) Non-interactive: skipping group ${group_num} (use -y to merge all)."
    REPLY=skip
    return 0
  fi
  local choice
  while true; do
    echo "  [Y] Merge   [N] Skip   [A] Skip all remaining   [M] Merge all remaining   [Q] Quit"
    printf 'Choice for group %d/%d [Y/n/a/m/q]: ' "$group_num" "$group_total"
    IFS= read -r choice || choice=q
    case "${choice,,}" in
      ''|y|yes)  REPLY=merge; return 0 ;;
      n|no)      REPLY=skip; return 0 ;;
      a|all)     REPLY=skip_all; return 0 ;;
      m|merge)   REPLY=merge_all; return 0 ;;
      q|quit)    REPLY=quit; return 0 ;;
      *)         echo "(PGM) Unknown choice: ${choice}" ;;
    esac
  done
}

show_merge_group_detail() {
  local group_num="$1" group_total="$2"
  shift 2
  local -a files=("$@")
  local f base part output_file
  output_file=$(group_output_file "${files[@]}")
  echo "=== Merge group ${group_num} of ${group_total} (${#files[@]} parts) ==="
  for f in "${files[@]}"; do
    base="${f##*/}"
    part=$(chapter_part_from_basename "$base" 2>/dev/null) || part=
    if [[ -n "$part" ]]; then
      printf '  part %02d  %s\n' "$part" "$base"
    else
      printf '         %s\n' "$base"
    fi
  done
  echo "  → ${output_file}"
  if [[ -e "$output_file" ]]; then
    echo "(PGM) Note: output file already exists."
  fi
  echo
}

do_merge() {
  local merger rc=0 group_num=0 mergeable_total=0
  local blob action -a files=() mergeable_blobs=()
  merger=$(find_merger) || {
    echo "(PGM) mp4_merge not found in . or ${SCRIPT_DIR}/" >&2
    echo "(PGM) Run: $(basename "$0") -u" >&2
    echo "(PGM) Or set MP4_MERGE_BIN=/path/to/mp4_merge" >&2
    return 1
  }

  shopt -s nullglob nocaseglob
  local mp4_files=( *.mp4 )
  shopt -u nocaseglob

  if (( ${#mp4_files[@]} == 0 )); then
    echo "(PGM) No *.mp4 files in $(pwd)" >&2
    return 1
  fi

  local sorted_mp4=()
  mapfile -t sorted_mp4 < <(printf '%s\n' "${mp4_files[@]}" | LC_ALL=C sort)

  build_chapter_groups "${sorted_mp4[@]}"
  if (( ${#GROUP_BLOBS[@]} == 0 )); then
    echo "(PGM) No chapter MP4s to process in $(pwd)" >&2
    return 1
  fi

  MERGE_ALL_REMAINING=0
  SKIP_ALL_REMAINING=0

  print_group_plan

  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    if (( ${#files[@]} >= 2 )); then
      mergeable_blobs+=("$blob")
    fi
  done
  mergeable_total=${#mergeable_blobs[@]}

  if (( mergeable_total == 0 )); then
    echo "(PGM) No multi-part chapter groups to merge."
    return 0
  fi

  for blob in "${mergeable_blobs[@]}"; do
    group_files_to_array "$blob" files
    (( group_num++ )) || true
    show_merge_group_detail "$group_num" "$mergeable_total" "${files[@]}"
    prompt_merge_group_action "$group_num" "$mergeable_total"
    action=$REPLY
    case "$action" in
      merge)
        run_merge_group "$merger" "${files[@]}" || rc=$?
        ;;
      skip)
        echo "(PGM) Skipped group ${group_num}."
        ;;
      skip_all)
        SKIP_ALL_REMAINING=1
        echo "(PGM) Skipped group ${group_num}; skipping remaining groups."
        ;;
      merge_all)
        MERGE_ALL_REMAINING=1
        run_merge_group "$merger" "${files[@]}" || rc=$?
        ;;
      quit)
        echo "(PGM) Quit at group ${group_num}."
        return "${rc}"
        ;;
    esac
    echo
  done

  if (( rc == 0 )); then
    echo "(PGM) Finished."
  fi
  return "${rc}"
}

# --- parse options before _script_header (avoids figlet/delay on --help) ---
DO_UPDATE=0
DO_YES=0
MERGE_ALL_REMAINING=0
SKIP_ALL_REMAINING=0
GROUP_BLOBS=()
HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      script_version
      exit 0
      ;;
    -u|--update)
      DO_UPDATE=1
      shift
      ;;
    -y|--yes)
      DO_YES=1
      shift
      ;;
    NO_STARTUP_DELAY)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    *)
      echo "(PGM) Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

# shellcheck disable=SC1091
. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MP4_MERGE_INSTALL_DIR="${MP4_MERGE_INSTALL_DIR:-${SCRIPT_DIR}}"

if [[ -f "${BASH_SOURCE[0]}" ]]; then
  chmod 700 "${BASH_SOURCE[0]}" 2>/dev/null || true
fi

if (( DO_UPDATE )); then
  update_mp4_merge
  kod_powrotu=$?
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

do_merge
kod_powrotu=$?

. /root/bin/_script_footer.sh

exit "${kod_powrotu}"
