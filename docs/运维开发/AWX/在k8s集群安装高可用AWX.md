---
tags:
  - AWX
  - Kubernetes
  - Ansible
---
# 在k8s集群安装高可用AWX

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 需要下载并导入的容器镜像

```
gcr.io/kubebuilder/kube-rbac-proxy:v0.15.0
quay.io/ansible/awx-operator:2.11.0
docker.io/library/redis:7
quay.io/ansible/awx:23.7.0
quay.io/ansible/awx-ee:23.7.0
quay.io/centos/centos:stream9
```

## 安装awx-operator

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

生成yaml文件：

```bash
kubectl apply -k . -o yaml --dry-run=client > awx-operator.yaml
```

如果需要离线部署，需要把`awx-operator.yaml`中`imagePullPolicy: Always`修改为`imagePullPolicy: IfNotPresent`，
将yaml文件应用：

```bash
kubectl create namespace awx
kubectl -n awx apply -f awx-operator.yaml
```

## 配置PostgreSQL数据库用户
AWX存储数据需要一套PostgreSQL-13数据库，数据库需要新建用户awx和数据库awx：

```
# psql -h postgresql-13 -U postgres
Password for user postgres:
psql (13.11, server 13.0 (Debian 13.0-1.pgdg100+1))
Type "help" for help.

postgres=# CREATE USER awx WITH ENCRYPTED PASSWORD '********';
CREATE ROLE
postgres=# CREATE DATABASE awx OWNER awx;
CREATE DATABASE
postgres=# exit
```

## 安装AWX并配置其使用外部数据库

定义AWX资源，新建`awx.yaml`：

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
  # postgres_storage_class: awx-postgres-volume
  # postgres_storage_requirements:
  #   requests:
  #     storage: 20Gi
  # projects_persistence: true
  # projects_existing_claim: awx-projects-claim
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
  password: ********
  sslmode: prefer
  type: unmanaged
type: Opaque
```
将两个yaml文件应用：
```bash
kubectl -n awx apply -f awx-postgres-configuration.yaml
kubectl -n awx apply -f awx.yaml
```
观察部署进度：
```bash
kubectl -n awx logs -f deployments/awx-operator-controller-manager
```
获取默认 admin 密码：
```
kubectl -n awx get secret awx-admin-password -o jsonpath="{.data.password}" | base64 --decode ; echo
```
## 参考链接

<https://github.com/ansible/awx-operator/blob/devel/docs/installation/basic-install.md>

<https://elatov.github.io/2022/03/deploying-awx-in-k8s-with-awx-operator/>

<https://github.com/ansible/awx-operator/blob/8391ed3501ff326647485b7272e537942da0dd68/docs/user-guide/database-configuration.md?plain=1#L7>

<https://tecadmin.net/postgresql-allow-remote-connections/>

<https://computingforgeeks.com/install-postgresql-13-on-centos-rhel/>

<https://github.com/ansible/awx-operator/issues/1190>

---

## 原文（English）

```
---
tags:
  - AWX
  - Kubernetes
  - Ansible
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 需要下载并导入的容器镜像

```
gcr.io/kubebuilder/kube-rbac-proxy:v0.15.0
quay.io/Ansible/AWX-operator:2.11.0
docker.io/library/Redis:7
quay.io/Ansible/AWX:23.7.0
quay.io/Ansible/AWX-ee:23.7.0
quay.io/CentOS/CentOS:stream9
```

## 安装awx-operator

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
namespace: AWX
```

生成yaml文件：

```bash
kubectl apply -k . -o yaml --dry-run=client > awx-operator.yaml
```

如果需要离线部署，需要把`awx-operator.yaml`中`imagePullPolicy: Always`修改为`imagePullPolicy: IfNotPresent`，
将yaml文件应用：

```bash
kubectl create namespace AWX
kubectl -n AWX apply -f awx-operator.yaml
```

## 配置PostgreSQL数据库用户
AWX存储数据需要一套PostgreSQL-13数据库，数据库需要新建用户awx和数据库awx：

```
# psql -h postgresql-13 -U postgres
Password for user postgres:
psql (13.11, server 13.0 (Debian 13.0-1.pgdg100+1))
Type "help" for help.

postgres=# CREATE USER AWX WITH ENCRYPTED PASSWORD '********';
CREATE ROLE
postgres=# CREATE DATABASE AWX OWNER AWX;
CREATE DATABASE
postgres=# exit
```

## 安装AWX并配置其使用外部数据库

定义AWX资源，新建`awx.yaml`：

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: AWX
  namespace: AWX
spec:
  ingress_type: ingress
  ingress_path: /
  ingress_hosts:
  - hostname: AWX.y.bocsys.cn
  # postgres_storage_class: awx-postgres-volume
  # postgres_storage_requirements:
  #   requests:
  #     storage: 20Gi
  # projects_persistence: true
  # projects_existing_claim: awx-projects-claim
  ee_images:
  - name: AWX-ee
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
          app.kubernetes.io/name: "AWX-task"
  web_topology_spread_constraints: |
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: "AWX-web"
  postgres_configuration_secret: AWX-postgres-configuration
```

新建数据库配置`awx-postgres-configuration.yaml`：

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: AWX-postgres-configuration
  namespace: AWX
stringData:
  host: PostgreSQL-13
  port: "5432"
  database: AWX
  username: AWX
  password: ********
  sslmode: prefer
  type: unmanaged
type: Opaque
```
将两个yaml文件应用：
```bash
kubectl -n AWX apply -f awx-postgres-configuration.yaml
kubectl -n AWX apply -f awx.yaml
```
观察部署进度：
```bash
kubectl -n AWX logs -f deployments/awx-operator-controller-manager
```
获取默认 admin 密码：
```
kubectl -n AWX get secret awx-admin-password -o jsonpath="{.data.password}" | base64 --decode ; echo
```
## 参考链接

<https://github.com/ansible/awx-operator/blob/devel/docs/installation/basic-install.md>

<https://elatov.github.io/2022/03/deploying-awx-in-k8s-with-awx-operator/>

<https://github.com/ansible/awx-operator/blob/8391ed3501ff326647485b7272e537942da0dd68/docs/user-guide/database-configuration.md?plain=1#L7>

<https://tecadmin.net/postgresql-allow-remote-connections/>

<https://computingforgeeks.com/install-postgresql-13-on-centos-rhel/>

<https://github.com/ansible/awx-operator/issues/1190>
```
