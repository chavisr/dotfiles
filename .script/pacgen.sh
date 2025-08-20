#!/bin/sh

pacman -Qne > ~/.config/pac/native.txt
pacman -Qme > ~/.config/pac/foreign.txt

echo 'Package lists generated.'
