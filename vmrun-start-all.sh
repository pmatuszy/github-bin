#!/bin/bash

# 2023.01.16 - v. 0.1 - initial release

. /root/bin/_script_header.sh

VM_LOCATIONS="/vmware /vmware-nvme /encrypted/vmware-in-encrypted /mnt/luks-raidsonic"

cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo 

echo vmrun list | boxes -s 40x5 -a c
vmrun list
echo;

echo ; echo "All VMs on that host (running and not running):" ; echo 
find $VM_LOCATIONS -type f -name \*vmx 2>/dev/null
echo ; echo 

for p in $VM_LOCATIONS ; do 
  for vm in $(ls -1 "${p}"/*/*vmx 2>/dev/null);do
    if (( $(vmrun list |grep -v "Total running VMs:" | grep "$vm"| wc -l) != 0 ))  ;then
      echo "(PGM) machine $vm is running so we don't want to start it again...";echo 
      continue
    fi
    echo $vm | boxes -s 40x5 -a c
    ls -ld $vm `dirname $vm`/*lck 2>/dev/null
    
    echo ; echo -n "Do you want to start $(ls -1 $vm) [y/N/q]: "
    input_from_user=""
    read -t 300 -n 1 input_from_user
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
      echo $?
      vmrun list
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
