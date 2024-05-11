---
tags:
  - Git
---

# Git 中文乱码问题解决

默认配置下 Git 如果有中文文件会有乱码：

```
$ git status
位于分支 master
您的分支与上游分支 'origin/master' 一致。

尚未暂存以备提交的变更：
  （使用 "git add <文件>..." 更新要提交的内容）
  （使用 "git checkout -- <文件>..." 丢弃工作区的改动）

	修改：     .obsidian/workspace.json

未跟踪的文件:
  （使用 "git add <文件>..." 以包含要提交的内容）

	"Git\344\270\255\346\226\207\344\271\261\347\240\201\351\227\256\351\242\230\350\247\243\345\206\263.md"

修改尚未加入提交（使用 "git add" 和/或 "git commit -a"）
```

解决方法：

```bash
git config --global core.quotepath false
```
