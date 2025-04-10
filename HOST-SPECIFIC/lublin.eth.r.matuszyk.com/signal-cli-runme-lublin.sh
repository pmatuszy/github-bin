#!/bin/bash

# 2024.12.03 - v. 0.2 - added sleep for signal not to restart too quickly
# 2023.01.26 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

echo
signal-cli version
echo

( sleep 10 ; for p in {1..60} ; do sleep 1 ; setfacl -m u:healthchecks:rw /tmp/signal-socket ; done ) 2>/dev/null &

while : ; do 
  signal-cli -a +420739836207 daemon --socket /tmp/signal-socket
  sleep 15    # do not restart too often
done

. /root/bin/_script_footer.sh
