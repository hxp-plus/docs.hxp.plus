---
tags:
  - Linux
  - GRUB
---

# Arch Linux 修复 GRUB

Today I encountered the most catastrophic incident I have ever had since I installed Arch Linux. I restored my BIOS to factory default. And after that, I cannot start my system any more. My laptop kept telling me "boot device not found". When I was young I used to reinstall the whole system to solve this problem. But as for now, I don't want to install Arch Linux again.

I tried to insert a linux live cd, it boots.

So here is my solution to this problem: reinstalling grub.

First, you need an Arch Linux live cd. I do not know whether other linux distro works as the same, so please use the Arch Linux one.

And we mount `/dev/sda2` to `/mnt` as we did during the installation of Arch Linux.

```shell
mount /dev/sda2 /mnt
```

Then we `chroot`

```shell
arch-chroot /mnt
```

Mount the `efi` partition and install grub

```shell
mount /dev/sda1 /boot/efi
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
```

And reboot

```shell
exit
reboot
```

After grub was reinstalled, my Arch Linux booted.
