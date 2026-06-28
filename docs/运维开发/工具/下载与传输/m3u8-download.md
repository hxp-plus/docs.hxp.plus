---
tags:
  - Linux
  - 工具
---

# 使用 FFmpeg 下载 m3u8


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Download m3u8 with FFmepg

```bash
ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto -i "http://s6.vidshare.tv/hls/pdommq4tlsm4f4kmledsh5d5fcn27i35msjxqw62lfflut5bgaqhb5kirb5q/index-v1-a1.m3u8" -c copy video.mp4
```
