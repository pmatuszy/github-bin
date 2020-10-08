. /root/_script_header.sh

while : ; do
  echo `date ` `awk '{printf "%3.1f C\n", $1/1000}' /sys/class/thermal/thermal_zone0/temp`
  sleep 3
done

. /root/_script_footer.sh

