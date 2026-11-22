#!/usr/bin/env bash
# v. 20261122.163000 - clear inherited SCRIPT_SELF_* unless $0 is this run's seal file (fix screen env poisoning rename.sh)
# v. 20261117.141000 - script_self_update_check_now: unthrottled live-path check
# v. 20261117.084500 - ignore inherited SCRIPT_SELF_* seal env from a different parent script
# v. 20261116.152500 - after [R]/[C]/[Q], drain leftover Enter from the tty so the next prompt is not auto-answered
# v. 20261102.155130 - DEBUG trap must not clear BASH_REMATCH
# v. 20261021.210400 - script_live_basename here; prefer SCRIPT_SELF_LIVE_PATH over stale CALLER_*
# v. 20261021.143500 - after seal, restore $0 / CALLER_* to the live script name (not .deleteme.*.seal.*)
# v. 20261020.205600 - seal name .deleteme.<script>.seal.XXXX; if seal copy fails, run live script
# v. 20261020.205000 - seal running script to a temp copy so in-place cp cannot break bash parse
# v. 20261020.202500 - detect live-script overwrite (git pull then copy into bin/) mid-run
# v. 20261020.202200 - detect on-disk script replacement while a run is in progress
#
# 2026.11.17 - v. 1.9.141000 - script_self_update_check_now: ignore the DEBUG throttle and check
#   the live path immediately (for callers such as merge after "Group finished"). The periodic
#   DEBUG trap (SCRIPT_SELF_UPDATE_INTERVAL_SEC, default 30) stays as a backup during long work.
# 2026.11.17 - v. 1.8.084500 - Seal exports SCRIPT_SELF_LIVE_PATH / SCRIPT_SELF_SEALED for re-exec of
#   the same script. Child helpers (e.g. video-pgm-play-terminal.sh spawned from merge) inherited
#   those vars and then printed the parent's figlet/banner (merge name/version). Clear foreign seal
#   env when the caller's basename does not match SCRIPT_SELF_LIVE_PATH (seal .deleteme.* names
#   normalize to the live basename first).
# 2026.11.16 - v. 1.7.152500 - After the single-key [R]/[C]/[Q] answer, drain leftover bytes
#   (especially Enter) from /dev/tty and stdin. Without that, Continue left a newline in the
#   buffer and the next one-key menu (e.g. Contour suspect, default Skip) was answered
#   immediately — the run looked like it exited while groups remained.
# 2026.11.02 - v. 1.6.155130 - DEBUG trap: validate the epoch with case, not =~, and save/restore
#   BASH_REMATCH around the check. =~ here cleared the caller's captures, so the next
#   line died under nounset (BASH_REMATCH[1]: unbound variable) and arithmetic saw 0.
# 2026.10.21 - v. 1.5.210400 - define script_live_basename here (header and rename both use it); never
#   return a .deleteme.*.seal.* name; prefer SCRIPT_SELF_LIVE_PATH over CALLER_SCRIPT_BASENAME
# 2026.10.21 - v. 1.4.143500 - After a sealed re-exec, set BASH_ARGV0 and CALLER_SCRIPT* back to
#   SCRIPT_SELF_LIVE_PATH so Equivalent/Command lines and banners show video-pgm-….sh, not
#   .deleteme.video-pgm-….sh.seal.XXXXXX
# 2026.10.20 - v. 1.3.205600 - Seal files are named .deleteme.<basename>.seal.XXXXXX beside the live
#   script (or under TMPDIR if bin/ is not writable). If mktemp/cp fails, skip sealing and keep
#   running the original script — never abort startup for a read-only directory.
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
        .deleteme.*.seal.*|*.deleteme.*.seal.*|.*.seal.*|*.seal.*) continue ;;
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
  # Same directory as the live script (keeps $0 dirname == bin/). Name marks leftovers as disposable.
  tmp="$(mktemp "${live_dir}/.deleteme.${base}.seal.XXXXXX" 2>/dev/null || true)"
  if [[ -z "$tmp" ]]; then
    # Fall back when bin/ is not writable (e.g. read-only mount).
    tmp="$(mktemp "${TMPDIR:-/tmp}/.deleteme.${base}.seal.XXXXXX" 2>/dev/null || true)"
  fi
  if [[ -z "$tmp" ]]; then
    # Cannot seal — run the original live script; do not abort.
    return 0
  fi
  if ! cp -f -- "$live" "$tmp" 2>/dev/null; then
    rm -f -- "$tmp" 2>/dev/null || true
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
    elif [[ ( "$a0" == env || "$a0" == */env ) && ${#args[@]} -ge 3 \
        && ( "${args[1]-}" == bash || "${args[1]-}" == */bash || "${args[1]-}" == sh || "${args[1]-}" == */sh ) ]]; then
      # #!/usr/bin/env bash → argv is env, bash, live-script, args…
      args[2]="$tmp"
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

# Drop leftover keypresses (Enter after a single-key answer, typeahead) so the
# next interactive prompt is not answered by accident.
script_self_update_drain_input() {
  local tty_dev="${1:-/dev/tty}"
  local discard drained=0 max_drain=64

  if [[ -r "$tty_dev" ]]; then
    while (( drained < max_drain )) && IFS= read -r -t 0.05 -n 1 discard <"$tty_dev"; do
      ((++drained)) || true
    done
  fi
  drained=0
  while (( drained < max_drain )) && IFS= read -r -t 0.05 -n 1 discard; do
    ((++drained)) || true
  done
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
  # Single-key read leaves a following Enter (and any typeahead) in the tty buffer.
  # Drain it so the caller's next menu is not auto-answered with its default.
  script_self_update_drain_input "$tty_dev"

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
      echo "[${ts}] Resuming where this run left off (remaining groups/prompts still ahead)." >&2
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
  # case, not =~. This function runs from the DEBUG trap, before every simple command.
  # =~ replaces BASH_REMATCH and drops capture groups the caller still needs.
  case "$now" in
    ''|*[!0-9]*) return 0 ;;
  esac
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

# Ignore the DEBUG throttle and check the live path now (e.g. after finishing a merge group).
# Same [R]/[C]/[Q] prompt as the trap when the on-disk script changed.
script_self_update_check_now() {
  SCRIPT_SELF_UPDATE_LAST_CHECK_EPOCH=0
  script_self_update_check_throttled
}

# DEBUG runs before the next simple command. Put the caller's captures back
# even if the check (or something it calls) uses =~.
script_self_update_debug_trap() {
  local saved_decl="" rc=0

  if ! saved_decl="$(declare -p BASH_REMATCH 2>/dev/null)"; then
    saved_decl=""
  fi
  script_self_update_check_throttled || rc=$?
  if [[ -n "$saved_decl" ]]; then
    # declare inside a function is local unless -g. declare -p does not emit -g.
    eval "${saved_decl/declare/declare -g}"
  else
    unset BASH_REMATCH
  fi
  return "$rc"
}

script_self_update_install_trap() {
  [[ "${SCRIPT_SELF_UPDATE_STATE}" == watch ]] || return 0
  (( SCRIPT_SELF_UPDATE_DEBUG_TRAP_INSTALLED == 1 )) && return 0

  # Do not clobber a DEBUG trap installed by the caller.
  if [[ "$(trap -p DEBUG 2>/dev/null)" == *DEBUG* ]]; then
    return 0
  fi

  trap 'script_self_update_debug_trap' DEBUG
  SCRIPT_SELF_UPDATE_DEBUG_TRAP_INSTALLED=1
}

# Basename of the live script — never a .deleteme.*.seal.* snapshot.
# Prefer this in Usage / Examples / Equivalent CLI / Command lines.
script_live_basename() {
  local base=""

  if [[ -n "${SCRIPT_SELF_LIVE_PATH:-}" ]]; then
    base="$(basename -- "${SCRIPT_SELF_LIVE_PATH}")"
  elif [[ -n "${CALLER_SCRIPT:-}" ]]; then
    base="$(basename -- "${CALLER_SCRIPT}")"
  elif [[ -n "${CALLER_SCRIPT_BASENAME:-}" ]]; then
    base="${CALLER_SCRIPT_BASENAME}"
  else
    base="$(basename -- "${0:-}")"
  fi
  case "$base" in
    .deleteme.*.seal.*)
      base="${base#.deleteme.}"
      base="${base%.seal.*}"
      ;;
  esac
  printf '%s\n' "$base"
}

# After seal re-exec, $0 is .deleteme.<script>.seal.XXXXXX. Point identity back at the live file
# so Command / Equivalent CLI / banners / --help examples show the real script name.
script_self_update_apply_live_identity() {
  local live base

  live="${SCRIPT_SELF_LIVE_PATH:-}"
  [[ -n "$live" && -f "$live" ]] || return 0

  # Bash 5+: assigning BASH_ARGV0 updates $0 for basename "$0" and similar.
  if [[ -n "${BASH_VERSINFO:-}" ]] && (( BASH_VERSINFO[0] >= 5 )); then
    BASH_ARGV0="$live"
  fi

  base="$(basename -- "$live")"
  CALLER_SCRIPT="$live"
  CALLER_SCRIPT_BASENAME="$base"
  export CALLER_SCRIPT CALLER_SCRIPT_BASENAME SCRIPT_SELF_LIVE_PATH
}

# Normalize .deleteme.<name>.seal.XXXX → <name> for comparing seal vs live basenames.
script_self_update_live_basename_of() {
  local base
  base="$(basename -- "${1:-}")"
  case "$base" in
    .deleteme.*.seal.*)
      base="${base#.deleteme.}"
      base="${base%.seal.*}"
      ;;
  esac
  printf '%s\n' "$base"
}

# Seal re-exec exports SCRIPT_SELF_* so the same script can restore identity. Long-lived children
# (e.g. bash inside `screen` started by screen-after-the-reboot.sh) inherit that env. Keep seal
# state only when THIS process is actually running the seal temp file; otherwise drop it so the
# next script seals/copies itself (never the parent's live path).
script_self_update_clear_foreign_seal() {
  local this="${1:-${CALLER_SCRIPT:-${0:-}}}"
  local this_base live_base seal_base

  [[ -n "${SCRIPT_SELF_SEALED:-}${SCRIPT_SELF_LIVE_PATH:-}${SCRIPT_SELF_SEAL_TMP:-}" ]] || return 0

  this_base="$(script_self_update_live_basename_of "$this")"
  live_base="$(script_self_update_live_basename_of "${SCRIPT_SELF_LIVE_PATH:-}")"
  seal_base="$(basename -- "${SCRIPT_SELF_SEAL_TMP:-}")"

  # Real sealed re-exec: $0 is the .deleteme.*.seal.* file and (if set) LIVE matches this script.
  if [[ -n "${SCRIPT_SELF_SEALED:-}" && -n "$seal_base" && "${0##*/}" == "$seal_base" ]]; then
    if [[ -z "$live_base" || -z "$this_base" || "$live_base" == "$this_base" ]]; then
      return 0
    fi
  fi

  # Inherited from another script, or SEALED without running the seal file — start clean.
  unset SCRIPT_SELF_SEALED SCRIPT_SELF_LIVE_PATH SCRIPT_SELF_SEAL_TMP
  SCRIPT_SELF_UPDATE_STATE=off
  SCRIPT_SELF_UPDATE_PATH=""
  SCRIPT_SELF_UPDATE_FP=""
  SCRIPT_SELF_UPDATE_DEBUG_TRAP_INSTALLED=0
}

# init live path → seal (exec, no return) → after re-entry: init + watch trap + seal cleanup.
script_self_update_setup() {
  local live="${1:-}"
  local caller_base live_arg_base

  script_self_update_clear_foreign_seal "${CALLER_SCRIPT:-${0:-}}"

  # Header used to pass "${SCRIPT_SELF_LIVE_PATH:-$CALLER_SCRIPT}"; that expands the parent's
  # live path before we clear foreign seal. Prefer CALLER_SCRIPT when $1 is a different script.
  if [[ -n "${CALLER_SCRIPT:-}" ]]; then
    caller_base="$(script_self_update_live_basename_of "$CALLER_SCRIPT")"
    live_arg_base="$(script_self_update_live_basename_of "${live:-}")"
    if [[ -z "$live" || ( -n "$caller_base" && -n "$live_arg_base" && "$caller_base" != "$live_arg_base" ) ]]; then
      live="$CALLER_SCRIPT"
    fi
  fi

  if [[ -n "${SCRIPT_SELF_SEALED:-}" ]]; then
    # Already running from a sealed temp copy — watch the live destination path.
    live="${SCRIPT_SELF_LIVE_PATH:-$live}"
    script_self_update_init "$live"
    script_self_update_apply_live_identity
    script_self_update_register_seal_cleanup
    script_self_update_install_trap
    return 0
  fi

  script_self_update_init "$live"
  # Prefer sealing; if exec fails we still install the watch trap.
  script_self_update_seal_and_reexec || true
  script_self_update_apply_live_identity
  script_self_update_install_trap
}
