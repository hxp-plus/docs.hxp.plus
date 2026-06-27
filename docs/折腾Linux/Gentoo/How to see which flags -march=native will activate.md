---
tags:
  - Gentoo
  - Linux
---

# [How to see which flags -march=native will activate?](https://stackoverflow.com/questions/5470257/how-to-see-which-flags-march-native-will-activate)


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

If you want to find out how to set-up a non-native cross compile, I found this useful:

On the target machine,

```c
% gcc -march=native -Q --help=target | grep march
-march=                               core-avx-i
```

Then use this on the build machine:

```c
% gcc -march=core-avx-i ...
```

