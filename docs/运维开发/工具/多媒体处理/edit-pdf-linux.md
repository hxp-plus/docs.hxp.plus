---
tags:
  - Linux
  - 工具
---

# 在 Linux 上编辑 PDF 元数据


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Edit PDF Metadata on Linux

```bash
yay -S perl-image-exiftool
exiftool -Title="This is the Title" -Author="Happy Man" -Subject="PDF Metadata" drawing.pdf
```
