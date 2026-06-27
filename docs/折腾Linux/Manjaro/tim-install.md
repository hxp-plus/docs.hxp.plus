---
tags:
  - Manjaro
  - Linux
---

# Install Tencent TIM on Manjaro


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

# Install TIM (Spark store version)

```bash
yay -Sy com.qq.tim.spark
```

## Install Windows fonts

```bash
cd /tmp
git clone https://github.com/hxp-plus/Windows-Font-Collection.git
cd Windows-Font-Collection
cp -r winfonts/* ~/.deepinwine/Spark-TIM/drive_c/windows/Fonts
```

## Update font cache

```bash
fc-cache -fv
```

and then reboot (P.S. I don't know why TIM crashes every time before I restarted completely. Log out and Log in did not work).