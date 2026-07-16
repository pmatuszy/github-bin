#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.04.06 - v. 0.3 - excluding temp dir /podsync-hdd/_temp/
# 2021.02.07 - v. 0.2 - spr. czy nie ma wiecej dzialajacych instancji skryptu....
# 2020.xx.xx - v. 0.1 - initial release

# 2021-01-21: 2>/dev/null on each find to avoid cron mails about missing files

# if more than one instance is running, exit
if [[ `ps -e|grep $0` -gt 1 ]]; then
  exit 2
fi

find /podsync-hdd/ -type f ! -group www-data -regex '.*\.\(mp3\|mp4\|webm\|xml\|m4a\)' -exec chgrp -v www-data {} \; 2>/dev/null
find /podsync-hdd/ -type f ! -perm 640       -regex '.*\.\(mp3\|mp4\|webm\|xml\|m4a\)' -exec chmod -v 640 {} \;      2>/dev/null
find /podsync-hdd/ -type d ! -wholename \*_temp\* ! -perm 750       -exec chmod 750 -v {} \;                         2>/dev/null
find /podsync-hdd/ -type d ! -wholename \*_temp\* ! -group www-data -exec chgrp www-data -v {} \;                    2>/dev/null


exit 

#### cron entry ####
* * * * *     ( /usr/bin/flock --nonblock --exclusive /root/bin/zmien-uprawnienia-podsync-hdd.sh -c /root/bin/zmien-uprawnienia-podsync-hdd.sh ) 2>&1 > /dev/null

