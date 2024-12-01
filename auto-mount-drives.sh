#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Define the username to mount as (leave empty to use root)
USERNAME=""

# Get the UID and GID of the specified user
if [ -n "$USERNAME" ]; then
    USER_UID=$(id -u "$USERNAME")
    USER_GID=$(id -g "$USERNAME")

    # Check if the user exists
    if [ -z "$USER_UID" ] || [ -z "$USER_GID" ]; then
        echo "User '$USERNAME' does not exist."
        exit 1
    fi

    # Set the mount options for the user
    mount_ids=",uid=$USER_UID,gid=$USER_GID"
else
    # Default mount options (root mount)
    mount_ids=""
fi

# Check if a specific device was provided
if [ $# -gt 0 ]; then
    devices=("$1")
else
    devices=(/dev/sd[a-z][1-9]) # Default to all /dev/sd[a-z][1-9] devices
fi

for device in "${devices[@]}"; do
    # Check if the device exists
    if [ ! -b "$device" ]; then
        echo "Error: $device is an invalid device."
        continue
    fi

    # Check if the device is already mounted
    if mountpoint -q "$device"; then
        echo "$device is already mounted."
        continue
    fi

    # Check if the device has a valid filesystem
    fs_type=$(blkid -o value -s TYPE "$device" 2>/dev/null)
    if [ -z "$fs_type" ]; then
        echo "Skipping $device: No valid filesystem found."
        continue
    fi

    # Set the mount options based on the filesystem type
    case "$fs_type" in
        ntfs)
            mount_opts="errors=remount-ro,relatime,utf8,flush$mount_ids"
            fs_type="ntfs-3g"
            ;;
        vfat)
            mount_opts="errors=remount-ro,relatime,flush$mount_ids"
            ;;
        exfat)
            mount_opts="defaults$mount_ids"
            ;;
        ext[2-4])
            mount_opts="$mount_ids"
            ;;
        *)
            echo "Error: Unsupported filesystem type '$fs_type' on $device."
            continue
            ;;
    esac

    # Define the mount point
    mount_point="/media/$(basename "$device")"

    # Check if the directory already exists and clean up if necessary
    if [ -d "$mount_point" ]; then
        if [ -z "$(ls -A "$mount_point" 2>/dev/null)" ]; then
            if ! mountpoint -q "$mount_point"; then
                echo "Removing unused empty directory: $mount_point"
                if ! rmdir "$mount_point"; then
                    echo "Failed to remove directory: $mount_point. Skipping."
                    continue
                fi
            else
                echo "Directory $mount_point is in use as a mount point."
                continue
            fi
        fi
    fi

    # Create the mount point
    if [ ! -d "$mount_point" ]; then
        echo "Creating mount point: $mount_point"
        mkdir -p "$mount_point" || {
            echo "Failed to create directory: $mount_point. Skipping."
            continue
        }
    fi

    # Mount the device
    echo "Mounting $device with filesystem type $fs_type"
    mount -t "$fs_type" -o $mount_opts "$device" "$mount_point" || {
        echo "Failed to mount $device as $fs_type."
        rmdir "$mount_point" 2>/dev/null
        continue
    }

    echo "$device successfully mounted at $mount_point"
done

echo "All valid devices processed."
