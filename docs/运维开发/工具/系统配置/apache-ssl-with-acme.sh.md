---
tags:
  - Apache
---

# Apache 使用 acme.sh 配置 SSL

# Server Information for This Article

- My friend's brand new CentOS 7 Server with `httpd` installed

- He updated all pre-installed packages via `yum update`

# Install SSL Module for https

```
yum install mod_ssl openssl
```

The apache official website said that my SSL configuration will need to contain, at minimum, the following directives.

```
LoadModule ssl_module modules/mod_ssl.so

Listen 443
<VirtualHost *:443>
    ServerName www.example.com
    SSLEngine on
    SSLCertificateFile "/path/to/www.example.com.cert"
    SSLCertificateKeyFile "/path/to/www.example.com.key"
</VirtualHost>
```

But `LoadModule ssl_module modules/mod_ssl.so` is already included in `/etc/httpd/conf.modules.d/00-ssl.conf`, so I did nothing.

# Install Certs

The next step was to use [acme.sh](https://github.com/acmesh-official/acme.sh) to issue a free cert.

Install `acme.sh` by running just one command

```
curl https://get.acme.sh | sh
```

I prefer using the standalone mode. The standalone mode is more reliable than other modes. But you need to stop Apache to release port 80.

```
systemctl stop httpd
```

Then I began to issue and install my cert in `/etc/pki/httpd/private`

```
mkdir -p /etc/pki/httpd/private
sudo ~/.acme.sh/acme.sh --issue -d mydomain.network --standalone -k ec-256
sudo ~/.acme.sh/acme.sh --renew -d mydomain.network --force --ecc
sudo ~/.acme.sh/acme.sh --installcert -d mydomain.network --fullchainpath /etc/pki/httpd/server.crt --keypath /etc/pki/httpd/private/server.key --ecc
```

If you are now issuing your cert, remember to change `mydomain.network` to your domain name.

# Install the Cert on Apache Server

Edit `/etc/httpd/conf.d/ssl.conf`, find the two lines with `SSLCertificateFile` and `SSLCertificateKeyFile`. Change the path to certs to where we installed just now.

```
SSLCertificateFile /etc/pki/httpd/server.crt
SSLCertificateKeyFile /etc/pki/httpd/private/server.key
```

And then restart httpd

```
systemctl restart httpd
```

Visit my server in Chrome, SSL worked!
