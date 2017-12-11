#!/bin/bash

# This script partitions the hard drive and creates file systems in a way that
# is suitable for installing Linux.

# This script uses a MBR. There is a different script you can use if you want
# GPT instead.

# This script assumes that the hard disk is about 5 GB or larger.

# DISK=/dev/sda
DISK=/dev/vda

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

if [ -d "/sys/firmware/efi" ]; then
    echo The computer booted using UEFI. This script does not yet support
    echo installation on computers using UEFI.
    exit 1
fi

# Grub2 is installed in the gap between the MBR and the first partition.
# This means that we need some space between them. 1 Mb is plenty of space.
# https://www.gnu.org/software/grub/manual/grub/html_node/BIOS-installation.html

# Also if you specify numbers that are powers of two parted will think that you
# are specifying exact alignments. This is usually not what you want since most
# of the time it means that the partitions you create will be misaligned.

# The following are the partitions that we are going to be creating.
# /dev/sda1 is the /boot partition which has a size of 256 Mb.
# /dev/sda2 is the swap partition which has the size 4 GB.
# /dev/sda3 is the root partition which i fills the rest of the disk.

BOOT_PARTITION="${DISK}1"
SWAP_PARTITION="${DISK}2"
ROOT_PARITION="${DISK}3"

echo "Partitioning $DISK"
echo "Boot partition: $BOOT_PARTITION"
echo "Swap partition: $SWAP_PARTITION"
echo "Root partition: $ROOT_PARITION" 

# I decided to use a mbr/msdos partition table instead of gtp since it is still
# easier to install boot loaders for systems that use mbr instead of gtp.
# This in turn means that we can not be using UEFI. Instead we have to use BIOS.
# https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface

# If you want to change to gtp instead of mbr you should use mklabel gtp instead
# of mklabel msdos.

# Start on the 3rd MB of the disk so we have an MBR gap that is large enough
# to hold Grub.
parted -a optimal -s $DISK \
unit MB \
mklabel msdos \
mkpart primary ext2 3 259 \
mkpart primary linux-swap 259 4355 \
mkpart primary ext4 4356 100% 

# Create and mount swap
mkswap SWAP_PARTITION

# Format the boot partition with ext2
mkfs.ext2 -T small $BOOT_PARTITION

# Format the root partition with ext4
mkfs.ext4 $ROOT_PARTITION

# Activate swap partition
swapon $SWAP_PARTITION

# Mount the root partition
mount $ROOT_PARTITION /mnt/gentoo
