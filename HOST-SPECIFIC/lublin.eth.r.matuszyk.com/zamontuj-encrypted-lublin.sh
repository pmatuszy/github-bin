#!/bin/bash
# 2022.11.20 - v  0.3 - added mounting dyskD
# 2022.10.11 - v  0.2 - added healthcheck support 
# 2022.07.30 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

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

echo
echo '########## /encrypted.luks2 ==> /encrypted'
echo
echo -n "$PASSWD" | cryptsetup luksOpen ${nazwa_pliku} encrypted_luks_file_in_root -d -
zrob_fsck /dev/mapper/encrypted_luks_file_in_root
mount -o noatime /dev/mapper/encrypted_luks_file_in_root /encrypted

echo
echo '########## /dev/vg_crypto_buffalo1/lv_do_luksa_buffalo1 ==> /mnt/luks-buffalo1'
echo
echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto_buffalo1/lv_do_luksa_buffalo1 luks-on-lv-buffalo1 -d -

zrob_fsck /dev/vg_crypto_buffalo1/lv_do_luksa_buffalo1
mount -o noatime /dev/mapper/luks-on-lv-buffalo1 /mnt/luks-buffalo1


echo
echo '########## /dev/vg_crypto_20221114_DyskD/lv_20221114_DyskD ==> /mnt/luks-dyskD'
echo
echo -n "$PASSWD" | cryptsetup luksOpen /dev/vg_crypto_20221114_DyskD/lv_20221114_DyskD luks-on-lv_20221114_DyskD -d -

zrob_fsck /dev/vg_crypto_20221114_DyskD/lv_20221114_DyskD
mount -o noatime,data=writeback,barrier=0,nobh,errors=remount-ro /dev/mapper/luks-on-lv_20221114_DyskD /mnt/luks-dyskD

echo
df -h /encrypted /mnt/luks-buffalo1 /mnt/luks-dyskD

/root/bin/sprawdz-czy-encrypted-jest-zamontowany.sh
