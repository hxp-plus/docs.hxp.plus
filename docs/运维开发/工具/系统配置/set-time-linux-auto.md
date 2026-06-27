---
tags:
  - Linux
  - 工具
---

# Set Time Automatically on Linux


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

```bash
yum install ntp
ntpdate pool.ntp.org
# OR 
sudo chronyd -q 'server pool.ntp.org iburst'
```