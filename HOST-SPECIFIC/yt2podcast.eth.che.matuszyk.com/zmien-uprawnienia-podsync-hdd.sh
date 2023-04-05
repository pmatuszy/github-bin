#!/bin/bash

# 2023.04.06 - v. 0.3 - excluding temp dir /podsync-hdd/_temp/
# 2021.02.07 - v. 0.2 - spr. czy nie ma wiecej dzialajacych instancji skryptu....
# 2020.xx.xx - v. 0.1 - initial release

# w dniu 21.01.2021 dodalem 2>/dev/null na koncu kazdego find'a by nie dostawac co jakis czas maili, ze plik nie istnieje z crontaba

# spr. ile jest dzialajacych instancji - jesli wiecej niz jedna to my wychodzimy
if [[ `ps -e|grep $0` -gt 1 ]]; then
  exit 2
fi

find /podsync-hdd/ -type f ! -group www-data -regex '.*\.\(mp3\|mp4\|webm\|xml\|m4a\)' -exec chgrp -v www-data {} \; 2>/dev/null
find /podsync-hdd/ -type f ! -perm 640       -regex '.*\.\(mp3\|mp4\|webm\|xml\|m4a\)' -exec chmod -v 640 {} \;      2>/dev/null
find /podsync-hdd/ -type d ! -wholename \*_temp\* ! -perm 750       -exec chmod 750 -v {} \;                         2>/dev/null
find /podsync-hdd/ -type d ! -wholename \*_temp\* ! -group www-data -exec chgrp www-data -v {} \;                    2>/dev/null
