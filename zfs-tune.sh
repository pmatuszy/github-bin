# 2020.10.26 - v. 0.1 - initial release


echo cat /sys/module/zfs/parameters/zfs_prefetch_disable
cat /sys/module/zfs/parameters/zfs_prefetch_disable
echo 1 >/sys/module/zfs/parameters/zfs_prefetch_disable

echo cat /sys/module/zfs/parameters/zfs_prefetch_disable
cat /sys/module/zfs/parameters/zfs_prefetch_disable

###############################################################
echo
echo
echo cat /sys/module/zfs/parameters/zfs_nocacheflush
cat /sys/module/zfs/parameters/zfs_nocacheflush
echo 1 >/sys/module/zfs/parameters/zfs_nocacheflush

echo cat /sys/module/zfs/parameters/zfs_nocacheflush
cat /sys/module/zfs/parameters/zfs_nocacheflush


###############################################################
echo
echo

echo cat /sys/module/zfs/parameters/zfs_arc_min
cat /sys/module/zfs/parameters/zfs_arc_min
echo 536870912 > /sys/module/zfs/parameters/zfs_arc_min

echo cat /sys/module/zfs/parameters/zfs_arc_min
cat /sys/module/zfs/parameters/zfs_arc_min

###############################################################
echo
echo

echo cat /sys/module/zfs/parameters/zfs_arc_max
cat /sys/module/zfs/parameters/zfs_arc_max
echo 644245094 > /sys/module/zfs/parameters/zfs_arc_max

echo cat /sys/module/zfs/parameters/zfs_arc_max
cat /sys/module/zfs/parameters/zfs_arc_max

