---
tags:
  - Kubernetes
  - PostgreSQL
---

# 使用 stolon 安装高可用 PostgreSQL

## 准备工作

stolon 是一种安装在 kubernetes 的 PostgreSQL 数据库，因此需要一套完整的 k8s 集群，且必须有至少 1 个 StorageClass，推荐是 local-path-provisioner。

## 下载配置文件

以下 stolon 配置文件根据 <https://github.com/sorintlab/stolon/tree/master/examples/kubernetes> 的配置文件修改，把 namespace 改成 stolon，image 修改为 sorintlab/stolon:v0.17.0-pg13

## 新增 service account

创建 role.yaml：

```yaml
# This is an example and generic rbac role definition for stolon. It could be
# fine tuned and split per component.
# The required permission per component should be:
# keeper/proxy/sentinel: update their own pod annotations
# sentinel/stolonctl: get, create, update configmaps
# sentinel/stolonctl: list components pods
# sentinel/stolonctl: get components pods annotations

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: stolon
  namespace: stolon
rules:
  - apiGroups:
      - ""
    resources:
      - pods
      - configmaps
      - events
    verbs:
      - "*"
```

创建 role-binding.yaml：

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: stolon
  namespace: stolon
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: stolon
subjects:
  - kind: ServiceAccount
    name: default
    namespace: stolon
```

新增 service account：

```
kubectl create namespace stolon
kubectl apply -f role.yaml -f role-binding.yaml
```

## 创建 stolon 集群的 configmap

```
kubectl -n stolon run -i -t stolonctl --image=sorintlab/stolon:v0.17.0-pg13 --restart=Never --rm -- /usr/local/bin/stolonctl --cluster-name=kube-stolon --store-backend=kubernetes --kube-resource-kind=configmap init
```

## 创建 stolon 实例

获取集群的 storage class 信息：

```
kubectl get storageclasses.storage.k8s.io
```

```
NAME            PROVISIONER           RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-cephfs-sc   cephfs.csi.ceph.com   Delete
```

使用 csi-cephfs-sc 作为 storage class，修改 stolon-keeper.yaml：

```yaml
volumeClaimTemplates:
  - metadata:
      name: data
      annotations:
        volume.alpha.kubernetes.io/storage-class: csi-cephfs-sc
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 4Gi
      storageClassName: csi-cephfs-sc
```

设置一个密码，将其 base64 编码：

```
echo '********' | base64
```

修改 secret.yaml 中的 password 为 base64 的输出：

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: stolon
type: Opaque
data:
  password: "***********"
```

创建资源：

```
kubectl -n stolon create -f stolon-sentinel.yaml -f secret.yaml -f stolon-keeper.yaml -f stolon-proxy.yaml -f stolon-proxy-service.yaml
```

## 将 stolon 设置成三副本

```
kubectl -n stolon scale deployment stolon-proxy --replicas 3
kubectl -n stolon scale deployment stolon-sentinel --replicas 3
kubectl -n stolon scale statefulset stolon-keeper --replicas 3
```

## 测试 PostgreSQL 连通性

首先临时创建一个 PostgreSQL 容器：

```
kubectl -n stolon run -i -t stolon-client --image=sorintlab/stolon:v0.17.0-pg13 --restart=Never --rm -- /bin/bash
```

在容器里连接数据库：

```
psql --host stolon-proxy-service  --port 5432 postgres -U stolon -W
```

密码为刚刚 base64 设置的密码。

## 检查数据库状态

首先创建一个临时的容器：

```
kubectl -n stolon run -i -t stolon-client --image=sorintlab/stolon:v0.17.0-pg13 --restart=Never --rm -- /bin/bash
```

在容器里使用 stolonctl 检查集群状态：

```
/usr/local/bin/stolonctl --cluster-name=kube-stolon --store-backend=kubernetes --kube-resource-kind=configmap status
```

```
=== Active sentinels ===

ID		LEADER
558a0979	false
b509f383	true
bc1deda2	false

=== Active proxies ===

ID
65e8c81e
6c322c41
c19abd6d

=== Keepers ===

UID	HEALTHY	PG LISTENADDRESS	PG HEALTHY	PG WANTEDGENERATION	PG CURRENTGENERATION
keeper0	true	172.18.209.38:5432	true		4			4
keeper1	true	172.18.122.32:5432	true	2	2
keeper2	true	172.18.97.20:5432	true	2	2

=== Cluster Info ===

Master Keeper: keeper0

===== Keepers/DB tree =====

keeper0 (master)
├─keeper2
└─keeper1
```
