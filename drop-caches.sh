free -m

set -x
echo 3 > /proc/sys/vm/drop_caches
set +x

free -m
