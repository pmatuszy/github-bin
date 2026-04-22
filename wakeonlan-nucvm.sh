#!/bin/bash

# 2026.04.22 - v. 0.9 - verify same LAN and broadcast vs kernel before sending WOL
# 2026.04.22 - v. 0.8 - remote host 192.168.200.220 (NUC VM MAC c0:3f:d5:60:73:6b)
# 2025.05.08 - v. 0.7 - added configurable max_attempts and smarter WOL loop
# 2025.05.08 - v. 0.6 - improved logic to stop wakeonlan attempts as soon as host responds to ping
# 2025.04.25 - v. 0.5 - cosmetic improvements
# 2023.10.18 - v. 0.4 - initial check if wake is needed
# 2023.10.02 - v. 0.3 - added ping at the end
# 2023.03.07 - v. 0.2 - added check for wakeonlan package
# 2023.01.29 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed wakeonlan

delay=2
max_attempts=30
# Remote host (NUC VM)
IP=192.168.200.220
MAC="c0:3f:d5:60:73:6b"
BROADCAST="192.168.200.255"

# Require Linux ip(8): confirm this host shares the target's broadcast domain and BROADCAST matches the iface.
validate_wol_network_or_exit() {
  local target_ip="$1" configured_brd="$2"
  local route_line dev src brd_on_src

  if ! command -v ip >/dev/null 2>&1; then
    echo "(PGM) ERROR: 'ip' not found; cannot verify local network. Install iproute2 or run from a full Linux host." >&2
    exit 1
  fi

  route_line="$(ip -4 route get "$target_ip" 2>/dev/null | head -n1 || true)"
  if [[ -z "$route_line" ]]; then
    echo "(PGM) ERROR: no IPv4 route to $target_ip. Is this machine on the same network as the host to wake?" >&2
    exit 1
  fi

  dev="$(awk '{ for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit } }' <<< "$route_line")"
  src="$(awk '{ for (i = 1; i < NF; i++) if ($i == "src") { print $(i + 1); exit } }' <<< "$route_line")"

  if [[ -z "$dev" ]]; then
    echo "(PGM) ERROR: could not determine output interface for $target_ip from: $route_line" >&2
    exit 1
  fi

  if [[ -z "$src" ]]; then
    echo "(PGM) ERROR: kernel route to $target_ip has no local 'src' address. Wake-on-LAN must be run from a host on the same LAN segment as $target_ip (same broadcast domain), not via remote SSH on another subnet." >&2
    exit 1
  fi

  IFS=. read -r t1 t2 t3 _ <<< "$target_ip"
  IFS=. read -r s1 s2 s3 _ <<< "$src"
  if [[ "$t1.$t2.$t3" != "$s1.$s2.$s3" ]]; then
    echo "(PGM) ERROR: this machine is not on the same /24 subnet as $target_ip (outgoing address is $src on $dev). Run this script from a host on ${t1}.${t2}.${t3}.x so the magic packet reaches the sleeping NIC." >&2
    exit 1
  fi

  brd_on_src="$(ip -4 addr show dev "$dev" 2>/dev/null | awk -v want="$src" '
    $1 == "inet" {
      split($2, a, "/")
      if (a[1] == want) {
        for (i = 1; i <= NF; i++) if ($i == "brd") { print $(i + 1); exit }
      }
    }
  ')"

  if [[ -z "$brd_on_src" ]]; then
    echo "(PGM) WARNING: could not read broadcast (brd) for $src on $dev; cannot verify BROADCAST=$configured_brd (continuing)." >&2
    return 0
  fi

  if [[ "$brd_on_src" != "$configured_brd" ]]; then
    echo "(PGM) ERROR: configured BROADCAST=$configured_brd does not match this system's broadcast on $dev for $src (kernel has brd $brd_on_src). Update BROADCAST in this script to $brd_on_src." >&2
    exit 1
  fi

  echo "(PGM) Network check OK: using $dev ($src), broadcast $configured_brd matches kernel."
}

validate_wol_network_or_exit "$IP" "$BROADCAST"

# Check if already up
ping -c 2 -W 2 -q "${IP}" >/dev/null
if (( $? == 0 )); then
  echo
  echo "(PGM) Host $IP is already up. No need to start it again..."
  echo
  exit 0
fi

# Try to wake up
for ((p=1; p<=max_attempts; p++)); do
  wakeonlan -i "$BROADCAST" "$MAC"
  echo "(PGM) Sent WOL packet attempt #$p. Waiting $delay seconds..."
  sleep "$delay"

  # Check if host is already awake
  if ping -c 1 -W 1 "$IP" >/dev/null; then
    echo "(PGM) Host $IP is now responding after $p WOL attempt(s)."
    break
  fi
done

# Final verification
if ping -c 3 -W 1 "$IP" ; then
  echo "(PGM) Host $IP successfully woke up."
else
  echo "(PGM) Host $IP did not respond after WOL attempts."
fi

logger "WOL script: sent packet to $MAC at $BROADCAST"

. /root/bin/_script_footer.sh

