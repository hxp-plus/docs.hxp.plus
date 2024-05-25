# 编译 OnlyOffice 以解除 20 连接数限制

## 构建容器编译环境

编译需要用到 Ubuntu 20.04 ，明智的做法是整一个 Ubuntu 20.04 的容器。在任意已经安装 docker 的机器上，新建目录 `onlyoffice` 作为本项目工作目录，创建 Dockerfile 如下：

```
FROM ubuntu:20.04

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get -y update && \
    apt-get -y install python2 \
                       python3 \
                       sudo \
                       git
RUN ln -s /usr/bin/python2 /usr/bin/python
WORKDIR /build

CMD /bin/bash -c 'while true;do sleep 3600;done'
```

构建容器：

```
docker build --tag onlyoffice-document-editors-builder .
```

启动容器前需要禁用 IPv6 ：

```
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
```

启动容器（需要在新创建的 `onlyoffice` 目录运行）：

```
docker rm onlyoffice_build
docker run -d --name onlyoffice_build -p 8701:80 -v $PWD:/build onlyoffice-document-editors-builder
```

容器后台启动完成后，进入容器：

```
docker exec -it onlyoffice_build /bin/bash
```

**之后的操作均在容器内运行。**

## 下载 build_tools 并开始编译

进入容器，下载`build_tools` 项目：

```
cd /build
git clone https://github.com/ONLYOFFICE/build_tools.git
```

使用 `build_tools` 项目编译：

```
cd /build/build_tools/tools/linux && ./automate.py server
```

之后等待其编译完成，需要等待几个小时。

## 修改 OnlyOffice 最大连接数

修改 `/build/server/Common/sources/constants.js` ：

```
exports.LICENSE_CONNECTIONS = 99999;
```

修改 `/build/build_tools/tools/linux/automate.py` 中此处 `--update` 为 `0` ，使得下次编译不再更新文件：

```
build_tools_params = ["--branch", branch,
                      "--module", modules,
                      "--update", "0",
                      "--qt-dir", os.getcwd() + "/qt_build/Qt-5.9.9"] + params
```

之后重新 编译源代码：

```
cd /build/build_tools/tools/linux && ./automate.py server
```

二次编译完成后，可以使用以下命令验证：

```
grep CONNECTIONS /build/build_tools/out/linux_64/onlyoffice/documentserver-snap/var
/www/onlyoffice/documentserver/server/Common/sources/constants.js
```

这里的 `exports.LICENSE_CONNECTIONS` 由 20 变为 99999 则为修改生效：

```
exports.LICENSE_CONNECTIONS = 99999;
```

## 试运行 documentserver

### 配置并启动 nginx

安装并清除 nginx 默认配置：

```
sudo apt-get install nginx
sudo rm -f /etc/nginx/sites-enabled/default
```

新建文件 `/etc/nginx/sites-available/onlyoffice-documentserver` 如下：

```
map $http_host $this_host {
  "" $host;
  default $http_host;
}
map $http_x_forwarded_proto $the_scheme {
  default $http_x_forwarded_proto;
  "" $scheme;
}
map $http_x_forwarded_host $the_host {
  default $http_x_forwarded_host;
  "" $this_host;
}
map $http_upgrade $proxy_connection {
  default upgrade;
  "" close;
}
proxy_set_header Host $http_host;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $proxy_connection;
proxy_set_header X-Forwarded-Host $the_host;
proxy_set_header X-Forwarded-Proto $the_scheme;
server {
  listen 0.0.0.0:80;
  listen [::]:80 default_server;
  server_tokens off;
  rewrite ^\/OfficeWeb(\/apps\/.*)$ /web-apps$1 redirect;
  location / {
    proxy_pass http://localhost:8000;
    proxy_http_version 1.1;
  }
}
```

使配置文件生效：

```
sudo ln -s /etc/nginx/sites-available/onlyoffice-documentserver /etc/nginx/sites-enabled/onlyoffice-documentserver
```

重启 nginx：

```
service nginx restart
```

### 配置并启动 postgresql

安装 postgresql 并启动：

```
sudo apt-get install postgresql
service postgresql restart
```

创建数据库和用户：

```
sudo -i -u postgres psql -c "CREATE DATABASE onlyoffice;"
sudo -i -u postgres psql -c "CREATE USER onlyoffice WITH password 'onlyoffice';"
sudo -i -u postgres psql -c "GRANT ALL privileges ON DATABASE onlyoffice TO onlyoffice;"
```

数据铺底：

```
psql -hlocalhost -Uonlyoffice -d onlyoffice -f /build/build_tools/out/linux_64/onlyoffice/documentserver/se
rver/schema/postgresql/createdb.sql # 密码为 onlyoffice
```

### 安装并启动 RabbitMQ

```
sudo apt-get install rabbitmq-server
service rabbitmq-server restart
```

### 生成字体和幻灯片主题

```
cd /build/build_tools/out/linux_64/onlyoffice/documentserver
mkdir fonts
LD_LIBRARY_PATH=${PWD}/server/FileConverter/bin server/tools/allfontsgen \
  --input="${PWD}/core-fonts" \
  --allfonts-web="${PWD}/sdkjs/common/AllFonts.js" \
  --allfonts="${PWD}/server/FileConverter/bin/AllFonts.js" \
  --images="${PWD}/sdkjs/common/Images" \
  --selection="${PWD}/server/FileConverter/bin/font_selection.bin" \
  --output-web='fonts' \
  --use-system="true"
LD_LIBRARY_PATH=${PWD}/server/FileConverter/bin server/tools/allthemesgen \
  --converter-dir="${PWD}/server/FileConverter/bin"\
  --src="${PWD}/sdkjs/slide/themes"\
  --output="${PWD}/sdkjs/common/Images"
```

### 运行 documentserver

启动 FileConverter ：

```
cd /build/build_tools/out/linux_64/onlyoffice/documentserver/server/FileConverter/
nohup bash -c 'LD_LIBRARY_PATH=$PWD/bin NODE_ENV=development-linux NODE_CONFIG_DIR=$PWD/../Common/config ./converter' &
```

启动 DocService ：

```
cd /build/build_tools/out/linux_64/onlyoffice/documentserver/server/DocService
nohup bash -c 'NODE_ENV=development-linux NODE_CONFIG_DIR=$PWD/../Common/config ./docservice' &
```

### 最终测试

使用官方的 [Java Spring Demo](https://api.onlyoffice.com/zh/editors/example/javaspring) 进行测试，该项目 GitHub 地址为：<https://github.com/ONLYOFFICE/document-server-integration/tree/master/web/documentserver-example/java-spring> ，也可以在 <https://api.onlyoffice.com/zh/editors/demopreview> 页面“选择编程语言并将在线编辑器集成示例的代码下载到您的网站”处下载。Spring 项目需要修改 `src/main/resources/application.properties` 的如下 2 行：

```
server.port=4000
files.docservice.url.site=http://ubuntu.hxp.lan:8701/
```

之后启动 Spring 后端，访问 <http://nuc.hxp.lan:4000/> 测试 Spring 后端是否能正常运作。（其中 ubuntu.hxp.lan 为 Document Server 的域名，而 nuc.hxp.lan 为后端 Spring 服务器域名，这两个域名可以使用 IP 地址代替）

## 参考资料

https://helpcenter.onlyoffice.com/installation/docs-community-compile.aspx

https://blog.cyida.com/2022/2YTMY16.html

https://github.com/ONLYOFFICE/build_tools

https://www.btactic.com/build-onlyoffice-from-source-code-2023/?lang=en

https://zsy314.wordpress.com/tag/linux/
