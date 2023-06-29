#!/bin/bash

# 2023.06.29 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

if [ ! -z "${HEALTHCHECKS_FORCE_ID:-}" ]; then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^$HEALTHCHECKS_FORCE_ID"|awk '{print $2}')
fi

if [ -f $HOME/.keychain/$HOSTNAME-sh ];then
  . $HOME/.keychain/$HOSTNAME-sh
fi

check_if_installed curl
check_if_installed scp openssh-client

RSYNC_BIN="$(type -Pf rsync)"


HC_MESSAGE=$(
   cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}'
   echo ; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ;

   echo ; echo "command to be run:"
   echo ssh  admin@192.168.200.230 "ifconfig -a" | sed -n '/^ppp[0-9]/,/^$/p'
   ssh  admin@192.168.200.230 "ifconfig -a" | sed -n '/^ppp[0-9]/,/^$/p'
   ssh admin@192.168.200.230 "ping -c 1 -W 2 -q 192.168.133.1 " | grep -vq ", 0 packets received"    # jesli znajdzie taka linie to kod powrotu bedzie <> 0
   exit $?
   )
kod_powrotu=$?

if (( $script_is_run_interactively == 1 )); then
  echo "$HC_MESSAGE"
  echo "kod_powrotu = $kod_powrotu"
fi

# if rsync exit code is 23 and no files are transferred / created  we treat it as successful run
if (( $kod_powrotu == 23 )) && (( $kod_1 == 0 )) &&  (( $kod_2 == 0 )) && (( $kod_3 == 0 )) ;then
  # we do nothing here - we don't even run curl - if nothing was fetched we do not provide status (neither ok nor error)
  echo > /dev/null
else
  echo "$HC_MESSAGE" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/$kod_powrotu 2>/dev/null
fi

. /root/bin/_script_footer.sh

