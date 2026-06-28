---
tags:
  - Linux
  - 工具
---

# 获取视频分辨率


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Get Video Resolution

```bash
alias videoresolution='ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0'
```

