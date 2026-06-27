---
tags:
  - 网络
  - Linux
---

# Configure NetworkManager to Change MAC Address everytime iface restarts


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Edit `/etc/NetworkManager/conf.d/00-macrandomize.conf`, add

```
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
ethernet.cloned-mac-address=stable
connection.stable-id=${CONNECTION}/${BOOT}
```