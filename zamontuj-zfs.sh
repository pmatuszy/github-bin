jd.sh

echo nacisnij ENTER
read r

dmesg

echo nacisnij ENTER
read r


zpool export zfs_usb 2>/dev/null

zpool import -d /dev/disk/by-id -l -a

zpool status -v

zfs mount -a

df -h

zfs set sharenfs="rw=@192.168.200.138/32" zfs_usb/worek/podsync-hdd


