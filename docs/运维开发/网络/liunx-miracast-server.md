---
tags:
  - 网络
  - Linux
---

# Use Linux as a Miracast receiver


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

# Download and compile miraclecast

从 <https://github.com/albfan/miraclecast> 下载 zip 包，按 README 操作。

### 安装依赖

```bash
sudo dnf install cmake meson glib2-devel systemd-devel readline-devel check libtool iw
sudo dnf install gstreamer1-libav
```

### 测试兼容性

```bash
cd res
sudo ./test-hardware-capabilities.sh
sudo ./test-viewer.sh
```

### 编译并安装

```bash
sudo cp org.freedesktop.miracle.conf /etc/dbus-1/system.d/
mkdir build
cd build/
../autogen.sh g --prefix=/usr
make -j12
sudo make install
```

## 启动服务端

```bash
systemctl stop NetworkManager
sudo systemctl stop NetworkManager
sudo systemctl stop wpa_supplicant
sudo miracle-wifid &
```

## 连接

```bash
sudo miracle-sinkctl
run 3
```

```bash
$ sudo miracle-wifictl --log-level trace
[miraclectl] # list
  LINK INTERFACE                FRIENDLY-NAME                 
     3 wlp3s0                   archlinux-alberto             

  LINK PEER-ID                  FRIENDLY-NAME                  CONNECTED 

 0 peers and 1 links listed.
[miraclectl] # select 3
link 3 selected
[ADD] Peer: f2:27:65:35:b6:8f@3
[PROV] Peer: ff:ff:ff:ff:ff:ff@3 Type: pbc PIN: 
[miraclectl] # list
  LINK INTERFACE                FRIENDLY-NAME                 
     3 wlp3s0                   archlinux-alberto             

  LINK PEER-ID                  FRIENDLY-NAME                  CONNECTED 
     3 ff:ff:ff:ff:ff:ff@3           Alberto Fanjul Alonso            no        

 1 peers and 1 links listed.
[miraclectl] # connect ff:ff:ff:ff:ff:ff@3
[CONNECT] Peer: ff:ff:ff:ff:ff:ff@3
[miraclectl] # list
  LINK INTERFACE                FRIENDLY-NAME                 
     3 wlp3s0                   archlinux-alberto             

  LINK PEER-ID                  FRIENDLY-NAME                  CONNECTED 
     3 ff:ff:ff:ff:ff:ff@3           Alberto Fanjul Alonso            yes        

 1 peers and 1 links listed.
```

## 故障排查

如果无法连接到 miraclecast，运行

```bash
sudo miracle-wifid --log-level trace
```

查看调试信息。如果错误描述为

```
ERROR: supplicant: HUP on dhcp-comm socket on p2p-wlo1-1 (supplicant_group_comm_fn() in ../../../src/wifi/wifid-supplicant.c:247)
```

尝试

```bash
sudo miracle-dhcp --netdev <your_interface>
```

在我的案例中，该命令报错：

```
ERROR: dhcp: execution of ip-binary (/bin/ip) not allowed: No such file or directory (parse_argv() in ../../../src/dhcp/dhcp.c:877)
```

运行

```bash
which ip
```

输出

```
/usr/sbin/ip
```

因此解决方案为

```bash
sudo ln -s /usr/sbin/ip /bin/ip
```

---

## 原文（English）

```
---
tags:
  - 网络
  - Linux
---

# Use Linux as a Miracast receiver


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

# Download and compile miraclecast

Download zip from <https://github.com/albfan/miraclecast>

Do what README says.

### Install dependencies

```bash
sudo dnf install cmake meson glib2-devel systemd-devel readline-devel check libtool iw
sudo dnf install gstreamer1-libav
```

### Test compatibilities

```bash
cd res
sudo ./test-hardware-capabilities.sh
sudo ./test-viewer.sh
```

### Make and install

```bash
sudo cp org.freedesktop.miracle.conf /etc/dbus-1/system.d/
mkdir build
cd build/
../autogen.sh g --prefix=/usr
make -j12
sudo make install
```

## Fire up the server

```bash
systemctl stop NetworkManager
sudo systemctl stop NetworkManager
sudo systemctl stop wpa_supplicant
sudo miracle-wifid &
```

## Connect

```bash
sudo miracle-sinkctl
run 3
```

```bash
$ sudo miracle-wifictl --log-level trace
[miraclectl] # list
  LINK INTERFACE                FRIENDLY-NAME                 
     3 wlp3s0                   archlinux-alberto             

  LINK PEER-ID                  FRIENDLY-NAME                  CONNECTED 

 0 peers and 1 links listed.
[miraclectl] # select 3
link 3 selected
[ADD] Peer: f2:27:65:35:b6:8f@3
[PROV] Peer: ff:ff:ff:ff:ff:ff@3 Type: pbc PIN: 
[miraclectl] # list
  LINK INTERFACE                FRIENDLY-NAME                 
     3 wlp3s0                   archlinux-alberto             

  LINK PEER-ID                  FRIENDLY-NAME                  CONNECTED 
     3 ff:ff:ff:ff:ff:ff@3           Alberto Fanjul Alonso            no        

 1 peers and 1 links listed.
[miraclectl] # connect ff:ff:ff:ff:ff:ff@3
[CONNECT] Peer: ff:ff:ff:ff:ff:ff@3
[miraclectl] # list
  LINK INTERFACE                FRIENDLY-NAME                 
     3 wlp3s0                   archlinux-alberto             

  LINK PEER-ID                  FRIENDLY-NAME                  CONNECTED 
     3 ff:ff:ff:ff:ff:ff@3           Alberto Fanjul Alonso            yes        

 1 peers and 1 links listed.
```

## Troubleshooting

If you cannot connect to miraclecast, run

```bash
sudo miracle-wifid --log-level trace
```

to show debug information. And if the error is described as

```
ERROR: supplicant: HUP on DHCP-comm socket on p2p-wlo1-1 (supplicant_group_comm_fn() in ../../../src/wifi/wifid-supplicant.c:247)
```

try 

```bash
sudo miracle-DHCP --netdev <your_interface>
```

In my case, the command failed with error:

```
ERROR: DHCP: execution of ip-binary (/bin/ip) not allowed: No such file or directory (parse_argv() in ../../../src/dhcp/dhcp.c:877)
```

I ran

```bash
which ip
```

it prints

```
/usr/sbin/ip
```

So the solution was

```bash
sudo ln -s /usr/sbin/ip /bin/ip
```
```