---
tags:
  - Kubernetes
  - local-path-provisioner
---

# local-path-provisioner 安装

## 创建 kubernetes 相关资源

下载 yaml 文件并应用：

```bash
wget https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml
kubectl apply -f local-path-storage.yaml
```

## 创建 local-path-provisioner 目录

在所有节点，创建`/opt/local-path-provisioner`目录（建议对此目录单独建立逻辑卷

## 将 local-path-provisioner 设置为默认 StorageClass

```bash
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## 测试并验证

创建 pvc 并测试，新建文件`test-pvc.yaml`：

```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-path
```

创建 pvc：

```
kubectl apply -f test-pvc.yaml
```

由于 VolumeBindingMode 设置成了 WaitForFirstConsumer，需要启动一个 pod 来使用 pvc，pv 才会被创建：

```bash
kubectl run -i --rm --tty busybox --overrides='
{
    "apiVersion": "v1",
    "spec": {
        "containers": [
            {
                "name": "busybox",
                "image": "docker.io/rancher/busybox:1.31.1",
                "args": [
                    "sh"
                ],
                "stdin": true,
                "stdinOnce": true,
                "tty": true,
                "volumeMounts": [
                    {
                        "mountPath": "/home/store",
                        "name": "store"
                    }
                ]
            }
        ],
        "volumes": [
            {
                "name": "store",
                "persistentVolumeClaim": {
                    "claimName": "test-pvc"
                }
            }
        ]
    }
}
'  --image=busybox --restart=Never -- /bin/sh
```

检查 pvc 为 Bound 状态：

```
kubectl get pvc
```

```
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE
test-pvc   Bound    pvc-9c92208e-cd5a-436a-a785-74b6dc00ae31   1Gi        RWX            csi-cephfs-sc   <unset>                 9m15s
```
