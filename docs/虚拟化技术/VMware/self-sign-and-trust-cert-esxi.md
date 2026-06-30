---
tags:
  - ESXi
  - Windows
---

# 替换 ESXi 默认 SSL 证书并在 Windows 11 信任

## Backup the old cert

Login to ESXi host via SSH and run:

```bash
cd /etc/vmware/ssl/
mkdir bak
mv rui.crt bak/
mv rui.key  bak/
```

## Sign a new cert on ESXi host

Under directory `/etc/vmware/ssl`, create `webclient.cnf`:

```text
[ req ]
default_bits = 2048
default_keyfile = rui.key
distinguished_name = req_distinguished_name
encrypt_key = no
prompt = no
string_mask = nombstr
req_extensions = v3_req

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = DNS:esxi.hxp.plus, DNS:esxi, IP:192.168.1.250

[ req_distinguished_name ]
countryName = CH
stateOrProvinceName = ZH
localityName = City
0.organizationName = hxp
organizationalUnitName = hxp
commonName = esxi.hxp.plus

[ alt_names ]
DNS.1 = esxi.hxp.plus
DNS.2 = esxi
IP.1 = 192.168.1.250
```

Please remember to replace `esxi.hxp.plus` to your ESXi FQDN, replace `esxi` to your ESXi host's hostname, and replace `192.168.1.250` to the IP address of your ESXi host.

and then use openssl command to generate self-signed cert:

```bash
openssl genrsa -out /etc/vmware/ssl/rui.key 2048
openssl req -new -nodes -out /etc/vmware/ssl/rui.csr -keyout /etc/vmware/ssl/rui.key -config /etc/vmware/ssl/webclient.cnf
openssl x509 -req -days 365 -in /etc/vmware/ssl/rui.csr -signkey /etc/vmware/ssl/rui.key -out /etc/vmware/ssl/rui.crt -extensions v3_req -extfile /etc/vmware/ssl/webclient.cnf
```

If no error occurs, the output should be:

```text
[root@esxi:/etc/vmware/ssl] openssl genrsa -out /etc/vmware/ssl/rui.key 2048
Generating RSA private key, 2048 bit long modulus
**************************************************************************************************************************************************************************+++++
**************************************************************************************************************************************************************************************************************************************************************+++++
e is 65537 (0x10001)
[root@esxi:/etc/vmware/ssl] openssl req -new -nodes -out /etc/vmware/ssl/rui.csr -keyout /etc/vmware/ssl/rui.key -config
 /etc/vmware/ssl/webclient.cnf
Generating a RSA private key
******************************************************************************************************************************************+++++
**************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************+++++
writing new private key to '/etc/vmware/ssl/rui.key'
-----
[root@esxi:/etc/vmware/ssl] openssl x509 -req -days 365 -in /etc/vmware/ssl/rui.csr -signkey /etc/vmware/ssl/rui.key -ou
t /etc/vmware/ssl/rui.crt -extensions v3_req -extfile /etc/vmware/ssl/webclient.cnf
Signature ok
subject=/C=CH/ST=ZH/L=City/O=hxp/OU=hxp/CN=esxi.hxp.plus
Getting Private key
```

Then restart vSphere Web Client by:

```bash
/etc/init.d/hostd restart
```

## Make Windows 11 trust the self-signed cert

Open Chrome browser, visit your ESXi web url, click on the lock to download the cert. Then double click the downloaded cert, click "Install Certificate", and then click "Local Machine", "Next", choose "Place all certificates in the following store", click "Browse..." and choose "Trusted Root Certification Authorities", click "OK" and "Next", and then "Finish".

After a restart of Chrome browser, the ESXi web url will be shown as a secure HTTPS connection.

## Alternative Method (Not tested yet on ESXi, but works on my AWX host)

```bash
AWX_HOST="awx.example.com"
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -out ./base/tls.crt -keyout ./base/tls.key -subj "/CN=${AWX_HOST}/O=${AWX_HOST}" -addext "subjectAltName = DNS:${AWX_HOST}"
```

## References

<https://www.vmwareblog.org/replace-default-esxi-ssl-certificate-self-signed-certificate-101-introduction/>
