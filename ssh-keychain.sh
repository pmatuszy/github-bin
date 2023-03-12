#!/bin/bash

# 2023.03.12 - v. 0.5 - added possibility to load more keys (variable klucze)
# 2023.03.03 - v. 0.4 - added sleep 1 as sometimes checking keychain shows nothing...
# 2023.02.28 - v. 0.3 - curl with kod_powrotu
# 2023.02.16 - v. 0.2 - major overhaul of the script 
# 2023.02.08 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi
export warnings_and_errors=0

# eval keychain -q --nogui --nocolor --eval id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH >/dev/null 2>&1

if [ -f $HOME/.keychain/$HOSTNAME-sh ];then
  . $HOME/.keychain/$HOSTNAME-sh
fi

check_if_installed keychain

klucze=""

if [ -f $HOME/.ssh/id_backupy_ed25519 ]; then
  klucze="id_backupy_ed25519 id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH"
else
  klucze="id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH"
fi

export klucze

HC_message=$(
  warnings_and_errors=0

  cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}'
  echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ;
  keychain  --nocolor ${klucze} 2>&1 | egrep -iq "warning|error"
  
  if (( $? == 0 )); then               # exit status = 0 oznacza, ze linie ZNALEZIONO, wiec jest blad
    let warnings_and_errors=warnings_and_errors+1
    keychain  --nocolor  ${klucze} 2>&1 | egrep -i "warning|error"
    echo "(PGM) NOT all 3 keys are loaded - PROBLEM " | boxes -s 50x3 -a c -d ada-box
    echo ;  echo
  else
    echo "(PGM) 3 keys are loaded - looks GOOD" | boxes -s 50x3 -a c -d ada-box
  fi

  echo "keychain --nogui --nocolor ${klucze}"
        keychain --nogui --nocolor ${klucze} 2>&1
  
  how_many=$(keychain --nogui --nocolor ${klucze} 2>&1 | \
             egrep -i "Known ssh key: .*/id_rsa|Known ssh key: .*/id_SSH_ed25519_20230207_OpenSSH|Known ssh key: .*/id_ed25519" | wc -l)
  
  if (( $how_many != 3 )); then
    let warnings_and_errors=warnings_and_errors+1
    echo "(PGM) NOT all 3 keys are known - PROBLEM" | boxes -s 50x3 -a c -d ada-box
  else
    echo "(PGM) all 3 keys are known - looks GOOD" | boxes -s 50x3 -a c -d ada-box
  fi
  
  echo ; echo 
  sleep 1
  echo keychain --nogui --nocolor -l | boxes -s 50x3 -a c -d ada-box
       keychain --nogui --nocolor -l 2>&1
  echo
  exit $warnings_and_errors
)
kod_powrotu=$?

if (( script_is_run_interactively )) ;then
  echo "$HC_message"
fi

echo "$HC_message" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${kod_powrotu}

#####
# new crontab entry

@reboot ( sleep 55 && /root/bin/ssh-keychain.sh )

0 * * * *    /root/bin/ssh-keychain.sh
