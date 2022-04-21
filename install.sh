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



        w
FDISK_CMDS
    }

    LEGACY_PART(){
        fdisk /dev/$DISK << FDISK_CMDS
        o
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
        mkfs.ext4 /dev/"$DISK""$PART"2
    }

    LEGACY_FORMAT(){
        mkfs.ext4 /dev/"$DISK""$PART"1
    }

    if [ $UEFI = true ]; then
    UEFI_FORMAT
    else
    LEGACY_FORMAT
    fi
}

MOUNTING(){
    UEFI_MOUNT(){
        mount /dev/"$DISK""$PART"2 /mnt
    }

    LEGACY_MOUNT(){
        mount /dev/"$DISK""$PART"1 /mnt
    }

    if [ $UEFI = true ]; then
    UEFI_MOUNT
    else
    LEGACY_MOUNT
    fi
}

PACKAGES=(base linux linux-firmware dhcpcd vim)

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

#Swap stuff
fallocate -l 4G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
echo -e "#Swapfile\n/swapfile\tswap\tswap\tdefaults\t0\t0" >> /mnt/etc/fstab
echo "vm.swappiness=10" >> /mnt/etc/sysctl.d/99-swappiness.conf

#Arch chroot script, extras script
mv chroot.sh /mnt
mv extras.sh /mnt
arch-chroot /mnt ./chroot.sh

#Removing the chroot script
rm /mnt/chroot.sh

#Unmounting
if [ $UEFI = true ]; then
umount /dev/"$DISK""$PART"1
swapoff /mnt/swapfile
umount /dev/"$DISK""$PART"2
else
swapoff /mnt/swapfile
umount /dev/"$DISK""$PART"1
fi

if [ ! -z $WIFI_MESSAGE ]; then
echo $WIFI_MESSAGE

#Extra message
echo "ArchBTW is done, after rebooting into your new system you can run extras.sh to install a GUI environment."
