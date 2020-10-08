#!/bin/bash

# v.1.1 - 2020.10.08 - showing timeouts before the setting them
# v.1.0 - 2020.10.04 - added timeout variable and increased value of it from 180 to 300s

# good reading: https://raid.wiki.kernel.org/index.php/Timeout_Mismatch
# "In 2019, a new technology called shingled magnetic recording (SMR) started becoming mainstream"
# WD has said that all the WD Red line is now SMR. To get raid-suitable CMR you need to buy Red Plus, or Red Pro
# You should never have been using Seagate Barracudas anyway, but these have now pretty much all moved over to 
# SMR (and been renamed BarraCuda). Seagate have said that their IronWolf and IronWolf Pro lines will remain CMR, 
# and the FireCuda line seems all CMR at the moment (I guess these will be a bit like the Red Pros, 
# the CMR equivalent of the BarraCuda).

# also this:
# https://unix.stackexchange.com/questions/541463/how-to-prevent-disk-i-o-timeouts-which-cause-disks-to-disconnect-and-data-corrup


timeout=3600

for p in {a..z} ; do 
  if [ -b /dev/sd$p ]; then
    echo -n "/dev/sd$p "
    cat /sys/block/sd${p}/device/timeout
  fi
done

for p in /dev/sd{a..z} ; do
  if [ -b $p ]; then
    if smartctl -l scterc,70,70 $p > /dev/null ; then
      echo -n $p " is good "
    else
      echo -n $p " is  bad "
    fi
    echo ${timeout} > /sys/block/${p/\/dev\/}/device/timeout
    smartctl -i $p | egrep "(Device Model|Product:)"
    blockdev --setra 1024 $p
  fi
done

for p in {a..z} ; do
  if [ -b /dev/sd$p ]; then
    echo -n "/dev/sd$p "
    cat /sys/block/sd${p}/device/timeout
  fi
done

