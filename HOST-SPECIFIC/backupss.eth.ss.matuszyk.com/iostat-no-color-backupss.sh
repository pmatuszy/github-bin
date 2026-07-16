#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay
# 2021.12.23 - v. 0.5 - added display of the initial description of the groups 
# 2020.11.17 - v. 0.4 - version for backupss server (specific groups of disks are named there)
# 2020.11.16 - v. 0.3 - version for backupche server (specific groups of disks are named there)
# 2020.11.15 - v. 0.2 - removed stats for dm- devicse and -x option (not needed usually)
# 2020.11.11 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

-c     Display the CPU utilization report.

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
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

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

export S_COLORS=never 

echo
echo "grupa luks-R1-encA to nastepujace urzadzenia:"

for p in  /dev/disk/by-id/scsi-SWDC_WD16_1KRYZ-01AGBB_000000000000000?; do 
 echo "   " $p
done

echo
echo "grupa luks-R1-encB to nastepujace urzadzenia:"
for p in /dev/disk/by-id/{wwn-0x5000c500bf23b8ce,wwn-0x50014ee057c2fd7f,wwn-0x50014ee206d2f67b,wwn-0x50014ee6ab33e0ad}  ; do
 echo "   " $p
done

echo
sleep 5 
iostat --dec=0  -cHd -t 1 -g luks-R1-encA /dev/disk/by-id/scsi-SWDC_WD16_1KRYZ-01AGBB_000000000000000? -g luks-R1-encB /dev/disk/by-id/{wwn-0x5000c500bf23b8ce,wwn-0x50014ee057c2fd7f,wwn-0x50014ee206d2f67b,wwn-0x50014ee6ab33e0ad} -N

# -c     Display the CPU utilization report.
# -d     Display the device utilization report.
# -H     This option must be used with option -g and indicates that only global statistics for the group are to be displayed, and not statistics for individual devices in the group.
# -t     Print the time for each report displayed. The timestamp format may depend on the value of the S_TIME_FORMAT environment variable (see below).


