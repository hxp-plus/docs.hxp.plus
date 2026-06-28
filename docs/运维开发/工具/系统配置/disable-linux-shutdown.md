---
tags:
  - Linux
  - 工具
---

# 禁用 Linux 关机


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Disable Linux Shutdown

*WARNING:* This approach will disable systemctl commands as a side effect.

Edit `/etc/sudoers`

```bash
visudo
```

Add

```
Cmnd_Alias      REBOOT = /sbin/halt, /sbin/reboot, /sbin/poweroff, /usr/bin/shu
tdown, /bin/shutdown
root ALL=(ALL) ALL, !REBOOT
%wheel ALL=(ALL) ALL, !REBOOT
```

Strip permissions for root

```
su
chmod -x /bin/halt
chmod -x /bin/reboot
chmod -x /bin/poweroff
```
