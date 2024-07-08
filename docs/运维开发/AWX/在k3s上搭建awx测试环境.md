---
tags:
  - Kubernetes
  - K3S
  - AWX
---

# 在 k3s 上安装 awx 测试环境

## 安装 k3s

一键安装 k3s ：

```bash
curl -sfL https://get.k3s.io | sh -
```

## 安装 AWX Operator

创建 `kustomization.yaml` ：

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  - github.com/ansible/awx-operator/config/default?ref=2.19.1

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.19.1

# Specify a custom namespace in which to install AWX
namespace: awx
```

生成 yaml 文件 `awx-operator.yaml` ：

```bash
kubectl apply -k . -o yaml --dry-run=client > awx-operator.yaml
```

将 yaml 文件应用：

```bash
kubectl create namespace awx
kubectl -n awx apply -f awx-operator.yaml
```

## 使用 AWX Operator 安装 AWX

创建 PostgresSQL 配置 `awx-postgres-configuration.yaml` ：

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-postgres-configuration
  namespace: awx
stringData:
  host: awx-postgres-15
  port: "5432"
  database: awx
  username: awx
  password: awx
  sslmode: prefer
  type: managed
type: Opaque
```

应用配置文件：

```bash
kubectl apply -f awx-postgres-configuration.yaml
```

创建 AWX 配置 `awx.yaml` ：

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: nodeport
```

部署 AWX ：

```bash
kubectl apply -f awx.yaml
```

查看安装进度：

```bash
kubectl -n awx logs -f deployments/awx-operator-controller-manager -c awx-manager
```

获取默认 admin 密码：

```bash
kubectl -n awx get secret awx-admin-password -o jsonpath="{.data.password}" | base64 --decode;echo
```
