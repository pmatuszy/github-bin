#!/bin/bash

# 2023.02.10 - v. 0.1 - initial release

. /root/bin/_script_header.sh

mail_subject="(`/bin/hostname`-`date '+%Y.%m.%d %H:%M:%S'`) logwatch"
mail_recipient=matuszyk+`/bin/hostname`@matuszyk.com
details_level=${1:-low}

{

check_if_installed mailx
check_if_installed strings
check_if_installed aha

/usr/sbin/logwatch --detail "${details_level}" 
} | strings | aha | mailx -a 'Content-Type: text/html' -s "${mail_subject}"  ${mail_recipient}

. /root/bin/_script_footer.sh

exit
#####
# new crontab entry

0 5 * * *   /root/bin/logwatch-send.sh      # optional $1 level can be a positive integer, or high, med, low, which correspond to the integers 10, 5, and 0, respectively.
