---
tags:
  - Linux
  - Networking
---

# RHEL 8/CentOS 8 连接 PPPoE 网络

# Install gcc make git net-tools and ppp

```
yum install gcc make ppp git net-tools
```

# download rp-pppoe source code

```
curl https://dianne.skoll.ca/projects/rp-pppoe/download/rp-pppoe-3.15.tar.gz | tar -xz
```

# install and configure rp-pppoe

```
cd rp-pppoe-3.15/
./go
```

then follow the prompt to input username and password.

# start pppoe network

```
pppoe-start
nmcli con up ppp0
```

# check pppoe network status

```
pppoe-status
```

# change your default gateway

After the dial succeed, the default gateway may still be the gateway of private network, and the public address can not be accessed from internet. So in this case the default gateway must be changed to the public one, to ensure the server can be accessed innernet and internet. Get current route table by:

```
route -n
```

```
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.1.1     0.0.0.0         UG    101    0        0 eth1
123.120.0.1     0.0.0.0         255.255.255.255 UH    0      0        0 ppp0
192.168.1.0     0.0.0.0         255.255.255.0   U     101    0        0 eth1
192.168.10.0    0.0.0.0         255.255.255.0   U     100    0        0 eth0
```

Change default gateway by (my gateway for ppp0 interface is 123.120.0.1 as the destination row shows):

```
route delete default gw 192.168.10.1 eth0
route add default gw 123.120.0.1 ppp0
```

```
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.1.1     0.0.0.0         UG    101    0        0 eth1
123.120.0.1     0.0.0.0         255.255.255.255 UH    0      0        0 ppp0
192.168.1.0     0.0.0.0         255.255.255.0   U     101    0        0 eth1
192.168.10.0    0.0.0.0         255.255.255.0   U     100    0        0 eth0
```
