#!/bin/bash

# 2023.05.09 - v. 0.6 - added checking if the script is run on the physical machine
# 2023.02.05 - v. 0.5 - added printing current date and time
# 2023.02.05 - v. 0.4 - added encrypted vm support
# 2023.01.20 - v. 0.3 - added status reporting after starting the vm
# 2023.01.16 - v. 0.2 - small changes to the way things are displayed
# 2023.01.14 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed virt-what
if (( $(virt-what | wc -l) != 0 ));then
  echo ; echo "host is NOT a physical machine ... exiting...";echo
  exit 1
fi

type -fP vmrun 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmrun utility... exiting ..."; echo
  exit 1
fi

export DISPLAY=

if [ -f /root/SECRET/vmware-pass.sh ];then
  . /root/SECRET/vmware-pass.sh
fi

echo vmrun list | boxes -s 40x5 -a c
echo;
vmrun list
echo

export IFS=$'\n'

for p in `vmrun list|grep vmx`;do
  echo ; echo -n "Do you want to SUSPEND $p [y/N/q]: "
  input_from_user=""
  read -t 300 -n 1 input_from_user
  echo
  if [ "${input_from_user}" == 'q' -o  $"{input_from_user}" == 'Q' ]; then
    echo
    exit 1
  fi
  if [ "${input_from_user}" == 'y' -o  $"{input_from_user}" == 'Y' ]; then
    echo "* * * suspending $p (PGM) * * *"
    if [ ! -z "${TPM_PASS:-}" ];then
      vmrun -vp "${TPM_PASS}" suspend $p nogui
    else
      vmrun suspend $p nogui
    fi
    if (( $? == 0 )); then
      echo ; echo "(PGM) vmrun finished SUCCESSFULLY"; echo
    else
      echo ; echo "(PGM) vmrun finished with ERRORS !!!!!!"; echo
    fi
  fi
  sleep 0.5 ;
done;

echo ; 

echo vmrun list | boxes -s 40x5 -a c
echo 
vmrun list
echo 

. /root/bin/_script_footer.sh
