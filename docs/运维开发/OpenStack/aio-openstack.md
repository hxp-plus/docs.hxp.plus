---
tags:
  - OpenStack
---

# Install All-in-One OpenStack Platform


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Edit `/etc/environment` and add

```shell
ALL_PROXY=<your_http_proxy>
```

and follow <https://docs.openstack.org/openstack-ansible/latest/user/aio/quickstart.html>
