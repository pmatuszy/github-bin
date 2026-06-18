#!/bin/bash

# 2026.06.18 - v. 0.5.34 - run summary: no [timestamp] prefix on summary lines
# 2026.06.18 - v. 0.5.33 - end-of-run and Ctrl-C summary (timing, scan/normalize stats)
# 2026.06.18 - v. 0.5.32 - batch NORMALIZING line: prefix with [YYYY.MM.DD HH:MM:SS]
# 2026.06.16 - v. 0.5.31 - before normalize: estimate disk need (+15%), show free space, warn if low
# 2026.06.18 - v. 0.5.30 - after scan: rephrase normalize offer (proceed with loudnorm, not meta “after scan”)
# 2026.06.18 - v. 0.5.29 - normalize progress: 3-line layout (Normalizing: / path / OK)
# 2026.06.18 - v. 0.5.28 - normalize OK label green when --colors yes
# 2026.06.18 - v. 0.5.27 - Y/n prompt hint: UP/DOWN instead of Unicode arrows
# 2026.06.18 - v. 0.5.26 - do not abort scan flow for NO AUDIO files (still offer normalize)
# 2026.06.17 - v. 0.5.25 - scan table: center column headers (FILE, MAX_VOLUME, …)
# 2026.06.17 - v. 0.5.24 - Y/n prompts: arrow up=yes, arrow down=no (↑ yes, ↓ no hint)
# 2026.06.17 - v. 0.5.23 - Files to scan: show count by extension (mp4, avi, ...)
# 2026.06.17 - v. 0.5.22 - offer-normalize prompt moved to after scan (with summary visible)
# 2026.06.17 - v. 0.5.21 - legend: do not color PERFECT label (scan table rows still green)
# 2026.06.17 - v. 0.5.20 - fix terminal colors: use ANSI bytes, not \\e in printf %b
# 2026.06.17 - v. 0.5.19 - prompt menus: default option letter uppercase only
# 2026.06.17 - v. 0.5.18 - terminal colors option (--colors); PERFECT rows green in scan table
# 2026.06.17 - v. 0.5.17 - dB: print 0.0 not -0.0; classes prompt no timeout; per-file default Y/N by class
# 2026.06.17 - v. 0.5.16 - print elapsed time after each normalize (ffmpeg)
# 2026.06.17 - v. 0.5.15 - fix nounset: quote yes/no in batch_selected array appends
# 2026.06.17 - v. 0.5.14 - batch prompt summary: align counter columns
# 2026.06.17 - v. 0.5.13 - fix batch-size prompt false failure (exit status 1 when not --print-cli-only)
# 2026.06.17 - v. 0.5.12 - fix empty normalize queue after sort; guard batch loop on total=0
# 2026.06.17 - v. 0.5.11 - --classes filter for normalize candidates (n/t/p abbreviations)
# 2026.06.17 - v. 0.5.10 - trim extra blank lines between interactive prompts and scan table
# 2026.06.17 - v. 0.5.9 - scan table: Unicode display-width columns (terminal-safe)
# 2026.06.17 - v. 0.5.8 - scan table: column dash gaps; fixed-width dB alignment
# 2026.06.17 - v. 0.5.7 - batch normalize prompts (like ffmpeg-voice): ask N, then process
# 2026.06.17 - v. 0.5.6 - prompt brackets: default letter capital; read timeout 10 min
# 2026.06.17 - v. 0.5.5 - scan scope: current directory or subdirectories (--scope)
# 2026.06.17 - v. 0.5.4 - interactive normalize prompt defaults to YouTube
# 2026.06.17 - v. 0.5.3 - --scan-only: measure cwd non-interactively, no normalize
# 2026.06.17 - v. 0.5.2 - CLI flags skip startup/wizard prompts on a TTY (-y batch)
# 2026.06.17 - v. 0.5.1 - Ctrl-C: remove temp output, restore *.backup.deleteme if moved aside
# 2026.06.17 - v. 0.5.0 - --print-cli-only; window title [cwd] script argv; prompt timestamps
# 2026.06.17 - v. 0.4.5 - normalize queue processed in alphabetical order
# 2026.06.17 - v. 0.4.4 - interactive backup conflict: replace, keep, or skip
# 2026.06.16 - v. 0.4.3 - per-file [D] normalize rest of directory (was [R] rest of batch)
# 2026.06.16 - v. 0.4.2 - prompt timestamps in square brackets for readability
# 2026.06.16 - v. 0.4.1 - backup: move original to *.backup.deleteme (not timestamped copy)
# 2026.06.16 - v. 0.4.0 - YouTube mode: optional include PERFECT; [R] normalize rest in batch
# 2026.06.16 - v. 0.3.12 - fix normalize temp path: name.tmp.PID.ext (ffmpeg muxer detection)
# 2026.06.16 - v. 0.3.11 - backup originals as name_YYYYMMDD_HHMMSS.ext (not name.ext_timestamp)
# 2026.06.16 - v. 0.3.10 - interactive backup prompt defaults to yes
# 2026.06.16 - v. 0.3.9 - optional backup originals as name.ext_YYYYMMDD_HHMMSS before normalize
# 2026.06.16 - v. 0.3.8 - normalize all audio tracks; copy video, subtitles, metadata, other streams
# 2026.06.16 - v. 0.3.7 - fix MP4 normalize: map streams, re-encode audio (aac); show ffmpeg errors
# 2026.06.16 - v. 0.3.6 - offer normalize for NORMAL and TOO_QUIET; skip only PERFECT
# 2026.06.16 - v. 0.3.5 - after normalize: print max/mean volume before and after
# 2026.06.16 - v. 0.3.4 - FILE column capped at 150 chars (shorter when names are shorter)
# 2026.06.16 - v. 0.3.3 - startup “offer normalize after scan?” defaults to yes
# 2026.06.16 - v. 0.3.2 - scan table: right-align MAX/MEAN dB columns (decimal aligned, not minus)
# 2026.06.16 - v. 0.3.1 - normalize prompts default N; [Q] quit on normalize-related prompts
# 2026.06.16 - v. 0.3.0 - no CLI flags: interactive startup; stream scan rows one-by-one (no hang)
# 2026.06.16 - v. 0.2.2 - legend: indent PERFECT dB range one column (leading minus on other rows)
# 2026.06.16 - v. 0.2.1 - align classification legend columns (label / dB / description)
# 2026.06.16 - v. 0.2 - dB cheat-sheet categories; optional loudnorm (standard / youtube-style); preserve mtime
# 2026.06.16 - v. 0.1 - initial release: scan cwd for audio/video; ffmpeg volumedetect; flag too-silent files

print_version_banner() {
  local ver=unknown date= line title verline width=60
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*) ]]; then
      date="${BASH_REMATCH[1]}"
      ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  title="$(basename "$0")"
  if [[ -n "$date" ]]; then
    verline="Version: ${ver} (${date})"
  else
    verline="Version: ${ver}"
  fi
  printf '┌%*s┐\n' "$width" '' | tr ' ' '─'
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$title"
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$verline"
  printf '└%*s┘\n' "$width" '' | tr ' ' '─'
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]
       [-n standard|youtube|none] [-y] [--colors yes|no] [--scope current|subdirs]
       [--batch-size N] [--classes SPEC] [--scan-only] [--print-cli-only] [-- FILE ...]

Scan for audio and video files and measure loudness with ffmpeg volumedetect
(video is ignored for speed). Each file is classified by peak level (max_volume):

  PERFECT (0.0 to -2.0 dB)     Already near digital maximum — do not normalize.
  NORMAL  (-2.0 to -6.0 dB)    Usually fine; normalize only if you want louder mix.
  TOO QUIET (-6.0 dB or lower) Prime candidates for loudnorm (quiet dialogue).

Optionally normalize selected classification groups in place (original
modification time kept). By default NORMAL and TOO QUIET are candidates;
PERFECT is optional (YouTube mode or --classes / --include-perfect).

Supported extensions (case-insensitive):
  Video: .avi .mp4 .mkv .mov .wmv .mpeg .mpg .m4v .webm .ts
  Audio: .mp3 .flac .wav .m4a .aac .ogg .opus .wma

With FILE operands, only those paths are checked (must exist). Without FILE,
media files are discovered in the working directory — current folder only by
default, or the whole tree with --scope subdirs (interactive default: subdirs).

When no command-line options are given (only optional FILE operands), the script
runs in interactive mode: it asks about terminal colors and scan scope, whether
to scan, and (after results are shown) whether to offer normalization. Each result
row is printed as soon as that file is measured. With --colors yes, PERFECT rows
are green in the scan table.

Normalization (non-PERFECT by default; PERFECT is never offered for standard mode):
  standard   ffmpeg loudnorm (default filter parameters)
  youtube    loudnorm=I=-16:TP=-1.0:LRA=11  (YouTube-style targets; can include PERFECT)

Video files: loudnorm on every audio track; video, subtitles, chapters, metadata,
and other non-audio streams are copied. Audio is re-encoded (AAC for MP4/MKV, etc.).
After a successful in-place replace, the output file gets the original timestamps
(mtime/atime) back via touch -r.

Optionally move each original aside before normalizing (delete *.backup.deleteme when satisfied):
  e.g. clip.mp4 -> clip.mp4.backup.deleteme   (same directory)
  If that backup path already exists, interactive mode explains the conflict and
  offers to replace the old backup, keep it and normalize in place, or skip.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  -n, --normalize MODE none|standard|youtube
                       Normalize eligible files (default: ask when interactive,
                       skip when not interactive unless -n is set).
  -y, --yes            Do not ask per file; normalize every eligible file when
                       -n standard or -n youtube is selected. With any CLI
                       option, startup wizard prompts are also skipped.
  --save-original      Move each original to *.backup.deleteme before normalizing
                       (skip the interactive backup question).
  --replace-backup     When *.backup.deleteme already exists, remove it and move
                       the current file aside (non-interactive; no prompt).
  --print-cli-only     Interactive dry-run: answer the usual prompts but do not
                       scan, normalize, or modify any file. Prints an equivalent
                       non-interactive command at the end.
  --scan-only          Measure loudness only; no prompts and no normalization
                       (exit 0 when scan completes).
  --scope current|subdirs
                       current = files in cwd only; subdirs = cwd and all
                       subfolders (skip the interactive scope question).
  --batch-size N       Per-file normalize prompts: ask N files at a time before
                       processing (default 50; skip the interactive batch question).
  --colors yes|no      Use terminal colors (skip the interactive colors question).
                       When enabled, PERFECT rows in the scan table are green.
  --classes SPEC       Normalization candidates by class (scan still measures all).
                       SPEC is comma-separated and/or concatenated letters:
                       n=normal, t or q=too-quiet, p=perfect, a or all=all three.
                       Default: n,t (NORMAL + TOO QUIET). Examples: --classes t
                       --classes n,t,p  LOUDNESS_CLASSES=n,q
  --include-perfect    Include PERFECT in candidate classes (same as adding p to
                       --classes; with -n youtube; skipped when -n standard).
  --no_startup_delay   Skip random startup delay when run non-interactively
                       (see _script_header.sh).
  -- FILE              Explicit file operands (use when a name starts with -).

Interactive normalization prompts (per file, in batches like ffmpeg-voice.sh):
  Ask about up to N files (batch size, default 50), then normalize only the
  files you selected in that batch before the next batch of prompts.
  Per-file normalize (batch prompts; default Y for NORMAL/TOO QUIET, N for PERFECT):
  [Y]/[n] yes/no, [d] rest of directory, [a] all remaining in batch,
  [f] finish batch (normalize selected; stop asking), [g] normalize selected and
  skip all further prompts, [q] quit.
  Backup conflict: [y] replace old backup, [k] keep backup and normalize in
  place, [s] skip file, [q] quit (default [s]).
  Yes/no prompts also accept UP arrow (yes) and DOWN arrow (no); Enter uses
  the default shown in brackets.

Environment:
  LOUDNESS_NORMALIZE        Same as -n / --normalize (CLI overrides).
  LOUDNESS_SAVE_ORIGINAL    1 = move originals to *.backup.deleteme (same as --save-original).
  LOUDNESS_INCLUDE_PERFECT  1 = with youtube mode, include PERFECT files (same as
                              --include-perfect).
  LOUDNESS_REPLACE_BACKUP   1 = remove existing *.backup.deleteme before moving
                              aside (same as --replace-backup).
  LOUDNESS_BACKUP_ON_CONFLICT  Non-interactive when backup exists: replace, keep
                              (normalize in place; default), or skip.
  LOUDNESS_SCAN_SCOPE       current or subdirs (same as --scope).
  LOUDNESS_BATCH_SIZE       Batch size for per-file normalize prompts (same as
                              --batch-size; default 50).
  LOUDNESS_CLASSES          Candidate classes for normalization (same as --classes).
                              n/normal, t or q/too-quiet, p/perfect; default n,t.
  LOUDNESS_READ_TIMEOUT     Seconds to wait for a single-key interactive prompt
                              (default: 600 = 10 minutes; 0 = wait forever).
                              The post-scan classes line prompt waits until Enter.
  LOUDNESS_USE_COLORS       yes or no (same as --colors). Interactive default: yes.

Exit status:
  0  Scan OK and (if requested) normalization finished without failures.
  1  Errors, or eligible files remain after a scan-only run (no normalize),
     except with --scan-only (always 0 after a successful scan).

Examples:
  cd /path/to/clips && $(basename "$0")
  cd /path/to/clips && $(basename "$0") --scan-only
  cd /path/to/tree && $(basename "$0") --scan-only --scope subdirs
  $(basename "$0") -n youtube -y --save-original --colors yes
  $(basename "$0") --print-cli-only
  $(basename "$0") -n standard -- quiet_interview.mkv
EOF
}

LOUDNESS_INVOCATION_CWD="$(pwd -P 2>/dev/null || pwd)"
LOUDNESS_ORIGINAL_ARGV=( "$0" "$@" )
LOUDNESS_WINDOW_TITLE_PUSHED=0

NORMALIZE_MODE="${LOUDNESS_NORMALIZE:-}"
AUTO_YES=0
CLI_FILES=()
ANY_CLI_OPTIONS=0
PRINT_CLI_ONLY=0
SCAN_ONLY=0
LOUDNESS_SCAN_SCOPE="${LOUDNESS_SCAN_SCOPE:-}"
LOUDNESS_SCAN_SCOPE_CLI=0
LOUDNESS_BATCH_SIZE="${LOUDNESS_BATCH_SIZE:-}"
LOUDNESS_BATCH_SIZE_CLI=0
BATCH_SIZE=50
LOUDNESS_CLASSES="${LOUDNESS_CLASSES:-}"
LOUDNESS_CLASSES_CLI=0
LOUDNESS_CLASSES_RESOLVED=0
LOUDNESS_CLASS_NORMAL=0
LOUDNESS_CLASS_TOO_QUIET=0
LOUDNESS_CLASS_PERFECT=0
LOUDNESS_USE_COLORS="${LOUDNESS_USE_COLORS:-}"
LOUDNESS_COLORS_CLI=0
LOUDNESS_BATCH_CHOICE_DECISION=""
LOUDNESS_BATCH_CHOICE_ACTION=""
LOUDNESS_SAVE_ORIGINAL="${LOUDNESS_SAVE_ORIGINAL:-0}"
LOUDNESS_SAVE_ORIGINAL_CLI=0
LOUDNESS_INCLUDE_PERFECT="${LOUDNESS_INCLUDE_PERFECT:-0}"
LOUDNESS_INCLUDE_PERFECT_CLI=0
LOUDNESS_REPLACE_BACKUP="${LOUDNESS_REPLACE_BACKUP:-0}"
LOUDNESS_REPLACE_BACKUP_CLI=0
LOUDNESS_BACKUP_ON_CONFLICT="${LOUDNESS_BACKUP_ON_CONFLICT:-}"
NORMALIZE_DIR=""
declare -a CLI_SELECTED_FILES=()
CLI_BUILD_ALL_YES=1
CLI_BUILD_NOTES=()

# --- parse options before sourcing the header (avoids figlet/delay on --help/--version) ---
HEADER_EXTRA_ARGS=()
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
    --no_startup_delay)
      ANY_CLI_OPTIONS=1
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    -n|--normalize)
      ANY_CLI_OPTIONS=1
      [[ $# -ge 2 ]] || { echo "Missing value for --normalize" >&2; exit 1; }
      NORMALIZE_MODE="$2"
      shift 2
      ;;
    -y|--yes)
      ANY_CLI_OPTIONS=1
      AUTO_YES=1
      shift
      ;;
    --save-original)
      ANY_CLI_OPTIONS=1
      LOUDNESS_SAVE_ORIGINAL=1
      LOUDNESS_SAVE_ORIGINAL_CLI=1
      shift
      ;;
    --include-perfect)
      ANY_CLI_OPTIONS=1
      LOUDNESS_INCLUDE_PERFECT=1
      LOUDNESS_INCLUDE_PERFECT_CLI=1
      shift
      ;;
    --replace-backup)
      ANY_CLI_OPTIONS=1
      LOUDNESS_REPLACE_BACKUP=1
      LOUDNESS_REPLACE_BACKUP_CLI=1
      shift
      ;;
    --print-cli-only)
      ANY_CLI_OPTIONS=1
      PRINT_CLI_ONLY=1
      shift
      ;;
    --scan-only)
      ANY_CLI_OPTIONS=1
      SCAN_ONLY=1
      shift
      ;;
    --scope)
      ANY_CLI_OPTIONS=1
      [[ $# -ge 2 ]] || { echo "Missing value for --scope" >&2; exit 1; }
      case "${2,,}" in
        current|c) LOUDNESS_SCAN_SCOPE=current ;;
        subdirs|s) LOUDNESS_SCAN_SCOPE=subdirs ;;
        *)
          echo "Invalid value for --scope: $2 (use current or subdirs)" >&2
          exit 1
          ;;
      esac
      LOUDNESS_SCAN_SCOPE_CLI=1
      shift 2
      ;;
    --batch-size)
      ANY_CLI_OPTIONS=1
      [[ $# -ge 2 ]] || { echo "Missing value for --batch-size" >&2; exit 1; }
      case "$2" in
        *[!0-9]*|'') echo "Invalid value for --batch-size: $2 (use a positive integer)" >&2; exit 1 ;;
        0*) echo "Invalid value for --batch-size: $2 (use a positive integer)" >&2; exit 1 ;;
        *) LOUDNESS_BATCH_SIZE="$2" ;;
      esac
      LOUDNESS_BATCH_SIZE_CLI=1
      BATCH_SIZE="$LOUDNESS_BATCH_SIZE"
      shift 2
      ;;
    --classes)
      ANY_CLI_OPTIONS=1
      [[ $# -ge 2 ]] || { echo "Missing value for --classes" >&2; exit 1; }
      LOUDNESS_CLASSES="$2"
      LOUDNESS_CLASSES_CLI=1
      shift 2
      ;;
    --colors)
      ANY_CLI_OPTIONS=1
      [[ $# -ge 2 ]] || { echo "Missing value for --colors" >&2; exit 1; }
      case "${2,,}" in
        yes|y|1|true) LOUDNESS_USE_COLORS=yes ;;
        no|n|0|false) LOUDNESS_USE_COLORS=no ;;
        *)
          echo "Invalid value for --colors: $2 (use yes or no)" >&2
          exit 1
          ;;
      esac
      LOUDNESS_COLORS_CLI=1
      shift 2
      ;;
    --)
      shift
      CLI_FILES+=( "$@" )
      break
      ;;
    -*)
      echo "Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
    *)
      CLI_FILES+=( "$1" )
      shift
      ;;
  esac
done

case "${NORMALIZE_MODE,,}" in
  ''|none|standard|youtube) ;;
  *)
    echo "Invalid --normalize / LOUDNESS_NORMALIZE: ${NORMALIZE_MODE}" >&2
    echo "Use: none, standard, or youtube" >&2
    exit 1
    ;;
esac
NORMALIZE_MODE="${NORMALIZE_MODE,,}"

case "${LOUDNESS_SAVE_ORIGINAL,,}" in
  1|yes|true|y) LOUDNESS_SAVE_ORIGINAL=1 ;;
  *)          LOUDNESS_SAVE_ORIGINAL=0 ;;
esac

case "${LOUDNESS_INCLUDE_PERFECT,,}" in
  1|yes|true|y) LOUDNESS_INCLUDE_PERFECT=1 ;;
  *)          LOUDNESS_INCLUDE_PERFECT=0 ;;
esac

case "${LOUDNESS_REPLACE_BACKUP,,}" in
  1|yes|true|y) LOUDNESS_REPLACE_BACKUP=1 ;;
  *)          LOUDNESS_REPLACE_BACKUP=0 ;;
esac

if (( SCAN_ONLY && PRINT_CLI_ONLY )); then
  echo 'ERROR: --scan-only and --print-cli-only cannot be used together.' >&2
  exit 1
fi

if (( SCAN_ONLY )); then
  if [[ -n "$NORMALIZE_MODE" && "$NORMALIZE_MODE" != none ]]; then
    echo "NOTE: --scan-only ignores -n ${NORMALIZE_MODE} (no normalization)." >&2
  fi
  NORMALIZE_MODE=none
  if (( ${#CLI_FILES[@]} > 0 )); then
    echo 'NOTE: --scan-only ignores FILE operands; scanning by scope instead.' >&2
    CLI_FILES=()
  fi
fi

# No flags at all (FILE operands alone are OK): presume interactive prompts and streaming scan.
PRESUME_INTERACTIVE=0
(( ! ANY_CLI_OPTIONS )) && PRESUME_INTERACTIVE=1
(( PRINT_CLI_ONLY )) && PRESUME_INTERACTIVE=1

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

if [[ -f "${BASH_SOURCE[0]}" ]]; then
  chmod 700 "${BASH_SOURCE[0]}" 2>/dev/null || true
fi

LOUDNESS_READ_TIMEOUT="${LOUDNESS_READ_TIMEOUT:-600}"

audio_pgm_loudness_cleanup() {
  loudness_interrupt_restore_in_progress_file
  [[ -n "${LOUDNESS_TMP_FILE:-}" && -f "${LOUDNESS_TMP_FILE}" ]] && rm -f -- "${LOUDNESS_TMP_FILE}"
  loudness_print_run_summary_once
  loudness_window_title_restore
  . /root/bin/_script_footer.sh
}
trap audio_pgm_loudness_cleanup EXIT

check_if_installed ffmpeg || true
if ! command -v ffmpeg >/dev/null 2>&1; then
  if (( PRINT_CLI_ONLY )); then
    echo "NOTE: ffmpeg not found — OK for --print-cli-only (no scan/normalize will run)."
  else
    echo "ERROR: ffmpeg is required but was not found in PATH." >&2
    echo "Try: ffmpeg-install.sh   or install the ffmpeg package." >&2
    kod_powrotu=1
    exit 1
  fi
fi

shopt -s nullglob nocaseglob

MEDIA_EXTENSIONS=(
  avi mp4 mkv mov wmv mpeg mpg m4v webm ts
  mp3 flac wav m4a aac ogg opus wma
)

LOUDNESS_TMP_FILE=""
LOUDNESS_INTERRUPT_RESTORE_DEST=""
LOUDNESS_INTERRUPT_RESTORE_BACKUP=""
LOUDNESS_INTERRUPT_CLEANUP_DONE=0
LOUDNESS_SESSION_START_SEC=""
LOUDNESS_SESSION_START_EPOCH=""
LOUDNESS_SCAN_PROC_SEC=0
LOUDNESS_NORM_PROC_SEC=0
LOUDNESS_PROMPT_WAIT_SEC=0
LOUDNESS_PROMPT_WAIT_MARK=0
LOUDNESS_SCAN_RAN=0
LOUDNESS_NORMALIZE_RAN=0
LOUDNESS_STATS_NORM_OK=0
LOUDNESS_STATS_NORM_SKIP=0
LOUDNESS_STATS_NORM_FAIL=0
LOUDNESS_STATS_NORM_BACKUP_SKIP=0
LOUDNESS_SUMMARY_DONE=no
LOUDNESS_STOPPED_BY_USER=no
LOUDNESS_INTERRUPTED=no
RED=''
GREEN=''
CYAN=''
YELLOW=''
BOLD=''
RESET=''

loudness_colors_enabled() {
  [[ "$LOUDNESS_USE_COLORS" == yes ]]
}

loudness_init_colors() {
  if loudness_colors_enabled; then
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    CYAN=$'\033[36m'
    YELLOW=$'\033[33m'
    BOLD=$'\033[1m'
    RESET=$'\033[0m'
  else
    RED=''
    GREEN=''
    CYAN=''
    YELLOW=''
    BOLD=''
    RESET=''
  fi
}

loudness_normalize_use_colors_token() {
  case "${LOUDNESS_USE_COLORS,,}" in
    yes|y|1|true) LOUDNESS_USE_COLORS=yes ;;
    no|n|0|false) LOUDNESS_USE_COLORS=no ;;
    '')
      return 1
      ;;
    *)
      echo "Invalid LOUDNESS_USE_COLORS / --colors: ${LOUDNESS_USE_COLORS}" >&2
      exit 1
      ;;
  esac
}

prompt_use_colors() {
  (( PRINT_CLI_ONLY )) && loudness_print_cli_only_section 'Terminal colors'
  echo 'Use colors in the terminal?'
  echo '  [Y] Yes (default)'
  echo '  [n] No'
  echo '  [q] Quit'
  loudness_read_yn_key 'Use colors? [Y/n/q]: ' Y
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    N) LOUDNESS_USE_COLORS=no ;;
    *) LOUDNESS_USE_COLORS=yes ;;
  esac
  if [[ "$LOUDNESS_USE_COLORS" == no ]]; then
    cli_equiv_note 'CLI: --colors no'
  fi
}

loudness_resolve_use_colors() {
  if ! loudness_normalize_use_colors_token; then
    if loudness_wants_wizard_prompts || (( PRINT_CLI_ONLY )); then
      prompt_use_colors
    else
      LOUDNESS_USE_COLORS=no
    fi
  fi
  loudness_init_colors
}

loudness_begin_file_normalize() {
  local dest="$1" backup="$2" src="$3"
  LOUDNESS_INTERRUPT_RESTORE_DEST="$dest"
  if [[ -n "$backup" && "$src" == "$backup" ]]; then
    LOUDNESS_INTERRUPT_RESTORE_BACKUP="$backup"
  else
    LOUDNESS_INTERRUPT_RESTORE_BACKUP=""
  fi
}

loudness_end_file_normalize() {
  LOUDNESS_INTERRUPT_RESTORE_DEST=""
  LOUDNESS_INTERRUPT_RESTORE_BACKUP=""
}

loudness_interrupt_restore_in_progress_file() {
  local dest="$LOUDNESS_INTERRUPT_RESTORE_DEST" backup="$LOUDNESS_INTERRUPT_RESTORE_BACKUP"

  (( LOUDNESS_INTERRUPT_CLEANUP_DONE )) && return 0
  LOUDNESS_INTERRUPT_CLEANUP_DONE=1

  [[ -n "${LOUDNESS_TMP_FILE:-}" && -f "${LOUDNESS_TMP_FILE}" ]] && rm -f -- "${LOUDNESS_TMP_FILE}"
  LOUDNESS_TMP_FILE=""

  [[ -n "$dest" && -n "$backup" && -f "$backup" ]] || return 0

  echo "Interrupted during normalize of ${dest}."
  if [[ -f "$dest" ]]; then
    echo "Removing partial output: ${dest}"
    rm -f -- "$dest"
  fi
  if [[ ! -e "$dest" ]]; then
    echo "Restoring original from backup: ${backup}"
    restore_original_from_backup "$backup" "$dest" || \
      echo "WARNING: could not restore ${dest} from ${backup}" >&2
  fi
  loudness_end_file_normalize
}

loudness_on_interrupt() {
  echo
  echo '** Trapped CTRL-C — cleaning up....'
  LOUDNESS_INTERRUPTED=yes
  loudness_interrupt_restore_in_progress_file
  if [[ -n "${STY:-}" ]]; then
    echo -ne "${tcScrTitleStart}${0}${tcScrTitleEnd}"
  fi
  loudness_window_title_restore
  kod_powrotu=130
  exit 130
}

trap loudness_on_interrupt INT

loudness_is_interactive() {
  (( PRESUME_INTERACTIVE )) && return 0
  (( script_is_run_interactively )) && return 0
  return 1
}

# Startup / mode / backup wizard (no CLI flags, or --print-cli-only).
loudness_wants_wizard_prompts() {
  (( PRINT_CLI_ONLY )) && return 0
  (( ! ANY_CLI_OPTIONS )) && return 0
  return 1
}

# Per-file normalize prompts (TTY ok when -n set but -y not set).
loudness_wants_per_file_prompts() {
  (( AUTO_YES )) && return 1
  (( PRESUME_INTERACTIVE )) && return 0
  (( script_is_run_interactively )) && return 0
  return 1
}

loudness_quit_now() {
  LOUDNESS_STOPPED_BY_USER=yes
  echo "Quit requested."
  kod_powrotu=0
  exit 0
}

flush_stdin() {
  local discard drained=0
  while (( drained < 256 )) && IFS= read -r -t 0.02 -n 1 discard; do
    (( ++drained ))
  done
}

loudness_read_tty_byte() {
  local timeout="${1:-}" byte="" use_timeout=0 track_wait=0

  if [[ "$timeout" =~ ^[0-9]+$ ]] && (( timeout > 0 )); then
    use_timeout=1
  fi
  if loudness_is_interactive; then
    LOUDNESS_PROMPT_WAIT_MARK=$SECONDS
    track_wait=1
  fi
  if [[ -r /dev/tty ]] 2>/dev/null; then
    if (( use_timeout )); then
      IFS= read -r -t "$timeout" -n 1 byte < /dev/tty 2>/dev/null || byte=""
    else
      IFS= read -r -n 1 byte < /dev/tty 2>/dev/null || byte=""
    fi
  elif (( use_timeout )); then
    IFS= read -r -t "$timeout" -n 1 byte || byte=""
  else
    IFS= read -r -n 1 byte || byte=""
  fi
  if (( track_wait )); then
    loudness_prompt_wait_end
  fi
  printf '%s' "$byte"
}

loudness_prompt_add_yn_arrow_hint() {
  local prompt="$1"

  [[ "$prompt" == *"(UP yes, DOWN no)"* ]] && {
    printf '%s' "$prompt"
    return 0
  }
  if [[ "$prompt" == *': ' ]]; then
    prompt="${prompt%: }"
    printf '%s (UP yes, DOWN no): ' "$prompt"
  elif [[ "$prompt" == *':' ]]; then
    prompt="${prompt%:}"
    printf '%s (UP yes, DOWN no): ' "$prompt"
  else
    printf '%s (UP yes, DOWN no): ' "$prompt"
  fi
}

loudness_read_arrow_yn_byte() {
  local timeout="${1:-}" answer="" c2 c3

  answer="$(loudness_read_tty_byte "$timeout")"
  if [[ "$answer" == $'\033' ]]; then
    c2="$(loudness_read_tty_byte 0.05)"
    if [[ "$c2" == '[' ]]; then
      c3="$(loudness_read_tty_byte 0.05)"
      case "$c3" in
        A) printf 'Y'; return 0 ;;
        B) printf 'N'; return 0 ;;
      esac
    elif [[ "$c2" == 'O' ]]; then
      c3="$(loudness_read_tty_byte 0.05)"
      case "$c3" in
        A) printf 'Y'; return 0 ;;
        B) printf 'N'; return 0 ;;
      esac
    fi
    printf ''
    return 0
  fi
  printf '%s' "$answer"
}

loudness_read_key() {
  local prompt="$1" default="${2:-N}" timeout="${3:-$LOUDNESS_READ_TIMEOUT}"
  local answer=""

  if ! loudness_is_interactive; then
    REPLY="$default"
    return 0
  fi

  if [[ "$prompt" != \[* ]]; then
    prompt="[$(date '+%Y.%m.%d %H:%M:%S')] ${prompt}"
  fi

  printf '%s' "$prompt"
  flush_stdin
  answer="$(loudness_read_tty_byte "$timeout")"
  echo
  if [[ -z "$answer" ]]; then
    REPLY="$default"
  else
    REPLY="$answer"
  fi
}

loudness_read_yn_key() {
  local prompt="$1" default="${2:-N}" timeout="${3:-$LOUDNESS_READ_TIMEOUT}"
  local display_prompt answer=""

  if ! loudness_is_interactive; then
    REPLY="$default"
    return 0
  fi

  display_prompt="$(loudness_prompt_add_yn_arrow_hint "$prompt")"
  if [[ "$prompt" != \[* ]]; then
    display_prompt="[$(date '+%Y.%m.%d %H:%M:%S')] ${display_prompt}"
  fi

  printf '%s' "$display_prompt"
  flush_stdin
  answer="$(loudness_read_arrow_yn_byte "$timeout")"
  echo
  if [[ -z "$answer" ]]; then
    REPLY="$default"
  else
    REPLY="$answer"
  fi
}

loudness_window_title_restore() {
  (( LOUDNESS_WINDOW_TITLE_PUSHED == 1 )) || return 0
  if [[ -w /dev/tty ]] 2>/dev/null; then
    printf '\033[23t' >/dev/tty 2>/dev/null || true
  fi
  LOUDNESS_WINDOW_TITLE_PUSHED=0
}

loudness_window_title_apply() {
  local title="" a i script0 max_len=400 cwd_bracket=""
  (( ${#LOUDNESS_ORIGINAL_ARGV[@]} > 0 )) || return 0
  [[ -w /dev/tty ]] 2>/dev/null || return 0

  script0="${LOUDNESS_ORIGINAL_ARGV[0]}"
  if [[ -e "$script0" ]]; then
    if command -v realpath >/dev/null 2>&1; then
      title="$(realpath "$script0" 2>/dev/null)" || title="$script0"
    else
      title="$(cd "$(dirname -- "$script0")" 2>/dev/null && pwd -P)/$(basename -- "$script0")" 2>/dev/null || title="$script0"
    fi
  else
    title="$script0"
  fi
  for (( i = 1; i < ${#LOUDNESS_ORIGINAL_ARGV[@]}; i++ )); do
    a="${LOUDNESS_ORIGINAL_ARGV[$i]}"
    a="${a//$'\r'/}"
    a="${a//$'\n'/ }"
    a="${a//$'\t'/ }"
    title+=" $a"
  done
  cwd_bracket="[ ${LOUDNESS_INVOCATION_CWD} ] "
  title="${cwd_bracket}${title}"
  if (( ${#title} > max_len )); then
    title="${title:0:$(( max_len - 3 ))}..."
  fi
  if [[ -n "${STY:-}" || -n "${TMUX:-}" ]]; then
    printf '\033k%s\033\\' "$title" >/dev/tty 2>/dev/null || true
  fi
  printf '\033[22t' >/dev/tty 2>/dev/null || true
  printf '\033]0;%s\033\\' "$title" >/dev/tty 2>/dev/null || printf '\033]0;%s\a' "$title" >/dev/tty 2>/dev/null || true
  printf '\033]2;%s\033\\' "$title" >/dev/tty 2>/dev/null || printf '\033]2;%s\a' "$title" >/dev/tty 2>/dev/null || true
  LOUDNESS_WINDOW_TITLE_PUSHED=1
}

loudness_print_cli_only_banner() {
  echo
  echo '════════════════════════════════════════════════════════════════════'
  echo '  PRINT-CLI-ONLY — no scan, no normalize, no files will be modified'
  echo '  Answer the prompts; an equivalent command line is built at the end.'
  echo '════════════════════════════════════════════════════════════════════'
  echo
}

loudness_print_cli_only_section() {
  echo
  echo "── ${1} (--print-cli-only: recording answers only, no action) ──"
}

cli_equiv_note() {
  local note="$1"
  (( PRINT_CLI_ONLY )) || return 0
  echo "    → ${note}"
}

cli_record_selected_file() {
  local file="$1"
  CLI_SELECTED_FILES+=( "$file" )
}

cli_setup_print_cli_normalize_queue() {
  local f
  NORMALIZE_FILES=()
  NORMALIZE_MAX=()
  NORMALIZE_STATUS=()
  for f in "${MEDIA_FILES[@]}"; do
    NORMALIZE_FILES+=( "$f" )
    NORMALIZE_MAX+=( '—' )
    NORMALIZE_STATUS+=( '?' )
  done
  sort_normalize_files_queue
}

cli_print_built_command() {
  local -a parts=() script_path f quoted note
  local use_y=0 file_count=0

  script_path="${LOUDNESS_ORIGINAL_ARGV[0]}"
  if [[ -e "$script_path" ]]; then
    if command -v realpath >/dev/null 2>&1; then
      script_path="$(realpath "$script_path" 2>/dev/null)" || true
    fi
  fi
  parts+=( "$script_path" )

  if [[ -n "$NORMALIZE_MODE" && "$NORMALIZE_MODE" != none ]]; then
    parts+=( -n "$NORMALIZE_MODE" )
  fi
  if ! loudness_classes_is_default; then
    parts+=( --classes "$(loudness_classes_cli_spec)" )
  elif (( LOUDNESS_INCLUDE_PERFECT )); then
    parts+=( --include-perfect )
  fi
  (( LOUDNESS_SAVE_ORIGINAL )) && parts+=( --save-original )
  (( LOUDNESS_REPLACE_BACKUP )) && parts+=( --replace-backup )
  if [[ -n "$LOUDNESS_SCAN_SCOPE" && ${#CLI_FILES[@]} == 0 ]]; then
    parts+=( --scope "$LOUDNESS_SCAN_SCOPE" )
  fi
  if [[ -n "$LOUDNESS_BATCH_SIZE" && "$LOUDNESS_BATCH_SIZE" != 50 ]]; then
    parts+=( --batch-size "$LOUDNESS_BATCH_SIZE" )
  fi
  if [[ "$LOUDNESS_USE_COLORS" == no ]]; then
    parts+=( --colors no )
  elif (( LOUDNESS_COLORS_CLI )) && [[ "$LOUDNESS_USE_COLORS" == yes ]]; then
    parts+=( --colors yes )
  fi

  file_count="${#CLI_SELECTED_FILES[@]}"
  if (( file_count > 1 )); then
    mapfile -t CLI_SELECTED_FILES < <(printf '%s\n' "${CLI_SELECTED_FILES[@]}" | LC_ALL=C sort -u)
    file_count="${#CLI_SELECTED_FILES[@]}"
  fi
  if (( file_count == 0 )); then
    :
  elif (( CLI_BUILD_ALL_YES && file_count == ${#NORMALIZE_FILES[@]} )); then
    use_y=1
    parts+=( -y )
  else
    parts+=( -- )
    for f in "${CLI_SELECTED_FILES[@]}"; do
      parts+=( "$f" )
    done
  fi

  echo
  echo '════════════════════════════════════════════════════════════════════'
  echo '  Equivalent command (copy and run without --print-cli-only):'
  echo
  printf '  cd %q && \\\n' "$LOUDNESS_INVOCATION_CWD"
  printf '  '
  for f in "${parts[@]}"; do
    printf '%q ' "$f"
  done
  echo
  echo
  if (( ${#CLI_BUILD_NOTES[@]} > 0 )); then
    echo '  Notes:'
    for note in "${CLI_BUILD_NOTES[@]}"; do
      echo "    - ${note}"
    done
    echo
  fi
  if (( ! LOUDNESS_OFFER_NORMALIZE )); then
    echo '  Scan-only intent: run without -n (or with -n none) after measuring;'
    echo '  this script exits 1 when eligible files remain un-normalized.'
    echo
  fi
  if (( use_y == 0 && file_count > 0 && file_count < ${#NORMALIZE_FILES[@]} )); then
    echo '  Per-file choices are listed as explicit FILE operands (no -y).'
    echo '  [D] rest-of-directory has no single flag — use -y or name files.'
    echo
  elif (( use_y )); then
    echo '  With -n and -y (and other flags shown), the script runs without'
    echo '  startup or per-file prompts when executed from the cd directory above.'
    echo
  fi
  echo '  No files were scanned or modified in this --print-cli-only session.'
  echo '════════════════════════════════════════════════════════════════════'
  echo
}

collect_normalize_choices_cli_only() {
  local rc=0
  NORMALIZE_DIR=""
  echo 'Per-file prompts run in batches (like ffmpeg-voice.sh): ask about each file,'
  echo 'then record selections for the batch before moving on.'
  echo 'Levels were not measured — status shows as ? for every file.'
  normalize_run_batch_prompt_loop 1 || rc=$?
  return "$rc"
}

run_print_cli_only_session() {
  local rc=0

  loudness_print_cli_only_banner

  if (( ${#MEDIA_FILES[@]} == 0 )); then
    echo "No supported audio/video files found under $(pwd) ($(loudness_scan_scope_label))."
    echo "Extensions: ${MEDIA_EXTENSIONS[*]}"
    kod_powrotu=0
    exit 0
  fi

  loudness_print_cli_only_section 'Startup'
  prompt_startup_interactive

  loudness_print_cli_only_section 'Normalize offer'
  prompt_offer_normalize_after_scan

  if (( LOUDNESS_OFFER_NORMALIZE )); then
    loudness_print_cli_only_section 'Normalization classes'
    prompt_normalize_classes
    loudness_rebuild_normalize_queue_from_scan
  fi

  if [[ -z "$NORMALIZE_MODE" ]]; then
    if (( LOUDNESS_OFFER_NORMALIZE )); then
      loudness_print_cli_only_section 'Normalization mode'
      NORMALIZE_FILES=()
      prompt_normalize_mode
    else
      NORMALIZE_MODE=none
      CLI_BUILD_NOTES+=( 'Normalize offer declined — built command is scan-only' )
    fi
  fi

  if [[ "$NORMALIZE_MODE" == none || -z "$NORMALIZE_MODE" ]]; then
    cli_print_built_command
    kod_powrotu=0
    exit 0
  fi

  if [[ "$NORMALIZE_MODE" == youtube ]]; then
    loudness_print_cli_only_section 'YouTube PERFECT files'
    if (( LOUDNESS_CLASS_PERFECT )); then
      LOUDNESS_INCLUDE_PERFECT=1
    elif (( LOUDNESS_INCLUDE_PERFECT_CLI || LOUDNESS_INCLUDE_PERFECT )); then
      LOUDNESS_INCLUDE_PERFECT=1
      LOUDNESS_CLASS_PERFECT=1
      loudness_rebuild_normalize_queue_from_scan
    else
      prompt_youtube_include_perfect_print_cli
      if (( LOUDNESS_INCLUDE_PERFECT )); then
        LOUDNESS_CLASS_PERFECT=1
        loudness_rebuild_normalize_queue_from_scan
      fi
    fi
    if (( LOUDNESS_INCLUDE_PERFECT )) && loudness_classes_is_default; then
      cli_equiv_note 'CLI: --include-perfect'
    fi
  fi

  cli_setup_print_cli_normalize_queue

  if (( ! LOUDNESS_SAVE_ORIGINAL && ! LOUDNESS_SAVE_ORIGINAL_CLI )); then
    loudness_print_cli_only_section 'Backup originals'
    prompt_save_original_aside
  elif (( LOUDNESS_SAVE_ORIGINAL )); then
    cli_equiv_note 'CLI: --save-original'
  fi

  loudness_print_cli_only_section 'Per-file normalize'
  collect_normalize_choices_cli_only || rc=$?
  if (( rc == 2 )); then
    kod_powrotu=130
    exit 130
  fi

  cli_print_built_command
  kod_powrotu=0
  exit 0
}

prompt_youtube_include_perfect_print_cli() {
  echo
  echo "YouTube-style loudnorm targets -16 LUFS. Loudness was not measured in"
  echo "--print-cli-only; you may include files that would scan as PERFECT."
  loudness_read_yn_key 'Include PERFECT-level files in YouTube normalize? [Y/n/q]: ' Y
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    N) LOUDNESS_INCLUDE_PERFECT=0 ;;
    *) LOUDNESS_INCLUDE_PERFECT=1 ;;
  esac
  echo
}

# Collect unique paths (sorted) from cwd or CLI operands.
normalize_loudness_scan_scope() {
  case "${LOUDNESS_SCAN_SCOPE,,}" in
    current|c) LOUDNESS_SCAN_SCOPE=current ;;
    subdirs|s|recursive|tree) LOUDNESS_SCAN_SCOPE=subdirs ;;
    *)
      echo "Invalid LOUDNESS_SCAN_SCOPE / --scope: ${LOUDNESS_SCAN_SCOPE}" >&2
      echo "Use: current or subdirs" >&2
      return 1
      ;;
  esac
}

loudness_scan_scope_label() {
  case "$LOUDNESS_SCAN_SCOPE" in
    subdirs) printf '%s' 'current directory and subdirectories' ;;
    *)       printf '%s' 'current directory only' ;;
  esac
}

prompt_scan_scope() {
  (( PRINT_CLI_ONLY )) && loudness_print_cli_only_section 'Scan scope'
  echo 'What should be scanned?'
  echo '  [S] Also subdirectories (default)'
  echo '  [c] Current directory only'
  echo '  [q] Quit'
  loudness_read_key 'Scan scope? [S/c/q]: ' S
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    C) LOUDNESS_SCAN_SCOPE=current ;;
    *) LOUDNESS_SCAN_SCOPE=subdirs ;;
  esac
  echo "Scope: $(loudness_scan_scope_label)"
  cli_equiv_note "CLI: --scope ${LOUDNESS_SCAN_SCOPE}"
}

collect_media_files_current_dir() {
  local -a found=() f ext
  declare -A seen=()

  for ext in "${MEDIA_EXTENSIONS[@]}"; do
    while IFS= read -r -d '' f; do
      f="${f#./}"
      [[ -f "$f" ]] || continue
      [[ -n "${seen[$f]+x}" ]] && continue
      seen[$f]=1
      found+=( "$f" )
    done < <(find . -maxdepth 1 -type f -iname "*.${ext}" -print0 2>/dev/null)
  done

  printf '%s\n' "${found[@]}"
}

collect_media_files_subdirs() {
  local -a found=() f ext
  declare -A seen=()

  for ext in "${MEDIA_EXTENSIONS[@]}"; do
    while IFS= read -r -d '' f; do
      f="${f#./}"
      [[ -f "$f" ]] || continue
      [[ -n "${seen[$f]+x}" ]] && continue
      seen[$f]=1
      found+=( "$f" )
    done < <(find . -type f -iname "*.${ext}" -print0 2>/dev/null)
  done

  printf '%s\n' "${found[@]}"
}

collect_media_files() {
  local -a found=()
  declare -A seen=()

  if (( ${#CLI_FILES[@]} > 0 )); then
    for f in "${CLI_FILES[@]}"; do
      [[ -e "$f" ]] || { echo "ERROR: file not found: $f" >&2; return 1; }
      [[ -f "$f" ]] || { echo "ERROR: not a regular file: $f" >&2; return 1; }
      if [[ -n "${seen[$f]+x}" ]]; then
        continue
      fi
      seen[$f]=1
      found+=( "$f" )
    done
  elif [[ "$LOUDNESS_SCAN_SCOPE" == subdirs ]]; then
    mapfile -t found < <(collect_media_files_subdirs)
  else
    mapfile -t found < <(collect_media_files_current_dir)
  fi

  if (( ${#found[@]} == 0 )); then
    return 0
  fi

  mapfile -t MEDIA_FILES < <(printf '%s\n' "${found[@]}" | LC_ALL=C sort -u)
}

loudness_media_files_scan_summary() {
  local file ext line count breakdown
  declare -A ext_count=()
  local -a parts=()

  for file in "${MEDIA_FILES[@]}"; do
    ext="${file##*.}"
    ext="${ext,,}"
    ext_count["$ext"]=$(( ${ext_count[$ext]:-0} + 1 ))
  done

  if (( ${#MEDIA_FILES[@]} == 0 )); then
    echo '0'
    return
  fi

  while IFS= read -r line; do
    count="${line%%$'\t'*}"
    ext="${line#*$'\t'}"
    parts+=( "${count} ${ext}" )
  done < <(
    for ext in "${!ext_count[@]}"; do
      printf '%d\t%s\n' "${ext_count[$ext]}" "$ext"
    done | LC_ALL=C sort -t $'\t' -k1,1nr -k2,2
  )

  breakdown=$(IFS=', '; echo "${parts[*]}")
  echo "${#MEDIA_FILES[@]} (${breakdown})"
}

file_has_audio_stream() {
  local file="$1"
  ffprobe -v error -select_streams a:0 -show_entries stream=index -of csv=p=0 -- "$file" 2>/dev/null | grep -q .
}

parse_volumedetect_db() {
  local blob="$1" key="$2"
  awk -v key="$key" '
    index($0, key ":") {
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^-?[0-9]+(\.[0-9]+)?$/ && (i == NF || $(i + 1) == "dB")) {
          print $i
          exit
        }
      }
    }
  ' <<<"$blob"
}

measure_loudness() {
  local file="$1" stderr_blob max_db mean_db rc

  stderr_blob="$(ffmpeg -hide_banner -nostats -i "$file" -af volumedetect -vn -f null /dev/null 2>&1)" || rc=$?
  rc="${rc:-0}"

  max_db="$(parse_volumedetect_db "$stderr_blob" max_volume)"
  mean_db="$(parse_volumedetect_db "$stderr_blob" mean_volume)"

  if [[ -z "$max_db" ]]; then
    if grep -qiE 'does not contain any stream|Stream map .* matches no streams|Output file #0 does not contain any stream' <<<"$stderr_blob"; then
      return 2
    fi
    (( rc != 0 )) && return 3
    return 4
  fi

  printf '%s %s\n' "$max_db" "${mean_db:--}"
  return 0
}

format_db_display_value() {
  local db="$1"
  if [[ "$db" == '—' || "$db" == '-' || -z "$db" ]]; then
    printf '%s' '—'
    return 0
  fi
  db="${db%%[[:space:]]dB*}"
  db="${db//[[:space:]]/}"
  printf '%s dB' "$(loudness_format_db_number "$db")"
}

# One dB value as "0.0" or "-3.2" (no unit). Negative zero → 0.0.
loudness_format_db_number() {
  awk -v v="$1" 'BEGIN {
    v = v + 0
    s = sprintf("%.1f", v)
    if (s == "-0.0") s = "0.0"
    print s
  }'
}

# Loudness from the scan pass (max mean on stdout); else re-measure the file.
get_scan_loudness_for_file() {
  local file="$1" i
  for i in "${!ROW_FILE[@]}"; do
    if [[ "${ROW_FILE[$i]}" == "$file" ]]; then
      printf '%s %s\n' "${ROW_MAX[$i]}" "${ROW_MEAN[$i]}"
      return 0
    fi
  done
  measure_loudness "$file"
}

print_normalize_before_after() {
  local before_max="$1" before_mean="$2" after_max="$3" after_mean="$4"
  printf '    Before: max %10s  mean %10s\n' \
    "$(format_db_display_value "$before_max")" "$(format_db_display_value "$before_mean")"
  printf '    After:  max %10s  mean %10s\n' \
    "$(format_db_display_value "$after_max")" "$(format_db_display_value "$after_mean")"
}

# Wall-clock seconds → "45s", "2m 15s", or "1h 3m 5s".
loudness_format_elapsed() {
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

loudness_ts() {
  date '+%Y.%m.%d %H:%M:%S'
}

loudness_log_kv() {
  local label="$1"
  shift
  printf '[%s] %-*s  %s\n' "$(loudness_ts)" 26 "${label}:" "$*"
}

loudness_summary_kv() {
  local label="$1"
  shift
  printf '%-*s  %s\n' 26 "${label}:" "$*"
}

loudness_record_session_start() {
  [[ -n "$LOUDNESS_SESSION_START_SEC" ]] && return 0
  LOUDNESS_SESSION_START_SEC=$SECONDS
  LOUDNESS_SESSION_START_EPOCH="$(loudness_ts)"
}

loudness_prompt_wait_begin() {
  LOUDNESS_PROMPT_WAIT_MARK=$SECONDS
}

loudness_prompt_wait_end() {
  (( LOUDNESS_PROMPT_WAIT_MARK > 0 )) || return 0
  LOUDNESS_PROMPT_WAIT_SEC=$(( LOUDNESS_PROMPT_WAIT_SEC + SECONDS - LOUDNESS_PROMPT_WAIT_MARK ))
  LOUDNESS_PROMPT_WAIT_MARK=0
}

loudness_stats_record_norm_result() {
  case "$1" in
    0) (( ++LOUDNESS_STATS_NORM_OK )) ;;
    1) (( ++LOUDNESS_STATS_NORM_FAIL )) ;;
    2) (( ++LOUDNESS_STATS_NORM_BACKUP_SKIP )) ;;
    skip) (( ++LOUDNESS_STATS_NORM_SKIP )) ;;
  esac
}

loudness_add_norm_proc_sec() {
  local elapsed="$1"
  (( elapsed > 0 )) || return 0
  LOUDNESS_NORM_PROC_SEC=$(( LOUDNESS_NORM_PROC_SEC + elapsed ))
}

loudness_run_exit_label() {
  if [[ "$LOUDNESS_INTERRUPTED" == yes ]]; then
    printf '%s' 'interrupted (Ctrl-C)'
    return 0
  fi
  if [[ "$LOUDNESS_STOPPED_BY_USER" == yes ]]; then
    printf '%s' 'quit ([Q])'
    return 0
  fi
  case "${kod_powrotu:-0}" in
    0) printf '%s' 'completed' ;;
    130) printf '%s' 'interrupted' ;;
    *) printf '%s' "exit code ${kod_powrotu}" ;;
  esac
}

loudness_print_run_summary_once() {
  local total_sec other_sec scan_line norm_line exit_label
  local count_perfect=0 count_normal=0 count_too_quiet=0 count_no_audio=0 count_error=0 i

  [[ "$LOUDNESS_SUMMARY_DONE" == yes ]] && return 0
  [[ -n "$LOUDNESS_SESSION_START_SEC" ]] || return 0
  (( PRINT_CLI_ONLY )) && return 0
  LOUDNESS_SUMMARY_DONE=yes

  total_sec=$(( SECONDS - LOUDNESS_SESSION_START_SEC ))
  other_sec=$(( total_sec - LOUDNESS_SCAN_PROC_SEC - LOUDNESS_NORM_PROC_SEC - LOUDNESS_PROMPT_WAIT_SEC ))
  (( other_sec < 0 )) && other_sec=0

  for i in "${!ROW_STATUS[@]}"; do
    case "${ROW_STATUS[$i]}" in
      PERFECT)    (( ++count_perfect )) ;;
      NORMAL)     (( ++count_normal )) ;;
      TOO_QUIET)  (( ++count_too_quiet )) ;;
      'NO AUDIO') (( ++count_no_audio )) ;;
      ERROR)      (( ++count_error )) ;;
    esac
  done

  echo
  echo '--- Run summary ---'
  loudness_summary_kv "Working directory" "$(pwd)"
  if (( ${#CLI_FILES[@]} > 0 )); then
    loudness_summary_kv "Input" "${#MEDIA_FILES[@]} explicit file(s)"
  else
    loudness_summary_kv "Scope" "$(loudness_scan_scope_label)"
  fi

  if (( LOUDNESS_SCAN_RAN )); then
    scan_line="${#MEDIA_FILES[@]} file(s) scanned"
    if (( ${#ROW_STATUS[@]} > 0 )); then
      scan_line+=", ${count_perfect} perfect, ${count_normal} normal, ${count_too_quiet} too quiet"
      (( count_no_audio > 0 )) && scan_line+=", ${count_no_audio} no audio"
      (( count_error > 0 )) && scan_line+=", ${count_error} error(s)"
    fi
    loudness_summary_kv "Scan" "$scan_line"
  fi

  if (( LOUDNESS_NORMALIZE_RAN )); then
    loudness_summary_kv "Normalize mode" "${NORMALIZE_MODE:-none}"
    if (( LOUDNESS_SAVE_ORIGINAL )); then
      loudness_summary_kv "Originals backup" '*.backup.deleteme (moved aside)'
    fi
    if (( LOUDNESS_STATS_NORM_BACKUP_SKIP > 0 )); then
      norm_line="${LOUDNESS_STATS_NORM_OK} OK, $(( LOUDNESS_STATS_NORM_SKIP + LOUDNESS_STATS_NORM_BACKUP_SKIP )) skipped (${LOUDNESS_STATS_NORM_BACKUP_SKIP} backup conflict), ${LOUDNESS_STATS_NORM_FAIL} failed"
    else
      norm_line="${LOUDNESS_STATS_NORM_OK} OK, ${LOUDNESS_STATS_NORM_SKIP} skipped, ${LOUDNESS_STATS_NORM_FAIL} failed"
    fi
    loudness_summary_kv "Normalization" "$norm_line"
  elif (( SCAN_ONLY )); then
    loudness_summary_kv "Normalize" 'scan-only (not run)'
  elif (( ! LOUDNESS_OFFER_NORMALIZE )); then
    loudness_summary_kv "Normalize" 'not offered / declined'
  fi

  if (( AUTO_YES )); then
    loudness_summary_kv "Batch prompts" 'auto-yes (-y)'
  elif loudness_wants_per_file_prompts; then
    loudness_summary_kv "Batch prompts" "interactive (batch size ${LOUDNESS_BATCH_SIZE:-50})"
  fi

  echo
  echo '--- Timing ---'
  loudness_summary_kv "Started" "$LOUDNESS_SESSION_START_EPOCH"
  loudness_summary_kv "Finished" "$(loudness_ts)"
  loudness_summary_kv "Total wall time" "$(loudness_format_elapsed "$total_sec")"
  if (( LOUDNESS_SCAN_RAN )); then
    loudness_summary_kv "Scan processing" "$(loudness_format_elapsed "$LOUDNESS_SCAN_PROC_SEC")  (ffmpeg volumedetect)"
  fi
  if (( LOUDNESS_NORMALIZE_RAN )); then
    loudness_summary_kv "Normalize processing" "$(loudness_format_elapsed "$LOUDNESS_NORM_PROC_SEC")  (ffmpeg loudnorm + re-measure)"
  fi
  loudness_summary_kv "Prompt/wait time" "$(loudness_format_elapsed "$LOUDNESS_PROMPT_WAIT_SEC")  (interactive prompts)"
  loudness_summary_kv "Other overhead" "$(loudness_format_elapsed "$other_sec")"
  exit_label="$(loudness_run_exit_label)"
  loudness_summary_kv "Exit" "$exit_label"
  echo
}

# PERFECT | NORMAL | TOO_QUIET based on max_volume peak (dB).
classify_max_volume() {
  local max_db="$1"
  awk -v max="$max_db" 'BEGIN {
    if (max + 0 >= -2.0) {
      print "PERFECT"
      exit 0
    }
    if (max + 0 > -6.0) {
      print "NORMAL"
      exit 0
    }
    print "TOO_QUIET"
  }'
}

# Map one class token to canonical name (normal|too-quiet|perfect); empty = invalid.
loudness_canonicalize_class_token() {
  local t="${1,,}"
  t="${t//[[:space:]]/}"
  t="${t//_/-}"
  case "$t" in
    n|normal|norm) printf 'normal' ;;
    t|q|too-quiet|tooquiet|quiet) printf 'too-quiet' ;;
    p|perfect|perf) printf 'perfect' ;;
    a|all) printf 'all' ;;
    *) return 1 ;;
  esac
}

loudness_enable_class_flag() {
  case "$1" in
    normal) LOUDNESS_CLASS_NORMAL=1 ;;
    too-quiet) LOUDNESS_CLASS_TOO_QUIET=1 ;;
    perfect) LOUDNESS_CLASS_PERFECT=1 ;;
  esac
}

loudness_parse_classes_spec() {
  local spec="$1" token canon c i
  local -a tokens=()

  [[ -n "$spec" ]] || return 1

  spec="${spec,,}"
  spec="${spec//[[:space:]]/}"

  LOUDNESS_CLASS_NORMAL=0
  LOUDNESS_CLASS_TOO_QUIET=0
  LOUDNESS_CLASS_PERFECT=0

  if [[ "$spec" == all || "$spec" == a ]]; then
    LOUDNESS_CLASS_NORMAL=1
    LOUDNESS_CLASS_TOO_QUIET=1
    LOUDNESS_CLASS_PERFECT=1
    return 0
  fi

  if [[ "$spec" == *","* ]]; then
    IFS=',' read -ra tokens <<< "$spec"
    for token in "${tokens[@]}"; do
      [[ -n "$token" ]] || continue
      canon="$(loudness_canonicalize_class_token "$token")" || {
        echo "Invalid class in --classes / LOUDNESS_CLASSES: ${token}" >&2
        echo "Use: n/normal, t or q/too-quiet, p/perfect, a/all (comma-separated or concatenated)." >&2
        return 1
      }
      if [[ "$canon" == all ]]; then
        LOUDNESS_CLASS_NORMAL=1
        LOUDNESS_CLASS_TOO_QUIET=1
        LOUDNESS_CLASS_PERFECT=1
        continue
      fi
      loudness_enable_class_flag "$canon"
    done
  else
    for (( i = 0; i < ${#spec}; ++i )); do
      c="${spec:i:1}"
      [[ "$c" == "," ]] && continue
      canon="$(loudness_canonicalize_class_token "$c")" || {
        echo "Invalid class letter in --classes / LOUDNESS_CLASSES: ${c}" >&2
        echo "Use: n, t or q, p, a (e.g. nt, n,t,p, or normal,too-quiet)." >&2
        return 1
      }
      if [[ "$canon" == all ]]; then
        LOUDNESS_CLASS_NORMAL=1
        LOUDNESS_CLASS_TOO_QUIET=1
        LOUDNESS_CLASS_PERFECT=1
        continue
      fi
      loudness_enable_class_flag "$canon"
    done
  fi

  if (( ! LOUDNESS_CLASS_NORMAL && ! LOUDNESS_CLASS_TOO_QUIET && ! LOUDNESS_CLASS_PERFECT )); then
    echo "ERROR: --classes / LOUDNESS_CLASSES matched no classes: ${spec}" >&2
    return 1
  fi
  return 0
}

loudness_apply_default_classes() {
  LOUDNESS_CLASS_NORMAL=1
  LOUDNESS_CLASS_TOO_QUIET=1
  LOUDNESS_CLASS_PERFECT=0
}

loudness_classes_is_default() {
  (( LOUDNESS_CLASS_NORMAL && LOUDNESS_CLASS_TOO_QUIET && ! LOUDNESS_CLASS_PERFECT ))
}

loudness_resolve_classes_from_cli_or_env() {
  if (( LOUDNESS_CLASSES_RESOLVED )); then
    return 0
  fi
  if [[ -n "$LOUDNESS_CLASSES" ]]; then
    loudness_parse_classes_spec "$LOUDNESS_CLASSES" || return 1
    LOUDNESS_CLASSES_RESOLVED=1
    return 0
  fi
  return 1
}

loudness_finalize_classes() {
  if (( LOUDNESS_CLASSES_RESOLVED )); then
    :
  elif [[ -n "$LOUDNESS_CLASSES" ]]; then
    loudness_parse_classes_spec "$LOUDNESS_CLASSES" || return 1
    LOUDNESS_CLASSES_RESOLVED=1
  else
    loudness_apply_default_classes
    LOUDNESS_CLASSES_RESOLVED=1
  fi
  if (( LOUDNESS_INCLUDE_PERFECT )); then
    LOUDNESS_CLASS_PERFECT=1
  fi
}

loudness_class_status_enabled() {
  case "$1" in
    NORMAL) (( LOUDNESS_CLASS_NORMAL )) ;;
    TOO_QUIET) (( LOUDNESS_CLASS_TOO_QUIET )) ;;
    PERFECT) (( LOUDNESS_CLASS_PERFECT )) ;;
    *) return 1 ;;
  esac
}

loudness_classes_label() {
  local -a parts=()
  (( LOUDNESS_CLASS_NORMAL )) && parts+=( 'NORMAL' )
  (( LOUDNESS_CLASS_TOO_QUIET )) && parts+=( 'TOO QUIET' )
  (( LOUDNESS_CLASS_PERFECT )) && parts+=( 'PERFECT' )
  ((${#parts[@]} == 0)) && { printf 'none'; return; }
  local IFS=', '
  printf '%s' "${parts[*]}"
}

loudness_classes_cli_spec() {
  local -a parts=()
  (( LOUDNESS_CLASS_NORMAL )) && parts+=( n )
  (( LOUDNESS_CLASS_TOO_QUIET )) && parts+=( t )
  (( LOUDNESS_CLASS_PERFECT )) && parts+=( p )
  ((${#parts[@]} == 0)) && return 0
  local IFS=,
  printf '%s' "${parts[*]}"
}

count_scan_status() {
  local want="$1" n=0 i
  for i in "${!ROW_STATUS[@]}"; do
    [[ "${ROW_STATUS[$i]}" == "$want" ]] && (( ++n ))
  done
  printf '%s' "$n"
}

loudness_rebuild_normalize_queue_from_scan() {
  local i file status max_db

  NORMALIZE_FILES=()
  NORMALIZE_MAX=()
  NORMALIZE_STATUS=()

  for i in "${!ROW_FILE[@]}"; do
    status="${ROW_STATUS[$i]}"
    loudness_class_status_enabled "$status" || continue
    file="${ROW_FILE[$i]}"
    max_db="${ROW_MAX[$i]}"
    NORMALIZE_FILES+=( "$file" )
    NORMALIZE_MAX+=( "$max_db" )
    NORMALIZE_STATUS+=( "$status" )
  done
}

loudness_filter_queue_for_standard_mode() {
  local -a keep_files=() keep_max=() keep_status=()
  local i n_skipped=0

  [[ "$NORMALIZE_MODE" == standard ]] || return 0

  for i in "${!NORMALIZE_FILES[@]}"; do
    if [[ "${NORMALIZE_STATUS[$i]}" == PERFECT ]]; then
      (( ++n_skipped ))
      continue
    fi
    keep_files+=( "${NORMALIZE_FILES[$i]}" )
    keep_max+=( "${NORMALIZE_MAX[$i]}" )
    keep_status+=( "${NORMALIZE_STATUS[$i]}" )
  done

  if (( n_skipped > 0 )); then
    echo "NOTE: -n standard skips PERFECT files (${n_skipped} removed from normalize queue)."
  fi

  NORMALIZE_FILES=( "${keep_files[@]}" )
  NORMALIZE_MAX=( "${keep_max[@]}" )
  NORMALIZE_STATUS=( "${keep_status[@]}" )
}

prompt_normalize_classes() {
  local cn ct cp input

  cn="$(count_scan_status NORMAL)"
  ct="$(count_scan_status TOO_QUIET)"
  cp="$(count_scan_perfect_files)"

  echo "Normalization candidates by class: NORMAL ${cn}, TOO QUIET ${ct}, PERFECT ${cp}"
  echo "  Letters: n=normal, t=too quiet, p=perfect (q also means too quiet on CLI)"
  echo "  Default: nt (NORMAL + TOO QUIET)"
  printf '[%s] Classes to include [nt]: ' "$(date '+%Y.%m.%d %H:%M:%S')"
  loudness_prompt_wait_begin
  if IFS= read -r input; then
    :
  else
    input=""
  fi
  loudness_prompt_wait_end
  input="${input%$'\r'}"
  [[ -z "$input" ]] && input=nt
  if ! loudness_parse_classes_spec "$input"; then
    echo 'Using default classes: nt (NORMAL + TOO QUIET).'
    loudness_apply_default_classes
  fi
  LOUDNESS_CLASSES_RESOLVED=1
  LOUDNESS_CLASSES="$(loudness_classes_cli_spec)"
  echo "Selected classes: $(loudness_classes_label)"
  cli_equiv_note "CLI: --classes ${LOUDNESS_CLASSES}"
}

loudness_apply_classes_after_scan() {
  if (( SCAN_ONLY || ! LOUDNESS_OFFER_NORMALIZE )); then
    return 0
  fi

  if loudness_wants_wizard_prompts && (( ! LOUDNESS_CLASSES_CLI )) && (( ! PRINT_CLI_ONLY )); then
    prompt_normalize_classes
  else
    loudness_finalize_classes || exit 1
  fi

  loudness_rebuild_normalize_queue_from_scan
}

loudnorm_filter_for_mode() {
  case "$1" in
    standard) printf '%s' 'loudnorm' ;;
    youtube)  printf '%s' 'loudnorm=I=-16:TP=-1.0:LRA=11' ;;
    *) return 1 ;;
  esac
}

restore_file_timestamps_from_ref() {
  local file="$1" ref="$2"
  [[ -f "$file" && -f "$ref" ]] || return 1
  touch -r "$ref" "$file"
}

# Audio encoder flags for filtered output (cannot use -c:a copy with loudnorm).
normalize_audio_encoder_args() {
  local file="$1" ext="${file##*.}"
  case "${ext,,}" in
    mp3)  printf '%s\n' '-c:a' 'libmp3lame' '-q:a' '2' ;;
    flac) printf '%s\n' '-c:a' 'flac' ;;
    ogg)  printf '%s\n' '-c:a' 'libvorbis' '-q:a' '5' ;;
    opus) printf '%s\n' '-c:a' 'libopus' '-b:a' '128k' ;;
    wav)  printf '%s\n' '-c:a' 'pcm_s16le' ;;
    wma)  printf '%s\n' '-c:a' 'wmav2' ;;
    *)    printf '%s\n' '-c:a' 'aac' '-b:a' '192k' ;;
  esac
}

print_ffmpeg_error_tail() {
  local log="$1" n="${2:-15}"
  [[ -f "$log" && -s "$log" ]] || return 0
  echo '    ffmpeg error (last lines):'
  tail -n "$n" "$log" | sed 's/^/      /'
}

count_file_audio_streams() {
  local file="$1"
  ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 -- "$file" 2>/dev/null | grep -c .
}

loudness_disk_space_df_bin() {
  if [[ "$(type -t df 2>/dev/null)" == function && -x /bin/df ]]; then
    printf '%s\n' /bin/df
  elif [[ -x /bin/df ]]; then
    printf '%s\n' /bin/df
  else
    command -v df 2>/dev/null || return 1
  fi
}

loudness_file_size_bytes() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    printf '0\n'
    return 0
  fi
  stat -c %s -- "$f" 2>/dev/null || stat -f %z -- "$f" 2>/dev/null || printf '0\n'
}

loudness_format_bytes_human() {
  local bytes="$1"
  awk -v b="$bytes" 'BEGIN {
    if (b >= 1073741824)
      printf "%.2f GiB (%.0f bytes)", b/1073741824.0, b
    else if (b >= 1048576)
      printf "%.2f MiB (%.0f bytes)", b/1048576.0, b
    else if (b >= 1024)
      printf "%.2f KiB (%.0f bytes)", b/1024.0, b
    else
      printf "%d bytes", b
  }'
}

loudness_apply_disk_margin_15pct() {
  local bytes="$1"
  printf '%s\n' $((( bytes * 115 + 99 ) / 100))
}

loudness_normalize_file_dir() {
  local file="$1" d
  d="$(dirname -- "$file")"
  if [[ "$d" == . ]]; then
    pwd -P 2>/dev/null || pwd
  elif [[ -d "$d" ]]; then
    (cd "$d" && pwd -P) 2>/dev/null || (cd "$d" && pwd)
  else
    printf '%s\n' "$d"
  fi
}

loudness_disk_avail_bytes() {
  local target_path="$1"
  local df_bin avail_kb
  df_bin="$(loudness_disk_space_df_bin)" || return 1
  avail_kb="$(
    LC_ALL=C "$df_bin" -Pk -- "$target_path" 2>/dev/null \
      | awk 'NR==2 {gsub(/[^0-9]/, "", $4); print $4}'
  )"
  [[ -n "$avail_kb" && "$avail_kb" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' $(( avail_kb * 1024 ))
}

# Estimate peak extra bytes for normalize in one directory (sum/max of queued files there).
loudness_estimate_normalize_dir_bytes() {
  local save_original="$1" sum="$2" max="$3"
  if (( save_original )); then
    printf '%s\n' $(( 2 * sum ))
  else
    printf '%s\n' $(( sum + max ))
  fi
}

# Print per-directory estimates; prompt when required (+15%) exceeds available. Returns 0 proceed, 1 cancel.
loudness_confirm_normalize_disk_space() {
  local -A dir_sum=() dir_max=() dir_count=()
  local file dir sz sum max base need need_margin avail shortfall
  local -a dirs=()
  local n_dirs=0 n_low=0 n_unknown=0 total_sum=0 total_need=0 total_need_margin=0
  local df_note_printed=0

  for file in "${NORMALIZE_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
      echo "WARNING: missing file (skipped in disk-space estimate): ${file}" >&2
      continue
    fi
    dir="$(loudness_normalize_file_dir "$file")"
    sz="$(loudness_file_size_bytes "$file")"
    (( sz >= 0 )) || sz=0
    dir_sum["$dir"]=$(( ${dir_sum[$dir]:-0} + sz ))
    dir_count["$dir"]=$(( ${dir_count[$dir]:-0} + 1 ))
    if (( sz > ${dir_max[$dir]:-0} )); then
      dir_max["$dir"]=$sz
    fi
    total_sum=$(( total_sum + sz ))
  done

  for dir in "${!dir_sum[@]}"; do
    dirs+=("$dir")
  done
  if (( ${#dirs[@]} == 0 )); then
    echo 'WARNING: no readable files in normalize queue — skipping disk-space check.' >&2
    return 0
  fi
  IFS=$'\n' dirs=($(printf '%s\n' "${dirs[@]}" | sort))
  unset IFS
  n_dirs=${#dirs[@]}

  echo
  echo 'Disk space check before normalization (includes 15% safety margin):'
  if (( LOUDNESS_SAVE_ORIGINAL )); then
    echo '  Estimate: ~2× queued file sizes (original *.backup.deleteme + normalized output).'
  else
    echo '  Estimate: queued file sizes + one temp copy of the largest file per directory during ffmpeg.'
  fi

  for dir in "${dirs[@]}"; do
    sum="${dir_sum[$dir]}"
    max="${dir_max[$dir]}"
    base="$(loudness_estimate_normalize_dir_bytes "$LOUDNESS_SAVE_ORIGINAL" "$sum" "$max")"
    need_margin="$(loudness_apply_disk_margin_15pct "$base")"
    total_need=$(( total_need + base ))
    total_need_margin=$(( total_need_margin + need_margin ))

    printf '  Directory: %s\n' "$dir"
    printf '    Files queued: %d (%s total)\n' "${dir_count[$dir]}" "$(loudness_format_bytes_human "$sum")"
    printf '    Estimated need: %s (+15%% margin: %s)\n' \
      "$(loudness_format_bytes_human "$base")" "$(loudness_format_bytes_human "$need_margin")"

    if ! avail="$(loudness_disk_avail_bytes "$dir")"; then
      (( ++n_unknown ))
      echo '    Available:      unknown (could not read free space from df)'
      echo '    Status:         UNKNOWN'
      continue
    fi
    printf '    Available:      %s\n' "$(loudness_format_bytes_human "$avail")"
    if (( avail >= need_margin )); then
      echo '    Status:         OK'
    else
      shortfall=$(( need_margin - avail ))
      (( ++n_low ))
      printf '    Status:         LOW (short by %s)\n' "$(loudness_format_bytes_human "$shortfall")"
    fi
  done

  if (( n_dirs > 1 )); then
    echo '  Overall queued data:'
    printf '    %d file(s), %s — estimated need %s (+15%% margin: %s)\n' \
      "${#NORMALIZE_FILES[@]}" \
      "$(loudness_format_bytes_human "$total_sum")" \
      "$(loudness_format_bytes_human "$total_need")" \
      "$(loudness_format_bytes_human "$total_need_margin")"
  fi

  if (( n_low == 0 && n_unknown == 0 )); then
    echo '  All checked directories have enough free space.'
    return 0
  fi

  if [[ "$(type -t df 2>/dev/null)" == function && df_note_printed -eq 0 ]]; then
    echo '  Note: df is a shell function; using /bin/df for free-space checks.'
    df_note_printed=1
  fi

  if (( n_low > 0 && n_unknown > 0 )); then
    echo
    echo "WARNING: insufficient disk space on ${n_low} director$( (( n_low == 1 )) && printf 'y' || printf 'ies' ); free space unknown for ${n_unknown} director$( (( n_unknown == 1 )) && printf 'y' || printf 'ies' )."
  elif (( n_low > 0 )); then
    echo
    if (( n_low == 1 )); then
      echo 'WARNING: insufficient disk space on 1 directory.'
    else
      echo "WARNING: insufficient disk space on ${n_low} directories."
    fi
  else
    echo
    if (( n_unknown == 1 )); then
      echo 'WARNING: could not determine free disk space for 1 directory.'
    else
      echo "WARNING: could not determine free disk space for ${n_unknown} directories."
    fi
  fi

  if ! loudness_is_interactive; then
    echo 'Non-interactive mode: normalization cancelled (free space not confirmed).' >&2
    return 1
  fi

  loudness_read_yn_key 'Proceed with normalization anyway? [y/N/q]: ' N
  case "${REPLY^^}" in
    Y|YES) return 0 ;;
    Q) loudness_quit_now ;;
    *) return 1 ;;
  esac
}

# Path for original moved aside: <dir>/<basename>.backup.deleteme
backup_deleteme_path() {
  local file="$1" dir base
  dir="$(dirname -- "$file")"
  base="$(basename -- "$file")"
  if [[ "$dir" == . ]]; then
    printf '%s' "${base}.backup.deleteme"
  else
    printf '%s' "${dir}/${base}.backup.deleteme"
  fi
}

# Move original to <path/name>.backup.deleteme in the same directory.
move_original_to_backup() {
  local file="$1" dest
  dest="$(backup_deleteme_path "$file")"
  if [[ -e "$dest" ]]; then
    return 2
  fi
  if mv -- "$file" "$dest"; then
    echo "    Original moved to: ${dest}"
    return 0
  fi
  echo "    ERROR: could not move ${file} to ${dest}" >&2
  return 1
}

file_stat_brief() {
  local f="$1" size mtime
  if [[ ! -e "$f" ]]; then
    printf 'not found'
    return 0
  fi
  size="$(du -h -- "$f" 2>/dev/null | awk '{print $1}')"
  mtime="$(date -r "$f" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || true)"
  if [[ -n "$size" && -n "$mtime" ]]; then
    printf '%s, modified %s' "$size" "$mtime"
  elif [[ -n "$size" ]]; then
    printf '%s' "$size"
  else
    printf 'present'
  fi
}

print_backup_conflict_details() {
  local file="$1" backup="$2"
  echo
  echo "    ┌─ Backup slot busy ─────────────────────────────────────────"
  printf '    │  Target backup:  %s\n' "$backup"
  printf '    │                   (%s)\n' "$(file_stat_brief "$backup")"
  if [[ -f "$file" ]]; then
    printf '    │  File to process: %s\n' "$file"
    printf '    │                   (%s)\n' "$(file_stat_brief "$file")"
    echo '    │  A previous run likely left the backup; the current file may'
    echo '    │  already be a normalized copy you are re-processing.'
  else
    echo "    │  WARNING: ${file} is missing — only the backup file remains."
  fi
  echo '    └────────────────────────────────────────────────────────────'
  echo
}

remove_old_backup_and_move_aside() {
  local file="$1" backup="$2"
  if ! rm -f -- "$backup"; then
    echo "    ERROR: could not remove old backup: ${backup}" >&2
    return 1
  fi
  echo "    Removed old backup: ${backup}"
  if [[ ! -f "$file" ]]; then
    echo "    ERROR: ${file} is missing; cannot create a new backup." >&2
    return 1
  fi
  move_original_to_backup "$file"
}

# Sets result to one of: moved | inplace | skip | quit | fail
resolve_backup_conflict() {
  local file="$1" backup="$2"
  local -n _result=$3
  local policy

  _result=fail
  print_backup_conflict_details "$file" "$backup"

  if (( LOUDNESS_REPLACE_BACKUP_CLI || LOUDNESS_REPLACE_BACKUP )); then
    if remove_old_backup_and_move_aside "$file" "$backup"; then
      _result=moved
    fi
    return 0
  fi

  if ! loudness_wants_wizard_prompts; then
    policy="${LOUDNESS_BACKUP_ON_CONFLICT,,}"
    [[ -z "$policy" ]] && policy=keep
    case "$policy" in
      replace|remove|r)
        if remove_old_backup_and_move_aside "$file" "$backup"; then
          _result=moved
        fi
        ;;
      keep|k|inplace)
        echo '    Keeping existing backup; normalizing in place (current file will be overwritten).'
        _result=inplace
        ;;
      skip|s)
        echo '    Skipped: backup already exists (LOUDNESS_BACKUP_ON_CONFLICT=skip).'
        _result=skip
        ;;
      *)
        echo "    ERROR: backup exists for ${file}; set LOUDNESS_BACKUP_ON_CONFLICT=replace|keep|skip or use --replace-backup" >&2
        _result=fail
        ;;
    esac
    return 0
  fi

  if [[ ! -f "$file" ]]; then
    echo '    Only the backup remains — cannot normalize without the original file.'
    loudness_read_yn_key 'Restore backup to original name and skip normalize? [Y/n/q]: ' Y
    case "${REPLY^^}" in
      Q) _result=quit ; return 0 ;;
      N)
        echo '    Skipped.'
        _result=skip
        return 0
        ;;
      *)
        if mv -- "$backup" "$file"; then
          echo "    Restored ${file} from backup (not normalized)."
          _result=skip
        else
          echo "    ERROR: could not restore ${file} from ${backup}" >&2
          _result=fail
        fi
        return 0
        ;;
    esac
  fi

  echo '  [y] Remove old backup, move current file aside, then normalize'
  echo '      (the previous original in .backup.deleteme will be deleted)'
  echo '  [k] Keep old backup; normalize current file in place'
  echo '      (safe for re-normalizing; backup still holds the first original)'
  echo '  [S] Skip this file (default)'
  echo '  [q] Quit'
  loudness_read_key "Backup conflict for ${file}? [y/k/S/q]: " S
  case "${REPLY^^}" in
    Q) _result=quit ;;
    Y)
      if remove_old_backup_and_move_aside "$file" "$backup"; then
        _result=moved
      fi
      ;;
    K)
      echo '    Keeping existing backup; normalizing in place.'
      _result=inplace
      ;;
    *)
      echo '    Skipped: backup left unchanged.'
      _result=skip
      ;;
  esac
}

# Sets src/backup; returns 0 ready, 2 skip, 3 quit, 1 error.
prepare_normalize_with_backup() {
  local file="$1"
  local -n _src=$2
  local -n _backup=$3
  local conflict_action prep_rc=0

  _backup="$(backup_deleteme_path "$file")"
  _src="$file"

  prep_rc=0
  move_original_to_backup "$file" || prep_rc=$?
  case "$prep_rc" in
    0)
      _src="$_backup"
      return 0
      ;;
    2)
      resolve_backup_conflict "$file" "$_backup" conflict_action
      case "$conflict_action" in
        moved)
          _src="$_backup"
          return 0
          ;;
        inplace)
          _src="$file"
          return 0
          ;;
        skip) return 2 ;;
        quit) return 3 ;;
        *)
          echo "    ERROR: could not resolve backup conflict for ${file}" >&2
          return 1
          ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac
}

restore_original_from_backup() {
  local backup="$1" dest="$2"
  [[ -f "$backup" ]] || return 1
  if mv -- "$backup" "$dest"; then
    echo "    Restored original from backup."
    return 0
  fi
  echo "    Could not restore ${dest} from ${backup}" >&2
  return 1
}

# Temp output beside source: <name>.tmp.<pid>.<ext> so ffmpeg sees a normal extension.
normalize_temp_output_path() {
  local file="$1" pid="$2"
  local dir base stem ext
  dir="$(dirname -- "$file")"
  base="$(basename -- "$file")"
  ext="${base##*.}"
  if [[ "$base" == *.* && "$ext" != "$base" ]]; then
    stem="${base%.*}"
    if [[ "$dir" == . ]]; then
      printf '%s' "${stem}.tmp.${pid}.${ext}"
    else
      printf '%s' "${dir}/${stem}.tmp.${pid}.${ext}"
    fi
  else
    if [[ "$dir" == . ]]; then
      printf '%s' "${base}.tmp.${pid}"
    else
      printf '%s' "${dir}/${base}.tmp.${pid}"
    fi
  fi
}

normalize_file_inplace() {
  local src="$1" dest="$2" filter="$3"
  local tmp ref ffmpeg_rc=0 ts_ref stderr_log
  local -a encoder_args=()

  tmp="$(normalize_temp_output_path "$dest" "$$")"
  ts_ref="$(mktemp)"
  stderr_log="$(mktemp)"
  touch -r "$src" "$ts_ref"
  LOUDNESS_TMP_FILE="$tmp"

  mapfile -t encoder_args < <(normalize_audio_encoder_args "$dest")

  # Map all streams; -filter:a applies loudnorm to every audio track; -c copy keeps
  # video, subtitles, attachments, etc.; -c:a overrides audio to re-encode after filter.
  ffmpeg -hide_banner -nostats -y -i "$src" \
    -map 0 \
    -map_metadata 0 \
    -map_chapters 0 \
    -filter:a "$filter" \
    -c copy \
    "${encoder_args[@]}" \
    -max_muxing_queue_size 9999 \
    -- "$tmp" 2>"$stderr_log" || ffmpeg_rc=$?

  if (( ffmpeg_rc != 0 )) || [[ ! -s "$tmp" ]]; then
    print_ffmpeg_error_tail "$stderr_log"
    rm -f -- "$tmp" "$ts_ref" "$stderr_log"
    LOUDNESS_TMP_FILE=""
    return 1
  fi

  rm -f -- "$stderr_log"

  if ! mv -f -- "$tmp" "$dest"; then
    rm -f -- "$tmp" "$ts_ref"
    LOUDNESS_TMP_FILE=""
    return 1
  fi
  LOUDNESS_TMP_FILE=""

  restore_file_timestamps_from_ref "$dest" "$ts_ref"
  rm -f -- "$ts_ref"
  return 0
}

_table_col_width() {
  local cur="$1" text="$2"
  (( ${#text} > cur )) && printf '%s' "${#text}" || printf '%s' "$cur"
}

# Terminal display width (Unicode-aware via python3 unicodedata.east_asian_width).
LOUDNESS_TABLE_HAVE_PYTHON=-1

_loudness_table_have_python() {
  if (( LOUDNESS_TABLE_HAVE_PYTHON >= 0 )); then
    return "$LOUDNESS_TABLE_HAVE_PYTHON"
  fi
  if command -v python3 >/dev/null 2>&1; then
    LOUDNESS_TABLE_HAVE_PYTHON=0
  else
    LOUDNESS_TABLE_HAVE_PYTHON=1
  fi
  return "$LOUDNESS_TABLE_HAVE_PYTHON"
}

_loudness_table_python() {
  TABLE_FMT_OP="$1" TABLE_FMT_TEXT="${2-}" TABLE_FMT_WIDTH="${3-0}" python3 <<'PY'
import os, sys, unicodedata

def disp_width(s):
    w = 0
    for ch in s:
        w += 2 if unicodedata.east_asian_width(ch) in ('F', 'W') else 1
    return w

def trunc(s, maxw, suffix='…'):
    if disp_width(s) <= maxw:
        return s
    sw = disp_width(suffix)
    limit = maxw - sw
    if limit < 1:
        return suffix if disp_width(suffix) <= maxw else ''
    out, w = [], 0
    for ch in s:
        cw = 2 if unicodedata.east_asian_width(ch) in ('F', 'W') else 1
        if w + cw > limit:
            break
        out.append(ch)
        w += cw
    return ''.join(out) + suffix

def pad_left(s, width):
    s = trunc(s, width) if disp_width(s) > width else s
    sys.stdout.write(s + (' ' * (width - disp_width(s))))

def pad_right(s, width):
    s = trunc(s, width) if disp_width(s) > width else s
    sys.stdout.write((' ' * (width - disp_width(s))) + s)

def pad_center(s, width):
    s = trunc(s, width) if disp_width(s) > width else s
    tw = disp_width(s)
    left = (width - tw) // 2
    right = width - tw - left
    sys.stdout.write((' ' * left) + s + (' ' * right))

op = os.environ['TABLE_FMT_OP']
text = os.environ.get('TABLE_FMT_TEXT', '')
width = int(os.environ.get('TABLE_FMT_WIDTH', '0'))

if op == 'width':
    print(disp_width(text))
elif op == 'pad_left':
    pad_left(text, width)
elif op == 'pad_right':
    pad_right(text, width)
elif op == 'pad_center':
    pad_center(text, width)
else:
    sys.exit(2)
PY
}

_table_disp_width() {
  local w
  if _loudness_table_have_python; then
    w="$(_loudness_table_python width "$1")"
    printf '%s' "$w"
    return 0
  fi
  printf '%s' "${#1}"
}

_table_disp_col_width() {
  local cur="$1" text="$2" w
  w="$(_table_disp_width "$text")"
  (( w > cur )) && printf '%s' "$w" || printf '%s' "$cur"
}

_table_pad_left() {
  local text="$1" width="$2"
  if _loudness_table_have_python; then
    _loudness_table_python pad_left "$text" "$width"
    return 0
  fi
  if (( ${#text} <= width )); then
    printf '%-*s' "$width" "$text"
  else
    printf '%-*s' "$width" "${text:0:$(( width - 3 ))}..."
  fi
}

_table_pad_right() {
  local text="$1" width="$2"
  if _loudness_table_have_python; then
    _loudness_table_python pad_right "$text" "$width"
    return 0
  fi
  printf '%*s' "$width" "$text"
}

_table_pad_center() {
  local text="$1" width="$2" len pad left right
  if _loudness_table_have_python; then
    _loudness_table_python pad_center "$text" "$width"
    return 0
  fi
  len=${#text}
  if (( len > width )); then
    text="${text:0:$(( width - 3 ))}..."
    len=${#text}
  fi
  pad=$(( width - len ))
  left=$(( pad / 2 ))
  right=$(( pad - left ))
  printf '%*s%s%*s' "$left" '' "$text" "$right" ''
}

_table_dash_col() {
  local w="$1"
  printf '%*s' "$w" '' | tr ' ' '-'
}

REPORT_COL_GAP='  '
REPORT_DB_FMT_W=10

print_loudness_class_legend() {
  local label_w=9 range_w=18
  printf '  %-*s  %-*s  — %s\n' "$label_w" 'PERFECT'   "$range_w" ' 0.0 to -2.0 dB'   'do not normalize'
  printf '  %-*s  %-*s  — %s\n' "$label_w" 'NORMAL'    "$range_w" '-2.0 to -6.0 dB'   'usually fine'
  printf '  %-*s  %-*s  — %s\n' "$label_w" 'TOO QUIET' "$range_w" '-6.0 dB or lower' 'loudnorm candidates'
}

declare -a ROW_FILE=() ROW_MAX=() ROW_MEAN=() ROW_STATUS=()
declare -a NORMALIZE_FILES=() NORMALIZE_MAX=() NORMALIZE_STATUS=()

REPORT_FILE_W=4
REPORT_FILE_MAX_W=150
REPORT_MAX_W=10
REPORT_MEAN_W=11
REPORT_STATUS_W=6

init_report_column_widths() {
  local f
  REPORT_FILE_W=4
  REPORT_MAX_W=$REPORT_DB_FMT_W
  REPORT_MEAN_W=$REPORT_DB_FMT_W
  REPORT_STATUS_W=6
  for f in "${MEDIA_FILES[@]}"; do
    REPORT_FILE_W=$(_table_disp_col_width "$REPORT_FILE_W" "$f")
  done
  if (( REPORT_FILE_W > REPORT_FILE_MAX_W )); then
    REPORT_FILE_W=$REPORT_FILE_MAX_W
  fi
  REPORT_MAX_W=$(_table_disp_col_width "$REPORT_MAX_W" 'MAX_VOLUME')
  REPORT_MEAN_W=$(_table_disp_col_width "$REPORT_MEAN_W" 'MEAN_VOLUME')
  REPORT_STATUS_W=$(_table_disp_col_width "$REPORT_STATUS_W" 'TOO_QUIET')
  REPORT_STATUS_W=$(_table_disp_col_width "$REPORT_STATUS_W" 'NO AUDIO')
}

# Left-align filename within the FILE column (truncate with … by display width).
format_scan_file_cell() {
  _table_pad_left "$1" "$2"
}

# Right-align a volumedetect dB value (or em dash) within a fixed column width.
# Uses "%7.1f dB" (always 10 chars) so decimals line up in a column, not the minus sign.
format_scan_db_cell() {
  local value="$1" width="$2" num cell
  if [[ "$value" == '—' || "$value" == '-' || -z "$value" ]]; then
    printf '%*s' "$width" '—'
    return 0
  fi
  num="${value%%[[:space:]]dB*}"
  num="${num//[[:space:]]/}"
  cell="$(awk -v v="$num" 'BEGIN {
    v = v + 0
    s = sprintf("%.1f", v)
    if (s == "-0.0") s = "0.0"
    printf "%s", sprintf("%7.1f dB", s + 0)
  }')"
  if (( ${#cell} > width )); then
    cell="$(awk -v v="$num" 'BEGIN {
      v = v + 0
      s = sprintf("%.1f", v)
      if (s == "-0.0") s = "0.0"
      printf "%s", sprintf("%.1f dB", s + 0)
    }')"
    if (( ${#cell} > width )); then
      cell="${cell: -width}"
    fi
  fi
  printf '%*s' "$width" "$cell"
}

print_report_table_header() {
  local file_h max_h mean_h status_h sep_file sep_max sep_mean sep_status
  file_h="$(_table_pad_center 'FILE' "$REPORT_FILE_W")"
  max_h="$(_table_pad_center 'MAX_VOLUME' "$REPORT_MAX_W")"
  mean_h="$(_table_pad_center 'MEAN_VOLUME' "$REPORT_MEAN_W")"
  status_h="$(_table_pad_center 'STATUS' "$REPORT_STATUS_W")"
  sep_file="$(_table_dash_col "$REPORT_FILE_W")"
  sep_max="$(_table_dash_col "$REPORT_MAX_W")"
  sep_mean="$(_table_dash_col "$REPORT_MEAN_W")"
  sep_status="$(_table_dash_col "$REPORT_STATUS_W")"
  printf '%s%s%s%s%s%s%s\n' \
    "$file_h" "$REPORT_COL_GAP" \
    "$max_h" "$REPORT_COL_GAP" \
    "$mean_h" "$REPORT_COL_GAP" \
    "$status_h"
  printf '%s%s%s%s%s%s%s\n' \
    "$sep_file" "$REPORT_COL_GAP" \
    "$sep_max" "$REPORT_COL_GAP" \
    "$sep_mean" "$REPORT_COL_GAP" \
    "$sep_status"
}

print_report_table_row() {
  local file="$1" max_val="$2" mean_val="$3" status="$4"
  local file_cell max_cell mean_cell

  file_cell="$(format_scan_file_cell "$file" "$REPORT_FILE_W")"
  max_cell="$(format_scan_db_cell "$max_val" "$REPORT_MAX_W")"
  mean_cell="$(format_scan_db_cell "$mean_val" "$REPORT_MEAN_W")"

  if [[ "$status" == PERFECT ]] && loudness_colors_enabled; then
    local status_cell
    status_cell="$(printf '%-*s' "$REPORT_STATUS_W" "$status")"
    printf '%s%s%s%s%s%s%s%s%s%s%s\n' \
      "$GREEN" "$file_cell" "$RESET" "$REPORT_COL_GAP" \
      "$max_cell" "$REPORT_COL_GAP" \
      "$mean_cell" "$REPORT_COL_GAP" \
      "$GREEN" "$status_cell" "$RESET"
    return 0
  fi

  printf '%s%s%s%s%s%s%-*s\n' \
    "$file_cell" "$REPORT_COL_GAP" \
    "$max_cell" "$REPORT_COL_GAP" \
    "$mean_cell" "$REPORT_COL_GAP" \
    "$REPORT_STATUS_W" "$status"
}

append_scan_row() {
  local file="$1" max_val="$2" mean_val="$3" status="$4" max_db="${5:-}"
  ROW_FILE+=( "$file" )
  ROW_MAX+=( "$max_val" )
  ROW_MEAN+=( "$mean_val" )
  ROW_STATUS+=( "$status" )
}

count_scan_perfect_files() {
  local n=0 i
  for i in "${!ROW_STATUS[@]}"; do
    [[ "${ROW_STATUS[$i]}" == PERFECT ]] && (( ++n ))
  done
  printf '%s' "$n"
}

file_in_normalize_queue() {
  local want="$1" i
  for i in "${!NORMALIZE_FILES[@]}"; do
    [[ "${NORMALIZE_FILES[$i]}" == "$want" ]] && return 0
  done
  return 1
}

add_perfect_files_to_normalize_queue() {
  local i file max_db
  for i in "${!ROW_FILE[@]}"; do
    [[ "${ROW_STATUS[$i]}" == PERFECT ]] || continue
    file="${ROW_FILE[$i]}"
    file_in_normalize_queue "$file" && continue
    max_db="${ROW_MAX[$i]}"
    NORMALIZE_FILES+=( "$file" )
    NORMALIZE_MAX+=( "$max_db" )
    NORMALIZE_STATUS+=( 'PERFECT' )
  done
}

# Keep NORMALIZE_FILES / NORMALIZE_MAX / NORMALIZE_STATUS in LC_ALL=C name order.
sort_normalize_files_queue() {
  local -a order=() sorted_files=() sorted_max=() sorted_status=()
  local n=${#NORMALIZE_FILES[@]} i idx sorted_n=0

  (( n < 2 )) && return 0

  mapfile -t order < <(
    for i in "${!NORMALIZE_FILES[@]}"; do
      # Index is the last field so paths that contain tabs cannot break sorting.
      printf '%s\t%s\n' "${NORMALIZE_FILES[$i]}" "$i"
    done | LC_ALL=C sort -t $'\t' -k1,1 | awk -F '\t' 'NF >= 2 { print $NF }'
  )

  if (( ${#order[@]} != n )); then
    echo "WARNING: Could not sort normalize queue (${#order[@]} indices for ${n} files); keeping scan order." >&2
    return 0
  fi

  for idx in "${order[@]}"; do
    idx="${idx//$'\r'/}"
    if [[ ! "$idx" =~ ^[0-9]+$ ]] || (( idx < 0 || idx >= n )); then
      echo "WARNING: Invalid normalize queue sort index '${idx}'; keeping scan order." >&2
      return 0
    fi
    sorted_files+=( "${NORMALIZE_FILES[$idx]}" )
    sorted_max+=( "${NORMALIZE_MAX[$idx]}" )
    sorted_status+=( "${NORMALIZE_STATUS[$idx]}" )
    (( ++sorted_n ))
  done

  if (( sorted_n != n )); then
    echo "WARNING: Normalize queue sort incomplete (${sorted_n}/${n}); keeping scan order." >&2
    return 0
  fi

  NORMALIZE_FILES=( "${sorted_files[@]}" )
  NORMALIZE_MAX=( "${sorted_max[@]}" )
  NORMALIZE_STATUS=( "${sorted_status[@]}" )
}

maybe_include_perfect_for_youtube() {
  [[ "$NORMALIZE_MODE" == youtube ]] || return 0

  if (( LOUDNESS_CLASS_PERFECT )); then
    LOUDNESS_INCLUDE_PERFECT=1
    return 0
  fi

  if (( LOUDNESS_INCLUDE_PERFECT_CLI || LOUDNESS_INCLUDE_PERFECT )); then
    LOUDNESS_CLASS_PERFECT=1
    LOUDNESS_INCLUDE_PERFECT=1
    loudness_rebuild_normalize_queue_from_scan
    return 0
  fi

  if ! loudness_wants_wizard_prompts; then
    return 0
  fi

  prompt_youtube_include_perfect
}

print_scan_summary() {
  local count_perfect=0 count_normal=0 count_too_quiet=0 count_no_audio=0 count_error=0 i

  for i in "${!ROW_STATUS[@]}"; do
    case "${ROW_STATUS[$i]}" in
      PERFECT)    (( ++count_perfect )) ;;
      NORMAL)     (( ++count_normal )) ;;
      TOO_QUIET)  (( ++count_too_quiet )) ;;
      'NO AUDIO') (( ++count_no_audio )) ;;
      ERROR)      (( ++count_error )) ;;
    esac
  done

  echo
  printf 'Summary: %d perfect, %d normal, %d too quiet, %d no audio, %d error(s)\n' \
    "$count_perfect" "$count_normal" "$count_too_quiet" "$count_no_audio" "$count_error"

  if (( count_no_audio > 0 )); then
    echo 'NOTE: NO AUDIO files are listed above but are not candidates for normalization.'
  fi

  if (( count_error > 0 )); then
    return 1
  fi
  if (( count_too_quiet > 0 )); then
    return 2
  fi
  if (( count_normal > 0 )); then
    return 3
  fi
  return 0
}

scan_one_media_file() {
  local file="$1"
  local max_db mean_db status measure_rc measure_line

  if ! file_has_audio_stream "$file"; then
    append_scan_row "$file" '—' '—' 'NO AUDIO'
    print_report_table_row "$file" '—' '—' 'NO AUDIO'
    return 0
  fi

  measure_rc=0
  measure_line="$(measure_loudness "$file")" || measure_rc=$?
  if (( measure_rc != 0 )); then
    if (( measure_rc == 2 )); then
      status='NO AUDIO'
    else
      status='ERROR'
    fi
    append_scan_row "$file" '—' '—' "$status"
    print_report_table_row "$file" '—' '—' "$status"
    return 0
  fi

  read -r max_db mean_db <<<"$measure_line"
  status="$(classify_max_volume "$max_db")"

  append_scan_row "$file" "$max_db" "$mean_db" "$status" "$max_db"
  print_report_table_row "$file" "$max_db" "$mean_db" "$status"
  return 0
}

scan_media_files_with_report() {
  local file scan_start=$SECONDS

  ROW_FILE=()
  ROW_MAX=()
  ROW_MEAN=()
  ROW_STATUS=()
  NORMALIZE_FILES=()
  NORMALIZE_MAX=()
  NORMALIZE_STATUS=()

  init_report_column_widths
  print_report_table_header
  LOUDNESS_SCAN_RAN=1

  for file in "${MEDIA_FILES[@]}"; do
    scan_one_media_file "$file"
  done

  LOUDNESS_SCAN_PROC_SEC=$(( SECONDS - scan_start ))
  print_scan_summary
}

prompt_startup_interactive() {
  echo "Files to scan: $(loudness_media_files_scan_summary)"
  if (( PRINT_CLI_ONLY )); then
    loudness_read_yn_key 'Include loudness scan in the built command? [Y/n/q]: ' Y
  else
    loudness_read_yn_key 'Proceed with loudness scan? [Y/n/q]: ' Y
  fi
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    N)
      if (( PRINT_CLI_ONLY )); then
        echo 'No command built (scan step declined).'
      else
        echo 'Scan skipped.'
      fi
      kod_powrotu=0
      exit 0
      ;;
  esac
}

prompt_offer_normalize_after_scan() {
  local n_normal n_too_quiet n_perfect

  n_normal="$(count_scan_status NORMAL)"
  n_too_quiet="$(count_scan_status TOO_QUIET)"
  n_perfect="$(count_scan_perfect_files)"

  echo
  if (( n_normal + n_too_quiet > 0 )); then
    if (( PRINT_CLI_ONLY )); then
      if (( n_too_quiet > 0 && n_normal > 0 )); then
        loudness_read_yn_key 'If scan finds NORMAL or TOO QUIET files, include loudnorm in the built command? [Y/n/q]: ' Y
      elif (( n_too_quiet > 0 )); then
        loudness_read_yn_key 'If scan finds TOO QUIET files, include loudnorm in the built command? [Y/n/q]: ' Y
      else
        loudness_read_yn_key 'If scan finds NORMAL files, include loudnorm in the built command? [Y/n/q]: ' Y
      fi
    elif (( n_too_quiet > 0 && n_normal > 0 )); then
      loudness_read_yn_key "${n_normal} NORMAL and ${n_too_quiet} TOO QUIET file(s) above — proceed with loudnorm? [Y/n/q]: " Y
    elif (( n_too_quiet > 0 )); then
      loudness_read_yn_key "${n_too_quiet} TOO QUIET file(s) above — proceed with loudnorm? [Y/n/q]: " Y
    else
      loudness_read_yn_key "${n_normal} NORMAL file(s) above — proceed with loudnorm? [Y/n/q]: " Y
    fi
  elif (( n_perfect > 0 )); then
    if (( PRINT_CLI_ONLY )); then
      loudness_read_yn_key 'If all scanned files are PERFECT, still include loudnorm in the built command? [y/N/q]: ' N
    else
      loudness_read_yn_key "All ${n_perfect} scanned file(s) are PERFECT — normalize anyway? [y/N/q]: " N
    fi
  else
    if (( PRINT_CLI_ONLY )); then
      loudness_read_yn_key 'Include loudnorm in the built command when eligible files are found? [Y/n/q]: ' Y
    else
      loudness_read_yn_key 'No NORMAL or TOO QUIET files in the scan — open loudnorm wizard anyway? [Y/n/q]: ' Y
    fi
  fi
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    N) LOUDNESS_OFFER_NORMALIZE=0 ;;
    Y) LOUDNESS_OFFER_NORMALIZE=1 ;;
    *)
      if (( n_normal + n_too_quiet > 0 )); then
        LOUDNESS_OFFER_NORMALIZE=1
      else
        LOUDNESS_OFFER_NORMALIZE=0
      fi
      ;;
  esac
  cli_equiv_note "Offer normalize after scan: $(( LOUDNESS_OFFER_NORMALIZE ))"
}

prompt_normalize_mode() {
  local n="${#NORMALIZE_FILES[@]}" n_perfect n_media="${#MEDIA_FILES[@]}"

  n_perfect="$(count_scan_perfect_files)"
  if (( PRINT_CLI_ONLY )); then
    echo "${n_media} media file(s) in directory (levels not measured in --print-cli-only)."
  elif (( n > 0 )); then
    echo "${n} file(s) queued for normalization ($(loudness_classes_label))."
  elif (( n_perfect > 0 && LOUDNESS_CLASS_PERFECT )); then
    echo "No files in selected classes; ${n_perfect} PERFECT file(s) match class filter."
  elif (( n_perfect > 0 )); then
    echo "No files in selected classes; ${n_perfect} PERFECT file(s) — add p to classes or use YouTube mode."
  else
    echo "No files available for normalization with selected classes."
  fi
  echo "  [s] Standard loudnorm"
  echo "  [Y] YouTube-style loudnorm (I=-16:TP=-1.0:LRA=11) (default)"
  echo "  [n] Skip normalization"
  echo "  [q] Quit"
  loudness_read_key 'Normalize? [s/Y/n/q]: ' Y
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    S) NORMALIZE_MODE=standard ;;
    N) NORMALIZE_MODE=none ;;
    *) NORMALIZE_MODE=youtube ;;
  esac
  if (( PRINT_CLI_ONLY )); then
    if [[ "$NORMALIZE_MODE" == none ]]; then
      cli_equiv_note 'CLI: scan only (omit -n or use -n none)'
    else
      cli_equiv_note "CLI: -n ${NORMALIZE_MODE}"
    fi
  fi
}

prompt_youtube_include_perfect() {
  local n_perfect

  (( LOUDNESS_CLASS_PERFECT )) && return 0

  n_perfect="$(count_scan_perfect_files)"
  (( n_perfect == 0 )) && return 0

  echo "YouTube-style loudnorm targets -16 LUFS. ${n_perfect} file(s) are PERFECT"
  echo "(peak already near maximum; normalization may reduce dynamic range)."
  loudness_read_yn_key 'Include PERFECT files in YouTube normalize? [Y/n/q]: ' Y
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    N) LOUDNESS_INCLUDE_PERFECT=0 ;;
    *)
      LOUDNESS_INCLUDE_PERFECT=1
      LOUDNESS_CLASS_PERFECT=1
      loudness_rebuild_normalize_queue_from_scan
      ;;
  esac
  if (( LOUDNESS_INCLUDE_PERFECT )); then
    cli_equiv_note 'CLI: --include-perfect'
  fi
}

prompt_save_original_aside() {
  echo "Backup pattern: <filename>.backup.deleteme (original is moved, not copied)."
  loudness_read_yn_key 'Move originals aside before normalizing? [Y/n/q]: ' Y
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    N) LOUDNESS_SAVE_ORIGINAL=0 ;;
    *) LOUDNESS_SAVE_ORIGINAL=1 ;;
  esac
  if (( LOUDNESS_SAVE_ORIGINAL )); then
    cli_equiv_note 'CLI: --save-original'
  fi
}

normalize_skip_file_prompt() {
  local file="$1"
  (( AUTO_YES )) && return 0
  [[ -n "$NORMALIZE_DIR" && "$(dirname -- "$file")" == "$NORMALIZE_DIR" ]] && return 0
  return 1
}

batch_prompt_finish_skip_idx() {
  local idx="$1" batch_size_now="$2" batch_count="$3"
  echo $(( idx + batch_size_now - batch_count ))
}

loudness_print_batch_prompt_summary() {
  local batch_pos="$1" batch_size_now="$2" overall_pos="$3" total_files="$4"
  local still_after="$5" batch_yes="$6" batch_no="$7"
  local undecided=$(( batch_size_now - batch_yes - batch_no ))
  local label_w=33 num_w=4

  printf 'PROMPTING: batch file %s/%s (overall %s/%s)\n' \
    "$batch_pos" "$batch_size_now" "$overall_pos" "$total_files"
  printf '%-*s %*s\n' "$label_w" 'LEFT TO ASK AFTER THIS:' "$num_w" "$still_after"
  printf '%-*s %*s\n' "$label_w" 'WILL BE NORMALIZED IN THIS BATCH:' "$num_w" "$batch_yes"
  printf '%-*s %*s\n' "$label_w" 'WILL BE SKIPPED IN THIS BATCH:' "$num_w" "$batch_no"
  printf '%-*s %*s\n' "$label_w" 'ANSWERS STILL MISSING:' "$num_w" "$undecided"
}

loudness_read_normalize_batch_choice() {
  local file="$1" status="$2" max_db="$3"
  local default='N' max_disp prompt

  [[ "$status" == PERFECT ]] || default='Y'
  max_disp="$(format_db_display_value "$max_db")"

  if [[ "$default" == 'Y' ]]; then
    echo '  [Y] Yes normalize (default)'
    echo '  [n] No'
    echo "  [d] Yes, and rest of directory ($(dirname -- "$file")/) without further prompts"
    echo '  [a] Yes for all remaining in this batch'
    echo '  [f] Finish batch now (normalize selected only; stop asking for rest of batch)'
    echo '  [g] Normalize selected; skip all further prompts this run'
    echo '  [q] Quit'
    prompt="Normalize ${file} (${status}, ${max_disp})? [Y/n/d/a/f/g/q]: "
    loudness_read_yn_key "$prompt" Y
  else
    echo '  [y] Yes normalize'
    echo '  [N] No (default)'
    echo "  [d] Yes, and rest of directory ($(dirname -- "$file")/) without further prompts"
    echo '  [a] Yes for all remaining in this batch'
    echo '  [f] Finish batch now (normalize selected only; stop asking for rest of batch)'
    echo '  [g] Normalize selected; skip all further prompts this run'
    echo '  [q] Quit'
    prompt="Normalize ${file} (${status}, ${max_disp})? [y/N/d/a/f/g/q]: "
    loudness_read_yn_key "$prompt" N
  fi

  LOUDNESS_BATCH_CHOICE_DECISION=""
  LOUDNESS_BATCH_CHOICE_ACTION=""
  case "${REPLY^^}" in
    Q) LOUDNESS_BATCH_CHOICE_ACTION=quit ;;
    Y) LOUDNESS_BATCH_CHOICE_DECISION='yes'; LOUDNESS_BATCH_CHOICE_ACTION=decided ;;
    D) LOUDNESS_BATCH_CHOICE_DECISION='yes'; LOUDNESS_BATCH_CHOICE_ACTION=decided_dir ;;
    A) LOUDNESS_BATCH_CHOICE_DECISION='yes'; LOUDNESS_BATCH_CHOICE_ACTION=accept_all ;;
    F) LOUDNESS_BATCH_CHOICE_ACTION=finish_batch ;;
    G) LOUDNESS_BATCH_CHOICE_ACTION=skip_all ;;
    N) LOUDNESS_BATCH_CHOICE_DECISION='no'; LOUDNESS_BATCH_CHOICE_ACTION=decided ;;
    *)
      if [[ "$default" == 'Y' ]]; then
        LOUDNESS_BATCH_CHOICE_DECISION='yes'
      else
        LOUDNESS_BATCH_CHOICE_DECISION='no'
      fi
      LOUDNESS_BATCH_CHOICE_ACTION=decided
      ;;
  esac
}

prompt_batch_size_interactive() {
  local input=""

  echo 'Batch size for per-file normalize prompts?'
  echo '  Default: 50 (ask about N files, then normalize selected before next batch)'
  printf '[%s] Batch size [50]: ' "$(date '+%Y.%m.%d %H:%M:%S')"
  loudness_prompt_wait_begin
  if IFS= read -r -t "$LOUDNESS_READ_TIMEOUT" input; then
    :
  else
    input=""
  fi
  loudness_prompt_wait_end
  if [[ -z "$input" ]]; then
    BATCH_SIZE=50
  elif [[ "$input" =~ ^[1-9][0-9]*$ ]]; then
    BATCH_SIZE="$input"
  else
    echo 'Invalid batch size. Using default: 50'
    BATCH_SIZE=50
  fi
  LOUDNESS_BATCH_SIZE="$BATCH_SIZE"
  echo "Batch size: ${BATCH_SIZE}"
  cli_equiv_note "CLI: --batch-size ${BATCH_SIZE}"
}

resolve_batch_size() {
  if [[ -n "$LOUDNESS_BATCH_SIZE" ]]; then
    case "$LOUDNESS_BATCH_SIZE" in
      *[!0-9]*|'')
        echo "Invalid LOUDNESS_BATCH_SIZE / --batch-size: ${LOUDNESS_BATCH_SIZE}" >&2
        return 1
        ;;
      0*)
        echo "Invalid LOUDNESS_BATCH_SIZE / --batch-size: ${LOUDNESS_BATCH_SIZE}" >&2
        return 1
        ;;
      *)
        BATCH_SIZE="$LOUDNESS_BATCH_SIZE"
        ;;
    esac
    return 0
  fi
  prompt_batch_size_interactive
  return 0
}

normalize_record_cli_batch_selection() {
  local file="$1" decision="$2"

  [[ "$decision" == yes ]] || return 0
  cli_record_selected_file "$file"
}

print_normalize_file_start() {
  local file="$1"
  printf 'Normalizing:\n'
  printf '%s ...\n' "$file"
}

# Returns 0 OK, 1 FAILED, 2 skipped (backup conflict), 3 quit requested.
normalize_one_selected_file() {
  local i="$1" filter="$2"
  local file="${NORMALIZE_FILES[$i]}"
  local before_max before_mean after_max after_mean measure_line measure_rc
  local backup src dest prep_rc audio_n norm_start norm_elapsed

  before_max=""
  before_mean=""
  if measure_line="$(get_scan_loudness_for_file "$file")"; then
    read -r before_max before_mean <<<"$measure_line"
  fi

  audio_n="$(count_file_audio_streams "$file")"
  backup=""
  src="$file"
  dest="$file"
  if (( LOUDNESS_SAVE_ORIGINAL )); then
    prep_rc=0
    prepare_normalize_with_backup "$file" src backup || prep_rc=$?
    case "$prep_rc" in
      0) ;;
      2) return 2 ;;
      3) return 3 ;;
      *)
        echo "    FAILED: backup step for ${file} (see messages above)."
        loudness_stats_record_norm_result 1
        return 1
        ;;
    esac
  fi
  loudness_begin_file_normalize "$dest" "$backup" "$src"
  norm_start=$SECONDS
  print_normalize_file_start "$file"
  if normalize_file_inplace "$src" "$dest" "$filter"; then
    loudness_end_file_normalize
    norm_elapsed=$(( SECONDS - norm_start ))
    printf '%bOK%b (%s)\n' "$GREEN" "$RESET" "$(loudness_format_elapsed "$norm_elapsed")"
    if (( audio_n > 1 )); then
      echo "    (${audio_n} audio tracks normalized; other streams copied)"
    fi
    measure_rc=0
    measure_line="$(measure_loudness "$file")" || measure_rc=$?
    if (( measure_rc == 0 )); then
      read -r after_max after_mean <<<"$measure_line"
      print_normalize_before_after "$before_max" "$before_mean" "$after_max" "$after_mean"
    else
      echo '    After: could not measure loudness'
    fi
    norm_elapsed=$(( SECONDS - norm_start ))
    loudness_add_norm_proc_sec "$norm_elapsed"
    loudness_stats_record_norm_result 0
    echo
    return 0
  fi
  norm_elapsed=$(( SECONDS - norm_start ))
  loudness_add_norm_proc_sec "$norm_elapsed"
  loudness_stats_record_norm_result 1
  echo "FAILED ($(loudness_format_elapsed "$norm_elapsed") — see ffmpeg errors above)"
  if [[ -n "$backup" && -f "$backup" && ! -f "$dest" ]]; then
    restore_original_from_backup "$backup" "$dest" || true
  fi
  loudness_end_file_normalize
  return 1
}

# cli_only=1: record CLI_SELECTED_FILES only; cli_only=0: normalize after each batch.
# Returns 0 ok, 2 quit.
normalize_run_batch_prompt_loop() {
  local cli_only="${1:-0}"
  local filter="${2:-}"
  local -n _norm_ok="${3:-_unused_norm_ok}"
  local -n _norm_fail="${4:-_unused_norm_fail}"
  local -n _norm_skip="${5:-_unused_norm_skip}"
  local -n _norm_backup_skip="${6:-_unused_norm_backup_skip}"

  local total idx remaining_total batch_size_now batch_count batch_yes batch_no
  local accept_all_remaining finish_batch_now skip_remaining='no'
  local overall_pos batch_pos still_after selected_total selected_pos selected_left
  local file max_db status i j rc decision

  if ! resolve_batch_size; then
    echo 'ERROR: Invalid batch size.' >&2
    return 1
  fi

  total=${#NORMALIZE_FILES[@]}
  idx=0

  if (( total == 0 )); then
    echo 'ERROR: Normalize queue is empty — nothing to normalize.' >&2
    return 1
  fi

  echo "Normalize queue: ${total} file(s)."

  while (( idx < total )); do
    [[ "$skip_remaining" == yes ]] && break

    declare -a batch_indices=()
    declare -a batch_selected=()

    remaining_total=$(( total - idx ))
    batch_size_now=$BATCH_SIZE
    (( remaining_total < batch_size_now )) && batch_size_now=$remaining_total

    batch_count=0
    batch_yes=0
    batch_no=0
    accept_all_remaining='no'
    finish_batch_now='no'

    while (( idx < total && batch_count < batch_size_now )); do
      file="${NORMALIZE_FILES[$idx]}"
      max_db="${NORMALIZE_MAX[$idx]}"
      status="${NORMALIZE_STATUS[$idx]}"

      if [[ "$accept_all_remaining" == yes ]] || normalize_skip_file_prompt "$file"; then
        batch_selected+=( 'yes' )
        (( ++batch_yes ))
        batch_indices+=( "$idx" )
        if (( cli_only )); then
          normalize_record_cli_batch_selection "$file" yes
        fi
        (( ++idx ))
        (( ++batch_count ))
        continue
      fi

      overall_pos=$(( idx + 1 ))
      batch_pos=$(( batch_count + 1 ))
      still_after=$(( total - overall_pos ))

      loudness_print_batch_prompt_summary \
        "$batch_pos" "$batch_size_now" "$overall_pos" "$total" "$still_after" \
        "$batch_yes" "$batch_no"
      loudness_read_normalize_batch_choice "$file" "$status" "$max_db"

      case "$LOUDNESS_BATCH_CHOICE_ACTION" in
        quit)
          LOUDNESS_STOPPED_BY_USER=yes
          echo 'Quit requested.'
          return 2
          ;;
        finish_batch)
          finish_batch_now='yes'
          echo "Finishing this batch — normalizing ${batch_yes} selected file(s) only."
          break
          ;;
        skip_all)
          skip_remaining='yes'
          finish_batch_now='yes'
          echo "Skipping all further normalize prompts — normalizing ${batch_yes} selected file(s) from this batch."
          break
          ;;
        accept_all)
          batch_selected+=( 'yes' )
          (( ++batch_yes ))
          accept_all_remaining='yes'
          batch_indices+=( "$idx" )
          if (( cli_only )); then
            normalize_record_cli_batch_selection "$file" yes
          fi
          (( ++idx ))
          (( ++batch_count ))
          continue
          ;;
        decided_dir)
          NORMALIZE_DIR="$(dirname -- "$file")"
          batch_selected+=( 'yes' )
          (( ++batch_yes ))
          if (( cli_only )); then
            CLI_BUILD_NOTES+=( "[D] used in $(dirname -- "$file")/ — no single CLI flag; use -y or list files" )
            normalize_record_cli_batch_selection "$file" yes
          fi
          ;;
        decided)
          if [[ "$LOUDNESS_BATCH_CHOICE_DECISION" == yes ]]; then
            batch_selected+=( 'yes' )
            (( ++batch_yes ))
            if (( cli_only )); then
              normalize_record_cli_batch_selection "$file" yes
            fi
          else
            batch_selected+=( 'no' )
            (( ++batch_no ))
            if (( cli_only )); then
              CLI_BUILD_ALL_YES=0
            fi
          fi
          ;;
      esac

      batch_indices+=( "$idx" )
      (( ++idx ))
      (( ++batch_count ))
    done

    if (( ${#batch_indices[@]} > 0 )); then
      selected_total=0
      for decision in "${batch_selected[@]}"; do
        [[ "$decision" == yes ]] && (( ++selected_total ))
      done

      if (( selected_total > 0 )); then
        if (( ! cli_only )); then
          selected_pos=0
          for j in "${!batch_indices[@]}"; do
            [[ "${batch_selected[$j]}" == yes ]] || continue
            (( ++selected_pos ))
            selected_left=$(( selected_total - selected_pos ))
            echo
            printf '[%s] NORMALIZING: selected file %s/%s in current batch (%s left in batch)\n' \
              "$(date '+%Y.%m.%d %H:%M:%S')" \
              "$selected_pos" "$selected_total" "$selected_left"
            rc=0
            normalize_one_selected_file "${batch_indices[$j]}" "$filter" || rc=$?
            case "$rc" in
              2) (( ++_norm_backup_skip )); loudness_stats_record_norm_result 2 ;;
              3) LOUDNESS_STOPPED_BY_USER=yes; echo 'Quit requested.' ; return 2 ;;
            esac
          done
        fi
      elif (( finish_batch_now )); then
        echo 'No files selected for normalization in this batch.'
      fi
    fi

    if [[ "$finish_batch_now" == yes ]]; then
      idx=$(batch_prompt_finish_skip_idx "$idx" "$batch_size_now" "$batch_count")
    fi

    if (( ! cli_only )); then
      _norm_skip=$(( _norm_skip + batch_no ))
      if [[ "$finish_batch_now" == yes ]]; then
        _norm_skip=$(( _norm_skip + batch_size_now - batch_count ))
      fi
    elif [[ "$finish_batch_now" == yes || "$skip_remaining" == yes ]]; then
      CLI_BUILD_ALL_YES=0
    fi

    if [[ "$skip_remaining" == yes || "$finish_batch_now" == yes ]]; then
      if (( ! cli_only )); then
        _norm_skip=$(( _norm_skip + total - idx ))
      fi
      break
    fi
  done

  return 0
}

normalize_candidate_files() {
  local filter norm_ok=0 norm_fail=0 norm_skip=0 norm_backup_skip=0 rc=0

  LOUDNESS_NORMALIZE_RAN=1
  NORMALIZE_DIR=""

  filter="$(loudnorm_filter_for_mode "$NORMALIZE_MODE")" || {
    echo "ERROR: unknown normalize mode: ${NORMALIZE_MODE}" >&2
    return 1
  }

  echo "Normalization mode: ${NORMALIZE_MODE} (${filter})"
  echo "All audio tracks are loudnorm-filtered; video, subtitles, and other streams are copied."
  if (( LOUDNESS_SAVE_ORIGINAL )); then
    echo "Originals are moved to *.backup.deleteme before each file is normalized."
  fi
  echo "Timestamps on the normalized file are preserved."

  if ! loudness_wants_per_file_prompts; then
    local i file prep_rc
    for i in "${!NORMALIZE_FILES[@]}"; do
      file="${NORMALIZE_FILES[$i]}"
      if ! normalize_skip_file_prompt "$file"; then
        (( ++norm_skip ))
        loudness_stats_record_norm_result skip
        continue
      fi
      rc=0
      normalize_one_selected_file "$i" "$filter" || rc=$?
      case "$rc" in
        2) (( ++norm_backup_skip )); loudness_stats_record_norm_result 2 ;;
        3) LOUDNESS_STOPPED_BY_USER=yes; LOUDNESS_STATS_NORM_SKIP=$norm_skip; echo 'Quit requested.' ; return 2 ;;
      esac
    done
    LOUDNESS_STATS_NORM_SKIP=$norm_skip
  else
    echo 'Per-file prompts run in batches (like ffmpeg-voice.sh): ask about each file,'
    echo 'then normalize selected files before the next batch.'
    echo '  Default: [Y] for NORMAL/TOO QUIET, [N] for PERFECT.'
    echo '  [d] rest of directory, [a] all remaining in batch,'
    echo '  [f] finish batch, [g] skip all further prompts, [q] quit.'
    normalize_run_batch_prompt_loop 0 "$filter" norm_ok norm_fail norm_skip norm_backup_skip || rc=$?
    if (( rc == 2 )); then
      LOUDNESS_STOPPED_BY_USER=yes
      LOUDNESS_STATS_NORM_SKIP=$norm_skip
      return 2
    fi
    if (( rc != 0 )); then
      return 1
    fi
    LOUDNESS_STATS_NORM_SKIP=$norm_skip
  fi

  echo
  if (( LOUDNESS_STATS_NORM_BACKUP_SKIP > 0 )); then
    printf 'Normalization: %d OK, %d skipped (%d backup conflict), %d failed\n' \
      "$LOUDNESS_STATS_NORM_OK" "$(( LOUDNESS_STATS_NORM_SKIP + LOUDNESS_STATS_NORM_BACKUP_SKIP ))" \
      "$LOUDNESS_STATS_NORM_BACKUP_SKIP" "$LOUDNESS_STATS_NORM_FAIL"
  else
    printf 'Normalization: %d OK, %d skipped, %d failed\n' \
      "$LOUDNESS_STATS_NORM_OK" "$LOUDNESS_STATS_NORM_SKIP" "$LOUDNESS_STATS_NORM_FAIL"
  fi
  if (( LOUDNESS_STATS_NORM_FAIL > 0 )); then
    echo 'Check FAILED entries above for ffmpeg errors or backup problems.'
  fi
  (( LOUDNESS_STATS_NORM_FAIL > 0 )) && return 1
  return 0
}

LOUDNESS_OFFER_NORMALIZE=1

if (( SCAN_ONLY )) && { (( LOUDNESS_CLASSES_CLI )) || [[ -n "$LOUDNESS_CLASSES" ]]; }; then
  echo 'NOTE: --scan-only ignores --classes / LOUDNESS_CLASSES (full scan table only).' >&2
fi

if (( LOUDNESS_CLASSES_CLI )) || [[ -n "$LOUDNESS_CLASSES" ]]; then
  loudness_parse_classes_spec "$LOUDNESS_CLASSES" || exit 1
  LOUDNESS_CLASSES_RESOLVED=1
fi
if (( LOUDNESS_INCLUDE_PERFECT )); then
  LOUDNESS_CLASS_PERFECT=1
fi

if (( PRINT_CLI_ONLY )) && ! loudness_is_interactive; then
  echo 'ERROR: --print-cli-only requires an interactive terminal.' >&2
  kod_powrotu=1
  exit 1
fi

loudness_window_title_apply

loudness_resolve_use_colors

if (( ${#CLI_FILES[@]} == 0 )); then
  if loudness_wants_wizard_prompts && (( ! LOUDNESS_SCAN_SCOPE_CLI )); then
    prompt_scan_scope
  fi
  if [[ -z "$LOUDNESS_SCAN_SCOPE" ]]; then
    LOUDNESS_SCAN_SCOPE=current
  fi
  if ! normalize_loudness_scan_scope; then
    kod_powrotu=1
    exit 1
  fi
fi

MEDIA_FILES=()
if ! collect_media_files; then
  kod_powrotu=1
  exit 1
fi

if (( ${#MEDIA_FILES[@]} == 0 )); then
  echo "No supported audio/video files found under $(pwd) ($(loudness_scan_scope_label))."
  echo "Extensions: ${MEDIA_EXTENSIONS[*]}"
  kod_powrotu=0
  exit 0
fi

if loudness_wants_wizard_prompts && (( ! PRINT_CLI_ONLY )); then
  prompt_startup_interactive
fi

if (( ${#CLI_FILES[@]} > 0 )); then
  loudness_record_session_start
  echo "Audio loudness scan: $(pwd) (${#MEDIA_FILES[@]} explicit file(s))"
else
  loudness_record_session_start
  echo "Audio loudness scan: $(pwd) ($(loudness_scan_scope_label))"
fi
echo "Classification (max_volume peak):"
print_loudness_class_legend
echo "Tool: ffmpeg volumedetect (-vn for video files)"

if (( PRINT_CLI_ONLY )); then
  run_print_cli_only_session
fi

if ! loudness_wants_wizard_prompts; then
  echo "Files to scan: $(loudness_media_files_scan_summary)"
fi

scan_rc=0
scan_media_files_with_report || scan_rc=$?

if (( scan_rc == 1 )); then
  echo 'Scan reported error(s); normalization skipped.' >&2
  kod_powrotu=1
  exit 1
fi

if (( SCAN_ONLY )); then
  kod_powrotu=0
  exit 0
fi

if loudness_wants_wizard_prompts; then
  prompt_offer_normalize_after_scan
fi

if (( ! LOUDNESS_OFFER_NORMALIZE )); then
  if (( scan_rc >= 2 )); then
    kod_powrotu=1
    exit 1
  fi
  kod_powrotu=0
  exit 0
fi

loudness_apply_classes_after_scan

if (( ${#NORMALIZE_FILES[@]} == 0 )); then
  kod_powrotu=0
  exit 0
fi

if [[ -z "$NORMALIZE_MODE" ]]; then
  if loudness_wants_wizard_prompts && (( LOUDNESS_OFFER_NORMALIZE )); then
    prompt_normalize_mode
  else
    NORMALIZE_MODE=none
  fi
fi

if [[ "$NORMALIZE_MODE" == none || -z "$NORMALIZE_MODE" ]]; then
  kod_powrotu=1
  exit 1
fi

loudness_filter_queue_for_standard_mode

if (( ${#NORMALIZE_FILES[@]} == 0 )); then
  echo 'No files remain in the normalize queue after applying mode and class filters.'
  kod_powrotu=0
  exit 0
fi

maybe_include_perfect_for_youtube

loudness_filter_queue_for_standard_mode

if (( ${#NORMALIZE_FILES[@]} == 0 )); then
  echo "No files queued for normalization."
  kod_powrotu=0
  exit 0
fi

sort_normalize_files_queue

if (( ${#NORMALIZE_FILES[@]} == 0 )); then
  echo 'ERROR: Normalize queue is empty after sorting — cannot continue.' >&2
  kod_powrotu=1
  exit 1
fi

if (( ! LOUDNESS_SAVE_ORIGINAL && ! LOUDNESS_SAVE_ORIGINAL_CLI )) && loudness_wants_wizard_prompts; then
  prompt_save_original_aside
fi

if ! loudness_confirm_normalize_disk_space; then
  echo 'Normalization cancelled (disk space check).' >&2
  kod_powrotu=1
  exit 1
fi

if normalize_candidate_files; then
  kod_powrotu=0
else
  norm_rc=$?
  if (( norm_rc == 2 )); then
    kod_powrotu=130
  else
    kod_powrotu=1
  fi
fi

exit "${kod_powrotu:-0}"
