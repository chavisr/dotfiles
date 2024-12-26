# wifi
connect wifi
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
# install artix
```sh
lsblk

cfdisk /dev/sdb
mkfs.fat -F32 /dev/sdb1
mkfs.ext4 /dev/sdb2

mount /dev/sdb2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sdb1 /mnt/boot/efi

lsblk

rc-service ntpd start
basestrap /mnt base base-devel openrc elogind-openrc linux linux-firmware linux-headers nano amd-ucode

fstabgen -U /mnt >> /mnt/etc/fstab

artix-chroot /mnt bash

dd if=/dev/zero of=/swapfile bs=1G count=1 status=progress
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile   none    swap    defaults 0 0' >> /etc/fstab

ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime
hwclock --systohc
nano /etc/locale.gen # uncomment en_US
locale-gen
```
nano `/etc/locale.conf`
```sh
export LANG="en_US.UTF-8"
export LC_COLLATE="C"
```
```sh
echo 'artix' > /etc/hostname
```
nano `/etc/hosts`
```sh
127.0.0.1        localhost
::1              localhost
127.0.1.1        artix.localdomain  artix
```
If you use OpenRC you should add your hostname to `/etc/conf.d/hostname` too
```sh
hostname='artix'
```

# install grub

```sh
pacman -S grub efibootmgr os-prober iwd-openrc resolvconf

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```
# post install
```sh
passwd

useradd -m -G wheel -s /bin/bash chavi
passwd chavi

EDITOR=nano visudo # uncomment wheel stuff

mkdir /etc/iwd
```
nano `/etc/iwd/main.conf`
```sh
[General]
EnableNetworkConfiguration=true
[Network]
RoutePriorityOffset=200
NameResolvingService=resolvconf
```
```sh
rc-update add iwd default
exit    # exit chroot environment
umount -R /mnt
reboot
```

# ethernet
```sh
sudo ip link set eth0 up
sudo ip addr add 192.168.0.249/24 dev eth0
sudo ip route add default via 192.168.0.1
```
