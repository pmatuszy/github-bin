#!/bin/bash
# v. 20260724.203756 - avoid startup delay when displaying help or version information
# v. 20260724.203704 - initial network move with uncompressed SSH, source removal, and dry-run support

# 2026.07.24 - v. 0.1 - initial release
#
# move-pgm-rsync.sh
#
# Move files over SSH with rsync, disabling compression and removing transferred source files.
#

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
  - Leaves source directories in place, including directories that become empty.

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

. "$SCRIPT_SUPPORT_DIR/_script_footer.sh"

exit "$return_code"
