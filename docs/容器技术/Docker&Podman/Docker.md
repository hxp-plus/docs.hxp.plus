---
tags:
  - Docker
  - 容器
---

# Increase Docker Download Speed in China Mainland #


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Using Azure mirror and Netease mirror.

Add these in `/etc/docker/daemon`. (touch this file if it does not exist)

```
{
  "registry-mirrors": [
    "https://dockerhub.azk8s.cn",
    "https://hub-mirror.c.163.com"
  ]
}
```
Then run

``` shell
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```

