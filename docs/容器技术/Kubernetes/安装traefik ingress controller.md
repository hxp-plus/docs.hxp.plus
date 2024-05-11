---
tags:
  - Kubernetes
  - traefik
---

# 安装 traefik ingress controller

## 准备工作

### 介质下载

需要使用以下命令下载 traefik 的 helm chart：

```
helm repo add traefik https://traefik.github.io/charts
helm pull traefik/traefik
```

同时需要下载此 helm chart 所需的容器镜像，镜像名称用以下命令查看：

```
helm install --dry-run traefik traefik-27.0.2.tgz | grep image:
```

如果需要测试 traefik 部署，还需要下载容器镜像`docker.io/traefik/whoami:v1.10`，并从 traefik 官网的 [QuickStart](https://doc.traefik.io/traefik/getting-started/quick-start-with-kubernetes/) 章节下载 yaml 文件`03-whoami.yml`、`03-whoami-services.yml`和`04-whoami-ingress.yml`。

## 创建并修改 values

创建`values.yaml`：

```
helm show values traefik-27.0.2.tgz > values.yaml
```

如果使用私有镜像仓库，需要修改`image`和`imagePullSecrets`。

## 部署 helm chart

创建 namespace 并部署：

```
kubectl create ns traefik
helm install --namespace traefik traefik traefik-27.0.2.tgz --values values.yaml
```

将容器部署修改为 3 个：

```
kubectl -n traefik scale deployment traefik --replicas 3
```

## 配置负载均衡器

首选查询 traefik 的 NodePort 端口：

```
kubectl get svc -n traefik
```

```
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
traefik   LoadBalancer   10.96.103.221   <pending>     80:30795/TCP,443:32752/TCP   5d1h
```

这里 http 端口 30795，https 端口 32752，配置负载均衡器的 80 端口转发到所有 k8s 节点 30795 端口，443 端口转发到所有 k8s 节点 32752 端口，负载模式为 TCP 轮询。如果使用的是在 k8s master 节点使用 static pod 方式安装 HAProxy 和 Keepalived 的方式，则需要修改 HAProxy 配置：

```cfg
frontend web
    bind *:80
    mode tcp
    option tcplog
    default_backend webbackend

backend webbackend
    mode tcp
    balance     roundrobin
        server k8s01 192.168.100.11:30795 check
        server k8s02 192.168.100.12:30795 check
        server k8s03 192.168.100.13:30795 check

frontend websecure
    bind *:443
    mode tcp
    option tcplog
    default_backend websecurebackend

backend websecurebackend
    mode tcp
    balance     roundrobin
        server k8s01 192.168.100.11:32752 check
        server k8s02 192.168.100.12:32752 check
        server k8s03 192.168.100.13:32752 check
```

static pod 重启必须使用 crictl 命令，首先找到 static pod 的容器 ID：

```
crictl ps | grep haproxy
```

```
a0b4e29a3ba18 6600fae04efde 3 minutes ago Running haproxy 2 5e3faac3ce66d haproxy-k8s01
```

然后停止容器：

```
crictl stop a0b4e29a3ba18
```

在停止容器后 kubelet 会自动将其重新拉起。

## 创建 whoami 容器进行验证

在 default 命名空间，创建 whoami 容器、service 和 ingress：

```
kubectl apply -f 03-whoami.yml -f 03-whoami-services.yml -f 04-whoami-ingress.yml
```

使用 curl 命令检查：

```
curl http://[负载均衡器VIP]/whoami/
```

```
Hostname: whoami-78994d7bf9-x7lzr
IP: 127.0.0.1
IP: ::1
IP: 172.18.209.24
IP: fe80::209c:b5ff:fefa:ca79
RemoteAddr: 172.18.209.20:41776
GET /whoami/ HTTP/1.1
Host: 192.168.100.10
User-Agent: curl/7.71.1
Accept: */*
Accept-Encoding: gzip
X-Forwarded-For: 192.168.100.11
X-Forwarded-Host: 192.168.100.10
X-Forwarded-Port: 80
X-Forwarded-Proto: http
X-Forwarded-Server: traefik-deployment-65547f8865-27d6x
X-Real-Ip: 192.168.100.11
```

可以看到 whoami 容器收到的请求里带着文根 whoami，之后测试 middleware 去除文根功能，修改`04-whoami-ingress.yml`如下：

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami-ingress
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
    traefik.ingress.kubernetes.io/router.middlewares: default-strip-prefix@kubernetescrd
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: whoami
                port:
                  name: web
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: strip-prefix
  # No namespace defined
spec:
  stripPrefixRegex:
    regex:
      - ^/[^/]+
```

修改完成后应用 yaml 配置：

```
kubectl apply -f 04-whoami-ingress.yml
```

用 curl 命令测试：

```
curl http://[负载均衡器VIP]/whoami/
```

```
Hostname: whoami-8c9864b56-dms8j
IP: 127.0.0.1
IP: ::1
IP: 172.18.122.2
IP: fe80::e840:22ff:fe60:51e7
RemoteAddr: 172.18.209.2:41866
GET / HTTP/1.1
Host: 192.168.100.10
User-Agent: curl/7.61.1
Accept: */*
Accept-Encoding: gzip
X-Forwarded-For: 172.18.122.0
X-Forwarded-Host: 192.168.100.10
X-Forwarded-Port: 80
X-Forwarded-Prefix: /whoami
X-Forwarded-Proto: http
X-Forwarded-Server: traefik-858b7cfbcd-t4ltm
X-Real-Ip: 172.18.122.0
```

注意这里的`GET /whoami/ HTTP/1.1`变成了`GET / HTTP/1.1`，说明 middleware 生效。最后清理测试使用的资源：

```
kubectl delete -f 03-whoami.yml -f 03-whoami-services.yml -f 04-whoami-ingress.yml
```

## 参考链接

https://doc.traefik.io/traefik/getting-started/install-traefik/#use-the-helm-chart

https://github.com/traefik/traefik-helm-chart/blob/master/EXAMPLES.md
