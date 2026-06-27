---
tags:
  - Gentoo
  - Linux
---

# Install Gentoo Linux KDE based on CLI


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 安装 sudo

```bash
emerge sudo
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
usermod -aG wheel hxp
```

## 添加 USE flag

```bash
echo "USE=\"bindist mmx sse sse2 mmxext dbus udev branding icu python X acpi display-manager sddm gtk handbook libkms wallpapers pulseaudio legacy-systray gtk2 gtk3 -gtk -gnome\"" >> /etc/portage/make.conf
echo "INPUT_DEVICES=\"evdev keyboard mouse synaptics\"" >> /etc/portage/make.conf
```

## 选择 Profile

```
eselect profile list
eselect profile set 8
```

## 安装 dbus

```bash
emerge --changed-use --deep @world
emerge -v sys-apps/dbus
/etc/init.d/dbus start
rc-update add dbus default
rc-update add udev sysinit
```

## 安装 Xorg 驱动

```
emerge -v x11-base/xorg-drivers
emerge -v x11-base/xorg-x11
```

## 允许用户访问 video

```bash
gpasswd -a root video
gpasswd -a hxp video
```

## 开始安装 KDE Plasma

```bash
echo "USE=\"harfbuzz bindist mmx sse sse2 mmxext dbus udev branding icu python X acpi display-manager sddm gtk handbook libkms wallpapers pulseaudio legacy-systray gtk2 gtk3 -gtk -gnome\"" >> /etc/portage/make.conf
emerge --changed-use --deep @world
# 仅安装 Plasma 桌面
emerge -v kde-plasma/plasma-desktop
dispatch-conf
chmod +s /sbin/unix_chkpwd
emerge -v kde-plasma/kdeplasma-addons kde-apps/kwalletmanager kde-apps/dolphin x11-misc/sddm kde-plasma/systemsettings kde-plasma/kscreen kde-apps/konsole
```

## 更换 display manager

```bash
emerge -v gui-libs/display-manager-init
rc-update add display-manager default
sed -i 's/DISPLAYMANAGER="xdm"/DISPLAYMANAGER="sddm"/' /etc/conf.d/display-manager
usermod -a -G video sddm
```

## 重启并测试 KDE 安装

```bash
reboot
```

# 安装所有 plasma 应用和插件

## 先安装基础 KDE 应用

```bash
emerge -v kde-plasma/plasma-meta
emerge -v kde-plasma/kdeplasma-addons kde-apps/kwalletmanager kde-apps/dolphin x11-misc/sddm kde-plasma/systemsettings kde-plasma/kscreen kde-apps/konsole
emerge -v net-misc/networkmanager kde-plasma/plasma-nm
rc-update del dhcpcd default
rc-service NetworkManager start
rc-update add NetworkManager default
```

## 然后安装所有 KDE 应用

```bash
echo 'USE="postproc harfbuzz mmx sse sse2 mmxext dbus udev branding icu python X acpi display-manager sddm gtk handbook libkms wallpapers pulseaudio legacy-systray gtk2 -gtk -gnome"' >> /etc/portage/make.conf
echo 'ABI_X86="(64)"' >> /etc/portage/make.conf
emerge -vuND --keep-going  @world --exclude="nodejs"
emerge -vuND --keep-going  @world --exclude="openssl http-parser"
emerge firefox kde-apps/kde-apps-meta
```

---

## 原文（English）

```
---
tags:
  - Gentoo
  - Linux
---

# Install Gentoo Linux KDE based on CLI


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Install sudo

```bash
emerge sudo
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
usermod -aG wheel hxp
```

## Add USE flag

```bash
echo "USE=\"bindist mmx sse sse2 mmxext dbus udev branding icu python X acpi display-manager sddm gtk handbook libkms wallpapers pulseaudio legacy-systray gtk2 gtk3 -gtk -gnome\"" >> /etc/portage/make.conf
echo "INPUT_DEVICES=\"evdev keyboard mouse synaptics\"" >> /etc/portage/make.conf
```

## Choose Profile

```
eselect profile list
eselect profile set 8
```

## Install dbus

```bash
emerge --changed-use --deep @world
emerge -v sys-apps/dbus
/etc/init.d/dbus start
rc-update add dbus default
rc-update add udev sysinit
```

## Install Xorg Drivers

```
emerge -v x11-base/xorg-drivers
emerge -v x11-base/xorg-x11
```

## Allow users to video access

```bash
gpasswd -a root video
gpasswd -a hxp video
```

## Start installing KDE Plasma

```bash
echo "USE=\"harfbuzz bindist mmx sse sse2 mmxext dbus udev branding icu python X acpi display-manager sddm gtk handbook libkms wallpapers pulseaudio legacy-systray gtk2 gtk3 -gtk -gnome\"" >> /etc/portage/make.conf
emerge --changed-use --deep @world
# Install Plasma desktop only
emerge -v kde-plasma/plasma-desktop
dispatch-conf
chmod +s /sbin/unix_chkpwd
emerge -v kde-plasma/kdeplasma-addons kde-apps/kwalletmanager kde-apps/dolphin x11-misc/sddm kde-plasma/systemsettings kde-plasma/kscreen kde-apps/konsole
```

## Change display manager

```bash
emerge -v gui-libs/display-manager-init
rc-update add display-manager default
sed -i 's/DISPLAYMANAGER="xdm"/DISPLAYMANAGER="sddm"/' /etc/conf.d/display-manager
usermod -a -G video sddm
```

## Reboot and test KDE Installation

```bash
reboot
```

# Install all plasma apps and addons

## Install basic KDE apps first

```bash
emerge -v kde-plasma/plasma-meta
emerge -v kde-plasma/kdeplasma-addons kde-apps/kwalletmanager kde-apps/dolphin x11-misc/sddm kde-plasma/systemsettings kde-plasma/kscreen kde-apps/konsole
emerge -v net-misc/networkmanager kde-plasma/plasma-nm
rc-update del dhcpcd default
rc-service NetworkManager start
rc-update add NetworkManager default
```

## Then install all KDE apps

```bash
echo 'USE="postproc harfbuzz mmx sse sse2 mmxext dbus udev branding icu python X acpi display-manager sddm gtk handbook libkms wallpapers pulseaudio legacy-systray gtk2 -gtk -gnome"' >> /etc/portage/make.conf
echo 'ABI_X86="(64)"' >> /etc/portage/make.conf
emerge -vuND --keep-going  @world --exclude="nodejs"
emerge -vuND --keep-going  @world --exclude="openssl http-parser"
emerge firefox kde-apps/kde-apps-meta
```
```