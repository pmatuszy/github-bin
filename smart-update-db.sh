#!/bin/bash

# 2023.02.10 - v. 0.3 - added check for smartmontools package
# 2023.02.01 - v. 0.2 - initial release
# 2022.10.11 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed smartctl smartmontools

echo
update-smart-drivedb
echo 

. /root/bin/_script_footer.sh
