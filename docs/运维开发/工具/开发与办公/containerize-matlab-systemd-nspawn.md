---
tags:
  - Linux
  - 工具
---

# Containerize MATLAB with systemd-nspawn


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 搭建 Debian 9 环境

切换目录

```bash
sudo su
cd /var/lib/machines
```

安装 `debootstrap` 和 `debian-archive-keyring`

```bash
sudo pacman -S debootstrap debian-archive-keyring
```

使用 `debootstrap` 搭建 `debian` 环境

```bash
debootstrap --include=systemd-container --components=main,universe stretch matlab-debian9 https://mirrors.163.com/debian
```

设置 Debian 密码

```bash
systemd-nspawn -D ./matlab-debian9/
passwd
```

## 安装 Firefox 并运行

编辑 `/etc/apt/sources.list`

```bash
systemd-nspawn -D ./matlab-debian9
deb https://mirrors.163.com/debian stretch main contrib non-free
```

安装 `Firefox`

```bash
apt install firefox-esr
```

退出容器

```bash
exit
```

启用 `xhost`

```bash
xhost +local:
```

复制所有字体：

```bash
cp -a /usr/share/fonts/* /var/lib/machines/matlab-debian9/usr/share/fonts/
```

然后进入容器并运行

```bash
fc-cache -f -v
```

然后在容器内运行 `Firefox`

```bash
systemd-nspawn --setenv=DISPLAY=:0 \
               --setenv=XAUTHORITY=~/.Xauthority \
               --bind-ro=$HOME/.Xauthority:/root/.Xauthority \
               --bind=/tmp/.X11-unix \
               -D /var/lib/machines/matlab-debian9 firefox
```

## 安装 MATLAB

挂载 MATLAB ISO

```bash
sudo mkdir /mnt/matlab
sudo mount -t iso9660 'Matlab98R2020a_Linux 64.iso' /mnt/matlab
```

启动进入容器

```bash
sudo systemd-nspawn -b -D /var/lib/machines/matlab-debian9 --bind=/mnt/matlab
```

如果在 MATLAB 安装过程中遇到 "archive is not a ZIP archive" 错误，移除 `-b` 选项

安装必要的库

```bash
apt-get install xorg build-essential libgtk2.0-0 libnss3 libasound2
```

设置打开文件数的下限

```bash
ulimit -n 100000
```

然后切换到 `/mnt/matlab` 目录并安装 MATLAB

然后安装并运行 MATLAB

```bash
/usr/local/Polyspace/R2020a/bin/matlab
```

---

## 原文（English）

# Containerize MATLAB with systemd-nspawn


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Set up Debian 9 environment

Change directory

```bash
sudo su
cd /var/lib/machines
```

Install `debootstrap` and `debian-archive-keyring`

```bash
sudo pacman -S debootstrap debian-archive-keyring
```

Use `debootstrap` to set up a `debian` environment

```bash
debootstrap --include=systemd-container --components=main,universe stretch matlab-debian9 https://mirrors.163.com/debian
```

Set password for Debian

```bash
systemd-nspawn -D ./matlab-debian9/
passwd
```

## Install Firefox and run

Edit `/etc/apt/sources.list`

```bash
systemd-nspawn -D ./matlab-debian9
deb https://mirrors.163.com/debian stretch main contrib non-free
```

Install `Firefox`

```bash
apt install firefox-esr
```

Exit the container

```bash
exit
```

And enable `xhost`

```bash
xhost +local:
```

Copy all your fonts:

```bash
cp -a /usr/share/fonts/* /var/lib/machines/matlab-debian9/usr/share/fonts/
```

Then shell into the container and run

```bash
fc-cache -f -v
```

Then run `Firefox` inside container

```bash
systemd-nspawn --setenv=DISPLAY=:0 \
               --setenv=XAUTHORITY=~/.Xauthority \
               --bind-ro=$HOME/.Xauthority:/root/.Xauthority \
               --bind=/tmp/.X11-unix \
               -D /var/lib/machines/matlab-debian9 firefox
```

## Install MATLAB

mount the MATLAB iso

```bash
sudo mkdir /mnt/matlab
sudo mount -t iso9660 'Matlab98R2020a_Linux 64.iso' /mnt/matlab
```

boot into the container

```bash
sudo systemd-nspawn -b -D /var/lib/machines/matlab-debian9 --bind=/mnt/matlab
```

if you encounter an error message "archive is not a ZIP archive" during MATLAB installation, remove the `-b` option

install requisite libraries

```bash
apt-get install xorg build-essential libgtk2.0-0 libnss3 libasound2
```

set a lower limit of number of open files by

```bash
ulimit -n 100000
```

and then change directory into `/mnt/matlab` and install MATLAB

then install and run MATLAB

```bash
/usr/local/Polyspace/R2020a/bin/matlab
```
