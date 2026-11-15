#!/bin/bash
# v. 20261115.103000 - pre-scan: batch only files that still need a decision
# v. 20261115.102500 - drop Files bar; show i/n on the live exiftool line
# v. 20261115.101500 - SUMMARY Timing: processing + prompt-wait (with start/finish/wall)
# v. 20261115.101000 - apply-phase progress bars (files + exiftool % from tmp)
# v. 20261115.100500 - batch decide: [b] apply answers so far, resume remaining files
# v. 20261115.100000 - batch decide: show question X of Y (file A of B overall)
# v. 20261115.095000 - batch decide-then-apply; Ctrl-C cleans in-flight exiftool write
# v. 20261115.093500 - end SUMMARY includes Started / Finished / Total wall time
# v. 20261115.093000 - Contour normalize: name=start, FS=end, media=start; idempotent via name↔FS↔duration
# v. 20261115.090500 - [c] Always Contour start for later Contour files in this run
# v. 20261115.085000 - Contour: offer Contour start (name − duration); agree if FS/media already at that start
# v. 20261021.120123 - [k] keep as written for the rest of this run
# v. 20261020.165500 - after each Fix dates key, print Selected: with the accepted answer
# v. 20261020.163800 - when nothing needed fixing, hint to re-run with --verbose
# v. 20261020.163600 - --verbose prints every file check (stamps + verdict) even when dates already agree
# v. 20261020.163300 - Processing header and before/after result block stand out (rules + mark changed rows)
# v. 20261020.163100 - parse exiftool CreateDate with hyphens so GNU date can read it back after a write
# v. 20261020.162800 - Processing header; before/after date table; numeric default spelled out on the prompt
# v. 20261020.162300 - when name and mtime match and CreateDate is missing, default is apply that date (not Skip)
# v. 20261020.155800 - Fix dates prompt: capitalise the default key (e.g. S when Skip is default)
# v. 20261020.150700 - date menu always lists File name, Filesystem, and Media tags (n/a when unusable)
# v. 20261020.150400 - date menu: ASCII n/a so parenthetical notes share one column
# v. 20261020.145500 - fix file / media dates when the name, filesystem, and tags disagree
#
# 2026.11.15 - v. 0.1.23 - pre-scan before batching; batch size / Question X of Y cover only files
#   that disagree (agree/skip counted once, not as batch slots)
# 2026.11.15 - v. 0.1.22 - apply progress: Write/Fix i/n line + (i/n) on exiftool bar; remove Files bar
# 2026.11.15 - v. 0.1.21 - SUMMARY Timing adds Processing and Prompt/wait (plus Other overhead)
# 2026.11.15 - v. 0.1.20 - apply phase: files bar + exiftool % from *_exiftool_tmp
# 2026.11.15 - v. 0.1.19 - [b] during batch decide: apply queued answers now; current+later files
#   in the batch are asked in the next decide round
# 2026.11.15 - v. 0.1.18 - during batch decide, show Question X of Y in this batch (file A of B overall)
# 2026.11.15 - v. 0.1.17 - process in batches: ask all decisions for a batch first, then write; batch size
#   default = all when ≤50 files, else 50 (--batch-size / MFD_BATCH_SIZE); Ctrl-C during a write stops
#   exiftool and removes that file's *_exiftool_tmp
# 2026.11.15 - v. 0.1.16 - end-of-run SUMMARY prints Started / Finished / Total wall time (like other pgm scripts)
# 2026.11.15 - v. 0.1.15 - Contour normalize: rename stamp to clip start, filesystem mtime = end, media
#   CreateDate = start. If name is already earlier than FS by ~duration (name=start, FS=end), treat as
#   agree and do not subtract duration again. [c] / Contour menu / -y on Contour files apply normalize.
# 2026.11.15 - v. 0.1.14 - Contour disagree menu: [c] Always Contour start for the rest of this run (name − duration; Contour files only; non-Contour still prompted / oldest as usual); short explanation under the keys
# 2026.11.15 - v. 0.1.13 - Contour-style names (YYYYMMDD_HHMMSS[.mp4|_NVenc_…]): treat the name stamp as a possible end of clip; offer absolute Contour start = name − ffprobe duration as a date source (not a relative FS shift). If filesystem or media already match that start (±2 min), count as agree vs the Contour name so re-runs do not subtract duration again
# 2026.10.21 - v. 0.1.12 - [k] keeps dates as written for this file and every later file in the run (parallel to [a] for oldest)
# 2026.10.20 - v. 0.1.11 - after each Fix dates answer, print Selected: with the key and meaning that the script accepted (same idea as loudness / swap-audio)
# 2026.10.20 - v. 0.1.10 - when the run finds no disagreements, suggest re-running with --verbose to see each file check
# 2026.10.20 - v. 0.1.9 - --verbose: for every scanned file print File name / Filesystem / Media tags and a verdict (agree / disagree / skip); -v remains --version
# 2026.10.20 - v. 0.1.8 - Processing and the before/after result are framed with === lines; rows that changed get a leading * and (changed)
# 2026.10.20 - v. 0.1.7 - reading CreateDate used exiftool's YYYY:MM:DD form, which GNU date rejects, so Media tags always looked like n/a after a successful write; parse as YYYY-MM-DD instead
# 2026.10.20 - v. 0.1.6 - per-file Processing header; after a change show File name / Filesystem / Media tags before and after side by side; when the default is a number, the prompt says e.g. (default 1 = File name)
# 2026.10.20 - v. 0.1.5 - when name and mtime already match and only CreateDate is missing, default is to apply that date (filesystem + media tags), not Skip
# 2026.10.20 - v. 0.1.4 - Fix dates prompt shows the default key in capitals (e.g. 1/2/3/4/a/S/q), like the other scripts
# 2026.10.20 - v. 0.1.2 - always show File name, Filesystem, and Media tags rows (n/a when missing or before 1990)
# 2026.10.20 - v. 0.1.1 - date menu uses ASCII n/a (UTF-8 dash broke the column of the notes in parentheses)
# 2026.10.20 - v. 0.1 - initial release: for video, audio, and pictures, compare the
#   file-name stamp, filesystem mtime, and media CreateDate (or DateTimeOriginal);
#   ask which to use (1/2/3…); default is the oldest usable date; stamps before 1990
#   are ignored; write media CreateDate/ModifyDate and filesystem times (Windows
#   creation on /mnt/?/…). -y applies the oldest without asking. [a] uses oldest for
#   every later file in this run; [k] keeps as written for every later file.
#
# media-pgm-fix-dates.sh
#
# Align filesystem times and media CreateDate when they disagree with each other
# or with a date stamp in the file name. Contour-style clips normalize to
# name=start, filesystem=end, media=start (see Contour notes in --help).
#

show_help() {
  cat <<EOF
Usage: $(script_live_basename) [-h|--help] [-v|--version] [--history]
       [-y|--yes] [-r|--recursive] [--dry-run] [--verbose]
       [--batch-size N]
       [FILE|DIR ...]

Compare the date in the file name, the filesystem time, and the media
CreateDate (DateTimeOriginal for many photos). When they disagree by more
than two minutes, ask which date to use. The default is the oldest usable
stamp. Dates before 1990-01-01 are ignored.

Work is batched: for each batch the script asks every decision first, then
writes (so you are not waiting on exiftool between prompts). Default batch
size is all files when there are 50 or fewer; otherwise 50 (overridable).

Contour-style video names (YYYYMMDD_HHMMSS.mp4 or …_NVenc_….mp4): Contour
cameras stamp the end of the clip in the name. This script can normalize:
  File name stamp  = start of clip (rename)
  Filesystem mtime = end of clip
  Media CreateDate = start of clip
Start = end-stamp − duration when the name still looks like an end; if the
name is already earlier than the filesystem by about the duration (name=start,
FS=end), the file agrees and duration is not subtracted again. Missing or
wrong media tags are filled with the start time.

Applies to video, audio, and picture files. With no FILE or DIR, scan the
current directory (not subdirectories unless -r).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  -y, --yes            Apply without asking: Contour normalize when Contour
                       applies; otherwise the oldest usable date.
  -r, --recursive      Also scan subdirectories.
  --dry-run            Show what would change; do not write.
  --verbose            Print every file check (stamps + verdict), including
                       files that already agree.
  --batch-size N       Decide/apply this many files per batch (default: all
                       if ≤50 files, else 50).

Interactive keys (per file) — decisions only; writes run after the batch's
questions:
  1/2/3…               Pick a listed source (default = oldest usable, or
                       Contour normalize when that row is the default).
                       When the default is a number, the prompt also says
                       e.g. (default 1 = File name).
  a                    Apply the oldest usable date for this file and every
                       later file in this run (no more prompts).
  c                    Contour only: Contour normalize (name→start, FS→end,
                       media→start) for this file and every later Contour
                       file in this run. Non-Contour files are unchanged by
                       [c] (still asked / oldest as usual). Shown only when
                       Contour normalize is available for this file.
  k                    Keep dates as written for this file and every later
                       file in this run (no more prompts).
  b                    Begin apply now — write answers so far; ask the rest
                       of this batch later.
  s                    Skip this file.
  q                    Quit (abandons unapplied plans for the current batch).

Ctrl-C during a write stops exiftool and removes that file's *_exiftool_tmp.

After a change, the script prints File name / Filesystem / Media tags
before and after side by side.

Examples:
  $(script_live_basename)
      Scan *.mp4 / *.jpg / … in this directory; ask when dates disagree.

  $(script_live_basename) -y -r /mnt/p/video/trip
      Recursively apply the oldest usable date to every mismatch.

  $(script_live_basename) --dry-run clip.mp4 photo.jpg
      Show the choice for those files only.

  $(script_live_basename) --verbose .
      Print the check for every media file in this directory.

Environment:
  MFD_EXIFTOOL / EXIFLOC / PGM_EXIFTOOL
                       Path to exiftool (else exiftool on PATH).
  MFD_BATCH_SIZE       Default batch size (same as --batch-size).
  MFD_EXIFTOOL_PROGRESS_MIN_BYTES
                       Min file size for exiftool % bar (default 5242880).
EOF
}

# --- after header is sourced ---
mfd_ts() {
  date '+[ %Y.%m.%d %H:%M:%S ]'
}

mfd_wall_clock_now() {
  date '+%Y.%m.%d %H:%M:%S'
}

mfd_format_elapsed() {
  local s="${1:-0}" h m
  (( s < 0 )) && s=0
  h=$(( s / 3600 )); s=$(( s % 3600 ))
  m=$(( s / 60 )); s=$(( s % 60 ))
  if (( h > 0 )); then
    printf '%dh %dm %ds' "$h" "$m" "$s"
  elif (( m > 0 )); then
    printf '%dm %ds' "$m" "$s"
  else
    printf '%ds' "$s"
  fi
}

mfd_summary_kv() {
  printf '  %-22s %s\n' "$1" "$2"
}

mfd_prompt_wait_begin() {
  MFD_PROMPT_WAIT_MARK=$(date +%s)
}

mfd_prompt_wait_end() {
  local now
  [[ -n "${MFD_PROMPT_WAIT_MARK:-}" && "$MFD_PROMPT_WAIT_MARK" -gt 0 ]] || return 0
  now=$(date +%s)
  MFD_PROMPT_WAIT_SEC=$(( MFD_PROMPT_WAIT_SEC + now - MFD_PROMPT_WAIT_MARK ))
  MFD_PROMPT_WAIT_MARK=0
}

mfd_proc_begin() {
  MFD_PROC_MARK=$(date +%s)
}

mfd_proc_end() {
  local now
  [[ -n "${MFD_PROC_MARK:-}" && "$MFD_PROC_MARK" -gt 0 ]] || return 0
  now=$(date +%s)
  MFD_PROC_SEC=$(( MFD_PROC_SEC + now - MFD_PROC_MARK ))
  MFD_PROC_MARK=0
}

mfd_print_summary() {
  local end_str wall_sec wall_time other_sec
  end_str="$(mfd_wall_clock_now)"
  wall_sec=$(( $(date +%s) - ${MFD_SCRIPT_START_EPOCH:-$(date +%s)} ))
  (( wall_sec < 0 )) && wall_sec=0
  other_sec=$(( wall_sec - MFD_PROC_SEC - MFD_PROMPT_WAIT_SEC ))
  (( other_sec < 0 )) && other_sec=0
  wall_time="$(mfd_format_elapsed "$wall_sec")"

  echo
  mfd_rule
  echo "$(mfd_ts) SUMMARY"
  mfd_rule
  mfd_summary_kv "Scanned:" "$SCANNED"
  mfd_summary_kv "No decision needed:" "${ALREADY_OK:-0}"
  mfd_summary_kv "Batch size:" "${BATCH_SIZE:-n/a}"
  mfd_summary_kv "Disagreed:" "$MISMATCH"
  mfd_summary_kv "Fixed:" "$FIXED"
  mfd_summary_kv "Skipped/kept:" "$SKIPPED"
  if (( DRY_RUN )); then
    mfd_summary_kv "Mode:" "dry-run (nothing written)"
  fi
  echo
  echo "--- Timing ---"
  mfd_summary_kv "Started:" "${MFD_SCRIPT_START_STR:-?}"
  mfd_summary_kv "Finished:" "$end_str"
  mfd_summary_kv "Total wall time:" "$wall_time"
  mfd_summary_kv "Processing time:" "$(mfd_format_elapsed "${MFD_PROC_SEC:-0}")  (exiftool / FS writes)"
  mfd_summary_kv "Prompt/wait time:" "$(mfd_format_elapsed "${MFD_PROMPT_WAIT_SEC:-0}")  (interactive prompts)"
  mfd_summary_kv "Other overhead:" "$(mfd_format_elapsed "$other_sec")"
  mfd_rule
}

mfd_cleanup_write_temps() {
  local f="$1" dir base t
  [[ -n "$f" ]] || return 0
  dir="$(dirname -- "$f")"
  base="${f##*/}"
  rm -f -- "${f}_exiftool_tmp" "${dir}/${base}_exiftool_tmp" 2>/dev/null || true
  shopt -s nullglob
  for t in "${dir}/${base}"*_exiftool_tmp "${dir}/.${base}"*exiftool*; do
    [[ -e "$t" ]] || continue
    rm -f -- "$t" 2>/dev/null || true
  done
  shopt -u nullglob
}

mfd_kill_exiftool_child() {
  local pid="${MFD_EXIFTOOL_PID:-}"
  MFD_EXIFTOOL_PID=""
  [[ -n "$pid" ]] || return 0
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
}

mfd_file_size_bytes() {
  local f="$1" s
  s="$(stat -c %s -- "$f" 2>/dev/null || stat -f %z -- "$f" 2>/dev/null)" || return 1
  [[ "$s" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$s"
}

mfd_format_bytes_short() {
  local bytes="${1:-0}"
  [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0
  awk -v b="$bytes" 'BEGIN {
    if (b >= 1073741824) printf "%.2f GiB", b / 1073741824.0
    else if (b >= 1048576) printf "%.1f MiB", b / 1048576.0
    else if (b >= 1024) printf "%.1f KiB", b / 1024.0
    else printf "%d B", b
  }'
}

mfd_make_bar() {
  local pct="${1:-0}" bar_w="${2:-20}" filled empty i bar=""
  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100
  filled=$(( pct * bar_w / 100 ))
  empty=$(( bar_w - filled ))
  for (( i = 0; i < filled; i++ )); do bar+="#"; done
  for (( i = 0; i < empty; i++ )); do bar+="-"; done
  printf '%s\n' "$bar"
}

mfd_progress_end() {
  if (( MFD_PROGRESS_ACTIVE )); then
    echo
    MFD_PROGRESS_ACTIVE=0
  fi
}

mfd_ctrl_c() {
  echo
  mfd_progress_end
  echo "$(mfd_ts) Interrupted (Ctrl-C)."
  mfd_kill_exiftool_child
  if [[ -n "${MFD_CURRENT_WRITE_FILE:-}" ]]; then
    mfd_cleanup_write_temps "$MFD_CURRENT_WRITE_FILE"
    echo "$(mfd_ts) Cleaned up in-progress write: ${MFD_CURRENT_WRITE_FILE##*/}"
    MFD_CURRENT_WRITE_FILE=""
  fi
  mfd_print_summary
  exit 130
}

# Run exiftool in background; show % from *_exiftool_tmp when MFD_CURRENT_WRITE_FILE is set.
mfd_run_exiftool() {
  local dest="${MFD_CURRENT_WRITE_FILE:-}" phase="exiftool"
  local expected=0 cur=0 pct=0 pid rc=0 tmp min_b bar width msg base room
  local bar_w=20

  "$@" >/dev/null 2>&1 &
  pid=$!
  MFD_EXIFTOOL_PID=$pid

  if [[ -z "$dest" || ! -f "$dest" || ! -t 1 ]]; then
    wait "$pid"
    rc=$?
    MFD_EXIFTOOL_PID=""
    return "$rc"
  fi

  expected="$(mfd_file_size_bytes "$dest" 2>/dev/null || echo 0)"
  [[ "$expected" =~ ^[0-9]+$ ]] || expected=0
  tmp="${dest}_exiftool_tmp"
  min_b="${MFD_EXIFTOOL_PROGRESS_MIN_BYTES:-5242880}"
  [[ "$min_b" =~ ^[0-9]+$ ]] || min_b=5242880

  if (( expected < min_b )); then
    wait "$pid"
    rc=$?
    MFD_EXIFTOOL_PID=""
    return "$rc"
  fi

  while kill -0 "$pid" 2>/dev/null; do
    cur=0
    if [[ -f "$tmp" ]]; then
      cur="$(mfd_file_size_bytes "$tmp" 2>/dev/null || echo 0)"
      [[ "$cur" =~ ^[0-9]+$ ]] || cur=0
    fi
    if (( expected > 0 )); then
      pct=$(( cur * 100 / expected ))
      (( pct > 99 )) && pct=99
    else
      pct=0
    fi
    bar="$(mfd_make_bar "$pct" "$bar_w")"
    base="${dest##*/}"
    idx=""
    if [[ -n "${MFD_APPLY_INDEX:-}" && -n "${MFD_APPLY_TOTAL:-}" ]]; then
      idx=" (${MFD_APPLY_INDEX}/${MFD_APPLY_TOTAL})"
    fi
    printf -v msg '%s %s  %3d%% [%s]  %s / %s%s' \
      "$(mfd_ts)" "$phase" "$pct" "$bar" \
      "$(mfd_format_bytes_short "$cur")" "$(mfd_format_bytes_short "$expected")" "$idx"
    width="${COLUMNS:-80}"
    [[ "$width" =~ ^[0-9]+$ ]] || width=80
    room=$(( width - ${#msg} - 2 ))
    if (( room >= 8 )) && [[ -n "$base" ]]; then
      if (( ${#base} > room )); then
        base="…${base: -$(( room - 1 ))}"
      fi
      msg+="  ${base}"
    fi
    if (( ${#msg} > width )); then
      msg="${msg:0:width}"
    fi
    printf '\r%s\033[K' "$msg"
    MFD_PROGRESS_ACTIVE=1
    sleep 0.4
  done

  wait "$pid"
  rc=$?
  MFD_EXIFTOOL_PID=""
  if (( rc == 0 && expected > 0 )); then
    bar="$(mfd_make_bar 100 "$bar_w")"
    idx=""
    if [[ -n "${MFD_APPLY_INDEX:-}" && -n "${MFD_APPLY_TOTAL:-}" ]]; then
      idx=" (${MFD_APPLY_INDEX}/${MFD_APPLY_TOTAL})"
    fi
    printf -v msg '%s %s  %3d%% [%s]  %s / %s%s  %s' \
      "$(mfd_ts)" "$phase" 100 "$bar" \
      "$(mfd_format_bytes_short "$expected")" "$(mfd_format_bytes_short "$expected")" \
      "$idx" "${dest##*/}"
    width="${COLUMNS:-80}"
    [[ "$width" =~ ^[0-9]+$ ]] || width=80
    if (( ${#msg} > width )); then
      msg="${msg:0:width}"
    fi
    printf '\r%s\033[K' "$msg"
    MFD_PROGRESS_ACTIVE=1
  fi
  mfd_progress_end
  return "$rc"
}

mfd_read_key() {
  local prompt="$1" default="${2:-}" answer=
  if (( ! script_is_run_interactively )); then
    REPLY="$default"
    return 0
  fi
  printf '%s %s' "$(mfd_ts)" "$prompt"
  if [[ -t 0 ]]; then
    mfd_prompt_wait_begin
    read -n 1 answer || answer=
    mfd_prompt_wait_end
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

# Echo what the script accepted (Enter uses the default key).
mfd_print_selected() {
  echo "$(mfd_ts) Selected: $*"
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

# Epoch → display string, or n/a when empty/unusable.
mfd_disp_or_na() {
  local e="${1:-}"
  if [[ -n "$e" ]]; then
    mfd_format_epoch_display "$e"
  else
    printf '%s\n' "n/a"
  fi
}

# Snapshot name / filesystem / media epochs for a file (empty string when n/a).
# Sets MFD_SNAP_NAME MFD_SNAP_FS MFD_SNAP_MEDIA.
mfd_snapshot_dates() {
  local f="$1"
  MFD_SNAP_NAME="$(mfd_filename_epoch_from_basename "${f##*/}" 2>/dev/null || true)"
  MFD_SNAP_FS="$(mfd_fs_mtime_epoch "$f" 2>/dev/null || true)"
  MFD_SNAP_MEDIA="$(mfd_media_createdate_epoch "$f" 2>/dev/null || true)"
}

mfd_rule() {
  printf '%s\n' "========================================================================"
}

mfd_question_progress_text() {
  if [[ -n "${MFD_Q_BATCH_POS:-}" && -n "${MFD_Q_BATCH_TOTAL:-}" ]]; then
    printf 'Question %s of %s in this batch  (file %s of %s overall)' \
      "$MFD_Q_BATCH_POS" "$MFD_Q_BATCH_TOTAL" \
      "${MFD_Q_OVERALL_POS:-?}" "${MFD_Q_OVERALL_TOTAL:-?}"
  else
    printf ''
  fi
}

# Prominent start-of-file banner.
mfd_print_processing() {
  local f="$1" prog
  echo
  mfd_rule
  prog="$(mfd_question_progress_text)"
  if [[ -n "$prog" ]]; then
    echo "$(mfd_ts) ${prog}"
  fi
  echo "$(mfd_ts) Processing: ${f}"
  mfd_rule
}

mfd_print_decide_slot() {
  local note="${1:-}" prog
  prog="$(mfd_question_progress_text)"
  [[ -n "$prog" ]] || return 0
  if [[ -n "$note" ]]; then
    echo "$(mfd_ts) ${prog} — ${note}"
  else
    echo "$(mfd_ts) ${prog}"
  fi
}

# One result row; mark with * when before and after differ.
mfd_print_ba_row() {
  local label="$1" before="$2" after="$3" mark=" " note=""
  if [[ "$before" != "$after" ]]; then
    mark="*"
    note="  (changed)"
  fi
  printf '%s %-18s %-21s %s%s\n' \
    "$mark" "$label" "$(mfd_disp_or_na "$before")" "$(mfd_disp_or_na "$after")" "$note"
}

# Side-by-side before/after for the three date sources (framed; * = changed).
mfd_print_before_after() {
  local b_name="$1" b_fs="$2" b_media="$3"
  local a_name="$4" a_fs="$5" a_media="$6"
  echo
  echo "  === Result (before -> after) =========================================="
  printf '  %-18s %-21s %s\n' "" "Before" "After"
  mfd_print_ba_row "File name" "$b_name" "$a_name"
  mfd_print_ba_row "Filesystem" "$b_fs" "$a_fs"
  mfd_print_ba_row "Media tags" "$b_media" "$a_media"
  echo "  ======================================================================"
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

# Contour-style basename: YYYYMMDD_HHMMSS.mp4 or YYYYMMDD_HHMMSS_NVenc_….mp4
# (not GoPro camera token, not _part_XX, not 70mai NO*/EV*).
mfd_is_contour_basename() {
  local base="$1"
  base="${base##*/}"
  [[ "$base" =~ _part_[0-9]{2} ]] && return 1
  [[ "$base" =~ (GOPRO|GoPro_) ]] && return 1
  if [[ "$base" =~ ^(NO|EV)[0-9]{8}-[0-9]{6}-[0-9]+[A-Za-z]\.[mM][pP]4$ ]]; then
    return 1
  fi
  if [[ "$base" =~ ^[0-9]{8}_[0-9]{6}\.[mM][pP]4$ ]]; then
    return 0
  fi
  if [[ "$base" =~ ^[0-9]{8}_[0-9]{6}_NVenc_.*\.[mM][pP]4$ ]]; then
    return 0
  fi
  return 1
}

mfd_ffprobe_duration_seconds() {
  local f="$1" d
  command -v ffprobe >/dev/null 2>&1 || return 1
  d=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 -- "$f" 2>/dev/null) || return 1
  d="${d//$'\r'/}"
  [[ -n "$d" && "$d" != "N/A" ]] || return 1
  awk -v x="$d" 'BEGIN { if (x+0 > 0) { printf "%.0f\n", x+0.5; exit 0 } exit 1 }'
}

mfd_epoch_near() {
  local a="$1" b="$2"
  [[ -n "$a" && -n "$b" ]] || return 1
  (( $(mfd_abs_diff "$a" "$b") <= 120 ))
}

# Contour analyze: sets MFD_CONTOUR_START_E / MFD_CONTOUR_END_E / MFD_CONTOUR_DUR /
# MFD_CONTOUR_LAYOUT (normalized|end_in_name). Return 0 when Contour normalize applies.
mfd_contour_analyze() {
  local f="$1" name_e="${2:-}" fs_e="${3:-}" media_e="${4:-}"
  local dur start_from_end end_from_start
  MFD_CONTOUR_START_E=""
  MFD_CONTOUR_END_E=""
  MFD_CONTOUR_DUR=""
  MFD_CONTOUR_LAYOUT=""
  mfd_is_contour_basename "${f##*/}" || return 1
  [[ -n "$name_e" ]] || name_e="$(mfd_filename_epoch_from_basename "${f##*/}" 2>/dev/null)" || return 1
  dur="$(mfd_ffprobe_duration_seconds "$f" 2>/dev/null)" || return 1
  (( dur >= 1 )) || return 1
  # Only meaningful when duration is wider than the disagree window.
  (( dur > 120 )) || return 1
  start_from_end=$(( name_e - dur ))
  end_from_start=$(( name_e + dur ))
  mfd_epoch_usable "$start_from_end" || return 1
  mfd_epoch_usable "$end_from_start" || return 1
  MFD_CONTOUR_DUR="$dur"

  # Already normalized: name earlier than FS by ~duration (name=start, FS=end).
  # Do not subtract duration again.
  if [[ -n "$fs_e" ]] && mfd_epoch_near "$fs_e" "$end_from_start"; then
    MFD_CONTOUR_LAYOUT="normalized"
    MFD_CONTOUR_START_E="$name_e"
    MFD_CONTOUR_END_E="$end_from_start"
    return 0
  fi
  if [[ -n "$media_e" ]] && mfd_epoch_near "$media_e" "$name_e" \
    && [[ -n "$fs_e" ]] && mfd_epoch_near "$fs_e" "$end_from_start"; then
    MFD_CONTOUR_LAYOUT="normalized"
    MFD_CONTOUR_START_E="$name_e"
    MFD_CONTOUR_END_E="$end_from_start"
    return 0
  fi

  # Name looks like Contour end-stamp (camera native, or FS/media already at start).
  MFD_CONTOUR_LAYOUT="end_in_name"
  MFD_CONTOUR_START_E="$start_from_end"
  MFD_CONTOUR_END_E="$name_e"
  return 0
}

# Replace YYYYMMDD_HHMMSS prefix with stamp for epoch. Prints new basename.
mfd_contour_basename_for_start() {
  local base="$1" start_e="$2" stamp
  base="${base##*/}"
  stamp="$(date -d "@${start_e}" +%Y%m%d_%H%M%S 2>/dev/null)" || return 1
  if [[ "$base" =~ ^[0-9]{8}_[0-9]{6}(.*)$ ]]; then
    printf '%s%s\n' "$stamp" "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

# Rename Contour file so the name stamp is start. Sets MFD_APPLIED_PATH.
# Dry-run: only sets MFD_APPLIED_PATH to the would-be path (no mv).
mfd_contour_rename_to_start() {
  local f="$1" start_e="$2"
  local dir base new_base dest
  MFD_APPLIED_PATH="$f"
  dir="$(dirname -- "$f")"
  base="${f##*/}"
  new_base="$(mfd_contour_basename_for_start "$base" "$start_e")" || return 1
  if [[ "$new_base" == "$base" ]]; then
    return 0
  fi
  dest="${dir}/${new_base}"
  if [[ -e "$dest" ]]; then
    echo "$(mfd_ts) Rename blocked (target exists): ${new_base}" >&2
    return 1
  fi
  if (( DRY_RUN )); then
    echo "$(mfd_ts) DRY-RUN would rename → ${new_base}"
    MFD_APPLIED_PATH="$dest"
    return 0
  fi
  mv -n -- "$f" "$dest" || return 1
  MFD_APPLIED_PATH="$dest"
  echo "$(mfd_ts) Renamed → ${new_base}"
  return 0
}

# Contour normalize: name→start, media→start, FS→end.
# Sets MFD_APPLIED_PATH; dry-run sets MFD_DRY_AFTER_NAME/FS/MEDIA.
mfd_apply_contour_normalize() {
  local f="$1" start_e="$2" end_e="$3"
  local path media_ok=0 fs_ok=0
  MFD_APPLIED_PATH="$f"
  MFD_DRY_AFTER_EPOCH=""
  MFD_DRY_AFTER_NAME=""
  MFD_DRY_AFTER_FS=""
  MFD_DRY_AFTER_MEDIA=""
  [[ -n "$start_e" && -n "$end_e" ]] || return 1

  if (( DRY_RUN )); then
    MFD_DRY_AFTER_NAME="$start_e"
    MFD_DRY_AFTER_MEDIA="$start_e"
    MFD_DRY_AFTER_FS="$end_e"
    mfd_contour_rename_to_start "$f" "$start_e" || true
    echo "$(mfd_ts) DRY-RUN would set media→start $(mfd_format_epoch_display "$start_e"), FS→end $(mfd_format_epoch_display "$end_e")"
    return 0
  fi

  MFD_CURRENT_WRITE_FILE="$f"
  mfd_contour_rename_to_start "$f" "$start_e" || {
    MFD_CURRENT_WRITE_FILE=""
    return 1
  }
  path="$MFD_APPLIED_PATH"
  MFD_CURRENT_WRITE_FILE="$path"

  if mfd_set_media_dates_epoch "$path" "$start_e"; then
    media_ok=1
  else
    echo "$(mfd_ts) Media CreateDate: could not write start $(mfd_format_epoch_display "$start_e")" >&2
  fi
  # FS last so end wins over any exiftool FileModifyDate side effect.
  if mfd_set_fs_times_epoch "$path" "$end_e"; then
    fs_ok=1
  else
    echo "$(mfd_ts) Filesystem times: could not set end $(mfd_format_epoch_display "$end_e")" >&2
  fi
  MFD_CURRENT_WRITE_FILE=""
  echo "$(mfd_ts) Contour normalize: name/media=start $(mfd_format_epoch_display "$start_e"); FS=end $(mfd_format_epoch_display "$end_e")"
  (( media_ok || fs_ok ))
}

mfd_fs_mtime_epoch() {
  local f="$1" e
  e="$(stat -c %Y -- "$f" 2>/dev/null || stat -f %m -- "$f" 2>/dev/null)" || return 1
  mfd_epoch_usable "$e" || return 1
  printf '%s\n' "$e"
}

# exiftool -d '%Y:%m:%d …' → GNU date needs hyphens in the date part.
mfd_exif_datetime_to_epoch() {
  local raw="$1" iso e
  raw="$(printf '%s' "$raw" | tr -d '\r')"
  [[ -n "$raw" && "$raw" != "0000:00:00 00:00:00" && "$raw" != "0000-00-00 00:00:00" ]] || return 1
  iso="$raw"
  # YYYY:MM:DD HH:MM:SS → YYYY-MM-DD HH:MM:SS (only the date separators).
  if [[ "$iso" =~ ^([0-9]{4}):([0-9]{2}):([0-9]{2})(.*)$ ]]; then
    iso="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}${BASH_REMATCH[4]}"
  fi
  e="$(date -d "$iso" +%s 2>/dev/null)" || return 1
  mfd_epoch_usable "$e" || return 1
  printf '%s\n' "$e"
}

mfd_media_createdate_epoch() {
  local f="$1" exif raw line e
  exif="$(mfd_find_exiftool 2>/dev/null)" || return 1
  while IFS= read -r line; do
    raw="$(printf '%s' "$line" | tr -d '\r')"
    e="$(mfd_exif_datetime_to_epoch "$raw" 2>/dev/null)" || continue
    printf '%s\n' "$e"
    return 0
  done < <("$exif" -api largefilesupport=1 -api QuickTimeUTC=1 -s3 \
    -CreateDate -DateTimeOriginal -MediaCreateDate -TrackCreateDate \
    -d '%Y-%m-%d %H:%M:%S' -- "$f" 2>/dev/null)
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
  if mfd_run_exiftool "$exif" -overwrite_original -P -api QuickTimeUTC=1 \
    -AllDates="$iso" \
    -CreateDate="$iso" -ModifyDate="$iso" -DateTimeOriginal="$iso" \
    -TrackCreateDate="$iso" -TrackModifyDate="$iso" \
    -MediaCreateDate="$iso" -MediaModifyDate="$iso" \
    -- "$dest"; then
    ok=1
  elif mfd_run_exiftool "$exif" -overwrite_original -P \
    -AllDates="$iso" \
    -CreateDate="$iso" -ModifyDate="$iso" -DateTimeOriginal="$iso" \
    -- "$dest"; then
    ok=1
  fi
  mfd_run_exiftool "$exif" -overwrite_original -P -api QuickTimeUTC=1 \
    -FileCreateDate="$iso" -FileModifyDate="$iso" \
    -- "$dest" || true
  (( ok ))
}

# Apply epoch to media + filesystem. Prints a short status; caller shows before/after.
# Returns 0 on success (or dry-run). On dry-run sets MFD_DRY_AFTER_EPOCH for the table.
mfd_apply_epoch() {
  local dest="$1" epoch="$2" disp media_ok=0 fs_ok=0
  disp="$(mfd_format_epoch_display "$epoch")"
  MFD_DRY_AFTER_EPOCH=""
  MFD_DRY_AFTER_NAME=""
  MFD_DRY_AFTER_FS=""
  MFD_DRY_AFTER_MEDIA=""
  MFD_APPLIED_PATH="$dest"
  if (( DRY_RUN )); then
    MFD_DRY_AFTER_EPOCH="$epoch"
    echo "$(mfd_ts) DRY-RUN would set media + filesystem times to ${disp}"
    return 0
  fi
  MFD_CURRENT_WRITE_FILE="$dest"
  if mfd_set_media_dates_epoch "$dest" "$epoch"; then
    media_ok=1
  else
    echo "$(mfd_ts) Media CreateDate: could not write ${disp}" >&2
  fi
  if mfd_set_fs_times_epoch "$dest" "$epoch"; then
    fs_ok=1
  else
    echo "$(mfd_ts) Filesystem times: could not set ${disp}" >&2
  fi
  MFD_CURRENT_WRITE_FILE=""
  (( media_ok || fs_ok ))
}

# After apply (or dry-run): print before/after using snapshots taken before the write.
# $1 may be the path after a Contour rename (MFD_APPLIED_PATH).
mfd_show_result_table() {
  local f="$1" before_name="$2" before_fs="$3" before_media="$4"
  local after_name after_fs after_media
  if (( DRY_RUN )) && [[ -n "${MFD_DRY_AFTER_NAME:-}" || -n "${MFD_DRY_AFTER_FS:-}" || -n "${MFD_DRY_AFTER_MEDIA:-}" ]]; then
    after_name="${MFD_DRY_AFTER_NAME:-$before_name}"
    after_fs="${MFD_DRY_AFTER_FS:-$before_fs}"
    after_media="${MFD_DRY_AFTER_MEDIA:-$before_media}"
  elif (( DRY_RUN )) && [[ -n "${MFD_DRY_AFTER_EPOCH:-}" ]]; then
    after_name="$before_name"
    after_fs="$MFD_DRY_AFTER_EPOCH"
    after_media="$MFD_DRY_AFTER_EPOCH"
  else
    mfd_snapshot_dates "$f"
    after_name="$MFD_SNAP_NAME"
    after_fs="$MFD_SNAP_FS"
    after_media="$MFD_SNAP_MEDIA"
  fi
  mfd_print_before_after \
    "$before_name" "$before_fs" "$before_media" \
    "$after_name" "$after_fs" "$after_media"
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

# Compare epoch to name stamp for verbose notes: "ok vs name (Ns)" / "differ vs name (Ns)".
mfd_vs_name_note() {
  local name_e="$1" other_e="$2" abs_diff
  if [[ -z "$name_e" || -z "$other_e" ]]; then
    printf '%s\n' ""
    return 0
  fi
  abs_diff="$(mfd_abs_diff "$name_e" "$other_e")"
  if (( abs_diff > 120 )); then
    printf 'differ vs name (%ss)\n' "$abs_diff"
  else
    printf 'ok vs name (%ss)\n' "$abs_diff"
  fi
}

# Print one verbose Check block. verdict: agree | disagree | skip
# Optional Contour fields via globals MFD_CONTOUR_* when set.
mfd_verbose_print_check() {
  local f="$1" verdict="$2" name_e="$3" fs_e="$4" media_e="$5"
  local contour_start_e="${MFD_CONTOUR_START_E:-}" contour_end_e="${MFD_CONTOUR_END_E:-}"
  local layout="${MFD_CONTOUR_LAYOUT:-}"
  local fs_note media_note vs name_note
  echo
  echo "$(mfd_ts) Check: ${f}"
  name_note=""
  if [[ "$layout" == "normalized" ]]; then
    name_note="(Contour: name = start)"
  elif [[ "$layout" == "end_in_name" ]]; then
    name_note="(Contour: name = end of clip)"
  elif [[ -n "$contour_start_e" ]]; then
    name_note="(Contour)"
  fi
  if [[ -n "$name_note" ]]; then
    printf '  %-18s %-21s %s\n' "File name" "$(mfd_disp_or_na "$name_e")" "$name_note"
  else
    printf '  %-18s %s\n' "File name" "$(mfd_disp_or_na "$name_e")"
  fi
  if [[ -n "$contour_start_e" ]]; then
    printf '  %-18s %-21s %s\n' "Contour start" "$(mfd_disp_or_na "$contour_start_e")" "(target for name + media)"
  fi
  if [[ -n "$contour_end_e" ]]; then
    printf '  %-18s %-21s %s\n' "Contour end" "$(mfd_disp_or_na "$contour_end_e")" "(target for filesystem)"
  fi
  fs_note="(mtime)"
  [[ -n "$fs_e" ]] || fs_note="(mtime missing or before 1990)"
  vs="$(mfd_vs_name_note "$name_e" "$fs_e")"
  if [[ -n "$contour_end_e" && -n "$fs_e" ]] && mfd_epoch_near "$contour_end_e" "$fs_e"; then
    vs="ok vs Contour end"
  elif [[ -n "$contour_start_e" && -n "$fs_e" ]] && mfd_epoch_near "$contour_start_e" "$fs_e"; then
    vs="ok vs Contour start (not yet FS=end)"
  fi
  if [[ -n "$vs" ]]; then
    printf '  %-18s %-21s %s  %s\n' "Filesystem" "$(mfd_disp_or_na "$fs_e")" "$fs_note" "$vs"
  else
    printf '  %-18s %-21s %s\n' "Filesystem" "$(mfd_disp_or_na "$fs_e")" "$fs_note"
  fi
  if [[ -n "$media_e" ]]; then
    media_note="(CreateDate)"
  else
    media_note="(CreateDate missing or before 1990)"
  fi
  vs="$(mfd_vs_name_note "$name_e" "$media_e")"
  if [[ -n "$contour_start_e" && -n "$media_e" ]] && mfd_epoch_near "$contour_start_e" "$media_e"; then
    vs="ok vs Contour start"
  fi
  if [[ -n "$vs" ]]; then
    printf '  %-18s %-21s %s  %s\n' "Media tags" "$(mfd_disp_or_na "$media_e")" "$media_note" "$vs"
  else
    printf '  %-18s %-21s %s\n' "Media tags" "$(mfd_disp_or_na "$media_e")" "$media_note"
  fi
  if [[ -n "$layout" ]]; then
    echo "  Contour layout: ${layout}"
  fi
  case "$verdict" in
    agree)    echo "  Verdict: agree — no change" ;;
    disagree) echo "  Verdict: disagree — ask / fix" ;;
    skip)     echo "  Verdict: skip — no usable stamps to compare" ;;
    *)        echo "  Verdict: ${verdict}" ;;
  esac
}

# Inspect stamps. Sets MFD_NAME_E / MFD_FS_E / MFD_MEDIA_E / MFD_CONTOUR_* / MFD_VERDICT
# (agree|disagree|skip). Return 0 if disagree (needs a decision), 1 otherwise.
# On disagree also fills MFD_LABELS / MFD_EPOCHS / … for the prompt.
# First three menu rows stay File name / Filesystem / Media tags (before/after table).
mfd_prepare_file() {
  local f="$1"
  local name_e="" fs_e="" media_e=""
  local i n oldest_e="" oldest_i=0 need=0 abs_diff contour_idx=-1
  MFD_LABELS=()
  MFD_EPOCHS=()
  MFD_NOTES=()
  MFD_DEF=1
  MFD_DEFAULT_KEY=1
  MFD_OLDEST_E=""
  MFD_NAME_E=""
  MFD_FS_E=""
  MFD_MEDIA_E=""
  MFD_CONTOUR_START_E=""
  MFD_CONTOUR_END_E=""
  MFD_CONTOUR_DUR=""
  MFD_CONTOUR_LAYOUT=""
  MFD_CONTOUR_MENU_IDX=-1
  MFD_VERDICT="skip"

  name_e="$(mfd_filename_epoch_from_basename "${f##*/}" 2>/dev/null || true)"
  fs_e="$(mfd_fs_mtime_epoch "$f" 2>/dev/null || true)"
  media_e="$(mfd_media_createdate_epoch "$f" 2>/dev/null || true)"
  MFD_NAME_E="$name_e"
  MFD_FS_E="$fs_e"
  MFD_MEDIA_E="$media_e"
  mfd_contour_analyze "$f" "$name_e" "$fs_e" "$media_e" || true

  # Need at least one usable stamp that can be compared.
  if [[ -z "$name_e" && -z "$fs_e" && -z "$media_e" ]]; then
    MFD_VERDICT="skip"
    return 1
  fi

  if [[ -n "${MFD_CONTOUR_START_E:-}" && -n "${MFD_CONTOUR_END_E:-}" ]]; then
    # Contour target: name=start, FS=end, media=start (FS≠media by design).
    mfd_epoch_near "$name_e" "$MFD_CONTOUR_START_E" || need=1
    if [[ -n "$fs_e" ]]; then
      mfd_epoch_near "$fs_e" "$MFD_CONTOUR_END_E" || need=1
    else
      need=1
    fi
    if [[ -n "$media_e" ]]; then
      mfd_epoch_near "$media_e" "$MFD_CONTOUR_START_E" || need=1
    else
      need=1
    fi
  else
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
  fi

  if (( ! need )); then
    MFD_VERDICT="agree"
    return 1
  fi
  MFD_VERDICT="disagree"

  # Always list File name / Filesystem / Media tags first (before/after uses indices 0–2).
  MFD_LABELS+=("File name")
  MFD_EPOCHS+=("${name_e}")
  if [[ -n "$name_e" ]]; then
    if [[ "${MFD_CONTOUR_LAYOUT:-}" == "normalized" ]]; then
      MFD_NOTES+=("(Contour: name = start)")
    elif [[ "${MFD_CONTOUR_LAYOUT:-}" == "end_in_name" ]]; then
      MFD_NOTES+=("(Contour: name = end of clip)")
    else
      MFD_NOTES+=("")
    fi
  else
    MFD_NOTES+=("(no stamp in name, or before 1990)")
  fi
  MFD_LABELS+=("Filesystem")
  MFD_EPOCHS+=("${fs_e}")
  if [[ -n "$fs_e" ]]; then
    if [[ -n "${MFD_CONTOUR_END_E:-}" ]]; then
      MFD_NOTES+=("(mtime; Contour target = end)")
    else
      MFD_NOTES+=("(mtime)")
    fi
  else
    MFD_NOTES+=("(mtime missing or before 1990)")
  fi
  MFD_LABELS+=("Media tags")
  MFD_EPOCHS+=("${media_e}")
  if [[ -n "$media_e" ]]; then
    if [[ -n "${MFD_CONTOUR_START_E:-}" ]]; then
      MFD_NOTES+=("(CreateDate; Contour target = start)")
    else
      MFD_NOTES+=("(CreateDate / DateTimeOriginal)")
    fi
  else
    MFD_NOTES+=("(CreateDate missing or before 1990)")
  fi
  # Contour normalize row (sentinel epoch = start; apply path uses start+end).
  if [[ -n "${MFD_CONTOUR_START_E:-}" && -n "${MFD_CONTOUR_END_E:-}" ]]; then
    contour_idx=${#MFD_LABELS[@]}
    MFD_CONTOUR_MENU_IDX=$contour_idx
    MFD_LABELS+=("Contour normalize")
    MFD_EPOCHS+=("${MFD_CONTOUR_START_E}")
    MFD_NOTES+=("(name→start, FS→end, media→start)")
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
  # Contour: default to Contour normalize, not plain oldest (which would set FS=start).
  if (( contour_idx >= 0 )); then
    MFD_DEF=$((contour_idx + 1))
  else
    MFD_DEF=$((oldest_i + 1))
  fi
  MFD_DEFAULT_KEY="$MFD_DEF"
  return 0
}

mfd_clear_plans() {
  PLAN_KIND=()
  PLAN_PATH=()
  PLAN_EPOCH=()
  PLAN_END_E=()
  PLAN_LABEL=()
  PLAN_BEFORE_NAME=()
  PLAN_BEFORE_FS=()
  PLAN_BEFORE_MEDIA=()
}

mfd_queue_epoch() {
  # $1 path $2 epoch $3 label $4 before_name $5 before_fs $6 before_media
  PLAN_KIND+=("epoch")
  PLAN_PATH+=("$1")
  PLAN_EPOCH+=("$2")
  PLAN_END_E+=("")
  PLAN_LABEL+=("$3")
  PLAN_BEFORE_NAME+=("$4")
  PLAN_BEFORE_FS+=("$5")
  PLAN_BEFORE_MEDIA+=("$6")
}

mfd_queue_contour() {
  # $1 path $2 start $3 end $4 before_name $5 before_fs $6 before_media
  PLAN_KIND+=("contour")
  PLAN_PATH+=("$1")
  PLAN_EPOCH+=("$2")
  PLAN_END_E+=("$3")
  PLAN_LABEL+=("Contour normalize")
  PLAN_BEFORE_NAME+=("$4")
  PLAN_BEFORE_FS+=("$5")
  PLAN_BEFORE_MEDIA+=("$6")
}

mfd_apply_plans() {
  local i n=${#PLAN_PATH[@]} kind path
  (( n > 0 )) || {
    echo "$(mfd_ts) Nothing to write in this batch."
    return 0
  }
  echo
  mfd_rule
  if [[ -n "${MFD_Q_BATCH_NUM:-}" ]]; then
    echo "$(mfd_ts) Batch ${MFD_Q_BATCH_NUM}: applying ${n} planned fix(es)…"
  else
    echo "$(mfd_ts) Applying ${n} planned fix(es)…"
  fi
  mfd_rule
  trap mfd_ctrl_c INT
  # Apply phase: clear decide question counters so Processing banners stay clean.
  MFD_Q_BATCH_POS=""
  MFD_Q_BATCH_TOTAL=""
  MFD_Q_OVERALL_POS=""
  MFD_Q_OVERALL_TOTAL=""
  mfd_proc_begin
  MFD_APPLY_TOTAL=$n
  for (( i = 0; i < n; i++ )); do
    kind="${PLAN_KIND[i]}"
    path="${PLAN_PATH[i]}"
    MFD_APPLY_INDEX=$((i + 1))
    echo "$(mfd_ts) Fix ${MFD_APPLY_INDEX}/${n}: ${path##*/} (${PLAN_LABEL[i]})"
    mfd_print_processing "$path"
    if [[ "$kind" == "contour" ]]; then
      if mfd_apply_contour_normalize "$path" "${PLAN_EPOCH[i]}" "${PLAN_END_E[i]}"; then
        FIXED=$((FIXED + 1))
        mfd_show_result_table "${MFD_APPLIED_PATH:-$path}" \
          "${PLAN_BEFORE_NAME[i]}" "${PLAN_BEFORE_FS[i]}" "${PLAN_BEFORE_MEDIA[i]}"
      else
        echo "$(mfd_ts) Contour normalize failed: ${path##*/}" >&2
      fi
    else
      if mfd_apply_epoch "$path" "${PLAN_EPOCH[i]}"; then
        FIXED=$((FIXED + 1))
        echo "$(mfd_ts) Set from ${PLAN_LABEL[i]}: $(mfd_format_epoch_display "${PLAN_EPOCH[i]}")"
        mfd_show_result_table "$path" \
          "${PLAN_BEFORE_NAME[i]}" "${PLAN_BEFORE_FS[i]}" "${PLAN_BEFORE_MEDIA[i]}"
      else
        echo "$(mfd_ts) Failed to set dates: ${path##*/}" >&2
      fi
    fi
  done
  MFD_APPLY_INDEX=""
  MFD_APPLY_TOTAL=""
  mfd_proc_end
  trap - INT
  mfd_clear_plans
}

# Decide only (queue writes). Return 2 = quit (abandon current batch plans).
mfd_decide_file() {
  local f="$1"
  local i n choice disp note prompt_keys prompt_extra="" def_note
  local before_name before_fs before_media need_fix=0
  local -a key_list=()

  if mfd_prepare_file "$f"; then
    need_fix=1
  fi
  if (( VERBOSE )); then
    mfd_verbose_print_check "$f" "$MFD_VERDICT" "$MFD_NAME_E" "$MFD_FS_E" "$MFD_MEDIA_E"
  fi
  if (( ! need_fix )); then
    mfd_print_decide_slot "agree (no prompt): ${f##*/}"
    return 0
  fi

  MISMATCH=$((MISMATCH + 1))
  n=${#MFD_LABELS[@]}
  before_name="${MFD_EPOCHS[0]}"
  before_fs="${MFD_EPOCHS[1]}"
  before_media="${MFD_EPOCHS[2]}"

  if (( ALWAYS_KEEP )); then
    mfd_print_decide_slot "kept as written (no prompt): ${f##*/}"
    echo "$(mfd_ts) Kept as written (for the rest of this run): ${f##*/}"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  # [c] rest-of-run: Contour normalize when Contour start/end are known.
  if (( ALWAYS_CONTOUR_START )) && [[ -n "${MFD_CONTOUR_START_E:-}" && -n "${MFD_CONTOUR_END_E:-}" ]]; then
    mfd_print_processing "$f"
    echo "$(mfd_ts) Queued (Contour normalize): ${f##*/}"
    mfd_queue_contour "$f" "$MFD_CONTOUR_START_E" "$MFD_CONTOUR_END_E" \
      "$before_name" "$before_fs" "$before_media"
    return 0
  fi

  if (( DO_YES )) || (( ALWAYS_OLDEST )) || (( ! script_is_run_interactively )); then
    mfd_print_processing "$f"
    if (( ALWAYS_OLDEST )); then
      if [[ -n "$MFD_OLDEST_E" ]]; then
        echo "$(mfd_ts) Queued (oldest usable): ${f##*/}"
        mfd_queue_epoch "$f" "$MFD_OLDEST_E" "oldest usable" \
          "$before_name" "$before_fs" "$before_media"
      fi
      return 0
    fi
    if [[ -n "${MFD_CONTOUR_START_E:-}" && -n "${MFD_CONTOUR_END_E:-}" ]]; then
      echo "$(mfd_ts) Queued (Contour normalize): ${f##*/}"
      mfd_queue_contour "$f" "$MFD_CONTOUR_START_E" "$MFD_CONTOUR_END_E" \
        "$before_name" "$before_fs" "$before_media"
      return 0
    fi
    if [[ -n "$MFD_OLDEST_E" ]]; then
      echo "$(mfd_ts) Queued (oldest usable): ${f##*/}"
      mfd_queue_epoch "$f" "$MFD_OLDEST_E" "oldest usable" \
        "$before_name" "$before_fs" "$before_media"
    fi
    return 0
  fi

  mfd_print_processing "$f"
  echo
  if [[ -n "${MFD_CONTOUR_START_E:-}" ]]; then
    echo "  Sources (Contour normalize is the default: name→start, FS→end, media→start)."
    echo "  Decisions are queued; writes run after this batch's questions."
  else
    echo "  Sources (oldest usable is the default)."
    echo "  Decisions are queued; writes run after this batch's questions."
  fi
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
      if (( i == MFD_CONTOUR_MENU_IDX )); then
        def_note="default"
      else
        def_note="oldest - default"
      fi
      if [[ -n "$note" ]]; then
        note="${note} (${def_note})"
      else
        note="(${def_note})"
      fi
    fi
    printf '  [%d] %-18s %-19s  %s\n' \
      "$((i + 1))" "${MFD_LABELS[i]}" "$disp" "$note"
    key_list+=("$((i + 1))")
  done
  echo "  [$(mfd_k a "$MFD_DEFAULT_KEY")] Always oldest for the rest of this run"
  if [[ -n "${MFD_CONTOUR_START_E:-}" && -n "${MFD_CONTOUR_END_E:-}" ]]; then
    echo "  [$(mfd_k c "$MFD_DEFAULT_KEY")] Always Contour normalize for the rest of this run"
    echo "      name→start (rename), filesystem→end, media→start."
    echo "      Applies to this file and later Contour files only; non-Contour still use oldest / prompts."
    echo "      Already normalized Contour files (name=start, FS=end, media=start) stay skipped."
  fi
  echo "  [$(mfd_k k "$MFD_DEFAULT_KEY")] Keep as written for the rest of this run"
  echo "  [$(mfd_k b "$MFD_DEFAULT_KEY")] Begin apply now — write answers so far; ask remaining files later"
  echo "  [$(mfd_k s "$MFD_DEFAULT_KEY")] Skip this file"
  echo "  [$(mfd_k q "$MFD_DEFAULT_KEY")] Quit (abandon this batch's pending writes)"
  if [[ -n "${MFD_CONTOUR_START_E:-}" && -n "${MFD_CONTOUR_END_E:-}" ]]; then
    key_list+=(a c k b s q)
  else
    key_list+=(a k b s q)
  fi
  prompt_keys="$(mfd_keys "$MFD_DEFAULT_KEY" "${key_list[@]}")"
  if [[ "$MFD_DEFAULT_KEY" =~ ^[0-9]+$ ]]; then
    i=$((MFD_DEFAULT_KEY - 1))
    prompt_extra=" (default ${MFD_DEFAULT_KEY} = ${MFD_LABELS[i]})"
  fi

  while true; do
    mfd_read_key "Fix dates [${prompt_keys}]${prompt_extra} (question ${MFD_Q_BATCH_POS}/${MFD_Q_BATCH_TOTAL}): " "$MFD_DEFAULT_KEY"
    choice="$(mfd_choice "$REPLY")"
    case "$choice" in
      q)
        mfd_print_selected "q = Quit"
        echo "$(mfd_ts) Quit — abandoning ${#PLAN_PATH[@]} pending fix(es) in this batch."
        mfd_clear_plans
        return 2
        ;;
      b)
        if (( ${#PLAN_PATH[@]} == 0 )); then
          echo "$(mfd_ts) Nothing queued yet — answer at least one file (or Skip), then [b]."
          continue
        fi
        mfd_print_selected "b = Begin apply now (answers so far)"
        echo "$(mfd_ts) Stopping decide early — will apply ${#PLAN_PATH[@]} queued fix(es); this file and later ones stay for the next decide round."
        return 3
        ;;
      s)
        mfd_print_selected "s = Skip this file"
        echo "$(mfd_ts) Skipped: ${f##*/}"
        SKIPPED=$((SKIPPED + 1))
        return 0
        ;;
      a)
        mfd_print_selected "a = Always oldest for the rest of this run"
        ALWAYS_OLDEST=1
        ALWAYS_KEEP=0
        ALWAYS_CONTOUR_START=0
        if [[ -n "$MFD_OLDEST_E" ]]; then
          echo "$(mfd_ts) Queued (oldest usable): ${f##*/}"
          mfd_queue_epoch "$f" "$MFD_OLDEST_E" "oldest usable" \
            "$before_name" "$before_fs" "$before_media"
        fi
        echo "$(mfd_ts) Will use the oldest usable date for every later file."
        return 0
        ;;
      c)
        if [[ -z "${MFD_CONTOUR_START_E:-}" || -z "${MFD_CONTOUR_END_E:-}" ]]; then
          echo "$(mfd_ts) Contour normalize is not available for this file."
          continue
        fi
        mfd_print_selected "c = Always Contour normalize for the rest of this run"
        ALWAYS_CONTOUR_START=1
        ALWAYS_OLDEST=0
        ALWAYS_KEEP=0
        echo "$(mfd_ts) Queued (Contour normalize): ${f##*/}"
        mfd_queue_contour "$f" "$MFD_CONTOUR_START_E" "$MFD_CONTOUR_END_E" \
          "$before_name" "$before_fs" "$before_media"
        echo "$(mfd_ts) Will Contour-normalize every later Contour file; other files still use oldest usable / prompts."
        return 0
        ;;
      k)
        mfd_print_selected "k = Keep as written for the rest of this run"
        ALWAYS_KEEP=1
        ALWAYS_OLDEST=0
        ALWAYS_CONTOUR_START=0
        echo "$(mfd_ts) Kept as written: ${f##*/}"
        SKIPPED=$((SKIPPED + 1))
        echo "$(mfd_ts) Will keep dates as written for every later file."
        return 0
        ;;
    esac
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= n )); then
      i=$((choice - 1))
      mfd_print_selected "${choice} = ${MFD_LABELS[i]}"
      if (( i == n - 1 )); then
        echo "$(mfd_ts) Kept as written: ${f##*/}"
        SKIPPED=$((SKIPPED + 1))
        return 0
      fi
      if [[ -z "${MFD_EPOCHS[i]}" ]]; then
        echo "$(mfd_ts) ${MFD_LABELS[i]} is n/a (not usable). Pick another."
        continue
      fi
      if (( i == MFD_CONTOUR_MENU_IDX )); then
        echo "$(mfd_ts) Queued (Contour normalize): ${f##*/}"
        mfd_queue_contour "$f" "$MFD_CONTOUR_START_E" "$MFD_CONTOUR_END_E" \
          "$before_name" "$before_fs" "$before_media"
        return 0
      fi
      echo "$(mfd_ts) Queued (${MFD_LABELS[i]}): ${f##*/}"
      mfd_queue_epoch "$f" "${MFD_EPOCHS[i]}" "${MFD_LABELS[i]}" \
        "$before_name" "$before_fs" "$before_media"
      return 0
    fi
    echo "$(mfd_ts) Unknown choice: ${REPLY}."
  done
}

mfd_default_batch_size_for_count() {
  local n="$1"
  if (( n <= 0 )); then
    printf '%s\n' "1"
  elif (( n <= 50 )); then
    printf '%s\n' "$n"
  else
    printf '%s\n' "50"
  fi
}

# Classify each file once: agree/skip out of the work list; disagree stays actionable.
# Sets ACTIONABLE / ACTIONABLE_COUNT / ALREADY_OK. Verbose prints each skip during pre-scan.
mfd_prescan_actionable() {
  local f i n=${#FILES[@]}
  ACTIONABLE=()
  ALREADY_OK=0
  echo
  echo "$(mfd_ts) Pre-scan: checking ${n} media file(s)…"
  for (( i = 0; i < n; i++ )); do
    f="${FILES[i]}"
    if mfd_prepare_file "$f"; then
      ACTIONABLE+=("$f")
      continue
    fi
    ALREADY_OK=$((ALREADY_OK + 1))
    if (( VERBOSE )); then
      mfd_verbose_print_check "$f" "$MFD_VERDICT" "$MFD_NAME_E" "$MFD_FS_E" "$MFD_MEDIA_E"
    fi
  done
  ACTIONABLE_COUNT=${#ACTIONABLE[@]}
  echo "$(mfd_ts) Pre-scan done: ${ALREADY_OK} no decision needed, ${ACTIONABLE_COUNT} disagree (of ${SCANNED} scanned)."
}

mfd_ask_batch_size() {
  local n="$ACTIONABLE_COUNT" def input
  if (( n <= 0 )); then
    BATCH_SIZE=0
    echo "$(mfd_ts) Batch size: n/a (nothing needs a decision)."
    return 0
  fi
  def="$(mfd_default_batch_size_for_count "$n")"
  if [[ -n "${BATCH_SIZE_CLI:-}" ]]; then
    BATCH_SIZE="$BATCH_SIZE_CLI"
    echo "$(mfd_ts) Batch size: ${BATCH_SIZE} (--batch-size)."
    return 0
  fi
  if [[ -n "${MFD_BATCH_SIZE:-}" ]]; then
    if [[ "${MFD_BATCH_SIZE}" =~ ^[1-9][0-9]*$ ]]; then
      BATCH_SIZE="$MFD_BATCH_SIZE"
      echo "$(mfd_ts) Batch size: ${BATCH_SIZE} (MFD_BATCH_SIZE)."
      return 0
    fi
    echo "$(mfd_ts) Invalid MFD_BATCH_SIZE=${MFD_BATCH_SIZE}; asking interactively." >&2
  fi
  if (( DO_YES )) || (( ! script_is_run_interactively )); then
    BATCH_SIZE="$def"
    echo "$(mfd_ts) Batch size: ${BATCH_SIZE} (non-interactive default)."
    return 0
  fi
  echo
  echo "$(mfd_ts) Total media files in this run: ${SCANNED}"
  echo "  No decision needed: ${ALREADY_OK}"
  echo "  Need a decision: ${n}"
  if (( n <= 50 )); then
    echo "  Suggested batch size: ${def} (all remaining in one go; ≤ 50)."
  else
    echo "  Suggested batch size: ${def} (of ${n}). Decide first, then write, then next batch."
  fi
  echo "  Enter how many files to decide before applying fixes."
  while true; do
    printf '%s Batch size [%s]: ' "$(mfd_ts)" "$def"
    mfd_prompt_wait_begin
    read -r input || input=""
    mfd_prompt_wait_end
    input="${input%"${input##*[![:space:]]}"}"
    input="${input#"${input%%[![:space:]]*}"}"
    if [[ -z "$input" ]]; then
      BATCH_SIZE="$def"
      break
    fi
    if [[ "$input" =~ ^[1-9][0-9]*$ ]]; then
      BATCH_SIZE="$input"
      break
    fi
    echo "$(mfd_ts) Enter a positive integer (or press Enter for ${def})."
  done
  mfd_print_selected "batch size ${BATCH_SIZE}"
}

# --- options ---
DO_YES=0
RECURSIVE=0
DRY_RUN=0
VERBOSE=0
ALWAYS_OLDEST=0
ALWAYS_KEEP=0
ALWAYS_CONTOUR_START=0
MFD_CONTOUR_MENU_IDX=-1
BATCH_SIZE=0
BATCH_SIZE_CLI=""
FIXED=0
SKIPPED=0
SCANNED=0
MISMATCH=0
ALREADY_OK=0
ACTIONABLE=()
ACTIONABLE_COUNT=0
MFD_SCRIPT_START_EPOCH=0
MFD_SCRIPT_START_STR=""
MFD_CURRENT_WRITE_FILE=""
MFD_EXIFTOOL_PID=""
MFD_PROGRESS_ACTIVE=0
MFD_PROC_SEC=0
MFD_PROC_MARK=0
MFD_PROMPT_WAIT_SEC=0
MFD_PROMPT_WAIT_MARK=0
PLAN_KIND=()
PLAN_PATH=()
PLAN_EPOCH=()
PLAN_END_E=()
PLAN_LABEL=()
PLAN_BEFORE_NAME=()
PLAN_BEFORE_FS=()
PLAN_BEFORE_MEDIA=()
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
    --batch-size)
      shift
      [[ $# -gt 0 ]] || { echo "$(mfd_ts) --batch-size needs a positive integer." >&2; exit 1; }
      BATCH_SIZE_CLI="$1"
      shift
      ;;
    --batch-size=*)
      BATCH_SIZE_CLI="${1#--batch-size=}"
      shift
      ;;
    --)
      shift
      POSITIONALS+=("$@")
      break
      ;;
    -*)
      echo "$(mfd_ts) Unknown argument: $1" >&2
      echo "Try: $(script_live_basename) --help" >&2
      exit 1
      ;;
    *)
      POSITIONALS+=("$1")
      shift
      ;;
  esac
done

if [[ -n "$BATCH_SIZE_CLI" ]]; then
  if [[ ! "$BATCH_SIZE_CLI" =~ ^[1-9][0-9]*$ ]]; then
    echo "$(mfd_ts) --batch-size needs a positive integer (got: ${BATCH_SIZE_CLI})." >&2
    exit 1
  fi
fi

if [[ -f "${BASH_SOURCE[0]}" ]]; then
  chmod 700 "${BASH_SOURCE[0]}" 2>/dev/null || true
fi

print_version_banner

MFD_SCRIPT_START_EPOCH=$(date +%s)
MFD_SCRIPT_START_STR="$(mfd_wall_clock_now)"

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
  mfd_print_summary
  exit 0
fi

mapfile -t FILES < <(printf '%s\n' "${FILES[@]}" | LC_ALL=C sort -u)
SCANNED=${#FILES[@]}

mfd_prescan_actionable
mfd_ask_batch_size

if (( ACTIONABLE_COUNT <= 0 )); then
  echo
  echo "$(mfd_ts) Nothing needs a decision (${ALREADY_OK} already OK of ${SCANNED} scanned)."
  mfd_print_summary
  if (( SCANNED > 0 && ! VERBOSE )); then
    echo "$(mfd_ts) Re-run with --verbose to see each file check and why."
  fi
  exit 0
fi

echo
echo "$(mfd_ts) Deciding ${ACTIONABLE_COUNT} of ${SCANNED} media file(s); batch size ${BATCH_SIZE}."
echo "$(mfd_ts) Each batch: decide all prompts first, then write."
(( DRY_RUN )) && echo "$(mfd_ts) Dry run — nothing will be written."
(( DO_YES )) && echo "$(mfd_ts) -y: apply without asking (Contour normalize when Contour; else oldest)."
(( VERBOSE )) && echo "$(mfd_ts) Verbose: agree/skip listed during pre-scan."
echo

batch_i=0
file_i=0
quit_run=0
while (( file_i < ACTIONABLE_COUNT )); do
  batch_i=$((batch_i + 1))
  batch_end=$((file_i + BATCH_SIZE))
  (( batch_end > ACTIONABLE_COUNT )) && batch_end=$ACTIONABLE_COUNT
  batch_count=$((batch_end - file_i))
  mfd_clear_plans
  echo
  mfd_rule
  echo "$(mfd_ts) Batch ${batch_i}: files $((file_i + 1))–${batch_end} of ${ACTIONABLE_COUNT} needing a decision — decide (${batch_count} file(s))"
  echo "$(mfd_ts) Tip: press [b] during a prompt to apply answers so far and ask the rest later."
  mfd_rule
  MFD_Q_BATCH_NUM=$batch_i
  MFD_Q_BATCH_TOTAL=$batch_count
  MFD_Q_OVERALL_TOTAL=$ACTIONABLE_COUNT
  early_apply=0
  next_file_i=$batch_end
  for (( j = file_i; j < batch_end; j++ )); do
    MFD_Q_BATCH_POS=$((j - file_i + 1))
    MFD_Q_OVERALL_POS=$((j + 1))
    mfd_decide_file "${ACTIONABLE[j]}"
    rc=$?
    if (( rc == 2 )); then
      quit_run=1
      break
    fi
    if (( rc == 3 )); then
      early_apply=1
      next_file_i=$j
      break
    fi
  done
  if (( quit_run )); then
    break
  fi
  echo "$(mfd_ts) Batch ${batch_i}: apply phase"
  mfd_apply_plans
  file_i=$next_file_i
  if (( early_apply )); then
    echo "$(mfd_ts) Resuming decide at file $((file_i + 1)) of ${ACTIONABLE_COUNT}."
  fi
done

mfd_print_summary
if (( SCANNED > 0 && MISMATCH == 0 && FIXED == 0 && ! VERBOSE )); then
  echo "$(mfd_ts) Nothing to change. Re-run with --verbose to see each file check and why."
fi
exit 0
