---
tags:
  - Kubernetes
  - k8s
---
# k3s安装

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 安装介质下载
1. 下载容器镜像：<https://github.com/k3s-io/k3s/releases>
2. 下载k3s二进制文件：<https://github.com/k3s-io/k3s/releases>
3. 下载安装脚本：<https://get.k3s.io/>
## 安装
```bash
cp k3s /usr/local/bin
chmod +x /usr/local/bin/k3s
mkdir -p /var/lib/rancher/k3s/agent/images/
cp k3s-airgap-images-amd64.tar.zst /var/lib/rancher/k3s/agent/images/
INSTALL_K3S_SKIP_DOWNLOAD=true ./install.sh
```
## 参考文献
<https://docs.k3s.io/installation/airgap>