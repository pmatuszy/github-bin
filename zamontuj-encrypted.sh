zpool export zfs_encrypted_file 2>/dev/null
zpool import -d /encrypted.zfs -l -a

zpool status -v

zfs mount zfs_encrypted_file/encrypted

df -h /encrypted

