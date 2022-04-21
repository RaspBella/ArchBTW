#!/bin/bash
check_for_xorg(){
	if [ ! -d /etc/X11 ]
	then
		echo "You don't seem to have X11 installed so lets install xorg"
		pacman -S --noconfirm xorg
	fi
}

PS3='Options: '
while true; do
	select option in "Awesome" "Gnome" "KDE Plasma" "Qtile" "XFCE" "Print options" "Quit"; do
		case $REPLY in
			1)
				check_for_xorg
				pacman -S --noconfirm awesome xorg-xinit compton kitty vim
				mkdir -p ~/.config/awesome
				curl https://raw.githubusercontent.com/RaspBella/dotfiles/main/.config/awesome/rc.lua > ~/.config/awesome/rc.lua
				;;
			2)
				check_for_xorg
				pacman -S --noconfirm gnome
				systemctl enable gdm
				;;
			3)
				check_for_xorg
				pacman -S --noconfirm plasma kde-applications
				systemctl enable sddm
				;;
			4)
				check_for_xorg
				pacman -S --noconfirm qtile
				;;
			5)
				check_for_xorg
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
