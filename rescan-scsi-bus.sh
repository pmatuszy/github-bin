#!/bin/bash

# 2026.04.22 - v. 0.3 - nullglob, root and scan-file checks, set -euo pipefail, exit status on failure
# 2026.04.21 - v. 0.2 - add script history header and fix SCSI rescan write payload
# 2023.01.14 - v. 0.1 - initial release
#
# Writes "- - -" to each host's scan sysfs knob (wildcard channel, id, LUN).
# For richer rescans (multipath, IDs), see sg3-utils: rescan-scsi-bus.sh

set -euo pipefail
shopt -s nullglob

if (( EUID != 0 )); then
  echo "$(basename "$0"): must run as root (writes to /sys/class/scsi_host/*/scan)." >&2
  exit 1
fi

hosts=( /sys/class/scsi_host/host* )
if ((${#hosts[@]} == 0)); then
  echo "$(basename "$0"): no /sys/class/scsi_host/host* entries (no SCSI HBAs?)." >&2
  exit 1
fi

failed=0
for p in "${hosts[@]}"; do
  if [[ ! -e "$p/scan" ]]; then
    echo "$(basename "$0"): skip (no scan knob): $p" >&2
    continue
  fi
  if [[ ! -w "$p/scan" ]]; then
    echo "$(basename "$0"): not writable: $p/scan" >&2
    ((++failed)) || true
    continue
  fi
  echo "scan: $p"
  echo '- - -' >"$p/scan" || { echo "$(basename "$0"): write failed: $p/scan" >&2; ((++failed)) || true; }
done

if (( failed > 0 )); then
  echo "$(basename "$0"): finished with $failed error(s)." >&2
  exit 1
fi
