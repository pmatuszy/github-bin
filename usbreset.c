/*
 * usbreset -- send a USB port reset to a USB device
 *
 * 2026.04.21 - v. 1.1 - close fd on ioctl failure; clarify perror text when opening the device node
 * v. 1.0 - initial Linux usbfs USBDEVFS_RESET helper (earlier in-repo history not recorded)
 */

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>

#include <linux/usbdevice_fs.h>


int main(int argc, char **argv)
{
    const char *filename;
    int fd;
    int rc;

    if (argc != 2) {
        fprintf(stderr, "Usage: usbreset device-filename\n");
        return 1;
    }
    filename = argv[1];

    fd = open(filename, O_WRONLY);
    if (fd < 0) {
        perror("Error opening USB device");
        return 1;
    }

    printf("Resetting USB device %s\n", filename);
    rc = ioctl(fd, USBDEVFS_RESET, 0);
    if (rc < 0) {
        perror("Error in ioctl");
        close(fd);
        return 1;
    }
    printf("Reset successful\n");

    close(fd);
    return 0;
}
