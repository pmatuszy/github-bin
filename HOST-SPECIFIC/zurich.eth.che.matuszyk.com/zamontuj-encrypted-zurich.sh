# 2021.01.30 - v. 0.1 - initial release (date unknown)

df -h /encrypted

nazwa_pliku=/encrypted.luks2

cryptsetup luksOpen ${nazwa_pliku} encrypted_luks_file_in_root

mount -o noatime /dev/mapper/encrypted_luks_file_in_root /encrypted

df -h /encrypted
echo

echo startuje vpnserver

/encrypted/vpnserver/vpnserver start

echo ; echo
ps -ef |grep vpnserver
echo ; echo

