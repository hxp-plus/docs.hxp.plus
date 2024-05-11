---
tags:
  - Kubernetes
  - metrics-server
---

# 安装 metrics-server

## 准备工作

### 介质下载

需要使用以下命令下载 metrics-server 的 helm chart：

```
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm pull metrics-server/metrics-server
```

同时需要下载此 helm chart 所需的容器镜像，镜像名称用以下命令查看：

```
helm install --dry-run metrics-server metrics-server-3.12.0.tgz | grep image:
```

## 使用 helm 安装 metrics-server

在其中一个节点创建 metrics-server 的 namespace 并安装：

```
kubectl create ns metrics-server
helm install --namespace metrics-server metrics-server metrics-server-3.11.0.tgz
```

创建之后，修改 deployments 配置：

```
kubectl -n metrics-server edit deployments.apps metrics-server
```

新增`- --kubelet-insecure-tls`配置，修改之后如下：

```
    spec:
      containers:
      - args:
        - --secure-port=10250
        - --cert-dir=/tmp
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
        image: registry.k8s.io/metrics-server/metrics-server:v0.6.4
```

修改之后轮询重启容器，并将容器修改为部署 3 个：

```
kubectl -n metrics-server rollout restart deployment metrics-server
kubectl -n metrics-server scale --replicas 3 deployment metrics-server
```

部署完成后检查资源状态：

```
kubectl get all -n metrics-server
```

```
NAME                                  READY   STATUS    RESTARTS   AGE
pod/metrics-server-55f78d9d6f-4r98q   1/1     Running   0          32s
pod/metrics-server-55f78d9d6f-68t2q   1/1     Running   0          32s
pod/metrics-server-55f78d9d6f-cktdd   1/1     Running   0          102s

NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/metrics-server   ClusterIP   10.108.4.192   <none>        443/TCP   8m2s

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/metrics-server   3/3     3            3           8m2s

NAME                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/metrics-server-55f78d9d6f   3         3         3       102s
replicaset.apps/metrics-server-596d577f98   0         0         0       2m24s
replicaset.apps/metrics-server-5b76987ff    0         0         0       8m2s
```

之后执行`kubectl top pods -A`和`kubectl top nodes`，观察有无报错。
