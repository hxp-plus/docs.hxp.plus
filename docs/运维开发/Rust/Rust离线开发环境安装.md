# Rust 离线开发环境安装

## 安装准备

下载以下文件：

- rust-1.80.1-aarch64-unknown-linux-gnu.tar.xz
- rust-std-1.80.1-aarch64-unknown-linux-musl.tar.xz
- rust-src-1.80.1.tar.xz
- rustup-init

安装地址详见 <https://static.rust-lang.org/dist/channel-rust-stable.toml> 和 <https://rust-lang.github.io/rustup/installation/other.html>

## 配置安装路径

使用环境变量配置安装路径：

```bash
export RUST_INSTALL_DIR=${HOME}/softwares/rust
mkdir -p $RUST_INSTALL_DIR
```

如果中途退出安装，下次继续安装时需要重新设置这些环境变量。

## 安装 Rust

```bash
tar -xJf rust-1.80.1-aarch64-unknown-linux-gnu.tar.xz
./rust-1.80.1-aarch64-unknown-linux-gnu/install.sh --prefix=$RUST_INSTALL_DIR
```

## 安装 rustup

```bash
chmod +x ./rustup-init
./rustup-init --default-toolchain none -y
source ~/.bashrc
```

## 安装 toolchain

```bash
rustup toolchain link rust-1.80.1-aarch64-unknown-linux-gnu $RUST_INSTALL_DIR
rustup default rust-1.80.1-aarch64-unknown-linux-gnu
rustc --version
```

## 安装交叉编译 target

```bash
tar -xJf rust-std-1.80.1-aarch64-unknown-linux-musl.tar.xz
./rust-std-1.80.1-aarch64-unknown-linux-musl/install.sh --prefix=$RUST_INSTALL_DIR
```

## 安装 rust-src

```bash
tar -xJf rust-src-1.80.1.tar.xz
./rust-src-1.80.1/install.sh --prefix=$RUST_INSTALL_DIR
```

## 配置 config.toml

新建文件 `~/.cargo/config.toml` :

```toml
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
```

## 交叉编译

查看可用的 target ：

```bash
rustc --print target-list | grep musl | grep linux | grep aarch64
```

编译：

```bash
cargo build --target=aarch64-unknown-linux-musl --release
```

如果需要使用 crate 包，在线机器上运行 `cargo vendor` ，之后把 `vendor` 目录复制到用户的家目录下。
