---
tags:
  - Linux
---

# BlackArch Linux 升级笔记

[BlackArch Linux](https://blackarch.org) is a Linux distribution based on Arch Linux, aiming at penetrate testing. It is somewhat an alternative to Kali Linux. Most importantly, Arch Linux can be upgraded to BlackArch directly. So if you are using Arch Linux currently as I do, and if you need Kali Linux, it is a good choice to upgrade your Arch Linux to BlackArch instead of repartitioning your disk and install Kali Linux.

To start the upgrading process, follow this [installation guide](https://blackarch.org/downloads.html). But there is something to notice.

run

```shell
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
sudo ./strap.sh
sudo pacman -S blackarch
```

To install as the official guide told us.

But, the installation was not so successfully for me. At first, it said

```shell
error: failed to prepare transaction (could not satisfy dependencies)
:: removing deepin-udis86 breaks dependency 'deepin-udis86' required by deepin-wine
```

The solution was to remove `deepin-udis86' and all the dependencies manually. And then install again.

```shell
sudo pacman -Rcns deepin-udis86
sudo pacman -S blackarch
```

And another error occurred.

```shell
error: failed retrieving file 'aesshell-0.7-4-any.pkg.tar.xz' from ftp.halifax.rwth-aachen.de : Operation too slow. Less than 1 bytes/sec transferred the last 10 seconds---------------]  38%
warning: failed to retrieve some files
```

That is because I use [TUNA mirror](https://mirrors.tuna.tsinghua.edu.cn/) to download packages quicker in China. Some packages are included in the mirror, while others are not. And the connection to foreign servers are not stable.

I have a V2Ray listening on localhost. Use the proxy to optimize the connection works.

Edit the environment variable to use proxy for pacman

```shell
export https_proxy="http://localhost:1080"
export http_proxy="http://localhost:1080"
```

And install BlackArch again

```shell
sudo pacman -S blackarch
```

Then I experienced "failed to commit transaction" errors.

```shell
python-quart: /usr/lib/python3.8/site-packages/quart/wrappers/__pycache__/__init__.cpython-38.pyc exists in filesystem
python-quart: /usr/lib/python3.8/site-packages/quart/wrappers/__pycache__/request.cpython-38.pyc exists in filesystem
python-quart: /usr/lib/python3.8/site-packages/quart/wrappers/__pycache__/response.cpython-38.pyc exists in filesystem
python-quart: /usr/lib/python3.8/site-packages/quart/wrappers/request.py exists in filesystem
python-quart: /usr/lib/python3.8/site-packages/quart/wrappers/response.py exists in filesystem
python-pypng: /usr/bin/prichunkpng exists in filesystem
python-pypng: /usr/bin/priforgepng exists in filesystem
python-pypng: /usr/bin/prigreypng exists in filesystem
python-pypng: /usr/bin/pripalpng exists in filesystem
python-pypng: /usr/bin/pripamtopng exists in filesystem
python-pypng: /usr/bin/pripnglsch exists in filesystem
python-pypng: /usr/bin/pripngtopam exists in filesystem
python-pypng: /usr/bin/priweavepng exists in filesystem
```

One solution is to run

```shell
sudo pacman -Syyu --needed blackarch --overwrite='*'
```

But strangely it did not work for me.

I ran

```shell
pip freeze > requirements.txt
pip uninstall -r requirements.txt -y
pip freeze | xargs pip uninstall -y
```

And if `pip` fails, replace it with `python -m pip`

Then came another error

```shell
ERROR: Cannot uninstall 'chrome-gnome-shell'. It is a distutils installed project and thus we cannot accurately determine which files belong to it which would lead to only a partial uninstall.

error: failed to commit transaction (conflicting files)
/usr/lib/python3.8/site-packages/tests/__init__.py exists in both 'python-telethon' and 'quark-engine'
/usr/lib/python3.8/site-packages/tests/__pycache__/__init__.cpython-38.opt-1.pyc exists in both 'python-telethon' and 'quark-engine'
/usr/lib/python3.8/site-packages/tests/__pycache__/__init__.cpython-38.pyc exists in both 'python-telethon' and 'quark-engine'
Errors occurred, no packages were upgraded.
```

I tried

```shell
sudo pacman -S --overwrite python-telethon quark-engine
```

as usual, but this error appeared again after I hit Enter.

I decided to install then independently, and solve the conflict manually.

```shell
sudo pacman -S quark-engine
sudo rm /usr/lib/python3.8/site-packages/tests/__init__.py
sudo rm /usr/lib/python3.8/site-packages/tests/__pycache__/__init__.cpython-38.opt-1.pyc
sudo rm /usr/lib/python3.8/site-packages/tests/__pycache__/__init__.cpython-38.pyc
sudo pacman -S python-telethon
```

It works!

After all, there were no more conflicts and errors.

```shell
sudo pacman -S blackarch
```

ran correctly.
