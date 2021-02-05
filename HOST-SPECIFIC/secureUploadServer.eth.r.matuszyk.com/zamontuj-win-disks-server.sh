. /root/_script_header.sh

set +x 

echo 
echo 
echo  server 
echo 
echo 

set -x

mount.cifs -o user=administrator //server.int.matuszyk.com/DyskC /mnt/server/DyskC ; df -hP /mnt/server/DyskC
mount.cifs -o user=administrator //server.int.matuszyk.com/DyskD /mnt/server/DyskD ; df -hP /mnt/server/DyskD
mount.cifs -o user=administrator //server.int.matuszyk.com/DyskN /mnt/server/DyskN ; df -hP /mnt/server/DyskN
mount.cifs -o user=administrator //server.int.matuszyk.com/DyskO /mnt/server/DyskO ; df -hP /mnt/server/DyskO

set +x

. /root/_script_footer.sh
