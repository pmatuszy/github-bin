#!/bin/bash

# 2023.02.28 - v. 0.4 - curl with kod_powrotu
# 2023.01.09 - v. 0.3 - added random delay support
# 2022.08.09 - v. 0.2 - added info about script version to the output 
# 2022.07.04 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

m=$( echo "${SCRIPT_VERSION}";echo ;
     cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo
     /usr/bin/geoipupdate -v 2>&1; exit $?
   )
kod_powrotu=$?

/usr/bin/curl -fsS -m 10 --retry 5 --retry-delay 5 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${kod_powrotu}
#####
# new crontab entry

5 7 * * * sleep $((RANDOM \% 50)) && /root/bin/healthchecks-geoipupdate.sh
