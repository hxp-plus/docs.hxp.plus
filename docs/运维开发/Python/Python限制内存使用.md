---
tags:
  - Python
---

# Python 限制内存使用

## 项目需求

在使用 Python 进行监控或者自动化操作时，需要特别留意的一点就是 Python 本身的内存使用，譬如说你写了个 Python 程序，查看日志并在日志里提取关键字进行分析，然后在测试环境程序运行没有问题，但是在生产环境，大多数机器上运行的也没有问题，突然有那么一个机器，日志有几个 G，Python 写的时候没有考虑到这种情况，把几个 G 的日志都载入内存，导致服务器 OOM 故障。

因此需要有一种方式，让 Python 程序在内存使用达到一个数值后，申请内存失败而自我熔断。

## Linux 内存的管理机制

在 Linux 中，如果使用 `ps` 命令查看进程的内存使用，会有 `VSZ` 和 `RSS` 两个数值。其中 `VSZ` 为虚拟内存大小，即进程申请使用了多少内存，而 `RSS` 为驻留集大小，即实际这个进程使用了多少物理内存（包含与其它进程共享的内存）。Linux 的内存分配机制为懒分配，如果程序需要使用内存，就分配给程序，但直到程序真正尝试访问内存时，才真正把内存给程序。譬如说程序有很多函数，但是除非函数真正被调用，否则这些函数不会被加载进内存，这种情况下 `VSZ` 高但是 `RSS` 低，节约物理内存。

## 使用 resource 来配置 ulimit

首先观察这样一个 Python 程序（由于 RLIMIT_RSS 仅在 Linux 2.4.30 以下有用，故限制 RLIMIT_AS）：

```python
#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import print_function
import sys
import resource
from subprocess import Popen, PIPE
import time

def run(cmd):
    process = Popen(cmd, stdout=PIPE, stderr=PIPE)
    output, err = process.communicate()
    return output,err

def memory_limit(size_kb):
    soft, hard = resource.getrlimit(resource.RLIMIT_AS)
    resource.setrlimit(resource.RLIMIT_AS, (size_kb * 1024, hard))

def main():
    stdout,stderr=run(['df', '-PTh'])
    time.sleep(60)
    print(stdout)
    print(stderr)

if __name__ == '__main__':
    memory_limit(102400)
    try:
        main()
    except MemoryError:
        sys.stderr.write('ERROR: Memory exceeded\n')
        sys.exit(1)
```

执行这段代码，在这段代码正在 sleep 的时候，使用 `ps aux` 命令查询到其占用的 `VSZ` 为 `33316 KB`，`RSS` 为 `5504 KB` ：

```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root       160  0.0  0.0  33316  5504 pts/0    S+   12:47   0:00 python test.py
```

将代码中的 `memory_limit(102400)` 修改为 `memory_limit(33000)` ，程序报错无法分配内存，修改为 `memory_limit(35000)` 则又可以恢复运行，证明这个限制内存使用方法有效。

## 参考资料

https://linuxconfig.org/ps-output-difference-between-vsz-vs-rss-memory-usage

https://cloud.tencent.com/developer/article/1121759

https://unix.stackexchange.com/questions/375889/unix-command-to-tell-how-much-ram-was-used-during-program-runtime
