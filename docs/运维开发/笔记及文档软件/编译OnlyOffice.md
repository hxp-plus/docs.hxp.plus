# 编译 OnlyOffice 以解除 20 连接数限制

## 构建容器编译环境

编译需要用到 Ubuntu 20.04 ，目前该版本已经很远古，明智的做法是整一个 Ubuntu 20.04 的容器。新建目录 `onlyoffice` 作为本项目工作目录，创建 Dockerfile 如下：

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
docker run -d --name onlyoffice_build -v $PWD:/build onlyoffice-document-editors-builder
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
cd /build/build_tools/tools/linux
nohup ./automate.py server &
tail -f /build/build_tools/tools/linux/nohup.out
```

之后等待其编译完成，需要等待几个小时。

## 修改 OnlyOffice 最大连接数

修改 `./out/linux_64/onlyoffice/documentserver-snap/var/www/onlyoffice/documentserver/server/Common/sources/constants.js` ：

```
exports.LICENSE_CONNECTIONS = 20000;
```

修改 `/build/build_tools/tools/linux/automate.py` 中此处 `--update` 为 `0` ，使得下次编译不再更新文件：

```
build_tools_params = ["--branch", branch,
                      "--module", modules,
                      "--update", "0",
                      "--qt-dir", os.getcwd() + "/qt_build/Qt-5.9.9"] + params
```

之后重新启动容器编译源代码。

## 参考资料

https://helpcenter.onlyoffice.com/installation/docs-community-compile.aspx

https://blog.cyida.com/2022/2YTMY16.html

https://github.com/ONLYOFFICE/build_tools

https://www.btactic.com/build-onlyoffice-from-source-code-2023/?lang=en

https://zsy314.wordpress.com/tag/linux/
