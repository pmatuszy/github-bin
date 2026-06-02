#!/bin/bash

# 2026.06.02 - v. 0.4 - fix --run argv order (ifaces before options); exclude wifi; verify screen session after start
# 2026.06.02 - v. 0.3 - resolve GNU screen binary when screen is a shell function (type -P, /usr/bin/screen, /bin/screen)
# 2026.06.02 - v. 0.2 - screen: -c /dev/null so user .screenrc is not loaded
# 2026.06.02 - v. 0.1 - try 1 Gbit/s renegotiation on physical ethernet NICs: list candidates, ask user, run test in screen (ping + revert after timeout on failure)

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
       [ -i IFACE ] [ -t SECONDS ] [ -p HOST ] [ -s MBPS ] [ --run IFACE ... ]

Try to renegotiate physical ethernet link(s) to a higher speed (default 1000 Mb/s),
verify connectivity with ping, and revert to the previous ethtool settings if the
test fails within the timeout.

Interactive flow (default):
  1. Lists physical ethernet interfaces (skips loopback and virtual/docker bridges).
  2. Asks whether to proceed.
  3. Starts a detached GNU screen session named "${SCREEN_SESSION_NAME}" (no .screenrc;
     uses -c /dev/null) that runs the renegotiation test
     (attach: screen -c /dev/null -r ${SCREEN_SESSION_NAME}).

Inside the screen session, for each selected interface:
  - Saves current ethtool settings
  - Requests autonegotiation / target speed (default 1000 Mb/s full duplex)
  - Pings the target host until success or timeout (default 20 s)
  - On success: leaves the new link settings in place
  - On failure: restores the saved settings

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (see _script_header.sh).
  -i IFACE             Test only this interface (must be a physical ethernet NIC).
  -t SECONDS           Ping test timeout per interface (default: 20).
  -p HOST              Ping target (default: www.google.com).
  -s MBPS              Target speed in Mb/s (default: 1000).
  --run IFACE ...      Internal/worker: run tests (used when launched inside screen).

Requires root, ethtool, and ping.
EOF
}

SCREEN_SESSION_NAME="${NET_RENEG_SCREEN_NAME:-net-renegotiate}"
SCREEN_NO_RC=/dev/null
SCREEN_BIN=""

# Real GNU screen executable (not a shell function/alias named screen).
resolve_screen_bin() {
  local p=""
  if declare -F screen >/dev/null 2>&1; then
    p="$(type -P screen 2>/dev/null || true)"
  else
    p="$(command -v screen 2>/dev/null || true)"
    if [[ -n "$p" && ! -x "$p" ]]; then
      p="$(type -P screen 2>/dev/null || true)"
    fi
  fi
  if [[ -n "$p" && -x "$p" ]]; then
    printf '%s' "$p"
    return 0
  fi
  for p in /usr/bin/screen /bin/screen; do
    if [[ -x "$p" ]]; then
      printf '%s' "$p"
      return 0
    fi
  done
  return 1
}

ensure_screen_bin() {
  if [[ -n "$SCREEN_BIN" && -x "$SCREEN_BIN" ]]; then
    return 0
  fi
  SCREEN_BIN="$(resolve_screen_bin)" || return 1
  return 0
}
TARGET_MBPS="${NET_RENEG_TARGET_MBPS:-1000}"
PING_TARGET="${NET_RENEG_PING_TARGET:-www.google.com}"
PING_TIMEOUT_SEC="${NET_RENEG_TIMEOUT_SEC:-20}"
RUN_WORKER=0
HEADER_EXTRA_ARGS=()
CLI_IFACE=""
declare -a WORKER_IFACES=()

# --- parse options (before header for --help / --version) ---
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
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    --run)
      RUN_WORKER=1
      shift
      while [[ $# -gt 0 && "$1" != -* ]]; do
        WORKER_IFACES+=( "$1" )
        shift
      done
      ;;
    -i)
      [[ -n "${2:-}" ]] || { echo "Missing argument for -i" >&2; exit 1; }
      CLI_IFACE=$2
      shift 2
      ;;
    -t)
      [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]] || { echo "-t requires a positive integer (seconds)" >&2; exit 1; }
      PING_TIMEOUT_SEC=$2
      shift 2
      ;;
    -p)
      [[ -n "${2:-}" ]] || { echo "Missing argument for -p" >&2; exit 1; }
      PING_TARGET=$2
      shift 2
      ;;
    -s)
      [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]] || { echo "-s requires a positive integer (Mb/s)" >&2; exit 1; }
      TARGET_MBPS=$2
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

net_reneg_cleanup() {
  . /root/bin/_script_footer.sh
}
trap net_reneg_cleanup EXIT

kod_powrotu=0

# Wired ethernet only: sysfs device, ARPHRD_ETHER (1), not loopback/wifi/virtual.
iface_is_physical_ethernet() {
  local iface="$1" t
  [[ "$iface" != lo ]] || return 1
  [[ -e "/sys/class/net/${iface}/device" ]] || return 1
  [[ ! -d "/sys/class/net/${iface}/wireless" ]] || return 1
  [[ -r "/sys/class/net/${iface}/type" ]] || return 1
  t="$(<"/sys/class/net/${iface}/type")"
  [[ "$t" == 1 ]]
}

iface_link_state() {
  local iface="$1"
  if [[ -r "/sys/class/net/${iface}/operstate" ]]; then
    printf '%s' "$(<"/sys/class/net/${iface}/operstate")"
    return 0
  fi
  printf '%s' '?'
}

read_sysfs_speed_mbps() {
  local iface="$1" v f="/sys/class/net/${iface}/speed"
  [[ -r "$f" ]] || return 1
  v="$(<"$f")"
  [[ "$v" =~ ^[0-9]+$ ]] || return 1
  (( v > 0 && v != 65535 )) || return 1
  printf '%s' "$v"
}

format_speed_label() {
  local mbps="$1"
  case "$mbps" in
    10)   printf '%s' '10 Mb/s' ;;
    100)  printf '%s' '100 Mb/s' ;;
    1000) printf '%s' '1000 Mb/s (1 Gbit/s)' ;;
    '')   printf '%s' 'unknown' ;;
    *)    printf '%s Mb/s' "$mbps" ;;
  esac
}

_table_col_width() {
  local cur="$1" text="$2"
  (( ${#text} > cur )) && printf '%s' "${#text}" || printf '%s' "$cur"
}

# Physical ethernet candidates (global; filled by discover_physical_ethernet).
declare -a CAND_IFACE=() CAND_STATE=() CAND_SPEED=()

discover_physical_ethernet() {
  local iface state mbps label
  CAND_IFACE=()
  CAND_STATE=()
  CAND_SPEED=()

  for iface in /sys/class/net/*; do
    iface="$(basename "$iface")"
    iface_is_physical_ethernet "$iface" || continue
    state="$(iface_link_state "$iface")"
    if mbps="$(read_sysfs_speed_mbps "$iface" 2>/dev/null)"; then
      label="$(format_speed_label "$mbps")"
    else
      label='unknown'
    fi
    CAND_IFACE+=( "$iface" )
    CAND_STATE+=( "$state" )
    CAND_SPEED+=( "$label" )
  done
}

print_physical_nic_table() {
  local name_w=9 state_w=5 speed_w=5 i sep

  discover_physical_ethernet

  if (( ${#CAND_IFACE[@]} == 0 )); then
    echo "No physical ethernet interfaces found (virtual/bridge/wifi skipped)."
    return 1
  fi

  name_w=$(_table_col_width 9 'INTERFACE')
  state_w=$(_table_col_width 5 'STATE')
  speed_w=$(_table_col_width 5 'CURRENT SPEED')

  for i in "${!CAND_IFACE[@]}"; do
    name_w=$(_table_col_width "$name_w" "${CAND_IFACE[$i]}")
    state_w=$(_table_col_width "$state_w" "${CAND_STATE[$i]}")
    speed_w=$(_table_col_width "$speed_w" "${CAND_SPEED[$i]}")
  done

  echo "Physical ethernet link(s) that can be renegotiated (ethtool):"
  echo

  printf '%-*s  %-*s  %-*s\n' \
    "$name_w" 'INTERFACE' "$state_w" 'STATE' "$speed_w" 'CURRENT SPEED'
  sep="$(printf '%*s' "$(( name_w + state_w + speed_w + 4 ))" '' | tr ' ' '-')"
  printf '%s\n' "$sep"

  for i in "${!CAND_IFACE[@]}"; do
    printf '%-*s  %-*s  %-*s\n' \
      "$name_w" "${CAND_IFACE[$i]}" \
      "$state_w" "${CAND_STATE[$i]}" \
      "$speed_w" "${CAND_SPEED[$i]}"
  done
  echo
  return 0
}

prompt_yes_no() {
  local prompt="$1" answer
  printf '%s' "$prompt"
  read -r -n 1 answer || answer=
  echo
  [[ "$answer" == [yY] ]]
}

# Save ethtool snapshot; apply target speed; on failure call revert function.
save_ethtool_settings() {
  local iface="$1"
  ETHTOOL_SAVE_FILE="$(mktemp)"
  ethtool "$iface" >"$ETHTOOL_SAVE_FILE" 2>&1 || true
}

revert_ethtool_settings() {
  local iface="$1" speed duplex autoneg
  [[ -f "${ETHTOOL_SAVE_FILE:-}" ]] || return 1

  speed="$(awk -F': ' '/^[[:space:]]*Speed:/ {print $2}' "$ETHTOOL_SAVE_FILE" | head -1)"
  duplex="$(awk -F': ' '/^[[:space:]]*Duplex:/ {print $2}' "$ETHTOOL_SAVE_FILE" | head -1 | tr -d ' ')"
  autoneg="$(awk -F': ' '/^[[:space:]]*Auto-negotiation:/ {print $2}' "$ETHTOOL_SAVE_FILE" | head -1 | tr -d ' ')"

  echo "  Reverting ${iface} to previous settings (from saved ethtool output)..."

  case "$speed" in
    *1000*|*1G*)
      ethtool -s "$iface" speed 1000 duplex full autoneg on 2>/dev/null \
        || ethtool -s "$iface" autoneg on 2>/dev/null || true
      ;;
    *100*|*0.1G*)
      ethtool -s "$iface" speed 100 duplex full autoneg on 2>/dev/null \
        || ethtool -s "$iface" autoneg on 2>/dev/null || true
      ;;
    *10*)
      ethtool -s "$iface" speed 10 duplex full autoneg on 2>/dev/null \
        || ethtool -s "$iface" autoneg on 2>/dev/null || true
      ;;
    *)
      if [[ "$autoneg" == on ]]; then
        ethtool -s "$iface" autoneg on 2>/dev/null || true
      else
        ethtool -s "$iface" autoneg off 2>/dev/null || true
      fi
      ;;
  esac
  sleep 2
  rm -f "${ETHTOOL_SAVE_FILE:-}"
}

apply_target_speed() {
  local iface="$1" mbps="$2"
  echo "  Applying target ${mbps} Mb/s (autoneg on, then forced if needed)..."
  ethtool -s "$iface" autoneg on 2>/dev/null || true
  sleep 2
  if ! ethtool -s "$iface" speed "$mbps" duplex full autoneg on 2>/dev/null; then
    ethtool -s "$iface" speed "$mbps" duplex full autoneg off 2>/dev/null || true
  fi
  sleep 3
}

show_iface_speed_now() {
  local iface="$1" mbps
  if mbps="$(read_sysfs_speed_mbps "$iface" 2>/dev/null)"; then
    echo "  Link speed now: $(format_speed_label "$mbps")"
  else
    echo "  Link speed now: $(ethtool "$iface" 2>/dev/null | awk -F': ' '/Speed:/ {print $2; exit}')"
  fi
}

ping_test_ok() {
  local host="$1" timeout_sec="$2"
  local start=$SECONDS ok=no
  while (( SECONDS - start < timeout_sec )); do
    if ping -c 1 -W 2 "$host" &>/dev/null; then
      ok=yes
      break
    fi
    sleep 2
  done
  [[ "$ok" == yes ]]
}

renegotiate_one_iface() {
  local iface="$1"
  echo
  echo "=== ${iface}: target ${TARGET_MBPS} Mb/s, ping ${PING_TARGET}, timeout ${PING_TIMEOUT_SEC}s ==="

  save_ethtool_settings "$iface"
  echo "  Saved ethtool state to ${ETHTOOL_SAVE_FILE}"
  show_iface_speed_now "$iface"

  apply_target_speed "$iface" "$TARGET_MBPS"
  show_iface_speed_now "$iface"

  echo "  Testing ping to ${PING_TARGET} (up to ${PING_TIMEOUT_SEC}s)..."
  if ping_test_ok "$PING_TARGET" "$PING_TIMEOUT_SEC"; then
    echo "  OK: ping succeeded — keeping ${TARGET_MBPS} Mb/s settings on ${iface}."
    show_iface_speed_now "$iface"
    rm -f "${ETHTOOL_SAVE_FILE:-}"
    return 0
  fi

  echo "  FAIL: no successful ping within ${PING_TIMEOUT_SEC}s."
  revert_ethtool_settings "$iface"
  show_iface_speed_now "$iface"
  return 1
}

run_worker() {
  local iface fail=0

  if (( ${#WORKER_IFACES[@]} == 0 )); then
    echo "No interfaces specified for --run (put interface name(s) immediately after --run)." >&2
    return 1
  fi

  check_if_installed ethtool
  check_if_installed ping iputils-ping
  ensure_screen_bin 2>/dev/null || true

  echo "Renegotiation worker in screen session '${SCREEN_SESSION_NAME}'"
  echo "Host: $(hostname 2>/dev/null || echo '?')  Target: ${TARGET_MBPS} Mb/s  Ping: ${PING_TARGET}"
  echo

  for iface in "${WORKER_IFACES[@]}"; do
    if ! iface_is_physical_ethernet "$iface"; then
      echo "SKIP: ${iface} is not a physical ethernet interface."
      (( ++fail ))
      continue
    fi
    renegotiate_one_iface "$iface" || (( ++fail ))
  done

  echo
  if (( fail == 0 )); then
    echo "(PGM) All interface test(s) completed successfully."
  else
    echo "(PGM) Finished with ${fail} failure(s) or skip(s)."
    kod_powrotu=1
  fi

  echo
  echo "Detach from screen: Ctrl-A then D   |   Reattach: ${SCREEN_BIN:-screen} -c ${SCREEN_NO_RC} -r ${SCREEN_SESSION_NAME}"
  if [[ -t 0 ]]; then
    read -r -n 1 -s -p "Press any key to close this screen window... " _
    echo
  fi
}

launch_screen_worker() {
  local script_path="$0"
  local -a cmd
  local iface
  if command -v readlink >/dev/null 2>&1; then
    script_path="$(readlink -f "$0" 2>/dev/null)" || script_path="$0"
  fi
  # Interface names must follow --run immediately (parser stops at first -option).
  cmd=( bash "$script_path" --run )
  for iface in "${WORKER_IFACES[@]}"; do
    cmd+=( "$iface" )
  done
  cmd+=( --no_startup_delay -t "$PING_TIMEOUT_SEC" -p "$PING_TARGET" -s "$TARGET_MBPS" )

  if ! ensure_screen_bin; then
    echo "ERROR: GNU screen is required but no screen binary was found." >&2
    return 1
  fi
  if declare -F screen >/dev/null 2>&1; then
    echo "Note: shell function 'screen' is defined; using binary: ${SCREEN_BIN}"
  fi

  if "$SCREEN_BIN" -list 2>/dev/null | grep -q "[[:space:]]*[0-9]*\.${SCREEN_SESSION_NAME}[[:space:]]"; then
    echo "Screen session '${SCREEN_SESSION_NAME}' already exists."
    echo "Attach: ${SCREEN_BIN} -c ${SCREEN_NO_RC} -r ${SCREEN_SESSION_NAME}"
    echo "Or remove it first: ${SCREEN_BIN} -c ${SCREEN_NO_RC} -S ${SCREEN_SESSION_NAME} -X quit"
    return 1
  fi

  echo "Starting screen session '${SCREEN_SESSION_NAME}'..."
  if ! "$SCREEN_BIN" -c "$SCREEN_NO_RC" -dmS "$SCREEN_SESSION_NAME" "${cmd[@]}"; then
    echo "ERROR: failed to start screen session." >&2
    return 1
  fi
  sleep 0.3
  if ! "$SCREEN_BIN" -list 2>/dev/null | grep -qE "[[:space:]]+[0-9]+\\.${SCREEN_SESSION_NAME}([[:space:]]|$)"; then
    echo "ERROR: screen session '${SCREEN_SESSION_NAME}' exited immediately." >&2
    echo "Worker command: ${cmd[*]}" >&2
    echo "Run manually to see errors: ${cmd[*]}" >&2
    return 1
  fi
  echo
  echo "Worker started. Attach to watch progress:"
  echo "  ${SCREEN_BIN} -c ${SCREEN_NO_RC} -r ${SCREEN_SESSION_NAME}"
  echo
  return 0
}

interactive_main() {
  local i found=0

  check_if_installed ethtool
  check_if_installed ping iputils-ping
  ensure_screen_bin || check_if_installed screen

  if ! print_physical_nic_table; then
    kod_powrotu=1
    return 1
  fi

  WORKER_IFACES=()

  if [[ -n "$CLI_IFACE" ]]; then
    for i in "${!CAND_IFACE[@]}"; do
      if [[ "${CAND_IFACE[$i]}" == "$CLI_IFACE" ]]; then
        found=1
        break
      fi
    done
    if (( found == 0 )); then
      echo "ERROR: -i ${CLI_IFACE} is not a physical ethernet interface on this host." >&2
      kod_powrotu=1
      return 1
    fi
    WORKER_IFACES=( "$CLI_IFACE" )
  else
    WORKER_IFACES=( "${CAND_IFACE[@]}" )
  fi

  echo "Planned action:"
  echo "  - Renegotiate to ${TARGET_MBPS} Mb/s (ethtool)"
  echo "  - Verify ping to ${PING_TARGET} within ${PING_TIMEOUT_SEC}s per interface"
  echo "  - Revert to previous settings if ping fails"
  echo "  - Run inside screen session: ${SCREEN_SESSION_NAME}"
  echo "  - Interface(s): ${WORKER_IFACES[*]}"
  echo

  if ! prompt_yes_no "Proceed with link renegotiation test? [y/N]: "; then
    echo "Cancelled — no changes made."
    return 0
  fi

  launch_screen_worker || kod_powrotu=1
}

if (( RUN_WORKER == 1 )); then
  run_worker
  exit "${kod_powrotu}"
fi

interactive_main
exit "${kod_powrotu}"
