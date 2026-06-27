---
tags:
  - Linux
  - 工具
---

 # Bug fix for Matlab R2020a black ui


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

If you install Matlab R2020a on Arch Linux, you may discover that if you open live script or help window, the Windows will be black with nothing shown, and no error message will be shown to you.

Here is the solution:

```bash
yay -S libsepol libselinux
sudo mkdir /usr/local/Polyspace/R2020a/cefclient/sys/os/glnxa64/0_excluded
sudo mv /usr/local/Polyspace/R2020a//cefclient/sys/os/glnxa64/libg* /usr/local/Polyspace/R2020a/cefclient/sys/os/glnxa64/0_excluded
```

