#!/bin/bash

# 2023.02.05 - v. 0.3 - added encrypted vm support
# 2023.01.20 - v. 0.2 - added status reporting after starting the vm
# 2023.01.16 - v. 0.1 - initial release

. /root/bin/_script_header.sh

VM_LOCATIONS="/vmware /vmware-nvme /encrypted/vmware-in-encrypted /mnt/luks-raidsonic"

cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo 

export DISPLAY=

if [ -f /root/SECRET/vmware-pass.sh ];then
  . /root/SECRET/vmware-pass.sh
fi

type -fP vmrun 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmrum utility... exiting ..."; echo 
  exit 1
fi

echo vmrun list | boxes -s 40x5 -a c
vmrun list
echo;

echo ; echo "All VMs on that host (running and not running):" ; echo 
find $VM_LOCATIONS -type f -name \*vmx 2>/dev/null
echo ; echo 

export OIFS="$IFS"

for p in $VM_LOCATIONS ; do 
  export IFS=$'\n'
  for vm in $(find $p -type f -name "*.vmx" -print 2>/dev/null);do 
    if (( $(vmrun list |grep -v "Total running VMs:" | grep "$vm"| wc -l) != 0 ))  ;then
      echo "(PGM) machine $vm is running so we don't want to start it again...";echo 
      continue
    fi
    echo $vm | boxes -s 40x5 -a c
    ls -ld $vm `dirname $vm`/*lck 2>/dev/null
    input_from_user=""
    IFS="$OIFS" read -t 300 -n 1 -p "Do you want to start [y/N/q]: " input_from_user
    echo
    if [ "${input_from_user}" == 'q' -o  $"{input_from_user}" == 'Q' ]; then
      echo
      exit 1
    fi
    if [ "${input_from_user}" == 'y' -o  $"{input_from_user}" == 'Y' ]; then
      if [ -d "${vm}.lck" ]; then
        echo "(PGM) removing lck directory as it exists..."
        rm -rfv "${vm}.lck"
      fi
      echo "* * * starting $vm (PGM) * * *";echo 
      vmrun start $vm nogui
      if [ ! -z "${TPM_PASS:-}" ];then
        vmrun -vp "${TPM_PASS}" start $vm nogui
      else
        vmrun start $vm nogui
      fi
      if (( $? == 0 )); then
        echo ; echo "(PGM) vmrun finished SUCCESSFULLY"; echo
      else
        echo ; echo "(PGM) vmrun finished with ERRORS !!!!!!"; echo

      fi       
    fi
    echo 
  done
done

echo ; 

echo vmrun list | boxes -s 40x5 -a c
echo 
vmrun list
echo 

. /root/bin/_script_footer.sh
