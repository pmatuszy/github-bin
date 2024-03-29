#!/bin/bash

# 2023.03.07 - v. 0.6 - added check if fstrim is installed
# 2023.02.28 - v. 0.5 - curl with kod_powrotu
# 2023.02.16 - v. 0.4 - added script version and current time
# 2023.01.03 - v. 0.3 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.04.30 - v. 0.2 - added healthcheck support
# 2021.02.24 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/start 2>/dev/null
fi

check_if_installed fstrim util-linux

HC_message=$( 
  echo "${SCRIPT_VERSION}" ; echo 
  /sbin/fstrim  --verbose --all 2>&1
  exit $?
  )
kod_powrotu=$?

echo "$HC_message" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${kod_powrotu}

######
template crontab entry:

@reboot        ( sleep 45 && /root/bin/ssd-trim.sh) 2>&1
0 */4 * * *    /root/bin/ssd-trim.sh
