---
tags:
  - Ceph
  - 银河麒麟V10
---

## 系统架构

本次安装的 Ceph 仅有 3 个节点，各个节点配置和用途如下：

| 节点名称 | IP 地址        | 服务器角色 | 配置要求 |
| -------- | -------------- | ---------- | -------- |
| ceph01   | 192.168.100.14 | Ceph 节点  | 4C8G     |
| ceph02   | 192.168.100.15 | Ceph 节点  | 4C8G     |
| ceph03   | 192.168.100.16 | Ceph 节点  | 4C8G     |

其中，所有的节点都需要配置 NTP 时钟同步服务器，且所有节点都需要有默认网关。同时，需要使用 Ansible 对这 3 个节点进行批量配置。

## 准备工作

### 安装前系统参数

所有节点均需要禁用 swap 、关闭 firewalld 防火墙与 SELinux ：

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

### Ansible 主机清单配置

本文使用 Ansible 来对节点进行批量操作，Ansible 主机清单配置如下：

```
[ceph]
192.168.100.14
192.168.100.15
192.168.100.16
```

### 介质下载

如果需要离线安装，需要额外准备一台可以通外网的机器来下载介质，此机器也需要禁用 swap 、关闭 firewalld 防火墙与 SELinux ，且至少需要安装 docker 。其中需要下载的二进制文件及配置文件如下：

| 介质名称                             | 下载地址                                                                        |
| ------------------------------------ | ------------------------------------------------------------------------------- |
| containerd-1.7.11-linux-amd64.tar.gz | https://github.com/containerd/containerd/releases                               |
| containerd.service                   | https://raw.githubusercontent.com/containerd/containerd/main/containerd.service |
| docker-24.0.7.tgz                    | https://download.docker.com/linux/static/stable/x86_64/                         |
| docker.service                       | https://github.com/moby/moby/blob/master/contrib/init/systemd/docker.service    |
| docker.socket                        | https://github.com/moby/moby/blob/master/contrib/init/systemd/docker.socket     |

需要下载的容器镜像如下：

| 镜像名称                                | 下载方式             |
| --------------------------------------- | -------------------- |
| quay.io/ceph/ceph:v18                   | 使用 docker 命令下载 |
| quay.io/ceph/ceph-grafana:9.4.7         | 使用 docker 命令下载 |
| quay.io/prometheus/prometheus:v2.43.0   | 使用 docker 命令下载 |
| quay.io/prometheus/alertmanager:v0.25.0 | 使用 docker 命令下载 |
| quay.io/prometheus/node-exporter:v1.5.0 | 使用 docker 命令下载 |
| registry:2                              | 使用 docker 命令下载 |

使用 docker 下载容器镜像的命令如下：

```
docker pull [镜像名称]
docker image save -i [镜像名称].tar
```

导入 docker 容器镜像命令如下：

```
docker image load -i [镜像名称].tar
```

## 安装 containerd 容器运行环境

所有的 ceph 节点都需要安装 containerd ，使用此 Ansible Playbook 进行批量安装：

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

## 安装 docker

所有的 ceph 节点都需要安装 docker ，使用此 Ansible Playbook 进行批量安装：

```yaml title="docker-install.yaml"
---
- name: install docker
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

## 安装 cephadm 和 ceph

使用以下 playbook 安装 ceph 和 cephadm：

```yaml
---
- name: install ceph
  hosts: ceph
  tasks:
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

## 配置 ceph01 节点

安装完成后，在 ceph01 节点，创建 ceph 集群：

```
source ~/.bashrc
cephadm bootstrap --mon-ip 192.168.100.14
```

之后使用`cephadm shell`命令进入 ceph 命令行（所有 ceph 命令均需要在 ceph 命令行执行），运行以下命令修改 ceph 相关容器使用本地镜像仓库：

```
ceph config set mgr mgr/cephadm/container_image_prometheus localhost:5000/prometheus/prometheus:v2.43.0
ceph config set mgr mgr/cephadm/container_image_node_exporter localhost:5000/prometheus/node-exporter:v1.5.0
ceph config set mgr mgr/cephadm/container_image_grafana localhost:5000/ceph/ceph-grafana:9.4.7
ceph config set mgr mgr/cephadm/container_image_alertmanager localhost:5000/prometheus/alertmanager:v0.25.0
```

重新部署 ceph 容器：

```
ceph orch redeploy prometheus
ceph orch redeploy node-exporter
ceph orch redeploy grafana
ceph orch redeploy alertmanager
```

验证：

```
ceph orch ls
```

```
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

将节点 ceph01 设置成管理节点：

```
ceph orch host label add ceph01 _admin
```

检查 ceph 所有节点：

```
ceph orch host ls
```

```
HOST    ADDR            LABELS  STATUS
ceph01  192.168.100.14  _admin
```

## 将其它节点加入 ceph 集群作为管理节点

在第一个节点上，将剩下两个节点加入 ceph 集群（以下命令不要在 ceph 命令行执行）：

```
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.100.15
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.100.16
cephadm shell -- ceph orch host add ceph02 192.168.100.15
cephadm shell -- ceph orch host label add ceph02 _admin
cephadm shell -- ceph orch host add ceph03 192.168.100.16
cephadm shell -- ceph orch host label add ceph03 _admin
```

将 monitor 部署在三个节点：

```
ceph orch apply mon --placement="ceph01,ceph02,ceph03"
```

如果三个节点在一个 B 段，但是不在一个 C 段，还需要额外运行这个命令修改 public_network 子网：

```
ceph config set mon public_network 192.168.0.0/16
```

完成以后，检查 ceph 主机列表：

```
ceph orch host ls
```

```
HOST    ADDR            LABELS  STATUS
ceph01  192.168.100.14  _admin
ceph02  192.168.100.15  _admin
ceph03  192.168.100.16  _admin
3 hosts in cluster
```

## 将磁盘加入 ceph

将三个机器的/dev/sdb 加入 ceph 集群：

```
ceph orch daemon add osd ceph01:/dev/sdb
ceph orch daemon add osd ceph02:/dev/sdb
ceph orch daemon add osd ceph03:/dev/sdb
```

## 检查 ceph 集群状态

```bash
ceph status
```

```
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
