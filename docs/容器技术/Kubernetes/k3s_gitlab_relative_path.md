---
tags:
  - Kubernetes
  - k8s
---

# 在 k3s 上安装 GitLab（使用 local path 和 relative URL path）


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Install GitLab with local path on k3s with relative url path as stateful set

## 创建 Persistent Volume

```
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-data-volume
spec:
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 32Gi
  storageClassName: gitlab-data-volume
  local:
    path: /data/gitlab/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - rhel9.hxp.lan
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-log-volume
spec:
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 2Gi
  storageClassName: gitlab-log-volume
  local:
    path: /data/gitlab/log
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - rhel9.hxp.lan
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-config-volume
spec:
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 16Mi
  storageClassName: gitlab-config-volume
  local:
    path: /data/gitlab/config
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - rhel9.hxp.lan
```

## 创建 Volume Claim

```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-data-claim
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 32Gi
  storageClassName: gitlab-data-volume

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-log-claim
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 2Gi
  storageClassName: gitlab-log-volume

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-config-claim
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 16Mi
  storageClassName: gitlab-config-volume
```

## 创建 TLS Secret

```
kubectl create secret tls hxp.lan --cert hxp.lan.crt --key hxp.lan.key --namespace gitlab
```

## 创建 GitLab 资源

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: gitlab
---
apiVersion: traefik.containo.us/v1alpha1
kind: ServersTransport
metadata:
  name: skipverify
  namespace: gitlab
spec:
    insecureSkipVerify: true
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gitlab
  namespace: gitlab
  annotations:
    ingress.kubernetes.io/ssl-redirect: "true"
    traefik.ingress.kubernetes.io/router.middlewares: gitlab-redirect-https@kubernetescrd
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  tls:
  - secretName: hxp.lan
  rules:
  - http:
      paths:
      - path: /gitlab
        pathType: Prefix
        backend:
          service:
            name: gitlab
            port:
              number: 443
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: redirect-https
  namespace: gitlab
spec:
  redirectScheme:
    scheme: https
    permanent: true
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: gitlab
  name: gitlab
  namespace: gitlab
  annotations:
    traefik.ingress.kubernetes.io/service.serversscheme: https
    traefik.ingress.kubernetes.io/service.serverstransport: gitlab-skipverify@kubernetescrd
spec:
  ports:
    - name: "80"
      port: 80
      targetPort: 80
    - name: "443"
      port: 443
      targetPort: 443
    - name: "2222"
      port: 2222
      targetPort: 22
  selector:
    app: gitlab
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: gitlab
  name: gitlab
  namespace: gitlab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitlab
  serviceName: gitlab
  minReadySeconds: 10
  template:
    metadata:
      labels:
        app: gitlab
    spec:
      containers:
        - env:
            - name: GITLAB_OMNIBUS_CONFIG
              value: |
                external_url 'https://rhel9.hxp.lan/gitlab'
                gitlab_rails['gitlab_shell_ssh_port'] = 2222
                puma['worker_processes'] = 0
                sidekiq['max_concurrency'] = 10
                prometheus_monitoring['enable'] = false
                gitlab_rails['env'] = {
                  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
                }
                gitaly['configuration'] = {
                  concurrency: [
                    {
                      'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                      'max_per_repo' => 3,
                    }, {
                      'rpc' => "/gitaly.SSHService/SSHUploadPack",
                      'max_per_repo' => 3,
                    },
                  ]
                }
                gitaly['env'] = {
                  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000',
                  'GITALY_COMMAND_SPAWN_MAX_PARALLEL' => '2'
                }
          image: gitlab/gitlab-ee:16.2.6-ee.0
          name: gitlab
          ports:
            - containerPort: 80
              name: web
            - containerPort: 443
              name: ssl
            - containerPort: 22
              hostPort: 2222
              protocol: TCP
          volumeMounts:
            - mountPath: /etc/gitlab
              name: gitlab-config
            - mountPath: /var/log/gitlab
              name: gitlab-log
            - mountPath: /var/opt/gitlab
              name: gitlab-data
            - mountPath: /dev/shm
              name: dshm
      volumes:
        - name: dshm
          emptyDir:
            medium: Memory
            sizeLimit: 256Mi
        - name: gitlab-config
          persistentVolumeClaim:
            claimName: gitlab-config-claim
        - name: gitlab-log
          persistentVolumeClaim:
            claimName: gitlab-log-claim
        - name: gitlab-data
          persistentVolumeClaim:
            claimName: gitlab-data-claim
```

---

## 原文（English）

---
tags:
  - Kubernetes
  - k8s
---

# Install GitLab with local path on k3s with relative url path as stateful set


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Create Persistent Volumes

```
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-data-volume
spec:
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 32Gi
  storageClassName: gitlab-data-volume
  local:
    path: /data/gitlab/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - rhel9.hxp.lan
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-log-volume
spec:
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 2Gi
  storageClassName: gitlab-log-volume
  local:
    path: /data/gitlab/log
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - rhel9.hxp.lan
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-config-volume
spec:
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  capacity:
    storage: 16Mi
  storageClassName: gitlab-config-volume
  local:
    path: /data/gitlab/config
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - rhel9.hxp.lan
```

## Create Volume Claims

```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-data-claim
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 32Gi
  storageClassName: gitlab-data-volume

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-log-claim
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 2Gi
  storageClassName: gitlab-log-volume

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-config-claim
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 16Mi
  storageClassName: gitlab-config-volume
```

## Create TLS secret

```
kubectl create secret tls hxp.lan --cert hxp.lan.crt --key hxp.lan.key --namespace gitlab
```

## Create GitLab Resources

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: gitlab
---
apiVersion: traefik.containo.us/v1alpha1
kind: ServersTransport
metadata:
  name: skipverify
  namespace: gitlab
spec:
    insecureSkipVerify: true
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gitlab
  namespace: gitlab
  annotations:
    ingress.kubernetes.io/ssl-redirect: "true"
    traefik.ingress.kubernetes.io/router.middlewares: gitlab-redirect-https@kubernetescrd
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  tls:
  - secretName: hxp.lan
  rules:
  - http:
      paths:
      - path: /gitlab
        pathType: Prefix
        backend:
          service:
            name: gitlab
            port:
              number: 443
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: redirect-https
  namespace: gitlab
spec:
  redirectScheme:
    scheme: https
    permanent: true
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: gitlab
  name: gitlab
  namespace: gitlab
  annotations:
    traefik.ingress.kubernetes.io/service.serversscheme: https
    traefik.ingress.kubernetes.io/service.serverstransport: gitlab-skipverify@kubernetescrd
spec:
  ports:
    - name: "80"
      port: 80
      targetPort: 80
    - name: "443"
      port: 443
      targetPort: 443
    - name: "2222"
      port: 2222
      targetPort: 22
  selector:
    app: gitlab
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: gitlab
  name: gitlab
  namespace: gitlab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitlab
  serviceName: gitlab
  minReadySeconds: 10
  template:
    metadata:
      labels:
        app: gitlab
    spec:
      containers:
        - env:
            - name: GITLAB_OMNIBUS_CONFIG
              value: |
                external_url 'https://rhel9.hxp.lan/gitlab'
                gitlab_rails['gitlab_shell_ssh_port'] = 2222
                puma['worker_processes'] = 0
                sidekiq['max_concurrency'] = 10
                prometheus_monitoring['enable'] = false
                gitlab_rails['env'] = {
                  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
                }
                gitaly['configuration'] = {
                  concurrency: [
                    {
                      'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                      'max_per_repo' => 3,
                    }, {
                      'rpc' => "/gitaly.SSHService/SSHUploadPack",
                      'max_per_repo' => 3,
                    },
                  ]
                }
                gitaly['env'] = {
                  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000',
                  'GITALY_COMMAND_SPAWN_MAX_PARALLEL' => '2'
                }
          image: gitlab/gitlab-ee:16.2.6-ee.0
          name: gitlab
          ports:
            - containerPort: 80
              name: web
            - containerPort: 443
              name: ssl
            - containerPort: 22
              hostPort: 2222
              protocol: TCP
          volumeMounts:
            - mountPath: /etc/gitlab
              name: gitlab-config
            - mountPath: /var/log/gitlab
              name: gitlab-log
            - mountPath: /var/opt/gitlab
              name: gitlab-data
            - mountPath: /dev/shm
              name: dshm
      volumes:
        - name: dshm
          emptyDir:
            medium: Memory
            sizeLimit: 256Mi
        - name: gitlab-config
          persistentVolumeClaim:
            claimName: gitlab-config-claim
        - name: gitlab-log
          persistentVolumeClaim:
            claimName: gitlab-log-claim
        - name: gitlab-data
          persistentVolumeClaim:
            claimName: gitlab-data-claim
```
