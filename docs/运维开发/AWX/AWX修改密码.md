---
tags:
  - AWX
  - Kubernetes
  - Ansible
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

进入awx_web容器，使用awx-manage命令

创建超级用户：
```
awx-manage createsuperuser --username=admin --email=admin@example.com --noinput
```

修改用户密码：
```
awx-manage update_password --username=admin --password=changeme
```
