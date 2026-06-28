---
tags:
  - Linux
  - 工具
---

!!! warning "文档时效性说明"
本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

# 部署 kodexplorer 的最简单方法

原英文标题：Easiest way to deploy kodexplorer

```
docker run -d -p 80:80 --name kodexplorer -v "$PWD":/var/www/html yangxuan8282/kodexplorer
```
