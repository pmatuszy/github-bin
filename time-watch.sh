#!/bin/bash

# 2023.01.16 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed figlet watch

#watch -t -n1 "date '+%Y.%m.%d %H:%M:%S'|figlet -f banner"
watch -w -t -n0.1 "date '+%Y.%m.%d %H:%M:%S' | figlet -w 140 -f big"

. /root/bin/_script_footer.sh
