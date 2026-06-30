---
tags:
  - Kubernetes
  - Linux
  - AWX
  - Ansible
---

# AWX 在 Kubernetes 上使用私有仓库离线安装

On an online machine, use kustomize to generate the yaml file:

```
vim kustomization.yaml
```

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  #- github.com/ansible/awx-operator/config/default?ref=1.3.0
  - github.com/ansible/awx-operator/config/default?ref=1.3.0
  - awx.yaml

  # Set the image tags to match the git version from above
images:
  - name: registry.hxp.plus/ansible/awx-operator
    newTag: 1.3.0

# Specify a custom namespace in which to install AWX
namespace: awx
```

```
kustomize build . > awx-operator.yaml
```

Then replace all images from gcr.io and quay.io to private registry. Copy the yaml to offline cluster, and apply the yaml:

```
kubectl apply -f awx-operator.yaml
```

Then create a persistent volume:

```
vim awx-pv.yaml
```

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: awx-pv
  namespace: awx
spec:
  capacity:
   storage: 10Gi
  accessModes:
   - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /data
    server: 192.168.12.21
```

```
kubectl apply -f awx-pv.yaml
```

and write the AWX offline deployment yaml with images from private registry:

```
vim awx.yaml
```

```
---
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  namespace: awx
  name: awx
spec:
  #service_type: nodeport
  ingress_type: ingress
  ingress_class_name: nginx
  hostname: awx.k8s.hxp.plus
  image_pull_policy: Always
  image: registry.hxp.plus/ansible/awx
  image_version: 21.13.0
  postgres_image: registry.hxp.plus/library/postgres
  postgres_image_version: "13"
  redis_image: registry.hxp.plus/library/redis
  redis_image_version: "7"
  ee_images:
  - name: awx-ee
    image: registry.hxp.plus/ansible/awx-ee:latest
  control_plane_ee_image: registry.hxp.plus/ansible/awx-ee:latest
  init_container_image: registry.hxp.plus/ansible/awx-ee
  init_container_image_version: latest
  image_pull_secrets:
    - regcred
```

apply the yaml manifest:

```
kubectl apply -f awx.yaml
```
