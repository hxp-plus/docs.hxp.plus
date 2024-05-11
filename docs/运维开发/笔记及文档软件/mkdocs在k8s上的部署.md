---
tags:
  - mkdocs
  - Keycloak
  - Kubernetes
---

# mkdocs 在 k8s 上的部署

## 前置条件

- 一个能运作的 k8s 集群
- 相关容器镜像上传到镜像仓库
- k8s 配置好私有镜像仓库凭证

## 创建 configmap

使用 configmap 来存储本次部署需要的所有配置文件：

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: mkdocs
  namespace: mkdocs
data:
  build.sh: |
    set -e
    cd /
    git config --global credential.helper store
    echo 'http://4895664:Pass1234%21@22.122.61.128' >> ~/.git-credentials
    git clone http://22.122.61.128/mkdocs/system-ops.git
    cd /system-ops && git checkout mkdocs-system-ops-hxp && mkdocs build
    cp -r /system-ops/site/* /mkdocs/
  nginx.conf: |
    user nginx;
    worker_processes 1;
    error_log /var/log/nginx/error.log notice;
    pid /var/run/nginx.pid;

    events {
      worker_connections  1024;
    }

    http {
      include /etc/nginx/mime.types;
      default_type application/octet-stream;
      log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
      access_log /var/log/nginx/access.log  main;
      sendfile on;
      server {
        listen 80;
        server_name _;
        keepalive_timeout 70;
        location / {
          root /mkdocs;
          autoindex   on;
        }
      }
    }
```

configmap 中包含 nginx 的配置和构建文档使用的 build.sh 脚本。

## 使用 deployment 部署 pod

本次部署是部署一个 pod ，其在启动的时候运行 mkdocs 容器来从 GitLab 拉代码并编译，编译成功以后，运行 nginx 容器提供服务。如果编译失败，则 initContainer 不停重启。部署使用的 yaml 文件如下：

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mkdocs
  namespace: mkdocs
  labels:
    app: mkdocs
spec:
  selector:
    matchLabels:
      app: mkdocs
  replicas: 2
  template:
    metadata:
      labels:
        app: mkdocs
    spec:
      initContainers:
        - image: 192.168.100.12:8082/mkdocs-git-revision:latest
          name: mkdocs
          volumeMounts:
            - name: build-script
              mountPath: /build.sh
              subPath: build.sh
            - name: mkdocs
              mountPath: /mkdocs
          command: ["/bin/sh", "-c", "/build.sh"]
      containers:
        - image: 192.168.100.12:8082/nginx:1.20.0
          name: nginx
          ports:
            - containerPort: 443
              name: web
          volumeMounts:
            - name: nginx-conf
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
            - name: mkdocs
              mountPath: /mkdocs
      imagePullSecrets:
        - name: nexus-regcred
      volumes:
        - name: nginx-conf
          configMap:
            defaultMode: 0644
            name: mkdocs
            items:
              - key: nginx.conf
                path: nginx.conf
        - name: build-script
          configMap:
            defaultMode: 0755
            name: mkdocs
            items:
              - key: build.sh
                path: build.sh
        - name: mkdocs
          emptyDir:
            
            
            
            
            sizeLimit: 500Mi
```

## 使用 service 暴露服务

由于此环境 mkdocs 不需要对外暴露，使用了 ClusterIP 类型的 service ：

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: mkdocs
  namespace: mkdocs
  labels:
    app: mkdocs
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 80
      name: web
  selector:
    app: mkdocs
```
