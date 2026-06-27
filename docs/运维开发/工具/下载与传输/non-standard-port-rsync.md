---
tags:
  - Linux
  - 工具
---

# Use non-standard SSH port to copy files remotely


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

```bash
rsync -a root@hxp-us-server:/usr/share/nginx/html . -v -e 'ssh -p 5319'
```

 