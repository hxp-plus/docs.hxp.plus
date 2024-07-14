---
tags:
  - k3s
---

# k3s 删除 namespace 卡死在 Terminating 解决方法

## 问题现象

k3s 在删除 namespace 时，卡死，按 Ctrl-C 后发现 namespace 一直处于 Terminating 状态：

```
$ kubectl get ns
NAME              STATUS        AGE
kube-system       Active        33d
default           Active        33d
kube-public       Active        33d
kube-node-lease   Active        33d
awx               Terminating   5d18h
```

## 解决方法

用以下命令清理：

```
NS=`kubectl get ns |grep Terminating | awk 'NR==1 {print $1}'` && kubectl get namespace "$NS" -o json   | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/"   | kubectl replace --raw /api/v1/namespaces/$NS/finalize -f -
```

## 参考文献

https://stackoverflow.com/questions/52369247/namespace-stucked-as-terminating-how-i-removed-it
