#!/bin/bash

# 2026.05.27 - v. 0.10.3 - merge group detail: INPUT/OUTPUT columns, totals side by side
# 2026.05.27 - v. 0.10.2 - fix json_tmp unbound on RETURN trap under set -o nounset
# 2026.05.27 - v. 0.10.1 - align labelled status lines after timestamp (pgm_log_kv)
# 2026.05.27 - v. 0.10.0 - -u: show installed hash/version, compare GitHub SHA-256, prompt install/replace
# 2026.05.27 - v. 0.9.1 - log prefix: YYYY.MM.DD HH:MM:SS instead of (PGM)
# 2026.05.27 - v. 0.9.0 - print start/finish, processing time, and other/wait time at end
# 2026.05.27 - v. 0.8.9 - already-merged menu: [d] delete input chapters (non-default)
# 2026.05.27 - v. 0.8.8 - output stem timestamp from first chapter file (not last)
# 2026.05.27 - v. 0.8.7 - output name: …_parts_01-04_concat.mp4 from chapter range
# 2026.05.27 - v. 0.8.6 - menu keys: default uppercase, other options lowercase in brackets
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
  -u, --update         Check installed mp4_merge (SHA-256 vs GitHub releases), show
                       version if known, then prompt to install or replace (or use -y).
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
  - If the expected _concat output already exists: skip (default), redo merge [r],
    or delete input chapters [d] (keeps merged output).
  - Output file per group: <first_chapter_stem>_parts_<first>-<last>_concat.mp4
    (timestamp from the first part, e.g. …154511_…_parts_01-04_concat.mp4)
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

mp4_merge_github_curl() {
  local url="$1"
  pgm_processing_begin
  /usr/bin/curl -fsSL --max-time 120 "${url}" 2>/dev/null
  pgm_processing_end
}

fetch_mp4_merge_latest_release_json() {
  mp4_merge_github_curl "https://api.github.com/repos/${MP4_MERGE_REPO}/releases/latest"
}

fetch_mp4_merge_all_releases_json() {
  mp4_merge_github_curl "https://api.github.com/repos/${MP4_MERGE_REPO}/releases?per_page=100"
}

release_tag_from_json() {
  printf '%s\n' "$1" | grep -m1 '"tag_name"' | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
}

# Requires python3. Args: releases_json_file asset_name -> stdout digest hex (no sha256: prefix).
release_asset_digest_from_json() {
  local json_file="$1" asset="$2"
  python3 - "$asset" "$json_file" <<'PY'
import json, sys
asset, path = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
for a in data.get("assets") or []:
    if a.get("name") == asset:
        d = (a.get("digest") or "").strip()
        if d.startswith("sha256:"):
            d = d[7:]
        print(d.lower())
        break
PY
}

# Requires python3. Args: releases_json_file asset_name sha256_hex -> stdout tag_name or nothing.
find_release_tag_for_asset_digest() {
  local json_file="$1" asset="$2" digest="$3"
  python3 - "$asset" "$digest" "$json_file" <<'PY'
import json, sys
asset, want, path = sys.argv[1], sys.argv[2].lower(), sys.argv[3]
with open(path, encoding="utf-8") as f:
    releases = json.load(f)
if isinstance(releases, dict):
    releases = [releases]
for rel in releases:
    tag = rel.get("tag_name") or ""
    for a in rel.get("assets") or []:
        if a.get("name") != asset:
            continue
        d = (a.get("digest") or "").strip().lower()
        if d.startswith("sha256:"):
            d = d[7:]
        if d == want:
            print(tag)
            raise SystemExit(0)
PY
}

file_sha256_hex() {
  local f="$1"
  sha256sum -- "$f" 2>/dev/null | awk '{print tolower($1)}'
}

resolve_mp4_merge_install_path() {
  local asset="$1"
  local dest="${MP4_MERGE_INSTALL_DIR}/${asset}"
  if [[ -f "$dest" ]]; then
    printf '%s\n' "$dest"
    return 0
  fi
  return 1
}

install_mp4_merge_asset() {
  local asset="$1" tag="$2"
  local dest tmp url
  mkdir -p "${MP4_MERGE_INSTALL_DIR}"
  dest="${MP4_MERGE_INSTALL_DIR}/${asset}"
  tmp="${dest}.tmp.$$"
  url="https://github.com/${MP4_MERGE_REPO}/releases/download/${tag}/${asset}"

  pgm_log_kv "Installing" "${asset} (${tag}) ..."
  pgm_log_kv "From" "${url}"
  pgm_log_kv "To" "${dest}"
  echo

  pgm_processing_begin
  if ! /usr/bin/curl -fsSL --max-time 600 -o "${tmp}" "${url}"; then
    pgm_processing_end
    rm -f "${tmp}"
    echo "$(pgm_ts) Download failed." >&2
    return 1
  fi
  pgm_processing_end
  chmod 755 "${tmp}"
  mv -f "${tmp}" "${dest}"

  if [[ "${asset}" != mp4_merge ]]; then
    ln -sf "${asset}" "${MP4_MERGE_INSTALL_DIR}/mp4_merge"
  fi

  local new_hash
  new_hash=$(file_sha256_hex "$dest")
  pgm_log_kv "Installed path" "${dest}"
  pgm_log_kv "SHA-256" "${new_hash}  (${tag})"
  if [[ -x "${dest}" ]]; then
    echo "$(pgm_ts) $(file -b "${dest}" 2>/dev/null || echo 'binary ready')"
  fi
  return 0
}

# Sets REPLY to: install | keep | quit
prompt_mp4_merge_update_action() {
  local state="$1"
  REPLY=keep
  if (( DO_YES )); then
    case "$state" in
      missing|outdated|unknown) REPLY=install ;;
      latest) REPLY=keep ;;
    esac
    return 0
  fi
  if (( ! script_is_run_interactively )); then
    case "$state" in
      missing|outdated|unknown) REPLY=install ;;
      latest)
        echo "$(pgm_ts) Already on latest release; skipping download (use -y only for merge mode)."
        REPLY=keep
        ;;
    esac
    return 0
  fi
  local choice
  while true; do
    case "$state" in
      missing)
        echo "  [Y] Download and install (default)"
        echo "  [n] Cancel"
        echo "  [q] Quit"
        pgm_read_key "mp4_merge not installed — [Y/n/q]: " y
        ;;
      latest)
        echo "  [N] Keep current install (default)"
        echo "  [y] Re-download and replace anyway"
        echo "  [q] Quit"
        pgm_read_key "Already on latest release — [N/y/q]: " n
        ;;
      outdated)
        echo "  [Y] Replace with latest release (default)"
        echo "  [n] Keep current install"
        echo "  [q] Quit"
        pgm_read_key "Update available — [Y/n/q]: " y
        ;;
      unknown)
        echo "  [Y] Replace with latest release from GitHub (default)"
        echo "  [n] Keep current file"
        echo "  [q] Quit"
        pgm_read_key "Installed hash unknown on GitHub — [Y/n/q]: " y
        ;;
    esac
    choice="${REPLY,,}"
    case "$state:$choice" in
      missing:''|missing:y) REPLY=install; return 0 ;;
      missing:n)           REPLY=keep; echo "$(pgm_ts) Install cancelled."; return 0 ;;
      latest:''|latest:n)  REPLY=keep; return 0 ;;
      latest:y)            REPLY=install; return 0 ;;
      outdated:''|outdated:y) REPLY=install; return 0 ;;
      outdated:n)          REPLY=keep; echo "$(pgm_ts) Keeping current install."; return 0 ;;
      unknown:''|unknown:y) REPLY=install; return 0 ;;
      unknown:n)           REPLY=keep; echo "$(pgm_ts) Keeping current file."; return 0 ;;
      *:q)                 REPLY=quit; return 0 ;;
      *)                   echo "$(pgm_ts) Unknown choice: ${REPLY}" ;;
    esac
  done
}

update_mp4_merge() {
  local asset tag dest install_path local_hash local_tag latest_json releases_json
  local latest_tag latest_digest json_tmp releases_tmp state

  check_if_installed curl
  if ! command -v python3 >/dev/null 2>&1; then
    echo "$(pgm_ts) python3 is required for release hash lookup (install python3)." >&2
    return 1
  fi
  if ! command -v sha256sum >/dev/null 2>&1; then
    echo "$(pgm_ts) sha256sum is required to verify mp4_merge binaries." >&2
    return 1
  fi

  if ! asset=$(detect_mp4_merge_asset); then
    echo "$(pgm_ts) Unsupported OS/arch for mp4_merge: $(uname -s) $(uname -m)" >&2
    return 1
  fi

  json_tmp=$(mktemp)
  releases_tmp=$(mktemp)
  # Embed paths when trap is set: on RETURN, locals are gone under nounset.
  trap "rm -f -- $(printf '%q' "$json_tmp") $(printf '%q' "$releases_tmp")" RETURN

  latest_json=$(fetch_mp4_merge_latest_release_json) || {
    echo "$(pgm_ts) Failed to fetch latest release from GitHub." >&2
    return 1
  }
  printf '%s' "$latest_json" >"${json_tmp}"
  latest_tag=$(release_tag_from_json "$latest_json")
  latest_digest=$(release_asset_digest_from_json "${json_tmp}" "${asset}")
  if [[ -z "$latest_tag" || -z "$latest_digest" ]]; then
    echo "$(pgm_ts) Could not read latest release metadata for ${asset}." >&2
    return 1
  fi

  releases_json=$(fetch_mp4_merge_all_releases_json) || {
    echo "$(pgm_ts) Failed to fetch release list from GitHub." >&2
    return 1
  }
  printf '%s' "$releases_json" >"${releases_tmp}"

  pgm_log_kv "Machine asset" "${asset}"
  pgm_log_kv "Install directory" "${MP4_MERGE_INSTALL_DIR}"
  pgm_log_kv "Latest on GitHub" "${latest_tag}"
  pgm_log_kv "Latest SHA-256" "${latest_digest}"
  echo

  if install_path=$(resolve_mp4_merge_install_path "$asset"); then
    local_hash=$(file_sha256_hex "$install_path")
    local_tag=$(find_release_tag_for_asset_digest "${releases_tmp}" "${asset}" "${local_hash}" 2>/dev/null || true)
    pgm_log_kv "Installed file" "${install_path}"
    pgm_log_kv "Installed SHA-256" "${local_hash}"
    if [[ -n "$local_tag" ]]; then
      pgm_log_kv "Installed version" "${local_tag}  (matched GitHub release by hash)"
    else
      pgm_log_kv "Installed version" "unknown  (hash not found in GitHub releases)"
    fi
    pgm_log_kv "Installed size" "$(format_bytes_human "$(file_size_bytes "$install_path")")"
    echo
    if [[ "$local_hash" == "$latest_digest" ]]; then
      state=latest
    elif [[ -n "$local_tag" ]]; then
      state=outdated
    else
      state=unknown
    fi
  else
    pgm_log_kv "Installed file" "not found"
    echo
    state=missing
  fi

  prompt_mp4_merge_update_action "$state"
  case "$REPLY" in
    install)
      install_mp4_merge_asset "$asset" "$latest_tag"
      return $?
      ;;
    keep)
      pgm_log_kv "Action" "Keeping current install."
      return 0
      ;;
    quit)
      echo "$(pgm_ts) Quit."
      return 0
      ;;
  esac
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
PGM_SCRIPT_START_NS=""
PGM_PROCESSING_SEC=0
PGM_PROCESSING_SLICE_START=""

pgm_ts() {
  date '+%Y.%m.%d %H:%M:%S'
}

# Timestamp + fixed-width label + value (labels align in status blocks).
pgm_log_kv() {
  local label="$1"
  shift
  printf '%s %-*s  %s\n' "$(pgm_ts)" 26 "${label}:" "$*"
}

pgm_time_now_ns() {
  date +%s.%N 2>/dev/null || date +%s
}

pgm_record_script_start() {
  PGM_SCRIPT_START_NS=$(pgm_time_now_ns)
  PGM_PROCESSING_SEC=0
}

pgm_processing_begin() {
  PGM_PROCESSING_SLICE_START=$(pgm_time_now_ns)
}

pgm_processing_end() {
  local t_end
  t_end=$(pgm_time_now_ns)
  PGM_PROCESSING_SEC=$(awk -v acc="${PGM_PROCESSING_SEC:-0}" -v t0="${PGM_PROCESSING_SLICE_START}" -v t1="${t_end}" \
    'BEGIN { printf "%.6f", acc + (t1 - t0) }')
}

pgm_format_wall_clock() {
  local ns="$1"
  date -d "@${ns%.*}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null \
    || date -r "${ns%.*}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null \
    || printf '%s\n' "${ns%.*}"
}

format_duration_sec() {
  local sec="$1"
  awk -v s="${sec}" 'BEGIN {
    if (s < 0) s = 0
    h = int(s / 3600)
    m = int((s - h * 3600) / 60)
    x = s - h * 3600 - m * 60
    if (h > 0) printf "%dh %02dm %05.2fs", h, m, x
    else if (m > 0) printf "%dm %05.2fs", m, x
    else printf "%.2f s", s
  }'
}

print_pgm_timing_summary() {
  local end_ns total_sec wait_sec
  [[ -n "${PGM_SCRIPT_START_NS}" ]] || return 0
  end_ns=$(pgm_time_now_ns)
  total_sec=$(awk -v s0="${PGM_SCRIPT_START_NS}" -v s1="${end_ns}" 'BEGIN { printf "%.6f", s1 - s0 }')
  wait_sec=$(awk -v t="${total_sec}" -v p="${PGM_PROCESSING_SEC:-0}" \
    'BEGIN { w = t - p; if (w < 0) w = 0; printf "%.6f", w }')
  echo
  echo "$(pgm_ts) --- Timing ---"
  pgm_log_kv "Started" "$(pgm_format_wall_clock "${PGM_SCRIPT_START_NS}")"
  pgm_log_kv "Finished" "$(date '+%Y.%m.%d %H:%M:%S')"
  pgm_log_kv "Total wall time" "$(format_duration_sec "${total_sec}")"
  pgm_log_kv "Processing time" "$(format_duration_sec "${PGM_PROCESSING_SEC:-0}")  (merges, downloads)"
  pgm_log_kv "Other/wait time" "$(format_duration_sec "${wait_sec}")  (prompts, startup delay, overhead)"
  echo
}

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

# One line: part label (if any), basename, size (no trailing newline).
chapter_file_summary_line() {
  local f="$1"
  local base="${f##*/}" part sz
  sz=$(file_size_bytes "$f")
  if part=$(chapter_part_from_basename "$base" 2>/dev/null); then
    printf 'part %02d  %s  %s' "$part" "$base" "$(format_bytes_human "$sz")"
  else
    printf '%s  %s' "$base" "$(format_bytes_human "$sz")"
  fi
}

# One line: part label (if any), basename, size.
print_chapter_file_line() {
  local indent="$1" f="$2"
  printf '%s%s\n' "$indent" "$(chapter_file_summary_line "$f")"
}

# INPUT / OUTPUT two-column block for one merge group.
print_merge_group_io_block() {
  local output_file="$1"
  shift
  local -a files=("$@")
  local f i col=76 len=0 input_total=0 out_sz=0
  local -a in_lines=()
  local input_total_s output_total_s output_note sep_in sep_out

  for f in "${files[@]}"; do
    in_lines+=("$(chapter_file_summary_line "$f")")
    sz=$(file_size_bytes "$f")
    (( input_total += sz ))
    if ((${#in_lines[-1]} > len)); then
      len=${#in_lines[-1]}
    fi
  done
  if (( len + 2 > col )); then
    col=$(( len + 2 ))
  fi
  if (( col > 100 )); then
    col=100
  fi

  if [[ -e "$output_file" ]]; then
    out_sz=$(file_size_bytes "$output_file")
    output_total_s="$(format_bytes_human "$out_sz")"
    output_note="(on disk)"
  else
    output_total_s="—"
    output_note="(not created yet)"
  fi
  input_total_s="$(format_bytes_human "$input_total")"

  sep_in=$(printf '%*s' 60 '' | tr ' ' '-')
  sep_out=$(printf '%*s' 44 '' | tr ' ' '-')

  printf '  %-*s  %s\n' "$col" "INPUT (${#files[@]} parts)" "OUTPUT"
  printf '  %-*s  %s\n' "$col" "$sep_in" "$sep_out"
  for i in "${!in_lines[@]}"; do
    if (( i == 0 )); then
      printf '  %-*s  %s\n' "$col" "${in_lines[$i]}" "${output_file}"
    else
      printf '  %-*s\n' "$col" "${in_lines[$i]}"
    fi
  done
  printf '  %-*s  %s\n' "$col" "$sep_in" "$sep_out"
  printf '  %-*s  Total: %s  %s\n' "$col" "Total: ${input_total_s}" "${output_total_s}  ${output_note}"
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
    echo "$(pgm_ts) Removed incomplete output: ${VIDEO_MERGE_OUT_FILE}"
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
  echo "$(pgm_ts) Chapter plan in $(pwd):"
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
      local out_name
      out_name=$(group_output_file "${files[@]}")
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
  echo "$(pgm_ts) Summary: ${mergeable} merge group(s), ${standalone} standalone file(s)."
  echo
}

group_output_file() {
  local -a files=("$@")
  local f base stem part min_part= max_part= got_part=0 suffix_proxy=
  for f in "${files[@]}"; do
    base="${f##*/}"
    if part=$(chapter_part_from_basename "$base" 2>/dev/null); then
      got_part=1
      if [[ -z "$min_part" ]] || (( part < min_part )); then
        min_part=$part
      fi
      if [[ -z "$max_part" ]] || (( part > max_part )); then
        max_part=$part
      fi
    fi
  done
  base="${files[0]##*/}"
  stem="${base%.*}"
  if (( got_part )) && [[ "$stem" =~ ^(.*)_part_[0-9]{2}(_Proxy)?$ ]]; then
    suffix_proxy="${BASH_REMATCH[2]}"
    printf '%s_parts_%02d-%02d%s_concat.mp4\n' \
      "${BASH_REMATCH[1]}" "$min_part" "$max_part" "$suffix_proxy"
    return 0
  fi
  printf '%s_concat.mp4\n' "$stem"
}

print_merge_size_summary() {
  local output_file="$1"
  shift
  local -a files=("$@")
  local f input_total=0 out_sz=0
  for f in "${files[@]}"; do
    sz=$(file_size_bytes "$f")
    (( input_total += sz ))
  done
  echo "=== Size summary ==="
  print_merge_group_io_block "$output_file" "${files[@]}"
  if [[ -f "$output_file" ]]; then
    out_sz=$(file_size_bytes "$output_file")
    format_size_comparison_line "$input_total" "$out_sz"
  else
    echo "  $(pgm_ts) Output file missing — merge may have failed."
  fi
  echo
}

prompt_delete_merged_inputs() {
  local context="${1:-after_merge}"
  shift
  local -a files=("$@")
  local f choice
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  if [[ "$context" == already_merged ]]; then
    echo "Delete ${#files[@]} input chapter file(s)? (merged output will be kept)"
  else
    echo "Delete the ${#files[@]} merged input chapter file(s)?"
  fi
  for f in "${files[@]}"; do
    printf '    %s\n' "${f##*/}"
  done
  echo "  [y] Yes — delete merged input chapter files"
  echo "  [N] No — keep input files (default)"
  pgm_read_key "Delete inputs? [y/N]: " n
  choice="${REPLY,,}"
  case "$choice" in
    y)
      for f in "${files[@]}"; do
        if rm -f -- "$f"; then
          echo "$(pgm_ts) Deleted: ${f##*/}"
        else
          echo "$(pgm_ts) Could not delete: $f" >&2
        fi
      done
      ;;
    *)
      echo "$(pgm_ts) Input files kept."
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
      echo "$(pgm_ts) Could not remove existing output: ${output_file}" >&2
      return 1
    fi
    echo "$(pgm_ts) Removed existing output for redo merge."
  fi
  VIDEO_MERGE_OUT_FILE="${output_file}"
  echo "$(pgm_ts) Merging ${#files[@]} chapter(s) → ${output_file}"
  trap video_merge_ctrl_c INT
  pgm_processing_begin
  "${merger}" "${files[@]}" --out "${output_file}"
  rc=$?
  pgm_processing_end
  trap ctrl_c INT
  VIDEO_MERGE_OUT_FILE=""
  if (( rc == 0 )); then
    echo "$(pgm_ts) Done: ${output_file}"
    echo
    print_merge_size_summary "$output_file" "${files[@]}"
    prompt_delete_merged_inputs after_merge "${files[@]}"
  else
    echo "$(pgm_ts) Merge failed (exit ${rc})." >&2
  fi
  return "${rc}"
}

# Sets REPLY to: merge | redo | skip | skip_all | merge_all | delete_inputs | quit
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
      echo "$(pgm_ts) Output already exists, skipping: ${output_file}"
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
      echo "$(pgm_ts) Output already exists, skipping: ${output_file}"
    else
      echo "$(pgm_ts) Non-interactive: skipping group ${group_num} (use -y to merge all)."
    fi
    REPLY=skip
    return 0
  fi
  while true; do
    if (( already_merged )); then
      echo "  [N] Skip — keep output and input files (default)"
      echo "  [r] Redo merge — replace output file"
      echo "  [d] Delete input chapter files — keep merged output"
      echo "  [a] Skip all remaining groups"
      echo "  [q] Quit"
      pgm_read_key "Already merged — group ${group_num}/${group_total} [N/r/d/a/q]: " n
      choice="${REPLY,,}"
      case "$choice" in
        ''|n)  REPLY=skip; pgm_log_kv "Action" "Keeping existing output and inputs."; return 0 ;;
        r)     REPLY=redo; return 0 ;;
        d)     REPLY=delete_inputs; return 0 ;;
        a)     REPLY=skip_all; return 0 ;;
        q)     REPLY=quit; return 0 ;;
        *)     echo "$(pgm_ts) Unknown choice: ${REPLY}" ;;
      esac
    else
      echo "  [Y] Merge this group (default)"
      echo "  [n] Skip this group"
      echo "  [a] Skip all remaining groups"
      echo "  [m] Merge all remaining groups"
      echo "  [q] Quit"
      pgm_read_key "Choice for group ${group_num}/${group_total} [Y/n/a/m/q]: " y
      choice="${REPLY,,}"
      case "$choice" in
        ''|y)  REPLY=merge; return 0 ;;
        n)     REPLY=skip; return 0 ;;
        a)     REPLY=skip_all; return 0 ;;
        m)     REPLY=merge_all; return 0 ;;
        q)     REPLY=quit; return 0 ;;
        *)     echo "$(pgm_ts) Unknown choice: ${REPLY}" ;;
      esac
    fi
  done
}

show_merge_group_detail() {
  local group_num="$1" group_total="$2"
  shift 2
  local -a files=("$@")
  local output_file
  output_file=$(group_output_file "${files[@]}")
  echo
  echo "=== Merge group ${group_num} of ${group_total} (${#files[@]} parts) ==="
  print_merge_group_io_block "$output_file" "${files[@]}"
  echo
}

do_merge() {
  local merger rc=0 group_num=0 mergeable_total=0
  local blob action -a files=() mergeable_blobs=()
  merger=$(find_merger) || {
    echo "$(pgm_ts) mp4_merge not found in . or ${SCRIPT_DIR}/" >&2
    echo "$(pgm_ts) Run: $(basename "$0") -u" >&2
    echo "$(pgm_ts) Or set MP4_MERGE_BIN=/path/to/mp4_merge" >&2
    return 1
  }

  shopt -s nullglob nocaseglob
  local mp4_files=( *.mp4 )
  shopt -u nocaseglob

  if (( ${#mp4_files[@]} == 0 )); then
    echo "$(pgm_ts) No *.mp4 files in $(pwd)" >&2
    return 1
  fi

  local sorted_mp4=()
  mapfile -t sorted_mp4 < <(printf '%s\n' "${mp4_files[@]}" | LC_ALL=C sort)

  build_chapter_groups "${sorted_mp4[@]}"
  if (( ${#GROUP_BLOBS[@]} == 0 )); then
    echo "$(pgm_ts) No chapter MP4s to process in $(pwd)" >&2
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
    echo "$(pgm_ts) No multi-part chapter groups to merge."
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
      delete_inputs)
        if [[ -e "$output_file" ]]; then
          prompt_delete_merged_inputs already_merged "${files[@]}"
        else
          echo "$(pgm_ts) No merged output for group ${group_num}; cannot delete inputs here." >&2
        fi
        ;;
      skip)
        if [[ ! -e "$output_file" ]]; then
          echo "$(pgm_ts) Skipped group ${group_num}."
        fi
        ;;
      skip_all)
        SKIP_ALL_REMAINING=1
        echo "$(pgm_ts) Skipping remaining groups."
        ;;
      merge_all)
        MERGE_ALL_REMAINING=1
        if [[ -e "$output_file" ]]; then
          echo "$(pgm_ts) Keeping existing output for group ${group_num}."
        else
          run_merge_group "$merger" 0 "${files[@]}" || rc=$?
        fi
        ;;
      quit)
        echo "$(pgm_ts) Quit at group ${group_num}."
        return "${rc}"
        ;;
    esac
    echo
  done

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
      echo "$(pgm_ts) Unknown argument: $1" >&2
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

pgm_record_script_start

if (( DO_UPDATE )); then
  update_mp4_merge
  kod_powrotu=$?
  print_pgm_timing_summary
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

do_merge
kod_powrotu=$?

print_pgm_timing_summary

. /root/bin/_script_footer.sh

exit "${kod_powrotu}"
