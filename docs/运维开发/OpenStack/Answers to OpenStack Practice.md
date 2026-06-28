---
tags:
  - OpenStack
---

# OpenStack 练习答案


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Answers to OpenStack Practice

## 练习前准备

将系统时间调整为 2020/06/25

```
[kiosk@foundation0 ~]$ su
Password: Asimov
[root@foundation0 kiosk]# date --set 2020/06/25
[root@foundation0 kiosk]# exit
[kiosk@foundation0 ~]$ rht-vmctl reset classroom
[kiosk@foundation0 ~]$ rht-vmctl fullreset all
```

## UnderCloud 操作

```
(undercloud) [stack@director ~]$ openstack subnet list
(undercloud) [stack@director ~]$ openstack subnet show management_subnet
```

## OverCloud 操作

```
(undercloud) [stack@director ~]$ ssh root@controller0 ovs-vsctl list-ports br-int
```

## 轮换 Fernet 密钥

访问 <http://content.example.com/rhosp13.0/x86_64/dvd/docs/>，搜索 "fernet"。

## 查找 Redis 密码

```
(undercloud) [stack@director ~]$ ssh root@controller0
[root@controller0 ~]# grep requirepass "/var/lib/config-data/puppet-generated/redis/etc/redis.conf"
[root@controller0 ~]# exit
```

## 创建用户

```
(undercloud) [stack@director ~]$ source overcloudrc
```

```
(overcloud) [stack@director ~]$ openstack domain create 210Demo
(overcloud) [stack@director ~]$ openstack project create Engineering --domain 210Demo
(overcloud) [stack@director ~]$ openstack project create Production --domain 210Demo
(overcloud) [stack@director ~]$ openstack group create --domain 210Demo Devops
```

```
(overcloud) [stack@director ~]$ openstack user create --domain 210Demo --project-domain 210Demo --password redhat --project Engineering --email Robert@lab.example.com Robert
(overcloud) [stack@director ~]$ openstack user create --domain 210Demo --project-domain 210Demo --password redhat --project Engineering --email George@lab.example.com George
(overcloud) [stack@director ~]$ openstack user create --domain 210Demo --project-domain 210Demo --password redhat --project Production --email William@lab.example.com William
(overcloud) [stack@director ~]$ openstack user create --domain 210Demo --project-domain 210Demo --password redhat --project Production --email John@lab.example.com John
```


```
(overcloud) [stack@director ~]$ openstack group add user --user-domain 210Demo --group-domain 210Demo Devops Robert
(overcloud) [stack@director ~]$ openstack group add user --user-domain 210Demo --group-domain 210Demo Devops George
(overcloud) [stack@director ~]$ openstack group add user --user-domain 210Demo --group-domain 210Demo Devops William
(overcloud) [stack@director ~]$ openstack group add user --user-domain 210Demo --group-domain 210Demo Devops John
```

```
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210D
emo --project Engineering --user Robert admin
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210Demo --project Engineering --user Robert _member_
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210Demo --project Engineering --user George _member_
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210Demo --project Production --user William admin
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210Demo --project Production --user William _member_
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210Demo --project Production --user John _member_
```

## 创建资源

```
(undercloud) [stack@director ~]$ ssh root@controller0
```

```
[root@controller0 ~]# vim /var/lib/config-data/puppet-generated/horizon/etc/openstack-dashboard/local_settings
```

```
# Set this to True if running on multi-domain model. When this is enabled, it
# will require user to enter the Domain name in addition to username for login.
#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
```

```
[root@controller0 ~]# vim /var/lib/config-data/puppet-generated/keystone/etc/keystone/keystone.conf
```

```
# A subset (or all) of domains can have their own identity driver, each with
# their own partial configuration options, stored in either the resource
# backend or in a file in a domain configuration directory (depending on the
# setting of `[identity] domain_configurations_from_database`). Only values
# specific to the domain need to be specified in this manner. This feature is
# disabled by default, but may be enabled by default in a future release; set
# to true to enable. (boolean value)
#domain_specific_drivers_enabled = false
domain_specific_drivers_enabled=True
```

```
[root@controller0 ~]# docker restart keystone
[root@controller0 ~]# docker restart horizon
```

```
[root@controller0 ~]# exit
```

```
(overcloud) [stack@director ~]$ cp overcloudrc robertrc
(overcloud) [stack@director ~]$ vim robertrc
(overcloud) [stack@director ~]$ source robertrc
```

```
(overcloud) [stack@director ~]$ openstack flavor create --public --ram 1024 --vcpus 1 --disk 10 m1.petite
```

```
(overcloud) [stack@director ~]$ wget http://materials.example.com/osp-small.qcow2
(overcloud) [stack@director ~]$ openstack image create --disk-format qcow2 --public --file osp-small.qcow2 web
```

```
(overcloud) [stack@director ~]$ openstack security group create ssh
(overcloud) [stack@director ~]$ openstack security group create web
(overcloud) [stack@director ~]$ openstack security group rule create --ingress --protocol icmp ssh
(overcloud) [stack@director ~]$ openstack security group rule create --ingress --protocol tcp --dst-port 22 ssh
(overcloud) [stack@director ~]$ openstack security group rule create --ingress --protocol tcp --dst-port 80 web
```

```
(overcloud) [stack@director ~]$ openstack keypair create webkey > /home/stack/webkey.pem
(overcloud) [stack@director ~]$ chmod 600 /home/stack/webkey.pem
```

## 创建网络

```
(overcloud) [stack@director ~]$ source robertrc
```

```
(overcloud) [stack@director ~]$ openstack network create engnet
(overcloud) [stack@director ~]$ openstack subnet create --subnet-range 192.168.101.0/24 --dhcp --network engnet engsubnet
```

```
(overcloud) [stack@director ~]$ openstack network create --provider-network-type flat --provider-physical-network datacentre --external public
(overcloud) [stack@director ~]$ ssh root@controller0 cat /etc/resolv.conf;route -n
(overcloud) [stack@director ~]$ openstack subnet create --network public --subnet-range 172.25.250.0/24 --allocation-pool start=172.25.250.101,end=172.25.250.109 --no-dhcp --dns-nameserver 172.25.250.254 --gateway 172.25.250.254 external
```

```
(overcloud) [stack@director ~]$ ssh root@controller0
[root@controller0 ~]# grep storage /var/lib/config-data/puppet-generated/neutron/etc/neutron/plugins/ml2/ml2_conf.ini
[root@controller0 ~]# exit
```

```
(overcloud) [stack@director ~]$ openstack network create --external --provider-network-type vlan --provider-segment 30 --provider-physical-network storage storagenet
(overcloud) [stack@director ~]$ openstack subnet create --subnet-range 172.24.3.0/24 --allocation-pool start=172.24.3.200,end=172.24.3.220 --dhcp --network storagenet storage-subnet
```

```
(overcloud) [stack@director ~]$ openstack router create 210-router
(overcloud) [stack@director ~]$ openstack router set --external-gateway public 210-router
(overcloud) [stack@director ~]$ openstack router add subnet 210-router engsubnet
```

## 运行实例

```
(overcloud) [stack@director ~]$ mkdir files
(overcloud) [stack@director ~]$ vim  files/cloud-init.sh
```

```
#!/usr/bin/bash
HOSTNAME=$(hostname -s)
yum -y install httpd
yum -y install python2-openstackclient
echo "Hello OpenStack" > /var/www/html/index.html
systemctl enable httpd --now
```

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack server create --image web --flavor m1.petite --network engnet --security-group ssh --security-group web --key-name webkey --user-data files/cloud-init.sh webserver
```

```
(overcloud) [stack@director ~]$ openstack floating ip create public
(overcloud) [stack@director ~]$ openstack server add floating ip webserver 172.25.250.108
```

```
(overcloud) [stack@director ~]$ ping 172.25.250.108
(overcloud) [stack@director ~]$ ssh -i webkey.pem cloud-user@172.25.250.108
[cloud-user@webserver ~]$ exit
[cloud-user@webserver ~]$ curl http://172.25.250.108/
```

## 创建卷

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack volume create --size 2 storage
```

## 挂载卷

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack server add volume webserver storage
```

## 创建卷快照

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack server remove volume webserver storage
(overcloud) [stack@director ~]$ openstack volume snapshot create storage
(overcloud) [stack@director ~]$ openstack server add volume webserver storage
```

## 创建 Heat 栈

参见工作手册第 420 页

## 编辑镜像

```
(undercloud) [stack@director ~]$ wget http://materials.example.com/osp-small.qcow2
(undercloud) [stack@director ~]$ sudo yum install -y guestfish
(undercloud) [stack@director ~]$ guestfish -i --network -a osp-small.qcow2
><fs> command "yum install -y httpd"
><fs> touch /var/www/html/index.html
><fs> vi /var/www/html/index.html
><fs> command "systemctl enable httpd"
><fs> command "useradd testuser"
><fs> selinux-relabel /etc/selinux/targeted/contexts/files/file_contexts /
><fs> exit
```

```
(undercloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack image create --min-ram 1024 --min-disk 10 --disk-format qcow2 --file osp-small.qcow2 webserver
```

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack flavor create --ram 1024 --disk 10 m1.web
(overcloud) [stack@director ~]$ openstack keypair create east > /home/stack/hello.pem
(overcloud) [stack@director ~]$ chmod 600 /home/stack/hello.pem
(overcloud) [stack@director ~]$ openstack server create --flavor m1.web --image webserver --key-name east --network engnet --security-group ssh --security-group web custom-web-server
(overcloud) [stack@director ~]$ openstack floating ip create public
(overcloud) [stack@director ~]$ openstack server add floating ip custom-web-server 172.25.250.106
(overcloud) [stack@director ~]$ ping 172.25.250.106
(overcloud) [stack@director ~]$ ssh -i /home/stack/hello.pem cloud-user@172.25.250.106 id testuser
(undercloud) [stack@director ~]$ curl 172.25.250.106
```

## 添加 RabbitMQ 用户

```
(undercloud) [stack@director ~]$ ssh root@controller0
[root@controller0 ~]# docker exec -it rabbitmq-bundle-docker-0 /bin/bash
()[root@controller0 /]# rabbitmqctl add_user test redhat
()[root@controller0 /]# rabbitmqctl set_permissions test ".*" ".*" ".*"
()[root@controller0 /]# rabbitmqctl set_user_tags test administrator
()[root@controller0 /]# rabbitmqctl trace_on
()[root@controller0 /]# exit
[root@controller0 ~]# exit
```

## 创建 Swift 容器

```
(undercloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ cd /tmp/
(overcloud) [stack@director tmp]$ tar zcvf etc.tar.gz /etc
(overcloud) [stack@director tmp]$ openstack container create warehouse
(overcloud) [stack@director tmp]$ openstack object create warehouse etc.tar.gz
```

```
(overcloud) [stack@director tmp]$ scp -i /home/stack/webkey.pem /home/stack/robertrc cloud-user@172.25.250.108:~
(overcloud) [stack@director tmp]$ ssh -i /home/stack/webkey.pem cloud-user@172.25.250.108
[cloud-user@custom-web-server ~]$ source robertrc
(overcloud) [cloud-user@webserver ~]$ openstack object list warehouse
(overcloud) [cloud-user@webserver ~]$ openstack object save warehouse etc.tar.gz
(overcloud) [cloud-user@webserver ~]$ exit
```

## 检查网络命名空间

```
(undercloud) [stack@director ~]$ ssh root@compute1
[root@compute1 ~]# ip netns list
[root@compute1 ~]# exit
```

## 配置 Manila 共享

```
(undercloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ manila type-create cephfstype false
(overcloud) [stack@director ~]$ manila create --name engineering_share --share-type cephfstype cephfs 1
(undercloud) [stack@director ~]$ ssh root@controller0
[root@controller0 ~]# ceph auth get-or-create --name=client.manila --keyring=/etc/ceph/ceph.client.manila.keyring client.cloud-user > /root/cloud-user.keyring
[root@controller0 ~]# exit
(overcloud) [stack@director ~]$ manila access-allow engineering_share cephx cloud-user
```

## 挂载 Manila 文件系统

```
(undercloud) [stack@director ~]$ vim files/manila.sh
```

```
#!/usr/bin/bash
cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<eof
DEVICE=eth1
BOOTPROTO=dhcp
ONBOOT=yes
eof

ifup eth1
curl -s -f -o /etc/yum.repos.d/ceph.repo http://materials.example.com/ceph.repo
yum install -y ceph-fuse
```

```
(undercloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack server create --image web --flavor m1.petite --security-group ssh --security-group web --key-name webkey --user-data files/manila.sh --network engnet --network storagenet eng_server1
(overcloud) [stack@director ~]$ openstack floating ip create public
(overcloud) [stack@director ~]$ openstack server add floating ip eng_server1 172.25.250.105
```

```
(overcloud) [stack@director ~]$ scp /home/stack/webkey.pem root@controller0:~
(overcloud) [stack@director ~]$ ssh root@controller0
[root@controller0 ~]# scp -i webkey.pem /etc/ceph/ceph.conf cloud-user@172.25.250.105:~
[root@controller0 ~]# scp -i webkey.pem /root/cloud-user.keyring cloud-user@172.25.250.105:~
[root@controller0 ~]# exit
```

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ manila share-export-location-list engineering_share
```

```
(overcloud) [stack@director ~]$ ssh -i /home/stack/webkey.pem cloud-user@172.25.250.105
[cloud-user@eng-server1 ~]$ sudo mkdir /mnt/ceph
[cloud-user@eng-server1 ~]$ sudo -i
[root@eng-server1 ~]# ceph-fuse --conf=/home/cloud-user/ceph.conf --name=client.cloud-user --keyring=/home/cloud-user/cloud-user.keyring --client-mountpoint=/volumes/_nogroup/308d8da3-f29d-4aad-8ba8-12cb00969c0f /mnt/ceph
[root@eng-server1 ceph]# exit
[cloud-user@eng-server1 ~]$ exit
```

---

## 原文（English）

# Answers to OpenStack Practice


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Before Practice

Change your time to 2020/06/25

```
[kiosk@foundation0 ~]$ su
Password: Asimov
[root@foundation0 kiosk]# date --set 2020/06/25
[root@foundation0 kiosk]# exit
[kiosk@foundation0 ~]$ rht-vmctl reset classroom
[kiosk@foundation0 ~]$ rht-vmctl fullreset all
```

## Operating on UnderCloud

```
(undercloud) [stack@director ~]$ openstack subnet list
(undercloud) [stack@director ~]$ openstack subnet show management_subnet
```

## Operating on OverCloud

```
(undercloud) [stack@director ~]$ ssh root@controller0 ovs-vsctl list-ports br-int
```

## Rotate Fernet Keys

Visit <http://content.example.com/rhosp13.0/x86_64/dvd/docs/>, search for "fernet".

## Find Redis Password

```
(undercloud) [stack@director ~]$ ssh root@controller0
[root@controller0 ~]# grep requirepass "/var/lib/config-data/puppet-generated/redis/etc/redis.conf"
[root@controller0 ~]# exit
```

## Create Users

```
(undercloud) [stack@director ~]$ source overcloudrc
```

```
(overcloud) [stack@director ~]$ openstack domain create 210Demo
(overcloud) [stack@director ~]$ openstack project create Engineering --domain 210Demo
(overcloud) [stack@director ~]$ openstack project create Production --domain 210Demo
(overcloud) [stack@director ~]$ openstack group create --domain 210Demo Devops
```

```
(overcloud) [stack@director ~]$ openstack user create --domain 210Demo --project-domain 210Demo --password redhat --project Engineering --email Robert@lab.example.com Robert
(overcloud) [stack@director ~]$ openstack user create --domain 210Demo --project-domain 210Demo --password redhat --project Engineering --email George@lab.example.com George
(overcloud) [stack@director ~]$ openstack user create --domain 210Demo --project-domain 210Demo --password redhat --project Production --email William@lab.example.com William
(overcloud) [stack@director ~]$ openstack user create --domain 210Demo --project-domain 210Demo --password redhat --project Production --email John@lab.example.com John
```


```
(overcloud) [stack@director ~]$ openstack group add user --user-domain 210Demo --group-domain 210Demo Devops Robert
(overcloud) [stack@director ~]$ openstack group add user --user-domain 210Demo --group-domain 210Demo Devops George
(overcloud) [stack@director ~]$ openstack group add user --user-domain 210Demo --group-domain 210Demo Devops William
(overcloud) [stack@director ~]$ openstack group add user --user-domain 210Demo --group-domain 210Demo Devops John
```

```
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210D
emo --project Engineering --user Robert admin
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210Demo --project Engineering --user Robert _member_
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210Demo --project Engineering --user George _member_
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210Demo --project Production --user William admin
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210Demo --project Production --user William _member_
(overcloud) [stack@director ~]$ openstack role add --user-domain 210Demo --project-domain 210Demo --project Production --user John _member_
```

## Create Resources

```
(undercloud) [stack@director ~]$ ssh root@controller0
```

```
[root@controller0 ~]# vim /var/lib/config-data/puppet-generated/horizon/etc/openstack-dashboard/local_settings
```

```
# Set this to True if running on multi-domain model. When this is enabled, it
# will require user to enter the Domain name in addition to username for login.
#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
```

```
[root@controller0 ~]# vim /var/lib/config-data/puppet-generated/keystone/etc/keystone/keystone.conf
```

```
# A subset (or all) of domains can have their own identity driver, each with
# their own partial configuration options, stored in either the resource
# backend or in a file in a domain configuration directory (depending on the
# setting of `[identity] domain_configurations_from_database`). Only values
# specific to the domain need to be specified in this manner. This feature is
# disabled by default, but may be enabled by default in a future release; set
# to true to enable. (boolean value)
#domain_specific_drivers_enabled = false
domain_specific_drivers_enabled=True
```

```
[root@controller0 ~]# docker restart keystone
[root@controller0 ~]# docker restart horizon
```

```
[root@controller0 ~]# exit
```

```
(overcloud) [stack@director ~]$ cp overcloudrc robertrc
(overcloud) [stack@director ~]$ vim robertrc
(overcloud) [stack@director ~]$ source robertrc
```

```
(overcloud) [stack@director ~]$ openstack flavor create --public --ram 1024 --vcpus 1 --disk 10 m1.petite
```

```
(overcloud) [stack@director ~]$ wget http://materials.example.com/osp-small.qcow2
(overcloud) [stack@director ~]$ openstack image create --disk-format qcow2 --public --file osp-small.qcow2 web
```

```
(overcloud) [stack@director ~]$ openstack security group create ssh
(overcloud) [stack@director ~]$ openstack security group create web
(overcloud) [stack@director ~]$ openstack security group rule create --ingress --protocol icmp ssh
(overcloud) [stack@director ~]$ openstack security group rule create --ingress --protocol tcp --dst-port 22 ssh
(overcloud) [stack@director ~]$ openstack security group rule create --ingress --protocol tcp --dst-port 80 web
```

```
(overcloud) [stack@director ~]$ openstack keypair create webkey > /home/stack/webkey.pem
(overcloud) [stack@director ~]$ chmod 600 /home/stack/webkey.pem
```

## Create Network

```
(overcloud) [stack@director ~]$ source robertrc
```

```
(overcloud) [stack@director ~]$ openstack network create engnet
(overcloud) [stack@director ~]$ openstack subnet create --subnet-range 192.168.101.0/24 --dhcp --network engnet engsubnet
```

```
(overcloud) [stack@director ~]$ openstack network create --provider-network-type flat --provider-physical-network datacentre --external public
(overcloud) [stack@director ~]$ ssh root@controller0 cat /etc/resolv.conf;route -n
(overcloud) [stack@director ~]$ openstack subnet create --network public --subnet-range 172.25.250.0/24 --allocation-pool start=172.25.250.101,end=172.25.250.109 --no-dhcp --dns-nameserver 172.25.250.254 --gateway 172.25.250.254 external
```

```
(overcloud) [stack@director ~]$ ssh root@controller0
[root@controller0 ~]# grep storage /var/lib/config-data/puppet-generated/neutron/etc/neutron/plugins/ml2/ml2_conf.ini
[root@controller0 ~]# exit
```

```
(overcloud) [stack@director ~]$ openstack network create --external --provider-network-type vlan --provider-segment 30 --provider-physical-network storage storagenet
(overcloud) [stack@director ~]$ openstack subnet create --subnet-range 172.24.3.0/24 --allocation-pool start=172.24.3.200,end=172.24.3.220 --dhcp --network storagenet storage-subnet
```

```
(overcloud) [stack@director ~]$ openstack router create 210-router
(overcloud) [stack@director ~]$ openstack router set --external-gateway public 210-router
(overcloud) [stack@director ~]$ openstack router add subnet 210-router engsubnet
```

## Run Instance

```
(overcloud) [stack@director ~]$ mkdir files
(overcloud) [stack@director ~]$ vim  files/cloud-init.sh
```

```
#!/usr/bin/bash
HOSTNAME=$(hostname -s)
yum -y install httpd
yum -y install python2-openstackclient
echo "Hello OpenStack" > /var/www/html/index.html
systemctl enable httpd --now
```

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack server create --image web --flavor m1.petite --network engnet --security-group ssh --security-group web --key-name webkey --user-data files/cloud-init.sh webserver
```

```
(overcloud) [stack@director ~]$ openstack floating ip create public
(overcloud) [stack@director ~]$ openstack server add floating ip webserver 172.25.250.108
```

```
(overcloud) [stack@director ~]$ ping 172.25.250.108
(overcloud) [stack@director ~]$ ssh -i webkey.pem cloud-user@172.25.250.108
[cloud-user@webserver ~]$ exit
[cloud-user@webserver ~]$ curl http://172.25.250.108/
```

## Create Volume

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack volume create --size 2 storage
```

## Attach Volume

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack server add volume webserver storage
```

## Create Volume Snapshot

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack server remove volume webserver storage
(overcloud) [stack@director ~]$ openstack volume snapshot create storage
(overcloud) [stack@director ~]$ openstack server add volume webserver storage
```

## Create Heat Stack

See workbook page 420

## Edit Image

```
(undercloud) [stack@director ~]$ wget http://materials.example.com/osp-small.qcow2
(undercloud) [stack@director ~]$ sudo yum install -y guestfish
(undercloud) [stack@director ~]$ guestfish -i --network -a osp-small.qcow2
><fs> command "yum install -y httpd"
><fs> touch /var/www/html/index.html
><fs> vi /var/www/html/index.html
><fs> command "systemctl enable httpd"
><fs> command "useradd testuser"
><fs> selinux-relabel /etc/selinux/targeted/contexts/files/file_contexts /
><fs> exit
```

```
(undercloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack image create --min-ram 1024 --min-disk 10 --disk-format qcow2 --file osp-small.qcow2 webserver
```

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack flavor create --ram 1024 --disk 10 m1.web
(overcloud) [stack@director ~]$ openstack keypair create east > /home/stack/hello.pem
(overcloud) [stack@director ~]$ chmod 600 /home/stack/hello.pem
(overcloud) [stack@director ~]$ openstack server create --flavor m1.web --image webserver --key-name east --network engnet --security-group ssh --security-group web custom-web-server
(overcloud) [stack@director ~]$ openstack floating ip create public
(overcloud) [stack@director ~]$ openstack server add floating ip custom-web-server 172.25.250.106
(overcloud) [stack@director ~]$ ping 172.25.250.106
(overcloud) [stack@director ~]$ ssh -i /home/stack/hello.pem cloud-user@172.25.250.106 id testuser
(undercloud) [stack@director ~]$ curl 172.25.250.106
```

## RabbitMQ User Adding

```
(undercloud) [stack@director ~]$ ssh root@controller0
[root@controller0 ~]# docker exec -it rabbitmq-bundle-docker-0 /bin/bash
()[root@controller0 /]# rabbitmqctl add_user test redhat
()[root@controller0 /]# rabbitmqctl set_permissions test ".*" ".*" ".*"
()[root@controller0 /]# rabbitmqctl set_user_tags test administrator
()[root@controller0 /]# rabbitmqctl trace_on
()[root@controller0 /]# exit
[root@controller0 ~]# exit
```

## Creating Swift Containers

```
(undercloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ cd /tmp/
(overcloud) [stack@director tmp]$ tar zcvf etc.tar.gz /etc
(overcloud) [stack@director tmp]$ openstack container create warehouse
(overcloud) [stack@director tmp]$ openstack object create warehouse etc.tar.gz
```

```
(overcloud) [stack@director tmp]$ scp -i /home/stack/webkey.pem /home/stack/robertrc cloud-user@172.25.250.108:~
(overcloud) [stack@director tmp]$ ssh -i /home/stack/webkey.pem cloud-user@172.25.250.108
[cloud-user@custom-web-server ~]$ source robertrc
(overcloud) [cloud-user@webserver ~]$ openstack object list warehouse
(overcloud) [cloud-user@webserver ~]$ openstack object save warehouse etc.tar.gz
(overcloud) [cloud-user@webserver ~]$ exit
```

## Check Network Namespace

```
(undercloud) [stack@director ~]$ ssh root@compute1
[root@compute1 ~]# ip netns list
[root@compute1 ~]# exit
```

## Set Up Manila Share

```
(undercloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ manila type-create cephfstype false
(overcloud) [stack@director ~]$ manila create --name engineering_share --share-type cephfstype cephfs 1
(undercloud) [stack@director ~]$ ssh root@controller0
[root@controller0 ~]# ceph auth get-or-create --name=client.manila --keyring=/etc/ceph/ceph.client.manila.keyring client.cloud-user > /root/cloud-user.keyring
[root@controller0 ~]# exit
(overcloud) [stack@director ~]$ manila access-allow engineering_share cephx cloud-user
```

## Mount Manila Filesystem

```
(undercloud) [stack@director ~]$ vim files/manila.sh
```

```
#!/usr/bin/bash
cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<eof
DEVICE=eth1
BOOTPROTO=dhcp
ONBOOT=yes
eof

ifup eth1
curl -s -f -o /etc/yum.repos.d/ceph.repo http://materials.example.com/ceph.repo
yum install -y ceph-fuse
```

```
(undercloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ openstack server create --image web --flavor m1.petite --security-group ssh --security-group web --key-name webkey --user-data files/manila.sh --network engnet --network storagenet eng_server1
(overcloud) [stack@director ~]$ openstack floating ip create public
(overcloud) [stack@director ~]$ openstack server add floating ip eng_server1 172.25.250.105
```

```
(overcloud) [stack@director ~]$ scp /home/stack/webkey.pem root@controller0:~
(overcloud) [stack@director ~]$ ssh root@controller0
[root@controller0 ~]# scp -i webkey.pem /etc/ceph/ceph.conf cloud-user@172.25.250.105:~
[root@controller0 ~]# scp -i webkey.pem /root/cloud-user.keyring cloud-user@172.25.250.105:~
[root@controller0 ~]# exit
```

```
(overcloud) [stack@director ~]$ source robertrc
(overcloud) [stack@director ~]$ manila share-export-location-list engineering_share
```

```
(overcloud) [stack@director ~]$ ssh -i /home/stack/webkey.pem cloud-user@172.25.250.105
[cloud-user@eng-server1 ~]$ sudo mkdir /mnt/ceph
[cloud-user@eng-server1 ~]$ sudo -i
[root@eng-server1 ~]# ceph-fuse --conf=/home/cloud-user/ceph.conf --name=client.cloud-user --keyring=/home/cloud-user/cloud-user.keyring --client-mountpoint=/volumes/_nogroup/308d8da3-f29d-4aad-8ba8-12cb00969c0f /mnt/ceph
[root@eng-server1 ceph]# exit
[cloud-user@eng-server1 ~]$ exit
```
