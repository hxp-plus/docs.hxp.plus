---
tags:
  - Shell
---

# Shell 设置变量未赋值或遇到错误立刻退出

## 问题背景

众所周知 Shell 是一个不安全的语言，变量不被定义也可以被访问，而且一行命令报错以后，不是像其它语言似的退出，而是接着运行下面的命令。通过修改 Shell 脚本的一些设置，可以暂时弥补下这个问题。

## 每个 Shell 脚本都推荐增加的参数

推荐在每个 Shell 脚本前都加入以下语句：

```bash
set -o errexit
set -o nounset
set -o pipefail
```

其中 `set -o errexit` 等同于 `set -e` ,作用为有一行命令报错立刻退出。 `set -o nounset` 等同于 `set -u` ，作用为在访问未定义变量时报错。 `set -o pipefail` 作用为对于单行命令，返回值不再是最右侧命令返回值，而是在返回值不为零的命令中，取最右侧的作为返回值。

## 参考资料

https://medium.com/factualopinions/consider-starting-all-your-bash-scripts-with-these-options-74fbec0cbb83

https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin
