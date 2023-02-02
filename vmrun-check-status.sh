#!/bin/bash

# 2023.02.02 - v. 0.1 - initial release

. /root/bin/_script_header.sh

echo ; echo ; cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo

type -fP vmrun 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmrum utility... exiting ..."; echo
  exit 1
fi

export DISPLAY=

echo vmrun list | boxes -s 40x5 -a c
echo;
vmrun list
echo

export IFS=$'\n'

for p in `vmrun list|grep vmx`;do
  echo
  echo "* * * suspending $p (PGM) * * *"
  vmrun getGuestIPAddress  $p nogui
  if (( $? != 0 )); then
    echo ; echo "(PGM) vmrun finished with ERRORS !!!!!!"; echo
  fi
  sleep 0.5 ;
done;

echo ; 

echo vmrun list | boxes -s 40x5 -a c
echo 
vmrun list
echo 

. /root/bin/_script_footer.sh
