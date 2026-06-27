---
tags:
  - AWX
  - Kubernetes
  - Ansible
---
# Install AWX on k8s with awx-operator

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 在 k8s 上使用 awx-operator 安装 AWX

```
[root@k8s-1 ~]# cat kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases

  - github.com/ansible/awx-operator/config/default?ref=2.5.0

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.5.0

# Specify a custom namespace in which to install AWX
namespace: awx
[root@k8s-1 ~]# kubectl apply -k .
namespace/awx created
customresourcedefinition.apiextensions.k8s.io/awxbackups.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxrestores.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxs.awx.ansible.com created
serviceaccount/awx-operator-controller-manager created
role.rbac.authorization.k8s.io/awx-operator-awx-manager-role created
role.rbac.authorization.k8s.io/awx-operator-leader-election-role created
clusterrole.rbac.authorization.k8s.io/awx-operator-metrics-reader created
clusterrole.rbac.authorization.k8s.io/awx-operator-proxy-role created
rolebinding.rbac.authorization.k8s.io/awx-operator-awx-manager-rolebinding created
rolebinding.rbac.authorization.k8s.io/awx-operator-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/awx-operator-proxy-rolebinding created
configmap/awx-operator-awx-manager-config created
service/awx-operator-controller-manager-metrics-service created
deployment.apps/awx-operator-controller-manager created
[root@k8s-1 ~]# kubectl get pods -n awx
NAME                                               READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-66c5b94884-mvbbd   2/2     Running   0          112s
```

```
[root@k8s-1 ~]# cat awx-demo.yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
  namespace: awx
spec:
  service_type: nodeport
  nodeport_port: 30001
  web_replicas: 6
  task_replicas: 6
  task_topology_spread_constraints: |
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: "awx-demo-task"
  web_topology_spread_constraints: |
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: "awx-demo-web"
[root@k8s-1 ~]# cat kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  - github.com/ansible/awx-operator/config/default?ref=2.5.0
  - awx-demo.yaml

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.5.0

# Specify a custom namespace in which to install AWX
namespace: awx
[root@k8s-1 ~]# kubectl apply -k .
```

部署日志可以通过以下命令查看：

```
kubectl -n awx logs awx-operator-controller-manager-66c5b94884-mvbbd -f
```

在 `awx-demo.yaml` 中，我指定了运行 6 个 task 和 6 个 web 容器，并指定 Pod 应在各主机上均匀调度。NodePort 为 30001。admin 密码可以通过以下方式获取：

```
[root@k8s-1 ~]# kubectl -n awx get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode ; echo
bdZ42ptoFtNTcNcPQUFra7EckP4jZc08
```

可以通过以下方式修改 admin 密码：

```
[root@k8s-1 ~]# kubectl -n awx describe pod/awx-demo-web-549bfcfbc8-44qqj
[root@k8s-1 ~]# kubectl -n awx exec -it pod/awx-demo-web-549bfcfbc8-44qqj -c awx-demo-web -- /bin/bash
bash-5.1$ awx-manage createsuperuser --username=admin --email=admin@example.com --noinput
CommandError: Error: That username is already taken.
bash-5.1$ awx-manage update_password --username=admin --password=changeme
Password updated
```

# 参考链接

<https://github.com/ansible/awx-operator/blob/devel/docs/installation/basic-install.md>

---

## 原文（English）

```
---
tags:
  - AWX
  - Kubernetes
  - Ansible
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Install AWX on k8s with awx-operator

```
[root@k8s-1 ~]# cat kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases

  - github.com/ansible/awx-operator/config/default?ref=2.5.0

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.5.0

# Specify a custom namespace in which to install AWX
namespace: awx
[root@k8s-1 ~]# kubectl apply -k .
namespace/awx created
customresourcedefinition.apiextensions.k8s.io/awxbackups.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxrestores.awx.ansible.com created
customresourcedefinition.apiextensions.k8s.io/awxs.awx.ansible.com created
serviceaccount/awx-operator-controller-manager created
role.rbac.authorization.k8s.io/awx-operator-awx-manager-role created
role.rbac.authorization.k8s.io/awx-operator-leader-election-role created
clusterrole.rbac.authorization.k8s.io/awx-operator-metrics-reader created
clusterrole.rbac.authorization.k8s.io/awx-operator-proxy-role created
rolebinding.rbac.authorization.k8s.io/awx-operator-awx-manager-rolebinding created
rolebinding.rbac.authorization.k8s.io/awx-operator-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/awx-operator-proxy-rolebinding created
configmap/awx-operator-awx-manager-config created
service/awx-operator-controller-manager-metrics-service created
deployment.apps/awx-operator-controller-manager created
[root@k8s-1 ~]# kubectl get pods -n awx
NAME                                               READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-66c5b94884-mvbbd   2/2     Running   0          112s
```

```
[root@k8s-1 ~]# cat awx-demo.yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
  namespace: awx
spec:
  service_type: nodeport
  nodeport_port: 30001
  web_replicas: 6
  task_replicas: 6
  task_topology_spread_constraints: |
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: "awx-demo-task"
  web_topology_spread_constraints: |
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: "awx-demo-web"
[root@k8s-1 ~]# cat kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  - github.com/ansible/awx-operator/config/default?ref=2.5.0
  - awx-demo.yaml

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.5.0

# Specify a custom namespace in which to install AWX
namespace: awx
[root@k8s-1 ~]# kubectl apply -k .
```

deployment logs can be seen by:

```
kubectl -n awx logs awx-operator-controller-manager-66c5b94884-mvbbd -f
```

In `awx-demo.yaml` I specified to run 6 task and 6 web containers and also specified that pods should be scheduled evenly on hosts. The node port is 30001. Admin password can be obtained by:

```
[root@k8s-1 ~]# kubectl -n awx get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode ; echo
bdZ42ptoFtNTcNcPQUFra7EckP4jZc08
```

you may change the admin password by:

```
[root@k8s-1 ~]# kubectl -n awx describe pod/awx-demo-web-549bfcfbc8-44qqj
[root@k8s-1 ~]# kubectl -n awx exec -it pod/awx-demo-web-549bfcfbc8-44qqj -c awx-demo-web -- /bin/bash
bash-5.1$ awx-manage createsuperuser --username=admin --email=admin@example.com --noinput
CommandError: Error: That username is already taken.
bash-5.1$ awx-manage update_password --username=admin --password=changeme
Password updated
```

# References

<https://github.com/ansible/awx-operator/blob/devel/docs/installation/basic-install.md>
```
