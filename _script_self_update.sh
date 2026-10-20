#!/usr/bin/env bash
# v. 20261020.202200 - detect on-disk script replacement while a run is in progress
#
# 2026.10.20 - v. 1.0.202200 - Snapshot inode/size/mtime (+ first # v. line). Throttled DEBUG trap
#   notices when the path is replaced (e.g. git pull). Interactive: [R]estart / [C]ontinue / [Q]uit.
#   Non-interactive: warn once and keep the already-running code. Sourced by _script_header.sh and rename.sh.
#
# Contract: source this file; call script_self_update_init [path] then script_self_update_install_trap.
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

script_self_update_resolve_path() {
  local p="" dir base found i

  p="${1:-}"
  if [[ -z "$p" ]]; then
    p="${CALLER_SCRIPT:-}"
  fi
  if [[ -z "$p" ]]; then
    for (( i=0; i < ${#BASH_SOURCE[@]}; i++ )); do
      p="${BASH_SOURCE[i]}"
      case "$(basename -- "$p")" in
        _script_self_update.sh|_script_header.sh|_script_footer.sh) continue ;;
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
  SCRIPT_SELF_UPDATE_FP="$fp"
  SCRIPT_SELF_UPDATE_STATE=watch
  SCRIPT_SELF_UPDATE_LAST_CHECK_EPOCH=0
}

script_self_update_reexec() {
  local -a args
  local last_i a0 arg

  args=()
  if [[ -r /proc/$$/cmdline ]]; then
    # bash 4.2: read -d '' (mapfile -d needs 4.4+)
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
    if [[ -n "${SCRIPT_SELF_UPDATE_PATH:-}" && -x "${SCRIPT_SELF_UPDATE_PATH}" ]]; then
      args=( "${SCRIPT_SELF_UPDATE_PATH}" )
    elif [[ -n "${SCRIPT_SELF_UPDATE_PATH:-}" ]]; then
      args=( bash "${SCRIPT_SELF_UPDATE_PATH}" )
    else
      echo "ERROR: cannot re-exec; original command line is unavailable." >&2
      return 1
    fi
  fi

  # Prefer the current on-disk path when argv pointed at this script.
  if [[ -n "${SCRIPT_SELF_UPDATE_PATH:-}" && -e "${SCRIPT_SELF_UPDATE_PATH}" ]]; then
    a0="${args[0]-}"
    if [[ "$a0" == bash || "$a0" == */bash || "$a0" == sh || "$a0" == */sh ]]; then
      if (( ${#args[@]} >= 2 )); then
        args[1]="${SCRIPT_SELF_UPDATE_PATH}"
      fi
    else
      args[0]="${SCRIPT_SELF_UPDATE_PATH}"
    fi
  fi

  trap - DEBUG
  SCRIPT_SELF_UPDATE_DEBUG_TRAP_INSTALLED=0
  SCRIPT_SELF_UPDATE_STATE=off

  echo "Restarting with updated on-disk script: ${SCRIPT_SELF_UPDATE_PATH}" >&2
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
  echo "[${ts}] WARNING: on-disk script was replaced while this run is still using the old code." >&2
  echo "  path: ${SCRIPT_SELF_UPDATE_PATH}" >&2
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
