---
tags:
  - Linux
  - 工具
---

# Change Linux file permissions back to default


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

```bash
printf "%04o\n" "$((0777 - $(umask)))"
```

```bash
find . -type f -print0 | xargs -0 chmod 644
```
