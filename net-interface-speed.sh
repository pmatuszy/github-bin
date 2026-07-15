#!/bin/bash

# 2026.06.02 - v. 0.2 - table: compute column widths from all rows (incl. long speed labels); align all four columns
# 2026.06.02 - v. 0.1 - initial release: list network interfaces with link state and speed (10/100/1000 Mb/s etc.) via sysfs; ethtool fallback when speed is unknown

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

Print a table of network interfaces with link state and negotiated link speed.

Works on x86 and Raspberry Pi (and other Linux systems) using
/sys/class/net/<iface>/speed (megabits per second). Common values are shown
as 10 / 100 / 1000 Mb/s; faster links show their rate. When sysfs reports an
unknown speed (-1), ethtool is used as a fallback if installed.

Skipped: loopback (lo). Virtual interfaces (no device in sysfs) are listed
with a "virtual" note.

Columns:
  INTERFACE   interface name (e.g. eth0, enp0s31f6, wlan0)
  STATE       operstate (up, down, dormant, ...)
  SPEED       10 / 100 / 1000 Mb/s where applicable, or N Mb/s / unknown
  KIND        ethernet, wlan, virtual, ...

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay when run non-interactively
                       (see _script_header.sh).
EOF
}

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
      HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

net_iface_speed_cleanup() {
  . /root/bin/_script_footer.sh
}
trap net_iface_speed_cleanup EXIT

# Map sysfs speed (Mb/s integer) to a readable label.
format_link_speed() {
  local mbps="$1"
  case "$mbps" in
    ''|-1|65535|unknown)
      printf '%s' 'unknown'
      ;;
    10)
      printf '%s' '10 Mb/s'
      ;;
    100)
      printf '%s' '100 Mb/s'
      ;;
    1000)
      printf '%s' '1000 Mb/s (1 Gbit/s)'
      ;;
    2500)
      printf '%s' '2500 Mb/s (2.5 Gbit/s)'
      ;;
    10000)
      printf '%s' '10000 Mb/s (10 Gbit/s)'
      ;;
    *)
      if [[ "$mbps" =~ ^[0-9]+$ ]]; then
        printf '%s Mb/s' "$mbps"
      else
        printf '%s' 'unknown'
      fi
      ;;
  esac
}

# Read speed in Mb/s from sysfs, or empty if unreadable.
read_sysfs_link_speed_mbps() {
  local iface="$1" f="/sys/class/net/${iface}/speed"
  local v
  [[ -r "$f" ]] || return 1
  v="$(<"$f")"
  [[ "$v" =~ ^-?[0-9]+$ ]] || return 1
  if (( v < 0 || v == 65535 )); then
    return 1
  fi
  printf '%s' "$v"
}

# Parse "Speed: 1000Mb/s" from ethtool; print Mb/s integer or return 1.
read_ethtool_speed_mbps() {
  local iface="$1" line speed_raw n
  command -v ethtool >/dev/null 2>&1 || return 1
  line="$(ethtool "$iface" 2>/dev/null | awk -F': ' '/^[[:space:]]*Speed:/ {print $2; exit}')"
  [[ -n "$line" ]] || return 1
  if [[ "$line" =~ ([0-9]+)[[:space:]]*Mb/s ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi
  if [[ "$line" =~ ([0-9]+)[[:space:]]*Gb/s ]]; then
    n="${BASH_REMATCH[1]}"
    printf '%s' $(( n * 1000 ))
    return 0
  fi
  if [[ "$line" == Unknown! ]]; then
    return 1
  fi
  return 1
}

iface_link_state() {
  local iface="$1" st
  if [[ -r "/sys/class/net/${iface}/operstate" ]]; then
    st="$(<"/sys/class/net/${iface}/operstate")"
    printf '%s' "$st"
    return 0
  fi
  printf '%s' '?'
}

iface_is_virtual() {
  local iface="$1"
  [[ -e "/sys/class/net/${iface}/device" ]] && return 1
  return 0
}

iface_type_hint() {
  local iface="$1" t
  if iface_is_virtual "$iface"; then
    printf '%s' 'virtual'
    return 0
  fi
  if [[ -r "/sys/class/net/${iface}/type" ]]; then
    t="$(<"/sys/class/net/${iface}/type")"
    case "$t" in
      1)   printf '%s' 'ethernet' ;;
      772) printf '%s' 'loopback' ;;
      801) printf '%s' 'wlan' ;;
      65534) printf '%s' 'tunnel' ;;
      *)   printf '%s' "type ${t}" ;;
    esac
    return 0
  fi
  printf '%s' ''
}

resolve_iface_speed_mbps() {
  local iface="$1" v
  v="$(read_sysfs_link_speed_mbps "$iface" 2>/dev/null)" && { printf '%s' "$v"; return 0; }
  v="$(read_ethtool_speed_mbps "$iface" 2>/dev/null)" && { printf '%s' "$v"; return 0; }
  return 1
}

# Widen column width if text is longer (uses byte length; fine for interface names and ASCII labels).
_table_col_width() {
  local cur="$1" text="$2"
  (( ${#text} > cur )) && printf '%s' "${#text}" || printf '%s' "$cur"
}

print_interface_speed_table() {
  local iface state speed_mbps speed_label kind
  local -a ifaces=() row_iface=() row_state=() row_speed=() row_kind=()
  local name_w state_w speed_w kind_w
  local i sep

  mapfile -t ifaces < <(
    for d in /sys/class/net/*; do
      [[ -d "$d" ]] || continue
      basename "$d"
    done | LC_ALL=C sort
  )

  for iface in "${ifaces[@]}"; do
    [[ "$iface" == lo ]] && continue
    state="$(iface_link_state "$iface")"
    kind="$(iface_type_hint "$iface")"
    if speed_mbps="$(resolve_iface_speed_mbps "$iface")"; then
      speed_label="$(format_link_speed "$speed_mbps")"
    else
      speed_label='unknown (no link or N/A)'
    fi
    row_iface+=( "$iface" )
    row_state+=( "$state" )
    row_speed+=( "$speed_label" )
    row_kind+=( "$kind" )
  done

  if (( ${#row_iface[@]} == 0 )); then
    echo "No network interfaces found under /sys/class/net."
    return 1
  fi

  name_w=$(_table_col_width 9 'INTERFACE')
  state_w=$(_table_col_width 5 'STATE')
  speed_w=$(_table_col_width 5 'SPEED')
  kind_w=$(_table_col_width 4 'KIND')

  for i in "${!row_iface[@]}"; do
    name_w=$(_table_col_width "$name_w" "${row_iface[$i]}")
    state_w=$(_table_col_width "$state_w" "${row_state[$i]}")
    speed_w=$(_table_col_width "$speed_w" "${row_speed[$i]}")
    kind_w=$(_table_col_width "$kind_w" "${row_kind[$i]}")
  done

  printf '%-*s  %-*s  %-*s  %-*s\n' \
    "$name_w" 'INTERFACE' "$state_w" 'STATE' "$speed_w" 'SPEED' "$kind_w" 'KIND'

  sep="$(printf '%*s' "$(( name_w + state_w + speed_w + kind_w + 6 ))" '' | tr ' ' '-')"
  printf '%s\n' "$sep"

  for i in "${!row_iface[@]}"; do
    printf '%-*s  %-*s  %-*s  %-*s\n' \
      "$name_w" "${row_iface[$i]}" \
      "$state_w" "${row_state[$i]}" \
      "$speed_w" "${row_speed[$i]}" \
      "$kind_w" "${row_kind[$i]}"
  done
}

echo "Network interface link speeds ($(hostname 2>/dev/null || echo '?'))"
echo "Source: /sys/class/net/*/speed (Mb/s); ethtool fallback when needed"
echo

if ! print_interface_speed_table; then
  return_code=1
else
  return_code=0
fi

exit "${return_code:-0}"
