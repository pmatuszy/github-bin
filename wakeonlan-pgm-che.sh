#!/bin/bash

# 2026.04.21 - v. 0.9 - WOL_* env overrides; rename target to WOL_HOST; -q loop ping; richer logger; validate inputs; footer on early-up path
# 2026.04.21 - v. 0.8 - exit 1 when host still down after WOL; quiet consistent final ping for exit status
# 2025.05.08 - v. 0.7 - added configurable max_attempts and smarter WOL loop
# 2025.05.08 - v. 0.6 - improved logic to stop wakeonlan attempts as soon as host responds to ping
# 2025.04.25 - v. 0.5 - cosmetic improvements
# 2023.10.18 - v. 0.4 - initial check if wake is needed
# 2023.10.02 - v. 0.3 - added ping at the end
# 2023.03.07 - v. 0.2 - added check for wakeonlan package
# 2023.01.29 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed wakeonlan

# Override with e.g. WOL_HOST=other.example.com WOL_MAC='aa:bb:...' WOL_BROADCAST=192.168.1.255
: "${WOL_DELAY:=2}"
: "${WOL_MAX_ATTEMPTS:=30}"
: "${WOL_HOST:=pgm-che.eth.che.matuszyk.com}"
: "${WOL_MAC:=04:D9:F5:60:42:4A}"
: "${WOL_BROADCAST:=192.168.200.255}"

if [[ -z "$WOL_HOST" || -z "$WOL_MAC" || -z "$WOL_BROADCAST" ]]; then
  echo "(PGM) WOL_HOST, WOL_MAC, and WOL_BROADCAST must be non-empty." >&2
  exit 2
fi
if ! [[ "$WOL_DELAY" =~ ^[0-9]+$ ]] || ! [[ "$WOL_MAX_ATTEMPTS" =~ ^[0-9]+$ ]] || (( WOL_DELAY < 1 || WOL_MAX_ATTEMPTS < 1 )); then
  echo "(PGM) WOL_DELAY and WOL_MAX_ATTEMPTS must be positive integers." >&2
  exit 2
fi

# Check if already up
if ping -c 2 -W 2 -q "$WOL_HOST" >/dev/null; then
  echo
  echo "(PGM) Host $WOL_HOST is already up. No need to start it again..."
  echo
  logger "WOL script: host=$WOL_HOST result=already_up (no WOL packets sent)"
  . /root/bin/_script_footer.sh
  exit 0
fi

wol_packets_sent=0

# Try to wake up
for ((p = 1; p <= WOL_MAX_ATTEMPTS; p++)); do
  wakeonlan -i "$WOL_BROADCAST" "$WOL_MAC"
  wol_packets_sent=$p
  echo "(PGM) Sent WOL packet attempt #$p. Waiting $WOL_DELAY seconds..."
  sleep "$WOL_DELAY"

  # Check if host is already awake
  if ping -c 1 -W 1 -q "$WOL_HOST" >/dev/null; then
    echo "(PGM) Host $WOL_HOST is now responding after $p WOL attempt(s)."
    break
  fi
done

# Final verification (quiet: we only need exit status for automation)
wol_rc=0
if ping -c 3 -W 1 -q "$WOL_HOST" >/dev/null 2>&1; then
  echo "(PGM) Host $WOL_HOST successfully woke up."
else
  echo "(PGM) Host $WOL_HOST did not respond after WOL attempts."
  wol_rc=1
fi

if (( wol_rc == 0 )); then
  logger "WOL script: host=$WOL_HOST mac=$WOL_MAC bcast=$WOL_BROADCAST wol_packets_sent=$wol_packets_sent result=ok"
else
  logger "WOL script: host=$WOL_HOST mac=$WOL_MAC bcast=$WOL_BROADCAST wol_packets_sent=$wol_packets_sent result=fail"
fi

. /root/bin/_script_footer.sh

exit "$wol_rc"
