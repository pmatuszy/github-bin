#!/bin/bash
# v. 20260921.085347 - initial release: reboot when /var/run/reboot-required and system is idle
# 2026.09.21 - v. 0.1 - Reboot only when /var/run/reboot-required exists and apt/dpkg are idle,
#                       load is low, and uptime is past a floor; retry every 5 minutes for up to
#                       2 hours, then give up; --verbose explains each gate; -n/--dry-run never reboots
#
# reboot-when-required.sh
#
# If the system needs a reboot (/var/run/reboot-required), wait until it is safe
# (no apt/dpkg activity, load low enough, minimum uptime), then reboot. When a
# gate fails, retry for a configurable window (default: every 5 minutes for 2 hours).
# Intended for a night cron window; keep healthchecks-reboot-required.sh as the monitor.
#

DEFAULT_RETRY_INTERVAL=300
DEFAULT_RETRY_WINDOW=7200
DEFAULT_MIN_UPTIME=3600
DEFAULT_SHUTDOWN_DELAY=1

show_help() {
  cat <<EOF
Usage: $(basename "$0") [options]

Reboot when /var/run/reboot-required is present and the machine looks idle
(no apt/dpkg activity, load below threshold, minimum uptime). If a gate fails,
retry until the retry window expires, then give up.

Options:
  -h, --help              Show this help and exit.
  -v, --version           Print script version and exit.
  --history               Print script changelog from the header and exit.
  --no_startup_delay      Skip random startup delay (recommended for cron).
  -V, --verbose           Print every gate result (pass/fail and why).
  -n, --dry-run           Run all checks and the retry loop; never reboot.
  --retry-interval SEC    Seconds between retries (default: ${DEFAULT_RETRY_INTERVAL}).
  --retry-window SEC      Give up after this many seconds (default: ${DEFAULT_RETRY_WINDOW}).
  --load-max N            Max 1-minute loadavg allowed (default: 0.25 * nproc).
  --min-uptime SEC        Refuse reboot if uptime is below this (default: ${DEFAULT_MIN_UPTIME}).
  --shutdown-delay MIN    Minutes argument for shutdown -r (default: ${DEFAULT_SHUTDOWN_DELAY}).
  --allow-users           Do not treat logged-in users (who) as a blocker.
  --require-no-users      Refuse reboot when who(1) shows any user (default).

Environment (overridden by flags when set):
  REBOOT_RETRY_INTERVAL   Same as --retry-interval
  REBOOT_RETRY_WINDOW     Same as --retry-window
  REBOOT_LOAD_MAX         Same as --load-max
  REBOOT_MIN_UPTIME       Same as --min-uptime
  REBOOT_SHUTDOWN_DELAY   Same as --shutdown-delay
  REBOOT_ALLOW_USERS=1    Same as --allow-users

Exit codes:
  0  reboot not required, or reboot initiated (or dry-run would have rebooted)
  1  gave up after the retry window (conditions never met)
  2  usage / privilege / configuration error

EOF
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

VERBOSE=0
DRY_RUN=0
RETRY_INTERVAL="${REBOOT_RETRY_INTERVAL:-$DEFAULT_RETRY_INTERVAL}"
RETRY_WINDOW="${REBOOT_RETRY_WINDOW:-$DEFAULT_RETRY_WINDOW}"
LOAD_MAX="${REBOOT_LOAD_MAX:-}"
MIN_UPTIME="${REBOOT_MIN_UPTIME:-$DEFAULT_MIN_UPTIME}"
SHUTDOWN_DELAY="${REBOOT_SHUTDOWN_DELAY:-$DEFAULT_SHUTDOWN_DELAY}"
ALLOW_USERS=0
case "${REBOOT_ALLOW_USERS:-0}" in
  1|yes|true|Y|y) ALLOW_USERS=1 ;;
esac
# Default: require no interactive users unless --allow-users.
REQUIRE_NO_USERS=1
RETRY_INTERVAL_CLI=0
RETRY_WINDOW_CLI=0
LOAD_MAX_CLI=0
MIN_UPTIME_CLI=0
SHUTDOWN_DELAY_CLI=0
ALLOW_USERS_CLI=0

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
    --history)
      print_script_history
      exit 0
      ;;
    -V|--verbose)
      VERBOSE=1
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    --retry-interval)
      [[ $# -ge 2 && "$2" =~ ^[1-9][0-9]*$ ]] || {
        echo "ERROR: --retry-interval needs a positive integer (seconds)." >&2
        exit 2
      }
      RETRY_INTERVAL="$2"
      RETRY_INTERVAL_CLI=1
      shift 2
      ;;
    --retry-window)
      [[ $# -ge 2 && "$2" =~ ^[1-9][0-9]*$ ]] || {
        echo "ERROR: --retry-window needs a positive integer (seconds)." >&2
        exit 2
      }
      RETRY_WINDOW="$2"
      RETRY_WINDOW_CLI=1
      shift 2
      ;;
    --load-max)
      [[ $# -ge 2 && "$2" =~ ^[0-9]+([.][0-9]+)?$ ]] || {
        echo "ERROR: --load-max needs a non-negative number." >&2
        exit 2
      }
      LOAD_MAX="$2"
      LOAD_MAX_CLI=1
      shift 2
      ;;
    --min-uptime)
      [[ $# -ge 2 && "$2" =~ ^[0-9]+$ ]] || {
        echo "ERROR: --min-uptime needs a non-negative integer (seconds)." >&2
        exit 2
      }
      MIN_UPTIME="$2"
      MIN_UPTIME_CLI=1
      shift 2
      ;;
    --shutdown-delay)
      [[ $# -ge 2 && "$2" =~ ^[0-9]+$ ]] || {
        echo "ERROR: --shutdown-delay needs a non-negative integer (minutes)." >&2
        exit 2
      }
      SHUTDOWN_DELAY="$2"
      SHUTDOWN_DELAY_CLI=1
      shift 2
      ;;
    --allow-users)
      ALLOW_USERS=1
      REQUIRE_NO_USERS=0
      ALLOW_USERS_CLI=1
      shift
      ;;
    --require-no-users)
      ALLOW_USERS=0
      REQUIRE_NO_USERS=1
      ALLOW_USERS_CLI=1
      shift
      ;;
    --no_startup_delay)
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 2
      ;;
    *)
      echo "Unexpected argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 2
      ;;
  esac
done

################################################################################
# Logging
################################################################################

ts() {
  date '+%Y.%m.%d %H:%M:%S'
}

log() {
  printf '%s %s\n' "$(ts)" "$*"
}

vlog() {
  (( VERBOSE )) || return 0
  printf '%s [verbose] %s\n' "$(ts)" "$*"
}

################################################################################
# Resolve defaults that need runtime probes
################################################################################

NPROC="$(nproc 2>/dev/null || echo 1)"
[[ "$NPROC" =~ ^[1-9][0-9]*$ ]] || NPROC=1

if [[ -z "$LOAD_MAX" ]]; then
  LOAD_MAX="$(awk -v c="$NPROC" 'BEGIN { printf "%.2f", (c < 1 ? 1 : c) * 0.25 }')"
fi

################################################################################
# Healthchecks (optional; same pattern as other healthchecks-*.sh scripts)
################################################################################

HEALTHCHECK_URL=""
if [[ -f "${HEALTHCHECKS_FILE:-}" ]]; then
  HEALTHCHECK_URL="$(grep "^$(basename "$0")" "$HEALTHCHECKS_FILE" | awk '{print $2}')"
fi

hc_ping() {
  local path="${1:-}"
  local body="${2:-}"
  [[ -n "$HEALTHCHECK_URL" ]] || return 0
  if [[ -n "$body" ]]; then
    printf '%s' "$body" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 \
      --data-binary @- -o /dev/null "${HEALTHCHECK_URL}${path}" 2>/dev/null || true
  else
    /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 \
      -o /dev/null "${HEALTHCHECK_URL}${path}" 2>/dev/null || true
  fi
}

################################################################################
# Run settings
################################################################################

print_run_settings_equivalent_cli() {
  local cmd out p q_host
  local -a parts=()

  cmd="$(basename -- "${BASH_SOURCE[0]:-$0}")"
  [[ -n "$cmd" ]] || cmd="reboot-when-required.sh"

  (( VERBOSE )) && parts+=("--verbose")
  (( DRY_RUN )) && parts+=("--dry-run")
  parts+=("--retry-interval" "$RETRY_INTERVAL")
  parts+=("--retry-window" "$RETRY_WINDOW")
  parts+=("--load-max" "$LOAD_MAX")
  parts+=("--min-uptime" "$MIN_UPTIME")
  parts+=("--shutdown-delay" "$SHUTDOWN_DELAY")
  if (( ALLOW_USERS )); then
    parts+=("--allow-users")
  else
    parts+=("--require-no-users")
  fi

  out="$(printf '%q' "$cmd")"
  for p in "${parts[@]}"; do
    out+=" $(printf '%q' "$p")"
  done
  q_host="$(printf '%q' "$(hostname)")"
  printf '  %-22s%s\n' "Equivalent CLI:" "$out"
  printf '  %-22s%s\n' "Host:" "$q_host"
}

print_run_settings() {
  echo
  echo "=== Run settings ==="
  if (( DRY_RUN )); then
    printf '  %-22s%s\n' "-n/--dry-run:" "given (checks + retries only; never reboot)"
  else
    printf '  %-22s%s\n' "-n/--dry-run:" "not given (will reboot when all gates pass)"
  fi
  if (( VERBOSE )); then
    printf '  %-22s%s\n' "-V/--verbose:" "given"
  else
    printf '  %-22s%s\n' "-V/--verbose:" "not given"
  fi
  if (( RETRY_INTERVAL_CLI )); then
    printf '  %-22s%s\n' "--retry-interval:" "given (${RETRY_INTERVAL}s)"
  elif [[ -n "${REBOOT_RETRY_INTERVAL:-}" ]]; then
    printf '  %-22s%s\n' "--retry-interval:" "${RETRY_INTERVAL}s (env REBOOT_RETRY_INTERVAL)"
  else
    printf '  %-22s%s\n' "--retry-interval:" "${RETRY_INTERVAL}s (default)"
  fi
  if (( RETRY_WINDOW_CLI )); then
    printf '  %-22s%s\n' "--retry-window:" "given (${RETRY_WINDOW}s)"
  elif [[ -n "${REBOOT_RETRY_WINDOW:-}" ]]; then
    printf '  %-22s%s\n' "--retry-window:" "${RETRY_WINDOW}s (env REBOOT_RETRY_WINDOW)"
  else
    printf '  %-22s%s\n' "--retry-window:" "${RETRY_WINDOW}s (default ~2h)"
  fi
  if (( LOAD_MAX_CLI )); then
    printf '  %-22s%s\n' "--load-max:" "given (${LOAD_MAX}; nproc=${NPROC})"
  elif [[ -n "${REBOOT_LOAD_MAX:-}" ]]; then
    printf '  %-22s%s\n' "--load-max:" "${LOAD_MAX} (env REBOOT_LOAD_MAX; nproc=${NPROC})"
  else
    printf '  %-22s%s\n' "--load-max:" "${LOAD_MAX} (default 0.25*nproc; nproc=${NPROC})"
  fi
  if (( MIN_UPTIME_CLI )); then
    printf '  %-22s%s\n' "--min-uptime:" "given (${MIN_UPTIME}s)"
  elif [[ -n "${REBOOT_MIN_UPTIME:-}" ]]; then
    printf '  %-22s%s\n' "--min-uptime:" "${MIN_UPTIME}s (env REBOOT_MIN_UPTIME)"
  else
    printf '  %-22s%s\n' "--min-uptime:" "${MIN_UPTIME}s (default)"
  fi
  if (( SHUTDOWN_DELAY_CLI )); then
    printf '  %-22s%s\n' "--shutdown-delay:" "given (${SHUTDOWN_DELAY} min)"
  elif [[ -n "${REBOOT_SHUTDOWN_DELAY:-}" ]]; then
    printf '  %-22s%s\n' "--shutdown-delay:" "${SHUTDOWN_DELAY} min (env REBOOT_SHUTDOWN_DELAY)"
  else
    printf '  %-22s%s\n' "--shutdown-delay:" "${SHUTDOWN_DELAY} min (default)"
  fi
  if (( ALLOW_USERS )); then
    printf '  %-22s%s\n' "Logged-in users:" "ignored (--allow-users)"
  else
    printf '  %-22s%s\n' "Logged-in users:" "must be none (--require-no-users)"
  fi
  printf '  %-22s%s\n' "Reboot signal:" "/var/run/reboot-required"
  print_run_settings_equivalent_cli
  echo
}

################################################################################
# Individual gates — each prints verbose detail; return 0 = pass (safe)
################################################################################

# Human-readable list of PIDs + short command for verbose output.
format_pids() {
  local pid cmd
  for pid in "$@"; do
    [[ -n "$pid" ]] || continue
    cmd="$(ps -o args= -p "$pid" 2>/dev/null | head -c 120)"
    [[ -n "$cmd" ]] || cmd="(gone)"
    printf ' pid=%s cmd=%s;' "$pid" "$cmd"
  done
}

gate_reboot_required() {
  if [[ -f /var/run/reboot-required ]]; then
    vlog "PASS reboot-required: /var/run/reboot-required exists"
    if [[ -f /var/run/reboot-required.pkgs ]]; then
      vlog "  pkgs: $(tr '\n' ' ' </var/run/reboot-required.pkgs | head -c 200)"
    fi
    return 0
  fi
  vlog "FAIL reboot-required: /var/run/reboot-required not present (nothing to do)"
  return 1
}

# Apt/dpkg lock files or package-manager processes → not idle.
gate_apt_idle() {
  local lock locks pids pid busy=0 detail="" holders

  locks=(
    /var/lib/dpkg/lock
    /var/lib/dpkg/lock-frontend
    /var/lib/apt/lists/lock
    /var/cache/apt/archives/lock
  )

  for lock in "${locks[@]}"; do
    [[ -e "$lock" ]] || continue
    if command -v fuser >/dev/null 2>&1; then
      holders="$(fuser "$lock" 2>/dev/null | tr -s '[:space:]' ' ')"
      holders="${holders# }"
      holders="${holders% }"
      if [[ -n "$holders" ]]; then
        busy=1
        detail+=" lock ${lock} held by${holders};"
        vlog "  lock busy: $lock ->$holders"
      else
        vlog "  lock free: $lock"
      fi
    else
      vlog "  fuser not installed; skipping lock probe for $lock"
    fi
  done

  # Exact process names that mean a package transaction may be in progress.
  pids=()
  for name in apt apt-get aptitude dpkg unattended-upgrade unattended-upgrades packagekitd; do
    while read -r pid; do
      [[ -n "$pid" ]] || continue
      pids+=("$pid")
    done < <(pgrep -x "$name" 2>/dev/null || true)
  done

  if ((${#pids[@]} > 0)); then
    busy=1
    detail+=" processes:$(format_pids "${pids[@]}")"
    vlog "  package-manager process(es) running:$(format_pids "${pids[@]}")"
  else
    vlog "  no apt/apt-get/aptitude/dpkg/unattended-upgrade/packagekitd process"
  fi

  if (( busy )); then
    vlog "FAIL apt-idle: package manager busy (${detail})"
    LAST_FAIL_REASON="apt/dpkg busy:${detail}"
    return 1
  fi
  vlog "PASS apt-idle: no package-manager locks or processes"
  return 0
}

gate_load() {
  local load1 load5 load15
  # /proc/loadavg: 1m 5m 15m ...
  read -r load1 load5 load15 _ </proc/loadavg || {
    vlog "FAIL load: cannot read /proc/loadavg"
    LAST_FAIL_REASON="cannot read /proc/loadavg"
    return 1
  }
  vlog "  loadavg: 1m=${load1} 5m=${load5} 15m=${load15} (max 1m allowed: ${LOAD_MAX})"
  if awk -v a="$load1" -v m="$LOAD_MAX" 'BEGIN { exit !(a > m) }'; then
    vlog "FAIL load: 1-minute load ${load1} > ${LOAD_MAX}"
    LAST_FAIL_REASON="load ${load1} > ${LOAD_MAX}"
    return 1
  fi
  vlog "PASS load: 1-minute load ${load1} <= ${LOAD_MAX}"
  return 0
}

gate_min_uptime() {
  local uptime_sec
  uptime_sec="$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)"
  vlog "  uptime: ${uptime_sec}s (minimum required: ${MIN_UPTIME}s)"
  if (( uptime_sec < MIN_UPTIME )); then
    vlog "FAIL min-uptime: ${uptime_sec}s < ${MIN_UPTIME}s (avoid reboot loops)"
    LAST_FAIL_REASON="uptime ${uptime_sec}s < ${MIN_UPTIME}s"
    return 1
  fi
  vlog "PASS min-uptime: ${uptime_sec}s >= ${MIN_UPTIME}s"
  return 0
}

gate_no_users() {
  local who_out
  if (( ! REQUIRE_NO_USERS )); then
    vlog "SKIP users: --allow-users (logged-in users are ignored)"
    return 0
  fi
  who_out="$(who 2>/dev/null || true)"
  if [[ -n "$who_out" ]]; then
    vlog "FAIL users: who(1) shows logged-in session(s):"
    while IFS= read -r line; do
      [[ -n "$line" ]] && vlog "  $line"
    done <<<"$who_out"
    LAST_FAIL_REASON="logged-in users present"
    return 1
  fi
  vlog "PASS users: who(1) shows nobody"
  return 0
}

# Root is required to call shutdown (skipped in --dry-run so checks can be tested as non-root).
gate_root() {
  if (( DRY_RUN )); then
    vlog "SKIP root: --dry-run (EUID=${EUID})"
    return 0
  fi
  if (( EUID == 0 )); then
    vlog "PASS root: running as uid 0"
    return 0
  fi
  vlog "FAIL root: not running as root (EUID=${EUID})"
  LAST_FAIL_REASON="not root (EUID=${EUID})"
  return 1
}

################################################################################
# Aggregate check (one attempt)
# Sets LAST_FAIL_REASON on failure. Returns 0 when safe to reboot.
################################################################################

LAST_FAIL_REASON=""

system_is_safe_to_reboot() {
  LAST_FAIL_REASON=""
  vlog "---- safety check begin ----"
  gate_root || return 1
  gate_reboot_required || {
    LAST_FAIL_REASON="reboot not required"
    return 1
  }
  gate_min_uptime || return 1
  gate_apt_idle || return 1
  gate_load || return 1
  gate_no_users || return 1
  vlog "---- safety check: ALL GATES PASSED ----"
  return 0
}

################################################################################
# Reboot action
################################################################################

initiate_reboot() {
  local msg
  msg="reboot-when-required: /var/run/reboot-required present; system idle"

  if (( DRY_RUN )); then
    log "DRY-RUN: would run: shutdown -r ${SHUTDOWN_DELAY} $(printf '%q' "$msg")"
    return 0
  fi

  if ! command -v shutdown >/dev/null 2>&1; then
    log "ERROR: shutdown command not found; cannot reboot."
    return 1
  fi

  log "Initiating reboot in ${SHUTDOWN_DELAY} minute(s): $msg"
  # wall message goes out automatically with shutdown -r.
  shutdown -r "$SHUTDOWN_DELAY" "$msg"
}

################################################################################
# Main
################################################################################

print_run_settings

# Real reboot needs root; dry-run may run as a normal user to inspect gates.
if (( EUID != 0 )) && (( ! DRY_RUN )); then
  log "ERROR: must run as root to reboot (or pass --dry-run to only check)."
  . /root/bin/_script_footer.sh
  exit 2
fi

hc_ping "/start"

# Fast path: if reboot is not required, do not sit in the 2-hour retry loop.
if [[ ! -f /var/run/reboot-required ]]; then
  log "Reboot not required (/var/run/reboot-required absent). Exiting."
  hc_ping "" "$(printf '%s\n' "${SCRIPT_VERSION}" "reboot not required")"
  . /root/bin/_script_footer.sh
  exit 0
fi

log "Reboot is required. Checking idle/safety gates (retry every ${RETRY_INTERVAL}s for up to ${RETRY_WINDOW}s)."

START_EPOCH="$(date +%s)"
DEADLINE=$((START_EPOCH + RETRY_WINDOW))
ATTEMPT=0
return_code=1

while true; do
  ((++ATTEMPT))
  NOW="$(date +%s)"
  REMAINING=$((DEADLINE - NOW))
  if (( REMAINING < 0 )); then
    REMAINING=0
  fi

  log "Attempt ${ATTEMPT}: evaluating safety gates (${REMAINING}s left in retry window)."

  if system_is_safe_to_reboot; then
    log "All gates passed on attempt ${ATTEMPT}."
    if initiate_reboot; then
      return_code=0
      if (( DRY_RUN )); then
        hc_ping "" "$(printf '%s\n' "${SCRIPT_VERSION}" "dry-run: would reboot (attempt ${ATTEMPT})")"
      else
        hc_ping "" "$(printf '%s\n' "${SCRIPT_VERSION}" "reboot initiated (attempt ${ATTEMPT}, delay ${SHUTDOWN_DELAY}m)")"
      fi
      . /root/bin/_script_footer.sh
      exit "$return_code"
    else
      log "ERROR: failed to initiate reboot."
      hc_ping "/fail" "$(printf '%s\n' "${SCRIPT_VERSION}" "failed to run shutdown")"
      . /root/bin/_script_footer.sh
      exit 1
    fi
  fi

  # Reboot-required disappeared mid-wait (admin cleared it) → success, nothing to do.
  if [[ "$LAST_FAIL_REASON" == "reboot not required" ]] || [[ ! -f /var/run/reboot-required ]]; then
    log "Reboot no longer required. Stopping retry loop."
    hc_ping "" "$(printf '%s\n' "${SCRIPT_VERSION}" "reboot no longer required after attempt ${ATTEMPT}")"
    . /root/bin/_script_footer.sh
    exit 0
  fi

  NOW="$(date +%s)"
  if (( NOW >= DEADLINE )); then
    log "Giving up after ${ATTEMPT} attempt(s): conditions not met within ${RETRY_WINDOW}s."
    log "Last failure: ${LAST_FAIL_REASON:-unknown}"
    hc_ping "/fail" "$(printf '%s\n' "${SCRIPT_VERSION}" \
      "gave up after ${ATTEMPT} attempt(s) / ${RETRY_WINDOW}s" \
      "last failure: ${LAST_FAIL_REASON:-unknown}")"
    . /root/bin/_script_footer.sh
    exit 1
  fi

  # Sleep, but do not overshoot the deadline by a full interval.
  SLEEP_FOR=$RETRY_INTERVAL
  REMAINING=$((DEADLINE - NOW))
  if (( SLEEP_FOR > REMAINING )); then
    SLEEP_FOR=$REMAINING
  fi
  if (( SLEEP_FOR < 1 )); then
    SLEEP_FOR=1
  fi

  if (( VERBOSE )); then
    log "Gate failed (${LAST_FAIL_REASON:-unknown}); sleeping ${SLEEP_FOR}s before retry."
  else
    log "Not ready (${LAST_FAIL_REASON:-unknown}); retry in ${SLEEP_FOR}s."
  fi
  sleep "$SLEEP_FOR"
done

######
# template crontab entry (night window; script itself retries for 2h):
#
# Keep the existing monitor separate:
#   0 7-22 * * * /root/bin/healthchecks-reboot-required.sh --no_startup_delay
#
# Attempt an idle reboot once per night (adjust host as needed):
#   20 3 * * * /root/bin/reboot-when-required.sh --no_startup_delay --verbose
#
# Dry-run first on a host:
#   20 3 * * * /root/bin/reboot-when-required.sh --no_startup_delay --verbose --dry-run
#
# Optional Healthchecks: add a line to /root/bin/healthchecks-ids.txt:
#   reboot-when-required.sh https://hc-ping.com/<uuid>
