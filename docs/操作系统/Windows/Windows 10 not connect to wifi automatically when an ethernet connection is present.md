---
tags:
  - Windows
---
# Windows 10 在有以太网连接时不自动连接 WiFi

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Windows 10 not connect to wifi automatically when an ethernet connection is present

这个问题可能已经有了解决方案，但这里有一个对笔者有效的、较少依赖硬件的解决方案，使用 RegEdit 和组策略。完全披露，笔者通过在 Google 上搜索该问题找到了此方法，来源是 [https://appuals.com/best-fix-windows-10-will-not-connect-to-wifi-automatically/](https://appuals.com/best-fix-windows-10-will-not-connect-to-wifi-automatically/ "appuals.com")。该网站署名 Kevin Arrows，他自称是一名拥有超过 10 年经验的 MCTS（Microsoft Certified Technology Specialist）认证专家。笔者在 Dell 笔记本电脑上尝试了此方法，效果很好。

**通过注册表编辑器编辑或创建组策略**

按住 Windows 键并按 R。在运行对话框中，输入 **regedit** 并点击确定。在注册表编辑器中导航到以下路径，

> HKLM\Software\Policies\Microsoft\Windows\WcmSvc\

查看 GroupPolicy 子键是否存在，如果不存在，在选中 WcmSvc 的情况下，右键点击 WcmSvc 并选择“新建 -> 键”，将其命名为 **GroupPolicy**，然后点击 **GroupPolicy**，在右侧窗格中（右键点击）选择“新建 -> DWORD (32 位) 值”，创建一个名为 **fMinimizeConnections** 的值，然后点击确定。现在，重启并测试。

此策略允许你自动连接到无线网络，即使插入了 LAN 网线，并且适用于 Windows 8/8.1 和 10。

<https://answers.microsoft.com/en-us/windows/forum/all/windows-10-not-connect-to-wifi-automatically-when/0cda7a70-6e1d-4ed9-a370-41581970ba73>

---

## 原文（English）

---
tags:
  - Windows
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

This may have been solved already, but here is a less hardware driven solution that worked for me using RegEdit and Group Policy.  Full disclosure, I found this by Googling the issue on the web at [https://appuals.com/best-fix-windows-10-will-not-connect-to-wifi-automatically/.](https://appuals.com/best-fix-windows-10-will-not-connect-to-wifi-automatically/ "appuals.com") The site is id'd as from Kevin Arrows, who says he is a certified MCTS (Microsoft Certified Technology Specialist) with over 10 years of experience. I tried this on my Dell laptop and it worked great.

**Edit or Create Group Policy via Registry Editor**

Hold the Windows Key and Press R. In the run dialog, type **regedit** and click OK. Navigate to the following path in Registry Editor,

> HKLM\Software\Policies\Microsoft\Windows\WcmSvc\

See if the GroupPolicy subkey exists, if not with WcmSvc highlighted, right click on WcmSvc and Choose New -> Key and name it GroupPolicy, then click GroupPolicy and then in the right pane, (right-click) and choose New -> DWORD (32-bit) and create value, name it as fMinimizeConnections and Click OK. Now, reboot and test.

This policy allows you to connect automatically to wireless network, even with a LAN plugged in and works on both Windows 8/8.1 and 10.

<https://answers.microsoft.com/en-us/windows/forum/all/windows-10-not-connect-to-wifi-automatically-when/0cda7a70-6e1d-4ed9-a370-41581970ba73>
