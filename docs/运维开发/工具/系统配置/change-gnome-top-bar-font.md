---
tags:
  - Linux
  - 工具
---

# 更改 GNOME 顶部栏字体


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Change GNOME Top Bar font

Install GNOME Shell Extension

```
yum install gnome-shell
```

Create a theme folder

```
mkdir -p MyTheme/gnome-shell
```

Write the theme css file `MyTheme/gnome-shell/gnome-shell.css`

```
@import url("/usr/share/themes/Adapta/gnome-shell/gnome-shell.css");

stage {
    font-family: Microsoft YaHei UI, Sans-Serif;
    font-size: 10pt;
    color: #000000;
}
```

Install the theme

```
mkdir -p ~/.theme/
mv MyTheme ~/.themes/
```

And then activate it in `gnome-tweak-tools`
