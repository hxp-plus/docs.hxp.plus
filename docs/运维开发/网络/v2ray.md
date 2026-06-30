---
tags:
  - VPN
  - V2Ray
  - Nginx
---

# V2Ray (TLS + WebSocket) + Nginx 教程

# Install v2ray

To deploy V2Ray on CentOS, we use the [installation instruction](https://www.v2ray.com/en/welcome/install.html) on V2Ray official site.

run

```shell
curl -Ls https://install.direct/go.sh | sudo bash
```

and wait the installation process to complete.

# Install Nginx

Install via yum

```shell
yum install nginx
```

# Write the V2Ray config file

The V2Ray config file is located in `/etc/v2ray/config.json`

Edit the config file

```shell
nano /etc/v2ray/config.json
```

For starters, I would suggest using [v2ray config generator](https://www.veekxt.com/utils/v2ray_gen) to generate config.

Here is a sample config, which I am currently using. I put it here for reference. **Change uuid for your own security**

You may get a random uuid here: [Online UUID Generator](https://www.uuidgenerator.net/)

```json
{
  "inbounds": [
    {
      "port": 10000,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "cd6e4579-7a1f-4784-91dd-e0e9e788c7ee",
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/ray"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
```

For this config we can see that V2Ray listens on localhost, so that V2Ray ports cannot be connected or detected from the outside web.

Reload the V2Ray service.

```shell
systemctl restart v2ray
```

To determine whether v2ray runs correctly, run

```shell
systemctl status v2ray
```

If on errors occurred, enable v2ray service so that it can start automatically on server startup.

```shell
systemctl enable v2ray
```

# Using acme.sh to install SSL cert for nginx

In this tutorial we install cert in default location. Firstly, make directories and install acme.sh

```shell
curl https://get.acme.sh | sh
mkdir /etc/pki/nginx/
mkdir /etc/pki/nginx/private/
```

Then we can use acme.sh to issue and renew certs automatically.

acme.sh requires `socat`

```shell
yum install socat
```

You need to stop nginx before these following steps.

```shell
systemctl stop nginx
```

I assume your domain name is `yourdomain.com`

```shell
sudo ~/.acme.sh/acme.sh --issue -d yourdomain.com --standalone -k ec-256
sudo ~/.acme.sh/acme.sh --renew -d yourdamain.com --force --ecc
sudo ~/.acme.sh/acme.sh --installcert -d yourdomain.com --fullchainpath /etc/pki/nginx/server.crt --keypath /etc/pki/nginx/private/server.key --ecc
```

# Use Nginx to forward port 443 to v2ray

Edit `/etc/nginx/nginx.conf`

One possible version (compatible with the v2ray config above, _Remember to change server_name to your domain name_)

```conf
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
        server_name  yourdomain.com;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
		 proxy_pass         https://dev-hxp.github.io;
		 proxy_redirect     off;
		 proxy_set_header   User-Agent "Mozilla/5.0";
		 proxy_set_header   Host                        $host;
		 proxy_set_header   X-Real-IP                $remote_addr;
		 proxy_set_header   X-Forwarded-For    $proxy_add_x_forwarded_for;
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }

# Settings for a TLS enabled server.

    server {
        listen       443 ssl;
	ssl on;
        server_name  yourdomain.com;
        ssl_certificate "/etc/pki/nginx/server.crt";
        ssl_certificate_key "/etc/pki/nginx/private/server.key";
	ssl_protocols         TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers           HIGH:!aNULL:!MD5;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

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

        location / {
		 proxy_pass         https://dev-hxp.github.io;
		 proxy_redirect     off;
		 proxy_set_header   User-Agent "Mozilla/5.0";
		 proxy_set_header   Host                        $host;
		 proxy_set_header   X-Real-IP                $remote_addr;
		 proxy_set_header   X-Forwarded-For    $proxy_add_x_forwarded_for;
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }

}
```

And I forwarded port 80 to my blog. So that if someone visits the server in web browser, he will certainly see my blog.

Restart Nginx to load the config

```shell
systemctl restart nginx
systemctl enable nginx
```

# Firewall configuration

Allow port 80 and 443 for your server. For CentOS, you may use `firewallcmd`. But I use Alibaba Cloud server. So as for me, I use the Alibaba Cloud Console to allow the ports.

Then connect your clients to your server and have fun.

# Congrats, you are done!

But there are 3 things to remember:

- Connect V2Ray through port 443 instead of 10000
- Enable TLS in V2Ray
- Enable WebSocket and the path of websocket should be /ray
