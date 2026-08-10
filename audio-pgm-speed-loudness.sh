#!/usr/bin/env bash
# v. 20260810.152506 - rename to audio-pgm-speed-loudness.sh (drop CURRENT-DIRECTORY suffix)
# v. 20260810.152137 - add English rewrite: cwd atempo+speechnorm, fix find grouping, safe file loop
# 2024.10.20 - v. 0.7 - with ffmpeg 7.0.2, -shortest shortened outputs incorrectly; removed it
# 2024.08.13 - v. 0.6 - zero-pad _1_,_2_,_3_ to _01_,_02_,_03_ in names
# 2024.07.31 - v. 0.5 - rar-compress org/ so phone sync does not show it as an extra subfolder
# 2023.05.21 - v. 0.4 - sanitize cwd basename (spaces, Polish and odd chars); find -not at end (still buggy)
# 2022.06.14 - v. 0.3 - work correctly when directory name has spaces
# 2022.04.17 - v. 0.2 - strip Polish chars from filenames; chmod/chown/touch on org/
# 2021.05.03 - v. 0.1 - initial release
#
# audio-pgm-speed-loudness.sh
#
# In the current directory: speed up speech audio (ffmpeg atempo) and apply speechnorm,
# write mono AAC, move sources into org/, then pack org/ into org.rar.
#

set -euo pipefail

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay] [SPEED]

Process *.mp3, *.m4a, and *.aac in the current directory only (not subdirs).
Skips files whose names already contain SPEECHNORM_SPEEDUP.

For each file, run ffmpeg with:
  - mono (-ac 1)
  - atempo=SPEED (default 1.6)
  - speechnorm
Output: <basename>_SPEECHNORM_SPEEDUP_<SPEED>.aac
On success: copy mode/owner/mtime from the source, move the source into org/.
After all files: zero-pad _1_.._9_ in names, then rar-pack org/ into org.rar.

Also sanitizes the cwd basename and common media/doc filenames (spaces, commas,
Polish diacritics, brackets) using Debian/Ubuntu perl rename(1).

ffmpeg resolution (first match wins):
  1. FFMPEG_BIN environment variable (if executable)
  2. /usr/local/bin/ffmpeg
  3. /usr/bin/ffmpeg
  4. ffmpeg on PATH

Required tools: ffmpeg, rename (perl File::Rename style), rar.

Options:
  -h, --help            Show this help and exit.
  -v, --version         Print script version and exit.
  --no_startup_delay    Skip random startup delay (see _script_header.sh).
  SPEED                 atempo factor (default: 1.6), e.g. 1.5 or 2.0

Examples:
  cd /path/to/files && $(basename "$0")
  cd /path/to/files && $(basename "$0") 1.8
  FFMPEG_BIN=/opt/ffmpeg/bin/ffmpeg $(basename "$0") --no_startup_delay
EOF
}

HEADER_EXTRA_ARGS=()
SPEED_FACTOR=1.6

while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      if [[ -f /root/bin/_script_header.sh ]]; then
        # shellcheck source=/dev/null
        . /root/bin/_script_header.sh NO_STARTUP_DELAY
        print_version_banner
      else
        head -n1 "$0"
      fi
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
    *)
      SPEED_FACTOR=$1
      shift
      if [[ $# -gt 0 ]]; then
        echo "Unexpected argument: $1" >&2
        echo "Try: $(basename "$0") --help" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ ! "$SPEED_FACTOR" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "ERROR: SPEED must be a positive number (got: $SPEED_FACTOR)" >&2
  exit 1
fi

if [[ -f /root/bin/_script_header.sh ]]; then
  # shellcheck source=/dev/null
  . /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"
fi

resolve_ffmpeg_bin() {
  local candidate=""

  if [[ -n "${FFMPEG_BIN:-}" && -x "${FFMPEG_BIN}" ]]; then
    printf '%s\n' "${FFMPEG_BIN}"
    return 0
  fi
  for candidate in /usr/local/bin/ffmpeg /usr/bin/ffmpeg; do
    if [[ -x "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  command -v ffmpeg 2>/dev/null || return 1
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  local name="$1"
  command -v "$name" >/dev/null 2>&1 || die "'$name' not found on PATH (required)."
}

# Perl rename expressions applied to cwd basename and to selected files.
RENAME_EXPRS=(
  's/ /_/g'
  's/,/_/g'
  's/__/_/g'
  's/^!/_/g'
  's/!/./g'
  's|Ę|E|g'
  's|Ć|C|g'
  's|Ó|O|g'
  's|Ł|L|g'
  's|Ą|A|g'
  's|Ś|S|g'
  's|Ż|Z|g'
  's|Ź|Z|g'
  's|Ń|N|g'
  's|ę|e|g'
  's|ć|c|g'
  's|ó|o|g'
  's|ł|l|g'
  's|ą|a|g'
  's|ś|s|g'
  's|ż|z|g'
  's|ź|z|g'
  's|ń|n|g'
  's|\[|_|g'
  's|\]|_|g'
  's|\(|_|g'
  's|\)|_|g'
  's|__|_|g'
  's|_\.|\.|g'
  's|_$||g'
)

run_perl_rename() {
  # Debian/Ubuntu perl rename(1): rename 'expr' file...
  local expr=$1
  shift
  if (( $# == 0 )); then
    return 0
  fi
  rename "$expr" "$@" || true
}

sanitize_cwd_basename() {
  local cwd_name expr
  local parent

  parent="$(dirname -- "$(readlink -f .)")"
  cwd_name="$(basename -- "$(readlink -f .)")"
  echo "cwd basename (before sanitize) = $cwd_name"

  for expr in "${RENAME_EXPRS[@]}"; do
    cwd_name="$(basename -- "$(readlink -f .)")"
    (
      cd -- "$parent"
      run_perl_rename "$expr" "$cwd_name"
    )
  done

  cwd_name="$(basename -- "$(readlink -f .)")"
  echo "cwd basename (after sanitize)  = $cwd_name"
  # Refresh shell cwd if the directory was renamed under us.
  cd -- "${parent}/${cwd_name}"
}

cwd_media_doc_globs() {
  # Caller must enable nullglob; prints matching names as separate words via array assign.
  shopt -s nullglob
  local -a targets=( *.mp3 *.m4a *.aac *.jpg *.doc *.pdf *.rtf *.txt *.MP3 *.M4A *.AAC *.JPG *.DOC *.PDF *.RTF *.TXT )
  shopt -u nullglob
  printf '%s\0' "${targets[@]}"
}

sanitize_files_in_cwd() {
  local expr
  local -a targets=()

  mapfile -d '' -t targets < <(cwd_media_doc_globs)
  if (( ${#targets[@]} == 1 )) && [[ -z "${targets[0]:-}" ]]; then
    targets=()
  fi
  if (( ${#targets[@]} == 0 )); then
    return 0
  fi

  for expr in "${RENAME_EXPRS[@]}"; do
    mapfile -d '' -t targets < <(cwd_media_doc_globs)
    if (( ${#targets[@]} == 1 )) && [[ -z "${targets[0]:-}" ]]; then
      targets=()
    fi
    if (( ${#targets[@]} == 0 )); then
      return 0
    fi
    run_perl_rename "$expr" "${targets[@]}"
  done
}

zero_pad_single_digit_indices() {
  local n
  local -a targets=()

  for n in 1 2 3 4 5 6 7 8 9; do
    mapfile -d '' -t targets < <(cwd_media_doc_globs)
    if (( ${#targets[@]} == 1 )) && [[ -z "${targets[0]:-}" ]]; then
      targets=()
    fi
    if (( ${#targets[@]} == 0 )); then
      return 0
    fi
    rename --verbose "s|_${n}_|_0${n}_|g" "${targets[@]}" || true
  done
}

echo "---- Script start $0 ($(date '+%Y.%m.%d %H:%M:%S'))"

FFMPEG_BIN="$(resolve_ffmpeg_bin)" || die "ffmpeg not found (set FFMPEG_BIN or install ffmpeg)."
require_cmd rename
require_cmd rar

FFMPEG_RESOLVED="$(readlink -f "${FFMPEG_BIN}" 2>/dev/null || printf '%s' "${FFMPEG_BIN}")"
FFMPEG_VERSION="$("${FFMPEG_BIN}" -hide_banner -version 2>/dev/null | head -n1 || true)"

SOURCE_DIR="."
MONO_ARGS=( -ac 1 )
FFMPEG_COMMON_ARGS=( -y -hide_banner -loglevel error )

mkdir -p -- org
chmod --reference=. org 2>/dev/null || true
chown --reference=. org 2>/dev/null || true
touch --reference=. org 2>/dev/null || true

ls -l -- "$SOURCE_DIR"

echo "(PGM) speed factor (atempo) = $SPEED_FACTOR"
echo "ffmpeg: ${FFMPEG_RESOLVED}"
if [[ -n "${FFMPEG_VERSION}" ]]; then
  echo "  ${FFMPEG_VERSION}"
fi
echo

sanitize_cwd_basename
sanitize_files_in_cwd

mapfile -d '' -t audio_files < <(
  find "${SOURCE_DIR}" -maxdepth 1 -type f \
    \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.aac' \) \
    ! -name '*SPEECHNORM_SPEEDUP*' \
    -print0 | sort -z
)
if (( ${#audio_files[@]} == 1 )) && [[ -z "${audio_files[0]:-}" ]]; then
  audio_files=()
fi

if (( ${#audio_files[@]} == 0 )); then
  echo "No .mp3 / .m4a / .aac files to process in: $(pwd -P)"
else
  for src in "${audio_files[@]}"; do
    # find may return ./file; normalize
    src="${src#./}"
    if [[ ! -f "$src" ]]; then
      continue
    fi
    if [[ "$src" == *SPEECHNORM_SPEEDUP* ]]; then
      continue
    fi

    echo "######################################"
    echo
    ext="${src##*.}"
    base="$(basename -- "$src" ".$ext")"
    dir="$(dirname -- "$src")"
    output_file="${dir}/${base}_SPEECHNORM_SPEEDUP_${SPEED_FACTOR}.aac"

    echo "Processing: $src"
    echo "Output:     $output_file"

    if ! "${FFMPEG_BIN}" "${FFMPEG_COMMON_ARGS[@]}" -i "$src" "${MONO_ARGS[@]}" \
      -filter:a "atempo=${SPEED_FACTOR},speechnorm" "$output_file"; then
      echo
      echo "!!!!! ffmpeg failed for file: $src !!!!!!!!"
      echo "Exiting."
      echo
      rm -f -- "$output_file"
      exit 2
    fi

    chmod --reference="$src" -- "$output_file" 2>/dev/null || true
    chown --reference="$src" -- "$output_file" 2>/dev/null || true
    touch --reference="$src" -- "$output_file" 2>/dev/null || true
    mv -v -- "$src" org/
    sleep 0.2
  done
fi

cd -- "$SOURCE_DIR"
zero_pad_single_digit_indices

if [[ -d org ]] && compgen -G 'org/*' >/dev/null 2>&1; then
  rar m -htb -m5 org.rar org
elif [[ -d org ]]; then
  echo "org/ is empty; skipping rar pack."
fi

echo "---- Script end   $0 ($(date '+%Y.%m.%d %H:%M:%S'))"
exit 0
