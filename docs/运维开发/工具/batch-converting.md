---
tags:
  - Linux
  - 工具
---

# 实用的批量转换 bash 脚本


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Useful bash Scripts to Batch Convert

remove all the spaces from filename:

```bash
for f in *; do mv "$f" "$(echo $f | tr ' ' '_')"; done
```

convert all mkv to mp4:

```bash
mkdir -p mp4convert;
target_dir=$1
cd $target_dir;
for file in `ls *.mkv`;
do
    mv "$file" "../mp4convert/$file";
done
cd ..
```

```bash
target_dir=$1;
cd mp4convert;
for file in `ls *.mkv`;
do
    filename=${file%.*};
    ffmpeg -i $file "../$target_dir/$filename.mp4";
done
cd ..

```
