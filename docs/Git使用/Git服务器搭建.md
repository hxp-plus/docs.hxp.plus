---
tags:
  - Git
---

只要有服务器有 SSH，就可以搭建 Git 仓库。在仓库上，先创建用户 git，并使用用户 git 来创建仓库：

```
cd /srv/git
mkdir project.git
cd project.git
git init --bare
```

之后在客户端使用 Git：

```
git remote add origin git@gitserver:/srv/git/project.git
```
