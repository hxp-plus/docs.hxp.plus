---
tags:
  - Linux
  - 工具
---

# Using wget to clone a whole site


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

一行命令：

```bash
wget --recursive --no-clobber --span-hosts --page-requisites --html-extension --convert-links --restrict-file-names=windows --domains ys168.com --no-parent http://qzbltushu.ys168.com/
```

参数说明：

```bash
wget \
     --recursive \ # Download the whole site.
     --page-requisites \ # Get all assets/elements (CSS/JS/images).
     --adjust-extension \ # Save files with .html on the end.
     --span-hosts \ # Include necessary assets from offsite as well.
     --convert-links \ # Update links to still work in the static version.
     --restrict-file-names=windows \ # Modify filenames to work in Windows as well.
     --domains yoursite.com \ # Do not follow links outside this domain.
     --no-parent \ # Don't follow links outside the directory you pass in.
         yoursite.com/whatever/path # The URL to download
```

灵感来自 <https://gist.github.com/mikecrittenden/fe02c59fed1aeebd0a9697cf7e9f5c0c>

---

## 原文（English）

One liner:

```bash
wget --recursive --no-clobber --span-hosts --page-requisites --html-extension --convert-links --restrict-file-names=windows --domains ys168.com --no-parent http://qzbltushu.ys168.com/
```

Explained:

```bash
wget \
     --recursive \ # Download the whole site.
     --page-requisites \ # Get all assets/elements (CSS/JS/images).
     --adjust-extension \ # Save files with .html on the end.
     --span-hosts \ # Include necessary assets from offsite as well.
     --convert-links \ # Update links to still work in the static version.
     --restrict-file-names=windows \ # Modify filenames to work in Windows as well.
     --domains yoursite.com \ # Do not follow links outside this domain.
     --no-parent \ # Don't follow links outside the directory you pass in.
         yoursite.com/whatever/path # The URL to download
```

Inspired by <https://gist.github.com/mikecrittenden/fe02c59fed1aeebd0a9697cf7e9f5c0c>
