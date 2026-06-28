---
tags:
  - Fedora
  - Linux
---

# 在 Fedora 上安装 Cockpit


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Install Cockpit on Fedora

```
yum install -y firewalld storaged cockpit cockpit-storaged
systemctl enable --now cockpit.socket
firewall-cmd --add-service=cockpit --permanent
```

使用以下命令安装 Cockpit、firewalld 和 storaged：

```
yum install -y firewalld storaged cockpit cockpit-storaged
systemctl enable --now cockpit.socket
firewall-cmd --add-service=cockpit --permanent
```

然后配置 Nginx 作为反向代理。编辑 `/etc/nginx/nginx.conf`：

`/etc/nginx/nginx.conf`

```
# For more information on configuration, see:

#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }

        server {

    server_name pan.hxp.plus;
    autoindex on;
    charset utf-8;
    root /usr/share/nginx/html;

    location /ray {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:10000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
            # Show realip in v2ray access.log
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /panel {
            proxy_redirect off;
            proxy_pass https://127.0.0.1:9090;
            proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_set_header Host $http_host;
    }

                location / {

        }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/pan.hxp.plus/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/pan.hxp.plus/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}

        server {
    if ($host = pan.hxp.plus) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    server_name pan.hxp.plus;
    listen 80;
    return 404; # managed by Certbot

}}
```

配置 Cockpit 允许通过 Nginx 反向代理访问，编辑 `/etc/cockpit/cockpit.conf`：

`/etc/cockpit/cockpit.conf`

```
[WebService]
AllowUnencrypted = true

[Log]
Fatal = criticals

[WebService]
Origins = https://pan.hxp.plus http://127.0.0.1:9090
UrlRoot = /panel/
LoginTitle = hxp-us-server
```

修改 pcp 的压缩行为，编辑 `/etc/pcp/pmlogger/control`，取消注释以下行：

```
$PCP_COMPRESSAFTER=never
```

---

## 原文（English）

```
---
tags:
  - Fedora
  - Linux
---

```
yum install -y firewalld storaged cockpit cockpit-storaged
systemctl enable --now cockpit.socket
firewall-cmd --add-service=cockpit --permanent
```

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

`/etc/nginx/nginx.conf`

```
# For more information on configuration, see:

#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }

        server {

    server_name pan.hxp.plus;
    autoindex on;
    charset utf-8;
    root /usr/share/nginx/html;

    location /ray {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:10000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
            # Show realip in v2ray access.log
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /panel {
            proxy_redirect off;
            proxy_pass https://127.0.0.1:9090;
            proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_set_header Host $http_host;
    }

                location / {

        }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/pan.hxp.plus/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/pan.hxp.plus/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}

        server {
    if ($host = pan.hxp.plus) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    server_name pan.hxp.plus;
    listen 80;
    return 404; # managed by Certbot

}}
```

`/etc/cockpit/cockpit.conf`

```
[WebService]
AllowUnencrypted = true

[Log]
Fatal = criticals

[WebService]
Origins = https://pan.hxp.plus http://127.0.0.1:9090
UrlRoot = /panel/
LoginTitle = hxp-us-server
```

Change the compression behavior of pcp in `/etc/pcp/pmlogger/control`, uncomment

```
$PCP_COMPRESSAFTER=never
```
```
