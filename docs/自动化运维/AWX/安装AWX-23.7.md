---
tags:
  - Kubernetes
  - AWX
---

# 安装 AWX-23.7

## 准备工作

AWX 高版本必须依托于 k8s 进行安装，且需要使用 PostgreSQL-13 数据库。

## 安装 awx-operator

编辑`kustomization.yaml`：

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  - github.com/ansible/awx-operator/config/default?ref=2.11.0

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.11.0

# Specify a custom namespace in which to install AWX
namespace: awx
```

生成 yaml 文件：

```
kubectl apply -k . -o yaml --dry-run=client > awx-operator.yaml
```

如果需要离线部署，需要把`awx-operator.yaml`中`imagePullPolicy: Always`修改为`imagePullPolicy: IfNotPresent`，
将 yaml 文件应用：

```
kubectl create namespace awx
kubectl -n awx apply -f awx-operator.yaml
```

## 配置 PostgreSQL 数据库用户

AWX 存储数据需要一套 PostgreSQL-13 数据库，数据库需要新建用户 awx 和数据库 awx：

```
psql -h postgresql-13 -U postgres
```

```
Password for user postgres:
psql (13.11, server 13.0 (Debian 13.0-1.pgdg100+1))
Type "help" for help.

postgres=# CREATE USER awx WITH ENCRYPTED PASSWORD '********';
CREATE ROLE
postgres=# CREATE DATABASE awx OWNER awx;
CREATE DATABASE
postgres=# exit
```

## 安装 AWX 并配置其使用外部数据库

定义 AWX 资源，新建`awx.yaml`：

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  ingress_type: ingress
  ingress_path: /
  ingress_hosts:
    - hostname: awx.y.bocsys.cn
  ee_images:
    - name: awx-ee
      image: quay.io/ansible/awx-ee:23.7.0
  control_plane_ee_image: quay.io/ansible/awx-ee:23.7.0
  init_container_image: quay.io/ansible/awx-ee
  init_container_image_version: 23.7.0
  task_replicas: 3
  web_replicas: 3
  task_topology_spread_constraints: |
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: "awx-task"
  web_topology_spread_constraints: |
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: "awx-web"
  postgres_configuration_secret: awx-postgres-configuration
```

新建数据库配置`awx-postgres-configuration.yaml`：

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-postgres-configuration
  namespace: awx
stringData:
  host: postgresql-13
  port: "5432"
  database: awx
  username: awx
  password: "********"
  sslmode: prefer
  type: unmanaged
type: Opaque
```

将两个 yaml 文件应用：

```
kubectl -n awx apply -f awx-postgres-configuration.yaml
kubectl -n awx apply -f awx.yaml
```

观察部署进度：

```
kubectl -n awx logs -f deployments/awx-operator-controller-manager
```

获取默认 admin 密码：

```
kubectl -n awx get secret awx-admin-password -o jsonpath="{.data.password}" | base64 --decode; echo
```

## 参考链接

https://github.com/ansible/awx-operator/blob/devel/docs/installation/basic-install.md

https://elatov.github.io/2022/03/deploying-awx-in-k8s-with-awx-operator/

https://github.com/ansible/awx-operator/blob/8391ed3501ff326647485b7272e537942da0dd68/docs/user-guide/database-configuration.md?plain=1#L7

https://tecadmin.net/postgresql-allow-remote-connections/

https://computingforgeeks.com/install-postgresql-13-on-centos-rhel/

https://github.com/ansible/awx-operator/issues/1190
