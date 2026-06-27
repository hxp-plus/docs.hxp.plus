---
tags:
  - Ceph
  - 存储
---

# Adding additional monitor and osd nodes to Ceph cluster


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 将新主机添加到集群

```
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.11.54
ceph orch host add arch04 192.168.11.54 --labels _admin
```

通过以下方式验证变更：

```
ceph orch host ls
```

```
HOST    ADDR           LABELS               STATUS
arch01  192.168.11.50  _admin
arch02  192.168.11.51  _admin
arch03  192.168.11.52  _admin,_no_schedule
arch04  192.168.11.54  _admin
4 hosts in cluster
```

```
ceph orch ps arch04
```

```
NAME                  HOST    PORTS   STATUS        REFRESHED  AGE  MEM USE  MEM LIM  VERSION  IMAGE ID      CONTAINER ID
ceph-exporter.arch04  arch04          running (3m)    57s ago   3m    4882k        -  18.2.0   baf61ab265f8  459465439bf9
crash.arch04          arch04          running (3m)    57s ago   3m    6665k        -  18.2.0   baf61ab265f8  0ffd092307fa
node-exporter.arch04  arch04  *:9100  running (3m)    57s ago   3m    15.8M        -  1.5.0    0da6a335fe13  fa26ca567639
```

## 向主机部署 Monitor 守护进程

```
ceph orch apply mon --placement="arch01;arch02;arch04"
```

验证：

```
ceph -s | grep mon:
```

```
    mon: 3 daemons, quorum arch01,arch02,arch04 (age 42s)
```

## 向主机部署 Manager 守护进程

```
ceph orch apply mgr --placement="arch01;arch02;arch04"
```

验证：

```
ceph -s | grep mgr:
```

```
    mgr: arch01.ehmhjd(active, since 2h), standbys: arch02.ktsjoy, arch04.bdxjpe
```

## 向主机部署 OSD

```
ceph orch daemon add osd arch04:/dev/sdb
```

验证：

```
ceph osd tree
```

```
ID  CLASS  WEIGHT   TYPE NAME        STATUS  REWEIGHT  PRI-AFF
-1         0.37198  root default
-3         0.12399      host arch01
 1    hdd  0.12399          osd.1        up   1.00000  1.00000
-5         0.12399      host arch02
 0    hdd  0.12399          osd.0        up   1.00000  1.00000
-7               0      host arch03
-9         0.12399      host arch04
 3    hdd  0.12399          osd.3        up   1.00000  1.00000
```

---

## 原文（English）

```
---
tags:
  - Ceph
  - 存储
---

# Adding additional monitor and osd nodes to Ceph cluster


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Add a new host to the cluster

```
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.11.54
ceph orch host add arch04 192.168.11.54 --labels _admin
```

Validate changes by:

```
ceph orch host ls
```

```
HOST    ADDR           LABELS               STATUS
arch01  192.168.11.50  _admin
arch02  192.168.11.51  _admin
arch03  192.168.11.52  _admin,_no_schedule
arch04  192.168.11.54  _admin
4 hosts in cluster
```

```
ceph orch ps arch04
```

```
NAME                  HOST    PORTS   STATUS        REFRESHED  AGE  MEM USE  MEM LIM  VERSION  IMAGE ID      CONTAINER ID
ceph-exporter.arch04  arch04          running (3m)    57s ago   3m    4882k        -  18.2.0   baf61ab265f8  459465439bf9
crash.arch04          arch04          running (3m)    57s ago   3m    6665k        -  18.2.0   baf61ab265f8  0ffd092307fa
node-exporter.arch04  arch04  *:9100  running (3m)    57s ago   3m    15.8M        -  1.5.0    0da6a335fe13  fa26ca567639
```

## Deploy monitor daemon to host

```
ceph orch apply mon --placement="arch01;arch02;arch04"
```

Validate by:

```
ceph -s | grep mon:
```

```
    mon: 3 daemons, quorum arch01,arch02,arch04 (age 42s)
```

## Deploy manager daemon to host

```
ceph orch apply mgr --placement="arch01;arch02;arch04"
```

Validate by:

```
ceph -s | grep mgr:
```

```
    mgr: arch01.ehmhjd(active, since 2h), standbys: arch02.ktsjoy, arch04.bdxjpe
```

## Deploy OSD to host

```
ceph orch daemon add osd arch04:/dev/sdb
```

Validate by:

```
ceph osd tree
```

```
ID  CLASS  WEIGHT   TYPE NAME        STATUS  REWEIGHT  PRI-AFF
-1         0.37198  root default
-3         0.12399      host arch01
 1    hdd  0.12399          osd.1        up   1.00000  1.00000
-5         0.12399      host arch02
 0    hdd  0.12399          osd.0        up   1.00000  1.00000
-7               0      host arch03
-9         0.12399      host arch04
 3    hdd  0.12399          osd.3        up   1.00000  1.00000
```
```