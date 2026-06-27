---
tags:
  - AWX
  - Kubernetes
  - Ansible
---
# RHEL8 k3s 与 AWX-23.9 安装

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 离线安装 k3s
### 需要下载的介质
k3s容器镜像：[k3s-airgap-images-amd64.tar.zst](https://github.com/k3s-io/k3s/releases/download/v1.29.3%2Bk3s1/k3s-airgap-images-amd64.tar.zst)
k3s安装脚本：[install.sh](https://get.k3s.io/)
k3s二进制程序：[k3s](https://github.com/k3s-io/k3s/releases/download/v1.29.3%2Bk3s1/k3s)
必要的RPM依赖：通过YUM源下载
所有涉及的容器镜像：通过`ctr -n k8s.io images export bind9:9.11.tar docker.io/internetsystemsconsortium/bind9:9.11 --platform linux/amd64`
命令下载
### 离线安装

k3s离线安装：

```
mkdir -p /var/lib/rancher/k3s/agent/images/
cp ./k3s-airgap-images-amd64.tar.zst /var/lib/rancher/k3s/agent/images/
cp k3s /usr/local/bin
chmod +x /usr/local/bin/k3s
chmod +x install.sh
INSTALL_K3S_SKIP_DOWNLOAD=true ./install.sh
```

## 安装 AWX Operator
导入容器镜像：

```
ctr -n=k8s.io image import "images/awx-operator:2.12.2.tar"
ctr -n=k8s.io image import "images/kube-rbac-proxy:v0.14.1.tar"
kubectl apply -f awx-operator.yaml
```
创建`kustomization.yaml`：
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases

  - github.com/ansible/awx-operator/config/default?ref=2.12.2

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.12.2

# Specify a custom namespace in which to install AWX
namespace: awx
```
生成yaml文件`awx-operator.yaml`（离线部署需要在外网机器执行）：

```bash
kubectl apply -k . -o yaml --dry-run=client > awx-operator.yaml
```

如果需要离线部署，需要把`awx-operator.yaml`中`imagePullPolicy: Always`修改为`imagePullPolicy: IfNotPresent`，  将yaml文件应用：

```bash
kubectl create namespace awx
kubectl -n awx apply -f awx-operator.yaml
```
## 使用 AWX Operator 安装 AWX

导入容器镜像：

```
ctr -n=k8s.io image import "images/postgres:13.tar" --platform linux/amd64
ctr -n=k8s.io image import "images/redis:7.tar" --platform linux/amd64
ctr -n=k8s.io image import "images/awx:23.9.0.tar" --platform linux/amd64
ctr -n=k8s.io image import "images/awx-ee:23.9.0.tar" --platform linux/amd64
ctr -n=k8s.io image import "images/centos:stream9.tar" --platform linux/amd64
```

创建PostgresSQL配置`awx-postgres-configuration.yaml`：

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-postgres-configuration
  namespace: awx
stringData:
  host: awx-postgres-13
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

创建AWX配置`awx.yaml`：
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

```
kubectl apply -f awx.yaml
```

查看安装进度：

```
kubectl -n awx logs -f deployments/awx-operator-controller-manager -c awx-manager
```

获取默认 admin 密码：

```
kubectl -n awx get secret awx-admin-password -o jsonpath="{.data.password}" | base64 --decode;echo
```
## 参考资料
<https://ansible.readthedocs.io/projects/awx-operator/en/latest/installation/basic-install.html>
<https://computingforgeeks.com/install-and-configure-ansible-awx-on-centos/#google_vignette>
<https://github.com/kurokobo/awx-on-k3s/tree/2.12.2?tab=readme-ov-file#prepare-required-files-to-deploy-awx>
