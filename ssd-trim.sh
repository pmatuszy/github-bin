#!/bin/bash

# 2023.02.16 - v. 0.4 - added script version and current time
# 2023.01.03 - v. 0.3 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.04.30 - v. 0.2 - added healthcheck support
# 2021.02.24 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/start 2>/dev/null
fi

HC_message=$( 
  echo "${SCRIPT_VERSION}" ; echo 
  /sbin/fstrim  --verbose --all 2>&1
  )

if [ -f "$HEALTHCHECKS_FILE" ];then
  echo "$HC_message" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit $?

######
template crontab entry:

@reboot        ( sleep 45 && /root/bin/ssd-trim.sh) 2>&1
0 */4 * * *    /root/bin/ssd-trim.sh
