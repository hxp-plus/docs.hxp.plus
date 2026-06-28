---
tags:
  - Linux
  - 工具
---

!!! warning "文档时效性说明"
本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

# 自动裁剪 PDF 边距

原英文标题：Autocrop

```bash
ffmpeg -loop 1 -i input.png -frames:v 3 -vf "negate,cropdetect=limit=0:round=0" -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1
```

```bash
ffmpeg -i input.png -vf crop=1056:496:200:472 output.png
```

```bash
for i in *.png;do convert $i -trim ${i%%.png}-cropped.png;done
for i in *-cropped.png;do ffmpeg -i $i -vf $(ffmpeg -loop 1 -i $i -frames:v 3 -vf "negate,cropdetect=limit=0:round=0" -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1) ${i%%-cropped.png}-crop.png;done
```
