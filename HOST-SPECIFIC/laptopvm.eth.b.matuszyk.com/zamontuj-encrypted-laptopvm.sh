#!/bin/bash

# 2021.09.19 - v. 0.5 - zmiana w fsck, dodana funkcja zrob_fsck
# 2021.08.29 - v. 0.4 - exportfs po zamontowaniu obu duzych volumentow, dodano montowanie dla minidlna i restart tego serwisu
# 2021.04.09 - v. 0.3 - bug fix: nie montowane byly backup2 i replication2 w jailu...
# 2020.11.26 - v. 0.2 - added fsck before mounting the disks
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

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
echo '########## /dev/vg_crypto/lv_do_luksa_16tb ==> /mnt/luks-raid1-16tb'
echo
echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto_buffalo3/lv_do_luksa_buffalo3 luks_buffalo3 -d -

zrob_fsck /dev/vg_crypto_buffalo3/lv_do_luksa_buffalo3

mount -o noatime /dev/mapper/luks_buffalo3 /mnt/luks_buffalo3

df -h /mnt/luks_buffalo3

