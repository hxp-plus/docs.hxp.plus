---
tags:
  - VMware
  - 虚拟化
---

!!! warning "文档时效性说明"
本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

# 为 VMware 虚拟机分配静态 IP

原英文标题：Assign static IP VMware

Edit `C:\ProgramData\VMware\vmnetdhcp.conf`

Add

```
host VMnet8 {
    hardware ethernet 00:0C:29:C6:C7:5E;
    fixed-address 192.168.9.23;
}
```

Run

```
net stop vmnetdhcp
net start vmnetdhcp
```

As admin
