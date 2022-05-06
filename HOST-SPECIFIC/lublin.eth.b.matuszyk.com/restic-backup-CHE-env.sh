export RESTIC_BACKUP_NAME=restic_backup_CHE

export RESTIC_REPOSITORY=rclone:crypt-sftp-CHE-ext-backup2-restic:/lublin.eth.b.matuszyk.com

export RCLONE_CONFIG=/root/rclone.conf

export MY_EXCLUDES='{/dev,/media,/mnt,/proc,/run,/sys,/tmp,/var/tmp,/veracrypt.vc,/encrypted.luks2,/rclone-jail,$XDG_CACHE_HOME,/root/.cache,/snap/**/*,/podsync-hdd/_montowanie,/podsync-hdd/_Mikey,/podsync-hdd}'
export MY_EXCLUDE_FILE=/root/restic_iexclude_file.txt

export RESTIC_BIN=/usr/bin/restic

export RCLONE_CHECKERS=2
export RCLONE_TRANSFERS=2
export RCLONE_BUFFER_SIZE=128M
export RCLONE_STATS_FILE_NAME_LENGTH=0
export RCLONE_VERBOSE=0
export RCLONE_STATS_LOG_LEVEL=INFO
export RCLONE_STATS_ONE_LINE=true
export RCLONE_STATS=1s

# export RCLONE_BWLIMIT=30M
export RCLONE_BWLIMIT='Mon-01:00,5M Mon-07:00,3M Tue-01:00,5M Tue-07:00,3M Wed-01:00,5M Wed-07:00,3M Thu-01:00,5M Thu-07:00,3M Fri-01:00,5M Fri-07:00,3M Sat-01:00,5M Sat-07:00,3M Sun-01:00,5M Sun-08:00,3M'

