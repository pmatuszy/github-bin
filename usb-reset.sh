#!/bin/bash

# 20xx.xx.xx - v. 0.1 - initial release (date unknown)

if [[ $EUID != 0 ]] ; then
  echo This must be run as root!
  exit 1
fi

for xhci in /sys/bus/pci/drivers/?hci_hcd ; do

  if ! cd $xhci ; then
    echo Weird error. Failed to change directory to $xhci
    exit 1
  fi

  echo Resetting devices from $xhci...

  for i in ????:??:??.? ; do
    echo -n "$i" > unbind 2>/dev/null
    echo -n "$i" > bind   2>/dev/null
  done
done
