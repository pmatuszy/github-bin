#!/bin/bash

# 2023.02.08 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi
export warnings_and_errors=0
HC_message=$(
warnings_and_errors=0

check_if_installed keychain
eval $(keychain -q --nogui --nocolor --eval id_rsa id_SSH_ed25519_20230207_OpenSSH 2>&1 ) 2>&1 | egrep -iq "warning|error" 
if (( $? != 0 )); then
  let warnings_and_errors=warnings_and_errors+1
  keychain --nogui --nocolor --eval id_rsa id_SSH_ed25519_20230207_OpenSSH 2>&1 | egrep -i "warning|error" 
  echo "(PGM) NOT all keys are loaded - PROBLEM " | boxes -s 50x3 -a c -d ada-box
  echo ;  echo 
else
  echo "(PGM) 3 keys are loaded - looks GOOD" | boxes -s 50x3 -a c -d ada-box
fi

echo 
echo " keychain --nogui --noask --nocolor id_ed25519 id_SSH_ed25519_20230207_OpenSSH "
echo 
keychain --nogui --nocolor id_ed25519 id_SSH_ed25519_20230207_OpenSSH 2>& 1

how_many=$(keychain --nogui --nocolor id_ed25519 id_SSH_ed25519_20230207_OpenSSH 2>&1 | \
           egrep -i "^ * Known ssh key: id_rsa$|^ * Known ssh key: id_SSH_ed25519_20230207_OpenSSH$|^ * Known ssh key: /root/.ssh/id_ed25519$" | wc -l)

echo 

if (( $how_many != 3 )); then
  let warnings_and_errors=warnings_and_errors+1
  echo "(PGM) NOT all 3 keys are known - PROBLEM" | boxes -s 50x3 -a c -d ada-box
else
  echo "(PGM) all 3 keys are known - looks GOOD" | boxes -s 50x3 -a c -d ada-box
fi

keychain --nogui --noask --nocolor -l 
echo
keychain --nogui --noask --nocolor -L

exit $warnings_and_errors
)

echo "$HC_message"

if (( $? == 0 ));then
  echo "$HC_message" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
else 
  echo "$HC_message" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
fi

. /root/bin/_script_footer.sh
exit

#####
# new crontab entry

0 * * * *   /root/bin/ssh-keychain.sh
