---
tags:
  - Windows
---

# 在 Windows 11 上完全卸载小组件功能


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Completely uninstall Widgets feature on Windows 11

要卸载 Windows 11 的 Widgets 功能，请以管理员身份打开 PowerShell 并运行以下
```
Get-AppxPackage *WebExperience* | Remove-AppxPackage
```
命令。
# Remove ADs from Windows 11 search menu

点击开始菜单，然后打开设置。
在左侧点击“隐私和安全性”。
然后在右侧向下滚动并点击“搜索权限”。
继续向下滚动，直到看到“显示搜索亮点”。
关闭该选项，图片将消失。

# Remove Chat from Windows 11

要移除 Chat，打开组策略编辑器（按 Win+R，输入 gpedit.msc，按回车），进入计算机配置 -> 管理模板 -> Windows 组件 -> Chat，双击“配置任务栏上的 Chat 图标”，点击“已启用”单选按钮，并将“状态”更改为“已禁用”，然后点击“确定”并重启。

# References
<https://pureinfotech.com/uninstall-widgets-powershell-windows-11/>

<https://answers.microsoft.com/en-us/windows/forum/all/how-do-i-remove-ads-from-windows-11-start-menu/acee8751-31e3-4abd-8caa-28ae7ba486fe>

<https://appuals.com/remove-chat-button-windows-11/>

---

## 原文（English）

---
tags:
  - Windows
---

# Completely uninstall Widgets feature on Windows 11


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

To uninstall the Windows 11 Widgets, open PowerShell (admin) and run the
```
Get-AppxPackage *WebExperience* | Remove-AppxPackage
```
command. 
# Remove ADs from Windows 11 search menu

Click on start the on settings
In left hand side click on privacy and security
Then on right hand side scroll down and click on search permissions
Scroll down again until you see "show search highlights"
Turn that option off and the images will disappear.

# Remove Chat from Windows 11

To remove Chat, open Group Policy Editor (Press Win+R, gpedit.msc, press Enter), go to Computer Configuration -> Administrative Templates -> Windows Components -> Chat, double click "Configure the Chat icon on the taskbar", click the Enabled radio button, and change "State" to "Disabled", then click "OK" and reboot.

# References
<https://pureinfotech.com/uninstall-widgets-powershell-windows-11/>

<https://answers.microsoft.com/en-us/windows/forum/all/how-do-i-remove-ads-from-windows-11-start-menu/acee8751-31e3-4abd-8caa-28ae7ba486fe>

<https://appuals.com/remove-chat-button-windows-11/>
