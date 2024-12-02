# Auto Mount Drives

This bash script configured as a service automatically mounts drives (such as `/dev/sda1`, `/dev/sdb1`, etc.) to `/media/sda1`, `/media/sdb1`, and so on. Originally designed for Raspberry Pi for USB drives, this script works on most Linux-based systems.

## Setup

Modify USERNAME and DEVICE_PATTERN in auto-mount-drives

Copy auto-mount-drives to /usr/local/bin/auto-mount-drives

sudo chmod +x /usr/local/bin/auto-mount-drives

Copy auto-mount-drives.service to /etc/systemd/system/auto-mount-drives.service

sudo systemctl enable auto-mount-drives.service

Copy 99-auto-mount-drives.rules to /etc/udev/rules.d/99-auto-mount-drives.rules

sudo udevadm control --reload-rules