#!/bin/bash

# 2026.05.27 - v. 0.8.5 - menu options one per line; default key uppercase in prompt (rename.sh style)
# 2026.05.27 - v. 0.8.4 - already-merged groups: only skip/redo prompt (not Y-merge then N/r)
# 2026.05.27 - v. 0.8.3 - prompt skip (default) or redo when _concat output already exists
# 2026.05.27 - v. 0.8.2 - one line per input file (name + size together)
# 2026.05.27 - v. 0.8.1 - size difference: positive value + which side is larger (input vs output)
# 2026.05.27 - v. 0.8 - single-key prompts, per-file sizes, post-merge summary, optional delete inputs
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
  - Shows each multi-part group (with file sizes) and asks whether to merge
    (single-key Y/N/A/M/Q, no Enter — like rename.sh).
  - After a successful merge: size summary (inputs, output, difference) and optional
    deletion of the source chapter files (single-key Y/N).
  - If the expected _concat output already exists: skip (default) or redo merge (R).
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
PGM_READ_TIMEOUT=300

flush_stdin() {
  local discard drained=0 max_drain=256
  while (( drained < max_drain )) && IFS= read -r -t 0.02 -n 1 discard; do
    ((++drained))
  done
}

# Read one key (no Enter). Sets REPLY; uses default when empty and default is set.
pgm_read_key() {
  local prompt="$1" default="${2:-}" timeout="${3:-$PGM_READ_TIMEOUT}"
  local answer=
  if (( ! script_is_run_interactively )); then
    REPLY="$default"
    return 0
  fi
  printf '%s' "$prompt"
  flush_stdin
  read -t "$timeout" -n 1 answer || answer=
  echo
  if [[ -z "$answer" ]]; then
    REPLY="$default"
  else
    REPLY="$answer"
  fi
}

file_size_bytes() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    printf '0\n'
    return 0
  fi
  stat -c %s -- "$f" 2>/dev/null || stat -f %z -- "$f" 2>/dev/null || printf '0\n'
}

# bytes | kB | MB on one line (kB/MB = 1024-based).
format_bytes_human() {
  local bytes="$1"
  awk -v b="$bytes" 'BEGIN {
    printf "%d bytes | %.2f kB | %.2f MB", b, b/1024.0, b/1048576.0
  }'
}

# One line: part label (if any), basename, size.
print_chapter_file_line() {
  local indent="$1" f="$2"
  local base="${f##*/}" part sz
  sz=$(file_size_bytes "$f")
  if part=$(chapter_part_from_basename "$base" 2>/dev/null); then
    printf '%spart %02d  %s  %s\n' "$indent" "$part" "$base" "$(format_bytes_human "$sz")"
  else
    printf '%s%s  %s\n' "$indent" "$base" "$(format_bytes_human "$sz")"
  fi
}

# Absolute size difference (always non-negative).
format_bytes_abs_human() {
  local bytes="$1"
  if (( bytes < 0 )); then
    bytes=$(( -bytes ))
  fi
  format_bytes_human "$bytes"
}

# Describe which side is larger: input parts vs merged output (positive difference only).
format_size_comparison_line() {
  local input_total="$1" output_bytes="$2"
  local diff=0
  if (( input_total > output_bytes )); then
    diff=$(( input_total - output_bytes ))
    printf '  Difference: %s — input files are larger than output\n' "$(format_bytes_abs_human "$diff")"
  elif (( output_bytes > input_total )); then
    diff=$(( output_bytes - input_total ))
    printf '  Difference: %s — output is larger than input files\n' "$(format_bytes_abs_human "$diff")"
  else
    printf '  Difference: 0 bytes | 0.00 kB | 0.00 MB — input total and output are the same size\n'
  fi
}

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
      local out_name="${files[-1]%.*}_concat.mp4"
      if [[ -e "$out_name" ]]; then
        printf '  [group %d/%d] %d parts → %s  (already merged)\n' \
          "$gidx" "$mergeable" "${#files[@]}" "$out_name"
      else
        printf '  [group %d/%d] %d parts → %s\n' \
          "$gidx" "$mergeable" "${#files[@]}" "$out_name"
      fi
      local group_bytes=0 sz
      for f in "${files[@]}"; do
        print_chapter_file_line '      ' "$f"
        sz=$(file_size_bytes "$f")
        (( group_bytes += sz ))
      done
      printf '      input total (%d files): %s\n' "${#files[@]}" "$(format_bytes_human "$group_bytes")"
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

print_merge_size_summary() {
  local output_file="$1"
  shift
  local -a files=("$@")
  local f sz input_total=0 out_sz=0
  echo "=== Size summary ==="
  printf '  Input parts (%d files):\n' "${#files[@]}"
  for f in "${files[@]}"; do
    print_chapter_file_line '    ' "$f"
    sz=$(file_size_bytes "$f")
    (( input_total += sz ))
  done
  printf '  Input total:  %s\n' "$(format_bytes_human "$input_total")"
  if [[ -f "$output_file" ]]; then
    out_sz=$(file_size_bytes "$output_file")
    printf '  Output:       %s\n' "$(format_bytes_human "$out_sz")"
    printf '                %s\n' "$output_file"
    format_size_comparison_line "$input_total" "$out_sz"
  else
    echo "  Output:       (file missing — merge may have failed)"
  fi
  echo
}

prompt_delete_merged_inputs() {
  local -a files=("$@")
  local f choice
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  echo "Delete the ${#files[@]} merged input chapter file(s)?"
  for f in "${files[@]}"; do
    printf '    %s\n' "${f##*/}"
  done
  echo "  [Y] Yes — delete merged input chapter files"
  echo "  [N] No — keep input files (default)"
  pgm_read_key "Delete inputs? [y/N]: " n
  choice="${REPLY,,}"
  case "$choice" in
    y)
      for f in "${files[@]}"; do
        if rm -f -- "$f"; then
          echo "(PGM) Deleted: ${f##*/}"
        else
          echo "(PGM) Could not delete: $f" >&2
        fi
      done
      ;;
    *)
      echo "(PGM) Input files kept."
      ;;
  esac
  echo
}

run_merge_group() {
  local merger="$1" redo="${2:-0}"
  shift 2
  local -a files=("$@")
  local output_file rc
  output_file=$(group_output_file "${files[@]}")
  if [[ -e "$output_file" ]]; then
    if (( ! redo )); then
      return 0
    fi
    if ! rm -f -- "$output_file"; then
      echo "(PGM) Could not remove existing output: ${output_file}" >&2
      return 1
    fi
    echo "(PGM) Removed existing output for redo merge."
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
    echo
    print_merge_size_summary "$output_file" "${files[@]}"
    prompt_delete_merged_inputs "${files[@]}"
  else
    echo "(PGM) Merge failed (exit ${rc})." >&2
  fi
  return "${rc}"
}

# Sets REPLY to: merge | redo | skip | skip_all | merge_all | quit
# $3 = expected output file (may already exist).
prompt_merge_group_action() {
  local group_num="$1" group_total="$2" output_file="${3:-}"
  local already_merged=0 choice
  REPLY=skip
  if [[ -n "$output_file" && -e "$output_file" ]]; then
    already_merged=1
  fi
  if (( DO_YES )); then
    if (( already_merged )); then
      echo "(PGM) Output already exists, skipping: ${output_file}"
      REPLY=skip
    else
      REPLY=merge
    fi
    return 0
  fi
  if (( MERGE_ALL_REMAINING )); then
    if (( already_merged )); then
      REPLY=skip
    else
      REPLY=merge
    fi
    return 0
  fi
  if (( SKIP_ALL_REMAINING )); then
    REPLY=skip
    return 0
  fi
  if (( ! script_is_run_interactively )); then
    if (( already_merged )); then
      echo "(PGM) Output already exists, skipping: ${output_file}"
    else
      echo "(PGM) Non-interactive: skipping group ${group_num} (use -y to merge all)."
    fi
    REPLY=skip
    return 0
  fi
  while true; do
    if (( already_merged )); then
      echo "  [N] Skip — keep existing output (default)"
      echo "  [R] Redo merge — replace output file"
      echo "  [A] Skip all remaining groups"
      echo "  [Q] Quit"
      pgm_read_key "Already merged — group ${group_num}/${group_total} [N/r/a/q]: " n
      choice="${REPLY,,}"
      case "$choice" in
        ''|n)  REPLY=skip; echo "(PGM) Keeping existing output."; return 0 ;;
        r)     REPLY=redo; return 0 ;;
        a)     REPLY=skip_all; return 0 ;;
        q)     REPLY=quit; return 0 ;;
        *)     echo "(PGM) Unknown choice: ${REPLY}" ;;
      esac
    else
      echo "  [Y] Merge this group (default)"
      echo "  [N] Skip this group"
      echo "  [A] Skip all remaining groups"
      echo "  [M] Merge all remaining groups"
      echo "  [Q] Quit"
      pgm_read_key "Choice for group ${group_num}/${group_total} [Y/n/a/m/q]: " y
      choice="${REPLY,,}"
      case "$choice" in
        ''|y)  REPLY=merge; return 0 ;;
        n)     REPLY=skip; return 0 ;;
        a)     REPLY=skip_all; return 0 ;;
        m)     REPLY=merge_all; return 0 ;;
        q)     REPLY=quit; return 0 ;;
        *)     echo "(PGM) Unknown choice: ${REPLY}" ;;
      esac
    fi
  done
}

show_merge_group_detail() {
  local group_num="$1" group_total="$2"
  shift 2
  local -a files=("$@")
  local f output_file sz input_total=0
  output_file=$(group_output_file "${files[@]}")
  echo "=== Merge group ${group_num} of ${group_total} (${#files[@]} parts) ==="
  for f in "${files[@]}"; do
    print_chapter_file_line '  ' "$f"
    sz=$(file_size_bytes "$f")
    (( input_total += sz ))
  done
  printf '  input total: %s\n' "$(format_bytes_human "$input_total")"
  echo "  → ${output_file}"
  if [[ -e "$output_file" ]]; then
    sz=$(file_size_bytes "$output_file")
    echo "(PGM) Already merged — output: $(format_bytes_human "$sz")"
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
    output_file=$(group_output_file "${files[@]}")
    show_merge_group_detail "$group_num" "$mergeable_total" "${files[@]}"
    prompt_merge_group_action "$group_num" "$mergeable_total" "$output_file"
    action=$REPLY
    case "$action" in
      merge)
        run_merge_group "$merger" 0 "${files[@]}" || rc=$?
        ;;
      redo)
        run_merge_group "$merger" 1 "${files[@]}" || rc=$?
        ;;
      skip)
        if [[ ! -e "$output_file" ]]; then
          echo "(PGM) Skipped group ${group_num}."
        fi
        ;;
      skip_all)
        SKIP_ALL_REMAINING=1
        echo "(PGM) Skipping remaining groups."
        ;;
      merge_all)
        MERGE_ALL_REMAINING=1
        if [[ -e "$output_file" ]]; then
          echo "(PGM) Keeping existing output for group ${group_num}."
        else
          run_merge_group "$merger" 0 "${files[@]}" || rc=$?
        fi
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
