#!/bin/sh
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
echo en_GB.UTF-8 > /etc/locale.gen
locale-gen
echo LANG=en_GB.UTF-8 > /etc/locale.conf
echo KEYMAP=uk > /etc/vconsole.conf
echo test > /etc/hostname
echo -e 127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\ttest > /etc/hosts
mkinitcpio -P
passwd
yes | pacman -S grub
grub-install /dev/vda
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable dhcpcd