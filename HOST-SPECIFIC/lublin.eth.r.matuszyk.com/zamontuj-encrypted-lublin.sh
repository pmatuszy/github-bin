#!/bin/bash

# 2022.07.30 - v. 0.1 - initial release (date unknown)

echo
read -r -p "Wpisz haslo: " -s PASSWD
echo

################################################################################
zrob_fsck() {
################################################################################

echo "################################################################################"
echo
echo czas na fsck $1 ...
echo
echo "################################################################################"

fsck -C -M -R -T -V $1

echo
echo ... and once again fsck
echo
fsck $1
}
################################################################################

echo
echo '########## /dev/vg_crypto_buffalo1/lv_do_luksa_buffalo1 ==> /mnt/luks-buffalo1'
echo
echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto_buffalo1/lv_do_luksa_buffalo1 luks-on-lv-buffalo1 -d -

zrob_fsck /dev/vg_crypto_buffalo1/lv_do_luksa_buffalo1

mount -o noatime /dev/mapper/luks-on-lv-buffalo1 /mnt/luks-buffalo1

df -h /mnt/luks-buffalo1

