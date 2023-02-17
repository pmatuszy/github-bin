#!/bin/bash

# 2023.02.10 - v. 0.1 - initial release

. /root/bin/_script_header.sh

export mail_subject="(`/bin/hostname`-`date '+%Y.%m.%d %H:%M:%S'`) logwatch"
export mail_recipient=matuszyk+`/bin/hostname`@matuszyk.com
export details_level=${1:-low}
export range="${2:-yesterday}"

{
check_if_installed mailx
check_if_installed strings
check_if_installed aha

/usr/sbin/logwatch --detail "${details_level}" --range="${range}"
} | strings | aha | mailx -a 'Content-Type: text/html' -s "${mail_subject}" "${mail_recipient}"

. /root/bin/_script_footer.sh

exit $?
#####
# new crontab entry

0 5 * * *   /root/bin/logwatch-send.sh      # optional $1 level can be a positive integer, or high, med, low, which correspond to the integers 10, 5, and 0, respectively.
                                            # optional $2 range e.g. "between -7 days and today" or "yesterday and today"
