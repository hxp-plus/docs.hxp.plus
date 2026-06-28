---
tags:
  - Kubernetes
  - k8s
---

# k3s traefik 路径前缀去除

```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: qbittorrent-ingress
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
    traefik.ingress.kubernetes.io/router.middlewares: default-strip-prefix@kubernetescrd
spec:
  rules:
    - http:
        paths:
          - path: /qbt
            pathType: Prefix
            backend:
              service:
                name: qbittorrent
                port:
                  number: 80
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

!!! warning "文档时效性说明"
本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：k3s traefik path prefix strip

change "default to" your namespace in "Traefik.ingress.Kubernetes.io/router.middlewares"
