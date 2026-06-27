---
tags:
  - Linux
---
# Linux忽略某个磁盘

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

在安装Proxmox VE并使用Clover进行引导后，我不想在PVE里看到引导用的U盘/dev/sdd，需要配置udev rule来忽略引导U盘。首先抓取udev特征：
```bash
udevadm info -a -n /dev/sdd
```
 重点关注model或者vendor：
```
ATTRS{model}=="CHIPFANCIER     "
ATTRS{vendor}=="32G SLC "
```
然后新建文件`/etc/udev/rules.d/99-hide-usb.rules`如下：
```
KERNEL=="sd?", ATTRS{model}=="CHIPFANCIER     ", ATTRS{vendor}=="32G SLC ", ENV{UDISKS_IGNORE}="1", RUN+="/bin/sh -c '/usr/bin/echo deleted device %k >> /tmp/udev.log && echo 1 > /sys/block/%k/device/delete'"
```
使其生效：
```bash
udevadm control --reload && udevadm trigger
```
这个udev rule原理是有这个盘就删除这个盘。

## 参考链接
<https://www.baeldung.com/linux/shell-run-script-usb-plugged>
<https://askubuntu.com/questions/352836/how-can-i-tell-linux-kernel-to-completely-ignore-a-disk-as-if-it-was-not-even-co>
<https://unix.stackexchange.com/questions/25552/making-udev-ignore-certain-devices-during-boot>
