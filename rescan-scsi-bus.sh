for p in /sys/class/scsi_host/host* ; do
  echo "scan for $p"
  echo echo "- - -" > ${p}/scan
done
