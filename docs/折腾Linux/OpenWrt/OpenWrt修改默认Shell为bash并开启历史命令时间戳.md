---
tags:
  - OpenWrt
  - DDNS
---

# OpenWrt 修改默认 Shell 为 bash 并开启历史命令时间戳

## 安装并配置 bash

安装 bash

```bash
opkg update && opkg install bash
```

检查 `/etc/shells` 中有 `/bin/bash` 后，修改 root 用户的 shell 解释器，编辑 `/etc/passwd` 文件，修改第一行（第一行就是 root 用户）中的 `/bin/ash` ，改成 `/bin/bash` ，重启路由器。

## 配置命令时间戳记录

新建配置 `/etc/profile.d/history.sh` ：

```bash
export PROMPT_COMMAND='history -a'
export HISTTIMEFORMAT="[ %F %T ] ($USER) || "
export HISTFILESIZE=100000
export HISTSIZE=100000
```

## 参考资料

<https://hellodk.cn/post/472>
