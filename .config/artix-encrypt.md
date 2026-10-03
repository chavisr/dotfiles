# Artix Linux: encrypted root and swap

A fresh installation using dinit, UEFI, GRUB, and ext4. Root uses LUKS
encryption; swap uses a new random key at every boot. `/boot` is unencrypted.
Suspend-to-RAM works, but **hibernation is not supported**.

Original installation steps confirmed working by the guide's author on
2026-10-02. The added VM Ethernet option has not yet been tested in the VM.

## Before you start

Boot an Artix dinit live image in UEFI mode and connect to the internet.
Run the installation commands as **root**. Each section states whether to
run it in the live environment, inside the chroot, or after reboot.

These commands format the target partitions. Back up any data you need and
confirm the disk name before continuing.

The examples use this layout:

| Partition | Purpose | Format / mapping | Mount point |
| --- | --- | --- | --- |
| `/dev/vda1` | EFI System Partition | FAT32 | `/boot` |
| `/dev/vda2` | Encrypted swap | Plain dm-crypt → `/dev/mapper/swap` | Swap |
| `/dev/vda3` | Encrypted root | LUKS → `/dev/mapper/root`, ext4 inside | `/` |

Choose partition sizes for your machine. Replace `/dev/vda` and its
partition names throughout if your target disk differs. The package list
assumes an Intel CPU. The examples also use hostname `artix-linux`, user `artix`,
and timezone `Asia/Bangkok`; adjust these as needed.

## 1. Partition and format — live environment

Inspect the disks, then create a GPT partition table with the three
partitions above. Set partition 1 to **EFI System**, partition 2 to
**Linux swap**, and partition 3 to **Linux filesystem**.

```sh
lsblk
cfdisk /dev/vda
```

Create and unlock the root container, then format and mount its filesystem:

```sh
cryptsetup -v luksFormat /dev/vda3
cryptsetup open /dev/vda3 root
mkfs.ext4 /dev/mapper/root
mount /dev/mapper/root /mnt
```

Format and mount the EFI partition:

```sh
mkfs.fat -F 32 /dev/vda1
mkdir /mnt/boot
mount /dev/vda1 /mnt/boot
```

Leave partition 2 unused for now. The installed system will create encrypted
swap at boot. Do not run `mkswap` or `swapon` on the raw partition.

## 2. Install the base system — live environment

Start time synchronization and install the packages:

```sh
dinitctl start chronyd

basestrap /mnt base base-devel dinit elogind-dinit
basestrap /mnt linux linux-firmware
basestrap /mnt cryptsetup cryptsetup-dinit vim grub efibootmgr \
  openresolv iwd-dinit sof-firmware intel-ucode linux-headers chrony-dinit
```

Generate the filesystem table, then enter the installed system:

```sh
fstabgen -U /mnt > /mnt/etc/fstab
artix-chroot /mnt
```

**Run sections 3–7 inside this chroot.**

## 3. Configure encrypted swap — chroot

Get the swap partition's **PARTUUID**, then open `/etc/crypttab`:

```sh
blkid -s PARTUUID -o value /dev/vda2
vim /etc/crypttab
```

Add the following line, replacing `SWAP_PARTUUID_HERE` with that output:

```text
swap PARTUUID=SWAP_PARTUUID_HERE /dev/urandom plain,swap,cipher=aes-xts-plain64,size=256
```

Confirm the PARTUUID belongs to `/dev/vda2`: its encrypted mapping will be
formatted at every boot. Use the PARTUUID because the swap filesystem UUID
changes each time.

```sh
vim /etc/fstab
```

Keep the root and `/boot` entries, and replace any swap entries with:

```text
/dev/mapper/swap none swap defaults 0 0
```

Enable automatic setup at boot:

```sh
dinitctl --offline enable cryptsetup
```

## 4. Set timezone, locale, and hostname — chroot

Set the timezone and write the system time to the hardware clock:

```sh
ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime
hwclock --systohc
```

Open `/etc/locale.gen` and uncomment `en_US.UTF-8 UTF-8`:

```sh
vim /etc/locale.gen
```

Generate the locale and set the defaults:

```sh
locale-gen
cat > /etc/locale.conf <<'EOF'
LANG="en_US.UTF-8"
LC_COLLATE="C"
EOF
```

Set the hostname:

```sh
echo artix-linux > /etc/hostname
vim /etc/hosts
```

Add or update the `127.0.1.1` entry below, keeping the existing localhost entries:

```text
127.0.1.1        artix-linux.localdomain  artix-linux
```

## 5. Configure the initramfs and GRUB — chroot

### Enable root unlocking

```sh
vim /etc/mkinitcpio.conf
```

In the active `HOOKS` array, add `encrypt` before `filesystems`.
Keep the other hooks, then rebuild the initramfs:

```sh
mkinitcpio -P
```

### Install and configure GRUB

```sh
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
vim /etc/default/grub
```

Set `GRUB_CMDLINE_LINUX_DEFAULT` as follows. Preserve any existing kernel
arguments you need.

```text
GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=UUID=LUKS_UUID_HERE:root root=UUID=ROOT_UUID_HERE"
```

Save the file with those placeholders, then replace them with the actual UUIDs:

```sh
sed -i "s|LUKS_UUID_HERE|$(blkid -o value -s UUID /dev/vda3)|" /etc/default/grub
sed -i "s|ROOT_UUID_HERE|$(blkid -o value -s UUID /dev/mapper/root)|" /etc/default/grub
```

The first UUID identifies the LUKS container; the second identifies the ext4
filesystem inside it. Generate the GRUB configuration:

```sh
grub-mkconfig -o /boot/grub/grub.cfg
```

## 6. Create user accounts — chroot

Set the root password, create your user, and add it to the `wheel` group:

```sh
passwd
useradd -m -s /bin/bash artix
passwd artix
usermod -aG wheel artix
```

Open the sudo configuration and uncomment the rule that grants the `wheel`
group sudo access:

```sh
EDITOR=vim visudo
```

## 7. Configure networking and services — chroot

Choose Ethernet for a VM or Wi-Fi for a wireless connection, then enable
time synchronization below.

### Ethernet — VM

In the VM settings, enable a virtual network adapter connected to a NAT
network with DHCP. The guest sees it as Ethernet even if the host uses Wi-Fi.

Install and enable the DHCP client inside the chroot:

```sh
pacman -S dhcpcd-dinit
dinitctl --offline enable dhcpcd
```

This installs `dhcpcd` and its dinit service to configure the address, gateway,
and DNS automatically at boot. Skip the Wi-Fi steps for this VM setup.

### Wi-Fi

Create `/etc/iwd/main.conf` with the following contents. IWD will manage
Wi-Fi addresses and use openresolv for DNS:

```ini
[General]
EnableNetworkConfiguration=true

[Network]
RoutePriorityOffset=200
NameResolvingService=resolvconf
```

Enable Wi-Fi:

```sh
dinitctl --offline enable iwd
```

### Time synchronization

Enable chrony for either network method:

```sh
dinitctl --offline enable chronyd
```

## 8. Leave the chroot and reboot

Exit the chroot, then unmount the installed system and reboot from the live
environment:

```sh
exit
umount -R /mnt
reboot
```

Boot from the installed disk. Enter the root LUKS passphrase when prompted;
swap is set up automatically without a password prompt.

## 9. Verify the installation — installed system

Log in and run these checks as root:

```sh
lsblk -f
swapon --show
cryptsetup status swap
```

Check that `root` is mounted at `/`, `/dev/vda1` at `/boot`, and `swap`
under `/dev/vda2` is marked `[SWAP]`. If `swapon` displays `/dev/dm-N`, use
`lsblk` to match it to the encrypted swap mapping.

For the VM Ethernet setup, also check the network:

```sh
dinitctl status dhcpcd
ip -brief address
ip route
ping -c 3 artixlinux.org
```

Expect an address on the virtual Ethernet interface and a default route.

## References

- [Artix installation guide](https://wiki.artixlinux.org/Main/Installation)
- [Arch Wiki: encrypting an entire system](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system)
- [Debian crypttab documentation](https://manpages.debian.org/unstable/cryptsetup/crypttab.5.en.html) — the parser's `PARTUUID`, `plain`, and `swap` options.
- [dhcpcd manual](https://man.archlinux.org/man/dhcpcd.8.en) — automatic network configuration for Ethernet.
