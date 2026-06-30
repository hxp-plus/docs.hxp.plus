---
tags:
  - GCC
  - Linux
---

# 从源码编译安装 GCC 12

## Obtaining the source code

Download `gcc-12.1.0.tar.xz` from <https://bigsearcher.com/mirrors/gcc/releases/gcc-12.1.0/>, and untar it with:

```bash
tar Jxvf gcc-12.1.0.tar.xz
```

## Download Prerequisites

```bash
cd gcc-12.1.0/
./contrib/download_prerequisites
```

```
hxp@mhd ~/data/gcc-12.1.0 $ ./contrib/download_prerequisites
failed: Connection timed out.
2022-08-18 01:22:32 URL:http://gcc.gnu.org/pub/gcc/infrastructure/gmp-6.2.1.tar.bz2 [2493916/2493916] -> "gmp-6.2.1.tar.bz2" [1]
failed: Connection timed out.
2022-08-18 01:24:43 URL:http://gcc.gnu.org/pub/gcc/infrastructure/mpfr-4.1.0.tar.bz2 [1747243/1747243] -> "mpfr-4.1.0.tar.bz2" [1]
failed: Connection timed out.
2022-08-18 01:26:54 URL:http://gcc.gnu.org/pub/gcc/infrastructure/mpc-1.2.1.tar.gz [838731/838731] -> "mpc-1.2.1.tar.gz" [1]
failed: Connection timed out.
2022-08-18 01:29:06 URL:http://gcc.gnu.org/pub/gcc/infrastructure/isl-0.24.tar.bz2 [2261594/2261594] -> "isl-0.24.tar.bz2" [1]
gmp-6.2.1.tar.bz2: OK
mpfr-4.1.0.tar.bz2: OK
mpc-1.2.1.tar.gz: OK
isl-0.24.tar.bz2: OK
All prerequisites downloaded successfully.
```

## Configure

I install GCC-12 in `~/data/software/gcc-12.1.0`, and I do not need to compile languages other than C, C++ and Fortran.

```bash
./configure --prefix=${HOME}/data/software/gcc-12.1.0 --enable-languages=c,c++,fortran
```

## Make

```bash
make -j$(nproc)
```

## Install

```bash
make install
```

## (Optional) Add a module file to load environment variables via Lmod

create `gcc-12.1.0.lua`

```lua
prepend_path("PATH", "/home/hxp/data/software/gcc-12.1.0/bin")
prepend_path("LD_LIBRARY_PATH","/home/hxp/data/software/gcc-12.1.0/lib/../lib64")
prepend_path("LD_RUN_PATH","/home/hxp/data/software/gcc-12.1.0/lib/../lib64")
```
