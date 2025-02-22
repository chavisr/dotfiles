#!/bin/sh

useradd -m -G wheel -s /bin/bash chavi

pacman -Syy

pacman -S os-prober iwd-dinit resolvconf ntp-dinit linux-firmware linux-headers nano \
    amd-ucode pulseaudio pavucontrol bspwm sxhkd polybar alacritty polkit-gnome \
    rofi picom xorg-server xorg-xinit xorg-xset ttf-jetbrains-mono ttf-jetbrains-mono-nerd \
    feh pcmanfm

# yay -S rofi-greenclip gruvbox-material-gtk-theme-git gruvbox-material-icon-theme-git
