#!/bin/sh

# This script is triggered by /etc/pacman.d/hooks/post-transaction.hook
pacman -Qqne > /home/chavi/.config/pkglist.txt
pacman -Qqme > /home/chavi/.config/foreignpkglist.txt
echo 'Packages list generated.'

# Fix input rate bug after installing packages (x11 only)
# xset r rate 300 50
