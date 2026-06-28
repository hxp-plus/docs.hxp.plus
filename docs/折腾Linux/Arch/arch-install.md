---
tags:
  - Arch Linux
  - Linux
---

# 从零开始安装 Arch Linux


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Install Arch Linux from Scratch

## 下载 ISO

下载 [Arch Linux ISO 镜像](https://archlinux.org/download/)

通过 [Rufus](https://rufus.ie/) 烧录到 U 盘

访问 [阿里云镜像站](https://developer.aliyun.com/mirror/) 以加快下载速度

## 启动 Live 环境

如果遇到类似 "nouveau: unknown chipset" 的错误，按 `e` 键编辑 grub 启动项，添加

```
nomodeset
```

连接 Wi-Fi

```bash
iwctl
station wlan0 scan
station wlan0 get-networks
station wlan0 connect SSID
```

更新系统时间

```bash
timedatectl set-ntp true
```

磁盘分区

```bash
fdisk /dev/sdX
```

挂载文件系统

```bash
mount /dev/partition /mnt
```

## 安装基础系统

使用镜像列表

```bash
vim /etc/pacman.d/mirrorlist
```

安装基础系统

```bash
pacstrap /mnt base linux linux-firmware
```

生成 fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

切换 root 环境

```bash
arch-chroot /mnt
```

生成 ramfs

```bash
mkinitcpio -P
```

设置 root 密码

```bash
passwd
```

安装必要的软件包

```bash
pacman -S iw vim
```

## 安装 Grub

```bash
mkdir /boot/efi
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

## 安装 KDE Plasma

```bash
pacman -S plasma
pacman -S kde-applications
systemctl enable sddm
```

---

## 原文（English）

```
---
tags:
  - Arch Linux
  - Linux
---

# Install Arch Linux from Scratch


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Download iso

Download [Arch Linux iso image](https://archlinux.org/download/) 

burn it via [Rufus](https://rufus.ie/)

Visit [Aliyun mirrors](https://developer.aliyun.com/mirror/) for faster download

## Boot Live Environment

if you encountered error like "nouveau: unknown chipset", hit `e` to edit grub, add

```
nomodeset
```

Connect to wifi

```bash
iwctl
station wlan0 scan
station wlan0 get-networks
station wlan0 connect SSID
```

Update time

```bash
timedatectl set-ntp true
```

Partition disk

```bash
fdisk /dev/sdX
```

Mount filesystems

```bash
mount /dev/partition /mnt
```

## Install Base System

Use mirrorlist

```bash
vim /etc/pacman.d/mirrorlist
```

Install base system

```bash
pacstrap /mnt base linux linux-firmware
```

Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

Change root

```bash
arch-chroot /mnt
```

Generate ramfs

```bash
mkinitcpio -P
```

Set root password

```bash
passwd
```

install packages that are necessary

```bash
pacman -S iw vim
```

## Install Grub

```bash
mkdir /boot/efi
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

## Install KDE Plasma

```bash
pacman -S plasma
pacman -S kde-applications
systemctl enable sddm
```
```
