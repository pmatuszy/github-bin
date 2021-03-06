#!/bin/bash
# 2020.12.03 - v.1.6 - zmiania sposobu wyswietlania (by output byl troche wezszy na ekranie)
# 2020.12.03 - v.1.5 - dodane wyswietlanie numeru seryjnego dyskow
# 2020.11.18 - v.1.4 - zmienna scheduler - wystarczy odkomentowac, ktorego nalezy uzywac, bug fixes
# 2020.11.11 - v.1.3 - zmiana schedulera z mq-deadline na none
# 2020.10.08 - v.1.2 - male zmiany w sposobie wyswietlania 
# 2020.10.08 - v.1.1 - showing timeouts before the setting them
# 2020.10.04 - v.1.0 - added timeout variable and increased value of it from 180 to 300s

# good reading: https://raid.wiki.kernel.org/index.php/Timeout_Mismatch
# "In 2019, a new technology called shingled magnetic recording (SMR) started becoming mainstream"
# WD has said that all the WD Red line is now SMR. To get raid-suitable CMR you need to buy Red Plus, or Red Pro
# You should never have been using Seagate Barracudas anyway, but these have now pretty much all moved over to 
# SMR (and been renamed BarraCuda). Seagate have said that their IronWolf and IronWolf Pro lines will remain CMR, 
# and the FireCuda line seems all CMR at the moment (I guess these will be a bit like the Red Pros, 
# the CMR equivalent of the BarraCuda).

# also this:
# https://unix.stackexchange.com/questions/541463/how-to-prevent-disk-i-o-timeouts-which-cause-disks-to-disconnect-and-data-corrup

# Redhat support (you need to log in) https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/6.5_release_notes/kernel
# Configurable Timeout for Unresponsive Devices
# In certain storage configurations (for example, configurations with many LUNs), the SCSI error handling code can spend 
# a large amount of time issuing commands such as TEST UNIT READY to unresponsive storage devices. A new sysfs parameter, eh_timeout,
# has been added to the SCSI device object, which allows configuration of the timeout value for TEST UNIT READY and REQUEST SENSE 
# commands used by the SCSI error handling code. This decreases the amount of time spent checking these unresponsive devices. 
# The default value of eh_timeout is 10 seconds, which was the timeout value used prior to adding this functionality.

timeout=7200
eh_timeout=7200
queue_depth=1
nr_requests=4
# scheduler='none'
scheduler='mq-deadline'

echo
echo '/----------------\'
echo '| przed zmianami |'
echo '\----------------/'

echo "   disk  |  /sys/block/sd?/device/timeout  |/sys/block/sd?/device/eh_timeout |/sys/block/sd?/device/queue_depth|  /sys/block/sd?/queue/scheduler |/sys/block/sdr?queue/nr_requests |"
echo "=========+=================================+=================================+=================================+=================================+=================================+"
for p in {a..z} ; do
  if [ -b /dev/sd$p ]; then
    printf "%8s | " /dev/sd${p}
    for r in device/timeout device/eh_timeout device/queue_depth queue/scheduler queue/nr_requests ; do
      if [ -f /sys/block/sd${p}/${r} ]; then
        printf "%31s | "  "`cat /sys/block/sd${p}/${r}`"
      fi
    done
    echo
    echo $timeout > /sys/block/sd${p}/device/timeout
    echo ${eh_timeout} > /sys/block/sd${p}/device/eh_timeout
#    echo ${queue_depth} > /sys/block/sd${p}/device/queue_depth

   # ze strony: https://wiki.ubuntu.com/Kernel/Reference/IOSchedulers
   #none (Multiqueue)
   # The multi-queue no-op I/O scheduler. Does no reordering of requests, minimal overhead. Ideal for fast random I/O devices such as NVME.
    echo "$scheduler" > /sys/block/sd${p}/queue/scheduler

# jesli scheduler = none to ponizsza linia zwraca blad
   if [ $scheduler != "none" ]; then
     echo "${nr_requests}" > /sys/block/sd${p}/queue/nr_requests
   fi
  fi
done

echo

for p in /dev/sd{a..z} ; do
  if [ -b $p ]; then
    if smartctl -l scterc,70,70 $p > /dev/null ; then
      echo -n $p " is good "
    else
      echo -n $p " is  bad "
    fi
    echo "("`gdisk -l $p |grep "Disk /dev"|sed 's/.*: //'` "," `hdparm -I $p 2>/dev/null | grep 'Serial\ Number'` `smartctl -i $p | egrep "(Device Model|Product:)"`")"
    echo ${timeout} > /sys/block/${p/\/dev\/}/device/timeout
    blockdev --setra 1024 $p
  fi

done

echo
echo '/-------------\'
echo '| po zmianach |'
echo '\-------------/'

echo "   disk  |  /sys/block/sd?/device/timeout  |/sys/block/sd?/device/eh_timeout |/sys/block/sd?/device/queue_depth|  /sys/block/sd?/queue/scheduler |/sys/block/sdr?queue/nr_requests |"
echo "=========+=================================+=================================+=================================+=================================+=================================+"

for p in {a..z} ; do
  if [ -b /dev/sd$p ]; then
    printf "%8s | " /dev/sd${p}
      for r in device/timeout device/eh_timeout device/queue_depth queue/scheduler queue/nr_requests ; do
        if [ -f /sys/block/sd${p}/${r} ]; then
          printf "%31s | "  "`cat /sys/block/sd${p}/${r}`"
        fi
      done
    echo
    echo $timeout > /sys/block/sd${p}/device/timeout
    echo ${eh_timeout} > /sys/block/sd${p}/device/eh_timeout
#    echo ${queue_depth} > /sys/block/sd${p}/device/queue_depth
# jesli scheduler = none to ponizsza linia zwraca blad
#    echo ${nr_requests} > /sys/block/sd${p}/queue/nr_requests
  fi
done

echo

