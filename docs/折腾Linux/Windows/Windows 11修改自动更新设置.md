---
tags:
  - Windows
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

为了防止自动更新在不需要的时间重启，需要修改以下设置：

1. **Administrative Templates** > **Windows Components** > **Windows Update** > **Legacy Policies** > **No auto-restart with logged on users for scheduled automatic updates installations**
2. **Administrative Templates** > **Windows Components** > **Windows Update** > **Manage end user experience > Configure Automatic Updates**

按Win+R输入gpedit.msc进入组策略编辑器修改。

<https://superuser.com/questions/1817039/disable-automatic-restarts-windows-11>