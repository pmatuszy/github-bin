#!/bin/bash
# v. 20260718.093500 - _part_XX: group by camera+session; chain when prev time+duration≈next

# 2026.07.18 - v. 0.15.12 - _part_XX: group by camera+middle (not full stem); consecutive parts merge when filename times chain (prev+duration≈next)
# 2026.07.15 - v. 0.15.10 - merge outputs: …_concat_parts_01-NN.mp4 (concat before parts)
# 2026.07.15 - v. 0.15.9 - size-split output: …_parts_01-NN_concat.mp4 (chapter count), fix middle/camera join
# 2026.07.15 - v. 0.15.8 - letter chapters (…BLACKa/b/c or …200322a/b): merge without ~4 GB size gate
# 2026.07.15 - v. 0.15.7 - size-split: ~6:49 (409s) chapter duration for all GOPRO* (not only GOPRO7)
# 2026.07.15 - v. 0.15.6 - size-split: accept chapter letter on camera token (GOPRO10_BLACKa)
# 2026.07.15 - v. 0.15.5 - size-split: accept YYYYMMDD_HHMMSSa letter suffixes (rename disambiguation)
# 2026.06.24 - v. 0.15.4 - _part_XX from part_01: merge without ~4 GB check; size rules only for orphan tails (part_02+)
# 2026.06.23 - v. 0.15.3 - fix rest_out circular nameref: pass caller array name into nested helpers
# 2026.06.23 - v. 0.15.2 - parse rename.sh *_parts_NN-NN_concat for orphan listing; clearer orphan output
# 2026.06.23 - v. 0.15.1 - fix _rest nameref loop; multiline skip message for invalid _part_XX groups
# 2026.06.23 - v. 0.15.0 - _part_XX groups: consecutive parts only; require ~4 GB / ~12 GB chapters (same as size-split)
# 2026.06.23 - v. 0.14.2 - seam preview: ask per seam with clearer play message; repeat then next seam
# 2026.06.23 - v. 0.14.1 - seam preview: pass --start/--length as separate args; fix repeat prompt arithmetic
# 2026.06.23 - v. 0.14.0 - post-merge: merge boundary times in output; optional terminal seam preview
# 2026.06.13 - v. 0.13.4 - size-split: recognize ~12 GB chapters (in addition to ~4 GB); same tier per group
# 2026.06.13 - v. 0.13.3 - size-split: group rename.sh-style names (same session label, different per-chapter timestamps)
# 2026.06.02 - v. 0.13.2 - rename NO_STARTUP_DELAY to --no_startup_delay
# 2026.06.01 - v. 0.13.1 - fix: _part_NN chapter grouping mixed proxy with normal parts; group by stem+variant (key-based) so originals and proxies never merge together
# 2026.05.31 - v. 0.13.0 - detect/group raw GoPro chapter files (GXccnnnn[_Proxy].MP4); merge originals & proxies separately
# 2026.05.31 - v. 0.12.3 - -v/--version print a short version banner; also show the banner at startup
# 2026.05.31 - v. 0.12.2 - merge mode: when mp4_merge is missing, show install info then offer to install it (Y/n/q)
# 2026.05.27 - v. 0.12.1 - prompt timeout: wait forever by default; --read-timeout or PGM_READ_TIMEOUT
# 2026.05.27 - v. 0.12.0 - group same-timestamp GoPro clips (_GOPRO*_GX chapter suffix, ~4GB)
# 2026.05.27 - v. 0.11.10 - [q] on delete-inputs prompt quits script (no next merge group)
# 2026.05.27 - v. 0.11.9 - size-split output name: timestamp from first file only (not last)
# 2026.05.27 - v. 0.11.8 - show ffprobe duration per input file in merge group display
# 2026.05.27 - v. 0.11.7 - size-split groups: next chapter time ≈ prev time + prev duration
# 2026.05.27 - v. 0.11.6 - size-split output: copy middle label verbatim from first input name
# 2026.05.27 - v. 0.11.5 - robust S29_-_dermatolog slug in size-split output filenames
# 2026.05.27 - v. 0.11.4 - size-split output: session label (dermatolog) in name + MP4 metadata
# 2026.05.27 - v. 0.11.3 - size-split: flexible GoPro names (_-_ labels, GOPRO7 suffix)
# 2026.05.27 - v. 0.11.2 - GoPro7 size-split: ~4GB and/or ~6:49 (409s) chapter duration
# 2026.05.27 - v. 0.11.1 - size-split: trust ~4GB size; ffprobe only rejects clearly short clips
# 2026.05.27 - v. 0.11.0 - detect size-split GoPro clips (~4GB, ~8:30-9:00) without _part_XX names
# 2026.05.27 - v. 0.10.9 - install mp4_merge to /usr/local/bin; remove PATH/cwd/script copies
# 2026.05.27 - v. 0.10.8 - default mp4_merge install /usr/local/bin; prompt to move from cwd
# 2026.05.27 - v. 0.10.7 - list *_concat outputs with no (or incomplete) input chapters in folder
# 2026.05.27 - v. 0.10.6.1 - fix invalid "local blob action -a" in do_merge (bash nounset)
# 2026.05.27 - v. 0.10.6 - INPUT block then OUTPUT block (stacked, not side by side)
# 2026.05.27 - v. 0.10.5 - one line per chapter; align size columns at '|' (fixed-width bytes/kB/MB)
# 2026.05.27 - v. 0.10.4 - fixed INPUT/OUTPUT columns: basename and size on separate lines
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
Usage: $(basename "$0") [-h|--help] [-u|--update] [-v|--version] [-y|--yes]
       [--read-timeout SEC] [--seam-before SEC] [--seam-after SEC]
       [--no_startup_delay]

Merge chapter MP4 files in the current directory (e.g. GoPro splits) into one
file using mp4_merge from https://github.com/gyroflow/mp4-merge

Options:
  -h, --help           Show this help and exit.
  -u, --update         Check installed mp4_merge (SHA-256 vs GitHub releases), show
                       version if known, then prompt to install or replace (or use -y).
  -v, --version        Print script version and exit.
  -y, --yes            Merge every detected multi-part group without prompts (for cron).
  --read-timeout SEC   Single-key prompt timeout in seconds (0 = wait forever).
                       Default: wait forever. Env: PGM_READ_TIMEOUT (e.g. 300).
  --seam-before SEC    Terminal seam preview: seconds before each join (default 2).
                       Env: PGM_SEAM_PREVIEW_BEFORE.
  --seam-after SEC     Terminal seam preview: seconds after each join (default 0).
                       Env: PGM_SEAM_PREVIEW_AFTER.
  --no_startup_delay   Skip random startup delay when run non-interactively (see
                       _script_header.sh).

Merge behaviour (no options):
  - Collects *.mp4 in the current working directory (case-insensitive), except
    existing *_concat.mp4 outputs.
  - Detects GoPro-style chapter sequences (_part_01, _part_02, …). Consecutive part
    numbers only. Same stem (one start time in the name) always groups; when each part
    has its own leading timestamp, parts merge only if times chain (previous start +
    duration ≈ next start, same as size-split). Runs starting at part_01 merge as-is;
    runs starting after part_01 (orphan tails) need full ~4 GB / ~12 GB chapters.
  - Also groups clips without _part_XX names when they look like fixed-size splits:
    same session label, ~4 GB or ~12 GB chapters (~6:49 or longer per chapter); filename times
    that chain, or the same YYYYMMDD_HHMMSS with GX chapter suffixes
    (e.g. …_GOPRO10_BLACK_GX013496.MP4). After rename.sh, consecutive chapters may differ
    only in the leading timestamp and share the same middle label, or share one start time with
    a trailing chapter letter on the time (…_200322a_…) or camera token (…_GOPRO10_BLACKa.MP4).
    Letter runs a,b,c… on the same timestamp merge like part_01 chapters (any file size).
  - Shows each multi-part group (with file sizes) and asks whether to merge
    (single-key Y/N/A/M/Q, no Enter — like rename.sh).
  - After a successful merge: merge-boundary times in the output timeline (where each
    chapter join occurs), size summary, optional per-seam terminal preview (asked one
    seam at a time), and optional deletion of the source chapter files (single-key Y/N).
  - If the expected _concat output already exists: skip (default), redo merge [r],
    preview merge seams [p], or delete input chapters [d] (keeps merged output).
  - Output file per group: <first_chapter_stem>_concat_parts_<first>-<last>.mp4
    (timestamp from the first part; size-split/letter groups use 01-<N> for chapter count,
    e.g. …_GOPRO10_BLACK_concat_parts_01-06.mp4). Legacy …_parts_*-*_concat.mp4 still recognized.
  - Other single files are listed as standalone; probable size-split sets are merge candidates.
  - Lists merged *_concat files when matching input chapters are not in the folder.

mp4_merge lookup (merge mode):
  1. MP4_MERGE_BIN if set and executable
  2. /usr/local/bin (or MP4_MERGE_INSTALL_DIR): mp4_merge-linux64, …, mp4_merge
  3. ./mp4_merge-linux64, … in the current directory (interactive: install to /usr/local/bin,
     remove other copies on PATH and in the script directory)
  4. Same names in the script directory

Environment:
  MP4_MERGE_BIN           Path to mp4_merge binary (overrides search paths).
  MP4_MERGE_INSTALL_DIR   Target directory for -u/--update (default: /usr/local/bin).
  MP4_MERGE_REPO          GitHub repo for releases (default: gyroflow/mp4-merge).
  PGM_READ_TIMEOUT        Seconds per single-key prompt; unset or 0 = wait forever.
                          Overridden by --read-timeout.
  PGM_SEAM_PREVIEW_BEFORE Seconds before each merge point in terminal preview (default: 2).
  PGM_SEAM_PREVIEW_AFTER  Seconds after each merge point in terminal preview (default: 0).

Examples:
  $(basename "$0") -u
      Download mp4_merge into /usr/local/bin (recommended system location).

  cd /path/to/chapters && $(basename "$0")
      Merge all chapter MP4s in that folder.

  $(basename "$0") -y --no_startup_delay
      Merge all chapter groups without prompts (cron).

  $(basename "$0") --no_startup_delay
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
  mp4_merge_collect_extras "$(mp4_merge_abs_path "$dest" 2>/dev/null || printf '%s' "$dest")"
  mp4_merge_remove_extras "$(mp4_merge_abs_path "$dest" 2>/dev/null || printf '%s' "$dest")"
  return 0
}

MP4_MERGE_ASSET_NAMES=(
  mp4_merge-linux64
  mp4_merge-linux-arm64
  mp4_merge-linux32
  mp4_merge-linux
  mp4_merge
)
MP4_MERGE_EXTRA_PATHS=()

mp4_merge_abs_path() {
  local p="$1"
  [[ -e "$p" || -L "$p" ]] || return 1
  if readlink -f -- "$p" &>/dev/null; then
    readlink -f -- "$p"
    return 0
  fi
  if command -v realpath >/dev/null 2>&1 && realpath -- "$p" &>/dev/null; then
    realpath -- "$p"
    return 0
  fi
  local dir base
  base=$(basename -- "$p")
  dir=$(cd "$(dirname -- "$p")" 2>/dev/null && pwd -P) || return 1
  printf '%s/%s\n' "$dir" "$base"
}

mp4_merge_dir_is_system_install() {
  local dir="$1" abs
  [[ -n "$dir" ]] || return 1
  if abs=$(mp4_merge_abs_path "${dir%/}/." 2>/dev/null); then
    dir="$abs"
  else
    dir="${dir%/}"
  fi
  [[ "$dir" == "${MP4_MERGE_INSTALL_DIR}" || "$dir" == "${MP4_MERGE_SYSTEM_DIR}" ]]
}

mp4_merge_path_in_system_dir() {
  local path="$1" dir abs
  abs=$(mp4_merge_abs_path "$path") || return 1
  dir=$(dirname -- "$abs")
  mp4_merge_dir_is_system_install "$dir"
}

mp4_merge_extra_already_listed() {
  local candidate="$1" existing
  for existing in "${MP4_MERGE_EXTRA_PATHS[@]}"; do
    [[ "$existing" == "$candidate" ]] && return 0
  done
  return 1
}

mp4_merge_extra_add() {
  local f="$1" skip_abs="${2:-}"
  local abs
  [[ -e "$f" || -L "$f" ]] || return 0
  abs=$(mp4_merge_abs_path "$f") || return 0
  mp4_merge_path_in_system_dir "$abs" && return 0
  [[ -n "$skip_abs" && "$abs" == "$skip_abs" ]] && return 0
  mp4_merge_extra_already_listed "$abs" && return 0
  MP4_MERGE_EXTRA_PATHS+=("$abs")
}

# Collect mp4_merge binaries outside MP4_MERGE_INSTALL_DIR (PATH, cwd, script dir).
mp4_merge_collect_extras() {
  local skip_abs="${1:-}"
  local dir name p path_dirs
  MP4_MERGE_EXTRA_PATHS=()
  if [[ -n "${PATH:-}" ]]; then
    IFS=':' read -r -a path_dirs <<< "$PATH"
    for dir in "${path_dirs[@]}"; do
      [[ -n "$dir" ]] || continue
      [[ -d "$dir" ]] || continue
      mp4_merge_dir_is_system_install "$dir" && continue
      for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
        mp4_merge_extra_add "${dir}/${name}" "$skip_abs"
      done
    done
  fi
  if [[ -n "${SCRIPT_DIR:-}" ]] && ! mp4_merge_dir_is_system_install "${SCRIPT_DIR}"; then
    for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
      mp4_merge_extra_add "${SCRIPT_DIR}/${name}" "$skip_abs"
    done
  fi
  for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
    mp4_merge_extra_add "./${name}" "$skip_abs"
  done
}

mp4_merge_print_extra_locations() {
  local p
  (( ${#MP4_MERGE_EXTRA_PATHS[@]} > 0 )) || return 0
  echo "  Other copies (will be removed when installed to ${MP4_MERGE_INSTALL_DIR}):"
  for p in "${MP4_MERGE_EXTRA_PATHS[@]}"; do
    printf '    %s\n' "$p"
  done
}

mp4_merge_remove_extras() {
  local keep_abs="${1:-}"
  local p dir d removed=0
  local -a rm_dirs=()
  for p in "${MP4_MERGE_EXTRA_PATHS[@]}"; do
    [[ -n "$keep_abs" && "$p" == "$keep_abs" ]] && continue
    [[ -e "$p" || -L "$p" ]] || continue
    dir=$(dirname -- "$p")
    if rm -f -- "$p"; then
      pgm_log_kv "Removed" "$p"
      (( removed++ )) || true
      rm_dirs+=("$dir")
    else
      echo "$(pgm_ts) Could not remove: ${p}" >&2
    fi
  done
  for dir in "${rm_dirs[@]}"; do
    mp4_merge_dir_is_system_install "$dir" && continue
    for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
      [[ -e "${dir}/${name}" || -L "${dir}/${name}" ]] && continue 2
    done
    if [[ -e "${dir}/mp4_merge" || -L "${dir}/mp4_merge" ]]; then
      if rm -f -- "${dir}/mp4_merge"; then
        pgm_log_kv "Removed" "${dir}/mp4_merge"
        (( removed++ )) || true
      fi
    fi
  done
  (( removed > 0 )) || true
}

mp4_merge_install_dir_writable() {
  local dir="${1:-${MP4_MERGE_INSTALL_DIR}}"
  [[ -n "$dir" ]] || return 1
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" 2>/dev/null || return 1
  fi
  [[ -w "$dir" ]]
}

# Move or copy a local mp4_merge binary into MP4_MERGE_INSTALL_DIR (and symlink mp4_merge).
mp4_merge_install_local_binary() {
  local src="$1"
  local base dest dir
  base=$(basename "$src")
  dest="${MP4_MERGE_INSTALL_DIR}/${base}"
  dir="${MP4_MERGE_INSTALL_DIR}"
  if ! mp4_merge_install_dir_writable "$dir"; then
    echo "$(pgm_ts) Cannot write to ${dir} (try: sudo $(basename "$0") -u)." >&2
    return 1
  fi
  if ! mv -f -- "$src" "$dest" 2>/dev/null; then
    if ! cp -f -- "$src" "$dest"; then
      echo "$(pgm_ts) Failed to install ${base} into ${dir}." >&2
      return 1
    fi
    rm -f -- "$src"
  fi
  chmod 755 "$dest"
  if [[ "$base" != mp4_merge ]]; then
    ln -sf "$base" "${dir}/mp4_merge"
  fi
  pgm_log_kv "Installed path" "${dest}"
  printf '%s\n' "$dest"
  return 0
}

mp4_merge_print_not_found_help() {
  echo "$(pgm_ts) mp4_merge not found." >&2
  echo "$(pgm_ts) Install to ${MP4_MERGE_INSTALL_DIR} (recommended):" >&2
  echo "$(pgm_ts)   $(basename "$0") -u" >&2
  if ! mp4_merge_install_dir_writable "${MP4_MERGE_INSTALL_DIR}" 2>/dev/null; then
    echo "$(pgm_ts)   (directory not writable — use sudo for -u)" >&2
  fi
  echo "$(pgm_ts) Or set MP4_MERGE_BIN=/path/to/mp4_merge" >&2
}

# When mp4_merge is missing, ask whether to download/install it now (reuses update_mp4_merge).
# Returns 0 if the user agreed and the install ran, 1 if declined / quit.
prompt_install_mp4_merge_now() {
  local rc prev_yes

  if (( ! DO_YES )) && (( script_is_run_interactively )); then
    echo
    echo "  [Y] Yes — download and install mp4_merge to ${MP4_MERGE_INSTALL_DIR} (default)"
    echo "  [n] No — do not install"
    echo "  [q] Quit"
    pgm_read_key "Install mp4_merge now? [Y/n/q]: " y
    case "${REPLY,,}" in
      ''|y) ;;
      n) echo "$(pgm_ts) Not installing mp4_merge."; return 1 ;;
      q) echo "$(pgm_ts) Quit."; return 1 ;;
      *) echo "$(pgm_ts) Not installing mp4_merge."; return 1 ;;
    esac
  fi

  # Auto-confirm the update prompt for the missing case (we already asked above).
  prev_yes=$DO_YES
  DO_YES=1
  update_mp4_merge
  rc=$?
  DO_YES=$prev_yes
  return $rc
}

# If merger is outside /usr/local/bin, offer install there and remove PATH/script/cwd copies.
resolve_merger_path_for_merge() {
  local merger="$1"
  local base choice dest dest_abs
  if mp4_merge_path_in_system_dir "$merger"; then
    printf '%s\n' "$merger"
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    printf '%s\n' "$merger"
    return 0
  fi
  if [[ "$merger" == ./* ]]; then
    base="${merger#./}"
    pgm_log_kv "mp4_merge in current directory" "$(pwd)/${base}"
  else
    pgm_log_kv "mp4_merge found outside" "${MP4_MERGE_INSTALL_DIR}" "$merger"
  fi
  echo "  Recommended location: ${MP4_MERGE_INSTALL_DIR}/"
  mp4_merge_collect_extras ""
  mp4_merge_print_extra_locations
  if ! mp4_merge_install_dir_writable "${MP4_MERGE_INSTALL_DIR}"; then
    echo "  (${MP4_MERGE_INSTALL_DIR} is not writable — use sudo $(basename "$0") -u)"
  fi
  while true; do
    echo "  [Y] Install to ${MP4_MERGE_INSTALL_DIR} and remove other copies (default)"
    echo "  [n] Keep using: ${merger}"
    echo "  [q] Quit"
    pgm_read_key "Install mp4_merge to ${MP4_MERGE_INSTALL_DIR}? [Y/n/q]: " y
    choice="${REPLY,,}"
    case "$choice" in
      ''|y)
        dest=$(mp4_merge_install_local_binary "$merger") || return 1
        dest_abs=$(mp4_merge_abs_path "$dest" 2>/dev/null || printf '%s' "$dest")
        mp4_merge_collect_extras "$dest_abs"
        mp4_merge_remove_extras "$dest_abs"
        echo "$(pgm_ts) mp4_merge is now at ${dest}"
        printf '%s\n' "$dest"
        return 0
        ;;
      n)
        printf '%s\n' "$merger"
        return 0
        ;;
      q)
        echo "$(pgm_ts) Quit."
        return 2
        ;;
      *)
        echo "$(pgm_ts) Unknown choice: ${REPLY}"
        ;;
    esac
  done
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
        echo "  [Y] Download and install to ${MP4_MERGE_INSTALL_DIR} (default)"
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
  pgm_log_kv "Install directory" "${MP4_MERGE_INSTALL_DIR}  (recommended: ${MP4_MERGE_SYSTEM_DIR})"
  if ! mp4_merge_install_dir_writable "${MP4_MERGE_INSTALL_DIR}"; then
    echo "$(pgm_ts) Install directory is not writable — run with sudo or set MP4_MERGE_INSTALL_DIR." >&2
  fi
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

find_merger_in_dir() {
  local dir="$1" name
  [[ -n "$dir" ]] || return 1
  for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
    if [[ -x "${dir}/${name}" ]]; then
      printf '%s\n' "${dir}/${name}"
      return 0
    fi
  done
  return 1
}

find_merger() {
  local name
  if [[ -n "${MP4_MERGE_BIN:-}" && -x "${MP4_MERGE_BIN}" ]]; then
    printf '%s\n' "${MP4_MERGE_BIN}"
    return 0
  fi
  find_merger_in_dir "${MP4_MERGE_INSTALL_DIR}" && return 0
  if [[ "${MP4_MERGE_SYSTEM_DIR}" != "${MP4_MERGE_INSTALL_DIR}" ]]; then
    find_merger_in_dir "${MP4_MERGE_SYSTEM_DIR}" && return 0
  fi
  for name in "${MP4_MERGE_ASSET_NAMES[@]}"; do
    if [[ -x "./${name}" ]]; then
      printf '%s\n' "./${name}"
      return 0
    fi
  done
  find_merger_in_dir "${SCRIPT_DIR}" && return 0
  return 1
}

# Set by do_merge; used by trap on Ctrl-C to drop a partial output file.
VIDEO_MERGE_OUT_FILE=""
PGM_READ_TIMEOUT_CLI=0
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

# Apply PGM_READ_TIMEOUT from env (unless --read-timeout set); 0 or unset = wait forever.
pgm_init_read_timeout() {
  if (( PGM_READ_TIMEOUT_CLI )); then
    return 0
  fi
  PGM_READ_TIMEOUT="${PGM_READ_TIMEOUT:--1}"
}

pgm_read_timeout_is_limited() {
  [[ "$PGM_READ_TIMEOUT" =~ ^[0-9]+$ ]] && (( PGM_READ_TIMEOUT > 0 ))
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
  if pgm_read_timeout_is_limited && [[ "$timeout" =~ ^[0-9]+$ ]] && (( timeout > 0 )); then
    read -t "$timeout" -n 1 answer || answer=
  else
    read -n 1 answer || answer=
  fi
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

# Same as format_bytes_human but fixed field widths so '|' columns line up in the terminal.
format_bytes_human_aligned() {
  local bytes="$1"
  awk -v b="$bytes" 'BEGIN {
    printf "%12d bytes | %10.2f kB | %8.2f MB", b, b/1024.0, b/1048576.0
  }'
}

# Seconds from ffprobe as "409.3 s (6:49)" for display.
format_duration_display() {
  local dur="$1"
  [[ -n "$dur" ]] || return 1
  awk -v d="$dur" 'BEGIN {
    m=int(d/60); s=int(d+0.5)%60;
    if (s >= 60) { s -= 60; m += 1 }
    printf "%.1f s (%d:%02d)", d+0, m, s
  }'
}

# Position in merged output as "8min 15s" / "1h 2min 3s".
format_output_timeline_pos() {
  local sec="$1"
  awk -v s="$sec" 'BEGIN {
    if (s < 0) s = 0
    h = int(s / 3600)
    m = int((s - h * 3600) / 60)
    x = int(s + 0.5) % 60
    if (h > 0) printf "%dh %dmin %ds", h, m, x
    else if (m > 0) printf "%dmin %ds", m, x
    else printf "%ds", int(s+0.5)
  }'
}

pgm_valid_seam_seconds() {
  [[ "${1:-}" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

pgm_invalid_seam_seconds() {
  echo "$(pgm_ts) invalid $1: ${2:-<empty>} (use 0 or a non-negative number)" >&2
  exit 1
}

# Fill namerefs: boundary_times[], boundary_left[], boundary_right[] (one entry per join).
merge_compute_boundaries() {
  local -n _out_times=$1
  local -n _out_left=$2
  local -n _out_right=$3
  shift 3
  local -a files=("$@")
  local f dur cumulative=0 i

  _out_times=()
  _out_left=()
  _out_right=()
  (( ${#files[@]} >= 2 )) || return 1

  for (( i = 0; i < ${#files[@]} - 1; i++ )); do
    dur=$(ffprobe_duration_seconds "${files[$i]}") || return 1
    cumulative=$(awk -v c="$cumulative" -v d="$dur" 'BEGIN { printf "%.6f", c + d }')
    _out_times+=( "$cumulative" )
    _out_left+=( "${files[$i]##*/}" )
    _out_right+=( "${files[$i + 1]##*/}" )
  done
  return 0
}

# Preview window around boundary T: [max(0,T-before), T+after].
merge_seam_preview_start_length() {
  local boundary="$1"
  local before="$2"
  local after="$3"
  awk -v t="$boundary" -v b="$before" -v a="$after" 'BEGIN {
    s = t - b; if (s < 0) s = 0
    e = t + a
    printf "%.3f %.3f\n", s, e - s
  }'
}

# Sum of before+after window (e.g. 2 + 0 → 2).
merge_seam_clip_total_seconds() {
  local before="$1" after="$2"
  awk -v b="$before" -v a="$after" 'BEGIN {
    t = b + a
    if (t == int(t)) print int(t)
    else printf "%g", t
  }'
}

pgm_ordinal_seam_label() {
  local n="$1" d u
  case "$n" in
    1) printf '1st' ;;
    2) printf '2nd' ;;
    3) printf '3rd' ;;
    *)
      d=$(( n % 10 ))
      u=$(( (n / 10) % 10 ))
      if (( u == 1 )); then printf '%dth' "$n"
      elif (( d == 1 )); then printf '%dst' "$n"
      elif (( d == 2 )); then printf '%dnd' "$n"
      elif (( d == 3 )); then printf '%drd' "$n"
      else printf '%dth' "$n"
      fi
      ;;
  esac
}

print_merge_boundaries_report() {
  local output_file="$1"
  shift
  local -a files=("$@")
  local -a boundary_times=() boundary_left=() boundary_right=()
  local i boundary pos preview start length preview_from preview_to

  if ! merge_compute_boundaries boundary_times boundary_left boundary_right "${files[@]}"; then
    echo "=== Merge boundaries ==="
    echo "  $(pgm_ts) Could not compute boundaries (ffprobe duration missing for one or more inputs)."
    echo
    return 1
  fi

  echo "=== Merge boundaries in output (${output_file##*/}) ==="
  for (( i = 0; i < ${#boundary_times[@]}; i++ )); do
    boundary="${boundary_times[$i]}"
    pos="$(format_output_timeline_pos "$boundary")"
    read -r start length < <(merge_seam_preview_start_length "$boundary" \
      "$PGM_SEAM_PREVIEW_BEFORE" "$PGM_SEAM_PREVIEW_AFTER")
    preview_from="$(format_output_timeline_pos "$start")"
    preview_to="$(format_output_timeline_pos "$(awk -v s="$start" -v l="$length" 'BEGIN { printf "%.6f", s + l }')")"
    printf '  %s | %s  at  %s  (preview %s – %s)\n' \
      "${boundary_left[$i]}" "${boundary_right[$i]}" "$pos" "$preview_from" "$preview_to"
  done
  echo
  return 0
}

find_video_pgm_play_terminal() {
  local candidate
  if [[ -n "${VIDEO_PGM_PLAY_TERMINAL_BIN:-}" && -x "${VIDEO_PGM_PLAY_TERMINAL_BIN}" ]]; then
    printf '%s\n' "${VIDEO_PGM_PLAY_TERMINAL_BIN}"
    return 0
  fi
  if candidate=$(command -v video-pgm-play-terminal.sh 2>/dev/null); then
    printf '%s\n' "$candidate"
    return 0
  fi
  for candidate in \
    "${SCRIPT_DIR:-}/video-pgm-play-terminal.sh" \
    "/root/bin/video-pgm-play-terminal.sh"; do
    [[ -n "$candidate" && -x "$candidate" ]] || continue
    printf '%s\n' "$candidate"
    return 0
  done
  return 1
}

play_merge_seam_preview_once() {
  local player="$1" output_file="$2" boundary="$3" left="$4" right="$5"
  local seam_num="$6" total_seams="$7" ord="$8"
  local start length pos clip_total

  read -r start length < <(merge_seam_preview_start_length "$boundary" \
    "$PGM_SEAM_PREVIEW_BEFORE" "$PGM_SEAM_PREVIEW_AFTER")
  pos="$(format_output_timeline_pos "$boundary")"
  clip_total="$(merge_seam_clip_total_seconds "$PGM_SEAM_PREVIEW_BEFORE" "$PGM_SEAM_PREVIEW_AFTER")"
  [[ -n "$ord" ]] || ord="$(pgm_ordinal_seam_label "$seam_num")"
  echo
  echo "Playing output file at ${ord} seam (${seam_num} of ${total_seams}): ${output_file##*/}"
  echo "  Join: ${left} | ${right}  at  ${pos}"
  echo "  Starts ${PGM_SEAM_PREVIEW_BEFORE}s before the seam; clip length ${clip_total}s (${PGM_SEAM_PREVIEW_BEFORE}s before + ${PGM_SEAM_PREVIEW_AFTER}s after)."
  "${player}" --no_startup_delay --no-countdown --start "$start" --length "$length" "$output_file"
}

# Return 2 if user quits from a prompt.
prompt_seam_terminal_previews() {
  local output_file="$1"
  shift
  local -a files=("$@")
  local -a boundary_times=() boundary_left=() boundary_right=()
  local player i choice seam_num total_seams ord pos clip_total

  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  if ! merge_compute_boundaries boundary_times boundary_left boundary_right "${files[@]}"; then
    return 0
  fi
  if [[ ! -f "$output_file" ]]; then
    return 0
  fi
  if ! player=$(find_video_pgm_play_terminal); then
    echo "$(pgm_ts) video-pgm-play-terminal.sh not found — seam preview skipped."
    echo "$(pgm_ts) Install it to /root/bin or set VIDEO_PGM_PLAY_TERMINAL_BIN."
    return 0
  fi

  total_seams=${#boundary_times[@]}
  clip_total="$(merge_seam_clip_total_seconds "$PGM_SEAM_PREVIEW_BEFORE" "$PGM_SEAM_PREVIEW_AFTER")"
  echo
  echo "Terminal seam preview: ${player}"
  echo "Each clip starts ${PGM_SEAM_PREVIEW_BEFORE}s before the join, ${PGM_SEAM_PREVIEW_AFTER}s after (${clip_total}s total)."
  echo

  for (( i = 0; i < total_seams; i++ )); do
    seam_num=$(( i + 1 ))
    ord="$(pgm_ordinal_seam_label "$seam_num")"
    pos="$(format_output_timeline_pos "${boundary_times[$i]}")"

    echo "--- ${ord} seam (${seam_num} of ${total_seams}) ---"
    echo "  ${boundary_left[$i]} | ${boundary_right[$i]}  at  ${pos}"
    echo "  [y] Play output at this seam (${PGM_SEAM_PREVIEW_BEFORE}s before join, ${clip_total}s clip)"
    echo "  [N] Skip this seam (default)"
    echo "  [q] Quit"
    pgm_read_key "Play ${ord} seam in terminal? [y/N/q]: " n
    choice="${REPLY,,}"
    case "$choice" in
      y)
        while true; do
          play_merge_seam_preview_once "$player" "$output_file" \
            "${boundary_times[$i]}" "${boundary_left[$i]}" "${boundary_right[$i]}" \
            "$seam_num" "$total_seams" "$ord"
          echo "  [y] Repeat ${ord} seam preview"
          echo "  [N] Continue (default)"
          echo "  [q] Quit"
          pgm_read_key "Repeat ${ord} seam preview? [y/N/q]: " n
          choice="${REPLY,,}"
          case "$choice" in
            y) continue ;;
            q) return 2 ;;
            *) break ;;
          esac
        done
        ;;
      q)
        return 2
        ;;
      *)
        ;;
    esac
  done
  echo
  return 0
}

# One line: part label (if any), basename, size (no trailing newline).
chapter_file_summary_line() {
  local f="$1"
  local base="${f##*/}" part sz dur dur_s
  sz=$(file_size_bytes "$f")
  if part=$(chapter_part_from_basename "$base" 2>/dev/null); then
    printf 'part %02d  %s  %s' "$part" "$base" "$(format_bytes_human "$sz")"
  else
    printf '%s  %s' "$base" "$(format_bytes_human "$sz")"
  fi
  if dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) && [[ -n "$dur" ]]; then
    dur_s=$(format_duration_display "$dur")
    printf '  %s' "$dur_s"
  fi
}

# One line: part label (if any), basename, size, duration.
print_chapter_file_line() {
  local indent="$1" f="$2"
  printf '%s%s\n' "$indent" "$(chapter_file_summary_line "$f")"
}

# Truncate for fixed-width columns (ellipsis if needed).
pgm_truncate_str() {
  local s="$1" max="$2"
  if ((${#s} <= max)); then
    printf '%s' "$s"
  else
    printf '%s...' "${s:0:$(( max - 3 ))}"
  fi
}

# Fixed widths so '|' in size strings lines up across input lines.
PGM_IO_PART_W=8
PGM_IO_NAME_W=52

pgm_io_input_line() {
  local part_lbl="$1" f="$2"
  local base="${f##*/}" sz dur dur_disp name_disp
  name_disp=$(pgm_truncate_str "$base" "$PGM_IO_NAME_W")
  sz=$(file_size_bytes "$f")
  if dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) && [[ -n "$dur" ]]; then
    dur_disp=$(format_duration_display "$dur")
  else
    dur_disp="—"
  fi
  printf '  %-*s %-*s %s  %s\n' "$PGM_IO_PART_W" "$part_lbl" "$PGM_IO_NAME_W" "$name_disp" \
    "$(format_bytes_human_aligned "$sz")" "$dur_disp"
}

# INPUT section, then OUTPUT section (narrower than side-by-side layout).
print_merge_group_io_block() {
  local output_file="$1"
  shift
  local -a files=("$@")
  local f input_total=0 out_sz=0 input_dur_total=0
  local base part_lbl dur
  local input_total_s output_total_s output_note input_dur_s sep

  for f in "${files[@]}"; do
    sz=$(file_size_bytes "$f")
    (( input_total += sz ))
    if dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) && [[ -n "$dur" ]]; then
      input_dur_total=$(awk -v a="$input_dur_total" -v b="$dur" 'BEGIN{printf "%.3f", a+b}')
    fi
  done

  if [[ -e "$output_file" ]]; then
    out_sz=$(file_size_bytes "$output_file")
    output_total_s="$(format_bytes_human_aligned "$out_sz")"
    output_note="(on disk)"
    if dur=$(ffprobe_duration_seconds "$output_file" 2>/dev/null) && [[ -n "$dur" ]]; then
      output_note+="  $(format_duration_display "$dur")"
    fi
  else
    output_total_s="—"
    output_note="(not created yet)"
  fi
  input_total_s="$(format_bytes_human_aligned "$input_total")"
  sep=$(printf '%*s' 72 '' | tr ' ' '-')

  echo "  INPUT (${#files[@]} parts)"
  printf '  %s\n' "$sep"
  for f in "${files[@]}"; do
    base="${f##*/}"
    if part_lbl=$(chapter_part_from_basename "$base" 2>/dev/null); then
      part_lbl=$(printf 'part %02d' "$part_lbl")
    else
      part_lbl=""
    fi
    pgm_io_input_line "$part_lbl" "$f"
  done
  if [[ -n "$input_dur_total" ]] && awk -v d="$input_dur_total" 'BEGIN{exit !(d>0)}'; then
    input_dur_s=$(format_duration_display "$input_dur_total")
  else
    input_dur_s="—"
  fi
  printf '  %-*s %-*s %s  %s\n' "$PGM_IO_PART_W" "Total:" "$PGM_IO_NAME_W" "" \
    "$input_total_s" "$input_dur_s"
  echo
  echo "  OUTPUT"
  printf '  %s\n' "$sep"
  printf '  %s\n' "${output_file}"
  printf '  %-*s %-*s Total: %s  %s\n' "$PGM_IO_PART_W" "" "$PGM_IO_NAME_W" "" \
    "$output_total_s" "$output_note"
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
  # …_concat.mp4 (legacy) or …_concat_parts_01-06[_Proxy].mp4
  [[ "${base}" == *_concat ]] && return 0
  [[ "${base}" =~ _concat_parts_[0-9]{2}-[0-9]{2}(_Proxy)?$ ]] && return 0
  return 1
}

# Set by concat_parse_cam_part_range: stem/camera token and part range from output name.
CONCAT_PARSE_CAM=""
CONCAT_PARSE_STEM=""
CONCAT_PARSE_PROXY=""
CONCAT_PARSE_FIRST=0
CONCAT_PARSE_LAST=0
PGM_ORPHAN_CONCAT_COUNT=0

# Parse <stem>_concat_parts_01-04[_Proxy], legacy <stem>_parts_01-04[_Proxy]_concat,
# or legacy *_part_04_concat basename.
concat_parse_cam_part_range() {
  local base="$1"
  CONCAT_PARSE_CAM=""
  CONCAT_PARSE_STEM=""
  CONCAT_PARSE_PROXY=""
  CONCAT_PARSE_FIRST=0
  CONCAT_PARSE_LAST=0
  if [[ "$base" =~ ^(.+)_concat_parts_([0-9]{2})-([0-9]{2})(_Proxy)?\.[mM][pP]4$ ]]; then
    CONCAT_PARSE_STEM="${BASH_REMATCH[1]}"
    CONCAT_PARSE_PROXY="${BASH_REMATCH[4]}"
    CONCAT_PARSE_FIRST=$((10#${BASH_REMATCH[2]}))
    CONCAT_PARSE_LAST=$((10#${BASH_REMATCH[3]}))
    CONCAT_PARSE_CAM="$(gopro_camera_suffix_from_basename "$base" 2>/dev/null || true)"
    return 0
  fi
  if [[ "$base" =~ ^(.+)_parts_([0-9]{2})-([0-9]{2})(_Proxy)?_concat\.[mM][pP]4$ ]]; then
    CONCAT_PARSE_STEM="${BASH_REMATCH[1]}"
    CONCAT_PARSE_PROXY="${BASH_REMATCH[4]}"
    CONCAT_PARSE_FIRST=$((10#${BASH_REMATCH[2]}))
    CONCAT_PARSE_LAST=$((10#${BASH_REMATCH[3]}))
    CONCAT_PARSE_CAM="$(gopro_camera_suffix_from_basename "$base" 2>/dev/null || true)"
    return 0
  fi
  if [[ "$base" =~ _-__-_([^/]+)_part_([0-9]{2})_concat\.[mM][pP]4$ ]]; then
    CONCAT_PARSE_CAM="${BASH_REMATCH[1]}"
    CONCAT_PARSE_FIRST=$((10#${BASH_REMATCH[2]}))
    CONCAT_PARSE_LAST=$CONCAT_PARSE_FIRST
    return 0
  fi
  return 1
}

chapter_input_matches_stem_part() {
  local base="$1" stem="$2" part="$3" proxy_suffix="${4:-}"
  local pp want want_uc
  pp=$(printf '%02d' "$part")
  want="${stem}_part_${pp}${proxy_suffix}.mp4"
  want_uc="${stem}_part_${pp}${proxy_suffix}.MP4"
  [[ "$base" == "$want" || "$base" == "$want_uc" ]]
}

chapter_input_matches_cam_part() {
  local base="$1" cam="$2" part="$3"
  local pp
  pp=$(printf '%02d' "$part")
  [[ "$base" =~ _-__-_${cam}_part_${pp}(_Proxy)?\.[mM][pP]4$ ]]
}

# How many distinct parts exist as chapter inputs for a concat output's range.
count_chapter_inputs_for_concat_range() {
  local first="$1" last="$2" stem="$3" proxy_suffix="${4:-}" cam="${5:-}"
  shift 5
  local -a all_mp4=("$@")
  local f base p found=0
  for (( p = first; p <= last; p++ )); do
    for f in "${all_mp4[@]}"; do
      base="${f##*/}"
      is_concat_output_basename "$base" && continue
      if [[ -n "$stem" ]]; then
        chapter_input_matches_stem_part "$base" "$stem" "$p" "$proxy_suffix" || continue
      elif [[ -n "$cam" ]]; then
        chapter_input_matches_cam_part "$base" "$cam" "$p" || continue
      else
        continue
      fi
      (( found++ ))
      break
    done
  done
  printf '%d\n' "$found"
}

print_orphan_concat_section() {
  local -a all_mp4=("$@")
  local f base cam stem proxy first last expected found note sep sz
  local -a orphans=()
  PGM_ORPHAN_CONCAT_COUNT=0

  for f in "${all_mp4[@]}"; do
    base="${f##*/}"
    is_concat_output_basename "$base" || continue
    if ! concat_parse_cam_part_range "$base"; then
      orphans+=( "${f}|unparseable concat name|?||0|0|0|0" )
      continue
    fi
    cam="$CONCAT_PARSE_CAM"
    stem="$CONCAT_PARSE_STEM"
    proxy="$CONCAT_PARSE_PROXY"
    first="$CONCAT_PARSE_FIRST"
    last="$CONCAT_PARSE_LAST"
    expected=$(( last - first + 1 ))
    found=$(count_chapter_inputs_for_concat_range "$first" "$last" "$stem" "$proxy" "$cam" "${all_mp4[@]}")
    if (( found >= expected )); then
      continue
    fi
    if (( found == 0 )); then
      note="no input chapters in this folder"
    else
      note="only ${found} of ${expected} input chapter(s) present"
    fi
    orphans+=( "${f}|${note}|${stem}|${cam}|${first}|${last}|${expected}|${found}" )
  done

  PGM_ORPHAN_CONCAT_COUNT=${#orphans[@]}
  (( PGM_ORPHAN_CONCAT_COUNT > 0 )) || return 0

  sep=$(printf '%*s' 72 '' | tr ' ' '-')
  echo "Merged outputs without input chapters in this folder:"
  printf '  %s\n' "$sep"
  for entry in "${orphans[@]}"; do
    IFS='|' read -r f note stem cam first last expected found <<< "$entry"
    base="${f##*/}"
    sz=$(file_size_bytes "$f")
    printf '  %s\n' "$base"
    printf '    %s\n' "$(format_bytes_human_aligned "$sz")"
    if [[ -n "$stem" ]]; then
      printf '    Stem: %s  parts %02d-%02d\n' "$stem" "$first" "$last"
      [[ -n "$cam" ]] && printf '    Camera: %s\n' "$cam"
    elif [[ -n "$cam" && "$cam" != '?' ]]; then
      printf '    Camera: %s  parts %02d-%02d\n' "$cam" "$first" "$last"
    fi
    printf '    Status: %s\n' "$note"
    echo
  done
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
  if gopro_camera_suffix_from_basename "$base"; then
    return 0
  fi
  if [[ "$base" =~ _-__-_([^/]+)_part_[0-9]{2} ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

# GoPro clip without _part_XX: YYYYMMDD_HHMMSS[a]_…_GOPRO7_BLACK.MP4 or …_GOPRO10_BLACK_GX013496.MP4
# Optional single letter after HHMMSS (…_200322a_…) or after the camera token (…_GOPRO10_BLACKa.MP4)
# is rename-style chapter disambiguation when several chapters share one start time.
# Sets GOPRO_CAM_LETTER when the letter is on the camera token (empty otherwise).
# Sets GOPRO_PARSED_CAM and optional GOPRO_CAM_LETTER; also prints camera on stdout
# (for legacy cam=$(…) callers). Prefer reading GOPRO_PARSED_CAM when letter is needed.
gopro_camera_suffix_from_basename() {
  local base="$1"
  GOPRO_CAM_LETTER=""
  GOPRO_PARSED_CAM=""
  if [[ "$base" =~ _(GOPRO[0-9]+_[A-Z0-9]+)_([A-Z]{2}[0-9]{4,6})\.[mM][pP]4$ ]]; then
    GOPRO_PARSED_CAM="${BASH_REMATCH[1]}"
    printf '%s\n' "$GOPRO_PARSED_CAM"
    return 0
  fi
  # Trailing letter after UPPERCASE model: GOPRO10_BLACKa.MP4 → cam BLACK, letter a
  if [[ "$base" =~ (GOPRO[0-9]+_[A-Z0-9]+)([a-zA-Z])?\.[mM][pP]4$ ]]; then
    GOPRO_PARSED_CAM="${BASH_REMATCH[1]}"
    GOPRO_CAM_LETTER="${BASH_REMATCH[2]}"
    printf '%s\n' "$GOPRO_PARSED_CAM"
    return 0
  fi
  return 1
}

# Optional GX-style chapter token (GX013496) before .MP4.
gopro_chapter_suffix_from_basename() {
  local base="$1"
  if [[ "$base" =~ _([A-Z]{2}[0-9]{4,6})\.[mM][pP]4$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

gopro_timestamp_cam_from_basename() {
  local base="$1"
  GOPRO_TS_DATE=""
  GOPRO_TS_TIME=""
  GOPRO_TS_LETTER=""
  GOPRO_TS_CAM=""
  GOPRO_TS_CHAPTER=""
  GOPRO_CAM_LETTER=""
  GOPRO_PARSED_CAM=""
  # With GX chapter token: date_time[letter]_middle_CAMERA_GXnnnnnn.ext
  if [[ "$base" =~ ^([0-9]{8})_([0-9]{6})([a-zA-Z])?_(.*)_((GOPRO[0-9]+_[A-Z0-9]+))_([A-Z]{2}[0-9]{4,6})\.[mM][pP]4$ ]]; then
    GOPRO_TS_DATE="${BASH_REMATCH[1]}"
    GOPRO_TS_TIME="${BASH_REMATCH[2]}"
    GOPRO_TS_LETTER="${BASH_REMATCH[3]}"
    GOPRO_TS_CAM="${BASH_REMATCH[5]}"
    GOPRO_TS_CHAPTER="${BASH_REMATCH[7]}"
    return 0
  fi
  # date_time[letter]_… — call camera parser without $() so GOPRO_CAM_LETTER is not lost in a subshell
  if [[ "$base" =~ ^([0-9]{8})_([0-9]{6})([a-zA-Z])?_ ]]; then
    GOPRO_TS_DATE="${BASH_REMATCH[1]}"
    GOPRO_TS_TIME="${BASH_REMATCH[2]}"
    GOPRO_TS_LETTER="${BASH_REMATCH[3]}"
  else
    return 1
  fi
  if ! gopro_camera_suffix_from_basename "$base" >/dev/null; then
    return 1
  fi
  GOPRO_TS_CAM="$GOPRO_PARSED_CAM"
  # Prefer time-letter; else use camera-letter (…_GOPRO10_BLACKa).
  if [[ -z "${GOPRO_TS_LETTER}" && -n "${GOPRO_CAM_LETTER:-}" ]]; then
    GOPRO_TS_LETTER="$GOPRO_CAM_LETTER"
  fi
  GOPRO_TS_CHAPTER=""
  return 0
}

# Middle part of GoPro basename (between timestamp[+letter] and camera suffix[+letter]).
gopro_middle_from_basename() {
  local base="$1" mid
  gopro_timestamp_cam_from_basename "$base" || return 1
  if [[ "$base" =~ ^[0-9]{8}_[0-9]{6}[a-zA-Z]?_(.*)_((GOPRO[0-9]+_[A-Z0-9]+))_([A-Z]{2}[0-9]{4,6})\.[mM][pP]4$ ]]; then
    mid="${BASH_REMATCH[1]}"
  elif [[ "$base" =~ ^[0-9]{8}_[0-9]{6}[a-zA-Z]?_(.*)_(GOPRO[0-9]+_[A-Z0-9]+)[a-zA-Z]?\.[mM][pP]4$ ]]; then
    mid="${BASH_REMATCH[1]}"
  else
    return 1
  fi
  printf '%s\n' "$mid"
}

# Grouping key: same date, time, camera, and middle (ignores per-file GX chapter / letter suffix).
gopro_recording_group_key_from_basename() {
  local base="$1" mid
  gopro_timestamp_cam_from_basename "$base" || return 1
  mid=$(gopro_middle_from_basename "$base" 2>/dev/null) || mid=""
  printf '%s_%s|%s|%s\n' "$GOPRO_TS_DATE" "$GOPRO_TS_TIME" "$GOPRO_TS_CAM" "$mid"
}

# Size-split session key: same camera + middle label; leading timestamp may differ per chapter.
gopro_size_split_session_key_from_basename() {
  local base="$1" mid
  gopro_timestamp_cam_from_basename "$base" || return 1
  mid=$(gopro_middle_from_basename "$base" 2>/dev/null) || mid=""
  printf '%s|%s\n' "$GOPRO_TS_CAM" "$mid"
}

# Next lowercase letter after $1 (a→b); empty if not a–y.
gopro_next_chapter_letter() {
  local letter="${1,,}" alphabet=abcdefghijklmnopqrstuvwxyz idx
  [[ "$letter" =~ ^[a-y]$ ]] || { printf ''; return 1; }
  idx=${alphabet%%"${letter}"*}
  idx=${#idx}
  printf '%s\n' "${alphabet:$((idx + 1)):1}"
}

# True when files share one recording stamp/camera/middle and chapter letters are a,b,c… consecutive.
# Rename-style disambiguation (…_200322a_… or …_GOPRO10_BLACKa.MP4) — merge at any size, like part_01.
gopro_letter_chapter_run_ok() {
  local -a files=("$@")
  local f base key0="" key letter prev="" expected
  (( ${#files[@]} >= 2 )) || return 1
  for f in "${files[@]}"; do
    base="${f##*/}"
    if chapter_part_from_basename "$base" >/dev/null 2>&1; then
      return 1
    fi
    gopro_timestamp_cam_from_basename "$base" || return 1
    letter="${GOPRO_TS_LETTER,,}"
    [[ "$letter" =~ ^[a-z]$ ]] || return 1
    key=$(gopro_recording_group_key_from_basename "$base") || return 1
    if [[ -z "$key0" ]]; then
      [[ "$letter" == a ]] || return 1
      key0="$key"
      prev="$letter"
      continue
    fi
    [[ "$key" == "$key0" ]] || return 1
    expected=$(gopro_next_chapter_letter "$prev") || return 1
    [[ "$letter" == "$expected" ]] || return 1
    prev="$letter"
  done
  return 0
}

# Sort key for size-split singles (time order, then letter a/b/c…, then GX chapter number).
gopro_size_split_sort_key() {
  local f="$1" base ch sort_num letter_key
  base="${f##*/}"
  gopro_timestamp_cam_from_basename "$base" || { printf '%s\n' "$base"; return 0; }
  sort_num=0
  if [[ -n "${GOPRO_TS_CHAPTER:-}" && "$GOPRO_TS_CHAPTER" =~ ^[A-Z]{2}([0-9]+)$ ]]; then
    sort_num=$((10#${BASH_REMATCH[1]}))
  fi
  # Empty letter sorts before 'a' (use '_' so plain HHMMSS comes first within same second).
  letter_key="${GOPRO_TS_LETTER:-_}"
  printf '%s_%s_%s_%06d_%s\n' "$GOPRO_TS_DATE" "$GOPRO_TS_TIME" "$letter_key" "$sort_num" "$base"
}

# Seconds since midnight from HHMMSS (for same-day checks without date(1)).
gopro_hhmmss_to_seconds() {
  local t="$1"
  awk -v t="$t" 'BEGIN {
    h=int(substr(t,1,2)); m=int(substr(t,3,2)); s=int(substr(t,5,2));
    printf "%d\n", h*3600+m*60+s
  }'
}

# Epoch seconds for YYYYMMDD + HHMMSS (uses date(1) when available).
gopro_datetime_to_epoch() {
  local d="$1" t="$2" iso
  iso="${d:0:4}-${d:4:2}-${d:6:2} ${t:0:2}:${t:2:2}:${t:4:2}"
  if date -d "$iso" +%s 2>/dev/null; then
    return 0
  fi
  return 1
}

# 0 = next file's basename time matches previous file end time (± tolerance).
size_split_chapter_timestamps_follow() {
  local prev_f="$1" next_f="$2"
  local pb nb prev_date prev_time next_date next_time
  local prev_epoch next_epoch dur expected delta tol min_gap max_gap
  pb="${prev_f##*/}"
  nb="${next_f##*/}"
  gopro_timestamp_cam_from_basename "$pb" || return 1
  prev_date="$GOPRO_TS_DATE" prev_time="$GOPRO_TS_TIME"
  gopro_timestamp_cam_from_basename "$nb" || return 1
  next_date="$GOPRO_TS_DATE" next_time="$GOPRO_TS_TIME"

  # Same start time in filename (GX013496, GX023496, … on one recording).
  if [[ "$prev_date" == "$next_date" && "$prev_time" == "$next_time" ]]; then
    return 0
  fi

  tol="${PGM_SIZE_SPLIT_TIME_TOLERANCE_SEC:-180}"
  min_gap="${PGM_SIZE_SPLIT_TIME_MIN_GAP_SEC:-300}"
  max_gap="${PGM_SIZE_SPLIT_TIME_MAX_GAP_SEC:-720}"
  if size_split_tier_for_file "$prev_f" | grep -qx 12; then
    max_gap="${PGM_SIZE_SPLIT_12G_TIME_MAX_GAP_SEC:-2400}"
  fi

  dur=$(ffprobe_duration_seconds "$prev_f" 2>/dev/null) || dur=""

  if prev_epoch=$(gopro_datetime_to_epoch "$prev_date" "$prev_time" 2>/dev/null) \
    && next_epoch=$(gopro_datetime_to_epoch "$next_date" "$next_time" 2>/dev/null); then
    if [[ -n "$dur" ]]; then
      expected=$(awk -v p="$prev_epoch" -v d="$dur" 'BEGIN{printf "%d", p+d+0.5}')
      delta=$(( next_epoch - expected ))
      (( delta >= -tol && delta <= tol ))
      return $?
    fi
    delta=$(( next_epoch - prev_epoch ))
    (( delta >= min_gap && delta <= max_gap ))
    return $?
  fi

  # Same calendar day only (filename times).
  [[ "$prev_date" == "$next_date" ]] || return 1
  prev_epoch=$(gopro_hhmmss_to_seconds "$prev_time")
  next_epoch=$(gopro_hhmmss_to_seconds "$next_time")
  if [[ -n "$dur" ]]; then
    expected=$(awk -v p="$prev_epoch" -v d="$dur" 'BEGIN{printf "%d", p+d+0.5}')
    delta=$(( next_epoch - expected ))
    # Midnight wrap: next chapter on same day usually does not roll past 24h.
    if (( next_epoch < prev_epoch )); then
      return 1
    fi
    (( delta >= -tol && delta <= tol ))
    return $?
  fi
  gap=$(( next_epoch - prev_epoch ))
  (( next_epoch >= prev_epoch && gap >= min_gap && gap <= max_gap ))
}

gopro_token_is_noise() {
  local t="${1,,}"
  [[ "$t" =~ ^s[0-9]+$ ]] && return 0
  case "$t" in
    niecaly|film|proxy|black|gopro|niecalyfilm) return 0 ;;
  esac
  return 1
}

# Human session label for grouping (dermatolog-s29 vs farma-s29, order-independent).
gopro_session_key_from_basename() {
  local base="$1" mid
  local -a tokens=()
  mid=$(gopro_middle_from_basename "$base") || return 1
  mapfile -t tokens < <(
    printf '%s\n' "$mid" | tr '_-( )' '\n' | tr '[:upper:]' '[:lower:]' |
      grep -E '^[a-z0-9]{2,}$' | grep -Ev '^(niecaly|film|proxy|black|gopro)$' | LC_ALL=C sort -u
  )
  ((${#tokens[@]} > 0)) || return 1
  local IFS='-'
  printf '%s\n' "${tokens[*]}"
}

# Primary description token (dermatolog, farma).
gopro_description_from_basename() {
  local base="$1" mid
  mid=$(gopro_middle_from_basename "$base") || return 1
  printf '%s\n' "$mid" | tr '_-( )' '\n' | tr '[:upper:]' '[:lower:]' |
    grep -E '^[a-z]{4,}$' | grep -Ev '^(s[0-9]+|niecaly|film|proxy|black|gopro)$' | head -1
}

# S29-style tag from basename, if present.
gopro_s_tag_from_basename() {
  local base="$1" mid raw
  mid=$(gopro_middle_from_basename "$base") || return 1
  raw=$(printf '%s\n' "$mid" | grep -oiE 's[0-9]{1,3}' | head -1) || return 1
  raw="${raw,,}"
  printf 'S%s\n' "${raw#s}"
}

# Session label for output names: S29_-_dermatolog
gopro_session_label_slug_from_basename() {
  local base="$1" s_tag="" desc="" key part
  s_tag=$(gopro_s_tag_from_basename "$base" 2>/dev/null) || s_tag=""
  desc=$(gopro_description_from_basename "$base" 2>/dev/null) || desc=""
  if [[ -z "$s_tag" || -z "$desc" ]]; then
    key=$(gopro_session_key_from_basename "$base" 2>/dev/null) || key=""
    if [[ -n "$key" ]]; then
      IFS='-' read -r -a parts <<< "$key"
      for part in "${parts[@]}"; do
        [[ -z "$part" ]] && continue
        if [[ "$part" =~ ^s[0-9]+$ ]]; then
          s_tag="S${part#s}"
        elif [[ -z "$desc" ]]; then
          desc="$part"
        fi
      done
    fi
  fi
  if [[ -n "$s_tag" && -n "$desc" ]]; then
    printf '%s_-_-%s' "$s_tag" "$desc"
    return 0
  fi
  [[ -n "$desc" ]] && printf '%s\n' "$desc" && return 0
  [[ -n "$s_tag" ]] && printf '%s\n' "$s_tag" && return 0
  return 1
}

gopro_camera_from_basename() {
  local base="$1"
  if gopro_camera_suffix_from_basename "$base"; then
    return 0
  fi
  chapter_camera_from_basename "$base"
}

# GoPro fixed-size chapter splits: ~4 GB (classic FAT32 cap) and ~12 GB (exFAT / high-bitrate cap).
PGM_SIZE_SPLIT_4G_MIN_BYTES=$(( 3500 * 1024 * 1024 ))
PGM_SIZE_SPLIT_4G_MAX_BYTES=$(( 4500 * 1024 * 1024 ))
PGM_SIZE_SPLIT_12G_MIN_BYTES=$(( 11000 * 1024 * 1024 ))
PGM_SIZE_SPLIT_12G_MAX_BYTES=$(( 12500 * 1024 * 1024 ))
# Legacy names used by near-miss hints (4 GB band).
PGM_SIZE_SPLIT_MIN_BYTES=$PGM_SIZE_SPLIT_4G_MIN_BYTES
PGM_SIZE_SPLIT_MAX_BYTES=$PGM_SIZE_SPLIT_4G_MAX_BYTES
# With ffprobe: reject a full chapter only if duration is clearly too short for its size tier.
PGM_SIZE_SPLIT_DURATION_REJECT_BELOW_SEC="${PGM_SIZE_SPLIT_DURATION_REJECT_BELOW_SEC:-420}"
PGM_SIZE_SPLIT_12G_DURATION_REJECT_BELOW_SEC="${PGM_SIZE_SPLIT_12G_DURATION_REJECT_BELOW_SEC:-1080}"
PGM_SIZE_SPLIT_12G_TIME_MAX_GAP_SEC="${PGM_SIZE_SPLIT_12G_TIME_MAX_GAP_SEC:-2400}"
# GoPro cameras (7, 10, …): ~4 GB chapters often ~6:49 (409s).
PGM_GOPRO7_SIZE_MIN_BYTES=$PGM_SIZE_SPLIT_4G_MIN_BYTES
PGM_GOPRO7_SIZE_MAX_BYTES=$PGM_SIZE_SPLIT_4G_MAX_BYTES
PGM_GOPRO7_DURATION_MIN_SEC="${PGM_GOPRO7_DURATION_MIN_SEC:-380}"
PGM_GOPRO7_DURATION_MAX_SEC="${PGM_GOPRO7_DURATION_MAX_SEC:-450}"

# stdout: 4 | 12 | empty
size_split_tier_for_bytes() {
  local sz="$1"
  (( sz >= PGM_SIZE_SPLIT_12G_MIN_BYTES && sz <= PGM_SIZE_SPLIT_12G_MAX_BYTES )) && { printf '12'; return 0; }
  (( sz >= PGM_SIZE_SPLIT_4G_MIN_BYTES && sz <= PGM_SIZE_SPLIT_4G_MAX_BYTES )) && { printf '4'; return 0; }
  return 1
}

size_split_tier_for_file() {
  local f="$1"
  size_split_tier_for_bytes "$(file_size_bytes "$f")"
}

gopro_camera_is_gopro7() {
  [[ "$1" == *GOPRO7* ]]
}

gopro_camera_uses_4gb_chapter_duration() {
  [[ "$1" == *GOPRO* ]]
}

gopro7_size_in_chapter_range() {
  local sz="$1"
  (( sz >= PGM_GOPRO7_SIZE_MIN_BYTES && sz <= PGM_GOPRO7_SIZE_MAX_BYTES ))
}

duration_in_gopro7_chapter_range() {
  local dur="$1"
  awk -v d="$dur" -v lo="$PGM_GOPRO7_DURATION_MIN_SEC" -v hi="$PGM_GOPRO7_DURATION_MAX_SEC" \
    'BEGIN { exit !(d+0 >= lo && d+0 <= hi) }'
}

ffprobe_duration_seconds() {
  local f="$1" d
  command -v ffprobe >/dev/null 2>&1 || return 1
  d=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 -- "$f" 2>/dev/null) || return 1
  [[ -n "$d" ]] || return 1
  awk -v d="$d" 'BEGIN { if (d+0 >= 0) printf "%.3f\n", d+0; else exit 1 }'
}

duration_too_short_for_full_size_split() {
  local dur="$1" tier="${2:-4}"
  local rej="$PGM_SIZE_SPLIT_DURATION_REJECT_BELOW_SEC"
  [[ "$tier" == 12 ]] && rej="$PGM_SIZE_SPLIT_12G_DURATION_REJECT_BELOW_SEC"
  awk -v d="$dur" -v rej="$rej" \
    'BEGIN { exit !(d+0 > 0 && d+0 < rej) }'
}

# Full segment at a size tier (4 or 12); reject only clearly invalid durations.
is_full_size_split_segment_at_tier() {
  local f="$1" tier="$2" sz dur base cam="" gopro_chap=0
  base="${f##*/}"
  sz=$(file_size_bytes "$f")
  dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) || dur=""

  case "$tier" in
    12)
      (( sz >= PGM_SIZE_SPLIT_12G_MIN_BYTES && sz <= PGM_SIZE_SPLIT_12G_MAX_BYTES )) || return 1
      if [[ -n "$dur" ]]; then
        duration_too_short_for_full_size_split "$dur" 12 && return 1
      fi
      return 0
      ;;
    4)
      cam=$(gopro_camera_from_basename "$base" 2>/dev/null) || cam=
      gopro_camera_uses_4gb_chapter_duration "$cam" && gopro_chap=1
      if (( gopro_chap )); then
        if gopro7_size_in_chapter_range "$sz"; then
          if [[ -n "$dur" ]]; then
            duration_in_gopro7_chapter_range "$dur" && return 0
            duration_too_short_for_full_size_split "$dur" 4 && return 1
          fi
          return 0
        fi
        if [[ -n "$dur" ]] && duration_in_gopro7_chapter_range "$dur" \
          && (( sz >= PGM_GOPRO7_SIZE_MIN_BYTES )); then
          return 0
        fi
      fi
      (( sz >= PGM_SIZE_SPLIT_4G_MIN_BYTES && sz <= PGM_SIZE_SPLIT_4G_MAX_BYTES )) || return 1
      if [[ -n "$dur" ]]; then
        duration_too_short_for_full_size_split "$dur" 4 && return 1
      fi
      return 0
      ;;
  esac
  return 1
}

# Full segment: auto-detect 12 GB band first, then 4 GB / GoPro7.
is_full_size_split_segment() {
  local f="$1" tier
  tier=$(size_split_tier_for_file "$f") || return 1
  is_full_size_split_segment_at_tier "$f" "$tier"
}

is_partial_size_split_segment_at_tier() {
  local f="$1" tier="$2" sz dur base cam="" gopro_chap=0
  base="${f##*/}"
  sz=$(file_size_bytes "$f")
  dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) || dur=""

  case "$tier" in
    12)
      (( sz < PGM_SIZE_SPLIT_12G_MIN_BYTES )) && return 0
      return 1
      ;;
    4)
      cam=$(gopro_camera_from_basename "$base" 2>/dev/null) || cam=
      gopro_camera_uses_4gb_chapter_duration "$cam" && gopro_chap=1
      if (( gopro_chap )); then
        (( sz < PGM_GOPRO7_SIZE_MIN_BYTES )) && return 0
        if [[ -n "$dur" ]] && ! duration_in_gopro7_chapter_range "$dur" \
          && duration_too_short_for_full_size_split "$dur" 4; then
          return 0
        fi
        return 1
      fi
      (( sz < PGM_SIZE_SPLIT_4G_MIN_BYTES )) && return 0
      if [[ -n "$dur" ]]; then
        duration_too_short_for_full_size_split "$dur" 4 && return 0
      fi
      return 1
      ;;
  esac
  return 1
}

is_partial_size_split_segment() {
  local f="$1" tier="${2:-}"
  [[ -n "$tier" ]] || tier=$(size_split_tier_for_file "$f" 2>/dev/null) || tier=4
  is_partial_size_split_segment_at_tier "$f" "$tier"
}


size_split_run_valid() {
  local -a run=("$@")
  local i n=${#run[@]} f tier next_tier
  (( n >= 2 )) || return 1
  tier=$(size_split_tier_for_file "${run[0]}") || return 1
  for (( i = 0; i < n - 1; i++ )); do
    next_tier=$(size_split_tier_for_file "${run[i]}") || return 1
    [[ "$next_tier" == "$tier" ]] || return 1
    is_full_size_split_segment_at_tier "${run[i]}" "$tier" || return 1
  done
  f="${run[n - 1]}"
  next_tier=$(size_split_tier_for_file "$f") || next_tier=""
  if [[ -n "$next_tier" && "$next_tier" == "$tier" ]] && is_full_size_split_segment_at_tier "$f" "$tier"; then
    return 0
  fi
  is_partial_size_split_segment_at_tier "$f" "$tier"
}

size_split_group_output_file() {
  local -a files=("$@")
  local fb date1 t1 cam1 middle="" n
  fb="${files[0]##*/}"
  gopro_timestamp_cam_from_basename "$fb" || return 1
  date1="$GOPRO_TS_DATE" t1="$GOPRO_TS_TIME" cam1="$GOPRO_TS_CAM"
  middle=$(gopro_middle_from_basename "$fb") || return 1
  n=${#files[@]}
  (( n >= 1 )) || return 1
  # e.g. 20220115_200322_-__-_GOPRO10_BLACK_concat_parts_01-06.mp4
  printf '%s_%s_%s_%s_concat_parts_01-%02d.mp4\n' "$date1" "$t1" "$middle" "$cam1" "$n"
}

# Label for merged output metadata (title/description).
group_merge_description_label() {
  local -a files=("$@")
  local fb middle
  fb="${files[0]##*/}"
  middle=$(gopro_middle_from_basename "$fb") || return 1
  middle="${middle#_}"
  middle="${middle%_}"
  middle="${middle//_-/ }"
  middle="${middle//_/ }"
  printf '%s\n' "$middle"
}

apply_merge_output_metadata() {
  local output_file="$1" label="$2"
  local tmp rc
  [[ -n "$label" && -f "$output_file" ]] || return 0
  if ! command -v ffmpeg >/dev/null 2>&1; then
    pgm_log_kv "Metadata" "skipped (ffmpeg not installed)"
    return 0
  fi
  tmp="${output_file}.meta.tmp.$$"
  if ffmpeg -y -v error -i "$output_file" -codec copy \
    -metadata "title=${label}" -metadata "description=${label}" \
    -metadata "comment=${label}" "$tmp" 2>/dev/null; then
    if mv -f -- "$tmp" "$output_file"; then
      pgm_log_kv "Metadata title" "$label"
      return 0
    fi
  fi
  rm -f -- "$tmp"
  pgm_log_kv "Metadata" "could not write (ffmpeg copy failed)"
  return 1
}

group_is_size_split() {
  local -a files=("$@")
  local f base
  (( ${#files[@]} >= 2 )) || return 1
  for f in "${files[@]}"; do
    base="${f##*/}"
    if chapter_part_from_basename "$base" >/dev/null 2>&1; then
      return 1
    fi
    gopro_timestamp_cam_from_basename "$base" || return 1
  done
  # Letter a,b,c… on one start time is enough (any size); else require ~4 GB / ~12 GB chapters.
  gopro_letter_chapter_run_ok "${files[@]}" && return 0
  size_split_run_valid "${files[@]}"
}

# Flush a letter-chapter run into dest arrays: multi-file merge blob, else singles back to kept.
letter_chapter_flush_run() {
  local -n _kept_ref=$1
  local -n _new_ref=$2
  shift 2
  local -a run=("$@")
  local rf
  if (( ${#run[@]} >= 2 )) && gopro_letter_chapter_run_ok "${run[@]}"; then
    _new_ref+=("$(printf '%s\n' "${run[@]}")")
  else
    for rf in "${run[@]}"; do
      _kept_ref+=("$rf")
    done
  fi
}

# Group rename-style chapter letters (…BLACKa/b/c or …HHMMSSa/b/c) without a ~4 GB size check.
# Runs before size-split so small lettered chapters still merge.
build_letter_chapter_groups() {
  local -a kept=() new_groups=() run=() keys_seen=()
  local -A by_key=()
  local blob f base key letter
  local -a files=() key_files=()

  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    if (( ${#files[@]} >= 2 )); then
      kept+=("$blob")
      continue
    fi
    f="${files[0]}"
    base="${f##*/}"
    if chapter_part_from_basename "$base" >/dev/null 2>&1 \
      || ! gopro_timestamp_cam_from_basename "$base"; then
      kept+=("$f")
      continue
    fi
    letter="${GOPRO_TS_LETTER,,}"
    if [[ ! "$letter" =~ ^[a-z]$ ]]; then
      kept+=("$f")
      continue
    fi
    key=$(gopro_recording_group_key_from_basename "$base" 2>/dev/null) || {
      kept+=("$f")
      continue
    }
    if [[ -z "${by_key[$key]+x}" ]]; then
      by_key["$key"]="$f"
      keys_seen+=("$key")
    else
      by_key["$key"]+=$'\n'"$f"
    fi
  done

  for key in "${keys_seen[@]}"; do
    key_files=()
    mapfile -t key_files <<< "${by_key[$key]}"
    if ((${#key_files[@]})) && [[ -z "${key_files[-1]}" ]]; then
      unset 'key_files[-1]'
    fi
    mapfile -t key_files < <(
      for f in "${key_files[@]}"; do
        printf '%s\t%s\n' "$(gopro_size_split_sort_key "$f")" "$f"
      done | LC_ALL=C sort -t $'\t' -k1,1 | cut -f2-
    )
    run=()
    for f in "${key_files[@]}"; do
      base="${f##*/}"
      gopro_timestamp_cam_from_basename "$base" || {
        letter_chapter_flush_run kept new_groups "${run[@]}"
        run=()
        kept+=("$f")
        continue
      }
      letter="${GOPRO_TS_LETTER,,}"
      if (( ${#run[@]} == 0 )); then
        if [[ "$letter" == a ]]; then
          run=( "$f" )
        else
          kept+=("$f")
        fi
        continue
      fi
      if gopro_letter_chapter_run_ok "${run[@]}" "$f"; then
        run+=( "$f" )
        continue
      fi
      letter_chapter_flush_run kept new_groups "${run[@]}"
      if [[ "$letter" == a ]]; then
        run=( "$f" )
      else
        run=()
        kept+=("$f")
      fi
    done
    letter_chapter_flush_run kept new_groups "${run[@]}"
  done

  GROUP_BLOBS=( "${kept[@]}" "${new_groups[@]}" )
}

# Combine single-file blobs that look like sequential ~4 GB or ~12 GB splits (no _part_XX).
build_size_split_groups() {
  local -a kept=() singles=() run=()
  local blob files f base i n run_len
  local -a new_groups=()
  local warned_ffprobe=0
  local run_tier="" next_tier=""

  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    if (( ${#files[@]} >= 2 )); then
      kept+=("$blob")
      continue
    fi
    base="${files[0]##*/}"
    if chapter_part_from_basename "$base" >/dev/null 2>&1; then
      kept+=("$blob")
      continue
    fi
    gopro_timestamp_cam_from_basename "$base" || {
      kept+=("$blob")
      continue
    }
    singles+=("${files[0]}")
  done

  (( ${#singles[@]} >= 2 )) || {
    GROUP_BLOBS=( "${kept[@]}" )
    return 0
  }

  if ! command -v ffprobe >/dev/null 2>&1; then
    echo "$(pgm_ts) ffprobe not found — size-split uses file size; timestamp chain uses ~5–12 min gaps (~4 GB) or up to ~40 min (~12 GB)." >&2
    warned_ffprobe=1
  fi

  mapfile -t singles < <(
    for f in "${singles[@]}"; do
      printf '%s\t%s\n' "$(gopro_size_split_sort_key "$f")" "$f"
    done | LC_ALL=C sort -t $'\t' -k1,1 | cut -f2-
  )
  n=${#singles[@]}
  i=0
  while (( i < n )); do
    if is_full_size_split_segment "${singles[i]}"; then
      run=("${singles[i]}")
      run_tier=$(size_split_tier_for_file "${singles[i]}")
    else
      kept+=("${singles[i]}")
      (( i++ )) || true
      continue
    fi
    local run_cam run_group_key
    run_cam=$(gopro_camera_from_basename "${singles[i]##*/}")
    run_group_key=$(gopro_size_split_session_key_from_basename "${singles[i]##*/}" 2>/dev/null) || run_group_key=""
    (( i++ )) || true
    while (( i < n )); do
      f="${singles[i]}"
      base="${f##*/}"
      if [[ "$(gopro_camera_from_basename "$base")" != "$run_cam" ]]; then
        break
      fi
      if [[ -n "$run_group_key" ]]; then
        [[ "$(gopro_size_split_session_key_from_basename "$base" 2>/dev/null)" == "$run_group_key" ]] || break
      fi
      if ! size_split_chapter_timestamps_follow "${run[-1]}" "$f"; then
        break
      fi
      if is_full_size_split_segment "$f"; then
        next_tier=$(size_split_tier_for_file "$f") || break
        [[ "$next_tier" == "$run_tier" ]] || break
        run+=("$f")
        (( i++ )) || true
        continue
      fi
      if is_partial_size_split_segment_at_tier "$f" "$run_tier"; then
        run+=("$f")
        (( i++ )) || true
      fi
      break
    done
    if size_split_run_valid "${run[@]}"; then
      new_groups+=("$(printf '%s\n' "${run[@]}")")
    else
      local part_path
      for part_path in "${run[@]}"; do
        kept+=("$part_path")
      done
    fi
  done

  GROUP_BLOBS=( "${kept[@]}" "${new_groups[@]}" )
  (( warned_ffprobe )) || true
  print_size_split_near_miss_hint
}

# Explain when same-camera ~4GB/~12GB singles were not grouped (after a failed strict check).
print_size_split_near_miss_hint() {
  local -a cand=() files=()
  local blob f base cam sz dur n_full=0
  local first_cam="" first_fail="" first_dur=""
  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    (( ${#files[@]} == 1 )) || continue
    f="${files[0]}"
    base="${f##*/}"
    gopro_timestamp_cam_from_basename "$base" || continue
    sz=$(file_size_bytes "$f")
    if [[ -z "$first_cam" ]]; then
      first_cam="$GOPRO_TS_CAM"
    fi
    [[ "$GOPRO_TS_CAM" == "$first_cam" ]] || continue
    cand+=("$f")
    if size_split_tier_for_bytes "$sz" >/dev/null; then
      (( n_full++ )) || true
      if [[ -z "$first_fail" ]] && ! is_full_size_split_segment "$f"; then
        first_fail="${base}"
        first_dur=$(ffprobe_duration_seconds "$f" 2>/dev/null) || first_dur="?"
      fi
    fi
  done
  (( ${#cand[@]} >= 2 && n_full >= 2 )) || return 0
  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    (( ${#files[@]} >= 2 )) && group_is_size_split "${files[@]}" && return 0
  done
  echo "$(pgm_ts) Note: ${#cand[@]} same-camera clips look like size-splits but were not grouped."
  if [[ -n "$first_fail" ]]; then
    if [[ "$first_cam" == *GOPRO* ]]; then
      echo "$(pgm_ts)       Example: ${first_fail} duration ${first_dur}s (GoPro ~4 GB: ~6:49, ${PGM_GOPRO7_DURATION_MIN_SEC}-${PGM_GOPRO7_DURATION_MAX_SEC}s)."
    else
      echo "$(pgm_ts)       Example: ${first_fail} duration ${first_dur}s (full ~4 GB chapter: duration not below ${PGM_SIZE_SPLIT_DURATION_REJECT_BELOW_SEC}s; ~12 GB: not below ${PGM_SIZE_SPLIT_12G_DURATION_REJECT_BELOW_SEC}s)."
    fi
  fi
}

# Raw GoPro camera chapter name (HERO6+ / MAX): G[HX] + 2-digit chapter + 4-digit
# recording number, optional _Proxy. Sets RAW_GP_PREFIX / RAW_GP_CHAPTER /
# RAW_GP_NUMBER / RAW_GP_PROXY. e.g. GX010393.MP4 -> GX 01 0393 ; GX020393_Proxy.MP4.
gopro_raw_chapter_parse() {
  local base="$1"
  RAW_GP_PREFIX="" RAW_GP_CHAPTER="" RAW_GP_NUMBER="" RAW_GP_PROXY=""
  if [[ "$base" =~ ^(G[HX])([0-9]{2})([0-9]{4})(_Proxy)?\.[mM][pP]4$ ]]; then
    RAW_GP_PREFIX="${BASH_REMATCH[1]}"
    RAW_GP_CHAPTER="${BASH_REMATCH[2]}"
    RAW_GP_NUMBER="${BASH_REMATCH[3]}"
    RAW_GP_PROXY="${BASH_REMATCH[4]}"
    return 0
  fi
  return 1
}

# Group key for a raw GoPro chapter file: prefix + recording number + variant (orig vs proxy).
# Chapters of one recording share this key; originals and proxies get different keys.
gopro_raw_group_key() {
  gopro_raw_chapter_parse "$1" || return 1
  printf '%s_%s%s\n' "$RAW_GP_PREFIX" "$RAW_GP_NUMBER" "$RAW_GP_PROXY"
}

# True if every file is a raw GoPro chapter sharing the same group key.
group_is_raw_gopro() {
  local -a files=("$@")
  local f base key first_key=
  (( ${#files[@]} >= 1 )) || return 1
  for f in "${files[@]}"; do
    base="${f##*/}"
    key=$(gopro_raw_group_key "$base") || return 1
    if [[ -z "$first_key" ]]; then
      first_key="$key"
    elif [[ "$key" != "$first_key" ]]; then
      return 1
    fi
  done
  return 0
}

# Output name for a raw GoPro chapter group: e.g. GX0393_concat_parts_01-04.mp4
# (proxies: GX0393_Proxy_concat_parts_01-04.mp4).
raw_gopro_group_output_file() {
  local -a files=("$@")
  local f base prefix="" num="" proxy="" min="" max="" ch
  for f in "${files[@]}"; do
    base="${f##*/}"
    gopro_raw_chapter_parse "$base" || return 1
    prefix="$RAW_GP_PREFIX"
    num="$RAW_GP_NUMBER"
    proxy="$RAW_GP_PROXY"
    ch=$((10#$RAW_GP_CHAPTER))
    if [[ -z "$min" ]] || (( ch < min )); then min=$ch; fi
    if [[ -z "$max" ]] || (( ch > max )); then max=$ch; fi
  done
  printf '%s%s%s_concat_parts_%02d-%02d.mp4\n' "$prefix" "$num" "$proxy" "$min" "$max"
}

# Pull raw GoPro chapter files (GXccnnnn[_Proxy].MP4) out of the sorted list into
# key-based groups (one per recording+variant, ordered by chapter). Remaining files
# are returned via the nameref _rest for the legacy sequential/size-split logic.
build_raw_gopro_groups() {
  local -n _rest=$1
  shift
  local -a sorted=("$@")
  local f base key
  local -a keys_seen=()
  local -A group_map=()
  _rest=()
  for f in "${sorted[@]}"; do
    base="${f##*/}"
    if is_concat_output_basename "$base"; then
      _rest+=("$f")
      continue
    fi
    if gopro_raw_chapter_parse "$base"; then
      key="${RAW_GP_PREFIX}_${RAW_GP_NUMBER}${RAW_GP_PROXY}"
      if [[ -z "${group_map[$key]+x}" ]]; then
        group_map["$key"]="$f"
        keys_seen+=("$key")
      else
        group_map["$key"]+=$'\n'"$f"
      fi
    else
      _rest+=("$f")
    fi
  done
  # Input was LC_ALL=C sorted; within one key only the 2 chapter digits vary, so
  # the entries are already in ascending chapter order.
  local k
  for k in "${keys_seen[@]}"; do
    GROUP_BLOBS+=("${group_map[$k]}")
  done
}

# Parse an already-renamed chapter name: <stem>_part_NN[_Proxy].<ext>.
# Sets PART_STEM / PART_NUM / PART_PROXY / PART_EXT. Returns 0 on match.
part_chapter_parse() {
  local base="$1"
  PART_STEM="" PART_NUM="" PART_PROXY="" PART_EXT=""
  if [[ "$base" =~ ^(.*)_part_([0-9]{2})(_Proxy)?\.([mM][pP]4)$ ]]; then
    PART_STEM="${BASH_REMATCH[1]}"
    PART_NUM="${BASH_REMATCH[2]}"
    PART_PROXY="${BASH_REMATCH[3]}"
    PART_EXT="${BASH_REMATCH[4]}"
    return 0
  fi
  return 1
}

# Virtual basename without _part_NN for GoPro timestamp/camera parsing.
part_chapter_gopro_parse_base() {
  local base="$1"
  part_chapter_parse "$base" || return 1
  printf '%s.%s\n' "$PART_STEM" "$PART_EXT"
}

# Group key: same camera + middle + proxy; leading timestamp may differ per part.
part_chapter_group_key_from_basename() {
  local base="$1" stripped cam mid
  part_chapter_parse "$base" || return 1
  stripped=$(part_chapter_gopro_parse_base "$base") || return 1
  if gopro_timestamp_cam_from_basename "$stripped"; then
    mid=$(gopro_middle_from_basename "$stripped" 2>/dev/null) || mid=""
    printf '%s|%s%s\n' "$GOPRO_TS_CAM" "$mid" "${PART_PROXY}"
    return 0
  fi
  if cam=$(chapter_camera_from_basename "$base" 2>/dev/null); then
    printf '%s|%s%s\n' "$cam" "" "${PART_PROXY}"
    return 0
  fi
  printf '%s%s\n' "$PART_STEM" "${PART_PROXY}"
}

# True when _part_XX filename times chain like size-split: same start time, or
# previous part start + ffprobe duration ≈ next part start (± tolerance).
part_chapter_timestamps_follow() {
  local prev_f="$1" next_f="$2"
  local pb nb prev_base next_base
  local prev_date prev_time next_date next_time
  local prev_epoch next_epoch dur expected delta tol min_gap max_gap gap
  pb="${prev_f##*/}"
  nb="${next_f##*/}"
  prev_base=$(part_chapter_gopro_parse_base "$pb") || return 1
  next_base=$(part_chapter_gopro_parse_base "$nb") || return 1
  gopro_timestamp_cam_from_basename "$prev_base" || return 1
  prev_date="$GOPRO_TS_DATE" prev_time="$GOPRO_TS_TIME"
  gopro_timestamp_cam_from_basename "$next_base" || return 1
  next_date="$GOPRO_TS_DATE" next_time="$GOPRO_TS_TIME"

  if [[ "$prev_date" == "$next_date" && "$prev_time" == "$next_time" ]]; then
    return 0
  fi

  tol="${PGM_SIZE_SPLIT_TIME_TOLERANCE_SEC:-180}"
  min_gap="${PGM_SIZE_SPLIT_TIME_MIN_GAP_SEC:-300}"
  max_gap="${PGM_SIZE_SPLIT_TIME_MAX_GAP_SEC:-720}"
  if size_split_tier_for_file "$prev_f" | grep -qx 12; then
    max_gap="${PGM_SIZE_SPLIT_12G_TIME_MAX_GAP_SEC:-2400}"
  fi

  dur=$(ffprobe_duration_seconds "$prev_f" 2>/dev/null) || dur=""

  if prev_epoch=$(gopro_datetime_to_epoch "$prev_date" "$prev_time" 2>/dev/null) \
    && next_epoch=$(gopro_datetime_to_epoch "$next_date" "$next_time" 2>/dev/null); then
    if [[ -n "$dur" ]]; then
      expected=$(awk -v p="$prev_epoch" -v d="$dur" 'BEGIN{printf "%d", p+d+0.5}')
      delta=$(( next_epoch - expected ))
      (( delta >= -tol && delta <= tol ))
      return $?
    fi
    delta=$(( next_epoch - prev_epoch ))
    (( delta >= min_gap && delta <= max_gap ))
    return $?
  fi

  [[ "$prev_date" == "$next_date" ]] || return 1
  prev_epoch=$(gopro_hhmmss_to_seconds "$prev_time")
  next_epoch=$(gopro_hhmmss_to_seconds "$next_time")
  if [[ -n "$dur" ]]; then
    expected=$(awk -v p="$prev_epoch" -v d="$dur" 'BEGIN{printf "%d", p+d+0.5}')
    delta=$(( next_epoch - expected ))
    if (( next_epoch < prev_epoch )); then
      return 1
    fi
    (( delta >= -tol && delta <= tol ))
    return $?
  fi
  gap=$(( next_epoch - prev_epoch ))
  (( next_epoch >= prev_epoch && gap >= min_gap && gap <= max_gap ))
}

# Lowest _part_XX number in a run (after numeric sort).
part_chapter_first_part_number() {
  local -a sorted=()
  part_chapter_sorted_files sorted "$@"
  (( ${#sorted[@]} > 0 )) || return 1
  chapter_part_from_basename "${sorted[0]##*/}"
}

# True when every file is _part_XX and the run is mergeable.
# Runs from part_01 are trusted rename.sh chapters (any size). Later orphan tails
# (e.g. part_04–06 left after parts 01–03 merged) still need size-split rules.
part_chapter_run_valid() {
  local -a files=("$@")
  local f first_part
  (( ${#files[@]} >= 2 )) || return 1
  for f in "${files[@]}"; do
    part_chapter_parse "${f##*/}" || return 1
  done
  first_part=$(part_chapter_first_part_number "${files[@]}") || return 1
  (( first_part == 1 )) && return 0
  size_split_run_valid "${files[@]}"
}

# Sort _part_XX paths by numeric part (not lexicographic — part_10 before part_09).
part_chapter_sorted_files() {
  local -n _out=$1
  shift
  local -a files=("$@")
  local f p
  mapfile -t _out < <(
    for f in "${files[@]}"; do
      p=$(chapter_part_from_basename "${f##*/}") || continue
      printf '%d\t%s\n' "$p" "$f"
    done | LC_ALL=C sort -t $'\t' -k1,1n | cut -f2-
  )
}

part_chapter_append_run_to_groups_or_rest() {
  local _rest_name=$1
  shift
  local -n rest_arr=$_rest_name
  local -a run=("$@")
  local f blob first_part skip_reason

  if (( ${#run[@]} < 2 )); then
    rest_arr+=( "${run[@]}" )
    return 0
  fi
  if part_chapter_run_valid "${run[@]}"; then
    blob=$(printf '%s\n' "${run[@]}")
    GROUP_BLOBS+=( "$blob" )
    return 0
  fi
  first_part=$(part_chapter_first_part_number "${run[@]}") || first_part=0
  if (( first_part > 1 )); then
    skip_reason="orphan tail from part_$(printf '%02d' "$first_part") and not full ~4 GB / ~12 GB chapters"
  else
    skip_reason="not full ~4 GB / ~12 GB chapters"
  fi
  echo "$(pgm_ts) Skipping _part_XX merge (${#run[@]} consecutive parts):"
  echo "$(pgm_ts)   Reason: ${skip_reason}"
  for f in "${run[@]}"; do
    echo "$(pgm_ts)     ${f##*/}"
  done
  rest_arr+=( "${run[@]}" )
}

part_chapter_split_key_into_runs() {
  local _rest_name=$1
  shift
  local -a key_files=("$@")
  local -a sorted=() run=()
  local f cur_part prev_part

  part_chapter_sorted_files sorted "${key_files[@]}"
  (( ${#sorted[@]} > 0 )) || return 0

  run=()
  prev_part=""
  for f in "${sorted[@]}"; do
    cur_part=$(chapter_part_from_basename "${f##*/}") || continue
    if (( ${#run[@]} == 0 )); then
      run=( "$f" )
      prev_part=$cur_part
      continue
    fi
    if (( cur_part == prev_part + 1 )) && part_chapter_timestamps_follow "${run[-1]}" "$f"; then
      run+=( "$f" )
      prev_part=$cur_part
    else
      part_chapter_append_run_to_groups_or_rest "$_rest_name" "${run[@]}"
      run=( "$f" )
      prev_part=$cur_part
    fi
  done
  (( ${#run[@]} > 0 )) && part_chapter_append_run_to_groups_or_rest "$_rest_name" "${run[@]}"
}

# Pull _part_NN chapter files out of the list into key-based groups. The key is
# camera + middle label + proxy variant (or full stem when not GoPro-shaped), so
# originals (_part_NN) and proxies (_part_NN_Proxy) go into separate groups and
# are NEVER mixed. Within each key, only consecutive part numbers whose filename
# times chain (or share one start time) are kept together. Runs from part_01 merge
# at any size; orphan tails starting after part_01 need ~4 GB / ~12 GB full segments.
# return via the array named in $1 (e.g. rest2 from build_chapter_groups).
build_part_chapter_groups() {
  local _rest_name=$1
  shift
  local -n rest_arr=$_rest_name
  local -a sorted=("$@")
  local f base key
  local -a keys_seen=() key_files=()
  local -A group_map=()
  rest_arr=()
  for f in "${sorted[@]}"; do
    base="${f##*/}"
    if is_concat_output_basename "$base"; then
      rest_arr+=( "$f" )
      continue
    fi
    if part_chapter_parse "$base"; then
      key=$(part_chapter_group_key_from_basename "$base") || {
        rest_arr+=( "$f" )
        continue
      }
      if [[ -z "${group_map[$key]+x}" ]]; then
        group_map["$key"]="$f"
        keys_seen+=( "$key" )
      else
        group_map["$key"]+=$'\n'"$f"
      fi
    else
      rest_arr+=( "$f" )
    fi
  done
  local k
  for k in "${keys_seen[@]}"; do
    key_files=()
    mapfile -t key_files <<< "${group_map[$k]}"
    if ((${#key_files[@]})) && [[ -z "${key_files[-1]}" ]]; then
      unset 'key_files[-1]'
    fi
    part_chapter_split_key_into_runs "$_rest_name" "${key_files[@]}"
  done
}

# Build merge groups: each element of GROUP_BLOBS is a newline-separated file list (sorted).
build_chapter_groups() {
  local -a sorted=("$@")
  GROUP_BLOBS=()
  local f base
  local -a rest1=() rest2=()
  # 1) raw GoPro chapter files (GXccnnnn[_Proxy].MP4) -> key-based groups
  build_raw_gopro_groups rest1 "${sorted[@]}"
  # 2) already-renamed _part_NN chapters -> key-based groups (originals vs proxies kept apart)
  build_part_chapter_groups rest2 "${rest1[@]}"
  # 3) everything else becomes a single-file blob; letter chapters then size-splits
  for f in "${rest2[@]}"; do
    base="${f##*/}"
    if is_concat_output_basename "$base"; then
      continue
    fi
    GROUP_BLOBS+=("$f")
  done
  # 4) rename-style a/b/c chapter letters on the same timestamp (any size)
  build_letter_chapter_groups
  # 5) ~4 GB / ~12 GB size-split chapters without letter / _part_XX names
  build_size_split_groups
}

group_files_to_array() {
  local blob="$1"
  local -n _out=$2
  mapfile -t _out <<< "$blob"
  if ((${#_out[@]})) && [[ -z "${_out[-1]}" ]]; then
    unset '_out[-1]'
  fi
}

print_size_split_group_hint() {
  local cam_sample="$1"
  if [[ "$cam_sample" == *GOPRO* ]]; then
    echo "Probable size-split / letter-chapter recordings (no _part_XX; same camera + session label; ~4 GB / ~6:49 or ~12 GB chapters, or a/b/c letters on one start time; leading timestamp may differ per file):"
  else
    echo "Probable size-split / letter-chapter recordings (no _part_XX; same camera + session label; sequential ~4 GB or ~12 GB chapters, or a/b/c letters on one start time; leading timestamp may differ per file):"
  fi
}

print_group_plan() {
  local -a all_mp4=("$@")
  local gidx=0 mergeable=0 size_split_groups=0 part_groups=0 raw_gopro_groups=0 standalone=0
  local -a files=()
  local f base part cam blob out_name is_ss
  local group_bytes=0 sz
  echo "$(pgm_ts) Chapter plan in $(pwd):"
  echo
  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    (( ${#files[@]} >= 2 )) || continue
    (( mergeable++ )) || true
    if group_is_raw_gopro "${files[@]}"; then
      (( raw_gopro_groups++ )) || true
    elif group_is_size_split "${files[@]}"; then
      (( size_split_groups++ )) || true
    else
      (( part_groups++ )) || true
    fi
  done
  if (( part_groups > 0 )); then
    echo "Merge candidates (_part_XX chapters; consecutive parts from part_01; times must chain when each part has its own timestamp):"
    gidx=0
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} < 2 )) && continue
      group_is_raw_gopro "${files[@]}" && continue
      group_is_size_split "${files[@]}" && continue
      (( gidx++ )) || true
      out_name=$(group_output_file "${files[@]}")
      if [[ -e "$out_name" ]]; then
        printf '  [group %d/%d] %d parts → %s  (already merged)\n' \
          "$gidx" "$part_groups" "${#files[@]}" "$out_name"
      else
        printf '  [group %d/%d] %d parts → %s\n' \
          "$gidx" "$part_groups" "${#files[@]}" "$out_name"
      fi
      group_bytes=0
      for f in "${files[@]}"; do
        print_chapter_file_line '      ' "$f"
        sz=$(file_size_bytes "$f")
        (( group_bytes += sz ))
      done
      printf '      input total (%d files): %s\n' "${#files[@]}" "$(format_bytes_human "$group_bytes")"
      echo
    done
  fi
  if (( size_split_groups > 0 )); then
    cam=""
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} < 2 )) && continue
      group_is_size_split "${files[@]}" || continue
      cam=$(gopro_camera_from_basename "${files[0]##*/}" 2>/dev/null) || cam=
      break
    done
    print_size_split_group_hint "$cam"
    gidx=0
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} < 2 )) && continue
      group_is_size_split "${files[@]}" || continue
      (( gidx++ )) || true
      out_name=$(group_output_file "${files[@]}")
      local grp_desc
      grp_desc=$(gopro_middle_from_basename "${files[0]##*/}" 2>/dev/null) || grp_desc=
      grp_desc="${grp_desc//_-/ }"
      grp_desc="${grp_desc//_/ }"
      grp_desc="${grp_desc# }"
      grp_desc="${grp_desc% }"
      # Skip empty separator-only middles (e.g. -__- → "-").
      [[ "$grp_desc" =~ ^[[:space:]-]*$ ]] && grp_desc=
      if [[ -e "$out_name" ]]; then
        if [[ -n "$grp_desc" ]]; then
          printf '  [group %d/%d] %d clips (%s) → %s  (already merged)\n' \
            "$gidx" "$size_split_groups" "${#files[@]}" "$grp_desc" "$out_name"
        else
          printf '  [group %d/%d] %d clips → %s  (already merged)\n' \
            "$gidx" "$size_split_groups" "${#files[@]}" "$out_name"
        fi
      else
        if [[ -n "$grp_desc" ]]; then
          printf '  [group %d/%d] %d clips (%s) → %s\n' \
            "$gidx" "$size_split_groups" "${#files[@]}" "$grp_desc" "$out_name"
        else
          printf '  [group %d/%d] %d clips → %s\n' \
            "$gidx" "$size_split_groups" "${#files[@]}" "$out_name"
        fi
      fi
      group_bytes=0
      for f in "${files[@]}"; do
        print_chapter_file_line '      ' "$f"
        sz=$(file_size_bytes "$f")
        (( group_bytes += sz ))
      done
      printf '      input total (%d files): %s\n' "${#files[@]}" "$(format_bytes_human "$group_bytes")"
      echo
    done
  fi
  if (( raw_gopro_groups > 0 )); then
    echo "Merge candidates (GoPro chapter files GXccnnnn — originals and proxies separately):"
    gidx=0
    for blob in "${GROUP_BLOBS[@]}"; do
      group_files_to_array "$blob" files
      (( ${#files[@]} < 2 )) && continue
      group_is_raw_gopro "${files[@]}" || continue
      (( gidx++ )) || true
      out_name=$(group_output_file "${files[@]}")
      if [[ -e "$out_name" ]]; then
        printf '  [group %d/%d] %d chapters → %s  (already merged)\n' \
          "$gidx" "$raw_gopro_groups" "${#files[@]}" "$out_name"
      else
        printf '  [group %d/%d] %d chapters → %s\n' \
          "$gidx" "$raw_gopro_groups" "${#files[@]}" "$out_name"
      fi
      group_bytes=0
      for f in "${files[@]}"; do
        printf '      %s\n' "${f##*/}"
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
  print_orphan_concat_section "${all_mp4[@]}"
  local breakdown=""
  (( part_groups > 0 )) && breakdown+="${breakdown:+, }${part_groups} _part_XX"
  (( raw_gopro_groups > 0 )) && breakdown+="${breakdown:+, }${raw_gopro_groups} GoPro chapter"
  (( size_split_groups > 0 )) && breakdown+="${breakdown:+, }${size_split_groups} size-split"
  if [[ -n "$breakdown" ]]; then
    echo "$(pgm_ts) Summary: ${mergeable} merge group(s) (${breakdown}), ${standalone} standalone file(s), ${PGM_ORPHAN_CONCAT_COUNT} merged output(s) without input chapters."
  else
    echo "$(pgm_ts) Summary: ${mergeable} merge group(s), ${standalone} standalone file(s), ${PGM_ORPHAN_CONCAT_COUNT} merged output(s) without input chapters."
  fi
  echo
}

group_output_file() {
  local -a files=("$@")
  local f base stem part min_part= max_part= got_part=0 suffix_proxy=
  if (( ${#files[@]} >= 2 )) && group_is_size_split "${files[@]}"; then
    size_split_group_output_file "${files[@]}" && return 0
  fi
  if group_is_raw_gopro "${files[@]}"; then
    raw_gopro_group_output_file "${files[@]}" && return 0
  fi
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
    printf '%s_concat_parts_%02d-%02d%s.mp4\n' \
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
  echo "  [q] Quit"
  pgm_read_key "Delete inputs? [y/N/q]: " n
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
      return 0
      ;;
    q)
      echo "$(pgm_ts) Quit."
      return 2
      ;;
    *)
      echo "$(pgm_ts) Input files kept."
      return 0
      ;;
  esac
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
    local meta_label
    if meta_label=$(group_merge_description_label "${files[@]}" 2>/dev/null); then
      apply_merge_output_metadata "$output_file" "$meta_label"
    fi
    echo
    print_merge_size_summary "$output_file" "${files[@]}"
    print_merge_boundaries_report "$output_file" "${files[@]}"
    prompt_seam_terminal_previews "$output_file" "${files[@]}"
    rc=$?
    if (( rc == 2 )); then
      return 2
    fi
    prompt_delete_merged_inputs after_merge "${files[@]}"
    rc=$?
    if (( rc == 2 )); then
      return 2
    fi
    rc=0
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
      echo "  [p] Preview merge seams in terminal"
      echo "  [d] Delete input chapter files — keep merged output"
      echo "  [a] Skip all remaining groups"
      echo "  [q] Quit"
      pgm_read_key "Already merged — group ${group_num}/${group_total} [N/r/p/d/a/q]: " n
      choice="${REPLY,,}"
      case "$choice" in
        ''|n)  REPLY=skip; pgm_log_kv "Action" "Keeping existing output and inputs."; return 0 ;;
        r)     REPLY=redo; return 0 ;;
        p)     REPLY=preview_seams; return 0 ;;
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
  local blob action
  local -a files=() mergeable_blobs=()
  merger=$(find_merger) || {
    mp4_merge_print_not_found_help
    if ! prompt_install_mp4_merge_now; then
      return 1
    fi
    merger=$(find_merger) || {
      echo "$(pgm_ts) mp4_merge is still not available after the install attempt — cannot merge." >&2
      return 1
    }
  }
  merger=$(resolve_merger_path_for_merge "$merger") || {
    local resolve_rc=$?
    if (( resolve_rc == 2 )); then
      return 0
    fi
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

  MERGE_ALL_REMAINING=0
  SKIP_ALL_REMAINING=0

  print_group_plan "${sorted_mp4[@]}"

  if (( ${#GROUP_BLOBS[@]} == 0 )); then
    echo "$(pgm_ts) No chapter input MP4s in $(pwd)."
    return 0
  fi

  for blob in "${GROUP_BLOBS[@]}"; do
    group_files_to_array "$blob" files
    if (( ${#files[@]} >= 2 )); then
      mergeable_blobs+=("$blob")
    fi
  done
  mergeable_total=${#mergeable_blobs[@]}

  if (( mergeable_total == 0 )); then
    echo "$(pgm_ts) No multi-part chapter groups to merge."
    echo "$(pgm_ts) Tip: sequential GoPro clips (_part_01… with chaining timestamps, YYYYMMDD_HHMMSS_… without _part_XX, ~4 GB / ~12 GB, or a/b/c letter suffixes) may be mergeable chapters."
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
        if (( rc == 2 )); then
          echo "$(pgm_ts) Quit at group ${group_num}."
          return "${rc}"
        fi
        ;;
      redo)
        run_merge_group "$merger" 1 "${files[@]}" || rc=$?
        if (( rc == 2 )); then
          echo "$(pgm_ts) Quit at group ${group_num}."
          return "${rc}"
        fi
        ;;
      delete_inputs)
        if [[ -e "$output_file" ]]; then
          prompt_delete_merged_inputs already_merged "${files[@]}" || rc=$?
          if (( rc == 2 )); then
            echo "$(pgm_ts) Quit at group ${group_num}."
            return "${rc}"
          fi
        else
          echo "$(pgm_ts) No merged output for group ${group_num}; cannot delete inputs here." >&2
        fi
        ;;
      skip)
        if [[ -e "$output_file" ]]; then
          print_merge_boundaries_report "$output_file" "${files[@]}"
        else
          echo "$(pgm_ts) Skipped group ${group_num}."
        fi
        ;;
      preview_seams)
        if [[ -e "$output_file" ]]; then
          print_merge_boundaries_report "$output_file" "${files[@]}"
          prompt_seam_terminal_previews "$output_file" "${files[@]}" || rc=$?
          if (( rc == 2 )); then
            echo "$(pgm_ts) Quit at group ${group_num}."
            return "${rc}"
          fi
        else
          echo "$(pgm_ts) No merged output for group ${group_num}; cannot preview seams." >&2
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
          if (( rc == 2 )); then
            echo "$(pgm_ts) Quit at group ${group_num}."
            return "${rc}"
          fi
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

# --- parse options (header sourced first so -v can call print_version_banner) ---
DO_UPDATE=0
DO_YES=0
MERGE_ALL_REMAINING=0
SKIP_ALL_REMAINING=0
GROUP_BLOBS=()
HEADER_EXTRA_ARGS=()
for _vpm_a in "$@"; do
  [[ "$_vpm_a" == --no_startup_delay ]] && HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
done
. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

PGM_SEAM_PREVIEW_BEFORE="${PGM_SEAM_PREVIEW_BEFORE:-2}"
PGM_SEAM_PREVIEW_AFTER="${PGM_SEAM_PREVIEW_AFTER:-0}"
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
    -u|--update)
      DO_UPDATE=1
      shift
      ;;
    -y|--yes)
      DO_YES=1
      shift
      ;;
    --read-timeout)
      if [[ -z "${2:-}" || ! "$2" =~ ^[0-9]+$ ]]; then
        echo "$(pgm_ts) --read-timeout requires a non-negative integer (seconds)." >&2
        exit 1
      fi
      PGM_READ_TIMEOUT="$2"
      PGM_READ_TIMEOUT_CLI=1
      shift 2
      ;;
    --read-timeout=*)
      PGM_READ_TIMEOUT="${1#*=}"
      if [[ ! "$PGM_READ_TIMEOUT" =~ ^[0-9]+$ ]]; then
        echo "$(pgm_ts) --read-timeout requires a non-negative integer (seconds)." >&2
        exit 1
      fi
      PGM_READ_TIMEOUT_CLI=1
      shift
      ;;
    --seam-before)
      [[ $# -ge 2 ]] || pgm_invalid_seam_seconds "seam-before" ""
      pgm_valid_seam_seconds "$2" || pgm_invalid_seam_seconds "seam-before" "$2"
      PGM_SEAM_PREVIEW_BEFORE="$2"
      shift 2
      ;;
    --seam-before=*)
      PGM_SEAM_PREVIEW_BEFORE="${1#*=}"
      pgm_valid_seam_seconds "$PGM_SEAM_PREVIEW_BEFORE" \
        || pgm_invalid_seam_seconds "seam-before" "$PGM_SEAM_PREVIEW_BEFORE"
      shift
      ;;
    --seam-after)
      [[ $# -ge 2 ]] || pgm_invalid_seam_seconds "seam-after" ""
      pgm_valid_seam_seconds "$2" || pgm_invalid_seam_seconds "seam-after" "$2"
      PGM_SEAM_PREVIEW_AFTER="$2"
      shift 2
      ;;
    --seam-after=*)
      PGM_SEAM_PREVIEW_AFTER="${1#*=}"
      pgm_valid_seam_seconds "$PGM_SEAM_PREVIEW_AFTER" \
        || pgm_invalid_seam_seconds "seam-after" "$PGM_SEAM_PREVIEW_AFTER"
      shift
      ;;
    --no_startup_delay)
      shift
      ;;
    *)
      echo "$(pgm_ts) Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

pgm_init_read_timeout

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MP4_MERGE_SYSTEM_DIR="${MP4_MERGE_SYSTEM_DIR:-/usr/local/bin}"
MP4_MERGE_INSTALL_DIR="${MP4_MERGE_INSTALL_DIR:-${MP4_MERGE_SYSTEM_DIR}}"

if [[ -f "${BASH_SOURCE[0]}" ]]; then
  chmod 700 "${BASH_SOURCE[0]}" 2>/dev/null || true
fi

pgm_record_script_start

print_version_banner

if (( script_is_run_interactively )) && ! (( DO_YES )); then
  if pgm_read_timeout_is_limited; then
    pgm_log_kv "Prompt timeout" "${PGM_READ_TIMEOUT} s per key (then default choice)"
  else
    pgm_log_kv "Prompt timeout" "none (wait for keypress)"
  fi
fi

if (( DO_UPDATE )); then
  update_mp4_merge
  return_code=$?
  print_pgm_timing_summary
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

do_merge
return_code=$?

print_pgm_timing_summary

. /root/bin/_script_footer.sh

exit "${return_code}"
