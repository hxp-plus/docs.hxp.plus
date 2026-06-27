---
tags:
  - Arch Linux
  - Linux
---

# Moving existing Arch Linux installation to VMWare


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 步骤 1：复制文件

挂载一个格式化为 ext4 的外部驱动器（这很重要，因为其他文件系统格式如 ntfs 无法保留文件权限）。`cd` 进入该驱动器，并使用 `rsync` 将现有系统上的所有文件复制到外部驱动器，保留文件权限、ACL 和所有属性。

```bash
sudo rsync -aAXH --progress  --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / .
```

然后卸载驱动器。

## 步骤 2：将所有文件复制到 VM

启动 VM，使用 Arch Linux live ISO 启动，使用 `fstab` 为 VM 中的 `/dev/sda` 创建分区表，用 `mkfs.ext4` 创建文件系统，然后将 `/dev/sda1` 挂载到 `/mnt` 或某个位置。

然后插入外部驱动器，将 `/dev/sdb1` 挂载到 `/old` 或某个位置。使用 `rsync` 将所有文件复制回去。

```bash
rsync -aAXH --progress /old/* /mnt/
```

## 步骤 3：重新生成 fstab

```bash
echo '# End of old fstab' >> /mnt/etc/fstab
genfstab -U /mnt >> /mnt/etc/fstab
```

然后用文本编辑器检查 `/mnt/etc/fstab`。

## 步骤 4：安装 GRUB

```bash
arch-chroot /mnt
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -p linux
```

## 步骤 5：退出并关机

```bash
exit
poweroff
```

---

## 原文（English）

---
tags:
  - Arch Linux
  - Linux
---

# Moving existing Arch Linux installation to VMWare


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Step 1: Copy files

mount an external drive, formatted in ext4 (this is important, cause other file system format such as ntfs cannot preserve file permissions). `cd` into the drive and use `rsync` to copy all files on the existing system to external drive, preserving file permission, ACL, and all attributes.

```bash
sudo rsync -aAXH --progress  --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / .
```

then umount the drive.

## Step 2: Copy all the files to the VM

Start VM, boot with archlinux live iso, use `fstab` to create partition table for `/dev/sda` in the VM, making file system with `mkfs.ext4`, then mount `/dev/sda1` to `/mnt` or somewhere. 

Then plug in the external drive and mount `/dev/sdb1` to `/old` or somewhere. Use `rsync` to copy all files back.

```bash
rsync -aAXH --progress /old/* /mnt/
```

## Step 3: Regenerate fstab

```bash
echo '# End of old fstab' >> /mnt/etc/fstab
genfstab -U /mnt >> /mnt/etc/fstab
```

Then check `/mnt/etc/fstab` with text editor.

## Step 4: Install GRUB

```bash
arch-chroot /mnt
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -p linux
```

## Step 5: Exit and poweroff

```bash
exit
poweroff
```
