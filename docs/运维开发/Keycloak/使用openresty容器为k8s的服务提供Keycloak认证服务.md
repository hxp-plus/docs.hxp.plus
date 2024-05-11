---
tags:
  - openresty
  - Keycloak
  - Kubernetes
---

# 使用 openresty 容器为 k8s 的服务提供 Keycloak 认证服务

## 前置条件

- 一个能运作的 k8s 集群
- 相关容器镜像上传到镜像仓库
- k8s 配置好私有镜像仓库凭证

## 构建容器镜像

使用 [openresty-keycloak-gateway](https://github.com/smyrgeorge/openresty-keycloak-gateway) 项目进行容器镜像的构建，其 Dockerfile 如下：

```Dockerfile
FROM openresty/openresty:alpine-fat
RUN mkdir /var/log/nginx
RUN apk add --no-cache openssl-dev
RUN apk add --no-cache git
RUN apk add --no-cache gcc
RUN luarocks install lua-resty-openidc
ENTRYPOINT ["/usr/local/openresty/nginx/sbin/nginx", "-g", "daemon off;"]
```

## 创建 configmap 来存储容器配置

使用 configmap 进行 openresty 配置的存储：

```yaml
---
apiVersion: v1
data:
  nginx.conf: |
    events {
      worker_connections 1024;
    }

    http {
      lua_package_path '~/lua/?.lua;;';
      lua_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
      lua_ssl_verify_depth 5;
      lua_shared_dict introspection 10m;
      server {
        listen       8000 default_server;
        listen       [::]:8000 default_server;
        # disbled caching so the browser won't cache the site.
        expires           0;
        add_header        Cache-Control private;
        set $session_name nginx_session;
        set $session_secret kjlbnbuukllkj23i;
        access_by_lua_block {
          local keycloak_base_url = "http://22.182.16.129:9003/"
          local client_id = "BOC-IT-Automation"
          local realm = "BOC-IT-Automation"
          local opts = {
            client_id = client_id,
            discovery = keycloak_base_url .. "/realms/" .. realm .. "/.well-known/openid-configuration",
            redirect_url_scheme = "http",
            redirect_uri_path = "/redirect",
            logout_path = "/logout",
            session_contents = {id_token=true},
            ssl_verify = "no",
          }
          local res, err = require("resty.openidc").authenticate(opts)
          if err then
            ngx.status = 401
            ngx.say(err)
            ngx.exit(ngx.HTTP_UNAUTHORIZED)
          end
        }
        location / {
          add_header Cache-Control 'no-store';
          add_header Cache-Control 'no-cache';
          expires 0;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header Authorization "";
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "Upgrade";
          proxy_pass http://mkdocs.mkdocs.svc.cluster.local/;
        }
      }
    }
```

其中 `proxy_pass` 为需要 openresty 进行反向代理的地址，在这里使用了 k8s 内部的域名解析，域名的格式为 `[service名称].[namespace名称].svc.cluster.local` ，解析到 mkdocs 这个 namespace 的 mkdocs service 。

## 使用 deployment 部署 pod

使用此 deployment 部署 pod ，部署数量为 2 份：

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: authproxy
  namespace: mkdocs
  labels:
    app: authproxy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: authproxy
  template:
    metadata:
      labels:
        app: authproxy
    spec:
      containers:
        - image: 192.168.100.12:8082/authproxy:v20240508
          name: authproxy
          ports:
            - containerPort: 8000
              name: web
          volumeMounts:
            - name: authproxy
              mountPath: /nginx.conf
              subPath: nginx.conf
          args: ["-c", "/nginx.conf"]
      imagePullSecrets:
        - name: nexus-regcred
      volumes:
        - name: authproxy
          configMap:
            defaultMode: 0644
            name: authproxy
            items:
              - key: nginx.conf
                path: nginx.conf
```

## 使用 service 暴露服务

将 authproxy 以 NodePort 方式暴露：

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: authproxy
  namespace: mkdocs
  labels:
    app: authproxy
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 8000
      name: web
  selector:
    app: authproxy
```
