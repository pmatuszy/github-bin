#!/bin/bash

# 2023.02.12 - v. 0.4 - added check for aha, mailutils and check if we are run interactively
# 2023.02.10 - v. 0.3 - added check for smartmontools package
# 2023.02.01 - v. 0.2 - initial release
# 2022.10.11 - v. 0.1 - initial release

. /root/bin/_script_header.sh

m=$(
  check_if_installed smartctl smartmontools
  check_if_installed aha
  check_if_installed mailx mailutils

  echo
  update-smart-drivedb
  echo
  )

if (( script_is_run_interactively ));then
  echo "$m"
else
  echo "$m" | strings | aha | \
    /usr/bin/mailx -r root@`hostname` -a 'Content-Type: text/html' -s "(`/bin/hostname`) /usr/sbin/update-smart-drivedb" matuszyk+`/bin/hostname`@matuszyk.com
fi 

. /root/bin/_script_footer.sh
