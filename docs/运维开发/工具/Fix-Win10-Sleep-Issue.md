---
tags:
  - Linux
  - 工具
---

# Fix Windows 10 Sleep Issue


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Problem Definition

- Windows 10 
- Only turn off screen when it sleeps
- Can use the touch pad to wake up immediatly, no login screen

## Solution

Edit Regestry:

Change `\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power\AwayModeEnabled` to `0`