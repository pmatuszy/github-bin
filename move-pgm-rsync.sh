#!/bin/bash
# v. 20260725.182831 - boxed SUCCESS/FAILURE summary; remove empty source dirs after verified move
# v. 20260724.203756 - avoid startup delay when displaying help or version information
# v. 20260724.203704 - initial network move with uncompressed SSH, source removal, and dry-run support

# 2026.07.25 - v. 0.2 - print boxed result summary; verify source has no files and remove empty dirs
# 2026.07.24 - v. 0.1 - initial release
#
# move-pgm-rsync.sh
#
# Move files over SSH with rsync, disabling compression and removing transferred source files.
#

MOVE_PGM_HAVE_BOXES=no
if type -fP boxes &>/dev/null; then
  MOVE_PGM_HAVE_BOXES=yes
fi

MOVE_PGM_SSH_OPTS=(-o Compression=no -x -o LogLevel=error)

move_pgm_emit_unicode_box() {
  local -a lines=( "$@" )
  local max_len=0 line w

  for line in "${lines[@]}"; do
    (( ${#line} > max_len )) && max_len=${#line}
  done
  (( max_len < 52 )) && max_len=52
  w=$(( max_len + 2 ))

  printf '┌%*s┐\n' "$w" '' | tr ' ' '─'
  for line in "${lines[@]}"; do
    printf '│ %-*s │\n' "$max_len" "$line"
  done
  printf '└%*s┘\n' "$w" '' | tr ' ' '─'
}

move_pgm_emit_boxed_block() {
  local design="$1"
  shift
  local -a lines=( "$@" )

  if [[ "$MOVE_PGM_HAVE_BOXES" == yes ]]; then
    printf '%s\n' "${lines[@]}" | boxes -a c -d "$design"
  else
    move_pgm_emit_unicode_box "${lines[@]}"
  fi
}

# [user@]host:/path is remote; otherwise local (rsync rules).
move_pgm_parse_rsync_spec() {
  local spec="$1"
  MOVE_PGM_SPEC_KIND=local
  MOVE_PGM_SPEC_SSH_TARGET=
  MOVE_PGM_SPEC_PATH="$spec"

  if [[ "$spec" == *:* && "$spec" != /* ]]; then
    MOVE_PGM_SPEC_KIND=remote
    MOVE_PGM_SPEC_SSH_TARGET="${spec%%:*}"
    MOVE_PGM_SPEC_PATH="${spec#*:}"
  fi

  MOVE_PGM_SPEC_PATH="${MOVE_PGM_SPEC_PATH%/}"
}

move_pgm_shell_quote() {
  local s=${1//\'/\'\\\'\'}
  printf "'%s'" "$s"
}

move_pgm_source_is_directory() {
  case "$MOVE_PGM_SPEC_KIND" in
    local)
      [[ -d "$MOVE_PGM_SPEC_PATH" ]]
      ;;
    remote)
      ssh "${MOVE_PGM_SSH_OPTS[@]}" "$MOVE_PGM_SPEC_SSH_TARGET" \
        "test -d $(move_pgm_shell_quote "$MOVE_PGM_SPEC_PATH")"
      ;;
  esac
}

move_pgm_count_source_files() {
  case "$MOVE_PGM_SPEC_KIND" in
    local)
      find "$MOVE_PGM_SPEC_PATH" -type f 2>/dev/null | wc -l | tr -d ' '
      ;;
    remote)
      ssh "${MOVE_PGM_SSH_OPTS[@]}" "$MOVE_PGM_SPEC_SSH_TARGET" \
        "find $(move_pgm_shell_quote "$MOVE_PGM_SPEC_PATH") -type f 2>/dev/null | wc -l" \
        | tr -d ' '
      ;;
  esac
}

move_pgm_remove_empty_source_dirs() {
  case "$MOVE_PGM_SPEC_KIND" in
    local)
      find "$MOVE_PGM_SPEC_PATH" -depth -type d -empty -print -delete 2>/dev/null \
        | wc -l | tr -d ' '
      ;;
    remote)
      ssh "${MOVE_PGM_SSH_OPTS[@]}" "$MOVE_PGM_SPEC_SSH_TARGET" \
        "find $(move_pgm_shell_quote "$MOVE_PGM_SPEC_PATH") -depth -type d -empty -print -delete 2>/dev/null | wc -l" \
        | tr -d ' '
      ;;
  esac
}

# After a successful rsync move, confirm the source tree has no files and remove empty dirs.
# Sets MOVE_PGM_CLEANUP_SUMMARY for the final result box.
move_pgm_cleanup_source_directories() {
  local remaining="" removed=""

  MOVE_PGM_CLEANUP_SUMMARY="Source cleanup: not applicable (source is not a directory)."

  move_pgm_parse_rsync_spec "$SOURCE"
  if ! move_pgm_source_is_directory; then
    return 0
  fi

  if (( DRY_RUN == 1 )); then
    MOVE_PGM_CLEANUP_SUMMARY="Source cleanup: would verify ${SOURCE} has no files and remove empty directories after transfer (dry-run)."
    return 0
  fi

  remaining="$(move_pgm_count_source_files)"
  [[ "$remaining" =~ ^[0-9]+$ ]] || remaining=-1

  if (( remaining < 0 )); then
    MOVE_PGM_CLEANUP_SUMMARY="Source cleanup: could not verify files under ${SOURCE}."
    return 1
  fi

  if (( remaining > 0 )); then
    MOVE_PGM_CLEANUP_SUMMARY="Source cleanup: ${remaining} file(s) still under ${SOURCE} — directories kept."
    return 1
  fi

  removed="$(move_pgm_remove_empty_source_dirs)"
  [[ "$removed" =~ ^[0-9]+$ ]] || removed=0
  MOVE_PGM_CLEANUP_SUMMARY="Source cleanup: no files left; removed ${removed} empty dir(s) under ${SOURCE}."
  return 0
}

move_pgm_print_result() {
  local rsync_rc="$1"
  local exit_rc="$2"
  local -a lines=()
  local design=stone

  echo
  if (( exit_rc == 0 )); then
    lines=(
      "*** RESULT: SUCCESS ***"
      "Return code: ${exit_rc}"
      "Move completed successfully."
    )
    design=ada-box
  elif (( rsync_rc == 0 )); then
    lines=(
      "*** RESULT: FAILURE ***"
      "Return code: ${exit_rc}"
      "Transfer finished (rsync=${rsync_rc}) but source cleanup failed."
    )
    design=stone
  else
    lines=(
      "*** RESULT: FAILURE ***"
      "Return code: ${exit_rc}"
      "Move did not complete successfully (rsync=${rsync_rc})."
    )
    design=stone
  fi

  lines+=("SOURCE: ${SOURCE}")
  lines+=("DESTINATION: ${DESTINATION}")
  if (( DRY_RUN == 1 )); then
    lines+=("Mode: dry-run (no changes made)")
  fi
  if [[ -n "${MOVE_PGM_CLEANUP_SUMMARY:-}" ]]; then
    lines+=("${MOVE_PGM_CLEANUP_SUMMARY}")
  fi

  move_pgm_emit_boxed_block "$design" "${lines[@]}"
  echo
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <SOURCE> <DESTINATION>

Move files between local and remote systems with rsync over SSH. SOURCE and
DESTINATION use normal rsync syntax; one is normally [user@]host:/path.

Options:
  -h, --help             Show this help and exit.
  -v, --version          Print script version and exit.
  -n, --dry-run          Show what would be transferred and removed, but change nothing.
  --bwlimit RATE         Limit bandwidth using rsync RATE syntax (for example 5000 or 10m).
                         By default no bandwidth limit is applied.
  --no_startup_delay     Skip random startup delay when run non-interactively.
  --                     End option parsing.

Transfer behaviour:
  - Uses archive and verbose modes, in-place updates, partial transfers, statistics,
    and progress output.
  - Disables both rsync compression and SSH compression.
  - Disables SSH X11 forwarding.
  - Removes each source file only after rsync transfers it successfully.
  - After a successful move, verifies the source directory tree has no files left
    and removes empty source directories.
  - Prints a boxed SUCCESS or FAILURE summary with the return code.

Examples:
  $(basename "$0") 20260724-Basel_Tattoo \\
    root@lublin.eth.r.matuszyk.com:/root/linki/archiwum/_filmy/2026

  $(basename "$0") --dry-run 20260724-Basel_Tattoo \\
    root@lublin.eth.r.matuszyk.com:/root/linki/archiwum/_filmy/2026

  $(basename "$0") --bwlimit 10m /data/video/ \\
    root@example.com:/archive/video/

Note: rsync trailing-slash rules apply. SOURCE_DIR copies the directory itself;
SOURCE_DIR/ copies only its contents.
EOF
}

HEADER_EXTRA_ARGS=()
CLI_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY) ;;
    -h|--help|-v|--version)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      CLI_ARGS+=("$arg")
      ;;
    *) CLI_ARGS+=("$arg") ;;
  esac
done
set -- "${CLI_ARGS[@]}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -r /root/bin/_script_header.sh ]]; then
  SCRIPT_SUPPORT_DIR=/root/bin
else
  SCRIPT_SUPPORT_DIR="$SCRIPT_DIR"
fi
. "$SCRIPT_SUPPORT_DIR/_script_header.sh" "${HEADER_EXTRA_ARGS[@]}"

DRY_RUN=0
BWLIMIT=
POSITIONAL=()

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
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    --bwlimit)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "Option --bwlimit requires a RATE." >&2
        exit 1
      fi
      BWLIMIT="$2"
      shift 2
      ;;
    --bwlimit=*)
      BWLIMIT="${1#*=}"
      if [[ -z "$BWLIMIT" ]]; then
        echo "Option --bwlimit requires a non-empty RATE." >&2
        exit 1
      fi
      shift
      ;;
    --)
      shift
      POSITIONAL+=("$@")
      break
      ;;
    -*)
      echo "Unknown option: $1 (try --help)" >&2
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if (( ${#POSITIONAL[@]} != 2 )); then
  echo "Exactly one SOURCE and one DESTINATION are required." >&2
  echo "Try: $(basename "$0") --help" >&2
  exit 1
fi

SOURCE="${POSITIONAL[0]}"
DESTINATION="${POSITIONAL[1]}"

check_if_installed rsync
check_if_installed ssh openssh-client

RSYNC_ARGS=(
  -a
  -v
  --inplace
  --no-compress
  --stats
  --progress
  --info=progress1
  --partial
  --remove-source-files
  --no-inc-recursive
  -e "ssh -o Compression=no -x"
)

if [[ -n "$BWLIMIT" ]]; then
  RSYNC_ARGS+=(--bwlimit="$BWLIMIT")
fi

if (( DRY_RUN == 1 )); then
  RSYNC_ARGS+=(--dry-run --itemize-changes)
  echo "DRY RUN: no files will be transferred or removed."
fi

printf 'Running: rsync'
printf ' %q' "${RSYNC_ARGS[@]}" "$SOURCE" "$DESTINATION"
printf '\n\n'

rsync "${RSYNC_ARGS[@]}" "$SOURCE" "$DESTINATION"
return_code=$?

MOVE_PGM_CLEANUP_SUMMARY=""
exit_code=$return_code
if (( return_code == 0 )); then
  move_pgm_cleanup_source_directories || {
    if (( DRY_RUN == 0 )); then
      exit_code=1
    fi
  }
fi

move_pgm_print_result "$return_code" "$exit_code"

return_code=$exit_code
. "$SCRIPT_SUPPORT_DIR/_script_footer.sh"

exit "$exit_code"
