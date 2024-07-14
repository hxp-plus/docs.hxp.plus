---
tags:
  - Linux
  - udev
---

# Linux 配置 udev 规则忽略磁盘

## 配置 udev 规则忽略磁盘

在安装 Proxmox VE 并使用 Clover 进行引导后，我不想在 PVE 里看到引导用的 U 盘/dev/sdd，需要配置 udev rule 来忽略引导 U 盘。首先抓取 udev 特征：

```bash
udevadm info -a -n /dev/sdd
```

重点关注 model 或者 vendor：

```
ATTRS{model}=="CHIPFANCIER     "
ATTRS{vendor}=="32G SLC "
```

然后新建文件 `/etc/udev/rules.d/99-hide-usb.rules` 如下：

```
KERNEL=="sd?", ATTRS{model}=="CHIPFANCIER     ", ATTRS{vendor}=="32G SLC ", ENV{UDISKS_IGNORE}="1", RUN+="/bin/sh -c '/usr/bin/echo deleted device %k >> /tmp/udev.log && echo 1 > /sys/block/%k/device/delete'"
```

使其生效：

```bash
udevadm control --reload && udevadm trigger
```

这个 udev rule 原理是有这个盘就删除这个盘。

## 参考链接

<https://www.baeldung.com/linux/shell-run-script-usb-plugged>

<https://askubuntu.com/questions/352836/how-can-i-tell-linux-kernel-to-completely-ignore-a-disk-as-if-it-was-not-even-co>

<https://unix.stackexchange.com/questions/25552/making-udev-ignore-certain-devices-during-boot>
