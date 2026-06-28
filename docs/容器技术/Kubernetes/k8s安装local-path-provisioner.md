---
tags:
  - Kubernetes
  - k8s
---

# k8s 安装 local-path-provisioner

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：kubectl get pvc

下载yaml文件：
```bash
wget https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml
```
下载以下两个镜像，并将yaml的image修改：
```
docker.io/rancher/local-path-provisioner:v0.0.26
docker.io/rancher/busybox:1.31.1
```
应用yaml文件：
```bash
kubectl apply -f local-path-storage.yaml
```
在所有节点，创建`/opt/local-path-provisioner`目录（建议对此目录单独建立逻辑卷），之后设置其为默认：
```bash
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
创建pvc并测试，新建文件`test-pvc.yaml`：

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

创建pvc：

```
kubectl apply -f test-pvc.yaml
```

由于VolumeBindingMode设置成了WaitForFirstConsumer，需要启动一个pod：
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
检查：

```
# kubectl get pvc

NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE
test-pvc   Bound    pvc-9c92208e-cd5a-436a-a785-74b6dc00ae31   1Gi        RWX            csi-cephfs-sc   <unset>                 9m15s
```
