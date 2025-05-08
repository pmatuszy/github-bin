#!/bin/bash

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
IP=pgm-che.eth.che.matuszyk.com
MAC="04:D9:F5:60:42:4A"
BROADCAST="192.168.200.255"

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

