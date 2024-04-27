---
tags:
  - Kubernetes
  - 银河麒麟V10
---

## 系统架构

本次安装的 K8S 仅有 3 个 master 节点，其中 1 节点和 3 节点额外 HAProxy 和 Keepalived 做 apiserver 高可用，各个节点配置和用途如下：

| 节点名称 | IP 地址        | 服务器角色      | 配置要求                 |
| -------- | -------------- | --------------- | ------------------------ |
| k8s01    | 192.168.100.11 | K8S master 节点 | 2C4G，公网网卡名称 ens33 |
| k8s02    | 192.168.100.12 | K8S master 节点 | 2C4G，公网网卡名称 ens33 |
| k8s03    | 192.168.100.13 | K8S master 节点 | 2C4G，公网网卡名称 ens33 |

其中，所有的节点都需要配置 NTP 时钟同步服务器，且所有节点都需要有默认网关。节点 k8s01 和 k8s03 因有安装 KeepAlived 的需求，需要额外配置一个 VIP：192.168.100.10，同时，需要使用 Ansible 对这 3 个节点进行批量配置。

此次安装为最小化安装，安装网络插件 calico，ingress、helm、ceph-csi 、metrics-server 等非必要功能不安装。同时，推荐提前创建 `/var/lib/containerd` 目录并给其单独挂在逻辑卷。

## 准备工作

### 安装前系统参数

所有节点均需要禁用 swap、关闭 firewalld 防火墙与 SELinux：

```
# Disable swap
sed -i '/^.*[[:space:]]*swap[[:space:]]*swap[[:space:]]*.*$/d' /etc/fstab
# Disable firewalld
systemctl disable firewalld.service
# Disable SELinux
sed -i 's/^SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config
# Reboot to apply changes
reboot
```

对于 1C2G 的低配置机器，如果发现内存不足，需要修改 kdump 的默认 1024M 内存为更小的数值：

```
sed -i 's/crashkernel=1024M,high/crashkernel=128M,high/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
reboot
```

### 安装依赖的软件

所有 k8s 节点都需要使用 yum 命令安装以下依赖：

```
yum install conntrack-tools libnetfilter_cthelper ibnetfilter_cttimeout libnetfilter_queue socat
```

### Ansible 主机清单配置

本文使用 Ansible 来对节点进行批量操作，Ansible 主机清单配置如下：

```
[k8s]
192.168.100.11
192.168.100.12
192.168.100.13

[keepalived]
192.168.100.11 keepalived_status=MASTER
192.168.100.13 keepalived_status=BACKUP

[keepalived:vars]
keepalived_nic=ens33
keepalived_pass=unIhenGAcvAEH
keepalived_router_id=101

[all:vars]
keepalived_vip=192.168.100.10
```

### 介质下载

如果需要离线安装，需要额外准备一台可以通外网的机器来下载介质，此机器也需要禁用 swap、关闭 firewalld 防火墙与 SELinux，且至少需要安装 docker、containerd 与 helm。其中需要下载的二进制文件及配置文件如下：

| 介质名称                             | 下载地址                                                                                             |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| containerd-1.7.11-linux-amd64.tar.gz | https://github.com/containerd/containerd/releases                                                    |
| containerd.service                   | https://raw.githubusercontent.com/containerd/containerd/main/containerd.service                      |
| runc.amd64                           | https://github.com/opencontainers/runc/releases                                                      |
| cni-plugins-linux-amd64-v1.4.0.tgz   | https://github.com/containernetworking/plugins/releases                                              |
| crictl-v1.28.0-linux-amd64.tar.gz    | https://github.com/kubernetes-sigs/cri-tools/releases                                                |
| kubelet                              | https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-2 |
| kubeadm                              | https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-2 |
| kubectl                              | https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-2 |
| 10-kubeadm.conf                      | https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-2 |
| tigera-operator.yaml                 | https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart                           |
| custom-resources.yaml                | https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart                           |

需要下载的容器镜像如下：

| 镜像名称                                        | 下载方式                      |
| ----------------------------------------------- | ----------------------------- |
| registry.k8s.io/kube-apiserver:v1.29.0          | 使用 ctr 或者 docker 命令下载 |
| registry.k8s.io/kube-controller-manager:v1.29.0 | 使用 ctr 或者 docker 命令下载 |
| registry.k8s.io/kube-scheduler:v1.29.0          | 使用 ctr 或者 docker 命令下载 |
| registry.k8s.io/kube-proxy:v1.29.0              | 使用 ctr 或者 docker 命令下载 |
| registry.k8s.io/coredns/coredns:v1.11.1         | 使用 ctr 或者 docker 命令下载 |
| registry.k8s.io/pause:3.9                       | 使用 ctr 或者 docker 命令下载 |
| registry.k8s.io/etcd:3.5.10-0                   | 使用 ctr 或者 docker 命令下载 |
| docker.io/library/haproxy:2.1.4                 | 使用 ctr 或者 docker 命令下载 |
| docker.io/osixia/keepalived:2.0.17              | 使用 ctr 或者 docker 命令下载 |
| docker.io/calico/apiserver:v3.27.0              | 使用 ctr 或者 docker 命令下载 |
| docker.io/calico/cni:v3.27.0                    | 使用 ctr 或者 docker 命令下载 |
| docker.io/calico/csi:v3.27.0                    | 使用 ctr 或者 docker 命令下载 |
| docker.io/calico/kube-controllers:v3.27.0       | 使用 ctr 或者 docker 命令下载 |
| docker.io/calico/node-driver-registrar:v3.27.0  | 使用 ctr 或者 docker 命令下载 |
| docker.io/calico/node:v3.27.0                   | 使用 ctr 或者 docker 命令下载 |
| docker.io/calico/pod2daemon-flexvol:v3.27.0     | 使用 ctr 或者 docker 命令下载 |
| quay.io/tigera/operator:v1.32.3                 | 使用 ctr 或者 docker 命令下载 |
| docker.io/calico/typha:v3.27.0                  | 使用 ctr 或者 docker 命令下载 |

容器镜像使用 ctr 或者 docker 命令下载，ctr 的下载命令如下：

```
ctr -n k8s.io image pull [镜像名称] --platform linux/amd64
ctr -n k8s.io image export [镜像名称].tar [镜像名称] --platform linux/amd64
```

docker 下载的命令如下：

```
docker pull [镜像名称]
docker image save -i [镜像名称].tar
```

导入容器镜像，需要在 k8s 节点用 ctr 命令导入，命令如下：

```
ctr -n k8s.io image import [镜像名称].tar --platform linux/amd64
```

## 安装 containerd 容器运行环境

所有的 k8s 节点都需要安装 containerd，使用此 Ansible Playbook 进行批量安装：

```yaml title="containerd-install.yaml"
---
- name: install containerd
  hosts: all
  tasks:
    - name: extract containerd-1.7.11-linux-amd64.tar.gz
      unarchive:
        src: containerd-1.7.11-linux-amd64.tar.gz
        dest: /usr/local/
    - name: install containerd.service
      copy:
        src: containerd.service
        dest: /usr/lib/systemd/system/containerd.service
    - name: generate default containerd config
      shell:
        cmd: |
          mkdir -p /etc/containerd/
          containerd config default > /etc/containerd/config.toml
    - name: configure containerd to use systemd cgroup
      replace:
        path: /etc/containerd/config.toml
        regexp: "SystemdCgroup = false"
        replace: "SystemdCgroup = true"
    - name: configure containerd to use pause:3.9
      replace:
        path: /etc/containerd/config.toml
        regexp: "registry.k8s.io/pause:3.8"
        replace: "registry.k8s.io/pause:3.9"
    - name: enable and restart containerd service
      systemd:
        name: containerd
        daemon_reload: yes
        state: restarted
        enabled: yes
```

## 安装 Kubernetes

### 配置内核参数并安装 k8s 二进制文件

使用以下 playbook 配置内核参数、安装二进制文件并导入容器镜像：

```yaml title="k8s-install.yaml"
---
- name: install kubernetes
  hosts: k8s
  tasks:
    - name: edit /etc/modules-load.d/k8s.conf
      copy:
        content: |
          overlay
          br_netfilter
        dest: /etc/modules-load.d/k8s.conf
      register: k8s_mod
    - name: edit /etc/sysctl.d/k8s.conf
      copy:
        content: |
          net.bridge.bridge-nf-call-iptables  = 1
          net.bridge.bridge-nf-call-ip6tables = 1
          net.ipv4.ip_forward                 = 1
        dest: /etc/sysctl.d/k8s.conf
      register: k8s_sysctl
    - name: edit /etc/sysctl.conf
      copy:
        content: ""
        dest: /etc/sysctl.conf
      register: sysctl
    - name: reboot
      reboot:
        reboot_timeout: 600
      when: k8s_mod.changed == true or k8s_sysctl.changed == true or sysctl.changed == true
    - name: install runc
      copy:
        src: runc.amd64
        dest: /usr/local/sbin/runc
        mode: 0755
    - name: create directory /opt/cni/bin
      file:
        path: /opt/cni/bin
        state: directory
    - name: install cni-plugins
      unarchive:
        src: cni-plugins-linux-amd64-v1.4.0.tgz
        dest: /opt/cni/bin
    - name: install crictl
      unarchive:
        src: crictl-v1.28.0-linux-amd64.tar.gz
        dest: /usr/local/bin
    - name: install kubelet, kubeadm and kubectl
      copy:
        src: "{{ item }}"
        dest: /usr/local/bin/
        mode: 0755
      with_items:
        - kubeadm
        - kubelet
        - kubectl
    - name: set up bash-completion
      lineinfile:
        line: "source <(kubectl completion bash)"
        path: /root/.bashrc
    - name: install kubelet service
      copy:
        src: kubelet.service
        dest: /etc/systemd/system/kubelet.service
    - name: create directory /etc/systemd/system/kubelet.service.d
      file:
        path: /etc/systemd/system/kubelet.service.d
        state: directory
    - name: install 10-kubeadm.conf
      copy:
        src: 10-kubeadm.conf
        dest: /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    - name: enable and restart kubelet service
      systemd:
        name: kubelet
        daemon_reload: yes
        state: restarted
        enabled: yes
```

### 配置所有节点/etc/hosts

#### 创建 jinja2 模板文件

创建一个 jinja2 模板文件用于配置 hosts，将其放在 templates 目录下：

```title="hosts.j2"
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

{{ keepalived_vip }} cluster-endpoint
{% for host in groups['k8s'] %}
{{ host }} {{ hostvars[host].ansible_nodename }}
{% endfor %}
```

#### 使用 Ansible Playbook 配置/etc/hosts

使用以下 Ansible Playbook 批量配置/etc/hosts：

```yaml
---
- name: config /etc/hosts for all hosts
  hosts: all
  tasks:
    - name: create /etc/hosts
      template:
        src: templates/hosts.j2
        dest: /etc/hosts
```

### 使用 static pod 方式安装 Keepalived 和 HAProxy

!!! warning

    在生产环境，如果负载均衡器可用，推荐使用负载均衡器来实现 apiserver 高可用。如果没有负载均衡器，推荐单独发放 2 台虚拟机做 HAProxy 和 Keepalived 进行软负载高可用。如果实在无法满足条件，在 2 个 k8s 节点以 static pod 方式安装 HAProxy 和 Keepalived。

#### 创建 jinja2 模板文件

一共需要创建 4 个 jinja2 模板文件，将其放在 templates 目录下：

```title="check_apiserver.sh.j2"
#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:8443/ -o /dev/null || errorExit "Error GET https://localhost:8443/"
if ip addr | grep -q {{ keepalived_vip }}; then
    curl --silent --max-time 2 --insecure https://{{ keepalived_vip }}:8443/ -o /dev/null || errorExit "Error GET https://{{ keepalived_vip }}:8443/"
fi
```

```title="haproxy.cfg.j2"
# /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s

#---------------------------------------------------------------------
# apiserver frontend which proxys to the control plane nodes
#---------------------------------------------------------------------
frontend apiserver
    bind *:8443
    mode tcp
    option tcplog
    default_backend apiserverbackend

#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserverbackend
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
    {% for host in groups['k8s'] %}
        server {{ hostvars[host].ansible_nodename }} {{ host }}:6443 check
    {% endfor %}
```

```title="haproxy.yaml.j2"
apiVersion: v1
kind: Pod
metadata:
  name: haproxy
  namespace: kube-system
spec:
  containers:
  - image: docker.io/library/haproxy:2.1.4
    name: haproxy
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: localhost
        path: /healthz
        port: 8443
        scheme: HTTPS
    volumeMounts:
    - mountPath: /usr/local/etc/haproxy/haproxy.cfg
      name: haproxyconf
      readOnly: true
  hostNetwork: true
  volumes:
  - hostPath:
      path: /etc/haproxy/haproxy.cfg
      type: FileOrCreate
    name: haproxyconf
status: {}
```

```title="keepalived.conf.j2"
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state {{ keepalived_status }}
    interface {{ keepalived_nic }}
    virtual_router_id {{ keepalived_router_id }}
    priority 50
    authentication {
        auth_type PASS
        auth_pass {{ keepalived_pass }}
    }
    virtual_ipaddress {
        {{ keepalived_vip }}
    }
    track_script {
        check_apiserver
    }
}
```

```title="keepalived.yaml.j2"
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  name: keepalived
  namespace: kube-system
spec:
  containers:
  - image: docker.io/osixia/keepalived:2.0.17
    name: keepalived
    resources: {}
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_BROADCAST
        - NET_RAW
    volumeMounts:
    - mountPath: /usr/local/etc/keepalived/keepalived.conf
      name: config
    - mountPath: /etc/keepalived/check_apiserver.sh
      name: check
  hostNetwork: true
  volumes:
  - hostPath:
      path: /etc/keepalived/keepalived.conf
    name: config
  - hostPath:
      path: /etc/keepalived/check_apiserver.sh
    name: check
status: {}
```

#### 使用 Ansible Playbook 安装 HAProxy 和 Keepalived 的 static pod

使用以下 Playbook 安装 HAProxy 和 Keepalived 的 static pod：

```yaml title="k8s-install-haproxy-keepalived.yaml"
---
- name: install keepalived and haproxy as static pod
  hosts: all
  tasks:
    - name: create directory /etc/haproxy, /etc/keepalived and /etc/kubernetes/manifests
      file:
        path: "{{ item }}"
        state: directory
        recurse: yes
      with_items:
        - /etc/haproxy
        - /etc/keepalived
        - /etc/kubernetes/manifests
      when: "'keepalived' in group_names"
    - name: create /etc/haproxy/haproxy.cfg
      template:
        src: templates/haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
      when: "'keepalived' in group_names"
    - name: create /etc/keepalived/check_apiserver.sh
      template:
        src: templates/check_apiserver.sh.j2
        dest: /etc/keepalived/check_apiserver.sh
      when: "'keepalived' in group_names"
    - name: create /etc/keepalived/keepalived.conf
      template:
        src: templates/keepalived.conf.j2
        dest: /etc/keepalived/keepalived.conf
      when: "'keepalived' in group_names"
    - name: create /etc/kubernetes/manifests/haproxy.yaml
      template:
        src: templates/haproxy.yaml.j2
        dest: /etc/kubernetes/manifests/haproxy.yaml
      when: "'keepalived' in group_names"
    - name: create /etc/kubernetes/manifests/keepalived.yaml
      template:
        src: templates/keepalived.yaml.j2
        dest: /etc/kubernetes/manifests/keepalived.yaml
      when: "'keepalived' in group_names"
```

### 使用 kubeadm 创建 Kubernetes 集群

在 k8s01 节点创建集群：

```
kubeadm init --control-plane-endpoint cluster-endpoint:8443 --pod-network-cidr=172.18.0.0/16 --upload-certs
```

创建成功后会有以下提示：

```
You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join cluster-endpoint:8443 --token dqgsa7.3g5uhcbbtbgogrfm \
    --discovery-token-ca-cert-hash sha256:7b66a8861d2c2986f1d5caf043b8e5358477b52d4760055dda2781ddad44cc92 \
    --control-plane --certificate-key 526b695cca88e6c8bbb1e19f805f46f080087bcb748a5547009d99c6ac1e4d27
```

在 k8s02 和 k8s03 执行：

```
kubeadm join cluster-endpoint:8443 --token dqgsa7.3g5uhcbbtbgogrfm \
    --discovery-token-ca-cert-hash sha256:7b66a8861d2c2986f1d5caf043b8e5358477b52d4760055dda2781ddad44cc92 \
    --control-plane --certificate-key 526b695cca88e6c8bbb1e19f805f46f080087bcb748a5547009d99c6ac1e4d27
```

将两个节点加入集群，之后所有 k8s 节点都修改 bashrc：

```
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /root/.bashrc
source /root/.bashrc
```

检查集群状态：

```
# kubectl get nodes
NAME    STATUS     ROLES           AGE     VERSION
k8s01   NotReady   control-plane   4m32s   v1.29.0
k8s02   NotReady   control-plane   2m6s    v1.29.0
k8s03   NotReady   control-plane   110s    v1.29.0
```

此时 NotReady 是因为没有安装 calico，为正常现象。

### 设置允许 master 节点调度容器

集群创建以后，因为我们只有 master 节点，需要允许容器在 master 节点调度：

```
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## 安装 Calico 网络插件

### 配置 NetworkManager

所有节点都需要配置 NetworkManager 忽略 calico 网卡，可使用以下 playbook 批量配置：

```yaml title="calico-configure-nm.yaml"
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

### 创建 tigera-operator 并安装 calico

创建 `custom-resources.yaml`：

```yaml title="custom-resources.yaml"
# This section includes base Calico installation configuration.
# For more information, see: https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.Installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
      - blockSize: 24
        cidr: 172.18.0.0/16
        encapsulation: VXLAN
        natOutgoing: Enabled
        nodeSelector: all()
---
# This section configures the Calico API server.
# For more information, see: https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.APIServer
#apiVersion: operator.tigera.io/v1
#kind: APIServer
#metadata:
#  name: default
#spec: {}
```

在任意一个 k8s 节点上运行：

```
kubectl create -f tigera-operator.yaml
kubectl create -f custom-resources.yaml
```

检查 pod 状态：

```
# kubectl -n tigera-operator get pods
NAME                               READY   STATUS    RESTARTS      AGE
tigera-operator-55585899bf-6mwrh   1/1     Running   2 (50s ago)   11m
# kubectl -n calico-system get pods
NAME                           READY   STATUS    RESTARTS       AGE
calico-typha-f8fd87f9d-8sb7w   1/1     Running   1 (2m8s ago)   10m
calico-typha-f8fd87f9d-thkt6   1/1     Running   1 (92s ago)    10m
```

在完全就绪以后，在 k8s 上查看路由表，可以看到 calico 为每个 k8s 节点都分配了一个网段，网段写入了路由表：

```
# ip route
default via 192.168.100.1 dev ens33 proto static metric 100
172.18.97.0/24 via 172.18.97.0 dev vxlan.calico onlink
172.18.122.0/24 via 172.18.122.0 dev vxlan.calico onlink
blackhole 172.18.209.0/24 proto 80
172.18.209.7 dev cali7ba71aa9a5b scope link
172.18.209.8 dev cali4f83fc794cd scope link
192.168.100.0/24 dev ens33 proto kernel scope link src 192.168.100.11 metric 100
```

完全就绪以后，检查两个 coredns 是不是扎堆部署在一个节点上：

```
# kubectl -n kube-system get pods -o wide | grep coredns
kube-system        coredns-76f75df574-4nskd            1/1     Running   1 (4m17s ago)   47m     172.18.97.7      k8s03    <none>           <none>
kube-system        coredns-76f75df574-t9stk            1/1     Running   1 (4m17s ago)   47m     172.18.97.6      k8s03    <none>           <none>
```

如果有这种情况，需要轮询重启 coredns 来使得 coredns 不扎堆在一个节点：

```
kubectl -n kube-system rollout restart deployment coredns
```

## 参考链接

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

https://kubernetes.io/docs/setup/production-environment/container-runtimes/

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/

https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing

https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart

https://www.pivert.org/ceph-csi-on-kubernetes-1-24/
