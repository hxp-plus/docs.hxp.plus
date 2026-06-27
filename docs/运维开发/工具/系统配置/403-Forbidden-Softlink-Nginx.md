---
tags:
  - Linux
  - 工具
---

# 403 Forbidden When Accessing Files in Webroot through Softlink #


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Created a soft link in `/usr/share/nginx/html/`z via

```
ln -s /root/qqbot/data.txt .
```

Expecting to access `data.txt` from `http://<ip address>/data.txt`

Ruturned 403 Forbidden.

Solution was to change the mod of `/root/qqbot/` to `755`

```
chmod -R 755 /root/qqbot/
```
