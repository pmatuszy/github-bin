#!/bin/bash
# 2021.04.09 - v. 0.2 - changed IP to machine DNS name 
# 2020.0x.xx - v. 0.1 - initial release (date unknown)


. /root/_script_header.sh

set +x

echo
echo
echo  desktopche
echo
echo

set -x

mount.cifs -o user=administrator //pgm-desktop-che.eth.che.matuszyk.com/DyskC /mnt/desktopche/DyskC ; df -hP /mnt/desktopche/DyskC
mount.cifs -o user=administrator //pgm-desktop-che.eth.che.matuszyk.com/DyskD /mnt/desktopche/DyskD ; df -hP /mnt/desktopche/DyskD
mount.cifs -o user=administrator //pgm-desktop-che.eth.che.matuszyk.com/DyskE /mnt/desktopche/DyskE ; df -hP /mnt/desktopche/DyskE

set +x

. /root/_script_footer.sh

