---
tags:
  - Kubernetes
  - k8s
---

# k8s临时启动挂载pvc的容器


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

使用 override 来创建容器：

```bash
kubectl run -i --rm --tty busybox --overrides='
{
    "apiVersion": "v1",
    "spec": {
        "containers": [
            {
                "name": "busybox",
                "image": "busybox:latest",
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
                "hostPath": {
                    "path": "/root",
                    "type": "Directory"
                }
            }
        ]
    }
}
'  --image=busybox --restart=Never -- /bin/sh
```
如果需要有容器内 UID 和 GID 需求：
```bash
kubectl -n test run -i --rm --tty test-pod --overrides='
{
    "apiVersion": "v1",
    "spec": {
        "containers": [
            {
                "name": "test-pod",
                "image": "quay.io/centos/centos:stream9",
                "securityContext": {
                    "runAsUser": 1000,
                    "runAsGroup": 1000
                },
                "args": [
                    "/bin/bash"
                ],
                "stdin": true,
                "stdinOnce": true,
                "tty": true,
                "volumeMounts": [
                    {
                        "mountPath": "/data",
                        "name": "data"
                    }
                ]
            }
        ],
        "volumes": [
            {
                "name": "data",
                "persistentVolumeClaim": {
                    "claimName": "test-pvc"
                }
            }
        ]
    }
}
' --image=quay.io/centos/centos:stream9 --restart=Never -- /bin/bash
```

---

## 原文（English）

---
tags:
  - Kubernetes
  - k8s
---

# k8s临时启动挂载pvc的容器


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

使用override来创建容器：

```bash
kubectl run -i --rm --tty busybox --overrides='
{
    "apiVersion": "v1",
    "spec": {
        "containers": [
            {
                "name": "busybox",
                "image": "busybox:latest",
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
                "hostPath": {
                    "path": "/root",
                    "type": "Directory"
                }
            }
        ]
    }
}
'  --image=busybox --restart=Never -- /bin/sh
```
如果需要有容器内UID和GID需求：
```bash
kubectl -n test run -i --rm --tty test-pod --overrides='
{
    "apiVersion": "v1",
    "spec": {
        "containers": [
            {
                "name": "test-pod",
                "image": "quay.io/centos/centos:stream9",
                "securityContext": {
                    "runAsUser": 1000,
                    "runAsGroup": 1000
                },
                "args": [
                    "/bin/bash"
                ],
                "stdin": true,
                "stdinOnce": true,
                "tty": true,
                "volumeMounts": [
                    {
                        "mountPath": "/data",
                        "name": "data"
                    }
                ]
            }
        ],
        "volumes": [
            {
                "name": "data",
                "persistentVolumeClaim": {
                    "claimName": "test-pvc"
                }
            }
        ]
    }
}
' --image=quay.io/centos/centos:stream9 --restart=Never -- /bin/bash
```
