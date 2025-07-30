#!/bin/bash

# 2025.07.30 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed figlet

while : ; do clear ; date +%Y_%m_%d' '%H:%M:%S | figlet -f banner -w 190 ; sleep 0.99 ; done

. /root/bin/_script_footer.sh

