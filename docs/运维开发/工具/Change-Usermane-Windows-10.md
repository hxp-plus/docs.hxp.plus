---
tags:
  - Linux
  - 工具
---

# Change your usermane in Windows 10


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Edit Registry

Enter directory:

```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
```

One of the subdirectories has a key named `ProfileImagePath` valued like `C:\Users\your_default_user_name`. Change `your_default_user_name` to `your_new_username`, for example.

And then logout.

## Change your name in the user profile directory

Log in. Error may occur and you will be logged in as temporary user.

Look into `C:\Users`, rename `your_default_user_name` folder to `your_new_username`.

Log out again and log back.
