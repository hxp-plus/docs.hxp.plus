---
tags:
  - OpenStack
---

# 在 CentOS Stream 上安装 OpenStack All-in-one


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Install OpenStack All-in-one CentOS Stream

Disable SELinux, install network-scripts, enable network, mask, disable, stop NetworkManager and firewalld, and run

```bash
sudo dnf install -y https://www.rdoproject.org/repos/rdo-release.el8.rpm
sudo dnf config-manager --enable powertools
sudo dnf install -y openstack-packstack
```

Then use packstack to deploy OpenStack

```bash
sudo packstack --gen-answer-file=/root/answers.txt
sudo vim /root/answers.txt
sudo packstatk --answer-file=/root/answers.txt
```



