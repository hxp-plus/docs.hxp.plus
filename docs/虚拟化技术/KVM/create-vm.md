---
tags:
  - KVM
  - QEMU
  - 虚拟化
---

# 使用 virsh 命令创建 KVM 虚拟机


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Create a KVM virtual machine using virsh command

## Set virsh default uri and virtual machine name

```
export LIBVIRT_DEFAULT_URI="qemu:///system"
export VMNAME="rhel77"
```

## Create disk image

```
mkdir /var/lib/libvirt/images/$VMNAME
qemu-img create -o preallocation=full -f qcow2 /var/lib/libvirt/images/$VMNAME/$VMNAME.qcow2 20G
```

## List os variants

```
virt-install --os-variant list
```

## Insall an VM

```
virt-install --name $VMNAME --vcpus 4 --memory 4096 --boot uefi --disk path=/var/lib/libvirt/images/$VMNAME/$VMNAME.qcow2 --cdrom /var/lib/libvirt/images/isos/rhel-server-7.7-x86_64-dvd.iso --os-variant rhel7.7 --network bridge=br0 --graphics vnc,listen=0.0.0.0 --virt-type kvm
```

## Get VM vnc port

```
virsh vncdisplay $VMNAME
```