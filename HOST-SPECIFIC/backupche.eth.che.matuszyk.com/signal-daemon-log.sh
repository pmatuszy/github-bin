while : ; do 
  echo "[`date '+%Y.%m.%d %H:%M:%S'`] restart signala"
  /opt/signal-cli/bin/signal-cli -u +41763691467 daemon 2>&1 > /encrypted/root/signal-output-`date '+%Y%m%d__%H_%M_%S'`.log
  echo 
done
