#!/bin/bash
# 2021.12.23 - v. 0.5 - added display of the initial description of the groups 
# 2020.11.17 - v. 0.4 - version for backupss server (specific groups of disks are named there)
# 2020.11.16 - v. 0.3 - version for backupche server (specific groups of disks are named there)
# 2020.11.15 - v. 0.2 - removed stats for dm- devicse and -x option (not needed usually)
# 2020.11.11 - v. 0.1 - initial release

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


