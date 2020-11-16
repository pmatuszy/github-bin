#!/bin/bash
# 2020.11.15 - v. 0.2 - removed stats for dm- devicse and -x option (not needed usually)
# 2020.11.11 - v. 0.1 - initial release

export S_COLORS=never 

iostat -cHd -t 1 -g luks-raid1-16tb sda sdb -g "luks-raid1     " sdc sdd -N

# -c     Display the CPU utilization report.
# -d     Display the device utilization report.
# -H     This option must be used with option -g and indicates that only global statistics for the group are to be displayed, and not statistics for individual devices in the group.
# -t     Print the time for each report displayed. The timestamp format may depend on the value of the S_TIME_FORMAT environment variable (see below).


