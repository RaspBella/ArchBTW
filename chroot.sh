#!/bin/sh

CHECK_UEFI(){
    if [ -e /sys/firmware/efi/efivars ]; then
    UEFI=true
    else
    UEFI=false
    fi
}

GET_DISK(){
    DISK=$(lsblk -n -o PKNAME $(findmnt -n -o SOURCE /))
}

GET_PART_NUM_SCHEME(){
    if [[ $DISK = nvme??? ]]; then
    PART=p
    else
    PART=""
    fi
}

GRUB_UEFI(){
    yes | pacman -S grub efibootmgr
    mkdir /boot/efi
    mount /dev/"$DISK""$PART"1 /boot/efi
    grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
}

GRUB_LEGACY(){
    yes | pacman -S grub
    grub-install /dev/$DISK
}

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
echo en_GB.UTF-8 > /etc/locale.gen
locale-gen
echo LANG=en_GB.UTF-8 > /etc/locale.conf
echo KEYMAP=uk > /etc/vconsole.conf

#Get desired hostname
read -p 'Please enter a hostname: ' hostname

echo $hostname > /etc/hostname
echo -e 127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$hostname > /etc/hosts
mkinitcpio -P
passwd

GET_DISK
GET_PART_NUM_SCHEME

#grub
CHECK_UEFI
if [ $UEFI = true ]; then
GRUB_UEFI
else
GRUB_LEGACY
fi
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable dhcpcd