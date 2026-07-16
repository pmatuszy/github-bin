#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.06.02 - v. 0.2 - add --no_startup_delay option (parsed before header)
# 2026.04.21 - v. 0.1 - root check, sync, levels, help/version, header/footer, free -h, optional trace
# (earlier tree had no changelog for this file)

# Default from environment; a single positional 1|2|3 overrides.
level="${DROP_CACHES_LEVEL:-3}"
trace=0
level_from_arg=0
HEADER_EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat <<'EOF'
Usage: drop-caches.sh [-h|--help] [-v|--version] [--no_startup_delay] [-t|--trace] [LEVEL]

Writes to /proc/sys/vm/drop_caches to free kernel caches. Requires root.
Can hurt performance briefly; use for diagnostics, benchmarking, or reclaiming
RAM after tests — not as routine maintenance.

Options:
  -h, --help     Show this help and exit.
  -v, --version  Print script version and exit.
  --no_startup_delay
                 Skip random startup delay when run non-interactively.
  -t, --trace    Enable bash xtrace around the drop_caches write (or set
                 DROP_CACHES_TRACE=1).

LEVEL (optional, 1–3):
  1  Drop page cache.
  2  Drop dentries and inodes (reclaimable slab).
  3  Drop page cache and slab (default).

Environment:
  DROP_CACHES_LEVEL   Default level if no LEVEL argument (default: 3).
  DROP_CACHES_TRACE   If 1, same as -t/--trace.

The script runs sync(1) before writing drop_caches.

Examples:
  sudo drop-caches.sh
      Level 3, human-readable free -h before/after.

  sudo drop-caches.sh 1
      Only page cache.

  DROP_CACHES_LEVEL=2 sudo -E drop-caches.sh
      Level 2 via environment.

  sudo DROP_CACHES_TRACE=1 drop-caches.sh
      Show the actual echo/redirect with set -x.
EOF
      exit 0
      ;;
    -v|--version)
      _dc_ver=unknown
      _dc_date=
      while IFS= read -r _dc_line; do
        if [[ "$_dc_line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*)\ - ]]; then
          _dc_date="${BASH_REMATCH[1]}"
          _dc_ver="${BASH_REMATCH[2]}"
          break
        fi
      done < "$0"
      if [[ -n "$_dc_date" ]]; then
        printf '%s version %s (%s)\n' "$(basename "$0")" "$_dc_ver" "$_dc_date"
      else
        printf '%s version %s\n' "$(basename "$0")" "$_dc_ver"
      fi
      exit 0
      ;;
    --no_startup_delay)
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    -t|--trace)
      trace=1
      shift
      ;;
    [123])
      if (( level_from_arg )); then
        echo "(PGM) Only one LEVEL (1, 2, or 3) allowed." >&2
        exit 1
      fi
      level=$1
      level_from_arg=1
      shift
      ;;
    *)
      echo "(PGM) Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

if [[ "${DROP_CACHES_TRACE:-0}" == 1 ]]; then
  trace=1
fi

if ! [[ "$level" =~ ^[123]$ ]]; then
  echo "(PGM) Level must be 1, 2, or 3 (got: ${level})." >&2
  exit 1
fi

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

return_code=0

if [ "$(id -u)" -ne 0 ]; then
  echo
  echo "(PGM) This script must run as root (writes /proc/sys/vm/drop_caches)."
  echo
  return_code=1
  . /root/bin/_script_footer.sh
  exit "${return_code}"
fi

echo
echo "(PGM) Memory before:"
free -h
echo

echo "(PGM) Syncing block devices..."
sync

echo "(PGM) Dropping caches (level ${level}: 1=pagecache, 2=dentries/inodes, 3=both)..."
if (( trace )); then
  set -x
fi
echo "$level" > /proc/sys/vm/drop_caches
return_code=$?
if (( trace )); then
  set +x
fi

if (( return_code != 0 )); then
  echo "(PGM) Write to /proc/sys/vm/drop_caches failed."
else
  echo "(PGM) drop_caches completed."
fi

echo
echo "(PGM) Memory after:"
free -h
echo

. /root/bin/_script_footer.sh

exit "${return_code}"
