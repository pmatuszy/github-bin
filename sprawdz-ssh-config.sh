#!/bin/bash

# 2023.02.08 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

type -fP keychain 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find keychain utility... exiting ..."; echo
  exit 1
fi

# spr. config ssh

pgrep  ssh-agent >/dev/null
if [ $? -ne 0 ];then 
  [ $script_is_run_interactively == 1 ] && echo "(PGM) PROBLEM - agent is NOT running"
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
else
  [ $script_is_run_interactively == 1 ] && echo "(PGM) all is good - agent is running"
  /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
fi

exit
#####
# new crontab entry

*/3 * * * * /root/bin/sprawdz-ssh-config.sh

