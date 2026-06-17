#!/bin/bash

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
       [-n standard|youtube|none] [-y] [--scope current|subdirs] [--batch-size N]
       [--scan-only] [--print-cli-only] [-- FILE ...]

Scan for audio and video files and measure loudness with ffmpeg volumedetect
(video is ignored for speed). Each file is classified by peak level (max_volume):

  PERFECT (0.0 to -2.0 dB)     Already near digital maximum — do not normalize.
  NORMAL  (-2.0 to -6.0 dB)    Usually fine; normalize only if you want louder mix.
  TOO QUIET (-6.0 dB or lower) Prime candidates for loudnorm (quiet dialogue).

Optionally normalize non-PERFECT files (NORMAL or TOO QUIET) in place (original
modification time kept). PERFECT peaks are never normalization candidates.

Supported extensions (case-insensitive):
  Video: .avi .mp4 .mkv .mov .wmv .mpeg .mpg .m4v .webm .ts
  Audio: .mp3 .flac .wav .m4a .aac .ogg .opus .wma

With FILE operands, only those paths are checked (must exist). Without FILE,
media files are discovered in the working directory — current folder only by
default, or the whole tree with --scope subdirs (interactive default: subdirs).

When no command-line options are given (only optional FILE operands), the script
runs in interactive mode: it asks before scanning and prints each result row as
soon as that file is measured (so a long scan does not look hung).

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
  --include-perfect    With -n youtube, normalize PERFECT files too (skip the
                       interactive question).
  --no_startup_delay   Skip random startup delay when run non-interactively
                       (see _script_header.sh).
  -- FILE              Explicit file operands (use when a name starts with -).

Interactive normalization prompts (per file, in batches like ffmpeg-voice.sh):
  Ask about up to N files (batch size, default 50), then normalize only the
  files you selected in that batch before the next batch of prompts.
  [y] yes, [N] no, [D] rest of directory, [A] yes for all remaining in batch,
  [F] finish batch (normalize selected; stop asking), [G] normalize selected and
  skip all further prompts, [Q] quit.
  Backup conflict: [Y] replace old backup, [K] keep backup and normalize in
  place, [S] skip file, [Q] quit.

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
  LOUDNESS_READ_TIMEOUT     Seconds to wait for a key at interactive prompts
                              (default: 600 = 10 minutes; 0 = wait forever).

Exit status:
  0  Scan OK and (if requested) normalization finished without failures.
  1  Errors, or eligible files remain after a scan-only run (no normalize),
     except with --scan-only (always 0 after a successful scan).

Examples:
  cd /path/to/clips && $(basename "$0")
  cd /path/to/clips && $(basename "$0") --scan-only
  cd /path/to/tree && $(basename "$0") --scan-only --scope subdirs
  $(basename "$0") -n youtube -y --save-original
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
  if [[ "$timeout" =~ ^[0-9]+$ ]] && (( timeout > 0 )); then
    read -t "$timeout" -n 1 answer || answer=""
  else
    read -n 1 answer || answer=""
  fi
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
  (( LOUDNESS_INCLUDE_PERFECT )) && parts+=( --include-perfect )
  (( LOUDNESS_SAVE_ORIGINAL )) && parts+=( --save-original )
  (( LOUDNESS_REPLACE_BACKUP )) && parts+=( --replace-backup )
  if [[ -n "$LOUDNESS_SCAN_SCOPE" && ${#CLI_FILES[@]} == 0 ]]; then
    parts+=( --scope "$LOUDNESS_SCAN_SCOPE" )
  fi
  if [[ -n "$LOUDNESS_BATCH_SIZE" && "$LOUDNESS_BATCH_SIZE" != 50 ]]; then
    parts+=( --batch-size "$LOUDNESS_BATCH_SIZE" )
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
  echo
  echo 'Per-file prompts run in batches (like ffmpeg-voice.sh): ask about each file,'
  echo 'then record selections for the batch before moving on.'
  echo 'Levels were not measured — status shows as ? for every file.'
  echo
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
    if (( LOUDNESS_INCLUDE_PERFECT_CLI || LOUDNESS_INCLUDE_PERFECT )); then
      LOUDNESS_INCLUDE_PERFECT=1
    else
      prompt_youtube_include_perfect_print_cli
    fi
    (( LOUDNESS_INCLUDE_PERFECT )) && cli_equiv_note 'CLI: --include-perfect'
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
  loudness_read_key 'Include PERFECT-level files in YouTube normalize? [Y/n/q]: ' Y
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
  echo
  echo 'What should be scanned?'
  echo '  [S] Also subdirectories (default)'
  echo '  [C] Current directory only'
  echo '  [Q] Quit'
  loudness_read_key 'Scan scope? [S/c/q]: ' S
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    C) LOUDNESS_SCAN_SCOPE=current ;;
    *) LOUDNESS_SCAN_SCOPE=subdirs ;;
  esac
  echo "Scope: $(loudness_scan_scope_label)"
  (( PRINT_CLI_ONLY )) && cli_equiv_note "CLI: --scope ${LOUDNESS_SCAN_SCOPE}"
  echo
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
  awk -v v="$db" 'BEGIN { printf "%.1f dB", v + 0 }'
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
    loudness_read_key 'Restore backup to original name and skip normalize? [Y/n/q]: ' Y
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

  echo '  [Y] Remove old backup, move current file aside, then normalize'
  echo '      (the previous original in .backup.deleteme will be deleted)'
  echo '  [K] Keep old backup; normalize current file in place'
  echo '      (safe for re-normalizing; backup still holds the first original)'
  echo '  [S] Skip this file (default)'
  echo '  [Q] Quit'
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

op = os.environ['TABLE_FMT_OP']
text = os.environ.get('TABLE_FMT_TEXT', '')
width = int(os.environ.get('TABLE_FMT_WIDTH', '0'))

if op == 'width':
    print(disp_width(text))
elif op == 'pad_left':
    pad_left(text, width)
elif op == 'pad_right':
    pad_right(text, width)
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
  cell="$(awk -v v="$num" 'BEGIN { printf "%s", sprintf("%7.1f dB", v + 0) }')"
  if (( ${#cell} > width )); then
    cell="$(awk -v v="$num" 'BEGIN { printf "%s", sprintf("%.1f dB", v + 0) }')"
    if (( ${#cell} > width )); then
      cell="${cell: -width}"
    fi
  fi
  printf '%*s' "$width" "$cell"
}

print_report_table_header() {
  local file_h sep_file sep_max sep_mean sep_status
  file_h="$(format_scan_file_cell 'FILE' "$REPORT_FILE_W")"
  sep_file="$(_table_dash_col "$REPORT_FILE_W")"
  sep_max="$(_table_dash_col "$REPORT_MAX_W")"
  sep_mean="$(_table_dash_col "$REPORT_MEAN_W")"
  sep_status="$(_table_dash_col "$REPORT_STATUS_W")"
  printf '%s%s%*s%s%*s%s%-*s\n' \
    "$file_h" "$REPORT_COL_GAP" \
    "$REPORT_MAX_W" 'MAX_VOLUME' "$REPORT_COL_GAP" \
    "$REPORT_MEAN_W" 'MEAN_VOLUME' "$REPORT_COL_GAP" \
    "$REPORT_STATUS_W" 'STATUS'
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
  if [[ "$status" == NORMAL || "$status" == TOO_QUIET ]]; then
    NORMALIZE_FILES+=( "$file" )
    NORMALIZE_MAX+=( "$max_db" )
    NORMALIZE_STATUS+=( "$status" )
  fi
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
  local i idx

  (( ${#NORMALIZE_FILES[@]} < 2 )) && return 0

  mapfile -t order < <(
    for i in "${!NORMALIZE_FILES[@]}"; do
      printf '%s\t%d\n' "${NORMALIZE_FILES[$i]}" "$i"
    done | LC_ALL=C sort -t $'\t' -k1,1 | cut -f2
  )

  for idx in "${order[@]}"; do
    sorted_files+=( "${NORMALIZE_FILES[$idx]}" )
    sorted_max+=( "${NORMALIZE_MAX[$idx]}" )
    sorted_status+=( "${NORMALIZE_STATUS[$idx]}" )
  done

  NORMALIZE_FILES=( "${sorted_files[@]}" )
  NORMALIZE_MAX=( "${sorted_max[@]}" )
  NORMALIZE_STATUS=( "${sorted_status[@]}" )
}

maybe_include_perfect_for_youtube() {
  [[ "$NORMALIZE_MODE" == youtube ]] || return 0

  if (( LOUDNESS_INCLUDE_PERFECT_CLI || LOUDNESS_INCLUDE_PERFECT )); then
    add_perfect_files_to_normalize_queue
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

  if (( count_error > 0 || count_no_audio > 0 )); then
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
  local file

  ROW_FILE=()
  ROW_MAX=()
  ROW_MEAN=()
  ROW_STATUS=()
  NORMALIZE_FILES=()
  NORMALIZE_MAX=()
  NORMALIZE_STATUS=()

  init_report_column_widths
  print_report_table_header

  for file in "${MEDIA_FILES[@]}"; do
    scan_one_media_file "$file"
  done

  print_scan_summary
}

prompt_startup_interactive() {
  local n="${#MEDIA_FILES[@]}"

  echo "Files to scan: ${n}"
  echo
  if (( PRINT_CLI_ONLY )); then
    loudness_read_key 'Include loudness scan in the built command? [Y/n/q]: ' Y
  else
    loudness_read_key 'Proceed with loudness scan? [Y/n/q]: ' Y
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

  echo
  if (( PRINT_CLI_ONLY )); then
    loudness_read_key 'If non-PERFECT files would be found, offer normalize in real run? [Y/n/q]: ' Y
  else
    loudness_read_key 'If non-PERFECT files are found, offer normalize after scan? [Y/n/q]: ' Y
  fi
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    N) LOUDNESS_OFFER_NORMALIZE=0 ;;
    *) LOUDNESS_OFFER_NORMALIZE=1 ;;
  esac
  (( PRINT_CLI_ONLY )) && cli_equiv_note "Offer normalize after scan: $(( LOUDNESS_OFFER_NORMALIZE ))"
  echo
}

prompt_normalize_mode() {
  local n="${#NORMALIZE_FILES[@]}" n_perfect n_media="${#MEDIA_FILES[@]}"

  n_perfect="$(count_scan_perfect_files)"
  echo
  if (( PRINT_CLI_ONLY )); then
    echo "${n_media} media file(s) in directory (levels not measured in --print-cli-only)."
  elif (( n > 0 )); then
    echo "${n} file(s) can be normalized (NORMAL or TOO QUIET; PERFECT skipped unless YouTube)."
  elif (( n_perfect > 0 )); then
    echo "No NORMAL/TOO QUIET files; ${n_perfect} PERFECT file(s) — YouTube mode can include them."
  else
    echo "No files available for normalization."
  fi
  echo "  [S] Standard loudnorm"
  echo "  [Y] YouTube-style loudnorm (I=-16:TP=-1.0:LRA=11) (default)"
  echo "  [N] Skip normalization"
  echo "  [Q] Quit"
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

  n_perfect="$(count_scan_perfect_files)"
  (( n_perfect == 0 )) && return 0

  echo
  echo "YouTube-style loudnorm targets -16 LUFS. ${n_perfect} file(s) are PERFECT"
  echo "(peak already near maximum; normalization may reduce dynamic range)."
  loudness_read_key 'Include PERFECT files in YouTube normalize? [Y/n/q]: ' Y
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    N) LOUDNESS_INCLUDE_PERFECT=0 ;;
    *)
      LOUDNESS_INCLUDE_PERFECT=1
      add_perfect_files_to_normalize_queue
      ;;
  esac
  (( PRINT_CLI_ONLY )) && (( LOUDNESS_INCLUDE_PERFECT )) && cli_equiv_note 'CLI: --include-perfect'
  echo
}

prompt_save_original_aside() {
  echo
  echo "Backup pattern: <filename>.backup.deleteme (original is moved, not copied)."
  loudness_read_key 'Move originals aside before normalizing? [Y/n/q]: ' Y
  case "${REPLY^^}" in
    Q) loudness_quit_now ;;
    N) LOUDNESS_SAVE_ORIGINAL=0 ;;
    *) LOUDNESS_SAVE_ORIGINAL=1 ;;
  esac
  (( PRINT_CLI_ONLY )) && (( LOUDNESS_SAVE_ORIGINAL )) && cli_equiv_note 'CLI: --save-original'
  echo
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

  echo
  printf 'PROMPTING: batch file %s/%s (overall %s/%s)\n' \
    "$batch_pos" "$batch_size_now" "$overall_pos" "$total_files"
  printf 'LEFT TO ASK AFTER THIS: %s\n' "$still_after"
  printf 'WILL BE NORMALIZED IN THIS BATCH: %s\n' "$batch_yes"
  printf 'WILL BE SKIPPED IN THIS BATCH:   %s\n' "$batch_no"
  printf 'ANSWERS STILL MISSING:           %s\n' "$undecided"
}

loudness_read_normalize_batch_choice() {
  local file="$1" status="$2" max_db="$3"

  echo '  [y] Yes normalize'
  echo '  [N] No (default)'
  echo "  [D] Yes, and rest of directory ($(dirname -- "$file")/) without further prompts"
  echo '  [A] Yes for all remaining in this batch'
  echo '  [F] Finish batch now (normalize selected only; stop asking for rest of batch)'
  echo '  [G] Normalize selected; skip all further prompts this run'
  echo '  [Q] Quit'
  loudness_read_key "Normalize ${file} (${status}, ${max_db} dB)? [y/N/d/a/f/g/q]: " N

  LOUDNESS_BATCH_CHOICE_DECISION=""
  LOUDNESS_BATCH_CHOICE_ACTION=""
  case "${REPLY^^}" in
    Q) LOUDNESS_BATCH_CHOICE_ACTION=quit ;;
    Y) LOUDNESS_BATCH_CHOICE_DECISION=yes; LOUDNESS_BATCH_CHOICE_ACTION=decided ;;
    D) LOUDNESS_BATCH_CHOICE_DECISION=yes; LOUDNESS_BATCH_CHOICE_ACTION=decided_dir ;;
    A) LOUDNESS_BATCH_CHOICE_DECISION=yes; LOUDNESS_BATCH_CHOICE_ACTION=accept_all ;;
    F) LOUDNESS_BATCH_CHOICE_ACTION=finish_batch ;;
    G) LOUDNESS_BATCH_CHOICE_ACTION=skip_all ;;
    N) LOUDNESS_BATCH_CHOICE_DECISION=no; LOUDNESS_BATCH_CHOICE_ACTION=decided ;;
    *) LOUDNESS_BATCH_CHOICE_DECISION=no; LOUDNESS_BATCH_CHOICE_ACTION=decided ;;
  esac
}

prompt_batch_size_interactive() {
  local input=""

  echo
  echo 'Batch size for per-file normalize prompts?'
  echo '  Default: 50 (ask about N files, then normalize selected before next batch)'
  printf '[%s] Batch size [50]: ' "$(date '+%Y.%m.%d %H:%M:%S')"
  if IFS= read -r -t "$LOUDNESS_READ_TIMEOUT" input; then
    :
  else
    input=""
  fi
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
  (( PRINT_CLI_ONLY )) && cli_equiv_note "CLI: --batch-size ${BATCH_SIZE}"
  echo
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
}

normalize_record_cli_batch_selection() {
  local file="$1" decision="$2"

  [[ "$decision" == yes ]] || return 0
  cli_record_selected_file "$file"
}

# Returns 0 OK, 1 FAILED, 2 skipped (backup conflict), 3 quit requested.
normalize_one_selected_file() {
  local i="$1" filter="$2"
  local file="${NORMALIZE_FILES[$i]}"
  local before_max before_mean after_max after_mean measure_line measure_rc
  local backup src dest prep_rc audio_n

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
        return 1
        ;;
    esac
  fi
  loudness_begin_file_normalize "$dest" "$backup" "$src"
  printf 'Normalizing %s ... ' "$file"
  if normalize_file_inplace "$src" "$dest" "$filter"; then
    loudness_end_file_normalize
    echo 'OK'
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
    echo
    return 0
  fi
  echo 'FAILED (ffmpeg — see error lines above)'
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
  local accept_all_remaining finish_batch_now skip_remaining=no
  local overall_pos batch_pos still_after selected_total selected_pos selected_left
  local file max_db status i j rc decision

  if ! resolve_batch_size; then
    return 1
  fi

  total=${#NORMALIZE_FILES[@]}
  idx=0

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
    accept_all_remaining=no
    finish_batch_now=no

    while (( idx < total && batch_count < batch_size_now )); do
      file="${NORMALIZE_FILES[$idx]}"
      max_db="${NORMALIZE_MAX[$idx]}"
      status="${NORMALIZE_STATUS[$idx]}"

      if [[ "$accept_all_remaining" == yes ]] || normalize_skip_file_prompt "$file"; then
        batch_selected+=( yes )
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
          echo 'Quit requested.'
          return 2
          ;;
        finish_batch)
          finish_batch_now=yes
          echo "Finishing this batch — normalizing ${batch_yes} selected file(s) only."
          break
          ;;
        skip_all)
          skip_remaining=yes
          finish_batch_now=yes
          echo "Skipping all further normalize prompts — normalizing ${batch_yes} selected file(s) from this batch."
          break
          ;;
        accept_all)
          batch_selected+=( yes )
          (( ++batch_yes ))
          accept_all_remaining=yes
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
          batch_selected+=( yes )
          (( ++batch_yes ))
          if (( cli_only )); then
            CLI_BUILD_NOTES+=( "[D] used in $(dirname -- "$file")/ — no single CLI flag; use -y or list files" )
            normalize_record_cli_batch_selection "$file" yes
          fi
          ;;
        decided)
          if [[ "$LOUDNESS_BATCH_CHOICE_DECISION" == yes ]]; then
            batch_selected+=( yes )
            (( ++batch_yes ))
            if (( cli_only )); then
              normalize_record_cli_batch_selection "$file" yes
            fi
          else
            batch_selected+=( no )
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
            printf 'NORMALIZING: selected file %s/%s in current batch (%s left in batch)\n' \
              "$selected_pos" "$selected_total" "$selected_left"
            rc=0
            normalize_one_selected_file "${batch_indices[$j]}" "$filter" || rc=$?
            case "$rc" in
              0) (( ++_norm_ok )) ;;
              1) (( ++_norm_fail )) ;;
              2) (( ++_norm_backup_skip )) ;;
              3) echo 'Quit requested.' ; return 2 ;;
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

  NORMALIZE_DIR=""

  filter="$(loudnorm_filter_for_mode "$NORMALIZE_MODE")" || {
    echo "ERROR: unknown normalize mode: ${NORMALIZE_MODE}" >&2
    return 1
  }

  echo
  echo "Normalization mode: ${NORMALIZE_MODE} (${filter})"
  echo "All audio tracks are loudnorm-filtered; video, subtitles, and other streams are copied."
  if (( LOUDNESS_SAVE_ORIGINAL )); then
    echo "Originals are moved to *.backup.deleteme before each file is normalized."
  fi
  echo "Timestamps on the normalized file are preserved."

  if ! loudness_wants_per_file_prompts; then
    echo
    local i file prep_rc
    for i in "${!NORMALIZE_FILES[@]}"; do
      file="${NORMALIZE_FILES[$i]}"
      if ! normalize_skip_file_prompt "$file"; then
        (( ++norm_skip ))
        continue
      fi
      rc=0
      normalize_one_selected_file "$i" "$filter" || rc=$?
      case "$rc" in
        0) (( ++norm_ok )) ;;
        1) (( ++norm_fail )) ;;
        2) (( ++norm_backup_skip )) ;;
        3) echo 'Quit requested.' ; return 2 ;;
      esac
    done
  else
    echo
    echo 'Per-file prompts run in batches (like ffmpeg-voice.sh): ask about each file,'
    echo 'then normalize selected files before the next batch.'
    echo '  [y] yes, [N] no, [D] rest of directory, [A] all remaining in batch,'
    echo '  [F] finish batch, [G] skip all further prompts, [Q] quit.'
    echo
    normalize_run_batch_prompt_loop 0 "$filter" norm_ok norm_fail norm_skip norm_backup_skip || rc=$?
    (( rc == 2 )) && return 2
    (( rc != 0 )) && return 1
  fi

  echo
  if (( norm_backup_skip > 0 )); then
    printf 'Normalization: %d OK, %d skipped (%d backup conflict), %d failed\n' \
      "$norm_ok" "$(( norm_skip + norm_backup_skip ))" "$norm_backup_skip" "$norm_fail"
  else
    printf 'Normalization: %d OK, %d skipped, %d failed\n' "$norm_ok" "$norm_skip" "$norm_fail"
  fi
  if (( norm_fail > 0 )); then
    echo 'Check FAILED entries above for ffmpeg errors or backup problems.'
  fi
  (( norm_fail > 0 )) && return 1
  return 0
}

LOUDNESS_OFFER_NORMALIZE=1

if (( PRINT_CLI_ONLY )) && ! loudness_is_interactive; then
  echo 'ERROR: --print-cli-only requires an interactive terminal.' >&2
  kod_powrotu=1
  exit 1
fi

loudness_window_title_apply

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

if (( ${#CLI_FILES[@]} > 0 )); then
  echo "Audio loudness scan: $(pwd) (${#MEDIA_FILES[@]} explicit file(s))"
else
  echo "Audio loudness scan: $(pwd) ($(loudness_scan_scope_label))"
fi
echo "Classification (max_volume peak):"
print_loudness_class_legend
echo "Tool: ffmpeg volumedetect (-vn for video files)"
echo

if (( ${#MEDIA_FILES[@]} == 0 )); then
  echo "No supported audio/video files found under $(pwd) ($(loudness_scan_scope_label))."
  echo "Extensions: ${MEDIA_EXTENSIONS[*]}"
  kod_powrotu=0
  exit 0
fi

if (( PRINT_CLI_ONLY )); then
  run_print_cli_only_session
fi

if loudness_wants_wizard_prompts; then
  prompt_startup_interactive
else
  echo "Files to scan: ${#MEDIA_FILES[@]}"
  echo
fi

scan_rc=0
scan_media_files_with_report || scan_rc=$?

if (( scan_rc == 1 )); then
  kod_powrotu=1
  exit 1
fi

if (( SCAN_ONLY )); then
  kod_powrotu=0
  exit 0
fi

perfect_scan_count="$(count_scan_perfect_files)"
if (( ${#NORMALIZE_FILES[@]} == 0 && perfect_scan_count == 0 )); then
  kod_powrotu=0
  exit 0
fi

if [[ -z "$NORMALIZE_MODE" ]]; then
  if loudness_wants_wizard_prompts && (( LOUDNESS_OFFER_NORMALIZE )); then
    if (( ${#NORMALIZE_FILES[@]} == 0 && perfect_scan_count == 0 )); then
      kod_powrotu=0
      exit 0
    fi
    prompt_normalize_mode
  else
    NORMALIZE_MODE=none
  fi
fi

if [[ "$NORMALIZE_MODE" == none || -z "$NORMALIZE_MODE" ]]; then
  kod_powrotu=1
  exit 1
fi

maybe_include_perfect_for_youtube

if (( ${#NORMALIZE_FILES[@]} == 0 )); then
  echo "No files queued for normalization."
  kod_powrotu=0
  exit 0
fi

sort_normalize_files_queue

if (( ! LOUDNESS_SAVE_ORIGINAL && ! LOUDNESS_SAVE_ORIGINAL_CLI )) && loudness_wants_wizard_prompts; then
  prompt_save_original_aside
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
