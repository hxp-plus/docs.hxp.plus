---
tags:
  - KVM
  - QEMU
  - 虚拟化
---

# Use libvirt to Run KVM


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

### 安装 qcow 镜像

```bash
virt-install \
  --name ibpe \
  --memory 2048 \
  --vcpus 2 \
  --disk /run/media/hxp/hxp-ssd/qemu-vm/ubuntu-disk.cow \
  --import \
  --os-variant ubuntu20.04
```

### 删除 KVM

停止 VM

```bash
virsh shutdown ibpe
```

然后查找并删除 `source file`，

```bash
virsh dumpxml ibpe | grep 'source file'
```

删除磁盘文件，并销毁 vm

```bash
virsh destroy ibpe
```

取消定义 VM

```bash
virsh undefine ibpe
```

### 为 VM 添加 VNC

停止 VM 并编辑 xml

```bash
virt-xml ibpe --add-device --graphics vnc,port=-1,autoport=yes,listen=0.0.0.0
```

然后启动 VM。

### 将宿主机端口 22222 转发到客户机端口 22

编辑 xml

```bash
EDITOR=nano virsh edit ibpe
```

将第一行改为

```
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
```

移除类似如下的 user interface

```
<interface type='user'>
  <mac address='52:54:00:52:35:ff'/>
  <model type='rtl8139'/>
  <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
</interface>
```

并将其作为 `<domain>` 的最后一个子元素添加

```
<qemu:commandline>
  <qemu:arg value='-netdev'/>
  <qemu:arg value='user,id=mynet.0,net=10.0.10.0/24,hostfwd=tcp::22222-:22'/>
  <qemu:arg value='-device'/>
  <qemu:arg value='rtl8139,netdev=mynet.0'/>
</qemu:commandline>
```

### 宿主机启动时启动 KVM

```bash
virsh autostart ibpe
```

### 更改 KVM 可访问的 vCPU 数量和 RAM

```bash
virsh destroy ibpe
virsh setvcpus --count 4 ibpe --config
virsh setmaxmem ibpe 6G --config
virsh setmem ibpe 6G --config
virsh start ibpe
```

### 导出和加载 VM 配置

导出

```bash
virsh dumpxml vmname > vmname.xml 
```

加载

```bash
virsh define /tmp/myvm.xml
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

# Use libvirt to Run KVM


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

### Install a qcow image

```bash
virt-install \
  --name ibpe \
  --memory 2048 \
  --vcpus 2 \
  --disk /run/media/hxp/hxp-ssd/qemu-vm/ubuntu-disk.cow \
  --import \
  --os-variant ubuntu20.04
```

### Delete KVM

Stop VM

```bash
virsh shutdown ibpe
```

And then find and delete `suorce file`,

```bash
virsh dumpxml ibpe | grep 'source file'
```

Delete the disk file, and destroy vm

```bash
virsh destroy ibpe
```

Undefine VM

```bash
virsh undefine ibpe
```

### Add VNC to your VM

Stop VM and edit xml

```bash
virt-xml ibpe --add-device --graphics vnc,port=-1,autoport=yes,listen=0.0.0.0
```

And start VM.

### Forward Host Port 22222 to Guest Port 22

Edit xml

```bash
EDITOR=nano virsh edit ibpe
```

Change the first line to

```
<domain type='kvm' xmlns:QEMU='http://libvirt.org/schemas/domain/qemu/1.0'>
```

Remove user interface like this

```
<interface type='user'>
  <mac address='52:54:00:52:35:ff'/>
  <model type='rtl8139'/>
  <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
</interface>
```

And add this as the last child of `<domain>`

```
<QEMU:commandline>
  <QEMU:arg value='-netdev'/>
  <QEMU:arg value='user,id=mynet.0,net=10.0.10.0/24,hostfwd=TCP::22222-:22'/>
  <QEMU:arg value='-device'/>
  <QEMU:arg value='rtl8139,netdev=mynet.0'/>
</QEMU:commandline>
```

### Start KVM on Host Boot

```bash
virsh autostart ibpe
```

### Change Number of Accessible vCPU and RAM for a KVM

```bash
virsh destroy ibpe
virsh setvcpus --count 4 ibpe --config
virsh setmaxmem ibpe 6G --config
virsh setmem ibpe 6G --config
virsh start ibpe
```

### Export and Load VM Config

To export

```bash
virsh dumpxml vmname > vmname.xml 
```

To load

```bash
virsh define /tmp/myvm.xml
```
```
