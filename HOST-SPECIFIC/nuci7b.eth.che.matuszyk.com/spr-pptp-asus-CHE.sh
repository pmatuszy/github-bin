#!/bin/bash

# 2023.10.18 - v. 0.4 - added possibility to pause checking until a specific date
# 2023.07.27 - v. 0.3 - bugfix: added ssh 2>/dev/null redirection in case the script is not able to connect
# 2023.07.05 - v. 0.2 - added printing of the public IP address if there is a problem
# 2023.06.29 - v. 0.1 - initial release

. /root/bin/_script_header.sh

export adres_publiczny_z_pl="31.179.173.42"
export ROUTER_IP="192.168.200.230"
export PAUSE_UP_TO_DATE="20231102"     # bez kropek YYYYMMDD

if (( "$(date +%Y%m%d)" <= "${PAUSE_UP_TO_DATE}" ));then
  exit 0
fi

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

if [ -f $HOME/.keychain/$HOSTNAME-sh ];then
  . $HOME/.keychain/$HOSTNAME-sh
fi

check_if_installed curl
check_if_installed scp openssh-client

HC_MESSAGE=$(
   echo dddd ${ROUTER_IP}
   cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}'
   echo ; echo "aktualna data: `date '+%Y.%m.%d %H:%M'`" ; echo ;

   echo ; echo -n "checking if ppp interface is up..."
   echo ssh  admin@${ROUTER_IP} "ifconfig -a" 2>/dev/null | sed -n '/^ppp[0-9]/,/^$/p'
   ssh -o ConnectTimeout=10 admin@${ROUTER_IP} "ifconfig -a" 2>/dev/null | sed -n '/^ppp[0-9]/,/^$/p'
   exit_code_1=$?

   if (( $exit_code_1 == 0 ));then
     echo "GOOD"
   else
     echo "NOT good"
   fi

   echo ; echo -n "checking if 192.168.1.1 is pingable... "
   ssh -o ConnectTimeout=10 admin@${ROUTER_IP} "ping -c 3 -W 5 -q 192.168.1.1 " 2>/dev/null | grep -vq ", 0 packets received"    # jesli znajdzie taka linie to kod powrotu bedzie <> 0
   exit_code_2=$?
   if (( $exit_code_2 == 0 ));then
     echo "GOOD"
   else
     echo "NOT good"
   fi

   echo ; echo -n "checking if our public IP address is from PL... "
   ssh -o ConnectTimeout=10 admin@${ROUTER_IP} "/usr/sbin/curl --silent ifconfig.me | grep -q ${adres_publiczny_z_pl}" 2>/dev/null
   exit_code_3=$?
   if (( $exit_code_3 == 0 ));then
     echo "GOOD (`ssh -o ConnectTimeout=10 admin@${ROUTER_IP} /usr/sbin/curl --silent ifconfig.me 2>/dev/null`)"
   else
     echo "NOT good (`ssh -o ConnectTimeout=10 admin@${ROUTER_IP} /usr/sbin/curl --silent ifconfig.me 2>/dev/null`)"
   fi

   let final_exit_code=exit_code_1+exit_code_2+exit_code_3
   exit $final_exit_code
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
