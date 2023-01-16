#!/bin/bash

# 2023.01.16 - v. 0.2 - small changes to the way things are displayed
# 2023.01.14 - v. 0.1 - initial release

. /root/bin/_script_header.sh

echo ; echo ; cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo

type -fP vmrun 2>/dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmrum utility... exiting ..."; echo
  exit 1
fi

echo vmrun list | boxes -s 40x5 -a c
echo;
vmrun list
echo

for p in `vmrun list|grep vmx`;do
  echo ; echo "* * * Suspending $p * * *"
  vmrun suspend $p nogui 
  sleep 1 ;
done;

echo ; 

echo vmrun list | boxes -s 40x5 -a c
echo 
vmrun list
echo 

. /root/bin/_script_footer.sh
