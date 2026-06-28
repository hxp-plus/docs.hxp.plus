---
tags:
  - Arch Linux
  - Linux
---

# 安装 CUPS 打印服务


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Install CUPS Printing Service

install `cups` package

```bash
sudo pacman -S cups-pdf
```

enable service

```bash
sudo systemctl enable cups-browsed.service --now
```

visit <http://localhost:631/> in browser, click "Administration" and enter your Linux username and password. For example, I entered username "hxp" and my password.

Then add virtual pirnters, printed file will be put under `/var/spool/`
