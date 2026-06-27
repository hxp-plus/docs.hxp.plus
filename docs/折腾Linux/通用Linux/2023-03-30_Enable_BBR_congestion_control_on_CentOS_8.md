---
tags:
  - Linux
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Add these 2 lines to `/etc/sysctl.conf`:
```
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
```
apply changes by:
```bash
sysctl -p
```
verify:
```bash
sysctl net.ipv4.tcp_available_congestion_control | grep bbr
```
```
net.ipv4.tcp_available_congestion_control = reno cubic bbr
```
```
lsmod | grep bbr
```
```
tcp_bbr                20480  2
```