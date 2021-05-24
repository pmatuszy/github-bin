for pid in $(pgrep -f 'sftp|rclone|rsync|md5sum|sha512sum|par2'); do echo -n "$pid " ; ionice -c 3 -p $pid; done
echo
