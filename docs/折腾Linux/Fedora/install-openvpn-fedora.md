---
tags:
  - Fedora
  - Linux
---

# Install OpenVPN on Fedora

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Server

首先，从 <https://github.com/angristan/openvpn-install> 获取脚本并赋予执行权限：

```bash
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh
```

然后运行：

```bash
./openvpn-install.sh
```

### Route with iptables (decrypted)

安装完成后 VPN 已经可用，但仍需配置路由，以便客户端能够连接互联网：

```bash
sh /etc/iptables/add-openvpn-rules.sh;
sysctl -w net.ipv4.ip_forward=1;
```

检查路由：

```bash
iptables -t nat -L -n -v
sysctl net.ipv4.ip_forward
```

#### 保存 iptables

```bash
yum install iptables-services
systemctl enable iptables
service iptables save
```

### Route with firewalld

```bash
firewall-cmd --permanent --add-masquerade
systemctl restart firewalld
firewall-cmd --reload
```

### 为 VPN 添加日志和管理功能

编辑 `/etc/openvpn/server.conf `，添加：

```
log-append /var/log/openvpn.log
status /var/log/openvpn/status.log
management localhost 7505
```

然后重启：

```bash
systemctl restart openvpn-server@server.service
```

使用 telnet 进行管理：

```bash
telnet localhost 7505
```

## Add or Remove User

只需再次运行安装脚本：

```bash
./openvpn-install.sh
```

## Assign an Static IP for a Client

```base
echo "ifconfig-push 10.8.0.50 255.255.255.0" > /etc/openvpn/ccd/<vpn-username>
```

或者如果 `server.conf` 中有 `ifconfig-pool-persist ipp.txt` 这行，则编辑 `ipp.txt`。

## Tracking user connects

创建一个所有用户都能访问的目录：

```bash
mkdir /etc/openvpn/scripts/
```

编辑 `/etc/openvpn/server.conf`，添加：

```bash
script-security 2
client-connect /etc/openvpn/scripts/user-connect.sh
client-disconnect /etc/openvpn/scripts/user-disconnect.sh
```

添加 `/etc/openvpn/scripts/user-connect.sh`：

```bash
#!/bin/sh

user=$common_name
remote_ip=$trusted_ip
local_ip=$ifconfig_pool_remote_ip

echo '[CONNECT]' $(date) $user $remote_ip $local_ip >>/var/log/openvpn/connectlog.txt
```

添加 `/etc/openvpn/scripts/user-disconnect.sh`：

```bash
#!/bin/sh

user=$common_name
remote_ip=$trusted_ip
local_ip=$ifconfig_pool_remote_ip

echo '[DISCONNECT]' $(date) $user $remote_ip $local_ip >>/var/log/openvpn/connectlog.txt
```

添加权限并重启：

```bash
touch /var/log/openvpn/connectlog.txt
chmod 666 /var/log/openvpn/connectlog.txt
chmod a+x /etc/openvpn/scripts/user-connect.sh
chmod a+x /etc/openvpn/scripts/user-disconnect.sh
systemctl restart openvpn-server@server.service
```

## Client

下载 ovpn 文件：

```bash
scp root@vpn-server:/root/<vpn-username>.ovpn .
```

安装 OpenVPN：

```bash
yum install openvpn
```

连接：

```bash
sudo cp desktop.ovpn /etc/openvpn/client/
sudo openvpn --client --config /etc/openvpn/client/<vpn-username>.ovpn
```

检查连接：

```bash
dig TXT +short o-o.myaddr.l.google.com @ns1.google.com
```

应该返回 VPN 服务器的 IP 地址。

对于 KDE 用户，需要安装 `networkmanager-openvpn`，并通过终端添加 VPN：

```bash
nmcli connection import type openvpn file <vpn-username>.ovpn
```

每次通过 KDE GUI 添加 VPN 时都会失败，可能是导入 OpenVPN 配置存在一些 bug。

## Troubleshooting

Linux 客户端无法获取 DNS 解析代理：在 `<vpn-username>.ovpn` 中添加以下内容：

```
script-security 2
up /usr/share/openvpn/contrib/pull-resolv-conf/client.up
down /usr/share/openvpn/contrib/pull-resolv-conf/client.down
```

删除以下行：

```
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns # Prevent Windows 10 DNS leak
```

如果仍无效，可以安装 `openvpn-update-systemd-resolved`：

```bash
yay -S openvpn-update-systemd-resolved openresolv
```

启用 systemd-resolved：

```bash
sudo systemctl enable systemd-resolved --now
```

安装后，在 VPN 配置中添加以下行：

```
script-security 2
setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
up /etc/openvpn/scripts/update-systemd-resolved
up-restart
down /etc/openvpn/scripts/update-systemd-resolved
down-pre
```

## Increase Stability

在客户端配置中添加：

```
keepalive 3 9
connect-retry 3	3
;persist-tun
```

添加路由：

```bash
firewall-cmd --add-forward-port=port=800:proto=tcp:toport=80:toaddr=10.8.0.2
firewall-cmd --runtime-to-permanent
```

---

## 原文（English）

---
tags:
  - Fedora
  - Linux
---

# Install OpenVPN on Fedora

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Server

First, get the script from <https://github.com/angristan/openvpn-install> and make it executable:

```bash
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh
```

Then run it:

```bash
./openvpn-install.sh
```

### Route with iptables (decrypted)

After that you have a VPN, but you still need to do the routing so that clients can connect to internet

```bash
sh /etc/iptables/add-openvpn-rules.sh;
sysctl -w net.ipv4.ip_forward=1;
```

Check the routing by

```bash
iptables -t nat -L -n -v
sysctl net.ipv4.ip_forward
```

#### Save iptables

```bash
yum install iptables-services
systemctl enable iptables
service iptables save
```

### Route with firewalld

```bash
firewall-cmd --permanent --add-masquerade
systemctl restart firewalld
firewall-cmd --reload
```

### Add log and management feature to VPN

Edit `/etc/openvpn/server.conf `, add

```
log-append /var/log/openvpn.log
status /var/log/openvpn/status.log
management localhost 7505
```

And restart

```bash
systemctl restart openvpn-server@server.service
```

And use telnet to manage

```bash
telnet localhost 7505
```

## Add or Remove User

Just simply run the installation script again

```bash
./openvpn-install.sh
```

## Assign an Static IP for a Client

```base
echo "ifconfig-push 10.8.0.50 255.255.255.0" > /etc/openvpn/ccd/<vpn-username>
```

or edit `ipp.txt` if there is a line `ifconfig-pool-persist ipp.txt` in `server.conf`

## Tracking user connects

make a directory under where all users may visit

```bash
mkdir /etc/openvpn/scripts/
```

edit `/etc/openvpn/server.conf`, add

```bash
script-security 2
client-connect /etc/openvpn/scripts/user-connect.sh
client-disconnect /etc/openvpn/scripts/user-disconnect.sh
```

and add `/etc/openvpn/scripts/user-connect.sh`

```bash
#!/bin/sh

user=$common_name
remote_ip=$trusted_ip
local_ip=$ifconfig_pool_remote_ip

echo '[CONNECT]' $(date) $user $remote_ip $local_ip >>/var/log/openvpn/connectlog.txt
```

add `/etc/openvpn/scripts/user-disconnect.sh`

```bash
#!/bin/sh

user=$common_name
remote_ip=$trusted_ip
local_ip=$ifconfig_pool_remote_ip

echo '[DISCONNECT]' $(date) $user $remote_ip $local_ip >>/var/log/openvpn/connectlog.txt
```

add permissions and restart

```bash
touch /var/log/openvpn/connectlog.txt
chmod 666 /var/log/openvpn/connectlog.txt
chmod a+x /etc/openvpn/scripts/user-connect.sh
chmod a+x /etc/openvpn/scripts/user-disconnect.sh
systemctl restart openvpn-server@server.service
```

## Client

Download the ovpn file

```bash
scp root@vpn-server:/root/<vpn-username>.ovpn .
```

Install OpenVPN

```bash
yum install openvpn
```

Connect

```bash
sudo cp desktop.ovpn /etc/openvpn/client/
sudo openvpn --client --config /etc/openvpn/client/<vpn-username>.ovpn
```

Check your connection by

```bash
dig TXT +short o-o.myaddr.l.google.com @ns1.google.com
```

Should return your VPN server's ip address

For kde users, you need to install `networkmanager-openvpn`, and add VPN through terminal:

```bash
nmcli connection import type openvpn file <vpn-username>.ovpn
```

Every time I add the VPN via kde GUI, it fails. Maybe there are some bugs in importing openvpn configs.

## Troubleshooting

Linux client cannot get DNS resolution proxied: Add these to your `<vpn-username>.ovpn`

```
script-security 2
up /usr/share/openvpn/contrib/pull-resolv-conf/client.up
down /usr/share/openvpn/contrib/pull-resolv-conf/client.down
```

Delete these lines

```
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns # Prevent Windows 10 DNS leak
```

you may also install `openvpn-update-systemd-resolved` if it doesn't work.

```bash
yay -S openvpn-update-systemd-resolved openresolv
```

enable systemd-resolved by

```bash
sudo systemctl enable systemd-resolved --now
```

after installing, add these lines to your VPN config

```
script-security 2
setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
up /etc/openvpn/scripts/update-systemd-resolved
up-restart
down /etc/openvpn/scripts/update-systemd-resolved
down-pre
```
## Increase Stability
Add these in client config
```
keepalive 3 9
connect-retry 3	3
;persist-tun
```

Add route

```bash
firewall-cmd --add-forward-port=port=800:proto=tcp:toport=80:toaddr=10.8.0.2
firewall-cmd --runtime-to-permanent
```
