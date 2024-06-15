---
tags:
  - Python
---

# 基于 Python 的模块化监控工具的开发

## 项目背景

大型公司有非常多的定制化监控需求， Zabbix 、 Prometheus 等监控工具不能满足，必须运维人员开发定制的脚本实现监控。但是在开发的过程中，遇到了以下几点困难：

1. 随着需求的增加，每增加一个监控项，就增加一个脚本。脚本使用 crontab 进行运行， crontab 越加越多，且项目的文件越来越多， crontab 也越来越多。随着项目的发展，越来越不好维护。
2. 代码可重复利用率低，很多的脚本都需要实现一个共同或相似的功能，事实上项目里是相同的代码不停在不同脚本中复制粘贴，且一旦共性的代码被修改，所有脚本都需要修改。
3. 代码 BUG 无法避免，由于脚本使用 Shell 进行开发， Shell 语法中并没有变量类型的概念，经常是脚本执行了一个命令，命令没有按照期望返回，但是 Shell 继续执行，并没有像其它语言在类型转换时抛出异常。同时， Shell 中比较大小经常由于小数和整数比较大小的问题，或者将小数转化为整数的问题，导致脚本得到的数据和阈值数据比较结果不正确。

## Python 项目的打包方式比较

对于这个项目，显然需要将 Python 项目进行打包，否则还是会有随着项目的推进、往服务器上部署的脚本文件越来越多的问题。目前 Python 项目的打包大致有使用 PyInstaller 和 zipapp 两种方式。不推荐使用 PyInstaller 的原因为：PyInstaller 虽然不需要目标主机安装 Python，但是它在运行的时候会在 /tmp 下创建临时目录存放 Python 代码，如果遇到了问题中途崩溃，则临时目录不会被清空。这会导致如果程序代码有问题，随着 crontab 不断调用代码会导致 /tmp 目录下子目录越来越多。

如果使用 zipapp 方式，则需要给所有的机器通过解压的方式安装一个 Python3 供项目运行使用。本次示例将 Python-3.7.17 解压和项目放到了 `/opt/Python-3.7.17` 目录下。

## 项目结构

项目的结构如下：

```
.
├── build.sh
├── dist
│   └── monitor.pyz
├── run.sh
└── src
    ├── monitor.py
    └── utils
        └── command.py
```

其中 dist 目录为存放打包好 Python 项目的目录。

## 项目核心 Python 代码架构

目录 `src` 下为监控工具代码，其中 `monitor.py` 为程序的入口：

```Python
from utils.command import run

def main():
    ls_result=run(['ls', '-lh'])
    print(ls_result)
    cat_result=run(['cat', '/proc/meminfo'])
    print(cat_result)
    cat_result=run(['cat', '/tmp/100MB.bin'])
    print(cat_result)

if __name__ == '__main__':
    main()
```

所有的功能以模块的形式放在 `utils` 下，其中 `utils/command.py` 为 Shell 命令相关的模块，模块里有个函数 `run` 是用来运行命令并返回命令运行结果的：

```Python
import subprocess

def run(cmd):
    return subprocess.check_output(cmd).decode('utf-8').split('\n')

```

如果日后有新增模块的需求，譬如说增加 HBA 卡状态监控，则新建 Python 文件 `utils/hba.py` ，并在里面写相应的函数来实现监控，最后在 `monitor.py` 里调用。

## 项目的构建与运行

`run.sh` 为运行项目的脚本，如下：

```Shell
#!/bin/bash
ulimit -v 128000 # Limit memory usage to 128MiB
PYTHON_INSTALL_DIR=/opt/Python-3.7.17/
LOG_FILE=/tmp/systemmon.out
export PATH=$PYTHON_INSTALL_DIR/bin:$PATH
export LD_LIBRATY_PATH=$PYTHON_INSTALL_DIR/lib:$LD_LIBRATY_PATH
echo "Current Python version is: $(python3 --version)"
python3 dist/monitor.pyz 2>&1 | tee -a $LOG_FILE
```

在这个脚本里使用 ulimit 限制了 Python 程序在执行时，最高消耗 128MB 内存，如果超过限制，Python 会报错 `MemoryError` 并被杀死。可将此脚本加到 crontab 里定时执行来实现监控，同时脚本所有的输出，用 `tee -a` 的方式重定向到了变量 `LOG_FILE` 定义的日志文件。

`build.sh` 为打包 Python 的脚本：

```Shell
#!/bin/bash
PYTHON_INSTALL_DIR=/opt/Python-3.7.17/
APP_NAME=monitor
export PATH=$PYTHON_INSTALL_DIR/bin:$PATH
export LD_LIBRATY_PATH=$PYTHON_INSTALL_DIR/lib:$LD_LIBRATY_PATH
echo "Current Python version is: $(python3 --version)"
mkdir -p dist
python3 -m zipapp src -o dist/$APP_NAME.pyz -m "monitor:main"
```

这个脚本负责将 `src` 目录下的所有代码打包成为 pyz 格式的 Python 包，并将其放在 `dist` 目录下。
