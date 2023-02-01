#!/bin/bash

# 2023.02.01 - v. 0.2 - initial release
# 2022.10.11 - v. 0.1 - initial release

. /root/bin/_script_header.sh

echo ; echo ; cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo

echo
update-smart-drivedb
echo 

. /root/bin/_script_footer.sh
