---
tags:
  - Linux
---

# 使用 Clover 实现 nvme 引导启动

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

在一些不支持 NVMe 启动的机器上可以使用 Clover 引导的方式实现 NVMe 启动，即先启动进入 U 盘的 Clover ，然后 Clover 启动 NVMe 硬盘。
## 下载并烧录 CloverCD 介质
从 GitHub 下载 [CloverBootloader](https://github.com/CloverHackyColor/CloverBootloader/releases) ，解压得到 ISO 介质，并使用 [Rufus](https://rufus.ie/) 烧录进 U 盘，烧写模式选择 "Write in ISO Image mode (Recommended)" 。
## 为 Clover 添加 NVMe 驱动
烧录完成后，进入 U 盘，将 U 盘中 `\EFI\CLOVER\drivers\off\NvmExpressDxe.efi` 复制到 `\EFI\CLOVER\drivers\BIOS` 和 `\EFI\CLOVER\drivers\UEFI` 目录。
## 使用 Clover 启动
将制作好的 U 盘插入到需要 NVMe 启动的机器上启动，进入 Clover 启动菜单后，按 F2 （按下去没有反应是正常的），之后关机，拔出 U 盘。此时在 U 盘的 `\EFI\CLOVER\misc` 下有 `PreBoot` 日志文件。在日志文件中搜索像这样的行：
```
(Loader entry created for 'PciRoot(0x0)\Pci(0x2,0x0)\Pci(0x0,0x0)\NVMe(0x1,5C-68-90-11-59-38-25-00)\HD(1,GPT,16F9A8BC-B144-4C9D-B0EF-311F91FB454C,0x40,0x32000)\EFI\BOOT\BOOTX64.efi'
```
将 UUID `16F9A8BC-B144-4C9D-B0EF-311F91FB454C` 记录下来，修改 `\EFI\CLOVER\config.plist` ：
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Boot</key>
  <dict>
    <key>Timeout</key>
    <integer>0</integer>
    <key>DefaultVolume</key>
    <string>16F9A8BC-B144-4C9D-B0EF-311F91FB454C</string>
  </dict>
  <key>GUI</key>
  <dict>
    <key>TextOnly</key>
    <true/>
    <key>Custom</key>
    <dict>
      <key>Entries</key>
      <array>
        <dict>
          <key>Hidden</key>
          <false/>
          <key>Volume</key>
          <string>16F9A8BC-B144-4C9D-B0EF-311F91FB454C</string>
          <key>Disabled</key>
          <false/>
          <key>Type</key>
          <string>Linux</string>
          <key>Title</key>
          <string>TrueNAS</string>
        </dict>
      </array>
    </dict>
  </dict>
</dict>
</plist>
```
之后将 U 盘插回即可实现 Clover 引导。
## 参考资料
<https://www.reddit.com/r/homelab/comments/tcp2rz/dell_poweredge_r730_boot_from_pcie_m2_device/>
