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

PACKAGES=(base linux linux-firmware dhcpcd vim make)

WIFI_OR_NOT(){
    read -r -p "Will you be using WiFi? [y/N] " WIFI
    case $WIFI in
        [yY][eE][sS]|[yY])
            PACKAGES+=(iwd)
            WIFI_MESSAGE="When you boot into Arch after installing you will have to connect to the internet with
            iwctl station DEVICE connect SSID
            e.g DEVICE could be wlan0 and SSID could be home-wifi"
            ;;
        [nN][oO]|[nN]|"")
            WIFI_MESSAGE=""
            ;;
    esac
}

#Main commands/funcs
loadkeys uk
CHECK_UEFI
timedatectl set-ntp true
GET_DISK
GET_PART_NUM_SCHEME
PARTITIONING
FORMATTING
MOUNTING
reflector -c GB
WIFI_OR_NOT
pacstrap /mnt ${PACKAGES[*]}
genfstab -U /mnt >> /mnt/etc/fstab

#Arch chroot script, extras script
mv chroot.sh /mnt
mv extras /mnt
arch-chroot /mnt ./chroot.sh

#Removing the chroot script
rm /mnt/chroot.sh

#Unmounting
if [ $UEFI = true ]; then
umount /dev/"$DISK""$PART"1
swapoff /dev/"$DISK""$PART"2
umount /dev/"$DISK""$PART"3
else
swapoff /dev/"$DISK""$PART"1
umount /dev/"$DISK""$PART"2
fi

if [ ! -z $WIFI_MESSAGE ]; then
echo $WIFI_MESSAGE

#Extra message
echo "ArchBTW is done, if however you want a Graphical environment and don't know where to start run 'make -f extras' from your home directory after rebooting, as the script will be putting a makefile in your users home directory."
