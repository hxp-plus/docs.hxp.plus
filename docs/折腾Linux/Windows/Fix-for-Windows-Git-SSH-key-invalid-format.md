---
tags:
  - Windows
---

# Fix for invalid format error when using Git on Windows


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

If you encounter this kind of error when using Git on Windows:

```powershell
PS C:\Users\hxp\Notes> git push origin master
Load key "/c/Users/hxp/credentials/ssh/hxp/id_rsa": invalid format
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
```

and if the ssh command on Windows works fine and can read ssh key then login to your server.

This is beacuse Git is using bundled ssh command instead of system's ssh.

Try to set Environment variable `GIT_SSH` to `C:\Windows\System32\OpenSSH\ssh.exe`.
