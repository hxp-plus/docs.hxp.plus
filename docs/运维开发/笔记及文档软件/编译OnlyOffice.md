## 进入容器编译环境

编译需要用到 Ubuntu 20.04 ，目前该版本已经很远古，明智的做法是整一个 Ubuntu 20.04 的容器，使用以下 Dockerfile ：

```
FROM ubuntu:20.04

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get -y update && \
    apt-get -y install python2 \
                       python3 \
                       sudo
RUN ln -s /usr/bin/python2 /usr/bin/python
ADD . /build_tools
WORKDIR /build_tools

CMD cd tools/linux && \
    python3 ./automate.py
```

构建容器：

```
mkdir out
docker build --tag onlyoffice-document-editors-builder .
```

启动容器前需要禁用 IPv6 ：

```
sysctl -w net.ipv6.conf.all.disable_ipv6=1
```

启动容器并编译：

```
docker run --name onlyoffice_build -v $PWD/out:/build_tools/out onlyoffice-document-editors-builder
```

**之后的操作均在容器内运行。**

## 安装依赖

在容器环境内，需要安装依赖：

```
apt-get update && apt-get install -y python git sudo nodejs npm
npm cache clean -f //清除npm缓存，执行命令
npm install -g n //n模块是专门用来管理nodejs的版本，安装n模块
n 16.15.1 // 指定node安装版本
npm install -g npm@8.12.1 // 指定npm安装版本
node -v //查看node版本
npm -v //查看npm版本
```

## 下载源码

```
cd /build
git clone https://github.com/ONLYOFFICE/build_tools.git
```

## 编译源码

```
cd /build/build_tools/tools/linux/
./automate.py server
```

## 参考资料

https://helpcenter.onlyoffice.com/installation/docs-community-compile.aspx

https://blog.cyida.com/2022/2YTMY16.html

https://github.com/ONLYOFFICE/build_tools

https://www.btactic.com/build-onlyoffice-from-source-code-2023/?lang=en
