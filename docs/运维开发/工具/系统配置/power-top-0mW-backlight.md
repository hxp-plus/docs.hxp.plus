---
tags:
  - Linux
  - 工具
---

# 修复 powertop 始终显示 0 mW 显示器背光使用错误


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Fix the powertop always show 0 mW Display Backlight usage error

今天我安装了 `powertop` 来监控笔记本电脑上所有设备的功耗。安装后，我立即通过命令 `powertop` 启动了它。该工具一直显示我的显示器背光功耗为 0 mW，如下所示。

```
Power est.    Usage     Device name
  6.48 W     35.1%        CPU core
   0    W    100.0%        Display backlight
```

我尝试调整了屏幕亮度，"Usage" 列确实会变化，但 "Power est." 列不会变化。

在 Google 搜索后，我安装了 `acpi`，并尝试通过以下命令关闭显示器：

```bash
xset -d :0 dpms force off
```

然后轻触触摸板，屏幕重新亮起，正如 GitHub 上 [marcelopm](https://github.com/marcelopm) 在这个 [issue](https://github.com/fenrus75/powertop/issues/62) 中所说。

我还编辑了 `/etc/default/grub`，添加了

```
GRUB_CMDLINE_LINUX="acpi_backlight=vendor"
```

并通过以下命令重新生成了 `grub.cfg`：

```bash
sudo grub-mkconfig /boot/grub/grub.cfg
```

最终的解决方案是上述操作，再加上使用以下命令校准 powertop：

```bash
sudo powertop --calibrate
```

然后它就恢复正常了。

```
The battery reports a discharge rate of 15.2 W
The energy consumed was 409 J
System baseline power is estimated at 24.3 W

Power est.    Usage     Device name
  13.8 W    100.0%        Display backlight
  6.73 W    236.9%        CPU core
  3.71 W    236.9%        CPU misc
 44.0 mW      9.6 pkts/s  Network interface: wlp1s0 (iwlwifi)
    0 mW    100.0%        Radio device: iwlwifi
    0 mW      0.0%        USB device: HP HD Camera (Chicony)
    0 mW      0.0%        USB device: usb-device-8087-0a2b
    0 mW      0.0%        USB device: xHCI Host Controller
    0 mW      0.0%        USB device: usb-device-138a-003f
    0 mW      0.0%        USB device: xHCI Host Controller
    0 mW      0.0%        Audio codec hwC0D0: Conexant
    0 mW      0.0%        Radio device: btusb
            100.0%        PCI Device: Intel Corporation Sunrise Point-LP LPC Controller
```

---

## 原文（English）

Today I installed `powertop` to monitor the power consumption of all the devices on my laptop. After installing, I immediately launched it by command `powertop`. And the utility always show me that my display backlight consumes 0 mW of power, like this.

```
Power est.    Usage     Device name
  6.48 W     35.1%        CPU core
   0    W    100.0%        Display backlight
```

I tried to adjust the screen brightness, the "Usage" column did change, but the "Power est." column wouldn't.

After Googling, I installed `acpi` , and tried tuning off the display by

```bash
xset -d :0 dpms force off
```

then tapped touchpad and screen went on, just as **[marcelopm](https://github.com/marcelopm)** said in this [issue](https://github.com/fenrus75/powertop/issues/62) on GitHub.

I also edited `/etc/default/grub`, added

```
GRUB_CMDLINE_LINUX="acpi_backlight=vendor"
```

and regenerated `grub.cfg` by

```bash
sudo grub-mkconfig /boot/grub/grub.cfg
```

The final solution was it and to calibrate powertop with

```bash
sudo powertop --calibrate
```

Then it became normal.

```
The battery reports a discharge rate of 15.2 W
The energy consumed was 409 J
System baseline power is estimated at 24.3 W

Power est.    Usage     Device name
  13.8 W    100.0%        Display backlight
  6.73 W    236.9%        CPU core
  3.71 W    236.9%        CPU misc
 44.0 mW      9.6 pkts/s  Network interface: wlp1s0 (iwlwifi)
    0 mW    100.0%        Radio device: iwlwifi
    0 mW      0.0%        USB device: HP HD Camera (Chicony)
    0 mW      0.0%        USB device: usb-device-8087-0a2b
    0 mW      0.0%        USB device: xHCI Host Controller
    0 mW      0.0%        USB device: usb-device-138a-003f
    0 mW      0.0%        USB device: xHCI Host Controller
    0 mW      0.0%        Audio codec hwC0D0: Conexant
    0 mW      0.0%        Radio device: btusb
            100.0%        PCI Device: Intel Corporation Sunrise Point-LP LPC Controller
```
