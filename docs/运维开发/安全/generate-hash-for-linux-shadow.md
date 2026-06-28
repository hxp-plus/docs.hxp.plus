---
tags:
  - 安全
  - Linux
---

# 为 Linux shadow 文件生成哈希


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Generate Hash for Linux shadow file

use openssl

```bash
openssl passwd -6 -salt some_random_string hxp
```

 or use random salt

```bash
openssl passwd -6 hxp
```

