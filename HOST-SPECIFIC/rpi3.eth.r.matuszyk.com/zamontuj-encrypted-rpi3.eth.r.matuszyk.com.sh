#!/bin/bash

# 2021.09.06 - v. 0.1 - initial release (date unknown)

nazwa_pliku=/encrypted.luks2
cryptsetup luksOpen ${nazwa_pliku} encrypted_luks_file_in_root
mount -o noatime /dev/mapper/encrypted_luks_file_in_root /encrypted

df -h /encrypted

echo startuje vpnserver

/encrypted/vpnserver/vpnserver start

