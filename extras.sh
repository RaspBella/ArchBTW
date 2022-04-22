#!/bin/bash
pacman -S --needed --noconfirm xorg
PS3='Options: '
while true; do
	select option in "Awesome" "Gnome" "KDE Plasma" "Qtile" "XFCE" "Print options" "Quit"; do
		case $REPLY in
			1)
				pacman -S --noconfirm awesome xorg-xinit compton kitty vim
				mkdir -p ~/.config/awesome
				curl https://raw.githubusercontent.com/RaspBella/dotfiles/main/.config/awesome/rc.lua > ~/.config/awesome/rc.lua
				;;
			2)
				pacman -S --noconfirm gnome
				systemctl enable gdm
				;;
			3)
				pacman -S --noconfirm plasma kde-applications
				systemctl enable sddm
				;;
			4)
				pacman -S --noconfirm qtile xorg-xinit kitty
				;;
			5)
				pacman -S --noconfirm xfce4 xfce4-goodies gvfs lightdm lightdm-gtk-greeter
				systemctl enable lightdm
				;;
			6)
				break
				;;
			7)
				exit 0
				;;
		esac
	done
done
