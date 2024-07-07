---
tags:
  - Python
---

# Python 限制内存和 CPU 使用

## 项目需求

在使用 Python 进行监控或者自动化操作时，需要特别留意的一点就是 Python 本身的内存使用，譬如说你写了个 Python 程序，查看日志并在日志里提取关键字进行分析，然后在测试环境程序运行没有问题，但是在生产环境，大多数机器上运行的也没有问题，突然有那么一个机器，日志有几个 G，Python 写的时候没有考虑到这种情况，把几个 G 的日志都载入内存，导致服务器 OOM 故障。

因此需要有一种方式，让 Python 程序在内存使用达到一个数值后，申请内存失败而自我熔断。对于 CPU 资源同理需要限制。

## Linux 内存的管理机制

在 Linux 中，如果使用 `ps` 命令查看进程的内存使用，会有 `VSZ` 和 `RSS` 两个数值。其中 `VSZ` 为虚拟内存大小，即进程申请使用了多少内存，而 `RSS` 为驻留集大小，即实际这个进程使用了多少物理内存（包含与其它进程共享的内存）。Linux 的内存分配机制为懒分配，如果程序需要使用内存，就分配给程序，但直到程序真正尝试访问内存时，才真正把内存给程序。譬如说程序有很多函数，但是除非函数真正被调用，否则这些函数不会被加载进内存，这种情况下 `VSZ` 高但是 `RSS` 低，节约物理内存。

## 使用 resource 来配置 ulimit

首先观察这样一个 Python 程序（由于 RLIMIT_RSS 仅在 Linux 2.4.30 以下有用，故限制 RLIMIT_AS）：

```python
#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import print_function
import sys, signal, resource, time, os
from subprocess import Popen, PIPE


class Command:
    def __init__(self, command, time_limit):
        self.command = command
        self.time_limit = time_limit
        self.stdout = None
        self.stderr = None
        self.return_code = None

    def run(self):
        process = Popen(
            [
                "timeout",
                "-s",
                "9",
                str(self.time_limit),
                "/bin/bash",
                "-c",
                self.command,
            ],
            stdout=PIPE,
            stderr=PIPE,
        )
        out, err = process.communicate()
        self.stdout = out.decode()
        self.stderr = err.decode()
        self.return_code = process.returncode


class ResourceLimit:
    def set_memory_limit(self, size_mb):
        size_bytes = size_mb * 1024 * 1024
        resource.setrlimit(resource.RLIMIT_AS, (size_bytes, size_bytes))

    def get_memory_limit(self):
        soft, hard = resource.getrlimit(resource.RLIMIT_AS)
        print("[INFO] Current memory limit: %s (soft) %s (hard)" % (soft, hard))

    def get_memory_usage(self):
        command = Command(
            "ps -o user,pid,pcpu,pmem,vsz,rss,args -p %s" % os.getpid(), 5
        )
        command.run()
        print("==== MEMORY USAGE ====")
        print(command.stdout)

    def set_max_runtime(self, seconds):
        resource.setrlimit(resource.RLIMIT_CPU, (seconds, seconds))

    def get_max_runtime(self):
        soft, hard = resource.getrlimit(resource.RLIMIT_CPU)
        print("[INFO] Current runtime limit: %ss (soft) %ss (hard)" % (soft, hard))


def main():
    df = Command("df -PTh", 5)
    df.run()
    print("=== STDOUT ====\n%s" % df.stdout)
    print("=== STDERR ====\n%s" % df.stderr)
    print("RETURN CODE: %s" % df.return_code)
    sleep = Command("sleep 10", 5)
    sleep.run()
    print("=== STDOUT ====\n%s" % sleep.stdout)
    print("=== STDERR ====\n%s" % sleep.stderr)
    print("RETURN CODE: %s" % sleep.return_code)
    # while True:
    #     pass


if __name__ == "__main__":
    ResourceLimit().set_memory_limit(64)
    ResourceLimit().set_max_runtime(1)
    ResourceLimit().get_memory_limit()
    ResourceLimit().get_max_runtime()
    ResourceLimit().get_memory_usage()
    main()
    ResourceLimit().get_memory_usage()

```

这段代码中， `Command` 类用于执行系统命令， `ResourceLimit` 类用于限制系统的 CPU 和内存使用。每当执行`ResourceLimit().get_memory_usage()` 时，都调用系统的 `ps` 命令并打印出程序当前的内存大小，示例如下：

```
==== MEMORY USAGE ====
USER       PID %CPU %MEM    VSZ   RSS COMMAND
root       167  0.0  0.0  33280  5504 python main.py
```

这表示程序申请了 33MB 内存，但是实际使用了 5.5 MB 。同时，在这个程序中，我们限制了 CPU 运行时间 1 秒，如果把死循环的语句的注释拿掉，程序进入死循环后 1 秒就被 Kill ，但是在没有拿掉注释时，程序实际运行时间大于 1 秒。这个是正常现象，因为我们限制的是这个 python 进程的实际在 CPU 上使用的时间，不包含它 sleep 的时间和子进程的时间。可以用 time 命令得到实际在 CPU 上跑的时间：

```
time python src/main.py
```

time 命令显示实际程序用的现实时间是 5 秒，但是其在 CPU 上运行的时间只有 0.1 秒不到。

```
real    0m5.020s
user    0m0.016s
sys     0m0.006s
```

## 参考资料

https://linuxconfig.org/ps-output-difference-between-vsz-vs-rss-memory-usage

https://cloud.tencent.com/developer/article/1121759

https://unix.stackexchange.com/questions/375889/unix-command-to-tell-how-much-ram-was-used-during-program-runtime

https://docs.python.org/2/library/resource.html

https://www.geeksforgeeks.org/python-how-to-put-limits-on-memory-and-cpu-usage/
