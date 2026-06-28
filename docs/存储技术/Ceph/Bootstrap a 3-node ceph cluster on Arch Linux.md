---
tags:
  - Ceph
  - 存储
---

# 在 Arch Linux 上初始化 3 节点 Ceph 集群


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Bootstrap a 3-node ceph cluster on Arch Linux

## 本场景使用的环境

| IP Address | Hostname |
|------------|----------|
| 192\.168.11.50 | arch01 |
| 192\.168.11.51 | arch02 |
| 192\.168.11.52 | arch03 |

## 从 AUR 安装 ceph-18.2

```
sudo pacman -Sy patch make gcc which
git clone https://aur.archlinux.org/ceph.git
cd ceph
makepkg -si
# load rbd module on boot
echo rbd > /etc/modules-load.d/ceph.conf
```

## 配置 NTP 服务

```
pacman -S chrony
systemctl enable chronyd
systemctl restart chronyd
```

## 在第一个节点上初始化 Monitor

```
podman pull quay.io/ceph/ceph:v18
cephadm bootstrap --mon-ip 192.168.11.50
```

## 将其他节点加入集群

在 arch01 节点上，将 SSH 密钥复制到所有节点：

```
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.11.50
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.11.51
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.11.52
```

在 arch01 上，告知 Ceph 新节点是集群的一部分：

```
ceph orch host add arch02 192.168.11.51 --labels _admin
ceph orch host add arch03 192.168.11.52 --labels _admin
```

通过以下方式验证节点已在集群中：

```
ceph orch host ls
```

```
HOST    ADDR           LABELS  STATUS
arch01  192.168.11.50  _admin
arch02  192.168.11.51  _admin
arch03  192.168.11.52  _admin
3 hosts in cluster
```

## 在另外两个节点上部署 Monitor

Monitor 将自动部署在其他节点上。通过以下方式检查：

```
ceph -s | grep mon
```

```
    mon: 3 daemons, quorum arch01,arch02,arch03 (age 118s)
```

在 arch01 上。

## 添加 OSD

在 arch01 上运行：

```
ceph orch apply osd --all-available-devices
```

将所有节点上的所有空磁盘作为 OSD 加入集群。通过以下方式检查集群健康状态：

```
ceph -s
```

```
  cluster:
    id:     7e871668-7b83-11ee-8975-00155d0b0b04
    health: HEALTH_OK

  services:
    mon: 3 daemons, quorum arch01,arch02,arch03 (age 3m)
    mgr: arch01.ehmhjd(active, since 18m), standbys: arch02.ktsjoy
    osd: 3 osds: 0 up, 3 in (since 4s)

  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0 B
    usage:   0 B used, 0 B / 0 B avail
    pgs:
```

---

## 原文（English）

```
---
tags:
  - Ceph
  - 存储
---

# Bootstrap a 3-node ceph cluster on Arch Linux


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Environments used in this scenario

| IP Address | Hostname |
|------------|----------|
| 192\.168.11.50 | arch01 |
| 192\.168.11.51 | arch02 |
| 192\.168.11.52 | arch03 |

## Install ceph-18.2 from AUR

```
sudo pacman -Sy patch make gcc which
git clone https://aur.archlinux.org/ceph.git
cd ceph
makepkg -si
# load rbd module on boot
echo rbd > /etc/modules-load.d/ceph.conf
```

## Set up NTP service

```
pacman -S chrony
systemctl enable chronyd
systemctl restart chronyd
```

## Bootstrap the monitor on the first node

```
podman pull quay.io/ceph/ceph:v18
cephadm bootstrap --mon-ip 192.168.11.50
```

## Add the other nodes to the cluster

On node arch01, copy the ssh key to all nodes:

```
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.11.50
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.11.51
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.11.52
```

On arch01, tell Ceph that the new nodes are part of the cluster:

```
ceph orch host add arch02 192.168.11.51 --labels _admin
ceph orch host add arch03 192.168.11.52 --labels _admin
```

Verify that the nodes are in the cluster by:

```
ceph orch host ls
```

```
HOST    ADDR           LABELS  STATUS
arch01  192.168.11.50  _admin
arch02  192.168.11.51  _admin
arch03  192.168.11.52  _admin
3 hosts in cluster
```

## Deploying monitors on the other 2 nodes

Monitors will be deployed automatically on the other nodes. Check it by:

```
ceph -s | grep mon
```

```
    mon: 3 daemons, quorum arch01,arch02,arch03 (age 118s)
```

on arch01.

## Adding osds

On arch01, run:

```
ceph orch apply osd --all-available-devices
```

To add all empty disks on all nodes into the cluster as osd. Check cluster health by:

```
ceph -s
```

```
  cluster:
    id:     7e871668-7b83-11ee-8975-00155d0b0b04
    health: HEALTH_OK

  services:
    mon: 3 daemons, quorum arch01,arch02,arch03 (age 3m)
    mgr: arch01.ehmhjd(active, since 18m), standbys: arch02.ktsjoy
    osd: 3 osds: 0 up, 3 in (since 4s)

  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0 B
    usage:   0 B used, 0 B / 0 B avail
    pgs:
```
```