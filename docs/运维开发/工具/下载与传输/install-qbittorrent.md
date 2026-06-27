---
tags:
  - Linux
  - 工具
---

# Install qbittorrent with nginx reverse proxy on Fedora Cloud


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 安装并启动 qbittorrent

通过 `yum` 安装

```bash
yum install qbittorrent
yum install qbittorrent-nox
```

运行 `qbittorrent-nox`

```bash
qbittorrent-nox
```

添加用户 `qbtuser`

```bash
useradd qbtuser
```

将 `qbittorrent-nox` 添加到 `systemctl`

```bash
nano /usr/lib/systemd/system/qbittorrent.service
```

```
[Unit]
Description=qbittorrent torrent server

[Service]
User=qbtuser   
ExecStart=/usr/bin/qbittorrent-nox --webui-port=8080
Restart=on-abort

[Install]
WantedBy=multi-user.target
```

重新加载 `systemctl`

```bash
systemctl daemon-reload
```

在 `systemctl` 中启用 `qbittorrent`

```bash
systemctl enable qbittorrent --now
```

## 添加 Nginx 反向代理

编辑 `/etc/nginx/default.d/qbittorrent.conf`，添加

```
location /qbt/ {
    proxy_pass              http://localhost:8080/;
    proxy_set_header        X-Forwarded-Host        $server_name:$server_port;
    proxy_hide_header       Referer;
    proxy_hide_header       Origin;
    proxy_set_header        Referer                 '';
    proxy_set_header        Origin                  '';
    add_header              X-Frame-Options         "SAMEORIGIN";
}
```

并记得检查

```
include default.d/*.conf;
```

是否存在于你的 `nginx.conf` 中

测试 Nginx 配置

```bash
nginx -t
```

并重启 Nginx

```bash
systemctl restart nginx
```

qbittorrent 的默认用户名和密码是 `admin` 和 `adminadmin`

---

## 原文（English）

## Install and start qbittorrent

Install via `yum`

```bash
yum install qbittorrent
yum install qbittorrent-nox
```

Run `qbittorrent-nox`

```bash
qbittorrent-nox
```

Add user `qbtuser`

```bash
useradd qbtuser
```

Add `qbittorrent-nox` to `systemctl`

```bash
nano /usr/lib/systemd/system/qbittorrent.service
```

```
[Unit]
Description=qbittorrent torrent server

[Service]
User=qbtuser   
ExecStart=/usr/bin/qbittorrent-nox --webui-port=8080
Restart=on-abort

[Install]
WantedBy=multi-user.target
```

Reload `systemctl`

```bash
systemctl daemon-reload
```

Enable `qbittorrent` in `systemctl`

```bash
systemctl enable qbittorrent --now
```

## Add Nginx reverse proxy

Edit `/etc/nginx/default.d/qbittorrent.conf`, add

```
location /qbt/ {
    proxy_pass              http://localhost:8080/;
    proxy_set_header        X-Forwarded-Host        $server_name:$server_port;
    proxy_hide_header       Referer;
    proxy_hide_header       Origin;
    proxy_set_header        Referer                 '';
    proxy_set_header        Origin                  '';
    add_header              X-Frame-Options         "SAMEORIGIN";
}
```

And remember to check

```
include default.d/*.conf;
```

exist in your `nginx.conf`

Test Nginx config

```bash
nginx -t
```

and restart Nginx

```bash
systemctl restart nginx
```

the default username and password for qbittorrent is`admin` and `adminadmin`
