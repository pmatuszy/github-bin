for pid in $(pgrep -f 'sftp|rclone|rsync|md5'); do echo -n "$pid " ; ionice -c 3 -p $pid; done
echo
