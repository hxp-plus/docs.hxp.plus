---
tags:
  - TrueNAS
  - Windows
  - iSCSI
  - TFTP
---

# TrueNAS iSCSI 安装 Windows Server 2025

## 准备工作

要想在 Windows Server 安装到 TrueNAS 的 iSCSI 服务器上，需要先具备以下：

- HTTP 服务器：由 TrueNAS 上虚拟机提供
- TFTP 服务器：由 TrueNAS 的容器提供
- iSCSI 服务器：由 TrueNAS 提供
- DNS 和 DHCP 服务器：由 OpenWrt 上 dnsmasq 提供
- SMB 服务器：由 TrueNAS 提供

同时需要具备一台已经装好 Windows 的机器用于制作 WinPE 镜像，一台 Linux 的机器用于编译 iPXE 和上传 iPXE 镜像到 TFTP 服务器

## 在 iSCSI 上划分一个 LUN

首先进入 Datasets ，新建一个 Zvol ，名称为 `windows-server-2025` ，大小为 64 GB ：
![新建Zvol](<images/Screenshot 2025-06-15 155635.png>)
之后不要忘记对此 Zvol 设置定时快照，以防 Windows 更新无法回退：
![设置快照](<images/Screenshot 2025-06-15 155956.png>)
进入 Shares -> iSCSI ，点击 Wizard 快速创建一个 LUN ：
![创建LUN-1](<images/Screenshot 2025-06-15 155635.png>)
![创建LUN-2](<images/Screenshot 2025-06-15 160518.png>)
![创建LUN-3](<images/Screenshot 2025-06-15 160531.png>)
创建完成后可挂载此 LUN 来验证。

## 搭建 TFTP 服务

直接使用 TrueNAS Scale 的容器功能搭建 TFTP 服务，在 Apps 里安装 `tftpd-hpa` 应用即可，相关配置默认即可。搭建完成后使用 TFTP 命令验证，注意 TFTP 命令是没有 ls 的。

## 配置 DNS 和 DHCP 服务

DNS 和 DHCP 服务由 OpenWrt 的 dnsmasq 提供，首先配置域名 `pxe.hxp.lan` 解析到 HTTP 服务器，在 `Network -> DHCP and DNS -> Hostnames` 里，添加域名解析。之后在 `Network -> DHCP and DNS -> PXE/TFTP` 里，找到 `Special PXE boot options for Dnsmasq` 添加如下配置：
![DHCP配置-1](<images/Screenshot 2025-06-15 161300.png>)
注意这里 `DHCP Options` 为默认值。上级界面里，不勾选 `Enable TFTP server` ：
![DHCP配置-2](<images/Screenshot 2025-06-15 161504.png>)
配置完成如图所示。

## 编译 iPXE 镜像并上传至 TFTP

这里使用 RHEL 9 进行编译，首先需要安装如下依赖：

```bash
sudo yum install git gcc binutils make perl xz-devel mtools
```

下载 iPXE 源码并进入源码目录：

```bash
git clone https://github.com/ipxe/ipxe.git
cd src
```

新建 `boot.ipxe` 文件，根据序列号启动：

```ipxe
#!ipxe
echo Configure dhcp ....
dhcp
chain --replace http://pxe.hxp.lan/http-boot.ipxe
shell
```

根据MAC地址启动：

```ipxe
#!ipxe
echo Serial number: ${serial}
echo Configure dhcp ....
dhcp
chain --replace http://pxe.hxp.lan:31485/ipxe/${netX/mac}.ipxe
```

这个 iPXE 仅负责将网卡 DHCP 获取到 IP 地址，并加载 `http://pxe.hxp.lan/http-boot.ipxe` ，如果后续需要修改 iPXE 则修改 HTTP 服务器上 `http-boot.ipxe` 而不是重新编译这个 iPXE 镜像。编译 iPXE 镜像：

```bash
make bin-x86_64-efi/ipxe.efi EMBED=boot.ipxe
```

上传编译好的 ipxe.efi 到 TFTP 服务器（如果 TFTP 命令卡死，需要临时禁用防火墙）：

```bash
cd bin-x86_64-efi
tftp 172.21.0.2 -m binary -c put ipxe.efi
touch autoexec.ipxe
tftp 172.21.0.2 -m binary -c put autoexec.ipxe
cd ..
```

同时，在 HTTP 服务器的根目录创建 `http-boot.ipxe` 如下：

```ipxe
#!ipxe
echo Serial number: ${serial}
chain --replace http://pxe.hxp.lan/boot-${serial}.ipxe
```

这个 iPXE 会输出自己的序列号，并加载 HTTP 服务器根目录下 `boot-[序列号].ipxe` 脚本，实现不同机器 PXE 启动时根据序列号拉取不同的脚本。

## 制作 WinPE 镜像并上传至 HTTP 服务器

需要 1 台 Windows 电脑，先按照[微软官方教程](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)安装 `Windows ADK` 和 `Windows PE add-on for the Windows ADK` ：
![下载ADK](<images/Screenshot 2025-06-15 163104.png>)
之后找到开始菜单里的 `部署和映像工具环境` ，使用管理员权限运行，会得到一个 CMD 窗口，输入以下命令：

```cmd
cd "..\Windows Preinstallation Environment\amd64"
md C:\WinPE_amd64\mount
Dism /Mount-Image /ImageFile:"en-us\winpe.wim" /index:1 /MountDir:"C:\WinPE_amd64\mount"
copype amd64 C:\temp\winpe\amd64
Dism /Unmount-Image /MountDir:"C:\WinPE_amd64\mount" /Commit
rd C:\WinPE_amd64\mount
rd C:\WinPE_amd64
```

之后将 `C:\temp\winpe\amd64` 复制到 HTTP 服务器的根目录下。

## 修改 Windows 安装镜像增加驱动

对 Windows 安装镜像 sources 目录下 boot.wim 和 install.wim 做如下操作（驱动可在 `C:\Windows\System32\DriverStore\FileRepository` 目录查找）：

```cmd
md C:\WinPE_amd64\mount
Dism /Mount-Image /ImageFile:"C:\temp\boot.wim" /Index:1 /MountDir:"C:\WinPE_amd64\mount"
Dism /Image:"C:\WinPE_amd64\mount" /Add-Driver /Driver:"C:\Windows\System32\DriverStore\FileRepository" /ForceUnsigned /Recurse
Dism /Unmount-Image /MountDir:"C:\WinPE_amd64\mount" /Commit
Dism /Mount-Image /ImageFile:"C:\temp\install.wim" /Index:4 /MountDir:"C:\WinPE_amd64\mount"
Dism /Image:"C:\WinPE_amd64\mount" /Add-Driver /Driver:"C:\Windows\System32\DriverStore\FileRepository" /ForceUnsigned /Recurse
Dism /Unmount-Image /MountDir:"C:\WinPE_amd64\mount" /Commit
rd C:\WinPE_amd64\mount
rd C:\WinPE_amd64
```

其中 install.wim 命令应当填入的序号在这里查看：

```cmd
Dism /Get-ImageInfo /ImageFile:"C:\temp\install.wim"
```

## 安装 Windows Server

在 HTTP 服务器上，根目录存放文件 `boot-[序列号].ipxe` 为如下：

```ipxe
#!ipxe

# Attach SAN storage
echo attaching SAN storage
set keep-san 1
sanhook iscsi:172.21.0.2::::iqn.2005-10.org.freenas.ctl:windows-server-2025

# Set webroot
set webroot http://pxe.hxp.lan
echo Webroot is ${webroot}

#Set architecture
cpuid --ext 29 && set arch amd64 || set arch x86
echo ARCH is ${arch}

#Load wimboot
echo Loading Wimboot ...
kernel ${webroot}/wimboot
initrd ${webroot}/${arch}/media/Boot/BCD BCD
initrd ${webroot}/${arch}/media/Boot/boot.sdi boot.sdi
initrd ${webroot}/${arch}/media/sources/boot.wim boot.wim

#boot winpe
echo booting winpe
boot
```

让待装机服务器从 PXE 启动：
![WinPE启动](<images/Screenshot 2025-06-15 170514.png>)

提前准备 SMB 服务器并将 Windows 安装 ISO 解压至 winsrv2025 目录，启动进入 WinPE 后，进入 CMD 命令行，按下 Ctrl-C ，然后挂载 SMB 目录到 `Z:` 并运行 `setup.exe` ：

```cmd
net use Z: \\172.21.0.2\downloads\others\winsrv2025
Z:
setup.exe
```

![启动setup.exe](<images/Screenshot 2025-06-15 171854.png>)

如果安装失败可能需要点击 `use previous version of windows setup` ，安装系统完成后，修改 `boot-[序列号].ipxe` 为如下：

```ipxe
echo booting from SAN storage
set keep-san 1
sanboot iscsi:172.21.0.2::::iqn.2005-10.org.freenas.ctl:windows-server-2025
```

之后进入 PXE 则会从 iSCSI 启动。

## 激活 Windows Server

激活之前，先查看当前 Windows 都有哪些版本，并将其转换为非试用版本：

```powershell
DISM.exe /Online /Get-TargetEditions
```

转换为非试用的 Datacenter 版本：

```powershell
DISM.exe /online /Set-Edition:ServerDatacenter /ProductKey:D764K-2NDRG-47T6Q-P8T8W-YP6DF /AcceptEula
```

重启后，使用[官方 KMS 密钥](https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=server2025%2Cwindows1110ltsc%2Cversion1803%2Cwindows81)激活：

```powershell
slmgr /ipk D764K-2NDRG-47T6Q-P8T8W-YP6DF
slmgr /skms openwrt.hxp.lan
slmgr /ato
slmgr /dlv
```

这里使用了 OpenWrt 作为 KMS 服务器。
