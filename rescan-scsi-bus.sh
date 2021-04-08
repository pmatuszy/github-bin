for p in /sys/class/scsi_host/host* ; do
  echo aaaaa  $p
  echo echo "- - -" > ${p}/scan
done
