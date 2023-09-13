#!/bin/bash

# 2023.09.13 - v. 0.2 - added invocation of script_header and script_footer
# 2022.12.02 - v. 0.1 - inicjalna wersja skryptu

. /root/bin/_script_header.sh

echo "Your system is $(getconf LONG_BIT)-bit" ; echo

. /root/bin/_script_footer.sh
