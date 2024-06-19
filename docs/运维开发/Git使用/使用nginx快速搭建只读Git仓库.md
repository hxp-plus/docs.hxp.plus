---
tags:
  - Git
  - Nginx
---

# 使用 nginx 快速搭建只读 Git 仓库

## 项目背景

对于有多地多个网络区域的大型公司，网络区域之间网络不通，同时每个网络区域都有一个 nginx 作为介质库，各个网络区域内所有主机可以访问本网络区域之间的介质库，介质库之间同步。同时需要使用 Git 来进行代码的管理，要求各个网络区域的主机都以只读的方式能访问到 Git 仓库来拉取代码。因此需要建立基于 HTTP 的 Git 仓库，同时尽量少地更改各地介质库的配置。

## 几种建立 Git 仓库的选择

### Smart HTTP 仓库

这个是 Git 官方推荐的使用 HTTP 建立 Git 仓库的方式，好处为建立好的 Git 仓库可读可写，但是官方只给了 Apache 的示例，如果使用 nginx，需要使用到第三方模块 fcgiwrap ，这就需要修改已有的 nginx ，同时，这个模块不是 RHEL 官方附带的，是否要安装到生产环境有待商榷。

### SSH 仓库

这个是最简单的建立 Git 仓库的方式，即只要有一个 SSH 服务器即可。缺点是 SSH 登录按照企业的规定，禁止空密码，这就必须每次拉代码的时候使用密码，或者建立 SSH 互信。且这种方式走的是 SSH 端口，对于这个需求而言不能满足。

### Dumb HTTP 仓库

当 Git 拉取 HTTP 仓库时，它会首先认为仓库是 Smart HTTP 仓库，服务器没有相应而失败后，主动回落到 Dumb HTTP 模式。这个模式完美符合此项目的要求，因为 Dumb HTTP 仓库只需要一个能正常工作的 HTTP 服务器，这意味着不需要修改 nginx 配置或者加入第三方模块。

## 建立 Dumb HTTP 仓库

以下 Dockerfile 是一个 Dumb HTTP 仓库的示例：

```
FROM redhat/ubi8:8.10
RUN yum install -y nginx git
WORKDIR /usr/share/nginx/html
RUN git clone --mirror https://github.com/hxp-plus/docs.hxp.plus.git docs.hxp.plus.git
RUN cd docs.hxp.plus.git && mv hooks/post-update.sample hooks/post-update && chmod a+x hooks/post-update && git update-server-info
COPY <<-'EOF' /etc/nginx/nginx.conf
daemon off;
user nginx;
worker_processes 1;
error_log /dev/stdout info;
pid /run/nginx.pid;
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}
http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  /dev/stdout  main;
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    server {
        listen                80 default_server;
        listen                [::]:80 default_server;
        server_name           _;
        root                  /usr/share/nginx/html;
        charset               utf-8;
        client_max_body_size  0;
        location / {
            autoindex on;
        }
    }
}
EOF
EXPOSE 80
CMD ["/sbin/nginx"]
```

可以看出，建立过程为大致以下几步：

1. 安装 git 和 nginx 。
2. 在 nginx 的根目录，克隆 git 仓库。
3. 修改克隆下的仓库的 post-update hook ，并运行一次 post-update hook 里的命令。
4. 配置 nginx ，使其能向外界提供 http 资源。

如果需要更新 nginx 上的 git 仓库，使用如下命令：

```
cd /usr/share/nginx/html/docs.hxp.plus.git
git fetch --all
```

# 参考资料

https://wiki.archlinux.org/title/Git_server

https://git-scm.com/book/en/v2/Git-on-the-Server-Smart-HTTP

https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols

https://cloud.tencent.com/developer/article/1921219
