---
tags:
  - Git
---

# Git 配置记住密码

## Token 的生成

由于 GitHub 等平台的限制，在 Git 客户端配置的密码需要是 Personal Access Token，可在个人设置的“Developer Settings”设置。

## 配置 Git 记住密码

使用以下命令配置（全局生效，如果想仅对仓库生效，去掉 `--global` ）：

```
git config --global credential.helper store
```
