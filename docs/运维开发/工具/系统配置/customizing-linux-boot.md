---
tags:
  - Linux
  - 工具
---

# 自定义 Linux 启动


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Customizing Linux Boot

To show kernel messages:

```
GRUB_CMDLINE_LINUX_DEFAULT="splash"
```

To enable hibernate:

```
GRUB_CMDLINE_LINUX="resume=UUID=3b745370-dce7-483a-abd4-27439f9cdea4"
```

disk UUID can be shown by `blkid` command.

generate `grub.cfg` :

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

and then edit `/etc/mkinitcpio.conf`, find the line that looks like this: 

```
HOOKS="base udev autodetect modconf block filesystems keyboard fsck"
```

It is located in the section named `HOOKS`. After `udev` insert hook `resume` (Like this: `..base udev resume..`) 

```
HOOKS="base udev resume autodetect modconf block filesystems keyboard fsck"
```

Save the file. run

```bash
mkinitcpio -p linux
```

to generate initramfs.



To boot into runlevel 3:

```bash
sudo systemctl set-default multi-user.target
```

To get current default runlevel:

```bash
sudo systemctl get-default
```