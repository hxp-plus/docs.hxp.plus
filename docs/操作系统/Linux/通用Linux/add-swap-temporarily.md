---
tags:
  - Linux
  - Swap
---

# Linux VPS 临时添加 Swap

# "Killed" error during make

When I tried to compile and install libtorrent on CentOS 7 server, I got a "Killed" error like this

```
g++: internal compiler error: Killed (program cc1plus)
Please submit a full bug report,
```

# Memory exhausted during compiling process

Thanks [Jon Combe](https://stackoverflow.com/users/5841226/jon-combe) from [Stack Overflow](https://stackoverflow.com/questions/30887143/make-j-8-g-internal-compiler-error-killed-program-cc1plus). It occurred me that perhaps the memory isn't sufficient. Due to the VPS environment, there is only 500 Mb of RAM and 256Mb of swap in total.

Of course, the most easiest way to solve this problem, is to pay more money to the VPS provider. But there's another way.

# Detect if the memory is insufficient

After the make process exited with "Killed" error, run `dmesg` immediately to show kernel message. And if you found something like `Out of memory: Kill process 23747 (cc1plus)`, that means the problem is just what we are talking about.

You can also run `make` in the background, run `df -lh` repeatedly.

# Spare some space in your storage to swap

First, make a disk image using dd

```
dd if=/dev/zero of=/swapfile bs=64M count=16
```

Change `count=16` to a larger number if more swap space is required.

Then, run

```
mkswap /swapfile
swapon /swapfile
```

Run `df -lh` to show the new RAM and swap status.

# Clean after use

After compiling, remember to delete the swap image to free your disk space.

```
swapoff /swapfile
rm /swapfile
```
