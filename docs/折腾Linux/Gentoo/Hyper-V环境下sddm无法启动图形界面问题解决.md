---
tags:
  - Gentoo
  - Linux
  - xfce
  - sddm
  - Hyper-V
---

# Hyper-V 环境下 sddm 无法启动图形界面问题解决

## 问题描述

在 Hyper-V 环境下，安装 KDE 后，sddm 无法启动图形界面，即以下命令无效：

```
rc-service display-manager start
```

其中 `/etc/conf.d/display-manager` 中正确配置了 `DISPLAYMANAGER="sddm"` ，且使用配置 `~/.xinitrc` 后用 `startx` 命令启动 KDE ，或者使用 VNC 都正常。

## 排查过程

将虚拟机迁移到 VMware ，一切正常。说明 sddm 安装和配置没有问题。 VMware 和 Hyper-V 的区别为 VMware 虚拟机里 `lspci` 有输出， Hyper-V 虚拟机里没有，因为 Hyper-V 走的是 VMBus 而不是 PCI-E 。

同时，在 Hyper-V 里启动 manjaro 安装镜像，图形界面可以启动。因此不是 Hyper-V 虚拟机配置问题。于是开始排查内核模块问题，在 manjaro 上 `lsmod | grep hyper` 和 gentoo 进行对比，最终将 gentoo 内核重新编译：

```
genkernel all --install --bootloader=grub2 --hyperv --mountboot --menuconfig
```

其中 menuconfig 里，禁用这里的 `hyperv_fb` ：

```
hyperv_fb
│ Symbol: FB_HYPERV [=m] │
│ Type : tristate │
│ Defined at drivers/video/fbdev/Kconfig:1781 │
│ Prompt: Microsoft Hyper-V Synthetic Video support │
│ Depends on: HAS_IOMEM [=y] && FB [=y] && HYPERV [=m] │
│ Location: │
│ -> Device Drivers │
│ -> Graphics support │
│ -> Frame buffer Devices │
│ (2) -> Microsoft Hyper-V Synthetic Video support (FB_HYPERV [=m])
```

开启这里的 `hyperv_drm` ：

```
hyperv_drm
│ Symbol: DRM_HYPERV [=n] │
│ Type : tristate │
│ Defined at drivers/gpu/drm/Kconfig:390 │
│ Prompt: DRM Support for Hyper-V synthetic video device │
│ Depends on: HAS_IOMEM [=y] && DRM [=m] && PCI [=y] && MMU [=y] && HYPERV [=m] │
│ Location: │
│ -> Device Drivers │
│ -> Graphics support │
│ (1) -> DRM Support for Hyper-V synthetic video device (DRM_HYPERV [=n]) │
│ Selects: DRM_KMS_HELPER [=m] && DRM_GEM_SHMEM_HELPER [=m]
```

问题没有得到解决。后来得知这个是 sddm 已知问题，更换 DM 为 lightdm 后，修改 lightdm 配置文件 `/etc/lightdm/lightdm.conf` 的这一行：

```
[LightDM]
logind-check-graphical=false
```

同时，需要移除文件 `/usr/share/xsessions/Xsession.desktop` 来防止右上角显示不能用的 Xsession 这个 DE ，修改 `/etc/conf.d/display-manager` 里 `DISPLAYMANAGER="lightdm"` ，之后问题得到解决。
