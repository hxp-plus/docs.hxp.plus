---
tags:
  - Linux
  - 工具
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Un-register the system :

```
sudo subscription-manager remove --all
sudo subscription-manager unregister
sudo subscription-manager clean
```

Re-register the system :

```
sudo subscription-manager register
sudo subscription-manager refresh
```

Search for the Pool ID :

```
sudo subscription-manager list --available
```

Attach to subscription :

```
subscription-manager role --set="Red Hat Enterprise Linux Workstation"
subscription-manager service-level --set="Self-Support"
subscription-manager usage --set="Development/Test"
subscription-manager attach --pool <pool_id>
```

Set release ver

```
subscription-manager release --set 8
```

Clean YUM and cache :

```
sudo dnf clean all
sudo rm -r /var/cache/dnf
```

Update the resources :

```
sudo dnf upgrade
```

Install epel

```
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
```
