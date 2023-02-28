#!/bin/bash

# 2023.02.28 - v. 0.4 - curl with kod_powrotu
# 2023.01.03 - v. 0.3 - dodano random delay jesli skrypt jest wywolywany nieinteraktywnie
# 2022.05.12 - v. 0.2 - usunieta zmienna m, ktora nie byla uzywana
# 2022.05.03 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

mountpoint -q /encrypted
kod_powrotu=$?

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${kod_powrotu}
#####
# new crontab entry

6 * * * * /root/bin/sprawdz-czy-encrypted-jest-zamontowany.sh
