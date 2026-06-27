---
tags:
  - Kubernetes
  - k8s
---

# k8s创建service account并授权、导入kubelet


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 为一个namespace创建Service Account

创建namespace：

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: test
```

最好为namespace设置本地存储限制，防止其把某个k8s节点的/var目录写满：

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: default-resource-quotas
  namespace: test
spec:
  hard:
    # limits.cpu: "2"
    # limits.memory: 8Gi
    limits.ephemeral-storage: 2Gi
    # requests.cpu: "1"
    # requests.memory: 4Gi
    requests.ephemeral-storage: 1Gi
```
##  创建Role、RoleBinding和Service Account
Role：
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: test
  namespace: test
rules:
- apiGroups:
  - ""
  resources:
  - 'pods'
  verbs:
  - '*'
- apiGroups:
  - ""
  resources:
  - persistentvolumeclaims
  verbs:
  - get
```
RoleBinding和ServiceAccount：
```bash
kubectl -n test create serviceaccount test
kubectl -n test create rolebinding test --namespace=test --serviceaccount test:test --role=test
```

## 验证Service Account权限

```bash
# kubectl auth can-i get pvc --as=system:serviceaccount:test:test -n test
yes
# kubectl auth can-i get pvc --as=system:serviceaccount:test:test
no
```

## 为Service Account创建永久token

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: test-secret
  namespace: test
  annotations:
    kubernetes.io/service-account.name: test
type: kubernetes.io/service-account-token
```

## 创建kubelet配置

```yaml
export SECRET_NAME_SA=test-secret
export TOKEN_SA=$(kubectl get secret test-secret -n test -o jsonpath="{.data.token}"|base64 -d)
kubectl config view --raw --minify > kubeconfig.txt
kubectl config unset users --kubeconfig=kubeconfig.txt
kubectl config set-credentials ${SECRET_NAME_SA} --kubeconfig=kubeconfig.txt --token=${TOKEN_SA}
kubectl config set-context --current --kubeconfig=kubeconfig.txt --user=${SECRET_NAME_SA}
kubectl config set-context --current --kubeconfig=kubeconfig.txt --namespace test
```

## 使用kubeconfig.txt配置

1. 可以通过设置环境变量： `export KUBECONFIG=/home/test/kubeconfig.txt`
2. 也可以通过在命令里指定：`kubectl --kubeconfig=kubeconfig.txt get pods`
## 参考链接

<https://pauldally.medium.com/avoid-running-out-of-ephemeral-storage-space-on-your-kubernetes-worker-nodes-eb94227347d0>
<https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/>
<https://dev.to/stack-labs/debugging-kubernetes-execute-kubectl-commands-with-a-service-account-1k44>