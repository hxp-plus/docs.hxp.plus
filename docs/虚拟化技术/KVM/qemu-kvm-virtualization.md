---
tags:
  - KVM
  - QEMU
  - 虚拟化
---

# 使用 KVM 和 QEMU 虚拟化 Ubuntu 或其他系统


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Vitrualize Ubuntu or Other Systems with KVM and QEMU

## 创建磁盘镜像并安装系统

创建磁盘镜像

```bash
qemu-img create -f qcow2 ubuntu-disk.cow2 20G
```

调整镜像大小

```bash
qemu-img resize disk_image +10G
```

安装系统

```bash
qemu-system-x86_64 -cdrom ubuntu-20.04.1-desktop-amd64.iso \
  -boot order=d -m 8096 -drive file=ubuntu-disk.cow,format=qcow2 \
  -vnc :0 -smp $(nproc) -usb -device usb-tablet \
  -enable-kvm -vga qxl
```

运行系统

```bash
qemu-system-x86_64 -smp $(nproc) -drive file=ubuntu-disk.cow,format=qcow2 -m 8096 --enable-kvm -vnc :0 -usb -device usb-tablet -vga qxl -monitor tcp:127.0.0.1:6666,server,nowait
```

检查系统是否正在运行

```bash
echo "info status " | timeout 1 netcat 127.0.0.1 6666 
```

## 从宿主机复制文件到客户机

使用 SMB 在客户机和宿主机之间共享文件，在宿主机上运行：

```bash
qemu-system-x86_64 -net nic -net user,smb=/dev/shm/ -smp $(nproc) -drive file=ubuntu-disk.cow,format=qcow2 -m 8096 --enable-kvm -vnc :0 -usb -device usb-tablet -vga qxl -monitor tcp:127.0.0.1:6666,server,nowait
```

在客户机上运行：

```bash
apt update
apt install cifs-utils
mount -t cifs //10.0.2.4/qemu/ /mnt/
```

## 访问客户机中的 SSH

```bash
qemu-system-x86_64 \
  -smp $(nproc) \
  -drive file=ubuntu-disk.cow,format=qcow2 \
  -m 8096 \
  --enable-kvm -usb -device usb-tablet -vga qxl \
  -device e1000,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::5555-:22 \
  -vnc :10
```

---

## 原文（English）

```
---
tags:
  - KVM
  - QEMU
  - 虚拟化
---

# Vitrualize Ubuntu or Other Systems with KVM and QEMU


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Create Disk Image and Install System

Create Disk Image

```bash
QEMU-img create -f qcow2 ubuntu-disk.cow2 20G
```

Rezize Image with

```bash
QEMU-img resize disk_image +10G
```

Install System

```bash
QEMU-system-x86_64 -cdrom ubuntu-20.04.1-desktop-amd64.iso \
  -boot order=d -m 8096 -drive file=ubuntu-disk.cow,format=qcow2 \
  -vnc :0 -smp $(nproc) -USB -device USB-tablet \
  -enable-kvm -vga qxl
```

Run System

```bash
QEMU-system-x86_64 -smp $(nproc) -drive file=ubuntu-disk.cow,format=qcow2 -m 8096 --enable-kvm -vnc :0 -USB -device USB-tablet -vga qxl -monitor TCP:127.0.0.1:6666,server,nowait
```

Check if system is running

```bash
echo "info status " | timeout 1 netcat 127.0.0.1 6666 
```

## Copy Files from Host to Guest

Use SMB to share files between guest and host, on host machine, run

```bash
QEMU-system-x86_64 -net nic -net user,smb=/dev/shm/ -smp $(nproc) -drive file=ubuntu-disk.cow,format=qcow2 -m 8096 --enable-kvm -vnc :0 -USB -device USB-tablet -vga qxl -monitor TCP:127.0.0.1:6666,server,nowait
```

On guest machine, run

```bash
apt update
apt install cifs-utils
mount -t cifs //10.0.2.4/qemu/ /mnt/
```

## Access SSH in Guest

```bash
QEMU-system-x86_64 \
  -smp $(nproc) \
  -drive file=ubuntu-disk.cow,format=qcow2 \
  -m 8096 \
  --enable-kvm -USB -device USB-tablet -vga qxl \
  -device e1000,netdev=net0 \
  -netdev user,id=net0,hostfwd=TCP::5555-:22 \
  -vnc :10
```
```
