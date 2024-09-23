# k8s 开启 swap 支持

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
