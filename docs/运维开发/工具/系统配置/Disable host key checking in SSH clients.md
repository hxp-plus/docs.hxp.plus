---
tags:
  - SSH
  - Linux
---

# 在 SSH 客户端中禁用主机密钥检查


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Disable host key checking in SSH clients

```bash
vim ~/.ssh/config
```

```
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    LogLevel ERROR
    PubkeyAcceptedKeyTypes +ssh-rsa
```



