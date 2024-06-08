# AWX 新增容器组

## 需要下载的文件

1. containergroup-sa.yml : <https://docs.ansible.com/automation-controller/latest/html/administration/_downloads/7a0708e6c2113e9601bf252270fa6c50/containergroup-sa.yml>

## 创建 namespace 和 service account

containergroup-sa.yml 修改如下：

```
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: awx-service-account
  namespace: awx
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: role-awx-service-account
  namespace: awx
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods/attach"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: role-awx-service-account-binding
  namespace: awx
subjects:
- kind: ServiceAccount
  name: awx-service-account
  namespace: awx
roleRef:
  kind: Role
  name: role-awx-service-account
  apiGroup: rbac.authorization.k8s.io

```

应用资源：

```bash
kubectl create ns awx
kubectl apply -f containergroup-sa.yml
```

## 为 service account 创建 token

```bash
kubectl -n awx apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: awx-secret
  annotations:
    kubernetes.io/service-account.name: awx-service-account
type: kubernetes.io/service-account-token
EOF
```

## 获取 token 和证书

```bash
# 获取token
kubectl -n awx get secrets awx-secret -o jsonpath='{.data.token}'|base64 -d;echo
# 获取证书
kubectl -n awx get secrets awx-secret -o jsonpath='{.data.ca\.crt}'|base64 -d;echo
```

## 在 AWX 上配置凭证

点击 Resources -> Credentials ，新增凭证，类型 “OpenShift or Kubernetes API Bearer Token”，API endpoint 为 k8s 的 apiserver endpoint，在 k3s 中为 https://IP 地址:6443，token 和 CA 证书为刚刚获取的值，Verify SSL 选 false。

## 加入实例组

点击 Administration -> Instance Groups ，点击 Add -> Add container group，Credential 为之前配置的凭证，Cutson pod spec 中，serviceAccountName 和 namespace 按需修改为 awx-service-account 和 awx。

## 参考链接

https://docs.ansible.com/automation-controller/latest/html/administration/containers_instance_groups.html
