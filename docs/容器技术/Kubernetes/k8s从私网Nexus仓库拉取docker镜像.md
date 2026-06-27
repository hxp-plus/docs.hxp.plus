---
tags:
  - Kubernetes
  - k8s
---
# k8s从私网Nexus仓库拉取docker镜像

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## docker配置添加
在Nexus虚拟机`192.168.100.12`上，获取docker配置`~/.docker/config.json`如下：
```json
{
	"auths": {
		"192.168.100.12:8082": {
			"auth": "**********"
		},
		"192.168.100.12:8083": {
			"auth": "**********"
		}
	}
}
```
将此配置复制到kubernetes的control-plane节点的`/tmp/config.json`，加入凭证：
```bash
kubectl -n keycloak create secret generic nexus-regcred --from-file=.dockerconfigjson=/tmp/config.json --type=kubernetes.io/dockerconfigjson
```
## CA证书添加
在Nexus虚拟机`192.168.100.12`上，获取CA证书`/etc/docker/certs.d/192.168.100.12:8082/ca.crt`，将其复制到所有k8s节点的`/etc/pki/ca-trust/source/anchors/nexus.crt`，并在所有节点更新证书：
```bash
update-ca-trust
```
之后还需要重启containerd：
```bash
systemctl restart containerd.service
```
## 使用凭证拉取镜像
以下是一个实例，创建一个pod，使用刚刚配好的凭证拉取镜像，新建文件`test-pod.yaml`：
```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: keycloak
spec:
  containers:
  - name: keycloak
    image: 192.168.100.12:8082/keycloak/keycloak:24.0
  imagePullSecrets:
  - name: nexus-regcred
```
创建pod：
```bash
kubectl create -f test-pod.yaml
```
