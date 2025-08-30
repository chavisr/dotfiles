#!/bin/sh

pacman -Qqne > ~/.config/pkglist.txt
pacman -Qqme > ~/.config/foreignpkglist.txt

echo 'Packages list generated.'
