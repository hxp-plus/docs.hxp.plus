---
tags:
  - Linux
  - 工具
---

# Linux社团服务器使用指南


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 使用SSH进行命令行界面登录

| 服务器IP地址 | SSH端口 |
| ------------ | ------- |
| 211.67.25.90 | 22      |

请确认你连接的是**校园网**，在Linux终端、macOS的Terminal、iTerm2（推荐）和Windows的Windows Terminal、PowerShell（不推荐，界面太丑了）上：

```bash
ssh <你的用户名>@<服务器IP地址>
```

如果Windows的PowerShell报错，说明Windows的环境变量`$PATH`设置的不对。如果你不知道怎么更改环境变量那就不推荐更改环境变量，改错了容易出事而且Windows的PowerShell内置SSH不好用。

**Windows好用的SSH客户端有：Windows Terminal、XShell、MobaXterm、PuTTY**

## 使用VNC登录图形界面

请下载TigerVNC客户端（Linux、Windows、macOS通用）：<https://github.com/TigerVNC/tigervnc/releases>

<u>由于GitHub国内有些地方访问不了，群文件已经上传了一份TigerVNC客户端。</u>

之后用SSH登录上服务器，将以下内容加入到`~/.vnc/xstartup`下，如果没有`~/.vnc`这个目录，用命令`mkdir -p ~/.vnc/`创建，用`nano ~/.vnc/xstartup ` 编辑

```
#!/bin/sh
eval "$(dbus-launch --sh-syntax --exit-with-session)"
export LANG="zh_CN.utf8"         #日常用户的桌面以中文显示
export LC_ALL="zh_CN.UTF-8"
export LC_TYPE="zh_CN.utf8"
export XMODIFIERS="@im=fcitx"    #日常用户加载中文输入法
export QT_IM_MODULE="fcitx"
export GTK_IM_MODULE="fcitx"
startplasma-x11 &
```

编辑完成后按`Ctrl-X`退出（会询问你是否保存，按Y保存），**保存以后加上执行权限**

```bash
chmod +x ~/.vnc/xstartup
```

运行

```
vncpasswd
```

设置你的**VNC密码**，之后运行

```bash
vncserver -list
```

来查看当前为你这个用户开启的VNC服务。如果没有VNC服务，输出如下

```
TigerVNC server sessions:

X DISPLAY #	PROCESS ID
```

则需要创建你这个用户的VNC服务，用

```bash
vncserver
```

命令创建一个VNC服务，创建后用`vncserver -list`列出已有的VNC服务，输出如下

```
TigerVNC server sessions:

X DISPLAY #	PROCESS ID
:X		27159
```

其中`X`是VNC**窗口号**，你的VNC**端口号**是`5900+X`，例如当`X=11`时，你的VNC**端口号**是`5911`

最后打开TigerVNC客户端，输入地址`<服务器IP>:<你的VNC端口号>`和**VNC密码**登录图形界面。如果你进去发现是黑屏，说明你先运行了`vncserver`命令，后写的`xstartup`，或者是`xstartup`没有加执行权限。用

```bash
vncserver -kill :X
```

其中`X`是VNC窗口号，停掉VNC服务，之后重新用`vncserver`命令创建VNC服务

