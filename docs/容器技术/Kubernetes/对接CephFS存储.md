---
tags:
  - Kubernetes
  - Ceph
---

# 对接 CephFS 存储

## 准备工作

### 介质下载

需要使用以下命令下载 ceph-csi-cephfs 的 helm chart：

```
helm repo add ceph-csi https://ceph.github.io/csi-charts
helm pull ceph-csi/ceph-csi-cephfs
```

同时需要下载此 helm chart 所需的容器镜像，镜像名称用以下命令查看：

```
helm template ceph-csi-cephfs-3.10.1.tgz | grep 'image:'
```

## 新建 cephfs 和 volume

在 ceph 服务器上，使用`cephadm shell`进入 ceph 命令行，并执行以下命令：

```bash
ceph fs volume create cephfs
ceph fs subvolumegroup create cephfs csi
```

执行以后检查：

```
ceph fs volume ls
```

```
[
    {
        "name": "cephfs"
    }
]
```

```
ceph fs subvolumegroup ls cephfs
```

```
[
    {
        "name": "csi"
    }
]
```

## ceph 集群配置和 admin keyring 收集

在 ceph 节点上，收集 ceph 配置和 admin 的 keyring：

```
ceph config generate-minimal-conf
```

```
# minimal ceph.conf for 77488730-b4d9-11ee-bec7-fa163e3bb924
[global]
    fsid = 77488730-b4d9-11ee-bec7-fa163e3bb924
    mon_host = [v2:192.168.100.14:3300/0,v1:192.168.100.14:6789/0] [v2:192.168.100.15:3300/0,v1:192.168.100.15:6789/0] [v2:192.168.100.16:3300/0,v1:192.168.100.16:6789/0]
```

```
ceph auth get client.admin
```

```
[client.admin]
    key = ********
    caps mds = "allow *"
    caps mgr = "allow *"
    caps mon = "allow *"
    caps osd = "allow *"
```

## 创建 values.yaml

首先生成 values.yaml：

```
helm show values ceph-csi-cephfs-3.10.1.tgz > values.yaml
```

修改以下的部分：

```yaml
csiConfig:
  - clusterID: "77488730-b4d9-11ee-bec7-fa163e3bb924"
    monitors:
      - "192.168.100.14"
      - "192.168.100.15"
      - "192.168.100.16"
    cephFS:
      subvolumeGroup: "csi"
      # netNamespaceFilePath: "{{ .kubeletDir }}/plugins/{{ .driverName }}/net"
# csiConfig: []
```

```
secret:
  # Specifies whether the secret should be created
  create: true
  name: csi-cephfs-secret
  adminID: admin
  adminKey: ********
```

```
storageClass:
  create: true
  name: csi-cephfs-sc
  clusterID: 77488730-b4d9-11ee-bec7-fa163e3bb924
  fsName: cephfs
```

## 使用 helm chart 安装 ceph-csi-cephfs

```bash
kubectl create namespace ceph-csi-cephfs
helm install --namespace "ceph-csi-cephfs" "ceph-csi-cephfs" ceph-csi-cephfs-3.10.1.tgz --values ./values.yaml
```

## 将 ceph-csi-sc 设置为默认 storage class

```bash
kubectl patch storageclass ceph-csi-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## 创建 pvc 并测试

新建文件`test-pvc.yaml`：

```yaml title="test-pvc.yaml"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-cephfs-sc
```

创建 pvc：

```
kubectl apply -f test-pvc.yaml
```

检查 pvc 状态为 Bound 则为安装成功：

```
kubectl get pvc
```

```
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE
test-pvc   Bound    pvc-9c92208e-cd5a-436a-a785-74b6dc00ae31   1Gi        RWX            csi-cephfs-sc   <unset>                 9m15s
```

如果要查询这个 pvc 对应的 pv 对应的 cephfs 存储位置，可使用以下命令：

```
kubectl get pv $(kubectl get pvc test-pvc -o jsonpath="{.spec.volumeName}") -o jsonpath='{.spec.csi.volumeAttributes.subvolumePath}';echo
```

清理：

```
kubectl delete -f testpvc.yaml
```

## 在非 k8s 节点挂载 cephfs 的方法

### 安装并配置 ceph-fuse

在 ceph 客户端上安装 ceph-fuse：

```
yum install ceph-fuse
```

配置`/etc/ceph/ceph.conf`：

```
mkdir -p -m 755 /etc/ceph
cat > /etc/ceph/ceph.conf <<-'EOF'
[global]
    fsid = 77488730-b4d9-11ee-bec7-fa163e3bb924
    mon_host = 192.168.100.14:6789,192.168.100.15:6789,192.168.100.16:6789
EOF
chmod 644 /etc/ceph/ceph.conf
```

配置 keyring：

```
cat > /etc/ceph/ceph.client.admin.keyring <<-'EOF'
[client.admin]
    key = **********
EOF
chmod 600 /etc/ceph/ceph.client.admin.keyring
```

### 临时挂在 cephfs

如果要临时挂载，使用命令：

```
ceph-fuse -n client.admin /mnt/cephfs
```

### 永久挂载 cephfs

如果要永久挂载，则配置`/etc/fstab`，加入以下行：

```
none	/mnt/cephfs	fuse.ceph	ceph.id=admin,_netdev	0	0
```

再挂载 cephfs：

```
mkdir -p /mnt/cephfs
mount /mnt/cephfs
```

## 参考链接

https://www.pivert.org/ceph-csi-on-kubernetes-1-24/
