---
tags:
  - Kubernetes
  - k8s
---

# 在 Kubernetes 上安装 Kubegres 数据库（使用 local path storage provisioner）


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Install the Kubegres database with local path storage provisioner on kubernetes

## 安装 local path storage provisioner

```
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml # 在一个 master 节点上执行
mkdir /opt/local-path-provisioner # 在所有 k8s 节点上执行
```

## 将 local path storage provisioner 设为默认 StorageClass

```
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
storageclass.storage.k8s.io/local-path patched
```

## 安装 Kubegres operator

```
kubectl apply -f https://raw.githubusercontent.com/reactive-tech/kubegres/v1.16/kubegres.yaml
```

运行后，可以按以下方式检查控制器的日志：

```
kubectl logs pod/kubegres-controller-manager-999786dd6-74tmb -c manager -n kubegres-system -f
```

## 创建 Secret 资源

创建 my-postgres-secret.YAML：

```
apiVersion: v1
kind: Secret
metadata:
  name: mypostgres-secret
  namespace: awx
type: Opaque
stringData:
  superUserPassword: postgresSuperUserPsw
  replicationUserPassword: postgresReplicaPsw
```

```
kubectl apply -f my-postgres-secret.yaml
```

## 创建 PostgreSQL 实例集群

创建 my-postgres.YAML：

```
apiVersion: kubegres.reactive-tech.io/v1
kind: Kubegres
metadata:
  name: mypostgres
  namespace: awx
spec:
   replicas: 3
   image: postgres:13.0
   database:
      size: 20Gi
   env:
      - name: POSTGRES_PASSWORD
        valueFrom:
           secretKeyRef:
              name: mypostgres-secret
              key: superUserPassword
      - name: POSTGRES_REPLICATION_PASSWORD
        valueFrom:
           secretKeyRef:
              name: mypostgres-secret
              key: replicationUserPassword
```

```
kubectl apply -f my-postgres.yaml
```

## 连接客户端应用到 PostgreSQL

基于我们创建的 Kubegres YAML，位于同一 Kubernetes 集群内的客户端应用可以使用以下配置连接到 PostgreSQL 数据库：

- host: mypostgres
- port: 5432
- username: postgres
- password: [value of mypostgres-secret/superUserPassword]

# 参考链接

https://www.kubegres.io/doc/getting-started.html

---

## 原文（English）

---
tags:
  - Kubernetes
  - k8s
---

# Install the Kubegres database with local path storage provisioner on kubernetes


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Install local path storage provisoner

```
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml # Execute on one master node
mkdir /opt/local-path-provisioner # Execute on all k8s nodes
```

## Make local path storage provisioner default storage class

```
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
storageclass.storage.k8s.io/local-path patched
```

## Install Kubegres operator

```
kubectl apply -f https://raw.githubusercontent.com/reactive-tech/kubegres/v1.16/kubegres.yaml
```

Once it is running, we can check the controller's logs, as follows:

```
kubectl logs pod/kubegres-controller-manager-999786dd6-74tmb -c manager -n kubegres-system -f
```

## Create a Secret resource

create my-postgres-secret.YAML:

```
apiVersion: v1
kind: Secret
metadata:
  name: mypostgres-secret
  namespace: awx
type: Opaque
stringData:
  superUserPassword: postgresSuperUserPsw
  replicationUserPassword: postgresReplicaPsw
```

```
kubectl apply -f my-postgres-secret.yaml
```

## Create a cluster of PostgreSQL instances

create my-postgres.YAML:

```
apiVersion: kubegres.reactive-tech.io/v1
kind: Kubegres
metadata:
  name: mypostgres
  namespace: awx
spec:
   replicas: 3
   image: postgres:13.0
   database:
      size: 20Gi
   env:
      - name: POSTGRES_PASSWORD
        valueFrom:
           secretKeyRef:
              name: mypostgres-secret
              key: superUserPassword
      - name: POSTGRES_REPLICATION_PASSWORD
        valueFrom:
           secretKeyRef:
              name: mypostgres-secret
              key: replicationUserPassword
```

```
kubectl apply -f my-postgres.yaml
```

## Connect client apps to PostgreSQL

Based on the Kubegres YAML that we have created, a client app located inside the same Kubernetes cluster would use the following configurations to connect to a PostgreSQL database:

- host: mypostgres
- port: 5432
- username: postgres
- password: [value of mypostgres-secret/superUserPassword]

# References

https://www.kubegres.io/doc/getting-started.html
