---
tags:
  - KVM
  - QEMU
  - 虚拟化
---

# KVM installation on Gentoo


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 安装 QEMU 和 libvirt

在 `/etc/portage/package.use/qemu` 中添加以下 USE flags：

```
app-emulation/qemu qemu_softmmu_targets_arm qemu_softmmu_targets_x86_64 qemu_softmmu_targets_sparc
app-emulation/qemu qemu_user_targets_x86_64 spice usbredir
app-emulation/qemu QEMU_SOFTMMU_TARGETS: arm x86_64 sparc QEMU_USER_TARGETS: x86_64
```

在 `/etc/portage/make.conf` 中添加以下环境变量：

```
QEMU_SOFTMMU_TARGETS="arm x86_64 sparc"
QEMU_USER_TARGETS="x86_64"
```

安装：

```bash
sudo emerge app-emulation/qemu app-emulation/libvirt app-emulation/virt-manager app-emulation/virt-viewer
```

安装完成后，运行：

```bash
gpasswd -a qemu kvm
gpasswd -a hxp kvm
gpasswd -a hxp libvirt
sudo chmod 666 /dev/kvm
```

在 `/etc/libvirt/libvirtd.conf` 中添加以下行：

```bash
auth_unix_ro = "none"
auth_unix_rw = "none"
unix_sock_group = "libvirt"
unix_sock_ro_perms = "0777"
unix_sock_rw_perms = "0770"
```

重启并启用 `libvirt`：

```bash
sudo rc-service libvirtd restart
sudo rc-update add libvirtd default
```

## 下载 Linux LiveCD ISO

```bash
wget https://mirror.sjtu.edu.cn/almalinux/8.4/isos/x86_64/AlmaLinux-8.4-x86_64-dvd.iso
```

注意：AlmaLinux 是 CentOS 的替代方案。ISO 放在 `~/AlmaLinux` 目录下。

## 创建 qcow2 镜像

```bash
qemu-img create -o preallocation=full -f qcow2 AlmaLinux-8.4.qcow2 128G
```

选项 `preallocation=full` 会花费更多时间创建磁盘镜像。其优势是虚拟机将获得更好的磁盘性能。如果此时不应用此选项，将立即创建一个仅几 KiB 大小的镜像，虚拟机在未来需要时才会分配更多空间，这会导致宿主机磁盘消耗更少，但虚拟机磁盘性能也更差。

注意：`AlmaLinux-8.4.qcow2` 也放在 `~/AlmaLinux` 目录下。

## 使用 LiveCD 安装 AlmaLinux

```bash
qemu-system-x86_64 -cdrom AlmaLinux-8.4-x86_64-dvd.iso \
  -boot order=d -m 8096 -drive file=AlmaLinux-8.4.qcow2,format=qcow2 \
  -vnc :20 -smp $(nproc) -usb -device usb-tablet \
  -enable-kvm
```

注意：`-vnc :20` 表示让 qemu 在端口 `5920` 上监听 VNC 连接，并通过它转发虚拟机的显示。

然后使用任意 VNC 客户端，连接到 `vnc://<宿主机_ip地址>:5920`，完成系统安装。

## 将已安装的磁盘添加到 libvirt

查看所有可用变体：

```bash
osinfo-query os
```

由于 `almalinux8` 在列表中，我们使用选项 `--os-variant almalinux8`。

```bash
sudo virt-install \
  --name AlmaLinux-8.4 \
  --memory 8192 \
  --vcpus 4 \
  --disk AlmaLinux-8.4.qcow2 \
  --import \
  --os-variant almalinux8
```

注意：如果卡在 `Waiting for the installation to complete.`，你需要 X display 来启动 `virt-viewer`。

## 为虚拟机添加 VNC

```bash
sudo virt-xml AlmaLinux-8.4 --add-device --graphics vnc,port=5950,listen=0.0.0.0
```

VNC 服务器将在以下操作后启动于 `vnc://<你的宿主机_ip>:5950`：

```bash
sudo virsh shutdown AlmaLinux-8.4
sudo virsh start AlmaLinux-8.4
```

## 将虚拟机端口转发到宿主机

关闭虚拟机：

```bash
sudo virsh shutdown AlmaLinux-8.4
```

等待虚拟机关闭。使用：

```bash
sudo virsh list --all
```

查看虚拟机状态。

然后编辑 xml：

```bash
sudo EDITOR=vim virsh edit AlmaLinux-8.4
```

将第一行从：

```xml
<domain type='kvm'>
```

改为：

```xml
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
```

并在 `</devices>` 之后、`</domain>` 之前（作为 `<domain>` 元素的最后一个子元素）添加以下行：

```xml
<qemu:commandline>
   <qemu:arg value='-netdev'/>
   <qemu:arg value='user,id=mynet.0,net=10.0.10.0/24,hostfwd=tcp::22222-:22,hostfwd=tcp::8000-:8000'/>
   <qemu:arg value='-device'/>
   <qemu:arg value='e1000,netdev=mynet.0'/>
 </qemu:commandline>
```

移除：

```xml
<interface type='network'>
  <mac address='52:54:00:02:1d:78'/>
  <source network='default'/>
  <model type='virtio'/>
  <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
</interface>
```

然后重启虚拟机：

```bash
sudo virsh shutdown AlmaLinux-8.4
sudo virsh start AlmaLinux-8.4
```

## 系统启动时自动启动虚拟机

```bash
sudo virsh autostart AlmaLinux/AlmaLinux-8.4
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

# KVM installation on Gentoo


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Install QEMU and libvirt

Add these USE flags in `/etc/portage/package.use/qemu`:

```
app-emulation/qemu qemu_softmmu_targets_arm qemu_softmmu_targets_x86_64 qemu_softmmu_targets_sparc
app-emulation/qemu qemu_user_targets_x86_64 spice usbredir
app-emulation/qemu QEMU_SOFTMMU_TARGETS: arm x86_64 sparc QEMU_USER_TARGETS: x86_64
```

Add these environment variables in `/etc/portage/make.conf`

```
QEMU_SOFTMMU_TARGETS="arm x86_64 sparc"
QEMU_USER_TARGETS="x86_64"
```

Install:

```bash
sudo emerge app-emulation/qemu app-emulation/libvirt app-emulation/virt-manager app-emulation/virt-viewer
```

After installation, run

```bash
gpasswd -a qemu kvm
gpasswd -a hxp kvm
gpasswd -a hxp libvirt
sudo chmod 666 /dev/kvm
```

Add these lines to `/etc/libvirt/libvirtd.conf`

```bash
auth_unix_ro = "none"
auth_unix_rw = "none"
unix_sock_group = "libvirt"
unix_sock_ro_perms = "0777"
unix_sock_rw_perms = "0770"
```

restart and enable `libvirt`

```bash
sudo rc-service libvirtd restart
sudo rc-update add libvirtd default
```

## Download a Linux LiveCD ISO

```bash
wget https://mirror.sjtu.edu.cn/almalinux/8.4/isos/x86_64/AlmaLinux-8.4-x86_64-dvd.iso
```

Note: AlmaLinux is an alternative of CentOS. The ISO is placed under directory `~/AlmaLinux`.

## Create a qcow2 image

```bash
qemu-img create -o preallocation=full -f qcow2 AlmaLinux-8.4.qcow2 128G
```

Option `preallocation=full` will take more time to create disk image. The advantage is that virtual machine will gain better disk performance. If this option is not applied now, an image in size of several kibibytes will be created immediately, more space will be allocated whenever the virtual machine needs them in the future, resulting in less host machine disk consumption and less virtual machine disk performance.

Note: `AlmaLinux-8.4.qcow2` is also located in `~/AlmaLinux`.

## Install AlmaLinux with LiveCD

```bash
qemu-system-x86_64 -cdrom AlmaLinux-8.4-x86_64-dvd.iso \
  -boot order=d -m 8096 -drive file=AlmaLinux-8.4.qcow2,format=qcow2 \
  -vnc :20 -smp $(nproc) -usb -device usb-tablet \
  -enable-kvm
```

Note: `-vnc :20` means that letting qemu listening on port `5920` for VNC connection, and tunnel the display of virtual machine through it. 

Then use any of the VNC clients, connect to `vnc://<ip_address_of_the_host>:5920`, and finish system installation.

## Add the installed disk to libvirt

To see all available variants:

```bash
osinfo-query os
```

Since `almalinux8` is in the list, we use option `--os-variant almalinux8`.

```bash
sudo virt-install \
  --name AlmaLinux-8.4 \
  --memory 8192 \
  --vcpus 4 \
  --disk AlmaLinux-8.4.qcow2 \
  --import \
  --os-variant almalinux8
```

Note: if you stuck at `Waiting for the installation to complete.`, you need X display to start `virt-viewer`.

## Add VNC to virtual machine

```bash
sudo virt-xml AlmaLinux-8.4 --add-device --graphics vnc,port=5950,listen=0.0.0.0
```

VNC server will start at `vnc://<your_host_ip>:5950` after

```bash
sudo virsh shutdown AlmaLinux-8.4
sudo virsh start AlmaLinux-8.4
```

## Forward ports in virtual machine to host

Shutdown virtual machine

```bash
sudo virsh shutdown AlmaLinux-8.4
```

Wait until virtual machine shuts down. Use

```bash
sudo virsh list --all
```

to see virtual machine status.

Then edit xml

```bash
sudo EDITOR=vim virsh edit AlmaLinux-8.4
```

Change the first line from

```xml
<domain type='kvm'>
```

to

```xml
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
```

and add these lines after `</devices>`, before `</domain>` as the last child of `<domain>` element

```xml
<qemu:commandline>
   <qemu:arg value='-netdev'/>
   <qemu:arg value='user,id=mynet.0,net=10.0.10.0/24,hostfwd=tcp::22222-:22,hostfwd=tcp::8000-:8000'/>
   <qemu:arg value='-device'/>
   <qemu:arg value='e1000,netdev=mynet.0'/>
 </qemu:commandline>
```

Remove

```xml
<interface type='network'>
  <mac address='52:54:00:02:1d:78'/>
  <source network='default'/>
  <model type='virtio'/>
  <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
</interface>
```

then restart virtual machine

```bash
sudo virsh shutdown AlmaLinux-8.4
sudo virsh start AlmaLinux-8.4
```

## Auto start virtual machine on system boot

```bash
sudo virsh autostart AlmaLinux/AlmaLinux-8.4
```
```
