---
tags:
  - Gentoo
  - Linux
---

# 如何查看 -march=native 会激活哪些编译器标志


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：[How to see which flags -march=native will activate?](https://stackoverflow.com/questions/5470257/how-to-see-which-flags-march-native-will-activate)

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
