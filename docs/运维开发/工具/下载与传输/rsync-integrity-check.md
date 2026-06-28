---
tags:
  - Linux
  - 工具
---

# 使用 rsync 验证副本的完整性


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Using rsync to verify the integrity of a duplicate

```bash
echo 3 > /proc/sys/vm/drop_caches
rsync --dry-run --checksum --itemize-changes --archive SRC DEST
```
