---
tags:
  - Linux
  - 工具
---
# Dell R730使用Clover引导NVMe磁盘启动

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Dell R730原生不支持NVMe启动，需要使用Clover进行启动引导，在机器的内置USB口插入一个U盘，然后先进入U盘，U盘进一步引导进入固态盘启动。
## 刻录Clover启动U盘
下载Clover文件[Clover-5157-X64.iso.7z](https://github.com/CloverHackyColor/CloverBootloader/releases/download/5157/Clover-5157-X64.iso.7z)并解压，使用rufus将ISO镜像Clover-5157-X64.iso烧录进U盘
## 配置Clover
挂载进入Clover启动U盘，将`\EFI\CLOVER\drivers\off\NvmExpressDxe.efi`复制到`\EFI\CLOVER\drivers\BIOS`和`\EFI\CLOVER\drivers\UEFI`，插入U盘启动，进入Clover界面按F2后关机（按F2没有反应是正常现象）。
之后启动U盘里`\EFI\CLOVER\misc`会多一个日志`PreBoot.log`，打开这个日志，搜索NVMe关键字：
```
106:192  0:000  - [02]: Volume: PciRoot(0x1)\Pci(0x1,0x0)\Pci(0x0,0x0)\NVMe(0x1,00-00-00-00-00-00-00-00)
106:192  0:000  - [03]: Volume: PciRoot(0x1)\Pci(0x1,0x0)\Pci(0x0,0x0)\NVMe(0x1,00-00-00-00-00-00-00-00)\HD(1,GPT,4489A295-C6EE-11EE-8418-20040FEAFB06,0x28,0x82000)
```
复制这里的UUID`4489A295-C6EE-11EE-8418-20040FEAFB06`，修改`\EFI\CLOVER\config.plist`：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Boot</key>
  <dict>
    <key>Timeout</key>
    <integer>0</integer>
    <key>DefaultVolume</key>
    <string>4489A295-C6EE-11EE-8418-20040FEAFB06</string>
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
          <string>4489A295-C6EE-11EE-8418-20040FEAFB06</string>
          <key>Disabled</key>
          <false/>
          <key>Type</key>
          <string>Linux</string>
          <key>Title</key>
          <string>ESXi</string>
        </dict>
      </array>
    </dict>
  </dict>
</dict>
</plist>
```
之后设置服务器的启动项为U盘即可。
## 参考链接
<https://www.reddit.com/r/homelab/comments/tcp2rz/dell_poweredge_r730_boot_from_pcie_m2_device/>