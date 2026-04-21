#!/bin/bash

# 2026.04.21 - v. 0.2 - add script history header and fix SCSI rescan write payload
# 2023.01.14 - v. 0.1 - initial release

for p in /sys/class/scsi_host/host*; do
  echo "scan for $p"
  echo "- - -" > "$p/scan"
done
