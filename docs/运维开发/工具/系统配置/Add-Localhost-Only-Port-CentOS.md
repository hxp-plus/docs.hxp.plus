---
tags:
  - Linux
  - 工具
---

# 在 CentOS 中通过 firewall-cmd 添加仅本地端口


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Add a localhost-only port in CentOS via firewall-cmd

## Zone Manipulating

To see which zones are available on your system:

```
firewall-cmd --get-zones
```

To see detailed information for all zones:

```
firewall-cmd --list-all-zones
```

To see detailed information for a specific zone:

```
firewall-cmd --zone=zone-name --list-all
```

Assign the interface to a different zone:

```
firewall-cmd --zone=zone-name --change-interface=<interface-name>
```

## Allow a port only on localhost

Assign loopback interface `lo` to `trusted` zone

```
firewall-cmd --permanent --zone=trusted --add-interface=lo
```

Add a port to `trusted` zone

```
firewall-cmd --permanent --zone=trusted --add-port=<port>/tcp
firewall-cmd --permanent --zone=trusted --add-port=<port>/udp
```

Reload

```
firewall-cmd --reload
```
