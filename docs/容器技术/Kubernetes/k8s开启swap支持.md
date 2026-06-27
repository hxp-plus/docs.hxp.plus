---
tags:
  - Kubernetes
  - k8s
  - swap
---

# k8s 开启 swap 支持

!!! warning "文档时效性说明"
    本文档基于写作时的技术栈编写，下方的版本号、API 参数、镜像 tag、第三方项目活跃度可能已过时。请以官方最新文档为准。

    **已知过时点**：

    - `featureGates.NodeSwap` 在 k8s 1.28+ 已 GA，1.36+ 配置会被 kubelet 拒绝
    - `swapBehavior: UnlimitedSwap` 在 k8s 1.30+ 默认改为 LimitedSwap（更安全）

## 隔离并驱逐所有容器

```bash
kubectl cordon awx-k8s-01
kubectl drain awx-k8s-01 --ignore-daemonsets --delete-emptydir-data
```

## 修改 kubelet 配置

修改 `/var/lib/kubelet/config.yaml` ：

```yaml
memorySwap: {}
```

修改为：

```yaml
failSwapOn: false
featureGates:
  NodeSwap: true
memorySwap:
  swapBehavior: UnlimitedSwap
```

## 重启 kubelet

```bash
systemctl restart kubelet
systemctl status kubelet
```
