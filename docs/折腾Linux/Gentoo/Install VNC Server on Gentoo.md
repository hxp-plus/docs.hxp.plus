---
tags:
  - Gentoo
  - Linux
---

# 在 Gentoo 上安装 VNC 服务器


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Install VNC Server on Gentoo

## Emerge

```bash
echo 'net-misc/tigervnc server' >> /etc/portage/package.use/tigervnc
emerge --update --newuse net-misc/tigervnc
```

## Server Configuration

```bash
vncserver
mkdir -p ~/.vnc/
echo '#!/bin/sh
eval "$(dbus-launch --sh-syntax --exit-with-session)"
export LANG="zh_CN.utf8"         #日常用户的桌面以中文显示
export LC_ALL="zh_CN.UTF-8"
export LC_TYPE="zh_CN.utf8"
export XMODIFIERS="@im=fcitx"    #日常用户加载中文输入法
export QT_IM_MODULE="fcitx"
export GTK_IM_MODULE="fcitx"
startplasma-x11 &' >> ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup
echo DISPLAYS="hxp:1" >> /etc/conf.d/tigervnc
rc-service tigervnc start
```
