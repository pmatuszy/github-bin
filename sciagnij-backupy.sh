#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.06.02 - v. 0.10 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2026.06.01 - v. 0.9 - support glob source paths (e.g. host:/root/config/*): expand on the remote shell so wildcards work like rsync; rename SOURCE/DEST vars to SOURCE/DEST
# 2026.06.01 - v. 0.8 - rewritten to use ssh + scp only (no rsync): ping remote first,
#                       then per-file download, sha512 (or md5) verify, and delete the
#                       remote file (move) ONLY after it is correctly downloaded & verified
# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.07.17 - v. 0.7 - rsync error stream redirecion to stdout
# 2023.07.06 - v. 0.3 - added --no-motd
# 2023.06.25 - v. 0.2 - added optional parameter $3 e.g. --remove-source-files which will be passed to rsync as a parameter
# 2023.03.13 - v. 0.1 - initial release

print_usage() {
  echo
  echo "Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay] <[user@]host:/remote/path> <local_dest_dir> [--remove-source-files|--move]"
  echo
  echo "  Pings the remote host first; if it does not respond, nothing is copied."
  echo "  Downloads each remote file via scp, verifies it with ${HASH_CMD:-sha512sum}, and (only with"
  echo "  --remove-source-files/--move) deletes each remote file AFTER it has been correctly"
  echo "  downloaded and verified."
  echo
  echo "  A trailing slash on the remote path copies its CONTENTS (rsync-style)."
  echo "  Env: SCP_LIMIT_KBIT=<n>      limit scp bandwidth (kbit/s); default unlimited."
  echo "       BACKUP_HASH_CMD=<cmd>   integrity hash command (default sha512sum)."
  echo
  echo "Options:"
  echo "  -h, --help           Show this help and exit."
  echo "  -v, --version        Print script version and exit."
  echo "  --no_startup_delay   Skip random startup delay when run non-interactively."
  echo
}

show_help() {
  print_usage
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    -*) echo "Unknown option: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

if [ -f "$HEALTHCHECKS_FILE" ]; then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" | grep "^$(basename "$0")" | awk '{print $2}')
fi

if [ ! -z "${HEALTHCHECKS_FORCE_ID:-}" ]; then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" | grep "^$HEALTHCHECKS_FORCE_ID" | awk '{print $2}')
fi

if [ -f "$HOME/.keychain/$HOSTNAME-sh" ]; then
  . "$HOME/.keychain/$HOSTNAME-sh"
fi

# Integrity hash command (whole-file checksum compared on both ends).
# Override with BACKUP_HASH_CMD=md5sum (or sha256sum) if you prefer a faster/other hash.
HASH_CMD="${BACKUP_HASH_CMD:-sha512sum}"

check_if_installed curl
check_if_installed ssh openssh-client
check_if_installed scp openssh-client
check_if_installed ping iputils-ping
check_if_installed "$HASH_CMD" coreutils

if (( $# != 2 )) && (( $# != 3 )); then
  echo; echo "(PGM) wrong # of command line arguments... (must be 2 or 3)"; echo
  print_usage
  exit 1
fi

export SOURCE="$1"
export DEST="$2"

MOVE_MODE=0
if (( $# == 3 )); then
  case "$3" in
    --remove-source-files|--move)
      MOVE_MODE=1 ;;
    *)
      echo; echo "(PGM) Unknown 3rd parameter ($3) - only --remove-source-files/--move is supported..."; echo
      echo "(PGM) Unknown 3rd parameter ($3) ..." | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/4 2>/dev/null
      exit 4 ;;
  esac
fi

if [ ! -d "$DEST" ]; then
  echo; echo "(PGM) Directory $DEST doesn't exist..."; echo
  exit 2
fi

case "$SOURCE" in
  *:*) ssh_target="${SOURCE%%:*}"; remote_path="${SOURCE#*:}" ;;
  *)   echo; echo "(PGM) SOURCE must be [user@]host:/remote/path ..."; echo; exit 3 ;;
esac
if [ -z "$ssh_target" ] || [ -z "$remote_path" ]; then
  echo; echo "(PGM) Could not parse remote spec ($SOURCE) ..."; echo
  exit 3
fi

# bare hostname/IP for the reachability ping (strip optional user@)
remote_host="${ssh_target##*@}"

SSH_OPTS=(-T -o Compression=no -o LogLevel=error -o BatchMode=yes)
SCP_OPTS=(-p -o Compression=no -o LogLevel=error -o BatchMode=yes)
if [ -n "${SCP_LIMIT_KBIT:-}" ]; then
  SCP_OPTS+=(-l "$SCP_LIMIT_KBIT")
fi

# single-quote a string for safe use inside a remote shell command
rq() {
  local s=${1//\'/\'\\\'\'}
  printf "'%s'" "$s"
}

# base dir used to compute each file's path relative to the destination (rsync-style)
if [[ "$remote_path" == */ ]]; then
  base="${remote_path%/}"
else
  base="$(dirname -- "$remote_path")"
fi

HC_MESSAGE=$(
  grep -E -m1 '^# *20[123][0-9]' "$0" | awk '{print "script version: " $5 " (dated "$2")"}'
  echo
  echo "current date: $(date '+%Y.%m.%d %H:%M')"
  echo
  echo "SOURCE = $SOURCE"
  echo "DEST   = $DEST"
  echo "hash  = $HASH_CMD"
  if (( MOVE_MODE == 1 )); then
    echo "mode  = MOVE (delete remote file after verified download)"
  else
    echo "mode  = COPY (remote files are kept)"
  fi
  echo

  found=0; transferred=0; deleted=0; failed=0

  # 4) Reachability check: if the remote host does not answer, do not try to copy.
  if ! ping -c 2 -W 5 "$remote_host" >/dev/null 2>&1; then
    echo "ERROR: remote host '$remote_host' is not responding to ping - aborting (nothing copied)"
    echo
    echo "SUMMARY: found=0 transferred=0 deleted=0 failed=1"
    exit 1
  fi
  echo "Remote host '$remote_host' is reachable (ping OK)."
  echo

  tmp_list="$(mktemp)"
  trap 'rm -f -- "$tmp_list"' EXIT

  # Build the remote listing command. If the remote path contains glob
  # metacharacters (* ? [), let the REMOTE shell expand it (rsync-style
  # "/path/*" sources) - "; true" keeps a no-match expansion from looking
  # like a failure. Otherwise quote the path literally so spaces are safe.
  if [[ "$remote_path" == *[*?[]* ]]; then
    remote_list_cmd="for p in ${remote_path}; do [ -e \"\$p\" ] && find \"\$p\" -type f -print0; done; true"
  else
    remote_list_cmd="find $(rq "$remote_path") -type f -print0"
  fi

  if ! ssh "${SSH_OPTS[@]}" "$ssh_target" "$remote_list_cmd" > "$tmp_list" 2>/dev/null; then
    echo "ERROR: remote enumeration failed (ssh/find on $ssh_target:$remote_path)"
    echo
    echo "SUMMARY: found=0 transferred=0 deleted=0 failed=1"
    exit 1
  fi

  mapfile -d '' -t remote_files < "$tmp_list"

  if (( ${#remote_files[@]} == 0 )); then
    echo "Nothing to do: no files found at $ssh_target:$remote_path"
    echo
    echo "SUMMARY: found=0 transferred=0 deleted=0 failed=0"
    exit 0
  fi

  for file in "${remote_files[@]}"; do
    [ -n "$file" ] || continue
    found=$((found + 1))

    relpath="${file#"$base"/}"
    if [ "$relpath" = "$file" ]; then
      relpath="$(basename -- "$file")"
    fi
    local_target="$DEST/$relpath"

    echo ">> $relpath"

    remote_sum="$(ssh "${SSH_OPTS[@]}" "$ssh_target" "$HASH_CMD -- $(rq "$file")" 2>/dev/null | awk '{print $1}')"
    if [ -z "$remote_sum" ]; then
      echo "   ERROR: cannot read remote checksum - skipping (remote kept)"
      failed=$((failed + 1))
      continue
    fi

    if ! mkdir -p -- "$(dirname -- "$local_target")"; then
      echo "   ERROR: cannot create local directory - skipping (remote kept)"
      failed=$((failed + 1))
      continue
    fi

    if ! scp "${SCP_OPTS[@]}" "$ssh_target:$file" "$local_target" >/dev/null 2>&1; then
      echo "   ERROR: scp download failed - skipping (remote kept)"
      rm -f -- "$local_target"
      failed=$((failed + 1))
      continue
    fi

    local_sum="$("$HASH_CMD" -- "$local_target" 2>/dev/null | awk '{print $1}')"
    if [ "$remote_sum" != "$local_sum" ]; then
      echo "   ERROR: checksum mismatch (remote=$remote_sum local=$local_sum) - removing bad copy, remote kept"
      rm -f -- "$local_target"
      failed=$((failed + 1))
      continue
    fi

    transferred=$((transferred + 1))

    if (( MOVE_MODE == 1 )); then
      if ssh "${SSH_OPTS[@]}" "$ssh_target" "rm -f -- $(rq "$file")" 2>/dev/null; then
        echo "   OK: verified + removed remote"
        deleted=$((deleted + 1))
      else
        echo "   OK: verified, but FAILED to remove remote (kept)"
        failed=$((failed + 1))
      fi
    else
      echo "   OK: verified (copy mode, remote kept)"
    fi
  done

  echo
  echo "SUMMARY: found=$found transferred=$transferred deleted=$deleted failed=$failed"
  exit "$failed"
)
return_code=$?

if (( script_is_run_interactively == 1 )); then
  echo "$HC_MESSAGE"
  echo "exit code = $return_code"
fi

# nothing found and nothing failed -> silent (no healthcheck ping), like the old rsync-23 no-op
if echo "$HC_MESSAGE" | grep -Eq "^SUMMARY: found=0 transferred=0 deleted=0 failed=0$"; then
  echo > /dev/null
else
  echo "$HC_MESSAGE" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/$return_code 2>/dev/null
fi

exit "$return_code"
