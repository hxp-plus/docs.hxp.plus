---
tags:
  - Linux
  - 工具
---

# Add Matlab Shortcut to GNOME or KDE


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

create ` vim /usr/share/applications/matlab.desktop `

add these lines

```
[Desktop Entry]
Type=Application
Name=Matlab
GenericName=Matlab 2019b
Comment=Matlab:The Language of Technical Computing
Exec=/usr/local/bin/matlab -desktop
Icon=/usr/local/Polyspace/R2019b/bin/glnxa64/cef_resources/matlab_icon.png
Terminal=false
Categories=Science;Engineering;
```



