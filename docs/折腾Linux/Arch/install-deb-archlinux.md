---
tags:
  - Arch Linux
  - Linux
---

# Install deb package on Arch Linux


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Install debtap

```bash
yay -S debtap
```

## Convert to pkg

```bash
sudo debtap -u
sudo debtap PacketTracer_731_amd64.deb
```

## Install via pacman

```bash
sudo pacman -U packettracer-7.3.1-1-x86_64.pkg.tar.zst
```
