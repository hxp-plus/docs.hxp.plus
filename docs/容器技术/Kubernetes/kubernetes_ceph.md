---
tags:
  - Kubernetes
  - k8s
---

# 使用 Ceph 作为 Kubernetes 存储后端


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Using Ceph as Kubernetes storage backend

# 参考链接

## 创建 Ceph 存储池

```
[root@ceph-1 ~]# ceph osd pool create kubernetes
pool 'kubernetes' created
[root@ceph-1 ~]# rbd pool init kubernetes
[root@ceph-1 ~]# ceph -s
  cluster:
    id:     03d6027c-3357-11ee-8af8-525400dfcf37
    health: HEALTH_OK

  services:
    mon: 3 daemons, quorum ceph-1,ceph-2,ceph-3 (age 22h)
    mgr: ceph-1.ttwmch(active, since 22h), standbys: ceph-2.fixhqd
    mds: 1/1 daemons up, 1 standby
    osd: 3 osds: 3 up (since 22h), 3 in (since 22h)

  data:
    volumes: 1/1 healthy
    pools:   4 pools, 81 pgs
    objects: 25 objects, 462 KiB
    usage:   71 MiB used, 96 GiB / 96 GiB avail
    pgs:     81 active+clean

  progress:
```

## 配置 Ceph-CSI

```
[root@ceph-1 ~]# ceph auth get-or-create client.kubernetes mon 'profile rbd' osd 'profile rbd pool=kubernetes' mgr 'profile rbd pool=kubernetes'
[client.kubernetes]
        key = AQAAK89k73cqNBAARKfeeaRn8dxOMxR/EvvLDw==
```

## 生成 ConfigMap

在 Ceph 上：

```
[root@ceph-1 ~]# ceph mon dump
epoch 3
fsid 03d6027c-3357-11ee-8af8-525400dfcf37
last_changed 2023-08-05T06:40:23.602118+0000
created 2023-08-05T06:12:58.227480+0000
min_mon_release 17 (quincy)
election_strategy: 1
0: [v2:192.168.100.31:3300/0,v1:192.168.100.31:6789/0] mon.ceph-1
1: [v2:192.168.100.32:3300/0,v1:192.168.100.32:6789/0] mon.ceph-2
2: [v2:192.168.100.33:3300/0,v1:192.168.100.33:6789/0] mon.ceph-3
dumped monmap epoch 3
```

在 Kubernetes 上：

```
cat <<EOF > csi-config-map.yaml
---
apiVersion: v1
kind: ConfigMap
data:
  config.json: |-
    [
      {
        "clusterID": "03d6027c-3357-11ee-8af8-525400dfcf37",
        "monitors": [
          "192.168.100.31:6789",
          "192.168.100.32:6789",
          "192.168.100.33:6789"
        ]
      }
    ]
metadata:
  name: ceph-csi-config
EOF
```

```
kubectl apply -f csi-config-map.yaml
```

```
cat <<EOF > csi-kms-config-map.yaml
---
apiVersion: v1
kind: ConfigMap
data:
  config.json: |-
    {}
metadata:
  name: ceph-csi-encryption-kms-config
EOF
```

```
kubectl apply -f csi-kms-config-map.yaml
```

```
cat <<EOF > ceph-config-map.yaml
---
apiVersion: v1
kind: ConfigMap
data:
  ceph.conf: |
    [global]
    auth_cluster_required = cephx
    auth_service_required = cephx
    auth_client_required = cephx
  # keyring is a required key and its value should be empty
  keyring: |
metadata:
  name: ceph-config
EOF
```

```
kubectl apply -f ceph-config-map.yaml
```

```
cat <<EOF > csi-rbd-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: csi-rbd-secret
  namespace: default
stringData:
  userID: kubernetes
  userKey: AQAAK89k73cqNBAARKfeeaRn8dxOMxR/EvvLDw==
EOF
```

```
kubectl apply -f csi-rbd-secret.yaml
```

## 安装 Ceph-csi 插件

```
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-provisioner-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-nodeplugin-rbac.yaml
wget https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-rbdplugin-provisioner.yaml
kubectl apply -f csi-rbdplugin-provisioner.yaml
wget https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-rbdplugin.yaml
kubectl apply -f csi-rbdplugin.yaml
```

## 创建 StorageClass

```
cat <<EOF > csi-rbd-sc.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: csi-rbd-sc
provisioner: rbd.csi.ceph.com
parameters:
   clusterID: 03d6027c-3357-11ee-8af8-525400dfcf37
   pool: kubernetes
   imageFeatures: layering
   csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
   csi.storage.k8s.io/provisioner-secret-namespace: default
   csi.storage.k8s.io/controller-expand-secret-name: csi-rbd-secret
   csi.storage.k8s.io/controller-expand-secret-namespace: default
   csi.storage.k8s.io/node-stage-secret-name: csi-rbd-secret
   csi.storage.k8s.io/node-stage-secret-namespace: default
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions:
   - discard
EOF
```

```
kubectl apply -f csi-rbd-sc.yaml
```

## 创建 PVC

```
cat <<EOF > raw-block-pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: raw-block-pvc
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Block
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-rbd-sc
EOF
```

```
kubectl apply -f raw-block-pvc.yaml
```

## 将 Ceph StorageClass 设为默认

```
[root@k8s-1 ~]# kubectl get storageclass
NAME         PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc   rbd.csi.ceph.com   Delete          Immediate           true                   18m
[root@k8s-1 ~]# kubectl patch storageclass csi-rbd-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
storageclass.storage.k8s.io/csi-rbd-sc patched
[root@k8s-1 ~]# kubectl get storageclass
NAME                   PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc (default)   rbd.csi.ceph.com   Delete          Immediate           true                   18m
```

https://docs.ceph.com/en/latest/rbd/rbd-kubernetes/

---

## 原文（English）

---
tags:
  - Kubernetes
  - k8s
---

# Using Ceph as Kubernetes storage backend


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

# References

## Create a Ceph storage pool

```
[root@ceph-1 ~]# ceph osd pool create kubernetes
pool 'kubernetes' created
[root@ceph-1 ~]# rbd pool init kubernetes
[root@ceph-1 ~]# ceph -s
  cluster:
    id:     03d6027c-3357-11ee-8af8-525400dfcf37
    health: HEALTH_OK

  services:
    mon: 3 daemons, quorum ceph-1,ceph-2,ceph-3 (age 22h)
    mgr: ceph-1.ttwmch(active, since 22h), standbys: ceph-2.fixhqd
    mds: 1/1 daemons up, 1 standby
    osd: 3 osds: 3 up (since 22h), 3 in (since 22h)

  data:
    volumes: 1/1 healthy
    pools:   4 pools, 81 pgs
    objects: 25 objects, 462 KiB
    usage:   71 MiB used, 96 GiB / 96 GiB avail
    pgs:     81 active+clean

  progress:
```

## Configure Ceph-CSI

```
[root@ceph-1 ~]# ceph auth get-or-create client.kubernetes mon 'profile rbd' osd 'profile rbd pool=kubernetes' mgr 'profile rbd pool=kubernetes'
[client.kubernetes]
        key = AQAAK89k73cqNBAARKfeeaRn8dxOMxR/EvvLDw==
```

## Generate config map

on Ceph:

```
[root@ceph-1 ~]# ceph mon dump
epoch 3
fsid 03d6027c-3357-11ee-8af8-525400dfcf37
last_changed 2023-08-05T06:40:23.602118+0000
created 2023-08-05T06:12:58.227480+0000
min_mon_release 17 (quincy)
election_strategy: 1
0: [v2:192.168.100.31:3300/0,v1:192.168.100.31:6789/0] mon.ceph-1
1: [v2:192.168.100.32:3300/0,v1:192.168.100.32:6789/0] mon.ceph-2
2: [v2:192.168.100.33:3300/0,v1:192.168.100.33:6789/0] mon.ceph-3
dumped monmap epoch 3
```

on Kubernetes:

```
cat <<EOF > csi-config-map.yaml
---
apiVersion: v1
kind: ConfigMap
data:
  config.json: |-
    [
      {
        "clusterID": "03d6027c-3357-11ee-8af8-525400dfcf37",
        "monitors": [
          "192.168.100.31:6789",
          "192.168.100.32:6789",
          "192.168.100.33:6789"
        ]
      }
    ]
metadata:
  name: ceph-csi-config
EOF
```

```
kubectl apply -f csi-config-map.yaml
```

```
cat <<EOF > csi-kms-config-map.yaml
---
apiVersion: v1
kind: ConfigMap
data:
  config.json: |-
    {}
metadata:
  name: ceph-csi-encryption-kms-config
EOF
```

```
kubectl apply -f csi-kms-config-map.yaml
```

```
cat <<EOF > ceph-config-map.yaml
---
apiVersion: v1
kind: ConfigMap
data:
  ceph.conf: |
    [global]
    auth_cluster_required = cephx
    auth_service_required = cephx
    auth_client_required = cephx
  # keyring is a required key and its value should be empty
  keyring: |
metadata:
  name: ceph-config
EOF
```

```
kubectl apply -f ceph-config-map.yaml
```

```
cat <<EOF > csi-rbd-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: csi-rbd-secret
  namespace: default
stringData:
  userID: kubernetes
  userKey: AQAAK89k73cqNBAARKfeeaRn8dxOMxR/EvvLDw==
EOF
```

```
kubectl apply -f csi-rbd-secret.yaml
```

## Install Ceph-csi plugin

```
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-provisioner-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-nodeplugin-rbac.yaml
wget https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-rbdplugin-provisioner.yaml
kubectl apply -f csi-rbdplugin-provisioner.yaml
wget https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-rbdplugin.yaml
kubectl apply -f csi-rbdplugin.yaml
```

## Create storage class

```
cat <<EOF > csi-rbd-sc.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: csi-rbd-sc
provisioner: rbd.csi.ceph.com
parameters:
   clusterID: 03d6027c-3357-11ee-8af8-525400dfcf37
   pool: kubernetes
   imageFeatures: layering
   csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
   csi.storage.k8s.io/provisioner-secret-namespace: default
   csi.storage.k8s.io/controller-expand-secret-name: csi-rbd-secret
   csi.storage.k8s.io/controller-expand-secret-namespace: default
   csi.storage.k8s.io/node-stage-secret-name: csi-rbd-secret
   csi.storage.k8s.io/node-stage-secret-namespace: default
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions:
   - discard
EOF
```

```
kubectl apply -f csi-rbd-sc.yaml
```

## Create a PVC

```
cat <<EOF > raw-block-pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: raw-block-pvc
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Block
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-rbd-sc
EOF
```

```
kubectl apply -f raw-block-pvc.yaml
```

## Make Ceph storage class the default

```
[root@k8s-1 ~]# kubectl get storageclass
NAME         PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc   rbd.csi.ceph.com   Delete          Immediate           true                   18m
[root@k8s-1 ~]# kubectl patch storageclass csi-rbd-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
storageclass.storage.k8s.io/csi-rbd-sc patched
[root@k8s-1 ~]# kubectl get storageclass
NAME                   PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc (default)   rbd.csi.ceph.com   Delete          Immediate           true                   18m
```

https://docs.ceph.com/en/latest/rbd/rbd-kubernetes/
