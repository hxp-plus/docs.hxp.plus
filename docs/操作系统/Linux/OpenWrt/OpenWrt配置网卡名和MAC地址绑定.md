---
tags:
  - OpenWrt
  - Linux
---
# OpenWrt配置网卡名和MAC地址绑定

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

有些时候会遇到网卡名重启后改变的情况，需要把网卡名和MAC地址绑定。首先新建配置文件`/etc/config/mac-static-interfaces`：
```
config mac-static-interfaces
        option eth0 "00:15:5d:1f:26:01"
        option eth1 "00:15:5d:1f:26:02"
        option eth2 "a0:36:9f:89:b5:04"
        option eth3 "a0:36:9f:89:b5:05"
        option eth4 "a0:36:9f:89:b5:06"
        option eth5 "a0:36:9f:89:b5:07"
```
编辑`/etc/rc.local`：
```bash
# Put your custom commands here that should be executed once

# the system init finished. By default this file does nothing.
# exit 0
#!/bin/sh /etc/rc.common

START=11

# don't run within buildroot
[ -n "${IPKG_INSTROOT}" ] && return 0

#use busybox grep as GNU grep may be set differently and break the script
grep(){
	/bin/busybox 'grep' $@
}

#shutting down all interfaces, then assigning temporary name to free up interface names
#bridges and virtual interfaces are already excluded by  /sys/class/net/*/device/uevent as only physical interfaces have that
for i in $( ls /sys/class/net/*/device/uevent | awk -F'/' '{print $5}' | tr '\n' ' ' ) ;
do
        mac_address=$( grep $i /etc/config/mac-static-interfaces | awk '{print $3}' | tr -d '"' )
        if [ "$mac_address" != '' ]; then
                ip link set "$i" down
                ip link set "$i" name old"$i"
        fi
done

for i in $( ls /sys/class/net/*/device/uevent | awk -F'/' '{print $5}' | tr '\n' ' ' ) ;
domac_address=$( cat /sys/class/net/$i/address  )
        interface_name=$( grep -i $mac_address /etc/config/mac-static-interfaces | awk '{print $2}' )
        if [ "$interface_name" != '' ]; then
                ip link set "$i" down
                ip link set "$i" name "$interface_name"
                ip link set "$interface_name" up
                /etc/init.d/network restart
        fi
done

exit 0
```
之后重启测试。

---

## 原文（English）

```
---
tags:
  - OpenWrt
  - Linux
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

有些时候会遇到网卡名重启后改变的情况，需要把网卡名和MAC地址绑定。首先新建配置文件`/etc/config/mac-static-interfaces`：
```
config mac-static-interfaces
        option eth0 "00:15:5d:1f:26:01"
        option eth1 "00:15:5d:1f:26:02"
        option eth2 "a0:36:9f:89:b5:04"
        option eth3 "a0:36:9f:89:b5:05"
        option eth4 "a0:36:9f:89:b5:06"
        option eth5 "a0:36:9f:89:b5:07"
```
编辑`/etc/rc.local`：
```bash
# Put your custom commands here that should be executed once

# the system init finished. By default this file does nothing.
# exit 0
#!/bin/sh /etc/rc.common

START=11

# don't run within buildroot
[ -n "${IPKG_INSTROOT}" ] && return 0

#use busybox grep as GNU grep may be set differently and break the script
grep(){
	/bin/busybox 'grep' $@
}

#shutting down all interfaces, then assigning temporary name to free up interface names
#bridges and virtual interfaces are already excluded by  /sys/class/net/*/device/uevent as only physical interfaces have that
for i in $( ls /sys/class/net/*/device/uevent | awk -F'/' '{print $5}' | tr '\n' ' ' ) ;
do
        mac_address=$( grep $i /etc/config/mac-static-interfaces | awk '{print $3}' | tr -d '"' )
        if [ "$mac_address" != '' ]; then
                ip link set "$i" down
                ip link set "$i" name old"$i"
        fi
done

for i in $( ls /sys/class/net/*/device/uevent | awk -F'/' '{print $5}' | tr '\n' ' ' ) ;
do
mac_address=$( cat /sys/class/net/$i/address  )
        interface_name=$( grep -i $mac_address /etc/config/mac-static-interfaces | awk '{print $2}' )
        if [ "$interface_name" != '' ]; then
                ip link set "$i" down
                ip link set "$i" name "$interface_name"
                ip link set "$interface_name" up
                /etc/init.d/network restart
        fi
done

exit 0
```
之后重启测试。
```
