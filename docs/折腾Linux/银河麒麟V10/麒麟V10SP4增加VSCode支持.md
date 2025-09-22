---
tags:
  - Linux
  - 银河麒麟V10
  - VSCode
---

# 麒麟 V10SP4 增加 VSCode 支持

VSCode 自 1.99 版本开始抛弃了对旧版本 Linux 的支持，对于旧版本需要额外进行一些配置才能使用。

## 安装编译依赖

```bash
yum group install -y 'Development Tools'
yum install -y texinfo help2man ncurses-libs ncurses-devel libstdc++-static
```

## 安装 crosstool-ng

```bash
wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.26.0.tar.bz2
tar -xjf crosstool-ng-1.26.0.tar.bz2
cd crosstool-ng-1.26.0
./configure --prefix=/opt/crosstool-ng-1.26.0
make
make install
```

## 编译新 sysroot

新建 `.config` 文件：

```bash
mkdir /opt/crosstool-ng-1.26.0/toolchain
cd /opt/crosstool-ng-1.26.0/toolchain
wget -O .config 'https://raw.githubusercontent.com/microsoft/vscode-linux-build-agent/refs/heads/main/x86_64-gcc-8.5.0-glibc-2.28.config'
```

编辑 `.config` 文件，将以下行插入到最开始位置以允许使用 root 构建：

```config
CT_EXPERIMENTAL=y
CT_ALLOW_BUILD_AS_ROOT=y
CT_ALLOW_BUILD_AS_ROOT_SURE=y
```

用 `make menuconfig` 修改 gcc 版本：

```bash
/opt/crosstool-ng-1.26.0/bin/ct-ng menuconfig
```

进入 `C compiler` -> `Version of gcc` ，将其修改为 `6.5.0` ，进入 `Operating System` -> `Version of linux` ，将其修改为 `4.18.20` ，保存退出后开始编译：

```bash
/opt/crosstool-ng-1.26.0/bin/ct-ng build
```

## 安装 patchelf

```bash
cd /tmp
wget https://github.com/NixOS/patchelf/releases/download/0.18.0/patchelf-0.18.0-x86_64.tar.gz
mkdir /opt/patchelf-0.18.0
tar -zxvf patchelf-0.18.0-x86_64.tar.gz -C /opt/patchelf-0.18.0
```

## 设置环境变量

新建文件 `/etc/profile.d/vscode.sh` ：

```bash
#!/bin/bash
export VSCODE_SERVER_CUSTOM_GLIBC_LINKER=/opt/crosstool-ng-1.26.0/toolchain/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/lib/ld-2.28.so
export VSCODE_SERVER_CUSTOM_GLIBC_PATH=/opt/crosstool-ng-1.26.0/toolchain/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/lib64
export VSCODE_SERVER_PATCHELF_PATH=/opt/patchelf-0.18.0/bin/patchelf
```

## 启用 sshd 的 AllowTcpForwarding

编辑 `/etc/ssh/sshd_config`，将 `AllowTcpForwarding` 设置为 `yes`后，重启 sshd 服务：

```bash
sshd -t && systemctl restart sshd
```

## 参考链接

- <https://code.visualstudio.com/docs/remote/faq#_can-i-run-vs-code-server-on-older-linux-distributions>
