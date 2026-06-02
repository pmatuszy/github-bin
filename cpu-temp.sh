#!/bin/bash

# 2026.06.02 - v. 0.2 - require readable thermal_zone0; EXIT trap runs footer; modern $(date) / quoted paths
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

THERMAL_ZONE_TEMP=/sys/class/thermal/thermal_zone0/temp

if [[ ! -r "$THERMAL_ZONE_TEMP" ]]; then
  echo "ERROR: cannot read CPU temperature from $THERMAL_ZONE_TEMP (not available on this hardware?)"
  exit 1
fi

cpu_temp_cleanup() {
  . /root/bin/_script_footer.sh
}
trap cpu_temp_cleanup EXIT

while : ; do
  echo "$(date '+%Y-%m-%d %H:%M:%S')" "$(awk '{printf "%3.1f C\n", $1/1000}' "$THERMAL_ZONE_TEMP")"
  sleep 3
done
