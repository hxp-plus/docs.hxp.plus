---
tags:
  - Kubernetes
---

## 在已有的节点上生成加入节点的命令

在已有的 master 节点生成证书和加入集群命令：

```
kubeadm token create --print-join-command
```

```
kubeadm join cluster-endpoint:8443 --token 9igvk8.ptcn52v5d7g261ff --discovery-token-ca-cert-hash sha256:b25ba14968a69b71974b51ee5996d61c3ae1940afcea673500b3d5468d41a1ee
```

```
kubeadm init phase upload-certs --upload-certs
```

```
W0417 16:23:10.938672 3195210 version.go:104] could not fetch a Kubernetes version from the internet: unable to get URL "https://dl.k8s.io/release/stable-1.txt": Get "https://dl.k8s.io/release/stable-1.txt": dial tcp: lookup dl.k8s.io on 21.126.129.88:53: no such host
W0417 16:23:10.938728 3195210 version.go:105] falling back to the local client version: v1.29.2
[upload-certs] Storing the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
[upload-certs] Using certificate key:
6147e16f74b590e74b53dd24e4e928dfeaf934c66229adb4036f6cbac792392a
```

## 在新节点加入 K8S 集群

在新节点上使用 kubeadm 命令加入集群，并作为 master 节点：

```
kubeadm join cluster-endpoint:8443 --token 9igvk8.ptcn52v5d7g261ff --discovery-token-ca-cert-hash sha256:b25ba14968a69b71974b51ee5996d61c3ae1940afcea673500b3d5468d41a1ee --control-plane --certificate-key 6147e16f74b590e74b53dd24e4e928dfeaf934c66229adb4036f6cbac792392a
```

## 配置 NetworkManager 忽略 calico 网卡

如果 k8s 集群使用 calico 作为网络插件，还需要配置 NetworkManager 忽略 calico 网卡，可使用以下 playbook 批量配置：

```yaml
---
- name: configure networkmanager for calico
  hosts: k8s
  tasks:
    - name: create /etc/NetworkManager/conf.d/calico.conf
      copy:
        content: |
          [keyfile]
          unmanaged-devices=interface-name:cali*;interface-name:tunl*;interface-name:vxlan.calico;interface-name:vxlan-v6.calico;interface-name:wireguard.cali;interface-name:wg-v6.cali
        dest: /etc/NetworkManager/conf.d/calico.conf
    - name: restart networkmanager
      systemd:
        name: NetworkManager
        state: restarted
```

## 修改 bashrc

修改 bashrc 使得默认 kubectl 命令连接此 k8s 集群：

```bash
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /root/.bashrc
source /root/.bashrc
```
