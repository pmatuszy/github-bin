#!/bin/bash
# v. 20261115.091200 - ask when Make/Model/Comment already set; safe -y (fill empty only)
# v. 20261115.091000 - Contour profile is Contour+2 only (drop ROAM/GPS generics)
# v. 20261115.090000 - initial: set Make/Model/Comment camera profiles (Contour, GoPro, 70mai, custom)
#
# 2026.11.15 - v. 0.1.2 - if Make/Model/Comment already filled but do not match the profile, ask: overwrite [Y], merge empty fields only [m], keep [k], overwrite rest-of-run [a], keep-existing rest-of-run [K]; -y only tags fully empty files (keeps differing existing tags)
# 2026.11.15 - v. 0.1.1 - Contour preset is Contour+2 Camera only (Make=Contour Model=Contour+2); removed Contour / ROAM / GPS generics
# 2026.11.15 - v. 0.1 - initial release: tag video files with camera identity (Make, Model,
#   Comment) so Contour / GoPro / 70mai detection does not rely on filename alone. Profiles
#   Contour+2, GoPro, 70mai-A510, or custom Make/Model. Idempotent: files that already match
#   are skipped. -y / --camera apply without a profile menu; --dry-run; -r; --verbose;
#   per-file prompts; end-of-run summary.
#
# video-pgm-set-camera-metadata.sh
#
# Embed camera Make / Model / Comment on MP4 (and similar) files for later scripts.
#

show_help() {
  cat <<EOF
Usage: $(script_live_basename) [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-r|--recursive] [--dry-run] [--verbose]
       [--camera PROFILE]
       [FILE|DIR ...]

Write camera identity into video metadata (Make, Model, Comment) so other
scripts can detect Contour+2 / GoPro / 70mai without guessing from the file
name alone. Exact matches are skipped. If tags are already filled but differ
from the profile, you are asked what to do (overwrite / merge empties / keep).

With no FILE or DIR, scan the current directory (not subdirectories unless -r).

Camera profiles (--camera or interactive menu):
  contour-plus-2  Make=Contour  Model=Contour+2  Comment=Contour+2 Camera
                  (aliases: contour+2, contour2, contour)
  gopro           Make=GoPro    Model=GoPro      Comment=GoPro
  70mai           Make=70mai    Model=A510       Comment=70mai-A510
  custom          Ask for Make and Model (Comment = Make Model)

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Apply without asking (needs --camera, or custom via
                       --make / --model). Safe: only tags files where Make,
                       Model, and Comment are all empty; keeps differing
                       existing tags.
  -r, --recursive      Also scan subdirectories.
  --dry-run            Show what would change; do not write.
  --verbose            Print current tags even when already matching.
  --camera PROFILE     One of: contour-plus-2 (aliases contour+2, contour2,
                       contour), gopro, 70mai, custom (see above).
  --make TEXT          Custom Make (implies --camera custom when set with --model).
  --model TEXT         Custom Model.

Interactive keys (per file, when not -y):
  Empty tags:
  [Y] Apply this file (default)
  [a] Overwrite/apply this and every later file
  [n] Skip this file
  [q] Quit

  Tags already filled (but not matching the profile):
  [Y] Overwrite with the profile (default)
  [m] Merge — fill only empty fields; keep non-empty Make/Model/Comment
  [k] Keep current tags on this file
  [a] Overwrite this and every later file that differs
  [K] Keep existing tags for the rest of this run (only tag fully empty files)
  [n] Skip this file
  [q] Quit

Needs: exiftool.

Examples:
  $(script_live_basename) --camera contour-plus-2 .
      Tag Contour+2 on every video in this directory (asks per file).

  $(script_live_basename) -y --camera contour+2 --dry-run .
      Plan Contour+2 tags; write nothing.

  $(script_live_basename) -y --make Contour --model Contour+2 ./clip.mp4
      Set custom Make/Model without asking.

Environment:
  SCM_EXIFTOOL / EXIFLOC / PGM_EXIFTOOL
                       Path to exiftool (else exiftool on PATH).
EOF
}

# --- after header is sourced ---
scm_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

scm_print_selected() {
  echo "$(scm_ts) Selected: $*"
}

scm_read_key() {
  local prompt="$1" default="${2:-}" answer=
  if (( ! script_is_run_interactively )); then
    REPLY="$default"
    return 0
  fi
  printf '%s %s' "$(scm_ts)" "$prompt"
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

scm_choice() {
  printf '%s\n' "${1,,}"
}

# Capitalise the default key in a [Y/n/a/q]-style list.
scm_k() {
  local key="$1" default="$2"
  if [[ "${key,,}" == "${default,,}" ]]; then
    printf '%s\n' "${key^^}"
  else
    printf '%s\n' "${key,,}"
  fi
}

scm_keys() {
  local default="$1"
  shift
  local k out="" sep=""
  for k in "$@"; do
    out+="${sep}$(scm_k "$k" "$default")"
    sep="/"
  done
  printf '%s\n' "$out"
}

scm_find_exiftool() {
  local p
  for p in "${SCM_EXIFTOOL:-}" "${EXIFLOC:-}" "${PGM_EXIFTOOL:-}"; do
    [[ -n "$p" && -x "$p" ]] && { printf '%s\n' "$p"; return 0; }
  done
  command -v exiftool 2>/dev/null
}

scm_is_video_file() {
  local base="${1##*/}" ext
  ext="${base##*.}"
  ext="${ext,,}"
  case "$ext" in
    mp4|mov|m4v|mkv|avi|webm|mts|m2ts|mpg|mpeg|wmv|3gp)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

scm_collect_from_dir() {
  local dir="$1" f
  if (( RECURSIVE )); then
    while IFS= read -r -d '' f; do
      scm_is_video_file "$f" || continue
      FILES+=("$f")
    done < <(find "$dir" -type f -print0 2>/dev/null)
  else
    shopt -s nullglob nocaseglob
    for f in "$dir"/*; do
      [[ -f "$f" ]] || continue
      scm_is_video_file "$f" || continue
      FILES+=("$f")
    done
    shopt -u nocaseglob
  fi
}

scm_rule() {
  printf '%s\n' "========================================================================"
}

scm_print_processing() {
  local f="$1"
  echo
  scm_rule
  echo "$(scm_ts) Processing: ${f}"
  scm_rule
}

# Sets SCM_CUR_MAKE / SCM_CUR_MODEL / SCM_CUR_COMMENT (may be empty).
scm_read_camera_tags() {
  local f="$1" exif
  SCM_CUR_MAKE=""
  SCM_CUR_MODEL=""
  SCM_CUR_COMMENT=""
  exif="$(scm_find_exiftool 2>/dev/null)" || return 1
  SCM_CUR_MAKE="$("$exif" -api largefilesupport=1 -s3 -Make -- "$f" 2>/dev/null | head -n1 | tr -d '\r')"
  SCM_CUR_MODEL="$("$exif" -api largefilesupport=1 -s3 -Model -- "$f" 2>/dev/null | head -n1 | tr -d '\r')"
  SCM_CUR_COMMENT="$("$exif" -api largefilesupport=1 -s3 -Comment -- "$f" 2>/dev/null | head -n1 | tr -d '\r')"
  # Some files only have QuickTime peers.
  if [[ -z "$SCM_CUR_MAKE" ]]; then
    SCM_CUR_MAKE="$("$exif" -api largefilesupport=1 -s3 -QuickTime:Make -- "$f" 2>/dev/null | head -n1 | tr -d '\r')"
  fi
  if [[ -z "$SCM_CUR_MODEL" ]]; then
    SCM_CUR_MODEL="$("$exif" -api largefilesupport=1 -s3 -QuickTime:Model -- "$f" 2>/dev/null | head -n1 | tr -d '\r')"
  fi
  return 0
}

scm_tags_match_wanted() {
  local want_make="$1" want_model="$2" want_comment="$3"
  [[ "${SCM_CUR_MAKE}" == "$want_make" ]] || return 1
  [[ "${SCM_CUR_MODEL}" == "$want_model" ]] || return 1
  [[ "${SCM_CUR_COMMENT}" == "$want_comment" ]] || return 1
  return 0
}

scm_tags_all_empty() {
  [[ -z "${SCM_CUR_MAKE}" && -z "${SCM_CUR_MODEL}" && -z "${SCM_CUR_COMMENT}" ]]
}

scm_tags_any_filled() {
  [[ -n "${SCM_CUR_MAKE}" || -n "${SCM_CUR_MODEL}" || -n "${SCM_CUR_COMMENT}" ]]
}

# Merge: keep non-empty current fields; fill empties from wanted. Sets SCM_MERGED_*.
scm_compute_merged_tags() {
  local want_make="$1" want_model="$2" want_comment="$3"
  if [[ -n "$SCM_CUR_MAKE" ]]; then SCM_MERGED_MAKE="$SCM_CUR_MAKE"; else SCM_MERGED_MAKE="$want_make"; fi
  if [[ -n "$SCM_CUR_MODEL" ]]; then SCM_MERGED_MODEL="$SCM_CUR_MODEL"; else SCM_MERGED_MODEL="$want_model"; fi
  if [[ -n "$SCM_CUR_COMMENT" ]]; then SCM_MERGED_COMMENT="$SCM_CUR_COMMENT"; else SCM_MERGED_COMMENT="$want_comment"; fi
}

scm_merged_changes_anything() {
  [[ "$SCM_MERGED_MAKE" != "$SCM_CUR_MAKE" \
    || "$SCM_MERGED_MODEL" != "$SCM_CUR_MODEL" \
    || "$SCM_MERGED_COMMENT" != "$SCM_CUR_COMMENT" ]]
}

scm_disp_tag() {
  local v="$1"
  if [[ -z "$v" ]]; then
    printf 'n/a\n'
  else
    printf '%s\n' "$v"
  fi
}

# Apply Make/Model/Comment. Returns 0 on success or dry-run.
scm_apply_camera_tags() {
  local dest="$1" want_make="$2" want_model="$3" want_comment="$4"
  local exif
  [[ -f "$dest" ]] || return 1
  if (( DRY_RUN )); then
    echo "$(scm_ts) DRY-RUN would set Make=${want_make} Model=${want_model} Comment=${want_comment}"
    return 0
  fi
  exif="$(scm_find_exiftool 2>/dev/null)" || return 1
  # -P: do not bump filesystem mtime while writing tags.
  if "$exif" -overwrite_original -P -api largefilesupport=1 \
    -Make="$want_make" -Model="$want_model" -Comment="$want_comment" \
    -QuickTime:Make="$want_make" -QuickTime:Model="$want_model" \
    -QuickTime:Comment="$want_comment" \
    -- "$dest" >/dev/null 2>&1; then
    return 0
  fi
  # Fallback without QuickTime: peers.
  "$exif" -overwrite_original -P -api largefilesupport=1 \
    -Make="$want_make" -Model="$want_model" -Comment="$want_comment" \
    -- "$dest" >/dev/null 2>&1
}

scm_do_tag_write() {
  local f="$1" make="$2" model="$3" comment="$4" how="$5"
  if scm_apply_camera_tags "$f" "$make" "$model" "$comment"; then
    TAGGED=$((TAGGED + 1))
    echo "$(scm_ts) Tagged as ${SCM_CAMERA_LABEL} (${how}): ${f##*/}"
    return 0
  fi
  FAILED=$((FAILED + 1))
  echo "$(scm_ts) Failed to write tags: ${f}" >&2
  return 1
}

scm_normalize_camera_id() {
  local id="${1,,}"
  id="${id//_/-}"
  id="${id// /-}"
  # Contour+2 aliases → one id (plus sign or "plus").
  case "$id" in
    contour|contour2|contour+2|contour-plus-2|contour-plus2|contourplus2)
      printf '%s\n' "contour-plus-2"
      return 0
      ;;
  esac
  printf '%s\n' "$id"
}

# Sets SCM_WANT_MAKE / SCM_WANT_MODEL / SCM_WANT_COMMENT / SCM_CAMERA_LABEL from id.
# custom uses SCM_CUSTOM_MAKE / SCM_CUSTOM_MODEL when already set.
scm_set_profile_from_id() {
  local id
  id="$(scm_normalize_camera_id "$1")"
  case "$id" in
    contour-plus-2)
      SCM_WANT_MAKE="Contour"
      SCM_WANT_MODEL="Contour+2"
      SCM_WANT_COMMENT="Contour+2 Camera"
      SCM_CAMERA_LABEL="Contour+2 Camera"
      ;;
    gopro)
      SCM_WANT_MAKE="GoPro"
      SCM_WANT_MODEL="GoPro"
      SCM_WANT_COMMENT="GoPro"
      SCM_CAMERA_LABEL="GoPro"
      ;;
    70mai|70mai-a510)
      SCM_WANT_MAKE="70mai"
      SCM_WANT_MODEL="A510"
      SCM_WANT_COMMENT="70mai-A510"
      SCM_CAMERA_LABEL="70mai-A510"
      ;;
    custom)
      if [[ -z "${SCM_CUSTOM_MAKE:-}" || -z "${SCM_CUSTOM_MODEL:-}" ]]; then
        return 1
      fi
      SCM_WANT_MAKE="$SCM_CUSTOM_MAKE"
      SCM_WANT_MODEL="$SCM_CUSTOM_MODEL"
      SCM_WANT_COMMENT="${SCM_CUSTOM_MAKE} ${SCM_CUSTOM_MODEL}"
      SCM_CAMERA_LABEL="custom (${SCM_WANT_MAKE} / ${SCM_WANT_MODEL})"
      ;;
    *)
      return 1
      ;;
  esac
  return 0
}

scm_ask_custom_make_model() {
  local make model
  if (( ! script_is_run_interactively )); then
    echo "$(scm_ts) Custom camera needs --make and --model (non-interactive)." >&2
    return 1
  fi
  printf '%s Make: ' "$(scm_ts)"
  read -r make || return 1
  printf '%s Model: ' "$(scm_ts)"
  read -r model || return 1
  make="${make#"${make%%[![:space:]]*}"}"
  make="${make%"${make##*[![:space:]]}"}"
  model="${model#"${model%%[![:space:]]*}"}"
  model="${model%"${model##*[![:space:]]}"}"
  [[ -n "$make" && -n "$model" ]] || {
    echo "$(scm_ts) Make and Model must be non-empty." >&2
    return 1
  }
  SCM_CUSTOM_MAKE="$make"
  SCM_CUSTOM_MODEL="$model"
  return 0
}

scm_choose_camera_profile() {
  local choice
  if [[ -n "${CAMERA_CLI:-}" ]]; then
    if [[ "$(scm_normalize_camera_id "$CAMERA_CLI")" == custom ]]; then
      if [[ -z "${SCM_CUSTOM_MAKE:-}" || -z "${SCM_CUSTOM_MODEL:-}" ]]; then
        scm_ask_custom_make_model || return 1
      fi
    fi
    scm_set_profile_from_id "$CAMERA_CLI" || {
      echo "$(scm_ts) Unknown --camera: ${CAMERA_CLI}" >&2
      return 1
    }
    return 0
  fi
  if [[ -n "${SCM_CUSTOM_MAKE:-}" && -n "${SCM_CUSTOM_MODEL:-}" ]]; then
    scm_set_profile_from_id custom || return 1
    return 0
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    echo "$(scm_ts) -y / non-interactive requires --camera PROFILE (or --make and --model)." >&2
    return 1
  fi
  echo
  echo "  Camera profile (written as Make / Model / Comment):"
  echo
  echo "  [1] Contour+2 Camera"
  echo "  [2] GoPro"
  echo "  [3] 70mai-A510"
  echo "  [4] Custom Make / Model"
  echo "  [q] Quit"
  echo
  while true; do
    scm_read_key "Camera [1/2/3/4/q]: " "1"
    choice="$(scm_choice "$REPLY")"
    case "$choice" in
      1)
        scm_print_selected "1 = Contour+2 Camera"
        scm_set_profile_from_id contour-plus-2
        return 0
        ;;
      2)
        scm_print_selected "2 = GoPro"
        scm_set_profile_from_id gopro
        return 0
        ;;
      3)
        scm_print_selected "3 = 70mai-A510"
        scm_set_profile_from_id 70mai
        return 0
        ;;
      4)
        scm_print_selected "4 = Custom Make / Model"
        scm_ask_custom_make_model || continue
        scm_set_profile_from_id custom || continue
        return 0
        ;;
      q)
        scm_print_selected "q = Quit"
        return 2
        ;;
      *)
        echo "$(scm_ts) Unknown choice: ${REPLY}."
        ;;
    esac
  done
}

scm_print_tag_plan() {
  local f="$1"
  scm_print_processing "$f"
  echo "  Camera profile: ${SCM_CAMERA_LABEL}"
  echo
  printf '  %-10s %-24s %s\n' "" "Current" "Proposed"
  printf '  %-10s %-24s %s\n' "Make" "$(scm_disp_tag "$SCM_CUR_MAKE")" "$SCM_WANT_MAKE"
  printf '  %-10s %-24s %s\n' "Model" "$(scm_disp_tag "$SCM_CUR_MODEL")" "$SCM_WANT_MODEL"
  printf '  %-10s %-24s %s\n' "Comment" "$(scm_disp_tag "$SCM_CUR_COMMENT")" "$SCM_WANT_COMMENT"
}

scm_process_file() {
  local f="$1"
  local def=y keys has_existing=0

  scm_read_camera_tags "$f" || {
    echo "$(scm_ts) Could not read tags: ${f}" >&2
    FAILED=$((FAILED + 1))
    return 0
  }

  if scm_tags_match_wanted "$SCM_WANT_MAKE" "$SCM_WANT_MODEL" "$SCM_WANT_COMMENT"; then
    ALREADY=$((ALREADY + 1))
    if (( VERBOSE )); then
      echo "$(scm_ts) Already tagged (${SCM_CAMERA_LABEL}): ${f##*/}"
      printf '  %-10s %s\n' "Make" "$(scm_disp_tag "$SCM_CUR_MAKE")"
      printf '  %-10s %s\n' "Model" "$(scm_disp_tag "$SCM_CUR_MODEL")"
      printf '  %-10s %s\n' "Comment" "$(scm_disp_tag "$SCM_CUR_COMMENT")"
    fi
    return 0
  fi

  NEED=$((NEED + 1))
  scm_tags_any_filled && has_existing=1

  # Rest-of-run: keep existing non-matching tags; only auto-tag fully empty files.
  if (( ALWAYS_KEEP_EXISTING )); then
    if (( has_existing )); then
      KEPT=$((KEPT + 1))
      echo "$(scm_ts) Kept existing tags (for the rest of this run): ${f##*/}"
      return 0
    fi
    scm_print_tag_plan "$f"
    scm_do_tag_write "$f" "$SCM_WANT_MAKE" "$SCM_WANT_MODEL" "$SCM_WANT_COMMENT" "empty file"
    return 0
  fi

  # Rest-of-run: overwrite every mismatch.
  if (( ALWAYS_APPLY )); then
    scm_print_tag_plan "$f"
    scm_do_tag_write "$f" "$SCM_WANT_MAKE" "$SCM_WANT_MODEL" "$SCM_WANT_COMMENT" "overwrite"
    return 0
  fi

  # -y / non-interactive: safe — only tag fully empty; keep differing existing tags.
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    scm_print_tag_plan "$f"
    if (( has_existing )); then
      KEPT=$((KEPT + 1))
      echo "$(scm_ts) Kept existing tags (-y does not overwrite): ${f##*/}"
      return 0
    fi
    scm_do_tag_write "$f" "$SCM_WANT_MAKE" "$SCM_WANT_MODEL" "$SCM_WANT_COMMENT" "empty file"
    return 0
  fi

  scm_print_tag_plan "$f"
  echo
  if (( has_existing )); then
    echo "  Tags are already filled but do not match ${SCM_CAMERA_LABEL}."
    echo "  [$(scm_k y "$def")] Overwrite with ${SCM_CAMERA_LABEL} (default)"
    echo "  [$(scm_k m "$def")] Merge — fill only empty fields; keep non-empty Make/Model/Comment"
    echo "  [$(scm_k k "$def")] Keep current tags on this file"
    echo "  [$(scm_k a "$def")] Overwrite this and every later file that differs"
    echo "  [$(scm_k K "$def")] Keep existing tags for the rest of this run (only tag fully empty files)"
    echo "  [$(scm_k n "$def")] Skip this file"
    echo "  [$(scm_k q "$def")] Quit"
    keys="$(scm_keys "$def" y m k a K n q)"
  else
    echo "  [$(scm_k y "$def")] Apply this file (default)"
    echo "  [$(scm_k a "$def")] Apply this file and every later file"
    echo "  [$(scm_k n "$def")] Skip this file"
    echo "  [$(scm_k q "$def")] Quit"
    keys="$(scm_keys "$def" y a n q)"
  fi

  while true; do
    scm_read_key "Set camera metadata [${keys}]: " "$def"
    case "$(scm_choice "$REPLY")" in
      y)
        if (( has_existing )); then
          scm_print_selected "y = Overwrite with ${SCM_CAMERA_LABEL}"
          scm_do_tag_write "$f" "$SCM_WANT_MAKE" "$SCM_WANT_MODEL" "$SCM_WANT_COMMENT" "overwrite"
        else
          scm_print_selected "y = Apply this file"
          scm_do_tag_write "$f" "$SCM_WANT_MAKE" "$SCM_WANT_MODEL" "$SCM_WANT_COMMENT" "apply"
        fi
        return 0
        ;;
      m)
        if (( ! has_existing )); then
          echo "$(scm_ts) Merge is only for files that already have some tags."
          continue
        fi
        scm_print_selected "m = Merge — fill only empty fields"
        scm_compute_merged_tags "$SCM_WANT_MAKE" "$SCM_WANT_MODEL" "$SCM_WANT_COMMENT"
        if ! scm_merged_changes_anything; then
          KEPT=$((KEPT + 1))
          echo "$(scm_ts) Nothing empty to fill; kept current tags: ${f##*/}"
          return 0
        fi
        printf '  %-10s %-24s %s\n' "Make" "$(scm_disp_tag "$SCM_CUR_MAKE")" "$SCM_MERGED_MAKE"
        printf '  %-10s %-24s %s\n' "Model" "$(scm_disp_tag "$SCM_CUR_MODEL")" "$SCM_MERGED_MODEL"
        printf '  %-10s %-24s %s\n' "Comment" "$(scm_disp_tag "$SCM_CUR_COMMENT")" "$SCM_MERGED_COMMENT"
        scm_do_tag_write "$f" "$SCM_MERGED_MAKE" "$SCM_MERGED_MODEL" "$SCM_MERGED_COMMENT" "merge empties"
        return 0
        ;;
      k)
        if (( ! has_existing )); then
          echo "$(scm_ts) No existing tags to keep; use Skip or Apply."
          continue
        fi
        # Capital K is rest-of-run; bare k is this file. scm_choice lowercases — distinguish via REPLY.
        if [[ "$REPLY" == "K" ]]; then
          scm_print_selected "K = Keep existing tags for the rest of this run"
          ALWAYS_KEEP_EXISTING=1
          ALWAYS_APPLY=0
          KEPT=$((KEPT + 1))
          echo "$(scm_ts) Kept existing tags: ${f##*/}"
          echo "$(scm_ts) Will keep existing tags for later files; only fully empty files get ${SCM_CAMERA_LABEL}."
          return 0
        fi
        scm_print_selected "k = Keep current tags on this file"
        KEPT=$((KEPT + 1))
        echo "$(scm_ts) Kept existing tags: ${f##*/}"
        return 0
        ;;
      a)
        scm_print_selected "a = Overwrite this and every later file that differs"
        ALWAYS_APPLY=1
        ALWAYS_KEEP_EXISTING=0
        scm_do_tag_write "$f" "$SCM_WANT_MAKE" "$SCM_WANT_MODEL" "$SCM_WANT_COMMENT" "overwrite"
        echo "$(scm_ts) Will overwrite differing tags with ${SCM_CAMERA_LABEL} on every later file."
        return 0
        ;;
      n)
        scm_print_selected "n = Skip this file"
        SKIPPED=$((SKIPPED + 1))
        echo "$(scm_ts) Skipped: ${f##*/}"
        return 0
        ;;
      q)
        scm_print_selected "q = Quit"
        echo "$(scm_ts) Quit."
        return 2
        ;;
      *)
        echo "$(scm_ts) Unknown choice: ${REPLY}."
        ;;
    esac
  done
}

scm_print_summary() {
  echo
  scm_rule
  echo "$(scm_ts) SUMMARY"
  scm_rule
  printf '  %-22s %s\n' "Camera profile:" "${SCM_CAMERA_LABEL:-n/a}"
  printf '  %-22s %s\n' "Make / Model:" "${SCM_WANT_MAKE:-?} / ${SCM_WANT_MODEL:-?}"
  printf '  %-22s %s\n' "Videos scanned:" "$SCANNED"
  printf '  %-22s %s\n' "Already matching:" "$ALREADY"
  printf '  %-22s %s\n' "Needed a change:" "$NEED"
  printf '  %-22s %s\n' "Tagged:" "$TAGGED"
  printf '  %-22s %s\n' "Kept existing tags:" "$KEPT"
  printf '  %-22s %s\n' "Skipped:" "$SKIPPED"
  printf '  %-22s %s\n' "Failed:" "$FAILED"
  if (( DRY_RUN )); then
    printf '  %-22s %s\n' "Mode:" "dry-run (nothing written)"
  fi
  scm_rule
}

# --- options ---
DO_YES=0
RECURSIVE=0
DRY_RUN=0
VERBOSE=0
ALWAYS_APPLY=0
ALWAYS_KEEP_EXISTING=0
CAMERA_CLI=""
SCM_CUSTOM_MAKE=""
SCM_CUSTOM_MODEL=""
SCM_WANT_MAKE=""
SCM_WANT_MODEL=""
SCM_WANT_COMMENT=""
SCM_CAMERA_LABEL=""
SCANNED=0
ALREADY=0
NEED=0
TAGGED=0
KEPT=0
SKIPPED=0
FAILED=0
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
    --verbose)
      VERBOSE=1
      shift
      ;;
    --camera)
      shift
      [[ $# -gt 0 ]] || { echo "$(scm_ts) --camera needs a profile name." >&2; exit 1; }
      CAMERA_CLI="$1"
      shift
      ;;
    --camera=*)
      CAMERA_CLI="${1#--camera=}"
      shift
      ;;
    --make)
      shift
      [[ $# -gt 0 ]] || { echo "$(scm_ts) --make needs a value." >&2; exit 1; }
      SCM_CUSTOM_MAKE="$1"
      shift
      ;;
    --make=*)
      SCM_CUSTOM_MAKE="${1#--make=}"
      shift
      ;;
    --model)
      shift
      [[ $# -gt 0 ]] || { echo "$(scm_ts) --model needs a value." >&2; exit 1; }
      SCM_CUSTOM_MODEL="$1"
      shift
      ;;
    --model=*)
      SCM_CUSTOM_MODEL="${1#--model=}"
      shift
      ;;
    --)
      shift
      POSITIONALS+=("$@")
      break
      ;;
    -*)
      echo "$(scm_ts) Unknown argument: $1" >&2
      echo "Try: $(script_live_basename) --help" >&2
      exit 1
      ;;
    *)
      POSITIONALS+=("$1")
      shift
      ;;
  esac
done

if [[ -n "$SCM_CUSTOM_MAKE" || -n "$SCM_CUSTOM_MODEL" ]]; then
  if [[ -z "$SCM_CUSTOM_MAKE" || -z "$SCM_CUSTOM_MODEL" ]]; then
    echo "$(scm_ts) Custom camera needs both --make and --model." >&2
    exit 1
  fi
  [[ -n "$CAMERA_CLI" ]] || CAMERA_CLI="custom"
fi

if [[ -f "${BASH_SOURCE[0]}" ]]; then
  chmod 700 "${BASH_SOURCE[0]}" 2>/dev/null || true
fi

print_version_banner

if ! scm_find_exiftool >/dev/null; then
  echo "$(scm_ts) exiftool not found (set SCM_EXIFTOOL or install exiftool)." >&2
  exit 1
fi

if (( ${#POSITIONALS[@]} == 0 )); then
  scm_collect_from_dir .
else
  for p in "${POSITIONALS[@]}"; do
    if [[ -d "$p" ]]; then
      scm_collect_from_dir "$p"
    elif [[ -f "$p" ]]; then
      if scm_is_video_file "$p"; then
        FILES+=("$p")
      else
        echo "$(scm_ts) Not a known video type (skipped): $p" >&2
      fi
    else
      echo "$(scm_ts) Not found: $p" >&2
    fi
  done
fi

if (( ${#FILES[@]} == 0 )); then
  echo "$(scm_ts) No video files to tag."
  exit 0
fi

mapfile -t FILES < <(printf '%s\n' "${FILES[@]}" | LC_ALL=C sort -u)
SCANNED=${#FILES[@]}

scm_choose_camera_profile
rc=$?
if (( rc == 2 )); then
  echo "$(scm_ts) Quit."
  exit 0
fi
if (( rc != 0 )); then
  exit 1
fi

echo
echo "$(scm_ts) Camera: ${SCM_CAMERA_LABEL}  (Make=${SCM_WANT_MAKE} Model=${SCM_WANT_MODEL})"
echo "$(scm_ts) Checking ${SCANNED} video file(s)."
(( DRY_RUN )) && echo "$(scm_ts) Dry run — nothing will be written."
(( DO_YES )) && echo "$(scm_ts) -y: apply without asking (safe: empty tags only; keep differing existing)."
(( VERBOSE )) && echo "$(scm_ts) Verbose: show files that already match."
echo

for f in "${FILES[@]}"; do
  scm_process_file "$f"
  rc=$?
  if (( rc == 2 )); then
    break
  fi
done

scm_print_summary
if (( SCANNED > 0 && NEED == 0 && TAGGED == 0 && ! VERBOSE )); then
  echo "$(scm_ts) Nothing to change. Re-run with --verbose to list already-tagged files."
fi
exit 0
