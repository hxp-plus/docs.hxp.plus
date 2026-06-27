---
tags:
  - Fedora
  - Linux
---

# Fedora System Upgrade


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

install dnf plugin

```bash
sudo dnf install dnf-plugin-system-upgrade
```

update to Fedora 32

```bash
sudo dnf system-upgrade download --refresh --releasever=32
```