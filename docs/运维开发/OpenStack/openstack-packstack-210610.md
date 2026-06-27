---
tags:
  - OpenStack
---

# Deploying OpenStack Cluster on CentOS 8  Stream with packstack


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

 ## 环境描述

需要 4 台可访问外网的 CentOS 8 Stream 服务器。下表描述了硬件需求。

| 角色             | 主机名   | IP 地址   | CPU    | 内存  | 磁盘  |
| ---------------- | ---------- | ------------ | ------ | ---- | ----- |
| Controller & NTP | controller | 192.168.8.10 | 2vCPUs | 10GB | 100GB |
| Compute          | compute0   | 192.168.8.20 | 4vCPUs | 4GB  | 200GB |
| Compute          | compute1   | 192.168.8.21 | 4vCPUs | 4GB  | 200GB |
| Network          | network    | 192.168.8.30 | 2vCPUs | 3GB  | 100GB |

网络配置如下

- 网关 IP 地址: **192.168.8.2**
- 子网地址: 192.168.8.0/24
- 可用 IP 地址: 192.168.8.50 - 150
- DNS 服务器: **192.168.8.2**

## 设置静态 IP 地址

在所有主机上

```bash
[root@192 ~]# nmcli connection modify ens160 ipv4.method manual ipv4.dns 192.168.8.2 ipv4.gateway 192.168.8.2 autoconnect yes ipv4.addresses <ip_addr>/24
[root@192 ~]# nmcli connection up ens160
```

## 配置主机名

编写 `/etc/hosts`

```
# Static table lookup for hostnames.
# See hosts(5) for details.
#
127.0.0.1    localhost
::1          localhost

192.168.8.10 controller ntp
192.168.8.20 compute0
192.168.8.21 compute1
192.168.8.30 network
```

将 `/etc/hosts` 分发到所有主机

```bash
for server in {controller,compute0,compute1,network};do scp /etc/hosts root@$server:/etc/hosts;done
```

设置主机名

```bash
for server in {controller,compute0,compute1,network};do ssh root@$server "hostnamectl set-hostname $server";done
```

## 禁用防火墙、SELinux、NetworkManager

在所有主机上

```bash
for server in {controller,compute0,compute1,network};do ssh root@$server "systemctl disable --now firewalld";done
for server in {controller,compute0,compute1,network};do ssh root@$server "systemctl mask firewalld";done
for server in {controller,compute0,compute1,network};do ssh root@$server "sed -i 's/SELINUX=enforcing/SELinux=disabled/' /etc/sysconfig/selinux";done
for server in {controller,compute0,compute1,network};do ssh root@$server "sed -i 's/SELINUX=enforcing/SELinux=disabled/' /etc/selinux/config";done
for server in {controller,compute0,compute1,network};do ssh root@$server "setenforce 0";done
for server in {controller,compute0,compute1,network};do ssh root@$server "dnf install -y network-scripts";done
for server in {controller,compute0,compute1,network};do ssh root@$server "systemctl disable --now NetworkManager";done
for server in {controller,compute0,compute1,network};do ssh root@$server "systemctl enable --now network";done
for server in {controller,compute0,compute1,network};do ssh root@$server "systemctl reboot";done
```

## 在 Controller 上启用 NTP

在 controller 上，编辑 `/etc/chrony.conf`

```bash
# Allow NTP client access from local network.
allow 192.168.8.0/24
```

在其他服务器上，编辑 `/etc/chrony.conf`

```
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
# pool 2.centos.pool.ntp.org iburst
pool ntp iburst
```

在所有主机上

```bash
systemctl enable --now chronyd.service
systemctl restart chronyd.service
```

验证

```bash
for server in {controller,compute0,compute1,network};do ssh root@$server "chronyc sources";done
```

## 安装 OpenStack 软件源

在所有 OpenStack 节点上

```bash
for server in {controller,compute0,compute1,network};do ssh root@$server "dnf config-manager --enable powertools";done
for server in {controller,compute0,compute1,network};do ssh root@$server "dnf remove -y epel-release";done
for server in {controller,compute0,compute1,network};do ssh root@$server "sudo dnf install -y https://www.rdoproject.org/repos/rdo-release.el8.rpm";done
# Not needed but rdo project recommend to install
# for server in {controller,compute01,compute02,network};do ssh root@$server "sudo dnf install -y centos-release-openstack-victoria";done
for server in {controller,compute0,compute1,network};do ssh root@$server "dnf -y update";done
```

## 安装 Packstack

在 controller 上

```bash
dnf install -y openstack-packstack
```

## 生成应答文件

在 controller 上

```bash
packstack \
--os-neutron-ml2-tenant-network-types=vxlan \
--os-neutron-l2-agent=openvswitch \
--os-neutron-ml2-type-drivers=vxlan,flat \
--os-neutron-ml2-mechanism-drivers=openvswitch \
--keystone-admin-passwd=redhat \
--nova-libvirt-virt-type=kvm \
--provision-demo=n \
--cinder-volumes-create=y \
--os-heat-install=y \
--os-swift-storage-size=20G \
--gen-answer-file /root/answers.txt
```

本例中，admin 密码设置为 `redhat`，编辑 `/root/answers.txt`

```
# Specify 'y' if you want to run OpenStack services in debug mode;
# otherwise, specify 'n'. ['y', 'n']
CONFIG_DEBUG_MODE=y

# Server on which to install OpenStack services specific to the
# controller role (for example, API servers or dashboard).
CONFIG_CONTROLLER_HOST=192.168.8.10

# List the servers on which to install the Compute service.
CONFIG_COMPUTE_HOSTS=192.168.8.20,192.168.8.21

# List of servers on which to install the network service such as
# Compute networking (nova network) or OpenStack Networking (neutron).
CONFIG_NETWORK_HOSTS=192.168.8.30
```

## 使用应答文件部署

在 **controller** 上

```bash
packstack --answer-file /root/answers.txt --timeout=6000
```

## 允许非管理员用户查看实例状态

在 **controller** 上，编辑 `/etc/nova/policy.json`，添加

```
"os_compute_api:os-extended-server-attributes": ""
```

另请参见 <https://docs.openstack.org/nova/latest/configuration/policy.html>

## 添加 bash 补全

在 **controller** 上

```bash
openstack complete | sudo tee /etc/bash_completion.d/osc.bash_completion > /dev/null
```

## 将网桥接入外部网络

在 **network** 节点上，编辑 `/etc/sysconfig/network-scripts/ifcfg-ens160`

```
TYPE=OVSPort
NAME=ens160
DEVICE=ens160
ONBOOT=yes
TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex
```

创建 `/etc/sysconfig/network-scripts/ifcfg-br-ex`

```
DEVICE=br-ex
BOOTPROTO=none
ONBOOT=yes
TYPE=OVSBridge
DEVICETYPE=ovs
USERCTL=yes
PEERDNS=yes
IPV6INIT=no
IPADDR=192.168.8.30
PREFIX=24
GATEWAY=192.168.8.2
DNS1=192.168.8.2
```

重启网络

```bash
systemctl restart network
```

## 修改 noVNC 地址

在所有 **compute** 节点上，编辑 `/etc/nova/nova.conf`

```
server_proxyclient_address=<compute_node_ip>
```

重启服务

```bash
systemctl restart openstack-nova-compute.service
```

## （仅限 AMD CPU）修复 libvirt 错误

如果你的 CPU 制造商是 AMD，可能会遇到以下错误（我是在所有 compute 节点上运行 `tail -f /var/log/nova/*.log` 时发现的）：

```
error: internal error: unknown feature amd-sev-es
```

在所有 compute 节点上运行以下命令来解决

```bash
mkdir -p /etc/qemu/firmware
touch /etc/qemu/firmware/50-edk2-ovmf-cc.json
```

另请参见: <https://serverfault.com/questions/1065246/virsh-reporting-unknown-feature-amd-sev-es>

## 测试部署

在 controller 上

```bash
source ~/keystonerc_admin
```

查看所有服务

```bash
openstack service list
```

创建私有网络

```bash
openstack network create private
```

为私有网络创建子网

```bash
openstack subnet create \
--network private \
--allocation-pool start=172.10.10.50,end=172.10.10.200 \
--dns-nameserver 223.5.5.5 \
--dns-nameserver 223.6.6.6 \
--subnet-range 172.10.10.0/24 private_subnet
```

创建公共网络

```bash
openstack network create \
--provider-network-type flat \
--provider-physical-network extnet \
--external public
```

为公共网络创建子网

```bash
openstack subnet create \
--network public \
--allocation-pool start=192.168.8.50,end=192.168.8.150 \
--no-dhcp \
--gateway 192.168.8.2 \
--dns-nameserver 192.168.8.2 \
--subnet-range 192.168.8.0/24 public_subnet
```

创建路由器

```bash
openstack router create private_router
```

添加路由器网关

```bash
openstack router set --external-gateway public private_router
```

将路由器关联到子网

```bash
openstack router add subnet private_router private_subnet
```

在 **network** 节点上，查看路由器信息，运行

```bash
ip netns show
```

检查连通性，运行

```bash
ip netns exec qrouter-<your_router_uuid_above> ping -c 1 baidu.com
```

在 controller 上，启动一个实例

```bash
mkdir images
cd images
wget http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img
```

上传镜像

```bash
openstack image create \
--disk-format qcow2 \
--container-format bare --public \
--file ./cirros-0.5.1-x86_64-disk.img "Cirros-0.5.1"
```

列出镜像

```bash
openstack image list
```

创建安全组

```bash
openstack security group create permit_all --description "Allow all ports"
openstack security group rule create --protocol TCP --dst-port 1:65535 --remote-ip 0.0.0.0/0 permit_all
openstack security group rule create --protocol ICMP --remote-ip 0.0.0.0/0 permit_all
```

列出安全组

```bash
openstack security group list
```

上传 SSH 密钥

```bash
openstack keypair create --public-key ~/.ssh/id_rsa.pub admin
```

列出 SSH 密钥

```bash
openstack keypair list
```

列出规格

```bash
openstack flavor list
```

启动实例

```bash
openstack server create \
--flavor m1.tiny \
--image "Cirros-0.5.1" \
--network private \
--key-name admin \
--security-group permit_all \
mycirros
```

列出所有服务器

```bash
openstack server list
```

分配浮动 IP

```bash
openstack floating ip create public
```

列出所有浮动 IP

```bash
openstack floating ip list
```

将浮动 IP 分配给实例

```bash
openstack server add floating ip mycirros <floating_ip>
```

登录到实例

```bash
ssh cirros@<floating_ip>
```

---

## 原文（English）

# Deploying OpenStack Cluster on CentOS 8  Stream with packstack


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

 ## Environment Description

4 CentOS 8 Stream with external network access is needed. The following table describes the hardware requirements.

| Role             | hostname   | IP address   | CPU    | RAM  | Disk  |
| ---------------- | ---------- | ------------ | ------ | ---- | ----- |
| Controller & NTP | controller | 192.168.8.10 | 2vCPUs | 10GB | 100GB |
| Compute          | compute0   | 192.168.8.20 | 4vCPUs | 4GB  | 200GB |
| Compute          | compute1   | 192.168.8.21 | 4vCPUs | 4GB  | 200GB |
| Network          | network    | 192.168.8.30 | 2vCPUs | 3GB  | 100GB |

Network configuration is described below

- Gateway IP Address: **192.168.8.2**
- Subnet Address: 192.168.8.0/24
- Available IP Address: 192.168.8.50 - 150
- DNS Server: **192.168.8.2**

## Set Static IP Address

On all hosts

```bash
[root@192 ~]# nmcli connection modify ens160 ipv4.method manual ipv4.dns 192.168.8.2 ipv4.gateway 192.168.8.2 autoconnect yes ipv4.addresses <ip_addr>/24
[root@192 ~]# nmcli connection up ens160
```

## Configure Hostname

Write `/etc/hosts`

```
# Static table lookup for hostnames.
# See hosts(5) for details.
#
127.0.0.1    localhost
::1          localhost

192.168.8.10 controller ntp
192.168.8.20 compute0
192.168.8.21 compute1
192.168.8.30 network
```

Distribute `/etc/hosts` to all hosts

```bash
for server in {controller,compute0,compute1,network};do scp /etc/hosts root@$server:/etc/hosts;done
```

Set hostname

```bash
for server in {controller,compute0,compute1,network};do ssh root@$server "hostnamectl set-hostname $server";done
```

## Disable Firewall, SELinux, NetworkManager

On all hosts

```bash
for server in {controller,compute0,compute1,network};do ssh root@$server "systemctl disable --now firewalld";done
for server in {controller,compute0,compute1,network};do ssh root@$server "systemctl mask firewalld";done
for server in {controller,compute0,compute1,network};do ssh root@$server "sed -i 's/SELINUX=enforcing/SELinux=disabled/' /etc/sysconfig/selinux";done
for server in {controller,compute0,compute1,network};do ssh root@$server "sed -i 's/SELINUX=enforcing/SELinux=disabled/' /etc/selinux/config";done
for server in {controller,compute0,compute1,network};do ssh root@$server "setenforce 0";done
for server in {controller,compute0,compute1,network};do ssh root@$server "dnf install -y network-scripts";done
for server in {controller,compute0,compute1,network};do ssh root@$server "systemctl disable --now NetworkManager";done
for server in {controller,compute0,compute1,network};do ssh root@$server "systemctl enable --now network";done
for server in {controller,compute0,compute1,network};do ssh root@$server "systemctl reboot";done
```

## Enable NTP on Controller

On controller, edit `/etc/chrony.conf`

```bash
# Allow NTP client access from local network.
allow 192.168.8.0/24
```

On other servers, edit `/etc/chrony.conf`

```
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
# pool 2.centos.pool.ntp.org iburst
pool ntp iburst
```

On all hosts

```bash
systemctl enable --now chronyd.service
systemctl restart chronyd.service
```

Verify

```bash
for server in {controller,compute0,compute1,network};do ssh root@$server "chronyc sources";done
```

## Install OpenStack Repository

On all OpenStack attenders

```bash
for server in {controller,compute0,compute1,network};do ssh root@$server "dnf config-manager --enable powertools";done
for server in {controller,compute0,compute1,network};do ssh root@$server "dnf remove -y epel-release";done
for server in {controller,compute0,compute1,network};do ssh root@$server "sudo dnf install -y https://www.rdoproject.org/repos/rdo-release.el8.rpm";done
# Not needed but rdo project recommend to install
# for server in {controller,compute01,compute02,network};do ssh root@$server "sudo dnf install -y centos-release-openstack-victoria";done
for server in {controller,compute0,compute1,network};do ssh root@$server "dnf -y update";done
```

## Install Packstack

On controller

```bash
dnf install -y openstack-packstack
```

## Generate answer file

On controller

```bash
packstack \
--os-neutron-ml2-tenant-network-types=vxlan \
--os-neutron-l2-agent=openvswitch \
--os-neutron-ml2-type-drivers=vxlan,flat \
--os-neutron-ml2-mechanism-drivers=openvswitch \
--keystone-admin-passwd=redhat \
--nova-libvirt-virt-type=kvm \
--provision-demo=n \
--cinder-volumes-create=y \
--os-heat-install=y \
--os-swift-storage-size=20G \
--gen-answer-file /root/answers.txt
```

in this case, admin password is set to `redhat`, Edit `/root/answers.txt`

```
# Specify 'y' if you want to run OpenStack services in debug mode;
# otherwise, specify 'n'. ['y', 'n']
CONFIG_DEBUG_MODE=y

# Server on which to install OpenStack services specific to the
# controller role (for example, API servers or dashboard).
CONFIG_CONTROLLER_HOST=192.168.8.10

# List the servers on which to install the Compute service.
CONFIG_COMPUTE_HOSTS=192.168.8.20,192.168.8.21

# List of servers on which to install the network service such as
# Compute networking (nova network) or OpenStack Networking (neutron).
CONFIG_NETWORK_HOSTS=192.168.8.30
```

## Deploy with answer file

on **controller**

```bash
packstack --answer-file /root/answers.txt --timeout=6000
```

## Permit Non-admin User to View Instance Status

on **controller**, edit `/etc/nova/policy.json`, add

```
"os_compute_api:os-extended-server-attributes": ""
```

See also <https://docs.openstack.org/nova/latest/configuration/policy.html>

## Add bash-completion

on **controller**

```bash
openstack complete | sudo tee /etc/bash_completion.d/osc.bash_completion > /dev/null
```

## Bridge Network to External

on **network** node, edit `/etc/sysconfig/network-scripts/ifcfg-ens160`

```
TYPE=OVSPort
NAME=ens160
DEVICE=ens160
ONBOOT=yes
TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex
```

create `/etc/sysconfig/network-scripts/ifcfg-br-ex`

```
DEVICE=br-ex
BOOTPROTO=none
ONBOOT=yes
TYPE=OVSBridge
DEVICETYPE=ovs
USERCTL=yes
PEERDNS=yes
IPV6INIT=no
IPADDR=192.168.8.30
PREFIX=24
GATEWAY=192.168.8.2
DNS1=192.168.8.2
```

restart network

```bash
systemctl restart network
```

## Modify noVNC Address

on all **compute node**s, edit `/etc/nova/nova.conf`

```
server_proxyclient_address=<compute_node_ip>
```

restart service

```bash
systemctl restart openstack-nova-compute.service
```

## (AMD CPU only) Fix a libvirt bug

If your CPU's manufacturer is AMD, you might encounter this error (I found it by running `tail -f /var/log/nova/*.log` on all compute nodes):

```
error: internal error: unknown feature amd-sev-es
```

run these command on all compute nodes to solve it

```bash
mkdir -p /etc/qemu/firmware
touch /etc/qemu/firmware/50-edk2-ovmf-cc.json
```

See also: <https://serverfault.com/questions/1065246/virsh-reporting-unknown-feature-amd-sev-es>

## Test the deployment

on controller

```bash
source ~/keystonerc_admin
```

see all services

```bash
openstack service list
```

create private network

```bash
openstack network create private
```

create subnet for private network

```bash
openstack subnet create \
--network private \
--allocation-pool start=172.10.10.50,end=172.10.10.200 \
--dns-nameserver 223.5.5.5 \
--dns-nameserver 223.6.6.6 \
--subnet-range 172.10.10.0/24 private_subnet
```

create public network

```bash
openstack network create \
--provider-network-type flat \
--provider-physical-network extnet \
--external public
```

create subnet for public network

```bash
openstack subnet create \
--network public \
--allocation-pool start=192.168.8.50,end=192.168.8.150 \
--no-dhcp \
--gateway 192.168.8.2 \
--dns-nameserver 192.168.8.2 \
--subnet-range 192.168.8.0/24 public_subnet
```

create a router

```bash
openstack router create private_router
```

add router gateway

```bash
openstack router set --external-gateway public private_router
```

link router to subnet

```bash
openstack router add subnet private_router private_subnet
```

on **network** node, to show router information, run

```bash
ip netns show
```

to check connectivity, run

```bash
ip netns exec qrouter-<your_router_uuid_above> ping -c 1 baidu.com
```

on controller, fire up an instance

```bash
mkdir images
cd images
wget http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img
```

upload image

```bash
openstack image create \
--disk-format qcow2 \
--container-format bare --public \
--file ./cirros-0.5.1-x86_64-disk.img "Cirros-0.5.1"
```

list images

```bash
openstack image list
```

create a security group

```bash
openstack security group create permit_all --description "Allow all ports"
openstack security group rule create --protocol TCP --dst-port 1:65535 --remote-ip 0.0.0.0/0 permit_all
openstack security group rule create --protocol ICMP --remote-ip 0.0.0.0/0 permit_all
```

list security group

```bash
openstack security group list
```

upload a ssh key

```bash
openstack keypair create --public-key ~/.ssh/id_rsa.pub admin
```

list ssh keys

```bash
openstack keypair list
```

list flavors

```bash
openstack flavor list
```

launch instance

```bash
openstack server create \
--flavor m1.tiny \
--image "Cirros-0.5.1" \
--network private \
--key-name admin \
--security-group permit_all \
mycirros
```

list all servers

```bash
openstack server list
```

allocate a floating IP

```bash
openstack floating ip create public
```

list all floating IPs

```bash
openstack floating ip list
```

assign floating IP to instance

```bash
openstack server add floating ip mycirros <floating_ip>
```

shell into instance

```bash
ssh cirros@<floating_ip>
```
