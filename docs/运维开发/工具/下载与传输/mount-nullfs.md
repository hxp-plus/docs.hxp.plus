---
tags:
  - Linux
  - 工具
---

# 在 Linux 上将 /dev/null 挂载为文件系统


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Mounting /dev/null as a filesystem on Linux

## Install nullfs

```bash
yay -S nullfs
```

## Mount

```bash
mkdir null
nullfs null
```

