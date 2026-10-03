# Artix Linux: encrypted root and swap

A fresh installation using dinit, UEFI, GRUB, and ext4. Root uses LUKS
encryption; swap uses a new random key at every boot. `/boot` is unencrypted.
Suspend-to-RAM works, but **hibernation is not supported**.

Original installation steps confirmed working by the guide's author on
2026-10-02. The added Ethernet option has not yet been tested.

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

Inspect the disks and confirm the target disk:

```sh
lsblk
```

### Command-line partitioning with sfdisk

This creates a new GPT partition table on `/dev/vda`, replacing its existing
partition layout. The example allocates **1 GiB for EFI**, **4 GiB for swap**,
and the remaining space for root. Adjust the sizes before running it:

```sh
sfdisk /dev/vda <<'EOF'
label: gpt
size=1GiB, type=U
size=4GiB, type=S
type=L
EOF
```

Check the resulting partition layout:

```sh
fdisk -l /dev/vda
```

### Format and mount

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

## 2. Install packages and enter the chroot

### Base system and kernel — live environment

Time synchronization via chronyd is already enabled in the live environment.
Use `basestrap` to install the base system into `/mnt`:

```sh
basestrap /mnt base base-devel dinit elogind-dinit
```

Install the kernel and firmware into the same target:

```sh
basestrap /mnt linux linux-firmware
```

### Generate fstab and enter the chroot — live environment

Generate the filesystem table:

```sh
fstabgen -U /mnt > /mnt/etc/fstab
```

Enter the installed system:

```sh
artix-chroot /mnt
```

### Additional packages — chroot

**Run all remaining commands through section 7 inside this chroot.**
Use `pacman` here to install packages directly into the installed system.

Install encryption support, editing tools, the bootloader, time synchronization,
Intel microcode, audio firmware, and kernel headers:

```sh
pacman -S cryptsetup cryptsetup-dinit vim grub efibootmgr chrony-dinit \
  intel-ucode sof-firmware linux-headers
```

Install the packages for your chosen network connection. For Ethernet:

```sh
pacman -S dhcpcd-dinit
```

For Wi-Fi:

```sh
pacman -S iwd-dinit openresolv
```

Configure and enable the chosen network service in section 7.

## 3. Configure encrypted swap — chroot

Store the swap partition's **PARTUUID**:

```sh
export SWAP_PARTUUID="$(blkid -s PARTUUID -o value /dev/vda2)"
```

Append the encrypted swap entry to `/etc/crypttab`:

```sh
cat >> /etc/crypttab <<EOF
swap PARTUUID=$SWAP_PARTUUID /dev/urandom plain,swap,cipher=aes-xts-plain64,size=256
EOF
```

Confirm the PARTUUID belongs to `/dev/vda2`: its encrypted mapping will be
formatted at every boot. Use the PARTUUID because the swap filesystem UUID
changes each time.

Append the encrypted swap entry to `/etc/fstab`, keeping the generated root
and `/boot` entries:

```sh
cat >> /etc/fstab <<'EOF'
/dev/mapper/swap none swap defaults 0 0
EOF
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

Set the hostname and append its `/etc/hosts` entry, keeping the existing
localhost entries:

```sh
echo artix-linux > /etc/hostname
cat >> /etc/hosts <<'EOF'
127.0.1.1        artix-linux.localdomain  artix-linux
EOF
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

Follow the Ethernet or Wi-Fi instructions for the packages installed in
section 2, then enable time synchronization below.

### Ethernet

Connect an Ethernet cable to a network with DHCP.

Enable the DHCP client:

```sh
dinitctl --offline enable dhcpcd
```

The `dhcpcd` service configures the address, gateway, and DNS automatically
at boot. Skip the Wi-Fi steps when using Ethernet.

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

Enable chronyd in the installed system for either network method:

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

For the Ethernet setup, also check the network:

```sh
dinitctl status dhcpcd
ip -brief address
ip route
ping -c 3 artixlinux.org
```

Expect an address on the Ethernet interface and a default route.

## References

- [Artix installation guide](https://wiki.artixlinux.org/Main/Installation)
- [Arch Wiki: encrypting an entire system](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system)
- [crypttab manual](https://man.archlinux.org/man/crypttab.5.en) — the parser's `PARTUUID`, `plain`, and `swap` options.
