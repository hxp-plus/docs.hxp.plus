---
tags:
  - Ceph
  - 存储
---
# ceph-deploy

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：ceph-deploy

```bash
[root@ceph_node1 ~]# history
    1  nmcli connection modify ens33 ipv4.addresses 192.168.8.61
    2  vim /etc/sysconfig/network-scripts/ifcfg-ens33
    3  nmcli connection modify ens33 ipv4.method manual ipv4.dns 192.168.8.1 ipv4.gateway 192.168.8.1 ipv4.addresses 192.168.8.61/24
    4  nmcli connection up ens33
    5  ifconfig
    6  ping baidu.com
    7  vim /etc/hosts
    8  vim /etc/sysconfig/selinux 
    9  setenforce 0
   10  systemctl disable --now firewalld.service
   11  for i in {1..3};do ssh-copy-id root@ceph_node$i;donw 
   12  for i in {1..3};do ssh-copy-id root@ceph_node$i;done
   13  ssh-keygen 
   14  for i in {1..3};do ssh-copy-id root@ceph_node$i;done
   15  for i in {1..3};do ssh root@ceph_node$i "hostnamectl set-hostname ceph_node$i";done
   16  for i in {1..3};do ssh root@ceph_node$i "hostname -f";done
   17  vim /etc/chrony.conf 
   18  for i in {1..3};do scp /etc/chrony.conf root@ceph_node$i:/etc/;done
   19  for i in {1..3};do ssh root@ceph_node$i "systemctl enable --now chronyd";done
   20  for i in {1..3};do ssh root@ceph_node$i "chronyc sources";done
   21  lsblk
   22  lvremove /dev/ceph*
   23  lsblk
   24  vim /etc/yum.repos.d/ceph.repo
   25  yum makecache 
   26  kill 2977
   27  yum makecache 
   28  for i in {1..3};do scp /etc/yum.repos.d/ceph.repo root@ceph_node$i:/etc/yum.repos.d/;done
   29  for i in {1..3};do ssh root@ceph_node$i "yum makecache";done
   30  for i in {1..3};do ssh root@ceph_node$i "yum install -y ceph";done
   31  wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
   32  for i in {1..3};do ssh root@ceph_node$i "wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo";done
   33  for i in {1..3};do ssh root@ceph_node$i "yum install -y ceph";done
   34  vim /etc/yum.repos.d/ceph.repo 
   35  for i in {1..3};do ssh root@ceph_node$i "yum install -y ceph";done
   36  for i in {1..3};do scp /etc/yum.repos.d/ceph.repo root@ceph_node$i:/etc/yum.repos.d/;done
   37  for i in {1..3};do ssh root@ceph_node$i "yum install -y ceph";done
   38  yum install ceph-deploy
   39  getenforce 
   40  systemctl status firewalld.service 
   41  mkdir cluster
   42  cd cluster/
   43  ceph-deploy new ceph_node1 ceph_node2 ceph_node3
   44  ceph-deploy mon create-initial
   45  ceph-deploy mgr create ceph_node1 ceph_node2 ceph_node3
   46  ceph-deploy admin ceph_node1 ceph_node2 ceph_node3
   47  yum install -y ceph-radosgw
   48  ceph-deploy rgw create ceph_node1
   49  ceph-deploy mds create ceph_node1 ceph_node2 ceph_node3
   50  ceph-deploy osd create --data /dev/sdb ceph_node1
   51  ceph-deploy osd create --data /dev/sdc ceph_node1
   52  ceph-deploy osd create --data /dev/sdd ceph_node1
   53  ceph-deploy osd create --data /dev/sdb ceph_node2
   54  ceph-deploy osd create --data /dev/sdc ceph_node2
   55  ceph-deploy osd create --data /dev/sdd ceph_node2
   56  ceph-deploy osd create --data /dev/sdb ceph_node3
   57  ceph-deploy osd create --data /dev/sdc ceph_node3
   58  ceph-deploy osd create --data /dev/sdd ceph_node3
   59  ceph -s
   60  history
```

```bash
[root@ceph_node1 ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.8.61 ceph_node1
192.168.8.62 ceph_node2
192.168.8.63 ceph_node3
192.168.8.40 ntp
```

```bash
[root@ceph_node1 ~]# cat /etc/yum.repos.d/ceph.repo 
[Ceph]
name=Ceph packages for $basearch
baseurl=http://mirrors.aliyun.com/ceph/rpm-nautilus/el7/\$basearch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc
priority=1
[Ceph-noarch]
name=Ceph noarch packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-nautilus/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc
priority=1
[ceph-source]
name=Ceph source packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-nautilus/el7/SRPMS
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc

```

---

## 原文（English）

```
---
tags:
  - Ceph
  - 存储
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

```bash
[root@ceph_node1 ~]# history
    1  nmcli connection modify ens33 ipv4.addresses 192.168.8.61
    2  vim /etc/sysconfig/network-scripts/ifcfg-ens33
    3  nmcli connection modify ens33 ipv4.method manual ipv4.DNS 192.168.8.1 ipv4.gateway 192.168.8.1 ipv4.addresses 192.168.8.61/24
    4  nmcli connection up ens33
    5  ifconfig
    6  ping baidu.com
    7  vim /etc/hosts
    8  vim /etc/sysconfig/selinux 
    9  setenforce 0
   10  systemctl disable --now firewalld.service
   11  for i in {1..3};do ssh-copy-id root@ceph_node$i;donw 
   12  for i in {1..3};do ssh-copy-id root@ceph_node$i;done
   13  ssh-keygen 
   14  for i in {1..3};do ssh-copy-id root@ceph_node$i;done
   15  for i in {1..3};do ssh root@ceph_node$i "hostnamectl set-hostname ceph_node$i";done
   16  for i in {1..3};do ssh root@ceph_node$i "hostname -f";done
   17  vim /etc/chrony.conf 
   18  for i in {1..3};do scp /etc/chrony.conf root@ceph_node$i:/etc/;done
   19  for i in {1..3};do ssh root@ceph_node$i "systemctl enable --now chronyd";done
   20  for i in {1..3};do ssh root@ceph_node$i "chronyc sources";done
   21  lsblk
   22  lvremove /dev/ceph*
   23  lsblk
   24  vim /etc/yum.repos.d/ceph.repo
   25  yum makecache 
   26  kill 2977
   27  yum makecache 
   28  for i in {1..3};do scp /etc/yum.repos.d/ceph.repo root@ceph_node$i:/etc/yum.repos.d/;done
   29  for i in {1..3};do ssh root@ceph_node$i "yum makecache";done
   30  for i in {1..3};do ssh root@ceph_node$i "yum install -y Ceph";done
   31  wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
   32  for i in {1..3};do ssh root@ceph_node$i "wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo";done
   33  for i in {1..3};do ssh root@ceph_node$i "yum install -y Ceph";done
   34  vim /etc/yum.repos.d/ceph.repo 
   35  for i in {1..3};do ssh root@ceph_node$i "yum install -y Ceph";done
   36  for i in {1..3};do scp /etc/yum.repos.d/ceph.repo root@ceph_node$i:/etc/yum.repos.d/;done
   37  for i in {1..3};do ssh root@ceph_node$i "yum install -y Ceph";done
   38  yum install Ceph-deploy
   39  getenforce 
   40  systemctl status firewalld.service 
   41  mkdir cluster
   42  cd cluster/
   43  Ceph-deploy new ceph_node1 ceph_node2 ceph_node3
   44  Ceph-deploy mon create-initial
   45  Ceph-deploy mgr create ceph_node1 ceph_node2 ceph_node3
   46  Ceph-deploy admin ceph_node1 ceph_node2 ceph_node3
   47  yum install -y Ceph-radosgw
   48  Ceph-deploy rgw create ceph_node1
   49  Ceph-deploy mds create ceph_node1 ceph_node2 ceph_node3
   50  Ceph-deploy osd create --data /dev/sdb ceph_node1
   51  Ceph-deploy osd create --data /dev/sdc ceph_node1
   52  Ceph-deploy osd create --data /dev/sdd ceph_node1
   53  Ceph-deploy osd create --data /dev/sdb ceph_node2
   54  Ceph-deploy osd create --data /dev/sdc ceph_node2
   55  Ceph-deploy osd create --data /dev/sdd ceph_node2
   56  Ceph-deploy osd create --data /dev/sdb ceph_node3
   57  Ceph-deploy osd create --data /dev/sdc ceph_node3
   58  Ceph-deploy osd create --data /dev/sdd ceph_node3
   59  Ceph -s
   60  history
```

```bash
[root@ceph_node1 ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.8.61 ceph_node1
192.168.8.62 ceph_node2
192.168.8.63 ceph_node3
192.168.8.40 ntp
```

```bash
[root@ceph_node1 ~]# cat /etc/yum.repos.d/ceph.repo 
[Ceph]
name=Ceph packages for $basearch
baseurl=http://mirrors.aliyun.com/ceph/rpm-nautilus/el7/\$basearch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc
priority=1
[Ceph-noarch]
name=Ceph noarch packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-nautilus/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc
priority=1
[Ceph-source]
name=Ceph source packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-nautilus/el7/SRPMS
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc

```
```