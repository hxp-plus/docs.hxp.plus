---
tags:
  - Gentoo
  - Linux
---

# Install Chinese Support based on KDE


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Install Chinese font

```bash
emerge media-fonts/font-isas-misc media-fonts/arphicfonts media-fonts/opendesktop-fonts media-fonts/wqy-zenhei media-fonts/zh-kcfonts
```

## Install Chinese IME

```bash
emerge fcitx-qt5
emerge app-i18n/fcitx-configtool
emerge app-i18n/fcitx-rime
```

## Write environment variables

```bash
echo "export GTK_IM_MODULE=fcitx" >> ~/.xprofile
echo "export QT_IM_MODULE=fcitx" >> ~/.xprofile
echo "export XMODIFIERS=@im=fcitx" >> ~/.xprofile
```

