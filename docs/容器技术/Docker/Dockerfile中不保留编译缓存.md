---
tags:
  - Docker
---

# Dockerfile 中不保留编译缓存

在构建 OnlyOffice 的 Docker 镜像时，需要在 Dockerfile 里下载源代码并编译，但是源代码编译后，编译的缓存由 40GB，导致镜像最终由 44GB，但是实际有用的只是编译后的二进制文件。原先的 Dockerfile 如下：

```Dockerfile
FROM ubuntu:20.04

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get -y update && \
    apt-get -y install python2 \
                       python3 \
                       sudo \
                       git \
                       postgresql \
                       rabbitmq-server \
                       nginx
RUN ln -s /usr/bin/python2 /usr/bin/python
WORKDIR /build

RUN git clone https://github.com/ONLYOFFICE/build_tools.git
RUN cd /build/build_tools/tools/linux && ./automate.py server
RUN sed -i 's/exports.LICENSE_CONNECTIONS = 20;/exports.LICENSE_CONNECTIONS = 99999;/' /build/server/Common/sources/constants.js
RUN sed -i 's/"--update", "1"/"--update", "0"/' /build/build_tools/tools/linux/automate.py
RUN cd /build/build_tools/tools/linux && ./automate.py server
```

这个 Dockerfile 构建出的镜像中，只有 `/build/build_tools/out/linux_64/onlyoffice/documentserver` 中的文件有用，其它文件没有用。如果尝试在 Dockerfile 中将其 `rm -rf` 掉，会不起作用。因为写入 image layer 的东西是删不掉的。这时候就需要使用 Dockerfile 的多阶段构建：

```Dockerfile
FROM ubuntu:20.04

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get -y update && \
    apt-get -y install python2 \
                       python3 \
                       sudo \
                       git \
                       postgresql \
                       rabbitmq-server \
                       nginx
RUN ln -s /usr/bin/python2 /usr/bin/python
WORKDIR /build

RUN git clone https://github.com/ONLYOFFICE/build_tools.git
RUN cd /build/build_tools/tools/linux && ./automate.py server
RUN sed -i 's/exports.LICENSE_CONNECTIONS = 20;/exports.LICENSE_CONNECTIONS = 99999;/' /build/server/Common/sources/constants.js
RUN sed -i 's/"--update", "1"/"--update", "0"/' /build/build_tools/tools/linux/automate.py
RUN cd /build/build_tools/tools/linux && ./automate.py server

FROM ubuntu:20.04
COPY --from=0 /build/build_tools/out/linux_64/onlyoffice/documentserver /var/www/html/
RUN apt-get -y update && apt-get -y install nginx

CMD /bin/bash -c 'while true;do sleep 3600;done'
```

即先构建一个编译镜像，然后把编译镜像里生成的有用的东西复制到第二个镜像，再构建第二个镜像。

同时，编译完成以后，还需要清理 docker 的 overlay2 里的缓存等其它缓存：

```
docker system prune -a
```

## 参考链接

https://docs.docker.com/build/building/multi-stage/
