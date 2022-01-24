#!/bin/sh

CHECK_UEFI(){
    if [ -e /sys/firmware/efi/efivars ]; then
    UEFI=true
    else
    UEFI=false
    fi
}

GET_DISK(){
    DISKS=$(lsblk -d -n -o KNAME)
    PS3="Please select a disk: "
    select DISK in ${DISKS[*]}; do
    break
    done
}

GET_PART_NUM_SCHEME(){
    if [[ $DISK = nvme??? ]]; then
    PART=p
    else
    PART=""
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
        mkfs.fat -F32 /dev/"$DISK""$PART"1
        mkswap /dev/"$DISK""$PART"2
        mkfs.ext4 /dev/"$DISK""$PART"3
    }

    LEGACY_FORMAT(){
        mkswap /dev/"$DISK""$PART"1
        mkfs.ext4 /dev/"$DISK""$PART"2
    }

    if [ $UEFI = true ]; then
    UEFI_FORMAT
    else
    LEGACY_FORMAT
    fi
}

MOUNTING(){
    UEFI_MOUNT(){
        swapon /dev/"$DISK""$PART"2
        mount /dev/"$DISK""$PART"3 /mnt
    }

    LEGACY_MOUNT(){
        swapon /dev/"$DISK""$PART"1
        mount /dev/"$DISK""$PART"2 /mnt
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
GET_DISK
GET_PART_NUM_SCHEME
PARTITIONING
FORMATTING
MOUNTING
reflector -c GB
pacstrap /mnt ${PACKAGES[*]}
genfstab -U /mnt >> /mnt/etc/fstab

#Arch chroot script
curl -L https://raw.githubusercontent.com/RaspBella/ArchBTW/main/chroot.sh > chroot.sh
chmod +x chroot.sh
mv chroot.sh /mnt
arch-chroot /mnt ./chroot.sh

#Unmounting
if [ $UEFI = true ]; then
umount /dev/"$DISK""$PART"1
swapoff /dev/"$DISK""$PART"2
umount /dev/"$DISK""$PART"3
else
swapoff /dev/"$DISK""$PART"1
umount /dev/"$DISK""$PART"2
fi
