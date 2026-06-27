---
tags:
  - Linux
  - 工具
---

# Install Xfce Desktop with VNC on CentOS


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 使用 dnf 安装软件包

确保已安装 epel-release，然后运行

```bash
sudo dnf groupinstall "xfce"
sudo dnf install tigervnc-server
```

## 配置 VNC 服务器

```bash
vncserver
```

## 编辑 VNC 启动脚本

编辑 `~/.vnc/xstartup`，注释掉

```bash
exec /etc/X11/xinit/xinitrc
```

添加

```bash
exec startxfce4
```

终止并重启 vncserver

```bash
vncserver -kill :1
vncserver
```

## 添加防火墙规则

```bash
sudo firewall-cmd --add-service=vnc-server --permanent
sudo firewall-cmd --reload
```

通过 vncviewer 连接 `yourip:5901` 并测试

### 添加 systemctl 启动脚本

```bash
sudo cp /usr/lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:1.service
sudo nano /etc/systemd/system/vncserver@\:1.service
```

并将 "hxp" 改为你的用户名

```bash
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=simple
User=root
Group=root

# Clean any existing files in /tmp/.X11-unix environment
ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill %i > /dev/null 2>&1 || :'
ExecStart=/usr/bin/vncserver_wrapper hxp %i
ExecStop=/bin/sh -c '/usr/bin/vncserver -kill %i > /dev/null 2>&1 || :'

[Install]
WantedBy=multi-user.target
```

重新加载 systemctl 并启动服务

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vncserver@:1.service
```

---

## 原文（English）

## dnf install packages

make sure you have installed epel-release and run

```bash
sudo dnf groupinstall "xfce"
sudo dnf install tigervnc-server
```

## Configure VNC server

```bash
vncserver
```

## Edit VNC startup script

edit `~/.vnc/xstartup`, comment

```bash
exec /etc/X11/xinit/xinitrc
```

add

```bash
exec startxfce4
```

kill and restart vncserver

```bash
vncserver -kill :1
vncserver
```

## Add firewall rules

```bash
sudo firewall-cmd --add-service=vnc-server --permanent
sudo firewall-cmd --reload
```

connect `yourip:5901`via vncviewer and test

### Add systemctl startup script

```bash
sudo cp /usr/lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:1.service
sudo nano /etc/systemd/system/vncserver@\:1.service
```

and change "hxp" to your username

```bash
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=simple
User=root
Group=root

# Clean any existing files in /tmp/.X11-unix environment
ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill %i > /dev/null 2>&1 || :'
ExecStart=/usr/bin/vncserver_wrapper hxp %i
ExecStop=/bin/sh -c '/usr/bin/vncserver -kill %i > /dev/null 2>&1 || :'

[Install]
WantedBy=multi-user.target
```

reload systemctl and start service

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vncserver@:1.service
```
