#!/bin/bash

# 2025.07.06 - v. 0.8 - bugfix - how_many_retries was not decremented... so script was running sometimes forever
# 2024.04.02 - v. 0.7 - added timeout command (as curl sometimes doesn't timeout )
# 2023.04.13 - v. 0.6 - added how_many_retries and retry_delay
# 2023.01.17 - v. 0.5 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.16 - v. 0.3 - commented out sending emails sections
# 2022.05.03 - v. 0.2 - added healthcheck support
# 2021.xx.xx - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export URL="www.ontsolutions.com"  ; export URL
blad=1
how_many_retries=10
retry_delay=15

curl_retry=1
curl_retry_delay=3

export timeout=20
export kill_after=30

while (( $blad != 0 && $how_many_retries != 0 )) ; do
  if [ $(/usr/bin/timeout --foreground --preserve-status --kill-after=$kill_after $timeout wget $URL -qO - |grep "Directory Listing"|wc -l) -gt 0 ];then
    /usr/bin/timeout --foreground --preserve-status --kill-after=$kill_after $timeout /usr/bin/curl -fsS -m 100 --retry $curl_retry --retry-delay $curl_retry_null "$HEALTHCHECK_URL" 2>/dev/null
    blad=0
    break
  else
    sleep $retry_delay
    ((how_many_retries--))
    if (( script_is_run_interactively == 1 ));then
       echo sleeping for $retry_delay
    fi
  fi
done

if (( $blad != 0 ));then
   /usr/bin/timeout --foreground --preserve-status --kill-after=$kill_after $timeout /usr/bin/curl -fsS -m 100 --retry $how_many_retries  --retry-delay $retry/null "$HEALTHCHECK_URL"/fail 2>/dev/null
fi

. /root/bin/_script_footer.sh

exit $?

#####
# new crontab entry

*/5 * * * *  /usr/bin/flock --nonblock --exclusive /root/bin/sprawdz-czy-dziala-strona-www.ontsolutions.com.sh -c /root/bin/sprawdz-czy-dziala-strona-www.ontsolutions.com.sh
