---
tags:
  - Kubernetes
  - PostgreSQL
  - AWX
---

## K8S 故障后 AWX 和 stolon 切换时间过长问题解决方案

在 k8s 上安装完成 AWX 后，实际测试发现在节点故障时切换时间过长，这是因为 k8s 默认设置里，当一个 k8s 节点 unreachable 或者 not-ready 时，容器会容忍这个节点 5 分钟才会自动漂移。可以修改为更短的时间，例如 10 秒。需要修改`awx.yaml`的`tolerations`。同时，为了防止容器被调度到相同的节点上，需要修改`task_topology_spread_constraints`和`web_topology_spread_constraints`：

```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
spec:
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
  tolerations: |
    - key: "node.kubernetes.io/not-ready"
      operator: "Exists"
      effect: "NoExecute"
      tolerationSeconds: 10
    - key: "node.kubernetes.io/unreachable"
      operator: "Exists"
      effect: "NoExecute"
      tolerationSeconds: 10
```

修改之后重新 apply 下这个 yaml 文件生效。同时，stolon 也有同样的问题，需要修改`stolon-keeper.yaml`、`stolon-proxy.yaml` 和`stolon-sentinel.yaml`，以`stolon-proxy.yaml`为例：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stolon-proxy
spec:
  selector:
    matchLabels:
      component: stolon-proxy
      ...
  template:
    ...
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              component: stolon-proxy
      tolerations:
        - key: "node.kubernetes.io/not-ready"
          operator: "Exists"
          effect: "NoExecute"
          tolerationSeconds: 10
        - key: "node.kubernetes.io/unreachable"
          operator: "Exists"
          effect: "NoExecute"
          tolerationSeconds: 10
```

## 参考链接

https://github.com/ansible/awx-operator/blob/0d1fa239a56c55202167cb833a72f495928442fc/docs/user-guide/advanced-configuration/assigning-awx-pods-to-specific-nodes.md?plain=1#L20
