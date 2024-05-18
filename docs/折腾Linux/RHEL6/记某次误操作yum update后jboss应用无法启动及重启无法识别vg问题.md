---
tags:
  - RHEL6
  - Linux
---

# 记某次误操作 yum update 后 jboss 应用无法启动及重启无法识别 vg 问题

## 问题描述

在一次开启 kdump 的操作中，因为误操作导致执行了 `yum update -y` ，即使在中途被发现后按 Ctrl-C 退出，但是还是有部分软件包被升级。误操作当时，内核和 java 等组件被升级，且当晚进行了修改 grub 的操作使得重启后依旧进入旧内核。

但是后续发现 jboss 在重启后，jboss 能启动但是 jboss 的应用无法启动，报错为国密证书无法加载。且在重启后报错找不到逻辑卷。

## 问题解决过程

### jboss 应用无法启动

经过和正常节点的对比，jboss 无法启动可能是由于 java 被升级导致，进行了 java 的降级（降级需要将系统的 YUM 源修改到 RHEL6.4 的 YUM 源）：

```
yum install java-1.7.0-openjdk-1.7.0.9-2.3.4.1.el6_3
yum reinstall java-1.7.0-openjdk-1.7.0.9-2.3.4.1.el6_3
```

经过 java 的降级后，jboss 应用无法启动问题被解决。

### 系统重启后报错 /var 目录和 /tmp 目录疑似损坏

后续又发现在重启后，由于 RHEL6 的 /etc/fstab 默认配置启动时 fsck ，fsck 报错 /var 和 /tmp 损坏。在系统进入 enmergency shell 后，输入 root 密码，首先尝试使用 `lvm lvs` 命令检查逻辑卷是否还在，发现报错：

```
File-based locking initialisation failed
```

查询文档得知，此报错是由于 `/var/lock/lvm` 目录无法写入导致。根本原因为在 emergency shell 中，根目录是以只读的方式挂载的，需要重新挂载为读写：

```
mount -o remount,rw /
```

之后发现 `lvs` 命令正常，但是所有逻辑卷都没有 activate ，且运行此命令可以 activate 所有逻辑卷：

```
vgchange -ay rootvg
```

之后排查文件系统损坏问题，尝试使用 `e2fsck` 命令修复文件系统：

```
e2fsck /dev/rootvg/lv_var
e2fsck /dev/rootvg/lv_tmp
```

但是发现文件系统没有损坏。重启以后，故障没有恢复，依旧是找不到除了根目录和 swap 以外所有逻辑卷。经过仔细分析系统启动时挂载逻辑卷的原理为执行 `/etc/rc.sysinit` 脚本中有一句 vgchange 命令激活逻辑卷。猜测是此命令没有正确执行导致，因为进入 emergency shell 的现象就是 vg 没有激活，且根目录和 swap 被激活。仔细和正常的机器进行对比，得出解决方案如下：

修改 /etc/rc.sysinit ，将：

```
action $"Setting up Logical Volume Management:" /sbin/lvm vgchange -a ay --sysinit --ignoreskippedcluster
```

修改为：

```
action $"Setting up Logical Volume Management:" /sbin/lvm vgchange -a ay --sysinit
```

问题的根本原因，猜测为 `yum update -y` 升级了 `/etc/rc.sysinit` 但是没有升级 lvm ，或者升级 lvm 的过程中被终止，导致 `/etc/rc.sysinit` 被更新加入了 `--ignoreskippedcluster` 参数，但是 vgchange 命令和 lvm 没有被更新。实际在机器上实行 `/sbin/lvm vgchange -a ay --sysinit --ignoreskippedcluster` 报错信息为“参数--ignoreskippedcluster 未知”也印证了这一点。

## 参考文献

<https://access.redhat.com/solutions/47028>
<https://access.redhat.com/solutions/22545>
