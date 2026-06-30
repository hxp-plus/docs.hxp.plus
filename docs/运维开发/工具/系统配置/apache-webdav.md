---
tags:
  - Apache
  - WebDAV
  - SSL
---

# CentOS 9 Apache HTTPS WebDAV 非标准端口配置

## Create a self-signed cert

Issue a self-signed cert with this command:

```bash
cd /etc/ssl/certs
openssl req -newkey rsa:4096 \
            -x509 \
            -sha256 \
            -days 3650 \
            -nodes \
            -out example.crt \
            -keyout example.key \
            -subj "/C=SI/ST=Ljubljana/L=Ljubljana/O=Security/OU=IT Department/CN=ipv6.webdav.hxp.plus"
mv example.crt ipv6.webdav.hxp.plus.crt
mv example.key ipv6.webdav.hxp.plus.key
```

Remember to change `ipv6.webdav.hxp.plus` to your server FQDN.

## Configure the WebDAV directory

For Apache, there are three WebDAV-related modules which will be loaded by default when a Apache web server getting started. You can confirm that with this command:

```bash
httpd -M | grep dav
```

You should be presented with:

```bash
dav_module (shared)
dav_fs_module (shared)
dav_lock_module (shared)
```

Then install the apache ssl module by:

```bash
yum install mod_ssl
```

Next, create a dedicated directory for WebDAV:

```bash
mkdir /var/www/html/webdav
chown -R apache:apache /var/www/html/webdav
chmod -R 755 /var/www/html/webdav
```

and change the ownership of `/var/www/html/`:

```bash
chown -R apache:apache /var/www/html/
```

## Create a user hxp for authentication

```bash
htpasswd -c /etc/httpd/.htpasswd hxp
chown root:apache /etc/httpd/.htpasswd
chmod 640 /etc/httpd/.htpasswd
```

## Create a VHost for WebDAV

Firstly, add

```bash
Listen 40443
```

to your `/etc/httpd/conf/httpd.conf`, then

Create a new file `/etc/httpd/conf.d/webdav.conf`:

```xml
DavLockDB /var/www/html/DavLock
<VirtualHost *:40443>
    DocumentRoot /var/www/html/webdav/
    ErrorLog /var/log/httpd/error.log
    CustomLog /var/log/httpd/access.log combined
    LimitRequestBody 0
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/ipv6.webdav.hxp.plus.crt
    SSLCertificateKeyFile /etc/ssl/certs/ipv6.webdav.hxp.plus.key
    Alias /webdav /var/www/html/webdav
    LimitXMLRequestBody 0
    <Directory /var/www/html/webdav>
        DAV On
        AuthType Basic
        AuthName "webdav"
        AuthUserFile /etc/httpd/.htpasswd
        Require valid-user
    </Directory>
</VirtualHost>
```

## Restart Apache

```bash
apachectl restart
```

## References

<https://devops.ionos.com/tutorials/how-to-set-up-webdav-with-apache-on-centos-7.html#:~:text=WebDAV%20(Web%2Dbased%20Distributed%20Authoring,on%20an%20Apache%20web%20server.>
<https://www.vultr.com/docs/how-to-setup-a-webdav-server-using-apache-on-centos-7/>
<https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-16-04>
