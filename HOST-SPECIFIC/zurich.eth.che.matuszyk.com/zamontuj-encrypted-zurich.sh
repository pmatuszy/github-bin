#!/bin/bash

# 2022.06.24 - v. 0.2 - dodano obsluge healthcheckow i grep -v grep 
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
ps -ef |grep vpnserver | grep -v grep
echo ; echo

if [ -x /root/bin/sprawdz-czy-encrypted-jest-zamontowany.sh ];then
  /root/bin/sprawdz-czy-encrypted-jest-zamontowany.sh
fi

if [ -x /root/bin/sprawdz-czy-dziala-server-vpn.sh ];then
  /root/bin/sprawdz-czy-dziala-server-vpn.sh
fi
