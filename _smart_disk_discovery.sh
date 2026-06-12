# 2026.06.12 - v. 0.1 - whole-disk block device list from fdisk (for smart-*.sh)

discover_whole_disk_devices() {
    fdisk -l 2>/dev/null | grep -E '^Disk /dev/' | grep -Ev 'mapper|/md|/ram|mmcblk|/dev/loop' |
        awk '{print $2}' | tr -d ':' | sort -u
}
