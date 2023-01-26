#!/bin/bash

# 2023.01.26 - v. 0.1 - initial release

. /root/bin/_script_header.sh

cat  $0|grep -e '2022'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

echo
signal-cli version
echo

(sleep 20 ; setfacl -m u:healthchecks:rw /tmp/signal-socket )&
(sleep 20 ; setfacl -m u:healthchecks:rw /tmp/signal-socket )&
(sleep 40 ; setfacl -m u:healthchecks:rw /tmp/signal-socket )&
(sleep 60 ; setfacl -m u:healthchecks:rw /tmp/signal-socket )&

( sleep 10 ; for p in {1..60} ; do sleep 1 ; setfacl -m u:healthchecks:rw /tmp/signal-socket ; done ) 2>/dev/null &

signal-cli -a +420739836207 daemon --socket /tmp/signal-socket

. /root/bin/_script_footer.sh

