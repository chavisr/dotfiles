## connect wifi
```sh
rfkill unblock wifi
ip link set wlan0 up
connmanctl
    scan wifi
    services
    agent on
    connect <wifi_>
    quit
pacman -Syy
```
## partitioning
```sh
lsblk

cfdisk /dev/sdb

mkfs.ext4 /dev/sdb3
mkfs.fat -F32 /dev/sdb1
mkswap /dev/sdb2

mount /dev/sdb3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sdb1 /mnt/boot/efi
swapon /dev/sdb2
```
## post-install
```sh
pacman -S os-prober iwd-dinit resolvconf linux-firmware linux-headers nano amd-ucode pulseaudio pavucontrol river wideriver waybar alacritty polkit-gnome

passwd

useradd -m -G wheel -s /bin/bash chavi
passwd chavi

EDITOR=nano visudo

mkdir /etc/iwd
nano /etc/iwd/main.conf
```sh
[General]
EnableNetworkConfiguration=true
[Network]
RoutePriorityOffset=200
NameResolvingService=resolvconf
```
## connect ethernet
```sh
sudo ip link set eth0 up
sudo ip addr add 192.168.0.249/24 dev eth0
sudo ip route add default via 192.168.0.1
```
