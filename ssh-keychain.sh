#!/bin/bash

# 2023.08.21 - v. 1.1 - added feature batchmode (parameter: batch)
# 2023.05.20 - v. 1.0 - added feature that more than 3 keys can be loaded (ile_kluczy_powinno_byc_zaladowanych)
# 2023.05.20 - v. 0.9 - bugfix: added that in ssh key: / is optional (with /?, it was / before)
# 2023.05.09 - v. 0.8 - changed sleep from 6 to 3 but added execution of $HOSTNAME-sh before that
# 2023.05.01 - v. 0.7 - extended sleep from 3 to 6s 
# 2023.03.13 - v. 0.6 - bugfix for a number of known kesy (!= changed to < )
# 2023.03.12 - v. 0.5 - added possibility to load more keys (variable klucze)
# 2023.03.03 - v. 0.4 - added sleep 1 as sometimes checking keychain shows nothing...
# 2023.02.28 - v. 0.3 - curl with kod_powrotu
# 2023.02.16 - v. 0.2 - major overhaul of the script 
# 2023.02.08 - v. 0.1 - initial release


batch_mode=0

if (( $# != 0 )) && [ "${1-nonbatch}" == "batch" ]; then
  echo ; echo "(PGM) enabling batch mode (no questions asked)"
  batch_mode=1
  . /root/bin/_script_header.sh NO_STARTUP_DELAY
else
  . /root/bin/_script_header.sh
fi

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

if [ -f $HOME/.ssh/id_ed25519_backupy ]; then
  klucze="id_ed25519_backupy id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH"
else
  klucze="id_rsa id_ed25519 id_SSH_ed25519_20230207_OpenSSH"
fi

if [ -f $HOME/.ssh/id_ed25519_kopiowanie_scp ]; then
  klucze="$klucze id_ed25519_kopiowanie_scp" 
fi

export klucze

ile_kluczy_powinno_byc_zaladowanych=$(echo $klucze | wc -w)

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
             egrep -i "Known ssh key: .*/?id_rsa|Known ssh key: .*/?id_SSH_ed25519_20230207_OpenSSH|Known ssh key: .*/?id_ed25519" | wc -l)
  
  if (( $how_many < $ile_kluczy_powinno_byc_zaladowanych )); then
    let warnings_and_errors=warnings_and_errors+1
    echo "(PGM) NOT all $ile_kluczy_powinno_byc_zaladowanych keys are known - PROBLEM" | boxes -s 50x3 -a c -d ada-box
  else
    echo "(PGM) all $ile_kluczy_powinno_byc_zaladowanych keys are known - looks GOOD" | boxes -s 50x3 -a c -d ada-box
  fi
  
  echo ; echo 
  sleep 3
  if [ -f $HOME/.keychain/$HOSTNAME-sh ];then
    . $HOME/.keychain/$HOSTNAME-sh
  fi

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
