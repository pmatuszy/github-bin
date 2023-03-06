. /root/_script_header.sh

while : ;do
  echo `date` `vcgencmd measure_temp`
  sysbench --test=cpu --cpu-max-prime=25000 --num-threads=4 run > /dev/null 2> /dev/null
done

vcgencmd measure_temp

date

. /root/_script_footer.sh
