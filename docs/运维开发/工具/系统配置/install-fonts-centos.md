---
tags:
  - Linux
  - 工具
---

# Install Hack font on CentOS


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Download zip

```
wget https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip
```

unzip

```
unzip Hack-v3.003-ttf.zip 
```

install

```
mv ttf hack
cp -r hack /usr/share/fonts/
fc-cache -f -v
```

Check

```
fc-list | grep "Hack"
```

# Install Windows Font

```
git clone https://github.com/hxp-plus/Windows-Font-Collection.git
cd Windows-Font-Collection
cp -r winfonts /usr/share/fonts/
fc-cache -f -v
```







 
