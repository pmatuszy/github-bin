#!/bin/bash

# 2021.02.24 - v. 0.1 - initial release - skrypt from https://github.com/maknesium/disable-hugepages
#    autor wrote this article: 
#      https://www.maknesium.de/disable-hugepages-on-linux-yields-huge-speed-improvements-for-vmware-workstation


###########################################################
# disable huge pages on debian/ubuntu based Linux systems #
###########################################################

echo "Disabling hugepages..."
echo '0'     | sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
# I tend to let the hugepage support enabled...
#echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

echo "=============== State of hugepages on current system ==============="
echo "Current setting for /sys/kernel/mm/transparent_hugepage/khugepaged/defrag"
cat /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
echo "Current setting for /sys/kernel/mm/transparent_hugepage/defrag"
cat /sys/kernel/mm/transparent_hugepage/defrag
echo "Current setting for /sys/kernel/mm/transparent_hugepage/enabled"
cat /sys/kernel/mm/transparent_hugepage/enabled
echo "===================================================================="

echo
echo
echo "replace in /etc/default/grub : "
echo GRUB_CMDLINE_LINUX_DEFAULT="transparent_hugepage=never nosplash "
echo
echo "then run: update-grub"
echo


###############################
# further links for hugepages #
###############################
# http://forums.fedoraforum.org/showthread.php?t=285246
# https://bugzilla.redhat.com/show_bug.cgi?id=879801
# http://unix.stackexchange.com/questions/161858/arch-linux-becomes-unresponsive-from-khugepaged
