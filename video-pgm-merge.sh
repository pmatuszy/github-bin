#!/bin/bash

# 2026.05.26 - v. 0.5 - source _script_header.sh / _script_footer.sh like other bin scripts
# 2026.05.26 - v. 0.4 - enforce owner-only mode 700 on this script when run on Linux
# 2026.05.26 - v. 0.3 - add -h/--help and -u/--update (install mp4_merge from gyroflow/mp4-merge)
# 2026.05.26 - v. 0.2 - renamed from gopro-mp4-merge.sh
# 2026.05.26 - v. 0.1 - merge GoPro chapter MP4s (Windows merge-gopro batch port)

MP4_MERGE_REPO="${MP4_MERGE_REPO:-gyroflow/mp4-merge}"

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-u|--update] [-v|--version] [NO_STARTUP_DELAY]

Merge chapter MP4 files in the current directory (e.g. GoPro splits) into one
file using mp4_merge from https://github.com/gyroflow/mp4-merge

Options:
  -h, --help           Show this help and exit.
  -u, --update         Download or update mp4_merge for this OS/CPU into the install
                       directory (default: directory containing this script).
  -v, --version        Print script version and exit.
  NO_STARTUP_DELAY     Skip random startup delay when run non-interactively (see
                       _script_header.sh).

Merge behaviour (no options):
  - Collects *.mp4 in the current working directory (case-insensitive).
  - Merges files in ascending name order (chapter 1, 2, 3, ...).
  - Output file: <highest_chapter_basename>_concat.mp4
    (basename taken from the last file when sorted in reverse).

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

  $(basename "$0") NO_STARTUP_DELAY
      Merge without random delay (cron).

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

do_merge() {
  local merger top_file file_base
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

  top_file=$(printf '%s\n' "${mp4_files[@]}" | LC_ALL=C sort -r | head -n1)
  file_base="${top_file%.*}"

  local merge_files=()
  mapfile -t merge_files < <(printf '%s\n' "${mp4_files[@]}" | LC_ALL=C sort)

  echo "Merging video chapters:"
  printf ' %q' "${merge_files[@]}"
  echo
  echo

  "${merger}" "${merge_files[@]}" --out "${file_base}_concat.mp4"
  local rc=$?

  echo
  if (( rc == 0 )); then
    echo "Done!"
  else
    echo "(PGM) Merge failed (exit ${rc})."
  fi
  return "${rc}"
}

# --- parse options before _script_header (avoids figlet/delay on --help) ---
DO_UPDATE=0
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
