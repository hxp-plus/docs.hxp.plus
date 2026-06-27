---
tags:
  - Ceph
  - 存储
---

# 3 node ceph cluster install on CentOS 8 Stream


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

在所有节点上安装 cephadm：

```
yum install python3
```

```
#!/bin/bash
yum install -y python3
CEPH_RELEASE=17.2.6 # replace this with the active release
curl --silent --remote-name --location https://download.ceph.com/rpm-${CEPH_RELEASE}/el9/noarch/cephadm
chmod +x cephadm
./cephadm add-repo --release quincy
./cephadm install
yum install -y ceph-common ceph-fuse
```

在第一个节点上初始化集群：

```
cephadm bootstrap --mon-ip 192.168.100.31
```

从第一个节点复制 SSH 密钥到其他节点：

```
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.100.32
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.100.33
```

在第一个节点上将另外两个节点加入集群：

```
./cephadm shell -- ceph orch host add ceph-2 192.168.100.32
./cephadm shell -- ceph orch host add ceph-3 192.168.100.33
./cephadm shell -- ceph orch host label add ceph-2 _admin
./cephadm shell -- ceph orch host label add ceph-3 _admin
```

添加 OSD：

```
./cephadm shell -- ceph orch apply osd --all-available-devices
```

添加 CephFS 卷：

```
ceph fs volume create cephfs
```

在 Ceph 客户端上：

```
mkdir -p -m 755 /etc/ceph
ssh root@192.168.100.31 "ceph config generate-minimal-conf" | sudo tee /etc/ceph/ceph.conf
chmod 644 /etc/ceph/ceph.conf
ssh root@192.168.100.31 "sudo ceph fs authorize cephfs_awx client.awx / rw" | sudo tee /etc/ceph/ceph.client.awx.keyring
chmod 600 /etc/ceph/ceph.client.awx.keyring
mkdir /mnt/mycephfs
echo "none    /mnt/mycephfs  fuse.ceph ceph.id=awx,ceph.conf=/etc/ceph/ceph.conf,_netdev,defaults  0 0" | tee -a /etc
/fstab
systemctl start ceph-fuse@/mnt/mycephfs.service
systemctl enable ceph-fuse.target
systemctl enable ceph-fuse@-mnt-mycephfs.service
mount -a
```



# 参考链接

<https://docs.ceph.com/en/latest/cephadm/install/#cephadm-deploying-new-cluster>

<https://docs.ceph.com/en/latest/cephadm/install/>

<https://docs.ceph.com/en/latest/cephfs/>

<https://docs.ceph.com/en/latest/rbd/rbd-kubernetes/>

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/

---

## 原文（English）

```
---
tags:
  - Ceph
  - 存储
---

# 3 node ceph cluster install on CentOS 8 Stream


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Install cephadm on the all nodes:

```
yum install python3
```

```
#!/bin/bash
yum install -y python3
CEPH_RELEASE=17.2.6 # replace this with the active release
curl --silent --remote-name --location https://download.ceph.com/rpm-${CEPH_RELEASE}/el9/noarch/cephadm
chmod +x cephadm
./cephadm add-repo --release quincy
./cephadm install
yum install -y Ceph-common Ceph-fuse
```

on the first node, bootstrap the cluster:

```
cephadm bootstrap --mon-ip 192.168.100.31
```

copy ssh key from first node to other nodes:

```
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.100.32
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.100.33
```

joining two other nodes on the first node:

```
./cephadm shell -- Ceph orch host add Ceph-2 192.168.100.32
./cephadm shell -- Ceph orch host add Ceph-3 192.168.100.33
./cephadm shell -- Ceph orch host label add Ceph-2 _admin
./cephadm shell -- Ceph orch host label add Ceph-3 _admin
```

adding osd:

```
./cephadm shell -- Ceph orch apply osd --all-available-devices
```

add a cephfs volume:

```
Ceph fs volume create cephfs
```

on ceph client:

```
mkdir -p -m 755 /etc/ceph
ssh root@192.168.100.31 "Ceph config generate-minimal-conf" | sudo tee /etc/ceph/ceph.conf
chmod 644 /etc/ceph/ceph.conf
ssh root@192.168.100.31 "sudo Ceph fs authorize cephfs_awx client.AWX / rw" | sudo tee /etc/ceph/ceph.client.awx.keyring
chmod 600 /etc/ceph/ceph.client.awx.keyring
mkdir /mnt/mycephfs
echo "none    /mnt/mycephfs  fuse.Ceph Ceph.id=AWX,Ceph.conf=/etc/Ceph/Ceph.conf,_netdev,defaults  0 0" | tee -a /etc
/fstab
systemctl start Ceph-fuse@/mnt/mycephfs.service
systemctl enable Ceph-fuse.target
systemctl enable Ceph-fuse@-mnt-mycephfs.service
mount -a
```



# References

<https://docs.ceph.com/en/latest/cephadm/install/#cephadm-deploying-new-cluster>

<https://docs.ceph.com/en/latest/cephadm/install/>

<https://docs.ceph.com/en/latest/cephfs/>

<https://docs.ceph.com/en/latest/rbd/rbd-kubernetes/>

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
```
