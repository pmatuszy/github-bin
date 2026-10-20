#!/bin/bash
# v. 20261020.162300 - when name and mtime match and CreateDate is missing, default is apply that date (not Skip)
# v. 20261020.155800 - Fix dates prompt: capitalise the default key (e.g. S when Skip is default)
# v. 20261020.150700 - date menu always lists File name, Filesystem, and Media tags (n/a when unusable)
# v. 20261020.150400 - date menu: ASCII n/a so parenthetical notes share one column
# v. 20261020.145500 - fix file / media dates when the name, filesystem, and tags disagree
#
# 2026.10.20 - v. 0.1.5 - when name and mtime already match and only CreateDate is missing, default is to apply that date (filesystem + media tags), not Skip
# 2026.10.20 - v. 0.1.4 - Fix dates prompt shows the default key in capitals (e.g. 1/2/3/4/a/S/q), like the other scripts
# 2026.10.20 - v. 0.1.2 - always show File name, Filesystem, and Media tags rows (n/a when missing or before 1990)
# 2026.10.20 - v. 0.1.1 - date menu uses ASCII n/a (UTF-8 dash broke the column of the notes in parentheses)
# 2026.10.20 - v. 0.1 - initial release: for video, audio, and pictures, compare the
#   file-name stamp, filesystem mtime, and media CreateDate (or DateTimeOriginal);
#   ask which to use (1/2/3…); default is the oldest usable date; stamps before 1990
#   are ignored; write media CreateDate/ModifyDate and filesystem times (Windows
#   creation on /mnt/?/…). -y applies the oldest without asking. [a] uses oldest for
#   every later file in this run.
#
# media-pgm-fix-dates.sh
#
# Align filesystem times and media CreateDate when they disagree with each other
# or with a date stamp in the file name.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-r|--recursive] [--dry-run]
       [FILE|DIR ...]

Compare the date in the file name, the filesystem time, and the media
CreateDate (DateTimeOriginal for many photos). When they disagree by more
than two minutes, ask which date to use. The default is the oldest usable
stamp. Dates before 1990-01-01 are ignored.

Applies to video, audio, and picture files. With no FILE or DIR, scan the
current directory (not subdirectories unless -r).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Apply the oldest usable date without asking.
  -r, --recursive      Also scan subdirectories.
  --dry-run            Show what would change; do not write.

Interactive keys (per file):
  1/2/3…               Pick a listed source (default = oldest usable).
  a                    Apply the oldest usable date for this file and every
                       later file in this run (no more prompts).
  s                    Skip this file.
  q                    Quit.

Examples:
  $(basename "$0")
      Scan *.mp4 / *.jpg / … in this directory; ask when dates disagree.

  $(basename "$0") -y -r /mnt/p/video/trip
      Recursively apply the oldest usable date to every mismatch.

  $(basename "$0") --dry-run clip.mp4 photo.jpg
      Show the choice for those files only.

Environment:
  MFD_EXIFTOOL / EXIFLOC / PGM_EXIFTOOL
                       Path to exiftool (else exiftool on PATH).
EOF
}

# --- after header is sourced ---
mfd_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

mfd_read_key() {
  local prompt="$1" default="${2:-}" answer=
  if (( ! script_is_run_interactively )); then
    REPLY="$default"
    return 0
  fi
  printf '%s %s' "$(mfd_ts)" "$prompt"
  if [[ -t 0 ]]; then
    read -n 1 answer || answer=
  else
    REPLY="$default"
    return 0
  fi
  echo
  if [[ -z "$answer" ]]; then
    REPLY="$default"
  else
    REPLY="$answer"
  fi
}

mfd_choice() {
  local c="${1,,}"
  c="${c//$'\r'/}"
  c="${c//$'\n'/}"
  printf '%s\n' "$c"
}

# Key for a prompt: capital when it is the default (mfd_k s s -> S, mfd_k a s -> a).
mfd_k() {
  local key="$1" def="$2"
  if [[ "${key,,}" == "${def,,}" ]]; then
    printf '%s' "${key^^}"
  else
    printf '%s' "$key"
  fi
}

# Keys for a prompt line with the default in capitals: mfd_keys s 1 2 3 4 a s q -> 1/2/3/4/a/S/q
mfd_keys() {
  local def="$1" k out=""
  shift
  for k in "$@"; do
    out+="${out:+/}$(mfd_k "$k" "$def")"
  done
  printf '%s\n' "$out"
}

mfd_find_exiftool() {
  local p
  for p in "${MFD_EXIFTOOL:-}" "${EXIFLOC:-}" "${PGM_EXIFTOOL:-}"; do
    if [[ -n "$p" && -x "$p" ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  p="$(command -v exiftool 2>/dev/null)" || return 1
  printf '%s\n' "$p"
}

MFD_TIME_MIN_EPOCH=""
mfd_time_min_epoch() {
  if [[ -z "$MFD_TIME_MIN_EPOCH" ]]; then
    MFD_TIME_MIN_EPOCH="$(date -d '1990-01-01 00:00:00' +%s 2>/dev/null || printf '631152000')"
  fi
  printf '%s\n' "$MFD_TIME_MIN_EPOCH"
}

mfd_epoch_usable() {
  local e="${1:-}"
  [[ "$e" =~ ^[0-9]+$ ]] || return 1
  (( e >= $(mfd_time_min_epoch) )) || return 1
  return 0
}

mfd_format_epoch_display() {
  local e="$1"
  date -d "@${e}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null \
    || date -r "$e" '+%Y.%m.%d %H:%M:%S' 2>/dev/null \
    || printf '%s\n' "$e"
}

mfd_abs_diff() {
  local a="$1" b="$2"
  if (( a > b )); then printf '%s\n' "$((a - b))"
  else printf '%s\n' "$((b - a))"
  fi
}

# File-name stamp → Unix epoch (local). Covers video/audio/photo common patterns.
mfd_filename_epoch_from_basename() {
  local base="$1" d t iso e
  base="${base##*/}"
  # YYYYMMDD_HHMMSS or YYYYMMDD-HHMMSS at start
  if [[ "$base" =~ ^([0-9]{8})[_-]([0-9]{6}) ]]; then
    d="${BASH_REMATCH[1]}"
    t="${BASH_REMATCH[2]}"
  # IMG_/VID_/PXL_/DSC_ + YYYYMMDD_HHMMSS
  elif [[ "$base" =~ ^(IMG|VID|PXL|DSC|MVI)_([0-9]{8})[_-]([0-9]{6}) ]]; then
    d="${BASH_REMATCH[2]}"
    t="${BASH_REMATCH[3]}"
  # 70mai NO/EV
  elif [[ "$base" =~ ^[Nn][Oo]([0-9]{8})-([0-9]{6}) ]]; then
    d="${BASH_REMATCH[1]}"
    t="${BASH_REMATCH[2]}"
  elif [[ "$base" =~ ^[Ee][Vv]([0-9]{8})-([0-9]{6}) ]]; then
    d="${BASH_REMATCH[1]}"
    t="${BASH_REMATCH[2]}"
  # YYYY-MM-DD_HH-MM-SS or YYYY-MM-DD HH.MM.SS
  elif [[ "$base" =~ ([0-9]{4})-([0-9]{2})-([0-9]{2})[[:space:]_-]([0-9]{2})[._-]([0-9]{2})[._-]([0-9]{2}) ]]; then
    d="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
    t="${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}"
  else
    return 1
  fi
  iso="${d:0:4}-${d:4:2}-${d:6:2} ${t:0:2}:${t:2:2}:${t:4:2}"
  e="$(date -d "$iso" +%s 2>/dev/null)" || return 1
  mfd_epoch_usable "$e" || return 1
  printf '%s\n' "$e"
}

mfd_fs_mtime_epoch() {
  local f="$1" e
  e="$(stat -c %Y -- "$f" 2>/dev/null || stat -f %m -- "$f" 2>/dev/null)" || return 1
  mfd_epoch_usable "$e" || return 1
  printf '%s\n' "$e"
}

mfd_media_createdate_epoch() {
  local f="$1" exif raw line e
  exif="$(mfd_find_exiftool 2>/dev/null)" || return 1
  while IFS= read -r line; do
    raw="$(printf '%s' "$line" | tr -d '\r')"
    [[ -n "$raw" && "$raw" != "0000:00:00 00:00:00" ]] || continue
    e="$(date -d "$raw" +%s 2>/dev/null)" || continue
    if mfd_epoch_usable "$e"; then
      printf '%s\n' "$e"
      return 0
    fi
  done < <("$exif" -api largefilesupport=1 -s3 \
    -CreateDate -DateTimeOriginal -MediaCreateDate -TrackCreateDate \
    -d '%Y:%m:%d %H:%M:%S' -- "$f" 2>/dev/null)
  return 1
}

mfd_set_fs_times_epoch() {
  local dest="$1" epoch="$2" touch_fmt dest_w
  [[ -f "$dest" && "$epoch" =~ ^[0-9]+$ ]] || return 1
  touch_fmt="$(date -d "@${epoch}" +%Y%m%d%H%M.%S 2>/dev/null)" || return 1
  touch -t "$touch_fmt" -- "$dest" 2>/dev/null || return 1
  if [[ "$dest" == /mnt/?/* ]] \
    && command -v powershell.exe >/dev/null 2>&1 \
    && command -v wslpath >/dev/null 2>&1; then
    dest_w=$(wslpath -w "$dest") || return 0
    dest_w=${dest_w//\'/\'\'}
    powershell.exe -NoProfile -Command \
      "\$d = Get-Item -LiteralPath '${dest_w}'; \$t = [DateTimeOffset]::FromUnixTimeSeconds(${epoch}).LocalDateTime; \$d.CreationTime = \$t; \$d.LastWriteTime = \$t" \
      >/dev/null 2>&1 || true
  fi
  return 0
}

mfd_set_media_dates_epoch() {
  local dest="$1" epoch="$2" exif iso ok=0
  [[ -f "$dest" && "$epoch" =~ ^[0-9]+$ ]] || return 1
  exif="$(mfd_find_exiftool 2>/dev/null)" || return 1
  iso="$(date -d "@${epoch}" '+%Y:%m:%d %H:%M:%S' 2>/dev/null)" || return 1
  if "$exif" -overwrite_original -P -api QuickTimeUTC=1 \
    -AllDates="$iso" \
    -CreateDate="$iso" -ModifyDate="$iso" -DateTimeOriginal="$iso" \
    -TrackCreateDate="$iso" -TrackModifyDate="$iso" \
    -MediaCreateDate="$iso" -MediaModifyDate="$iso" \
    -- "$dest" >/dev/null 2>&1; then
    ok=1
  elif "$exif" -overwrite_original -P \
    -AllDates="$iso" \
    -CreateDate="$iso" -ModifyDate="$iso" -DateTimeOriginal="$iso" \
    -- "$dest" >/dev/null 2>&1; then
    ok=1
  fi
  "$exif" -overwrite_original -P -api QuickTimeUTC=1 \
    -FileCreateDate="$iso" -FileModifyDate="$iso" \
    -- "$dest" >/dev/null 2>&1 || true
  (( ok ))
}

mfd_apply_epoch() {
  local dest="$1" epoch="$2" disp
  disp="$(mfd_format_epoch_display "$epoch")"
  if (( DRY_RUN )); then
    echo "$(mfd_ts) DRY-RUN would set media + filesystem times to ${disp} for ${dest##*/}"
    return 0
  fi
  if mfd_set_media_dates_epoch "$dest" "$epoch"; then
    echo "$(mfd_ts) Media CreateDate: ${disp}"
  else
    echo "$(mfd_ts) Media CreateDate: could not write ${disp}" >&2
  fi
  if mfd_set_fs_times_epoch "$dest" "$epoch"; then
    echo "$(mfd_ts) Filesystem times: ${disp}"
  else
    echo "$(mfd_ts) Filesystem times: could not set ${disp}" >&2
  fi
}

mfd_is_media_file() {
  local base="${1##*/}" ext
  ext="${base##*.}"
  ext="${ext,,}"
  case "$ext" in
    mp4|mov|m4v|mkv|avi|webm|mts|m2ts|mpg|mpeg|wmv|3gp)
      return 0 ;;
    mp3|m4a|aac|wav|flac|ogg|opus|wma|aiff|aif)
      return 0 ;;
    jpg|jpeg|png|tif|tiff|heic|heif|webp|gif|bmp|raw|cr2|cr3|nef|arw|dng|orf|rw2)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

mfd_collect_from_dir() {
  local dir="$1" f
  if (( RECURSIVE )); then
    while IFS= read -r -d '' f; do
      mfd_is_media_file "$f" || continue
      FILES+=("$f")
    done < <(find "$dir" -type f -print0 2>/dev/null)
  else
    shopt -s nullglob nocaseglob
    for f in "$dir"/*; do
      [[ -f "$f" ]] || continue
      mfd_is_media_file "$f" || continue
      FILES+=("$f")
    done
    shopt -u nocaseglob
  fi
}

# Return 0 if this file needs a decision; sets globals for the prompt.
# MFD_LABELS / MFD_EPOCHS / MFD_NOTES / MFD_DEF / MFD_DEFAULT_KEY / MFD_OLDEST_E
mfd_prepare_file() {
  local f="$1"
  local name_e="" fs_e="" media_e=""
  local i n oldest_e="" oldest_i=0 need=0 abs_diff
  MFD_LABELS=()
  MFD_EPOCHS=()
  MFD_NOTES=()
  MFD_DEF=1
  MFD_DEFAULT_KEY=1
  MFD_OLDEST_E=""

  name_e="$(mfd_filename_epoch_from_basename "${f##*/}" 2>/dev/null || true)"
  fs_e="$(mfd_fs_mtime_epoch "$f" 2>/dev/null || true)"
  media_e="$(mfd_media_createdate_epoch "$f" 2>/dev/null || true)"

  # Need at least one usable stamp that can be compared.
  if [[ -z "$name_e" && -z "$fs_e" && -z "$media_e" ]]; then
    return 1
  fi

  if [[ -n "$name_e" && -n "$fs_e" ]]; then
    abs_diff="$(mfd_abs_diff "$name_e" "$fs_e")"
    (( abs_diff > 120 )) && need=1
  fi
  if [[ -n "$name_e" && -n "$media_e" ]]; then
    abs_diff="$(mfd_abs_diff "$name_e" "$media_e")"
    (( abs_diff > 120 )) && need=1
  fi
  if [[ -n "$fs_e" && -n "$media_e" ]]; then
    abs_diff="$(mfd_abs_diff "$fs_e" "$media_e")"
    (( abs_diff > 120 )) && need=1
  fi
  # Name present but no other usable stamp that matches → still offer to apply name.
  if [[ -n "$name_e" && -z "$fs_e" && -z "$media_e" ]]; then
    need=1
  fi
  # Media CreateDate missing/unusable while another stamp exists → offer to set it.
  if [[ -z "$media_e" && ( -n "$name_e" || -n "$fs_e" ) ]]; then
    need=1
  fi
  (( need )) || return 1

  # Always list all three sources so a missing CreateDate is visible.
  MFD_LABELS+=("File name")
  MFD_EPOCHS+=("${name_e}")
  if [[ -n "$name_e" ]]; then
    MFD_NOTES+=("")
  else
    MFD_NOTES+=("(no stamp in name, or before 1990)")
  fi
  MFD_LABELS+=("Filesystem")
  MFD_EPOCHS+=("${fs_e}")
  if [[ -n "$fs_e" ]]; then
    MFD_NOTES+=("(mtime)")
  else
    MFD_NOTES+=("(mtime missing or before 1990)")
  fi
  MFD_LABELS+=("Media tags")
  MFD_EPOCHS+=("${media_e}")
  if [[ -n "$media_e" ]]; then
    MFD_NOTES+=("(CreateDate / DateTimeOriginal)")
  else
    MFD_NOTES+=("(CreateDate missing or before 1990)")
  fi
  MFD_LABELS+=("Keep as written")
  MFD_EPOCHS+=("")
  MFD_NOTES+=("(leave this file as it is)")

  n=${#MFD_LABELS[@]}
  for (( i = 0; i < n; i++ )); do
    [[ -n "${MFD_EPOCHS[i]}" ]] || continue
    if [[ -z "$oldest_e" ]] || (( MFD_EPOCHS[i] < oldest_e )); then
      oldest_e="${MFD_EPOCHS[i]}"
      oldest_i=$i
    fi
  done
  MFD_OLDEST_E="$oldest_e"
  MFD_DEF=$((oldest_i + 1))
  MFD_DEFAULT_KEY="$MFD_DEF"
  return 0
}

mfd_process_file() {
  local f="$1"
  local i n choice disp note prompt_keys
  local -a key_list=()

  if ! mfd_prepare_file "$f"; then
    return 0
  fi
  MISMATCH=$((MISMATCH + 1))
  n=${#MFD_LABELS[@]}

  if (( DO_YES )) || (( ALWAYS_OLDEST )) || (( ! script_is_run_interactively )); then
    echo
    echo "$(mfd_ts) Dates disagree: ${f}"
    if [[ -n "$MFD_OLDEST_E" ]]; then
      mfd_apply_epoch "$f" "$MFD_OLDEST_E"
      FIXED=$((FIXED + 1))
    fi
    return 0
  fi

  echo
  echo "$(mfd_ts) Dates disagree: ${f}"
  echo
  echo "  Sources (oldest usable is the default; applying it sets media CreateDate and filesystem times):"
  echo
  key_list=()
  for (( i = 0; i < n; i++ )); do
    note="${MFD_NOTES[i]}"
    if [[ -n "${MFD_EPOCHS[i]}" ]]; then
      disp="$(mfd_format_epoch_display "${MFD_EPOCHS[i]}")"
    else
      disp="n/a"
    fi
    if (( i + 1 == MFD_DEF )); then
      if [[ -n "$note" ]]; then
        note="${note} (oldest - default)"
      else
        note="(oldest - default)"
      fi
    fi
    # ASCII-only date column so %-19s matches terminal columns (UTF-8 "—" broke alignment).
    printf '  [%d] %-18s %-19s  %s\n' \
      "$((i + 1))" "${MFD_LABELS[i]}" "$disp" "$note"
    key_list+=("$((i + 1))")
  done
  echo "  [$(mfd_k a "$MFD_DEFAULT_KEY")] Always oldest for the rest of this run"
  echo "  [$(mfd_k s "$MFD_DEFAULT_KEY")] Skip this file"
  echo "  [$(mfd_k q "$MFD_DEFAULT_KEY")] Quit"
  key_list+=(a s q)
  prompt_keys="$(mfd_keys "$MFD_DEFAULT_KEY" "${key_list[@]}")"

  while true; do
    mfd_read_key "Fix dates [${prompt_keys}]: " "$MFD_DEFAULT_KEY"
    choice="$(mfd_choice "$REPLY")"
    case "$choice" in
      q)
        echo "$(mfd_ts) Quit."
        return 2
        ;;
      s)
        echo "$(mfd_ts) Skipped: ${f##*/}"
        SKIPPED=$((SKIPPED + 1))
        return 0
        ;;
      a)
        ALWAYS_OLDEST=1
        if [[ -n "$MFD_OLDEST_E" ]]; then
          mfd_apply_epoch "$f" "$MFD_OLDEST_E"
          FIXED=$((FIXED + 1))
        fi
        echo "$(mfd_ts) Will use the oldest usable date for every later file."
        return 0
        ;;
    esac
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= n )); then
      i=$((choice - 1))
      # Keep is the last row and has an empty epoch on purpose.
      if (( i == n - 1 )); then
        echo "$(mfd_ts) Kept as written: ${f##*/}"
        SKIPPED=$((SKIPPED + 1))
        return 0
      fi
      if [[ -z "${MFD_EPOCHS[i]}" ]]; then
        echo "$(mfd_ts) ${MFD_LABELS[i]} is n/a (not usable). Pick another."
        continue
      fi
      mfd_apply_epoch "$f" "${MFD_EPOCHS[i]}"
      FIXED=$((FIXED + 1))
      echo "$(mfd_ts) Set from ${MFD_LABELS[i]}: $(mfd_format_epoch_display "${MFD_EPOCHS[i]}")"
      return 0
    fi
    echo "$(mfd_ts) Unknown choice: ${REPLY}."
  done
}

# --- options ---
DO_YES=0
RECURSIVE=0
DRY_RUN=0
ALWAYS_OLDEST=0
FIXED=0
SKIPPED=0
SCANNED=0
MISMATCH=0
FILES=()
POSITIONALS=()

. "${profile_location_dir:-$HOME}/bin/_script_header.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      print_version_banner
      exit 0
      ;;
    --history)
      print_script_history
      exit 0
      ;;
    -y|--yes)
      DO_YES=1
      shift
      ;;
    -r|--recursive)
      RECURSIVE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --)
      shift
      POSITIONALS+=("$@")
      break
      ;;
    -*)
      echo "$(mfd_ts) Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
    *)
      POSITIONALS+=("$1")
      shift
      ;;
  esac
done

if [[ -f "${BASH_SOURCE[0]}" ]]; then
  chmod 700 "${BASH_SOURCE[0]}" 2>/dev/null || true
fi

print_version_banner

if ! mfd_find_exiftool >/dev/null; then
  echo "$(mfd_ts) exiftool not found (set MFD_EXIFTOOL or install exiftool)." >&2
  exit 1
fi

if (( ${#POSITIONALS[@]} == 0 )); then
  mfd_collect_from_dir .
else
  for p in "${POSITIONALS[@]}"; do
    if [[ -d "$p" ]]; then
      mfd_collect_from_dir "$p"
    elif [[ -f "$p" ]]; then
      if mfd_is_media_file "$p"; then
        FILES+=("$p")
      else
        echo "$(mfd_ts) Not a known media type (skipped): $p" >&2
      fi
    else
      echo "$(mfd_ts) Not found: $p" >&2
    fi
  done
fi

if (( ${#FILES[@]} == 0 )); then
  echo "$(mfd_ts) No media files to check."
  exit 0
fi

mapfile -t FILES < <(printf '%s\n' "${FILES[@]}" | LC_ALL=C sort -u)
SCANNED=${#FILES[@]}

echo
echo "$(mfd_ts) Checking ${SCANNED} media file(s)."
(( DRY_RUN )) && echo "$(mfd_ts) Dry run — nothing will be written."
(( DO_YES )) && echo "$(mfd_ts) -y: apply oldest usable date without asking."
echo

for f in "${FILES[@]}"; do
  mfd_process_file "$f"
  rc=$?
  if (( rc == 2 )); then
    break
  fi
done

echo
echo "$(mfd_ts) Done. Scanned ${SCANNED}; disagreed ${MISMATCH}; fixed ${FIXED}; skipped/kept ${SKIPPED}."
exit 0
