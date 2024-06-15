---
tags:
  - Python
---

# 构建解压即用的 Python3

## 背景

在复杂的运维场景下，不同的 Linux 操作系统的 Python 版本不一，有的操作系统是 Python2，有的是 Python3 ，且即使都 Python3，各个操作系统的 Python3 的版本也不一样。如果我们要发布一个程序，譬如说监控程序，需要让不同的操作系统都能运行，则需要把所有操作系统都适配一遍，且每次更新都需要适配。不如直接单独带一个 Python 到所有的操作系统中。

## 编译一份 Python3 并将其安装到 /opt 目录

由于不同版本的 Linux 的 glibc 版本不同，且高版本的 glibc 兼容低版本，反之不兼容，因此需要在你需要适配的最低版本 Linux 上编译，我这里选用的 CentOS 6 ，同时，编译不需要真的安装 CentOS 6 ，可以使用 docker 容器并在容器里编译。我的 Dockerfile 如下：

```
FROM centos:6.10
COPY <<-'EOF' /etc/yum.repos.d/CentOS-Base.repo
[base]
name=CentOS-$releasever - Base
baseurl=https://vault.centos.org/6.10/os/$basearch/
gpgcheck=0
EOF
RUN yum install -y make gcc zlib-devel
RUN mkdir -p /build
WORKDIR /build
RUN curl https://www.python.org/ftp/python/3.7.17/Python-3.7.17.tgz -o Python-3.7.17.tgz
RUN tar -zxf Python-3.7.17.tgz -C /build
WORKDIR /build/Python-3.7.17
RUN ./configure --prefix=/opt/Python-3.7.17
RUN make install
WORKDIR /opt
VOLUME /opt
CMD ["/bin/bash"]
```

使用 docker 构建一个容器并在容器里编译出 Python3，安装到容器的 /opt 目录：

```
docker build -t centos6-python3.7 .
```

之后将容器内编译好的 Python3 复制出来：

```
mkdir -p dist
docker run --rm -v ./dist:/mnt centos6-python3.7 /bin/bash -c 'cd /opt && /bin/tar zcpf /mnt/Python-3.7.17.tgz Python-3.7.17'
```

## 使用 Python3

将整个 Python-3.7.17 目录复制到别的机器上，运行前设置环境变量：

```
export PATH=$PWD/Python-3.7.17/bin:$PATH
export LD_LIBRATY_PATH=$PWD/Python-3.7.17/lib:$LD_LIBRATY_PATH
echo "Current Python version is: $(python3 --version)"
```

之后使用 python3 命令执行。
