---
tags:
  - Kubernetes
  - k8s
---

# Tuning Kubernetes cluster to react faster on node failure


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

在 Kubernetes 的默认设置中，只有节点宕机 5 分钟后，Pod 才会被驱逐。在某些情况下，5 分钟太长，因此需要进行调优。

## 需要调优的参数

在 **kube-controller-manager** 上：

1. \--node-monitor-grace-period（默认：5s）：在 cloud-node-lifecycle-controller 中同步 NodeStatus 的周期。
2. \--node-monitor-period（默认：40s）：允许运行中的节点在标记为不健康之前无响应的时间。它必须是 kubelet 的 nodeStatusUpdateFrequency 的 N 倍，其中 N 表示允许 kubelet 发布节点状态的重试次数。

在 **kube-apiserver** 上：

1. \--default-not-ready-toleration-seconds（默认：300）：表示为默认添加到每个尚未具有此类容忍度的 Pod 的 notReady:NoExecute 容忍度的 tolerationSeconds。
2. \--default-unreachable-toleration-seconds（默认：300）：表示为默认添加到每个尚未具有此类容忍度的 Pod 的 unreachable:NoExecute 容忍度的 tolerationSeconds。

在 **kubelet** 上：

1. \--node-status-update-frequency（默认：10s）：Kubelet 定期向 apiserver 更新其状态的时间间隔。

## 调优 kubelet 服务

编辑所有控制平面节点上的 `/var/lib/kubelet/kubeadm-flags.env`，将 `--node-status-update-frequency=1s` 添加到 `KUBELET_KUBEADM_ARGS`：

```
KUBELET_KUBEADM_ARGS="--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.9 --node-status-update-frequency=1s"
```

## 调优 kube-apiserver

编辑所有控制平面节点上的 `/etc/kubernetes/manifests/kube-apiserver.yaml`：

```
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=192.168.11.52
    ...
    - --default-unreachable-toleration-seconds=10 <= 添加此行
    - --default-not-ready-toleration-seconds=10 <= 添加此行
    ...
```

## 调优 kube-controller-manager

编辑所有控制平面节点上的 `/etc/kubernetes/manifests/kube-controller-manager.yaml`：

```
spec:
  containers:
  - command:
    - kube-controller-manager
    - --allocate-node-cidrs=true
    ...
    - --node-monitor-grace-period=10s <= 添加此行
    - --node-monitor-period=5s <= 添加此行
    ...
```

## 重启 kubelet 服务

逐个重启所有节点上的 kubelet 服务：

```
systemctl restart kubelet
```

每次启动后，检查集群状态：

```
kubectl -n kube-system get pods
```

## 参考链接

<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/kubernetes-reliability.md>

<https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/>

<https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/>

<https://stackoverflow.com/questions/52372069/changing-the-default-behavior-of-kubernetes>

---

## 原文（English）

---
tags:
  - Kubernetes
  - k8s
---

# Tuning Kubernetes cluster to react faster on node failure


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

In the default settings of Kubernetes, pods will be evicted from a node only if the node is down for 5 minutes. For some circumstances, 5 minutes is too long and so far tuning is required.

## Parameters to be tuned

on **kube-controller-manager:** 

1. \--node-monitor-grace-period (Default: 5s): The period for syncing NodeStatus in cloud-node-lifecycle-controller.
2. \--node-monitor-period duration (Default: 40s): Amount of time which we allow running Node to be unresponsive before marking it unhealthy. It must be N times more than kubelet's nodeStatusUpdateFrequency, where N means the number of retries allowed for kubelet to post node status.

on **kube-apiserver:**

1. \--default-not-ready-toleration-seconds (Default: 300): Indicates the tolerationSeconds of the toleration for notReady:NoExecute that is added by default to every pod that does not already have such a toleration.
2. \--default-unreachable-toleration-seconds (Default: 300): Indicates the tolerationSeconds of the toleration for unreachable:NoExecute that is added by default to every pod that does not already have such a toleration.

on **kubelet**:

1. \--node-status-update-frequency (Default: 10s): The time interval of Kubelet updates its status to apiserver periodically.

## Tuning kubelet service

Edit `/var/lib/kubelet/kubeadm-flags.env` add `--node-status-update-frequency=1s` to  `KUBELET_KUBEADM_ARGS` on all control-plane nodes :

```
KUBELET_KUBEADM_ARGS="--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.9 --node-status-update-frequency=1s"
```

## Tuning kube-apiserver

Edit `/etc/kubernetes/manifests/kube-apiserver.yaml` on all control-plane nodes : 

```
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=192.168.11.52
    ...
    - --default-unreachable-toleration-seconds=10 <= Add this line
    - --default-not-ready-toleration-seconds=10 <= Add this line
    ...
```

## Tuning kube-controller-manager

Edit `/etc/kubernetes/manifests/kube-controller-manager.yaml` on all control-plane nodes : 

```
spec:
  containers:
  - command:
    - kube-controller-manager
    - --allocate-node-cidrs=true
    ...
    - --node-monitor-grace-period=10s <= Add this line
    - --node-monitor-period=5s <= Add this line
    ...
```

## Restart kubelet service

Restart all kubelet services on all nodes one by one:

```
systemctl restart kubelet
```

After each start, check the cluster status by:

```
kubectl -n kube-system get pods
```

## References

<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/kubernetes-reliability.md>

<https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/>

<https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/>

<https://stackoverflow.com/questions/52372069/changing-the-default-behavior-of-kubernetes>
