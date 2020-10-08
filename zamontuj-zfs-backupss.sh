jd.sh

echo nacisnij ENTER
read r

dmesg

echo nacisnij ENTER
read r

set +x
zpool export zfs-raid1-encosureA 2>/dev/null
zpool export zfs-raid1-encosureB 2>/dev/null
zpool import -d /dev/disk/by-id -l -a
zpool status -v

zfs mount -a

df -h

mount -o bind /mnt/replication1/skasujto /rclone-jail/storage-master/


