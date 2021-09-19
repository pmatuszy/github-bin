# 2021.09.19 - v. 0.2 - dodana funkcja fsck, czytanie hasla do zmiennej
# 2021.01.30 - v. 0.1 - initial release (date unknown)

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

mount -o noatime /dev/mapper/encrypted_luks_file_in_root /encrypted

df -h /encrypted
echo
