---
tags:
  - Kubernetes
  - k8s
---
# 麒麟V10SP1高可用Kubernetes+Ceph集群部署

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 系统架构

一套高可用k8s环境由6个节点组成，各个节点配置和用途如下：

| 节点名称 | IP地址 | 服务器角色 | 配置要求 |
| --- | --- | --- | --- |
| k8s01 | 192.168.100.11 | K8S节点 | 2C4G |
| k8s02 | 192.168.100.12 | K8S节点 | 2C4G |
| k8s03 | 192.168.100.13 | K8S节点 | 2C4G |
| ceph01 | 192.168.100.14 | Ceph节点 | 2C4G |
| ceph02 | 192.168.100.15 | Ceph节点 | 2C4G |
| ceph03 | 192.168.100.16 | Ceph节点 | 2C4G |

其中，所有的节点都需要配置NTP时钟同步服务器，且所有节点都需要有默认网关。节点k8s01和k8s03因有安装KeepAlived的需求，需要额外配置一个VIP：192.168.100.10。

## 准备工作

所有6个节点均需要禁用swap、关闭firewalld防火墙与SELinux：

```bash
# Disable swap

sed -i '/^.*[[:space:]]*swap[[:space:]]*swap[[:space:]]*.*$/d' /etc/fstab
# Disable firewalld
systemctl disable firewalld.service
# Disable SELinux
sed -i 's/^SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config
# Reboot to apply changes
reboot
```

同时，对于1C2G的低配置机器，如果发现内存不足，需要修改kdump的默认1024M内存为更小的数值：

```bash
sed -i 's/crashkernel=1024M,high/crashkernel=128M,high/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
reboot
```

如果需要离线安装，需要额外准备一台可以通外网的机器来下载介质，此机器也需要禁用swap、关闭firewalld防火墙与SELinux，且至少需要安装docker、containerd与helm，安装教程见后文。

本文使用的ansible主机清单如下：

```
[k8s]
192.168.100.11
192.168.100.12
192.168.100.13

[ceph]
192.168.100.14
192.168.100.15
192.168.100.16

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

## 安装containerd

在所有的6个节点上，都需要安装containerd，containerd的二进制文件从这里下载：https://github.com/containerd/containerd/releases

containerd的systemd配置文件在这里下载：https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

使用以下ansible playbook安装containerd：

```yaml
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
    shell: mkdir -p /etc/containerd/ && containerd config default > /etc/containerd/config.toml
  - name: configure containerd to use systemd cgroup
    replace:
      path: /etc/containerd/config.toml
      regexp: 'SystemdCgroup = false'
      replace: 'SystemdCgroup = true'
  - name: configure containerd to use pause:3.9
    replace:
      path: /etc/containerd/config.toml
      regexp: 'registry.k8s.io/pause:3.8'
      replace: 'registry.k8s.io/pause:3.9'
  - name: enable and restart containerd service
    systemd:
      name: containerd
      daemon_reload: yes
      state: restarted
      enabled: yes
```

## 安装docker

在所有的ceph节点上，都需要安装docker，其中docker二进制程序和systemd配置在以下两个地方下载：

https://download.docker.com/linux/static/stable/x86_64/

https://github.com/moby/moby/tree/master/contrib/init/systemd

使用以下playbook安装docker：

```yaml
---
- name: install containerd
  hosts: ceph
  tasks:
  - name: copy files to remote /tmp
    copy:
      src: "{{ item }}"
      dest: /tmp/
    with_items:
    - docker-24.0.7.tgz
    - docker.service
    - docker.socket
  - name: install docker
    shell: |
      cd /tmp
      tar zxvf docker-24.0.7.tgz
      cp docker/* /usr/bin/
      cp docker.service docker.socket /usr/lib/systemd/system/
      groupadd --system docker --gid 357
  - name: enable and restart docker service
    systemd:
      name: docker
      daemon_reload: yes
      state: restarted
      enabled: yes
```

## 安装ceph集群

如果已经安装ceph，可以使用以下命令铲掉（fsid从/etc/Ceph/Ceph.conf查）：

```bash
cephadm rm-cluster --force --zap-osds --fsid 6c41951a-b354-11ee-be6d-fa163e3bb924
```

### 下载容器镜像

首先需要使用docker命令下载以下容器镜像：

```
quay.io/ceph/ceph:v18
quay.io/ceph/ceph-grafana:9.4.7
quay.io/prometheus/prometheus:v2.43.0
quay.io/prometheus/alertmanager:v0.25.0
quay.io/prometheus/node-exporter:v1.5.0
registry:2
```

以quay.io/Ceph/Ceph:v18为例，需要用以下命令下载：

```bash
docker pull quay.io/ceph/ceph:v18
docker save quay.io/ceph/ceph:v18 | gzip > ceph_v18.tar.gz 
```

导入使用以下命令：

```bash
gzip -d ceph_v18.tar.gz -c | docker load
```

### 安装cephadm和ceph

使用以下playbook安装ceph和cephadm：

```yaml
---
- name: install ceph
  hosts: ceph
  tasks:
  - name: copy files to remote /tmp
    copy:
      src: "{{ item }}"
      dest: /tmp/images/
    with_items:
    - images/alertmanager_v0.25.0.tar.gz
    - images/ceph-grafana_9.4.7.tar.gz
    - images/ceph_v18.tar.gz
    - images/node-exporter_v1.5.0.tar.gz
    - images/prometheus_v2.43.0.tar.gz
    - images/registry_2.tar.gz
  - name: import images
    shell: |
      gzip -d "/tmp/images/{{ item }}" -c | docker load
    with_items:
    - alertmanager_v0.25.0.tar.gz
    - ceph-grafana_9.4.7.tar.gz
    - ceph_v18.tar.gz
    - node-exporter_v1.5.0.tar.gz
    - prometheus_v2.43.0.tar.gz
    - registry_2.tar.gz
  - name: tag images
    shell: |
      docker image tag quay.io/prometheus/alertmanager:v0.25.0 localhost:5000/prometheus/alertmanager:v0.25.0
      docker image tag quay.io/ceph/ceph-grafana:9.4.7 localhost:5000/ceph/ceph-grafana:9.4.7
      docker image tag quay.io/ceph/ceph:v18 localhost:5000/ceph/ceph:v18
      docker image tag quay.io/prometheus/node-exporter:v1.5.0 localhost:5000/prometheus/node-exporter:v1.5.0
      docker image tag quay.io/prometheus/prometheus:v2.43.0 localhost:5000/prometheus/prometheus:v2.43.0
  - name: run docker local registry
    shell: |
      docker run -d --restart=unless-stopped --name registry \
        -e "REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry" \
        -e "REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=inmemory" \
        -e "REGISTRY_STORAGE_DELETE_ENABLED=true" \
        -e "REGISTRY_VALIDATION_DISABLED=true" \
        -v "registry-data:/var/lib/registry" \
        -p "127.0.0.1:5000:5000" \
        registry:2
      true
  - name: push images to local repository
    shell: |
      docker push localhost:5000/prometheus/alertmanager:v0.25.0
      docker push localhost:5000/ceph/ceph-grafana:9.4.7
      docker push localhost:5000/ceph/ceph:v18
      docker push localhost:5000/prometheus/node-exporter:v1.5.0
      docker push localhost:5000/prometheus/prometheus:v2.43.0
  - name: install cephadm
    copy:
      src: cephadm
      dest: /usr/local/bin/
      mode: 0755
  - name: add ceph group
    group:
      name: ceph
      gid: 167
  - name: add ceph user
    user:
      name: ceph
      uid: 167
      shell: /sbin/nologin
      expires: -1
  - name: add /root/.bashrc environment variable
    lineinfile:
      path: /root/.bashrc
      line: "export CEPHADM_IMAGE=localhost:5000/ceph/ceph:v18"
```

### 配置ceph01节点

安装完成后，在ceph01节点，创建ceph集群：

```bash
source ~/.bashrc
cephadm bootstrap --mon-ip 192.168.100.14
```

之后使用`cephadm shell`命令进入ceph命令行（所有ceph命令均需要在ceph命令行执行），运行以下命令修改ceph相关容器使用本地镜像仓库：

```bash
ceph config set mgr mgr/cephadm/container_image_prometheus localhost:5000/prometheus/prometheus:v2.43.0
ceph config set mgr mgr/cephadm/container_image_node_exporter localhost:5000/prometheus/node-exporter:v1.5.0
ceph config set mgr mgr/cephadm/container_image_grafana localhost:5000/ceph/ceph-grafana:9.4.7
ceph config set mgr mgr/cephadm/container_image_alertmanager localhost:5000/prometheus/alertmanager:v0.25.0
```

重新部署ceph容器：

```bash
ceph orch redeploy prometheus
ceph orch redeploy node-exporter
ceph orch redeploy grafana
ceph orch redeploy alertmanager
```

验证：

```bash
# ceph orch ls
NAME           PORTS        RUNNING  REFRESHED  AGE  PLACEMENT  
alertmanager   ?:9093,9094      1/1  7s ago     3m   count:1    
ceph-exporter                   1/1  7s ago     3m   *          
crash                           1/1  7s ago     3m   *          
grafana        ?:3000           1/1  7s ago     3m   count:1    
mgr                             1/2  7s ago     3m   count:2    
mon                             1/5  7s ago     3m   count:5    
node-exporter  ?:9100           1/1  7s ago     3m   *          
prometheus     ?:9095           1/1  7s ago     3m   count:1
```

将节点ceph01设置成管理节点：

```bash
ceph orch host label add ceph01 _admin
```

检查ceph所有节点：

```bash
# ceph orch host ls
HOST    ADDR            LABELS  STATUS  
ceph01  192.168.100.14  _admin
```

### 将其它节点加入ceph集群作为管理节点

在第一个节点上，将剩下两个节点加入ceph集群（以下命令不要在ceph命令行执行）：

```bash
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.100.15
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.100.16
cephadm shell -- ceph orch host add ceph02 192.168.100.15
cephadm shell -- ceph orch host label add ceph02 _admin
cephadm shell -- ceph orch host add ceph03 192.168.100.16
cephadm shell -- ceph orch host label add ceph03 _admin
```

将monitor部署在三个节点：

```bash
ceph orch apply mon --placement="ceph01,ceph02,ceph03"
```

如果三个节点在一个B段，但是不在一个C段，还需要额外运行这个命令修改public_network子网：

```bash
ceph config set mon public_network 192.168.0.0/16
```

完成以后，检查ceph主机列表：

```bash
# ceph orch host ls
HOST    ADDR            LABELS  STATUS  
ceph01  192.168.100.14  _admin          
ceph02  192.168.100.15  _admin          
ceph03  192.168.100.16  _admin          
3 hosts in cluster
```

### 将磁盘加入ceph

将三个机器的/dev/sdb加入ceph集群：

```bash
ceph orch daemon add osd ceph01:/dev/sdb
ceph orch daemon add osd ceph02:/dev/sdb
ceph orch daemon add osd ceph03:/dev/sdb
```

### 检查ceph集群状态

```bash
# ceph status
  cluster:
    id:     2708c980-bdb5-11ee-9d2f-000c29838e6e
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum ceph01,ceph02,ceph03 (age 3m)
    mgr: ceph02.rlxrnd(active, since 3m), standbys: ceph01.ftqqta
    osd: 3 osds: 3 up (since 22s), 3 in (since 38s)
 
  data:
    pools:   1 pools, 1 pgs
    objects: 2 objects, 449 KiB
    usage:   80 MiB used, 96 GiB / 96 GiB avail
    pgs:     1 active+clean
```

## 安装Kubernetes集群

如果已经安装过kubernetes，用以下命令铲掉：

```bash
kubeadm reset --force
reboot
```

### 下载介质

#### 二进制文件

runc下载地址：https://github.com/opencontainers/runc/releases

cni-plugins下载地址：https://github.com/containernetworking/plugins/releases

crictl下载地址：https://github.com/kubernetes-sigs/cri-tools/releases

kubeadm、kubectl、kubelet、10-kubeadm.conf和kubelet.service，在这里下载：https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-2 （请点击“Installing kubeadm, kubelet and kubectl”章节的“Without a package manager”）

#### 容器镜像

以下容器镜像需要下载（使用`./kubeadm config images list`可以查看）：

```
registry.k8s.io/kube-apiserver:v1.29.0
registry.k8s.io/kube-controller-manager:v1.29.0
registry.k8s.io/kube-scheduler:v1.29.0
registry.k8s.io/kube-proxy:v1.29.0
registry.k8s.io/coredns/coredns:v1.11.1
registry.k8s.io/pause:3.9
registry.k8s.io/etcd:3.5.10-0
docker.io/library/haproxy:2.1.4
docker.io/osixia/keepalived:2.0.17
```

下载命令示例如下：

```bash
ctr -n k8s.io image pull docker.io/library/haproxy:2.1.4
ctr -n k8s.io images export haproxy_2.1.4.tar docker.io/library/haproxy:2.1.4 --platform linux/amd64
```

导入命令示例如下：

```bash
ctr -n k8s.io images import haproxy_2.1.4.tar --platform linux/amd64
```
如需批量下载，命令可参考如下：
```bash
while read line;do ctr -n k8s.io image pull $line --platform linux/amd64;done<images-metrics.txt
while read line;do ctr -n k8s.io image export ${line##*/}.tar $line --platform linux/amd64;done<images-metrics.txt
```
#### RPM包

需要安装以下RPM包：

```
conntrack-tools
libnetfilter_cthelper
libnetfilter_cttimeout
libnetfilter_queue
socat
```

可以使用yum命令下载rpm包：

```
yum install --downloadonly --downloaddir=. socat
```

### 配置内核参数、安装二进制文件并导入容器镜像

使用以下playbook配置内核参数、安装二进制文件并导入容器镜像：

```yaml
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
  - name: copy images to /tmp
    copy:
      src: "{{ item }}"
      dest: /tmp/images/
    with_items:
    - images/coredns_v1.11.1.tar
    - images/etcd_3.5.10-0.tar
    - images/haproxy_2.1.4.tar
    - images/keepalived_2.0.17.tar
    - images/kube-apiserver_v1.29.0.tar
    - images/kube-controller-manager_v1.29.0.tar
    - images/kube-proxy_v1.29.0.tar
    - images/kube-scheduler_v1.29.0.tar
    - images/pause_3.9.tar
  - name: import images
    shell: |
      ctr -n k8s.io images import "/tmp/images/{{ item }}" --platform linux/amd64
    with_items:
    - coredns_v1.11.1.tar
    - etcd_3.5.10-0.tar
    - haproxy_2.1.4.tar
    - keepalived_2.0.17.tar
    - kube-apiserver_v1.29.0.tar
    - kube-controller-manager_v1.29.0.tar
    - kube-proxy_v1.29.0.tar
    - kube-scheduler_v1.29.0.tar
    - pause_3.9.tar
```

### 使用static pod方式安装KeepAlived和HAProxy

首先在templates目录下创建ansible模板check_apiserver.sh.j2、HAProxy.cfg.j2、HAProxy.YAML.j2、hosts.j2、Keepalived.conf.j2和keepalived.YAML.j2：

check_apiserver.sh.j2：

```
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

HAProxy.cfg.j2：

```
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

HAProxy.YAML.j2：

```
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

hosts.j2：

```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

{{ keepalived_vip }} cluster-endpoint
{% for host in groups['k8s'] %}
{{ host }} {{ hostvars[host].ansible_nodename }}
{% endfor %}
```

Keepalived.conf.j2：

```
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

Keepalived.YAML.j2：

```
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

使用以下playbook部署keepalived和haproxy，并写所有节点/etc/hosts：

```yaml
---
- name: install keepalived and haproxy as static pod
  hosts: all
  tasks:
  - name: create /etc/hosts
    template:
      src: templates/hosts.j2
      dest: /etc/hosts
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

### 使用kubeadm创建集群

在k8s01节点创建集群：

```bash
kubeadm init --control-plane-endpoint cluster-endpoint:8443 --pod-network-cidr=172.18.0.0/16 --upload-certs
```

创建成功后会有以下提示：

```
You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join cluster-endpoint:8443 --token dqgsa7.3g5uhcbbtbgogrfm \
    --discovery-token-ca-cert-hash sha256:7b66a8861d2c2986f1d5caf043b8e5358477b52d4760055dda2781ddad44cc92 \
    --control-plane --certificate-key 526b695cca88e6c8bbb1e19f805f46f080087bcb748a5547009d99c6ac1e4d27
```

在k8s02和k8s03执行：

```bash
kubeadm join cluster-endpoint:8443 --token dqgsa7.3g5uhcbbtbgogrfm \
    --discovery-token-ca-cert-hash sha256:7b66a8861d2c2986f1d5caf043b8e5358477b52d4760055dda2781ddad44cc92 \
    --control-plane --certificate-key 526b695cca88e6c8bbb1e19f805f46f080087bcb748a5547009d99c6ac1e4d27
```

将两个节点加入集群，之后所有k8s节点都修改bashrc：

```bash
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /root/.bashrc
source /root/.bashrc
```

检查集群状态：

```bash
# kubectl get nodes
NAME    STATUS     ROLES           AGE     VERSION
k8s01   NotReady   control-plane   4m32s   v1.29.0
k8s02   NotReady   control-plane   2m6s    v1.29.0
k8s03   NotReady   control-plane   110s    v1.29.0
```

此时NotReady是因为没有安装calico，为正常现象。集群创建以后，需要允许control-plane调度：

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## 安装Calico网络插件

### 下载介质

进入Calico的quickstart页面(<https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart>)，在"Install Calico"章节下载两个yaml文件tigera-operator.yaml和custom-resources.YAML

同时，需要用ctr命令下载以下容器镜像：

```
docker.io/calico/apiserver:v3.27.0
docker.io/calico/cni:v3.27.0
docker.io/calico/csi:v3.27.0
docker.io/calico/kube-controllers:v3.27.0
docker.io/calico/node-driver-registrar:v3.27.0
docker.io/calico/node:v3.27.0
docker.io/calico/pod2daemon-flexvol:v3.27.0
quay.io/tigera/operator:v1.32.3
docker.io/calico/typha:v3.27.0
```

### 导入容器镜像

使用此playbook批量导入：

```yaml
---
- name: install calico images
  hosts: k8s
  tasks:
  - name: copy images to /tmp
    copy:
      src: "{{ item }}"
      dest: /tmp/images/
    with_items:
    - images/apiserver_v3.27.0.tar
    - images/cni_v3.27.0.tar
    - images/csi_v3.27.0.tar
    - images/kube-controllers_v3.27.0.tar
    - images/node-driver-registrar_v3.27.0.tar
    - images/node_v3.27.0.tar
    - images/pod2daemon-flexvol_v3.27.0.tar
    - images/tigera_operator_v1.32.3.tar
    - images/typha_v3.27.0.tar
  - name: import images
    shell: |
      ctr -n k8s.io images import "/tmp/images/{{ item }}" --platform linux/amd64
    with_items:
    - apiserver_v3.27.0.tar
    - cni_v3.27.0.tar
    - csi_v3.27.0.tar
    - kube-controllers_v3.27.0.tar
    - node-driver-registrar_v3.27.0.tar
    - node_v3.27.0.tar
    - pod2daemon-flexvol_v3.27.0.tar
    - tigera_operator_v1.32.3.tar
    - typha_v3.27.0.tar
```

### 配置NetworkManager

需要配置NetworkManager忽略calico网卡，使用以下playbook：

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

### 创建tigera-operator并安装calico

创建custom-resources.YAML：

```yaml
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

在任意一个k8s节点上运行：

```bash
kubectl create -f tigera-operator.yaml
kubectl create -f custom-resources.yaml
```

检查pod状态：

```bash
# kubectl -n tigera-operator get pods
NAME                               READY   STATUS    RESTARTS      AGE
tigera-operator-55585899bf-6mwrh   1/1     Running   2 (50s ago)   11m
# kubectl -n calico-system get pods
NAME                           READY   STATUS    RESTARTS       AGE
calico-typha-f8fd87f9d-8sb7w   1/1     Running   1 (2m8s ago)   10m
calico-typha-f8fd87f9d-thkt6   1/1     Running   1 (92s ago)    10m
```

在完全就绪以后，在k8s上查看路由表，可以看到calico为每个k8s节点都分配了一个网段，网段写入了路由表：

```bash
# ip route 
default via 192.168.100.1 dev ens33 proto static metric 100 
172.18.97.0/24 via 172.18.97.0 dev vxlan.calico onlink 
172.18.122.0/24 via 172.18.122.0 dev vxlan.calico onlink 
blackhole 172.18.209.0/24 proto 80 
172.18.209.7 dev cali7ba71aa9a5b scope link 
172.18.209.8 dev cali4f83fc794cd scope link 
192.168.100.0/24 dev ens33 proto kernel scope link src 192.168.100.11 metric 100
```

完全就绪以后，检查两个coredns是不是扎堆部署在一个机器上：

```bash
# kubectl -n kube-system get pods -o wide | grep coredns
kube-system        coredns-76f75df574-4nskd            1/1     Running   1 (4m17s ago)   47m     172.18.97.7      k8s03    <none>           <none>
kube-system        coredns-76f75df574-t9stk            1/1     Running   1 (4m17s ago)   47m     172.18.97.6      k8s03    <none>           <none>
```

轮询重启coredns：

```bash
kubectl -n kube-system rollout restart deployment coredns
```

## 安装helm

在这里下载helm：<https://github.com/helm/helm/releases>

下载完成后，将helm二进制程序放到`/usr/local/bin/`即可完成安装，playbook如下：

```bash
---
- name: install helm
  hosts: k8s
  tasks:
  - name: unarchive files to remote /tmp
    unarchive:
      src: helm-v3.14.0-linux-amd64.tar.gz
      dest: /tmp/
  - name: install helm
    copy:
      src: /tmp/linux-amd64/helm
      dest: /usr/local/bin/helm
      mode: 0755
      remote_src: yes
```

## 安装traefik
以下helm chart需要下载：

```
helm repo add traefik https://traefik.github.io/charts
helm pull traefik/traefik
```
创建并修改values：
```bash
helm show values traefik-27.0.2.tgz > values.yaml
```
修改image和imagePullSecrets后，创建namespace并部署：
```bash
kubectl create ns traefik
helm install --namespace traefik traefik traefik-27.0.2.tgz --values values.yaml
```
如果需要对外暴露dashboard，values.yaml还需要做如下修改：
```yaml
# Create an IngressRoute for the dashboard
ingressRoute:
  dashboard:
    enabled: true
    # Custom match rule with host domain
    matchRule: Host(`traefik-dashboard.example.com`)
    entryPoints: ["websecure"]
    # Add custom middlewares : authentication and redirection
    middlewares:
      - name: traefik-dashboard-auth

# Create the custom middlewares used by the IngressRoute dashboard (can also be created in another way).
# /!\ Yes, you need to replace "changeme" password with a better one. /!\
extraObjects:
  - apiVersion: v1
    kind: Secret
    metadata:
      name: traefik-dashboard-auth-secret
    type: kubernetes.io/basic-auth
    stringData:
      username: admin
      password: changeme

  - apiVersion: traefik.io/v1alpha1
    kind: Middleware
    metadata:
      name: traefik-dashboard-auth
    spec:
      basicAuth:
        secret: traefik-dashboard-auth-secret
```
将容器部署修改为3个：
```bash
kubectl -n traefik scale deployment traefik --replicas 3
```

查询 Traefik 的 NodePort 端口：

```bash
kubectl get svc -n traefik
```

```
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
traefik   LoadBalancer   10.96.103.221   <pending>     80:30795/TCP,443:32752/TCP   5d1h
```

这里 HTTP 端口 30795，HTTPS 端口 32752，配置负载均衡器的 80 端口转发到所有 k8s 节点 30795 端口，443 端口转发到所有 k8s 节点 32752 端口，负载模式为 TCP 轮询。如果使用的是在 k8s master 节点使用 static pod 方式安装 HAProxy 和 Keepalived 的方式，则需要修改 HAProxy 配置：

```cfg
frontend web
    bind *:80
    mode tcp
    option tcplog
    default_backend webbackend

backend webbackend
    mode tcp
    balance     roundrobin
        server k8s01 192.168.100.11:30795 check
        server k8s02 192.168.100.12:30795 check
        server k8s03 192.168.100.13:30795 check

frontend websecure
    bind *:443
    mode tcp
    option tcplog
    default_backend websecurebackend

backend websecurebackend
    mode tcp
    balance     roundrobin
        server k8s01 192.168.100.11:32752 check
        server k8s02 192.168.100.12:32752 check
        server k8s03 192.168.100.13:32752 check
```

static pod 重启必须使用 crictl 命令，首先找到 static pod 的容器 ID：

```bash
crictl ps | grep haproxy
```

```
a0b4e29a3ba18 6600fae04efde 3 minutes ago Running haproxy 2 5e3faac3ce66d haproxy-k8s01
```

然后停止容器：

```bash
crictl stop a0b4e29a3ba18
```

在停止容器后 kubelet 会自动将其重新拉起。

下载 <https://doc.traefik.io/traefik/getting-started/quick-start-with-kubernetes/> 的yaml文件`03-whoami.yml`、`03-whoami-services.yml`、`04-whoami-ingress.yml`，并应用：
```bash
kubectl apply -f 03-whoami.yml -f 03-whoami-services.yml -f 04-whoami-ingress.yml
```
容器起来以后检查：
```
# curl http://192.168.100.10/whoami/
Hostname: whoami-78994d7bf9-x7lzr
IP: 127.0.0.1
IP: ::1
IP: 172.18.209.24
IP: fe80::209c:b5ff:fefa:ca79
RemoteAddr: 172.18.209.20:41776
GET /whoami/ HTTP/1.1
Host: 192.168.100.10
User-Agent: curl/7.71.1
Accept: */*
Accept-Encoding: gzip
X-Forwarded-For: 192.168.100.11
X-Forwarded-Host: 192.168.100.10
X-Forwarded-Port: 80
X-Forwarded-Proto: http
X-Forwarded-Server: traefik-deployment-65547f8865-27d6x
X-Real-Ip: 192.168.100.11
```
测试middleware是否正常工作，修改`04-whoami-ingress.yml`如下：
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami-ingress
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
    traefik.ingress.kubernetes.io/router.middlewares: default-strip-prefix@kubernetescrd
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: whoami
            port:
              name: web
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
修改完成后应用yaml配置：
```bash
kubectl apply -f 04-whoami-ingress.yml
```
测试：
```
# curl http://192.168.100.10/whoami/
Hostname: whoami-8c9864b56-dms8j
IP: 127.0.0.1
IP: ::1
IP: 172.18.122.2
IP: fe80::e840:22ff:fe60:51e7
RemoteAddr: 172.18.209.2:41866
GET / HTTP/1.1
Host: 192.168.100.10
User-Agent: curl/7.61.1
Accept: */*
Accept-Encoding: gzip
X-Forwarded-For: 172.18.122.0
X-Forwarded-Host: 192.168.100.10
X-Forwarded-Port: 80
X-Forwarded-Prefix: /whoami
X-Forwarded-Proto: http
X-Forwarded-Server: traefik-858b7cfbcd-t4ltm
X-Real-Ip: 172.18.122.0
```
注意这里的`GET /whoami/ HTTP/1.1`变成了`GET / HTTP/1.1`，说明middleware生效。最后清理测试使用的资源：

```bash
kubectl delete -f 03-whoami.yml -f 03-whoami-services.yml -f 04-whoami-ingress.yml
```

## 安装metrics-server

在k8s上执行`kubectl top pods -A`报错`error: Metrics API not available`，需要安装metrics-server，首先下载以下容器镜像（可通过`helm install --dry-run metrics-server metrics-server-3.12.0.tgz | grep image:`命令查询）：

```
registry.k8s.io/metrics-server/metrics-server:v0.6.4
```

以下helm chart需要下载：

```
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm pull metrics-server/metrics-server
```

所有节点导入容器镜像：

```bash
ctr -n k8s.io image import metrics-server_v0.6.4.tar
```

在其中一个节点创建metrics-server：

```bash
kubectl create ns metrics-server
helm install --namespace metrics-server metrics-server metrics-server-3.11.0.tgz
```

创建之后，修改deployments配置：

```bash
kubectl -n metrics-server edit deployments.apps metrics-server
```

新增`- --kubelet-insecure-tls`配置，修改之后如下：

```bash
    spec:
      containers:
      - args:
        - --secure-port=10250
        - --cert-dir=/tmp
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
        image: registry.k8s.io/metrics-server/metrics-server:v0.6.4
```

修改之后轮询重启容器，并将容器修改为部署3个：

```bash
kubectl -n metrics-server rollout restart deployment metrics-server
kubectl -n metrics-server scale --replicas 3 deployment metrics-server
```

部署完成后检查资源状态：

```bash
# kubectl get all -n metrics-server
NAME                                  READY   STATUS    RESTARTS   AGE
pod/metrics-server-55f78d9d6f-4r98q   1/1     Running   0          32s
pod/metrics-server-55f78d9d6f-68t2q   1/1     Running   0          32s
pod/metrics-server-55f78d9d6f-cktdd   1/1     Running   0          102s

NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/metrics-server   ClusterIP   10.108.4.192   <none>        443/TCP   8m2s

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/metrics-server   3/3     3            3           8m2s

NAME                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/metrics-server-55f78d9d6f   3         3         3       102s
replicaset.apps/metrics-server-596d577f98   0         0         0       2m24s
replicaset.apps/metrics-server-5b76987ff    0         0         0       8m2s
```

之后执行`kubectl top pods -A`和`kubectl top nodes`不会报错。

## 安装ceph-csi并对接cephfs存储

### 下载介质

在可以通外网的机器上，安装helm，并使用以下命令下载helm chart：

```bash
helm repo add ceph-csi https://ceph.github.io/csi-charts
helm pull ceph-csi/ceph-csi-cephfs
```

下载之后的helm chart为tgz格式，还需要下载所有的容器镜像，使用以下命令列出此helm chart需要的所有容器镜像：

```bash
helm template ceph-csi-cephfs-3.10.1.tgz | grep 'image:'
```

以下为下载容器镜像示例：

```bash
ctr -n k8s.io image pull docker.io/library/haproxy:2.1.4
ctr -n k8s.io images export haproxy_2.1.4.tar docker.io/library/haproxy:2.1.4 --platform linux/amd64
```

### 新建cephfs和volume

在ceph服务器上，使用`cephadm shell`进入ceph命令行，并执行以下命令：

```bash
ceph fs volume create cephfs
ceph fs subvolumegroup create cephfs csi
```

执行以后检查：

```
# ceph fs volume ls
[
    {
        "name": "cephfs"
    }
]
# ceph fs subvolumegroup ls cephfs
[
    {
        "name": "csi"
    }
]
```

### ceph配置收集

在ceph节点上，收集ceph配置和admin的keyring：

```
# ceph config generate-minimal-conf
# minimal ceph.conf for 77488730-b4d9-11ee-bec7-fa163e3bb924
[global]
    fsid = 77488730-b4d9-11ee-bec7-fa163e3bb924
    mon_host = [v2:192.168.100.14:3300/0,v1:192.168.100.14:6789/0] [v2:192.168.100.15:3300/0,v1:192.168.100.15:6789/0] [v2:192.168.100.16:3300/0,v1:192.168.100.16:6789/0]
# ceph auth get client.admin
[client.admin]
    key = ********
    caps mds = "allow *"
    caps mgr = "allow *"
    caps mon = "allow *"
    caps osd = "allow *"
```

### 容器镜像导入

在所有k8s节点导入容器镜像：

```bash
ctr -n k8s.io image import cephcsi_v3.10.1.tar
ctr -n k8s.io image import csi-node-driver-registrar_v2.9.1.tar
ctr -n k8s.io image import csi-provisioner_v3.6.2.tar
ctr -n k8s.io image import csi-resizer_v1.9.2.tar
ctr -n k8s.io image import csi-snapshotter_v6.3.2.tar
```

### 创建values.YAML

首先生成values.YAML：

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

### 使用helm chart安装ceph-csi-cephfs

```bash
kubectl create namespace ceph-csi-cephfs
helm install --namespace "ceph-csi-cephfs" "ceph-csi-cephfs" ceph-csi-cephfs-3.10.1.tgz --values ./values.yaml
```

### 将ceph-csi-sc设置为默认storage class

```bash
kubectl patch storageclass ceph-csi-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### 创建pvc并测试

新建文件`test-pvc.yaml`：

```
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

创建pvc：

```
kubectl apply -f test-pvc.yaml
```

检查：

```
# kubectl get pvc
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE
test-pvc   Bound    pvc-9c92208e-cd5a-436a-a785-74b6dc00ae31   1Gi        RWX            csi-cephfs-sc   <unset>                 9m15s
```

如果要查询这个pvc对应的pv对应的cephfs存储位置：

```
kubectl get pv $(kubectl get pvc test-pvc -o jsonpath="{.spec.volumeName}") -o jsonpath='{.spec.csi.volumeAttributes.subvolumePath}';echo
```

清理：

```
kubectl delete -f testpvc.yaml
```

### 备注：在非k8s节点挂载cephfs的方法

在ceph客户端上需要安装ceph-fuse：

```
yum localinstall gperftools-libs-2.7-7.ky10.x86_64.rpm ceph-fuse-12.2.8-7.p02.ky10.x86_64.rpm
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

配置keyring：

```
cat > /etc/ceph/ceph.client.admin.keyring <<-'EOF'
[client.admin]
    key = **********
EOF
chmod 600 /etc/ceph/ceph.client.admin.keyring
```

如果要临时挂载，使用一下命令：

```bash
ceph-fuse -n client.admin /mnt/cephfs
```

如果要永久挂载，则配置`/etc/fstab`，加入以下行：

```
none	/mnt/cephfs	fuse.ceph	ceph.id=admin,_netdev	0	0
```

挂载cephfs：

```bash
mkdir -p /mnt/cephfs
mount /mnt/cephfs
```

# 参考链接

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

https://kubernetes.io/docs/setup/production-environment/container-runtimes/

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/

https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing

https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart

https://helm.sh/docs/intro/install/

https://stackoverflow.com/questions/50343089/how-to-use-helm-charts-without-internet-access

https://stackoverflow.com/questions/60892265/extract-docker-images-from-helm-chart

https://www.pivert.org/ceph-csi-on-kubernetes-1-24/

<https://doc.traefik.io/traefik/getting-started/install-traefik/#use-the-helm-chart>

<https://github.com/traefik/traefik-helm-chart/blob/master/EXAMPLES.md>
---

## 原文（English）

（本文原为中文撰写，无英文原文）
