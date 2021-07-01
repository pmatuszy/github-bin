. /root/bin/_script_header.sh

while : ; do 
  ls -l /mnt/server/DyskC/* > /dev/null 2>/dev/null
  ls -l /mnt/server/DyskD/* > /dev/null 2>/dev/null
  ls -l /mnt/server/DyskN/* > /dev/null 2>/dev/null
  ls -l /mnt/server/DyskO/* > /dev/null 2>/dev/null
  df -Ph /mnt/server/DyskC/ /mnt/server/DyskD/ /mnt/server/DyskN/ /mnt/server/DyskO/
  echo `date` czekam 15s...
  sleep 14.98
done

. /root/bin/_script_footer.sh
