---
tags:
  - Windows
---

# 修复 Windows 10 外置硬盘空闲时自动休眠问题


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Fix for the External HDD Sleep Automatically when Idle Issus on Windows 10

```cmd
powercfg -change -disk-timeout-dc 0
powercfg -change -disk-timeout-ac 0
```
