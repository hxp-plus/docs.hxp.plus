---
tags:
  - Linux
  - 工具
---

# Disabling Shutdown and Logout in GNOME


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Use this extension to remove the shutdown button： <https://github.com/mmartinortiz/RmPwOffBtn/tree/keeping-shutdown-object>

And also disabling shutdown in systemctl

```
systemctl mask poweroff.target
```

To prevent the user logging out in gnome:

```
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
gsettings set org.gnome.desktop.lockdown disable-log-out true
gsettings set org.gnome.desktop.lockdown disable-user-switching true
``` 
