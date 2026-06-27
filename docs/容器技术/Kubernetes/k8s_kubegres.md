---
tags:
  - Kubernetes
  - k8s
---

# Deploy kubegres on k8s


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

安装 kubegres operator：

```
kubectl apply -f https://raw.githubusercontent.com/reactive-tech/kubegres/v1.16/kubegres.yaml
kubectl get all -n kubegres-system
kubectl logs pod/kubegres-controller-manager-999786dd6-74tmb -c manager -n kubegres-system -f
```

my-postgres.YAML

```
apiVersion: kubegres.reactive-tech.io/v1
kind: Kubegres
metadata:
  name: mypostgres
  namespace: awx
spec:
   replicas: 3
   image: postgres:13.0
   database:
      size: 20Gi
   scheduler:
      affinity:
         podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                 matchExpressions:
                   - key: app
                     operator: In
                     values:
                        - mypostgres
                topologyKey: "kubernetes.io/hostname"
      tolerations:
         - key: group
           operator: Equal
           value: critical
   probe:
      livenessProbe:
         exec:
            command:
              - sh
              - -c
              - exec pg_isready -U postgres -h $POD_IP
         failureThreshold: 3
         initialDelaySeconds: 60
         periodSeconds: 3
         successThreshold: 1
         timeoutSeconds: 3

      readinessProbe:
         exec:
            command:
              - sh
              - -c
              - exec pg_isready -U postgres -h $POD_IP
         failureThreshold: 3
         initialDelaySeconds: 5
         periodSeconds: 3
         successThreshold: 1
         timeoutSeconds: 3
   env:
      - name: POSTGRES_PASSWORD
        valueFrom:
           secretKeyRef:
              name: mypostgres-secret
              key: superUserPassword
      - name: POSTGRES_REPLICATION_PASSWORD
        valueFrom:
           secretKeyRef:
              name: mypostgres-secret
              key: replicationUserPassword
```

my-postgres-secret.YAML

```
apiVersion: v1
kind: Secret
metadata:
  name: mypostgres-secret
  namespace: awx
type: Opaque
stringData:
  superUserPassword: postgresSuperUserPsw
  replicationUserPassword: postgresReplicaPsw
```



# 参考链接

https://www.kubegres.io/doc/getting-started.html

---

## 原文（English）

---
tags:
  - Kubernetes
  - k8s
---

# Deploy kubegres on k8s


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

install kubegres operator:

```
kubectl apply -f https://raw.githubusercontent.com/reactive-tech/kubegres/v1.16/kubegres.yaml
kubectl get all -n kubegres-system
kubectl logs pod/kubegres-controller-manager-999786dd6-74tmb -c manager -n kubegres-system -f
```

my-postgres.YAML

```
apiVersion: kubegres.reactive-tech.io/v1
kind: Kubegres
metadata:
  name: mypostgres
  namespace: awx
spec:
   replicas: 3
   image: postgres:13.0
   database:
      size: 20Gi
   scheduler:
      affinity:
         podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                 matchExpressions:
                   - key: app
                     operator: In
                     values:
                        - mypostgres
                topologyKey: "kubernetes.io/hostname"
      tolerations:
         - key: group
           operator: Equal
           value: critical
   probe:
      livenessProbe:
         exec:
            command:
              - sh
              - -c
              - exec pg_isready -U postgres -h $POD_IP
         failureThreshold: 3
         initialDelaySeconds: 60
         periodSeconds: 3
         successThreshold: 1
         timeoutSeconds: 3

      readinessProbe:
         exec:
            command:
              - sh
              - -c
              - exec pg_isready -U postgres -h $POD_IP
         failureThreshold: 3
         initialDelaySeconds: 5
         periodSeconds: 3
         successThreshold: 1
         timeoutSeconds: 3
   env:
      - name: POSTGRES_PASSWORD
        valueFrom:
           secretKeyRef:
              name: mypostgres-secret
              key: superUserPassword
      - name: POSTGRES_REPLICATION_PASSWORD
        valueFrom:
           secretKeyRef:
              name: mypostgres-secret
              key: replicationUserPassword
```

my-postgres-secret.YAML

```
apiVersion: v1
kind: Secret
metadata:
  name: mypostgres-secret
  namespace: awx
type: Opaque
stringData:
  superUserPassword: postgresSuperUserPsw
  replicationUserPassword: postgresReplicaPsw
```



# References

https://www.kubegres.io/doc/getting-started.html
