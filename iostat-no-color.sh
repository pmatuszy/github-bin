#!/bin/bash
# 2020.11.11 - v. 0.1 - initial release

export S_COLORS=never 
iostat -x 1  -cd -t |grep -v '^loop'

# -c     Display the CPU utilization report.
# -d     Display the device utilization report.
# -H     This option must be used with option -g and indicates that only global statistics for the group are to be displayed, and not statistics for individual devices in the group.
# -t     Print the time for each report displayed. The timestamp format may depend on the value of the S_TIME_FORMAT environment variable (see below).


