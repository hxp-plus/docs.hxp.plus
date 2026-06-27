---
tags:
  - AWX
  - Kubernetes
  - Ansible
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

首先进入awx_web容器：
```
docker exec -it awx_web /bin/bash
```
然后列出当前实例组：
```
awx-manage list_instances
```
```
[tower capacity=299 policy=100%]
	awx capacity=299 version=13.0.0 heartbeat="2023-05-15 09:31:10"
```
增加实例：
```
awx-manage provision_instance --hostname 22.185.158.235 --is-isolated
Successfully registered instance Ansible-ZJYL
(changed: True)
```
增加实例组：
```
awx-manage register_queue --queuename Ansible-YL --hostname 22.185.158.235 --controller tower
```
配置互信：
```
awx-manage generate_isolated_key
```
把ssh密钥分发给 22.185.158.235 的 AWX 用户。最后测试：
```
awx-manage test_isolated_connection --hostname 22.185.158.235 -v 2
```

删除实例组：
```
awx-manage unregister_queue --queuename ANSIBLE-YL
```

删除实例：
```
awx-manage remove_from_queue --hostname 22.185.158.235 --queuename tower
```
