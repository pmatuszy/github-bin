. /root/_script_header.sh

while : ; do 
  ls -l /mnt/superintel/DyskC/* > /dev/null 2>/dev/null
  ls -l /mnt/superintel/DyskD/* > /dev/null 2>/dev/null
  ls -l /mnt/superintel/DyskE/* > /dev/null 2>/dev/null
  ls -l /mnt/superintel/DyskI/* > /dev/null 2>/dev/null
  ls -l /mnt/superintel/DyskS/* > /dev/null 2>/dev/null
  ls -l /mnt/superintel/DyskT/* > /dev/null 2>/dev/null
  ls -l /mnt/superintel/DyskU/* > /dev/null 2>/dev/null
  df -Ph /mnt/superintel/DyskC/ /mnt/superintel/DyskD/ /mnt/superintel/DyskE/ /mnt/superintel/DyskI/ /mnt/superintel/DyskS/ /mnt/superintel/DyskT/ /mnt/superintel/DyskU/
  echo `date` czekam 15s...
  sleep 14.98
done

. /root/_script_footer.sh
