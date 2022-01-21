#!/bin/sh

DISK=vda

CHECK_UEFI(){
    if [ -e /sys/firmware/efi/efivars ]; then
    UEFI=true
    else
    UEFI=false
    fi
}

PARTITIONING(){
    UEFI_PART(){
        fdisk /dev/$DISK << FDISK_CMDS
        g
        n


        +0.5G
        t
        uefi
        n


        +4G
        t

        swap
        n



        w
FDISK_CMDS
    }

    LEGACY_PART(){
        fdisk /dev/$DISK << FDISK_CMDS
        o
        n



        +4G
        t
        swap
        n




        w
FDISK_CMDS
    }

    if [ $UEFI = true ]; then
    UEFI_PART
    else
    LEGACY_PART
    fi
}

FORMATTING(){
    UEFI_FORMAT(){
        mkfs.fat -F32 /dev/"$DISK"1
        mkswap /dev/"$DISK"2
        mkfs.ext4 /dev/"$DISK"3
    }

    LEGACY_FORMAT(){
        mkswap /dev/"$DISK"1
        mkfs.ext4 /dev/"$DISK"2
    }

    if [ $UEFI = true ]; then
    UEFI_FORMAT
    else
    LEGACY_FORMAT
    fi
}

MOUNTING(){
    UEFI_MOUNT(){
        swapon /dev/"$DISK"2
        mount /dev/"$DISK"3 /mnt
    }

    LEGACY_MOUNT(){
        swapon /dev/"$DISK"1
        mount /dev/"$DISK"2 /mnt
    }

    if [ $UEFI = true ]; then
    UEFI_MOUNT
    else
    LEGACY_MOUNT
    fi
}

PACKAGES=(base linux linux-firmware nano dhcpcd)

loadkeys uk
CHECK_UEFI
timedatectl set-ntp true
PARTITIONING
FORMATTING
MOUNTING
reflector -c GB
pacstrap /mnt ${PACKAGES[*]}
genfstab -U /mnt >> /mnt/etc/fstab

#Arch chroot script
cp chroot.sh /mnt/
arch-chroot /mnt ./chroot.sh