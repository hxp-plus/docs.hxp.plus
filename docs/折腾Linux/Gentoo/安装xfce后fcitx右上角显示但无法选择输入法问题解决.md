---
tags:
  - Gentoo
  - Linux
  - xfce
  - fcitx
---

# 安装 xfce 后 fcitx 右上角显示但无法选择输入法问题解决

## 问题描述

在安装 xfce 后，安装 fcitx-rime ，之后发现输入法的键盘图标在右上角能显示，但是右键无法选择输入法。已经尝试过的方法为：

- 将那三个环境变量同时配置于 `~/.xprofile` 、 `~/.xinitrc` 和 `/etc/profile.d/fcitx.sh` ，重启，问题依旧存在。
- 使用 `fcitx-diagnose` 诊断，发现无异常。
- 尝试使用 vnc 连接，问题依旧存在。

## 解决方法

安装 ibus 输入法后，问题自动解决，我也不知道为什么：

```
emerge --ask app-i18n/ibus ibus-libpinyin
```

表现为安装 ibus 后，我将三个环境变量清除：

```
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
```

然后改成了 ibus 的：

```
GTK_IM_MODULE=ibus
QT_IM_MODULE=ibus
XMODIFIERS=@im=ibus
```

之后没有卸载 fcitx ，重启后发现 xfce 右上角键盘图标变成加粗的图标， fcitx 莫名其妙地好了。删除 ibus 环境变量，不添加 fcitx 环境变量，重启，依旧是好的。
