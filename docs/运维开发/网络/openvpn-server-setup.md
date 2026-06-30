---
tags:
  - OpenVPN
---

# Manjaro Linux 搭建 IPv6 OpenVPN 服务器

## Install OpenVPN and Easy-RSA software on Manjaro

```bash
sudo yay -Sy openvpn easy-rsa
```

## Initialize a new PKI and generate a CA pair

```bash
cd /etc/easyrsa
export EASYRSA=$(pwd)
easyrsa init-pki
# remove this vars if it exists, otherwise build-ca would fail with "Conflicting 'vars' files found" error.
rm vars
easyrsa build-ca
```

```text
* Notice:
Using SSL: openssl OpenSSL 1.1.1q  5 Jul 2022


Enter New CA Key Passphrase:
Re-Enter New CA Key Passphrase:
.........................+++++
...+++++
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:hxp-manjaro.hxp.plus

* Notice:

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/etc/easy-rsa/pki/ca.crt
```

## Generate OpenVPN server files

```bash
cp /etc/easy-rsa/pki/ca.crt /etc/openvpn/server/ca.crt
cd /etc/easy-rsa/
easyrsa gen-req hxp-manjaro nopass
cp /etc/easy-rsa/pki/private/hxp-manjaro.key /etc/openvpn/server/
openssl dhparam -out /etc/openvpn/server/dh.pem 2048
easyrsa sign-req server hxp-manjaro
cp /etc/easy-rsa/pki/issued/hxp-manjaro.crt /etc/openvpn/server/
```

## Generate a client key and cert

```bash
cd /etc/easy-rsa
easyrsa gen-req client1 nopass
cp /etc/easy-rsa/pki/private/client1.key /etc/openvpn/client/
easyrsa sign-req client client1
cp /etc/easy-rsa/pki/issued/client1.crt /etc/openvpn/client/
```

## Create a server configuration

```bash
cat > /etc/openvpn/server/server.conf << EOF
dev tun
ca ca.crt
cert hxp-manjaro.crt
key hxp-manjaro.key
dh dh.pem
port 3389
proto tcp6
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
server 10.8.0.0 255.255.255.0
topology subnet
keepalive 10 120
verb 3
EOF
```

## Create a client configuration

```bash
cat > /etc/openvpn/client/client1.ovpn << EOF
client
dev tun
proto tcp6
remote ipv6.hxp-manjaro.hxp.plus 3389
nobind
persist-key
persist-tun
verb 3
<ca>
$(cat /etc/easy-rsa/pki/ca.crt)
</ca>
<cert>
$(cat /etc/easy-rsa/pki/issued/client1.crt)
</cert>
<key>
$(cat /etc/easy-rsa/pki/private/client1.key)
</key>
EOF
```

## Configure the firewall

In this case I am using firewalld as my firewall.

```bash
pacman -Sy firewalld
firewall-cmd --add-masquerade
firewall-cmd --add-port=3389/tcp
firewall-cmd --runtime-to-permanent
```

## Start and enable OpenVPN service

```bash
systemctl start openvpn-server@server.service
systemctl enable openvpn-server@server.service
```

## References

<https://wiki.archlinux.org/title/OpenVPN>

<https://wiki.archlinux.org/title/Easy-RSA>
