---
tags:
  - Ceph
  - 存储
---

# Remove a node from Ceph cluster


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 从主机上驱逐所有守护进程

```
ceph orch host drain arch03
```

## 等待 OSD 上的所有 PG 被重新分配

通过以下方式获取 OSD 移除状态：

```
ceph orch osd rm status
```

等待直到显示 "No OSD remove/replace operations reported"

## 从集群中移除主机

首先，确保主机上没有守护进程在运行：

```
ceph orch ps arch03
```

```
No daemons reported
```

然后，将其从集群中移除：

```
ceph orch host rm arch03
```

验证：

```
ceph -s
```

```
  cluster:
    id:     7e871668-7b83-11ee-8975-00155d0b0b04
    health: HEALTH_WARN
            Failed to apply 1 service(s): mon

  services:
    mon: 3 daemons, quorum arch01,arch02,arch04 (age 10m)
    mgr: arch01.ehmhjd(active, since 2h), standbys: arch02.ktsjoy
    osd: 3 osds: 3 up (since 6m), 3 in (since 6m)

  data:
    pools:   1 pools, 1 pgs
    objects: 2 objects, 449 KiB
    usage:   82 MiB used, 381 GiB / 381 GiB avail
    pgs:     1 active+clean
```

## 销毁并擦除 OSD

在已移除的主机上：

```
ceph-volume lvm zap /dev/sdb --destroy
```

---

## 原文（English）

```
---
tags:
  - Ceph
  - 存储
---

# Remove a node from Ceph cluster


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Drain all daemons from the host

```
ceph orch host drain arch03
```

## Wait until all PGs on OSDs are replaced

Get OSD removing status by :

```
ceph orch osd rm status
```

Wait until "No OSD remove/replace operations reported"

## Remove the host from the cluster

First, make sure no daemon is running on the host:

```
ceph orch ps arch03
```

```
No daemons reported
```

Then, remove it from the cluster:

```
ceph orch host rm arch03
```

Validate by :

```
ceph -s
```

```
  cluster:
    id:     7e871668-7b83-11ee-8975-00155d0b0b04
    health: HEALTH_WARN
            Failed to apply 1 service(s): mon

  services:
    mon: 3 daemons, quorum arch01,arch02,arch04 (age 10m)
    mgr: arch01.ehmhjd(active, since 2h), standbys: arch02.ktsjoy
    osd: 3 osds: 3 up (since 6m), 3 in (since 6m)

  data:
    pools:   1 pools, 1 pgs
    objects: 2 objects, 449 KiB
    usage:   82 MiB used, 381 GiB / 381 GiB avail
    pgs:     1 active+clean
```

## Destroy and wipe OSD

On the removed host :

```
ceph-volume lvm zap /dev/sdb --destroy
```
```