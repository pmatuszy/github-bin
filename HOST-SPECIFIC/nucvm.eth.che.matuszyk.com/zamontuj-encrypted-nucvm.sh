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

nazwa_pliku=/encrypted.luks2

echo -n "$PASSWD" | cryptsetup luksOpen ${nazwa_pliku} encrypted_luks_file_in_root -d -
zrob_fsck /dev/mapper/encrypted_luks_file_in_root

echo
echo '########## /dev/vg_crypto_buffalo2/lv_do_luksa_buffalo2 ==> /mnt/luks-buffalo2'
echo
echo -n "$PASSWD" | cryptsetup luksOpen  /dev/vg_crypto_buffalo2/lv_do_luksa_buffalo2 luks_buffalo2 -d -

zrob_fsck /dev/mapper/luks_buffalo2

echo
echo '########## /dev/vg_crypto_raidsonic/lv_do_luksa_raidsonic  ==> /mnt/luks-raidsonic'
echo
echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto_raidsonic/lv_do_luksa_raidsonic luks-on-lv-raidsonic -d -

zrob_fsck /dev/mapper/luks-on-lv-raidsonic

mount -o noatime /dev/mapper/encrypted_luks_file_in_root /encrypted
mount -o noatime /dev/mapper/luks_buffalo2 /mnt/luks-buffalo2
mount -o noatime /dev/mapper/luks-on-lv-raidsonic /mnt/luks-raidsonic

df -h /encrypted /mnt/luks-buffalo2 /mnt/luks-raidsonic

echo ; echo 
echo "restart nfs servera, bo zwykle jest problem polegajacy na tym, ze service nie startuje od razu, bo nie sa zamontowane exportowane fs'y"
echo "wiec teraz po ich zamontowaniu, restartujemy serwis..."
echo ; echo 
systemctl restart nfs-kernel-server

echo 
exportfs -av
echo

sleep 2 

