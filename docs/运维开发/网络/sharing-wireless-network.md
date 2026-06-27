---
tags:
  - 网络
  - Linux
---

# Bridging WLAN Networks Using 2 Wireless Cards


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 方法一：brctl（不可用）

wlan0：开启 4addr

```bash
sudo iw dev wlan0 set 4addr on
```

wlan1：开启监听模式

```bash
sudo airmon-ng start wlan1
```

启动 AP

```bash
sudo airbase-ng --essid HUST_WIRELESS_TWIN -c 6 wlan1mon
```

添加桥接

```bash
sudo brctl addbr mitm-bridge
sudo brctl addif mitm-bridge at0
sudo brctl addif mitm-bridge wlan0
```

## 方法二：hostapd

编辑 `hostapd.conf`

```
interface=wlan1
ssid=Wifi_Lab
channel=6
```

编辑 `dnsmasq.conf`

```
interface=wlan1
dhcp-range=10.0.0.10,10.0.0.250,255.255.255.0,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
log-queries
log-dhcp
```

编辑 `fakehosts.conf`

```
10.0.0.1 baidu.com
```

启动 DNS 和 DHCP 服务器

```bash
sudo dnsmasq -C dnsmasq.conf -H fakehosts.conf -d
```

启动 AP

```bash
sudo hostapd hostapd.conf
```

为 AP 分配 IP

```bash
sudo ifconfig wlan1 10.0.0.1 
```

启用 NAT

```bash
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables -P FORWARD ACCEPT
iptables --table nat --append POSTROUTING --out-interface wlan0 -j MASQUERADE
iptables --append FORWARD --in-interface wlan0 -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward
```

提示：可以将 `wlan0` 替换为 `tun0`，以通过 WiFi 共享 VPN 隧道。

## 故障排查

### 热点不稳定

编辑 `/etc/NetworkManager/NetworkManager.conf`，将 `wlan1` 加入 unmanaged

```
[keyfile]
unmanaged-devices=interface-name:wlan1
```

然后重启服务

```bash
sudo systemctl restart NetworkManager
```

另请参阅：<https://wiki.archlinux.org/index.php/software_access_point#NetworkManager_is_interfering>

---

## 原文（English）

```
---
tags:
  - 网络
  - Linux
---

# Bridging WLAN Networks Using 2 Wireless Cards


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Method 1: brctl (Not working)

wlan0: turn on 4addr

```bash
sudo iw dev wlan0 set 4addr on
```

wlan1: turn on monitor mode

```bash
sudo airmon-ng start wlan1
```

fire up the ap

```bash
sudo airbase-ng --essid HUST_WIRELESS_TWIN -c 6 wlan1mon
```

add bridge

```bash
sudo brctl addbr mitm-bridge
sudo brctl addif mitm-bridge at0
sudo brctl addif mitm-bridge wlan0
```

## Method 2: hostapd

edit `hostapd.conf`

```
interface=wlan1
ssid=Wifi_Lab
channel=6
```

edit `dnsmasq.conf`

```
interface=wlan1
dhcp-range=10.0.0.10,10.0.0.250,255.255.255.0,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
log-queries
log-dhcp
```

edit fakehosts.conf

```
10.0.0.1 baidu.com
```

fire up DNS and DHCP server

```bash
sudo dnsmasq -C dnsmasq.conf -H fakehosts.conf -d
```

fire up the access point

```bash
sudo hostapd hostapd.conf
```

assign IP to ap

```bash
sudo ifconfig wlan1 10.0.0.1 
```

enable NAT

```bash
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables -P FORWARD ACCEPT
iptables --table nat --append POSTROUTING --out-interface wlan0 -j MASQUERADE
iptables --append FORWARD --in-interface wlan0 -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward
```

Tips: you may replace `wlan0` to `tun0` to share VPN tunnel through WiFi.

## Trouble Shooting

### Hotspot unstable

edit `/etc/NetworkManager/NetworkManager.conf`, add `wlan1` to unmanaged

```
[keyfile]
unmanaged-devices=interface-name:wlan1
```

and restart service

```bash
sudo systemctl restart NetworkManager
```

See also: <https://wiki.archlinux.org/index.php/software_access_point#NetworkManager_is_interfering>
```