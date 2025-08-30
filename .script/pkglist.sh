#!/bin/sh

# This script is triggered by /etc/pacman.d/hooks/pkglist.hook
pacman -Qqne > /home/chavi/.config/pkglist.txt
pacman -Qqme > /home/chavi/.config/foreignpkglist.txt

echo 'Packages list generated.'
