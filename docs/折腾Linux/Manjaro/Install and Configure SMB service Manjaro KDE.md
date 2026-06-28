---
tags:
  - Manjaro
  - Linux
---

# 在 Manjaro KDE 上安装和配置 SMB 服务


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Install and Configure SMB service on Manjaro KDE

## 安装所需软件包

```bash
yay -Sy samba
yay -Sy wsdd
```

注意：`wsdd` 是本地网络发现所必需的。虽然 Samba 服务器可以在没有 `wsdd` 的情况下运行，但当服务器的 `wsdd` 停止时，Windows 将无法发现共享的网络驱动器。

## 配置 Samba

```bash
sudo touch /etc/samba/smb.conf
sudo vim /etc/samba/smb.conf
```

一个示例 `/etc/samba/smb.conf`，共享用户主目录和 `/data` 目录（仅当用户在 staff 组中时才可写入）：

```
[global]
   workgroup = WORKGROUP
   server string = Manjaro
   server role = standalone server
   log file = /usr/local/samba/var/log.%m
   max log size = 50
   server min protocol = NT1
   ntlm auth = yes

[homes]
   comment = Home Directories
   browseable = no
   writable = yes

[data]
   comment = Data Directories
   path = /data
   public = yes
   writable = no
   printable = no
   write list = @staff
```

## 创建 /data 目录并设置 SMB 密码

```bash
sudo smbpasswd -a <your_username>
sudo mkdir -p /data
sudo groupadd staff # Create staff group
sudo usermod -aG staff <your_username> # Add user to staff group
sudo chown root:staff /data # Change group ownership to staff group
sudo chmod 770 /data # Change group permission to allow read and write
```

## 启动服务

```bash
sudo systemctl start smb
sudo systemctl start wsdd
sudo systemctl enable smb
sudo systemctl enable wsdd
sudo systemctl start nmb 
sudo systemctl enable nmb
```

## 参考

[Samba - ArchWiki](https://wiki.archlinux.org/title/samba)

[A sample samba config](https://git.samba.org/samba.git/?p=samba.git;a=blob_plain;f=examples/smb.conf.default;hb=HEAD)

---

## 原文（English）

```
---
tags:
  - Manjaro
  - Linux
---

# Install and Configure SMB service on Manjaro KDE


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Install required packages

```bash
yay -Sy samba
yay -Sy wsdd
```

Note: `wsdd `is required for local network discovery. Although samba server can run without `wsdd`, windows would not discover the network drives shared when the server's `wsdd` is down.

## Configure samba

```bash
sudo touch /etc/samba/smb.conf
sudo vim /etc/samba/smb.conf
```

A sample `/etc/samba/smb.conf` sharing user's home directory and `/data` directory (writable only if user is in staff group).

```
[global]
   workgroup = WORKGROUP
   server string = Manjaro
   server role = standalone server
   log file = /usr/local/samba/var/log.%m
   max log size = 50
   server min protocol = NT1
   ntlm auth = yes

[homes]
   comment = Home Directories
   browseable = no
   writable = yes

[data]
   comment = Data Directories
   path = /data
   public = yes
   writable = no
   printable = no
   write list = @staff
```

## Create /data directory and set SMB password

```bash
sudo smbpasswd -a <your_username>
sudo mkdir -p /data
sudo groupadd staff # Create staff group
sudo usermod -aG staff <your_username> # Add user to staff group
sudo chown root:staff /data # Change group ownership to staff group
sudo chmod 770 /data # Change group permission to allow read and write
```

## Start services

```bash
sudo systemctl start smb
sudo systemctl start wsdd
sudo systemctl enable smb
sudo systemctl enable wsdd
sudo systemctl start nmb 
sudo systemctl enable nmb
```

## References

[Samba - ArchWiki](https://wiki.archlinux.org/title/samba)

[A sample samba config](https://git.samba.org/samba.git/?p=samba.git;a=blob_plain;f=examples/smb.conf.default;hb=HEAD)
```
