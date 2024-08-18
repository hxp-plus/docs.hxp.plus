---
tags:
  - Linux
  - tlog
---

# 使用 tlog 对登录到 Linux 上的用户进行录屏

## 项目背景

需要对 SSH 登录到 Linux 服务器上的用户进行录屏，主要有两种需求：

1. 记录自己在 Linux 上的操作。
2. 如果别人做了什么蠢事，把他揪出来。

## 安装 tlog

从 [GitHub 仓库](https://github.com/Scribery/tlog) 的 Releases 页面下载 tlog 源码，之后安装依赖 （以 RHEL 8 为例）：

```bash
yum install gcc make m4 json-c-devel systemd-devel libcurl-devel
```

之后对源码进行编译安装：

```bash
./configure --prefix=/opt/tlog --sysconfdir=/etc --localstatedir=/var && make
make install
```

## 为用户启用 tlog

启用 tlog 需要修改用户登录 shell ：

```bash
usermod -s /opt/tlog/bin/tlog-rec-session hxp
```

修改 pam 配置 `/etc/pam.d/sshd` 和 `/etc/pam.d/system-auth` ，加入：

```text
session     required      pam_env.so readenv=1 envfile=/etc/locale.conf
```

修改系统临时文件目录配置 `/usr/lib/tmpfiles.d/tlog.conf` ，加入：

```text
d /var/run/tlog 1777 root root 10d
```

创建 `/var/run/tlog/` 目录：

```bash
mkdir -p /var/run/tlog/
chmod 1777 /var/run/tlog/
```

## 查看录屏

录屏会录入到 journal ，查看 journal 中用户登录记录获取 ID 后：

```bash
tlog-play -r journal -M TLOG_REC=12ca5b356065453fb50adfe57007658a-306a-26f2910 -s 5
```
