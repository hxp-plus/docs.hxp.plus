---
tags:
  - Kubernetes
  - k8s
---
# k8s qbittorrent prefix

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：k8s_qbittorrent_prefix



```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: qbittorrent
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: qbittorrent-ingress
  namespace: qbittorrent
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
    traefik.ingress.kubernetes.io/router.middlewares: qbittorrent-redirect-https@kubernetescrd,qbittorrent-strip-prefix@kubernetescrd
spec:
  tls:
  - secretName: hxp.lan
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
  namespace: qbittorrent
spec:
  stripPrefixRegex:
    regex:
    - ^/[^/]+
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: redirect-https
  namespace: qbittorrent
spec:
  redirectScheme:
    scheme: https
    permanent: true
---
apiVersion: v1
kind: Service
metadata:
  name: qbittorrent
  namespace: qbittorrent
  labels:
    app: qbittorrent
spec:
  ports:
  - port: 80
    targetPort: 8080
    name: qbt-webui
  selector:
    app: qbittorrent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: qbittorrent
  namespace: qbittorrent
spec:
  selector:
    matchLabels:
      app: qbittorrent # has to match .spec.template.metadata.labels
  serviceName: "qbittorrent"
  replicas: 1 # by default is 1
  minReadySeconds: 10 # by default is 0
  template:
    metadata:
      labels:
        app: qbittorrent # has to match .spec.selector.matchLabels
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: qbittorrent-nox
        image: docker.io/qbittorrentofficial/qbittorrent-nox:4.5.5-1
        ports:
        - containerPort: 8080
          name: qbt-webui
        volumeMounts:
        - name: qbittorrent-downloads
          mountPath: /downloads
        - name: qbittorrent-config
          mountPath: /config
  volumeClaimTemplates:
  - metadata:
      name: qbittorrent-downloads
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "local-path"
      resources:
        requests:
          storage: 4Ti
  - metadata:
      name: qbittorrent-config
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "local-path"
      resources:
        requests:
          storage: 16Mi
```

hxp.lan TLS Secret 通过以下命令导入：

```
kubectl create secret tls hxp.lan --cert hxp.lan.crt --key hxp.lan.key --namespace qbittorrent
```


---

## 原文（English）

---
tags:
  - Kubernetes
  - k8s
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。



```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: qbittorrent
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: qbittorrent-ingress
  namespace: qbittorrent
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
    traefik.ingress.kubernetes.io/router.middlewares: qbittorrent-redirect-https@kubernetescrd,qbittorrent-strip-prefix@kubernetescrd
spec:
  tls:
  - secretName: hxp.lan
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
  namespace: qbittorrent
spec:
  stripPrefixRegex:
    regex:
    - ^/[^/]+
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: redirect-https
  namespace: qbittorrent
spec:
  redirectScheme:
    scheme: https
    permanent: true
---
apiVersion: v1
kind: Service
metadata:
  name: qbittorrent
  namespace: qbittorrent
  labels:
    app: qbittorrent
spec:
  ports:
  - port: 80
    targetPort: 8080
    name: qbt-webui
  selector:
    app: qbittorrent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: qbittorrent
  namespace: qbittorrent
spec:
  selector:
    matchLabels:
      app: qbittorrent # has to match .spec.template.metadata.labels
  serviceName: "qbittorrent"
  replicas: 1 # by default is 1
  minReadySeconds: 10 # by default is 0
  template:
    metadata:
      labels:
        app: qbittorrent # has to match .spec.selector.matchLabels
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: qbittorrent-nox
        image: docker.io/qbittorrentofficial/qbittorrent-nox:4.5.5-1
        ports:
        - containerPort: 8080
          name: qbt-webui
        volumeMounts:
        - name: qbittorrent-downloads
          mountPath: /downloads
        - name: qbittorrent-config
          mountPath: /config
  volumeClaimTemplates:
  - metadata:
      name: qbittorrent-downloads
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "local-path"
      resources:
        requests:
          storage: 4Ti
  - metadata:
      name: qbittorrent-config
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "local-path"
      resources:
        requests:
          storage: 16Mi
```

hxp.lan TLS secret is imported by:

```
kubectl create secret tls hxp.lan --cert hxp.lan.crt --key hxp.lan.key --namespace qbittorrent
```
