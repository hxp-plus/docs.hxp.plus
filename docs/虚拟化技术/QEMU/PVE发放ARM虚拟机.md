
# PVE发放ARM虚拟机

## PVE 宿主机安装依赖

PVE宿主机需要安装ARM结构的firmware：

```bash
apt install pve-edk2-firmware-aarch64
```

## 新建虚拟机

新建虚拟机，并做如下配置：

- 不选择 CDROM
- Machine 选择 i440fx
- BIOS 选择 UEFI ，不添加 EFI 磁盘
- SCSI 控制器选择 VirtIO SCSI ，磁盘选 VirtIO Block 类型

## 修改虚拟机配置

创建出的虚拟机ID为108，进入 `/etc/pve/qemu-server/108.conf` ，修改这个文件，添加如下配置：

```text
arch: aarch64
```

删除如下配置：

```text
cpu: x86-64-v2-AES
vmgenid: 8e8ffebe-a35d-4882-9039-a8f1d66b6b8d
```

之后再页面上删除 CD 驱动器，再新建为 SCSI 的 CD 驱动器。修改完成此配置示例如下：

```text
arch: aarch64
bios: ovmf
boot: order=net0;scsi0
cores: 8
memory: 16384
meta: creation-qemu=9.0.2,ctime=1740024564
name: centos-9-arm-1
net0: virtio=BC:24:11:E4:64:02,bridge=vmbr0,firewall=1
numa: 0
ostype: l26
scsi0: local:iso/CentOS-Stream-9-latest-aarch64-dvd1.iso,media=cdrom,size=10398208K
scsihw: virtio-scsi-pci
smbios1: uuid=3b8d0e01-c5e7-49d3-9f3e-d0fb02e0e048
sockets: 1
template: 1
virtio0: local-zfs:base-106-disk-0,iothread=1,size=32G
```

挂载操作系统 ISO 安装镜像，在 Options 里修改 CD 为第一启动项，安装操作系统。
