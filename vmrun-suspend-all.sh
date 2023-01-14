#!/bin/bash

# 2023.01.14 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

echo vmrun list | boxes -s 40x5 -a c
echo;

for p in `vmrun list|grep vmx`;do
  echo ; echo "* * * Suspending $p * * *"
  vmrun suspend $p nogui 
  sleep 1 ;
done;

echo ; 

echo vmrun list | boxes -s 40x5 -a c
echo 
vmrun list

. /root/bin/_script_footer.sh
