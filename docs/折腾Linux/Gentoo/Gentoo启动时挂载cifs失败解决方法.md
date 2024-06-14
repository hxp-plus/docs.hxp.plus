---
tags:
  - Gentoo
  - Linux
---

# Gentoo 启动时挂载 cifs 失败解决方法

## 问题描述

今日观察到 Gentoo 重启后 cifs 挂载项丢失，其中 `/etc/fstab` 是这样写的：

```
//192.168.11.254/downloads/others /mnt/winshare cifs credentials=/etc/cifs-credentials,uid=3000,gid=3000,_netdev 0 0
```

启动报错里 `dmesg` 大致为网络不可达类型的报错。

## 排查方向

### 检查网卡名字是否匹配

- 检查 `/etc/init.d/net.*` 网卡配置文件的网卡名称是否是当前网卡名称。
- 检查 `/etc/conf.d/net` 中配置的网卡名称。

### 检查 dhcpcd 和网卡服务启动状态

在服务 `net.eth0` 开启的情况下，服务 `dhcpcd` 应该不设置开机启动，而由 `net.eth0` 拉起。

### 配置挂载前网络依赖

配置文件 `/etc/conf.d/netmount` ：

```
rc_need="net.eth0"
rc_need="dhcpcd"
```

配置文件 `/etc/conf.d/net-online` ：

```
interfaces="eth0"
include_ping_test=yes
ping_test_host=192.168.11.1
timeout=120
```

同时将这两个服务开机自启动。
