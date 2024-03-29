#!/bin/bash

# 2023.11.05 - v. 0.3 - dodano sprawdzanie, czy pakiet apcupsd jest zainstalowany
# 2023.01.16 - v. 0.2 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.09 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

check_if_installed apcupsd

# spr. czy nie ma bledow
if [ $(/usr/bin/env apcaccess | egrep "STATUS   : ONLINE *$"|wc -l) -eq 0 ];then
  m=$( /usr/bin/env apcaccess 2>&1)
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  m=$( /usr/bin/env apcaccess 2>&1| egrep "STATUS   : ONLINE *")
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit $?


# wysylanie info o statusie APC ups'a
0 * * * *    /root/bin/apc-status.sh
