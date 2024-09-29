---
tags:
  - OpenWrt
  - AX9000
---

# 小米 AX9000 解锁 SSH

## 刷入小米开发版固件

下载[小米路由器修复工具](./attachments/【密码：MiWiFi】MIWIFIRepairTool.x86.7z)和[小米路由器开发版固件 1.0.140](./attachments/miwifi_ra70_all_develop_1.0.140.bin)，进行刷机。下载地址也可在[小米路由器官网](https://www.miwifi.com/miwifi_download.html)下载。

## 安装 docker

准备一个格式化成 ext4 格式且大于 64GB 的 U 盘，插入 AX9000，登录[小米路由器后台](http://192.168.31.1)安装 docker 后安装管理插件。

## 启动 busybox 容器

使用安装好的 docker 启动 busybox 容器：

- Image: docker.io/busybox
- Console: Interactive & TTY
- Advanced container settings:
  - Volumes:
    - container: /mnt, Bind
    - host: /, Writable

之后返回容器列表，点击 busybox 容器后回形针图标，进入容器。

## chroot 到 AX9000 并获取 SSH

在容器内执行：

```bash
chroot /mnt
vi /etc/init.d/dropbear
```

编辑 `/etc/init.d/dropbear` 注释以下几行：

```bash
start_service()
{
        # 稳定版不能打开ssh服务
        #flg_ssh=`nvram get ssh_en`
        #channel=`/sbin/uci get /usr/share/xiaoqiang/xiaoqiang_version.version.CHANNEL`
        #if [ "$flg_ssh" != "1" -o "$channel" = "release" ]; then
        #       return 0
        #fi

        [ -s /etc/dropbear/dropbear_rsa_host_key ] || keygen

        . /lib/functions.sh
        . /lib/functions/network.sh

        config_load "${NAME}"
        config_foreach dropbear_instance dropbear
}
```

启动 SSH 服务：

```bash
/etc/init.d/dropbear start
```

修改 root 密码：

```bash
passwd root
```

## 固化 SSH

如果想让升级后依旧保留 SSH 权限，需要固化，固化直接使用这个工具即可：<https://github.com/paldier/ax3600_tool>

注意 AX9000 的 bdata 分区是 mtd18

```
root@XiaoQiang:~# cat /proc/mtd
dev: size erasesize name
mtd0: 00100000 00020000 "0:SBL1"
mtd1: 00100000 00020000 "0:MIBIB"
mtd2: 00080000 00020000 "0:BOOTCONFIG"
mtd3: 00080000 00020000 "0:BOOTCONFIG1"
mtd4: 00300000 00020000 "0:QSEE"
mtd5: 00300000 00020000 "0:QSEE_1"
mtd6: 00080000 00020000 "0:DEVCFG"
mtd7: 00080000 00020000 "0:DEVCFG_1"
mtd8: 00080000 00020000 "0:APDP"
mtd9: 00080000 00020000 "0:APDP_1"
mtd10: 00080000 00020000 "0:RPM"
mtd11: 00080000 00020000 "0:RPM_1"
mtd12: 00080000 00020000 "0:CDT"
mtd13: 00080000 00020000 "0:CDT_1"
mtd14: 00080000 00020000 "0:APPSBLENV"
mtd15: 00100000 00020000 "0:APPSBL_1"
mtd16: 00100000 00020000 "0:APPSBL"
mtd17: 00080000 00020000 "0:ART"
mtd18: 00080000 00020000 "bdata"
mtd19: 00080000 00020000 "crash"
mtd20: 00080000 00020000 "crash_syslog"
mtd21: 03800000 00020000 "rootfs"
mtd22: 03800000 00020000 "rootfs_1"
mtd23: 00100000 00020000 "cfg_bak"
mtd24: 03d80000 00020000 "overlay"
mtd25: 04000000 00020000 "mifw_bak"
mtd26: 005ef000 0001f000 "kernel"
mtd27: 02283000 0001f000 "ubi_rootfs"
mtd28: 0087a000 0001f000 "rootfs_data"
mtd29: 03013000 0001f000 "data"
```

所以备份命令是：

```bash
nanddump -f /tmp/bdata_mtd18.img /dev/mtd18
```

## 参考资料

<https://blog.nanpuyue.com/2022/056.html>
