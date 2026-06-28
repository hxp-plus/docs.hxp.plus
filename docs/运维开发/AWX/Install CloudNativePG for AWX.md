---
tags:
  - AWX
  - Kubernetes
  - Ansible
---

# 为 AWX 安装 CloudNativePG


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Install CloudNativePG for AWX

## 在 Kubernetes 上安装 CNPG

```
kubectl apply -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.19/releases/cnpg-1.19.6.yaml
```

## 初始化 PostgreSQL 集群

### 为 awx 用户创建 Secret

```
vim awx-postgres-secret.yaml
```

```
apiVersion: v1
stringData:
  username: awx
  password: awx
kind: Secret
metadata:
  name: awx-secret
  namespace: cnpg
type: kubernetes.io/basic-auth
```

```
kubectl apply -f awx-postgres-secret.yaml
```

### 创建高可用 PG 集群

```
vim cluster-example.yaml
```

```
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-example
  namespace: cnpg
spec:
  instances: 3
  replicationSlots:
    highAvailability:
      enabled: true
  bootstrap:
    initdb:
      database: awx
      owner: awx
      secret:
        name: awx-secret
  storage:
    size: 10Gi
```

```
kubectl apply -f cluster-example.yaml
```

### 验证变更

```
kubectl get all -n cnpg --show-labels
```

```
NAME                    READY   STATUS    RESTARTS   AGE     LABELS
pod/cluster-example-1   1/1     Running   0          9m3s    cnpg.io/cluster=cluster-example,cnpg.io/instanceName=cluster-example-1,cnpg.io/instanceRole=primary,cnpg.io/podRole=instance,role=primary
pod/cluster-example-2   1/1     Running   0          8m33s   cnpg.io/cluster=cluster-example,cnpg.io/instanceName=cluster-example-2,cnpg.io/instanceRole=replica,cnpg.io/podRole=instance,role=replica
pod/cluster-example-3   1/1     Running   0          8m6s    cnpg.io/cluster=cluster-example,cnpg.io/instanceName=cluster-example-3,cnpg.io/instanceRole=replica,cnpg.io/podRole=instance,role=replica

NAME                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE     LABELS
service/cluster-example-r    ClusterIP   10.106.223.150   <none>        5432/TCP   9m14s   cnpg.io/cluster=cluster-example
service/cluster-example-ro   ClusterIP   10.99.154.121    <none>        5432/TCP   9m14s   cnpg.io/cluster=cluster-example
service/cluster-example-rw   ClusterIP   10.105.220.153   <none>        5432/TCP   9m14s   cnpg.io/cluster=cluster-example
```

```
psql -h 10.106.223.150 -U awx
```

```
Password for user awx: <type password or awx user here>
psql (15.4, server 16.0 (Debian 16.0-1.pgdg110+1))
WARNING: psql major version 15, server major version 16.
         Some psql features might not work.
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

awx=> \du
                                       List of roles
     Role name     |                         Attributes                         | Member of
-------------------+------------------------------------------------------------+-----------
 awx               |                                                            | {}
 postgres          | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 streaming_replica | Replication                                                | {}

awx=> quit
```

---

## 原文（English）

```
---
tags:
  - AWX
  - Kubernetes
  - Ansible
---

# Install CloudNativePG for AWX


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Install CNPG on Kubernetes

```
kubectl apply -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.19/releases/cnpg-1.19.6.yaml
```

## Bootstrap a PostgreSQL cluster

### Create a secret for user awx

```
vim awx-postgres-secret.yaml
```

```
apiVersion: v1
stringData:
  username: awx
  password: awx
kind: Secret
metadata:
  name: awx-secret
  namespace: cnpg
type: kubernetes.io/basic-auth
```

```
kubectl apply -f awx-postgres-secret.yaml
```

### Create the PG cluster with high availability

```
vim cluster-example.yaml
```

```
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-example
  namespace: cnpg
spec:
  instances: 3
  replicationSlots:
    highAvailability:
      enabled: true
  bootstrap:
    initdb:
      database: awx
      owner: awx
      secret:
        name: awx-secret
  storage:
    size: 10Gi
```

```
kubectl apply -f cluster-example.yaml
```

### Validate changes

```
kubectl get all -n cnpg --show-labels
```

```
NAME                    READY   STATUS    RESTARTS   AGE     LABELS
pod/cluster-example-1   1/1     Running   0          9m3s    cnpg.io/cluster=cluster-example,cnpg.io/instanceName=cluster-example-1,cnpg.io/instanceRole=primary,cnpg.io/podRole=instance,role=primary
pod/cluster-example-2   1/1     Running   0          8m33s   cnpg.io/cluster=cluster-example,cnpg.io/instanceName=cluster-example-2,cnpg.io/instanceRole=replica,cnpg.io/podRole=instance,role=replica
pod/cluster-example-3   1/1     Running   0          8m6s    cnpg.io/cluster=cluster-example,cnpg.io/instanceName=cluster-example-3,cnpg.io/instanceRole=replica,cnpg.io/podRole=instance,role=replica

NAME                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE     LABELS
service/cluster-example-r    ClusterIP   10.106.223.150   <none>        5432/TCP   9m14s   cnpg.io/cluster=cluster-example
service/cluster-example-ro   ClusterIP   10.99.154.121    <none>        5432/TCP   9m14s   cnpg.io/cluster=cluster-example
service/cluster-example-rw   ClusterIP   10.105.220.153   <none>        5432/TCP   9m14s   cnpg.io/cluster=cluster-example
```

```
psql -h 10.106.223.150 -U awx
```

```
Password for user awx: <type password or awx user here>
psql (15.4, server 16.0 (Debian 16.0-1.pgdg110+1))
WARNING: psql major version 15, server major version 16.
         Some psql features might not work.
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

awx=> \du
                                       List of roles
     Role name     |                         Attributes                         | Member of
-------------------+------------------------------------------------------------+-----------
 awx               |                                                            | {}
 postgres          | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 streaming_replica | Replication                                                | {}

awx=> quit
```
```
