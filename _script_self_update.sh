#!/usr/bin/env bash
# v. 20261020.205000 - seal running script to a temp copy so in-place cp cannot break bash parse
# v. 20261020.202500 - detect live-script overwrite (git pull then copy into bin/) mid-run
# v. 20261020.202200 - detect on-disk script replacement while a run is in progress
#
# 2026.10.20 - v. 1.2.205000 - Copy the live script to a temp file and re-exec from that copy at
#   startup (seal). Bash keeps reading the open inode; an in-place cp into ~/bin overwrites that
#   inode and causes bogus mid-file syntax errors (e.g. near unexpected token `else`). Sealed runs
#   keep executing the snapshot; the live path is still watched for [R]/[C]/[Q].
# 2026.10.20 - v. 1.1.202500 - Fingerprint is the running script path (e.g. ~/bin/rename.sh), not the
#   git checkout. git pull alone does nothing; copying/overwriting that live file (cp/rsync/mv) is what
#   trips the check — in-place overwrite or new inode both work (size/mtime and/or inode change).
# 2026.10.20 - v. 1.0.202200 - Snapshot inode/size/mtime (+ first # v. line). Throttled DEBUG trap
#   notices when the path is replaced. Interactive: [R]estart / [C]ontinue / [Q]uit.
#   Non-interactive: warn once and keep the already-running code. Sourced by _script_header.sh and rename.sh.
#
# Contract: source this file; call script_self_update_setup [live-path].
# Do not execute this file standalone.

if [[ "${BASH_SOURCE[0]-}" == "$0" ]]; then
  echo "do not run _script_self_update.sh standalone — source it from a script" >&2
  exit 1
fi

# watch | ignore (user chose continue) | off
SCRIPT_SELF_UPDATE_STATE="${SCRIPT_SELF_UPDATE_STATE:-off}"
SCRIPT_SELF_UPDATE_PATH="${SCRIPT_SELF_UPDATE_PATH:-}"
SCRIPT_SELF_UPDATE_FP="${SCRIPT_SELF_UPDATE_FP:-}"
SCRIPT_SELF_UPDATE_LAST_CHECK_EPOCH="${SCRIPT_SELF_UPDATE_LAST_CHECK_EPOCH:-0}"
SCRIPT_SELF_UPDATE_INTERVAL_SEC="${SCRIPT_SELF_UPDATE_INTERVAL_SEC:-30}"
SCRIPT_SELF_UPDATE_DEBUG_TRAP_INSTALLED="${SCRIPT_SELF_UPDATE_DEBUG_TRAP_INSTALLED:-0}"
SCRIPT_SELF_UPDATE_IN_CHECK="${SCRIPT_SELF_UPDATE_IN_CHECK:-0}"
SCRIPT_SELF_SEALED="${SCRIPT_SELF_SEALED:-}"
SCRIPT_SELF_SEAL_TMP="${SCRIPT_SELF_SEAL_TMP:-}"
SCRIPT_SELF_LIVE_PATH="${SCRIPT_SELF_LIVE_PATH:-}"
SCRIPT_SELF_SEAL_CLEANUP_REGISTERED="${SCRIPT_SELF_SEAL_CLEANUP_REGISTERED:-0}"

script_self_update_resolve_path() {
  local p="" dir base found i

  p="${1:-}"
  if [[ -z "$p" ]]; then
    p="${SCRIPT_SELF_LIVE_PATH:-}"
  fi
  if [[ -z "$p" ]]; then
    p="${CALLER_SCRIPT:-}"
  fi
  if [[ -z "$p" ]]; then
    for (( i=0; i < ${#BASH_SOURCE[@]}; i++ )); do
      p="${BASH_SOURCE[i]}"
      case "$(basename -- "$p")" in
        _script_self_update.sh|_script_header.sh|_script_footer.sh) continue ;;
        .*.seal.*|*.seal.*) continue ;;
      esac
      [[ -n "$p" ]] && break
    done
  fi
  if [[ -z "$p" ]]; then
    p="${0:-}"
  fi

  if [[ "$p" == */* && -e "$p" ]]; then
    dir="$(cd "$(dirname -- "$p")" && pwd -P)"
    base="$(basename -- "$p")"
    printf '%s/%s' "$dir" "$base"
    return 0
  fi
  if [[ -e "./$p" ]]; then
    dir="$(cd "$(dirname -- "./$p")" && pwd -P)"
    base="$(basename -- "$p")"
    printf '%s/%s' "$dir" "$base"
    return 0
  fi
  found="$(type -P "$p" 2>/dev/null || true)"
  if [[ -n "$found" && -e "$found" ]]; then
    printf '%s' "$found"
    return 0
  fi
  printf '%s' "$p"
}

# device:inode size mtime <TAB> first version header line (best-effort)
script_self_update_fingerprint() {
  local path="$1"
  local st ver=""

  [[ -n "$path" && -e "$path" ]] || return 1
  st="$(stat -c '%d:%i %s %Y' -- "$path" 2>/dev/null)" || return 1
  ver="$(LC_ALL=C grep -m1 -E '^# v\. [0-9]{8}\.[0-9]{6}[[:space:]]*-' -- "$path" 2>/dev/null || true)"
  printf '%s\t%s' "$st" "$ver"
}

script_self_update_cleanup_seal() {
  if [[ -n "${SCRIPT_SELF_SEAL_TMP:-}" && -e "${SCRIPT_SELF_SEAL_TMP}" ]]; then
    rm -f -- "${SCRIPT_SELF_SEAL_TMP}" 2>/dev/null || true
  fi
  SCRIPT_SELF_SEAL_TMP=""
}

# Chain onto EXIT without dropping an existing EXIT trap (best-effort).
script_self_update_register_seal_cleanup() {
  local prev body

  [[ -n "${SCRIPT_SELF_SEAL_TMP:-}" ]] || return 0
  (( SCRIPT_SELF_SEAL_CLEANUP_REGISTERED == 1 )) && return 0
  SCRIPT_SELF_SEAL_CLEANUP_REGISTERED=1

  prev="$(trap -p EXIT 2>/dev/null || true)"
  if [[ -z "$prev" ]]; then
    trap 'script_self_update_cleanup_seal' EXIT
    return 0
  fi
  # prev looks like: trap -- 'commands' EXIT
  if [[ "$prev" =~ ^trap\ --\ \'(.*)\'\ EXIT$ ]]; then
    body="${BASH_REMATCH[1]}"
    # shellcheck disable=SC2064
    trap "script_self_update_cleanup_seal; ${body}" EXIT
  else
    trap 'script_self_update_cleanup_seal' EXIT
  fi
}

script_self_update_init() {
  local path fp

  path="$(script_self_update_resolve_path "${1:-}")"
  if [[ -z "$path" || ! -e "$path" ]]; then
    SCRIPT_SELF_UPDATE_STATE=off
    SCRIPT_SELF_UPDATE_PATH=""
    SCRIPT_SELF_UPDATE_FP=""
    return 0
  fi

  fp="$(script_self_update_fingerprint "$path" || true)"
  if [[ -z "$fp" ]]; then
    SCRIPT_SELF_UPDATE_STATE=off
    SCRIPT_SELF_UPDATE_PATH=""
    SCRIPT_SELF_UPDATE_FP=""
    return 0
  fi

  SCRIPT_SELF_UPDATE_PATH="$path"
  SCRIPT_SELF_LIVE_PATH="$path"
  export SCRIPT_SELF_LIVE_PATH
  SCRIPT_SELF_UPDATE_FP="$fp"
  SCRIPT_SELF_UPDATE_STATE=watch
  SCRIPT_SELF_UPDATE_LAST_CHECK_EPOCH=0
}

# Copy live script to a private temp file and re-exec from it so later in-place cp of the
# live path cannot feed bash a spliced mix of old and new source (classic mid-run syntax errors).
# Prefer a seal file beside the live script so dirname/$0 stays the real bin/ directory
# (many callers cd to "$(dirname "$0")" or source sibling helpers from that dir).
# Does not return on success (exec). Safe no-op if already sealed or copy fails.
script_self_update_seal_and_reexec() {
  local live tmp arg a0 last_i live_dir base
  local -a args

  [[ -z "${SCRIPT_SELF_SEALED:-}" ]] || return 0

  live="${SCRIPT_SELF_LIVE_PATH:-${SCRIPT_SELF_UPDATE_PATH:-}}"
  [[ -n "$live" && -f "$live" && -r "$live" ]] || return 0

  live_dir="$(cd "$(dirname -- "$live")" && pwd -P)" || return 0
  base="$(basename -- "$live")"
  tmp=""
  # Same directory as the live script (keeps $0 dirname == bin/).
  tmp="$(mktemp "${live_dir}/.${base}.seal.XXXXXX" 2>/dev/null || true)"
  if [[ -z "$tmp" ]]; then
    # Fall back when bin/ is not writable.
    tmp="$(mktemp "${TMPDIR:-/tmp}/${base}.seal.XXXXXX" 2>/dev/null || true)"
  fi
  [[ -n "$tmp" ]] || return 0
  if ! cp -f -- "$live" "$tmp"; then
    rm -f -- "$tmp"
    return 0
  fi
  chmod u+rwx -- "$tmp" 2>/dev/null || chmod u+rw -- "$tmp" 2>/dev/null || true

  args=()
  if [[ -r /proc/$$/cmdline ]]; then
    while IFS= read -r -d '' arg || [[ -n "$arg" ]]; do
      args+=( "$arg" )
    done < /proc/$$/cmdline
  fi
  if (( ${#args[@]} > 0 )); then
    last_i=$(( ${#args[@]} - 1 ))
    if [[ -z "${args[last_i]-}" ]]; then
      unset "args[last_i]"
    fi
  fi
  if (( ${#args[@]} == 0 )); then
    args=( bash "$tmp" )
  else
    a0="${args[0]-}"
    if [[ "$a0" == bash || "$a0" == */bash || "$a0" == sh || "$a0" == */sh ]]; then
      if (( ${#args[@]} >= 2 )); then
        args[1]="$tmp"
      else
        args+=( "$tmp" )
      fi
    else
      # Direct shebang exec: argv0 was the live script path.
      args[0]="$tmp"
    fi
  fi

  export SCRIPT_SELF_SEALED=1
  export SCRIPT_SELF_LIVE_PATH="$live"
  export SCRIPT_SELF_SEAL_TMP="$tmp"
  # Child cleans its own seal file; parent would remove it before child runs if we cleaned here.
  exec "${args[@]}"
}

script_self_update_reexec() {
  local -a args
  local last_i a0 arg live

  live="${SCRIPT_SELF_LIVE_PATH:-${SCRIPT_SELF_UPDATE_PATH:-}}"
  args=()
  if [[ -r /proc/$$/cmdline ]]; then
    while IFS= read -r -d '' arg || [[ -n "$arg" ]]; do
      args+=( "$arg" )
    done < /proc/$$/cmdline
  fi

  if (( ${#args[@]} > 0 )); then
    last_i=$(( ${#args[@]} - 1 ))
    if [[ -z "${args[last_i]-}" ]]; then
      unset "args[last_i]"
    fi
  fi

  if (( ${#args[@]} == 0 )); then
    if [[ -n "$live" && -x "$live" ]]; then
      args=( "$live" )
    elif [[ -n "$live" ]]; then
      args=( bash "$live" )
    else
      echo "ERROR: cannot re-exec; original command line is unavailable." >&2
      return 1
    fi
  fi

  # Always restart from the live path (new content after copy), not the sealed temp.
  if [[ -n "$live" && -e "$live" ]]; then
    a0="${args[0]-}"
    if [[ "$a0" == bash || "$a0" == */bash || "$a0" == sh || "$a0" == */sh ]]; then
      if (( ${#args[@]} >= 2 )); then
        args[1]="$live"
      fi
    else
      args[0]="$live"
    fi
  fi

  trap - DEBUG
  SCRIPT_SELF_UPDATE_DEBUG_TRAP_INSTALLED=0
  SCRIPT_SELF_UPDATE_STATE=off
  script_self_update_cleanup_seal
  unset SCRIPT_SELF_SEALED

  echo "Restarting with updated on-disk script: ${live}" >&2
  echo "Command: ${args[*]}" >&2
  exec "${args[@]}"
}

script_self_update_handle_change() {
  local answer="" new_fp="" new_ver="" old_ver="" tty_dev
  local ts

  new_fp="$(script_self_update_fingerprint "${SCRIPT_SELF_UPDATE_PATH}" 2>/dev/null || true)"
  [[ -n "$new_fp" ]] || return 0

  old_ver="${SCRIPT_SELF_UPDATE_FP#*$'\t'}"
  new_ver="${new_fp#*$'\t'}"
  ts="$(date '+%Y.%m.%d %H:%M:%S')"

  echo >&2
  echo "[${ts}] WARNING: the live script file was overwritten while this run is still using the old code." >&2
  echo "  path: ${SCRIPT_SELF_UPDATE_PATH}" >&2
  echo "  (Watches this path only — e.g. after git pull + copy into bin/. The git checkout alone is ignored.)" >&2
  if [[ -n "${SCRIPT_SELF_SEALED:-}" ]]; then
    echo "  This process is sealed (running from a private snapshot), so Continue will not hit in-place cp parse corruption." >&2
  else
    echo "  WARNING: this process is NOT sealed — Continue after an in-place cp can cause random mid-script syntax errors." >&2
  fi
  if [[ -n "$old_ver" || -n "$new_ver" ]]; then
    echo "  was:  ${old_ver:-unknown}" >&2
    echo "  now:  ${new_ver:-unknown}" >&2
  fi

  case "${SCRIPT_SELF_UPDATE_ACTION:-ask}" in
    continue|CONTINUE|c|C)
      echo "[${ts}] SCRIPT_SELF_UPDATE_ACTION=continue — keeping the already-running script." >&2
      SCRIPT_SELF_UPDATE_STATE=ignore
      SCRIPT_SELF_UPDATE_FP="$new_fp"
      return 0
      ;;
    quit|QUIT|q|Q)
      echo "[${ts}] SCRIPT_SELF_UPDATE_ACTION=quit — exiting." >&2
      trap - DEBUG
      script_self_update_cleanup_seal
      exit 75
      ;;
    reexec|restart|REEXEC|R)
      script_self_update_reexec
      return 1
      ;;
  esac

  tty_dev="/dev/tty"
  if [[ ! -r "$tty_dev" ]] && [[ ! -t 0 ]]; then
    echo "[${ts}] Non-interactive session — continuing with the already-running script (set SCRIPT_SELF_UPDATE_ACTION=reexec|quit to override)." >&2
    SCRIPT_SELF_UPDATE_STATE=ignore
    SCRIPT_SELF_UPDATE_FP="$new_fp"
    return 0
  fi

  echo -n "[${ts}] Script updated on disk — [R]estart with new script / [C]ontinue this run / [Q]uit: "
  answer=""
  if [[ -r "$tty_dev" ]]; then
    if ! IFS= read -r -n 1 answer <"$tty_dev"; then
      answer=C
    fi
  else
    if ! IFS= read -r -n 1 answer; then
      answer=C
    fi
  fi
  echo >&2

  case "${answer}" in
    r|R)
      script_self_update_reexec
      return 1
      ;;
    q|Q)
      echo "[${ts}] Selected: quit" >&2
      trap - DEBUG
      script_self_update_cleanup_seal
      exit 75
      ;;
    *)
      echo "[${ts}] Selected: continue with the already-running script" >&2
      SCRIPT_SELF_UPDATE_STATE=ignore
      SCRIPT_SELF_UPDATE_FP="$new_fp"
      return 0
      ;;
  esac
}

# Fast no-op when unchanged. Safe to call from DEBUG trap.
script_self_update_check_throttled() {
  local now fp

  (( SCRIPT_SELF_UPDATE_IN_CHECK == 1 )) && return 0
  [[ "${SCRIPT_SELF_UPDATE_STATE}" == watch ]] || return 0
  [[ -n "${SCRIPT_SELF_UPDATE_PATH}" && -n "${SCRIPT_SELF_UPDATE_FP}" ]] || return 0

  now="$(date +%s 2>/dev/null || printf '%s' 0)"
  [[ "$now" =~ ^[0-9]+$ ]] || return 0
  if (( SCRIPT_SELF_UPDATE_LAST_CHECK_EPOCH > 0 )) && \
     (( now - SCRIPT_SELF_UPDATE_LAST_CHECK_EPOCH < SCRIPT_SELF_UPDATE_INTERVAL_SEC )); then
    return 0
  fi
  SCRIPT_SELF_UPDATE_LAST_CHECK_EPOCH="$now"

  # Path briefly missing during an atomic replace — check again later.
  [[ -e "${SCRIPT_SELF_UPDATE_PATH}" ]] || return 0

  fp="$(script_self_update_fingerprint "${SCRIPT_SELF_UPDATE_PATH}" 2>/dev/null || true)"
  [[ -n "$fp" ]] || return 0
  [[ "$fp" == "${SCRIPT_SELF_UPDATE_FP}" ]] && return 0

  SCRIPT_SELF_UPDATE_IN_CHECK=1
  trap - DEBUG
  SCRIPT_SELF_UPDATE_DEBUG_TRAP_INSTALLED=0
  script_self_update_handle_change || true
  SCRIPT_SELF_UPDATE_IN_CHECK=0
  if [[ "${SCRIPT_SELF_UPDATE_STATE}" == watch ]]; then
    script_self_update_install_trap
  fi
  return 0
}

script_self_update_install_trap() {
  [[ "${SCRIPT_SELF_UPDATE_STATE}" == watch ]] || return 0
  (( SCRIPT_SELF_UPDATE_DEBUG_TRAP_INSTALLED == 1 )) && return 0

  # Do not clobber a DEBUG trap installed by the caller.
  if [[ "$(trap -p DEBUG 2>/dev/null)" == *DEBUG* ]]; then
    return 0
  fi

  trap 'script_self_update_check_throttled' DEBUG
  SCRIPT_SELF_UPDATE_DEBUG_TRAP_INSTALLED=1
}

# init live path → seal (exec, no return) → after re-entry: init + watch trap + seal cleanup.
script_self_update_setup() {
  local live="${1:-}"

  if [[ -n "${SCRIPT_SELF_SEALED:-}" ]]; then
    # Already running from a sealed temp copy — watch the live destination path.
    live="${SCRIPT_SELF_LIVE_PATH:-$live}"
    script_self_update_init "$live"
    script_self_update_register_seal_cleanup
    script_self_update_install_trap
    return 0
  fi

  script_self_update_init "$live"
  # Prefer sealing; if exec fails we still install the watch trap.
  script_self_update_seal_and_reexec || true
  script_self_update_install_trap
}
