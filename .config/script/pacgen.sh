#!/bin/sh

pacman -Qne > ~/.config/script/native.txt
pacman -Qme > ~/.config/script/foreign.txt

echo 'Package lists generated.'
