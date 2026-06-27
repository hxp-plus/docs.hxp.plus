---
tags:
  - Linux
  - 工具
---

# Piping Terminal to Clipboard


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

 install `xclip`

```bash
sudo pacman -S xclip
```

set alias: add alias to `.bashrc`

```bash
alias setclip="xclip -selection c"
alias getclip="xclip -selection c -o"
```

start piping

```bash
grep 'xclip' .bashrc | setclip
```

