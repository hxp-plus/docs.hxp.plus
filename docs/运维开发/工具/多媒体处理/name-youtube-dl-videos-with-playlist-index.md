---
tags:
  - Linux
  - 工具
---

!!! warning "文档时效性说明"
本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

# 使用 youtube-dl 按播放列表索引命名视频

原英文标题：Name youtube-dl videos with playlist index

```bash
alias ytbdl='/usr/local/bin/youtube-dl --recode-video mp4 -o "%(playlist_index)s.%(title)s.%(ext)s" --no-mtime'
```
