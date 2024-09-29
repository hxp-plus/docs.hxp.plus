# Rust 交叉编译环境离线安装

## 安装准备

下载以下文件：

- aarch64-linux-musl-cross.tgz
- rust-std-1.80.1-aarch64-unknown-linux-musl.tar.xz

其中 MUSL 交叉编译工具链下载地址见 <https://musl.cc> ，Rust 相关下载地址见 <https://static.rust-lang.org/dist/channel-rust-stable.toml>

## 安装 MUSL 交叉编译环境

```bash
tar -zxf aarch64-linux-musl-cross.tgz -C ~/softwares/rust/
```

修改 `~/.bashrc` ：

```bash
export PATH=~/softwares/rust/aarch64-linux-musl-cross/bin/:$PATH
```

```bash
source ~/.bashrc
```

## 安装目标版本 rust-std

解压 `rust-std` 并安装 ：

```bash
tar -xJf rust-std-1.80.1-aarch64-unknown-linux-musl.tar.xz
./rust-std-1.80.1-aarch64-unknown-linux-musl/install.sh --prefix=$HOME/softwares/rust/
```

## 配置 cargo

修改 `~/.cargo/config.toml` ：

```bash
[target.aarch64-unknown-linux-musl]
linker = "aarch64-linux-musl-ld"
```
