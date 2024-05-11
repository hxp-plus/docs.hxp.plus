---
tags:
  - 思源笔记
  - Keycloak
  - Kubernetes
---

# 思源笔记 k8s 部署

## 前置条件

- 一个能运作的 k8s 集群
- 相关容器镜像上传到镜像仓库
- k8s 配置好私有镜像仓库凭证
- k8s 上至少有一个 default storage class

## 创建 pvc 来提供持久化存储

首先创建 pvc 来为思源笔记提供持久化存储：

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: siyuan-pandoc-monitor
  namespace: siyuan-pandoc
  labels:
    app: siyuan-pandoc-monitor
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
```

## 创建 deployment 来部署 pod

然后使用此 yaml 部署 deployment：

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: siyuan-pandoc-monitor
  name: siyuan-pandoc-monitor
  namespace: siyuan-pandoc
spec:
  replicas: 1
  selector:
    matchLabels:
      app: siyuan-pandoc-monitor
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: siyuan-pandoc-monitor
    spec:
      containers:
        - args:
            - -c
            - /opt/siyuan/kernel --workspace=/siyuan/workspace
          command:
            - /bin/sh
          env:
            - name: SIYUAN_ACCESS_AUTH_CODE_BYPASS
              value: "true"
          image: 192.168.100.12:8082/siyuan-pandoc:v3.0.9
          imagePullPolicy: IfNotPresent
          name: siyuan-pandoc-monitor
          ports:
            - containerPort: 6806
              name: web
              protocol: TCP
          volumeMounts:
            - mountPath: /siyuan/workspace
              name: siyuan-pandoc-monitor
      imagePullSecrets:
        - name: nexus-regcred
      securityContext:
        fsGroup: 1000
      tolerations:
        - effect: NoExecute
          key: node.kubernetes.io/not-ready
          operator: Exists
          tolerationSeconds: 10
        - effect: NoExecute
          key: node.kubernetes.io/unreachable
          operator: Exists
          tolerationSeconds: 10
      volumes:
        - name: siyuan-pandoc-monitor
          persistentVolumeClaim:
            claimName: siyuan-pandoc-monitor
```

特别需要注意，思源笔记只能单 pod 运行，第一个 pod 启动后，会给笔记的目录加锁，第二个 pod 启动的时候看到目录被加锁就会启动报错，因此只能部署 1 个 pod ，而且需要将 `strategy.type` 设置为 `Recreate` ，否则 rollout restart deployment 的时候，会先创建一个新的 pod ，新 pod 会永远 CrashLoopbackOff 。修改之后 rollout restart 时会先把 pod 杀掉然后启动新的 pod 。同时， k8s 默认设置下，如果节点宕机， pod 会忍耐节点 5 分钟才会迁移，这在单 pod 部署的情况下宕机会出现 5 分钟服务不可用，需要修改 tolerations 那里来将这个 5 分钟缩短为 10 秒。

## 创建 service 来暴露服务

最后需要将思源笔记服务暴露，创建 service ：

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: siyuan-pandoc-monitor
  namespace: siyuan-pandoc
  labels:
    app: siyuan-pandoc-monitor
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 6806
      name: web
  selector:
    app: siyuan-pandoc-monitor
```

如果思源笔记在集群访问就可以，可以将 `spec.type` 修改为 `ClusterIP` 。
