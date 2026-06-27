---
tags:
  - Windows
---

# Steps to Uninstall OneDrive Completely on Windows 10 Pro


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

1. Open Group Policy Editor.
2. Go to `Computer Configuration` -> `Admimistrative Templates` -> `Windows Components` -> `OneDrive`.
3. Edit `Prevent the usage of OneDrive for file storage on Windows 8.1`, Change it to `Enabled`.
4. Reboot.
5. Go to `Settings` -> `Apps` and Uninstall `Microsoft OneDrive`.
6. Go to `%HOMEPATH%\OneDrive`, right click `Desktop`, `Documents` and `Pictures`, and click `Properties`, then select `Location` tab, and click `Restore Default`, then `Apply`.
7. If some error happens, try opening Registry Editor and edit keys under `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders` and reboot.
