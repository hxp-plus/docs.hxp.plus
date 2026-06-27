---
tags:
  - Windows
---

首先，通过以下命令检查操作系统版本：
```
PS C:\Users\Administrator> dism /Online /Get-CurrentEdition
Deployment Image Servicing and Management tool
Version: 10.0.20348.681
Image Version: 10.0.20348.1607
Current edition is:
Current Edition : ServerDatacenterEval
The operation completed successfully.
```
如果系统版本为评估版（evaluation version），需要先升级为非评估版：
```
dism /Online /Set-Edition:ServerDatacenter /AcceptEula /ProductKey:WX4NM-KYWYW-QJJR4-XV3QB-6VM33
```

设置 KMS 服务器：
```
slmgr.vbs /skms openwrt.hxp.plus
```
通过以下命令检查 KMS 服务器状态：
```
slmgr /dlv
```
获取激活密钥并执行：
```
slmgr /ipk WX4NM-KYWYW-QJJR4-XV3QB-6VM33
slmgr /ato
```
Windows 11/10 产品密钥：

|Operating system edition|KMS Client Product Key|
|-|-|
|Windows 11/10 Pro|W269N-WFGWX-YVC9B-4J6C9-T83GX|
|Windows 11/10 Pro N|MH37W-N47XK-V7XM9-C7227-GCQG9|
|Windows 11/10 Pro for Workstations|NRG8B-VKK3Q-CXVCJ-9G2XF-6Q84J|
|Windows 11/10 Pro for Workstations N|9FNHH-K3HBT-3W4TD-6383H-6XYWF|
|Windows 11/10 Pro Education|6TP4R-GNPTD-KYYHQ-7B7DP-J447Y|
|Windows 11/10 Pro Education N|YVWGF-BXNMC-HTQYQ-CPQ99-66QFC|
|Windows 11/10 Education|NW6C2-QMPVW-D7KKK-3GKT6-VCFB2|
|Windows 11/10 Education N|2WH4N-8QGBV-H22JP-CT43Q-MDWWJ|
|Windows 11/10 Enterprise|NPPR9-FWDCX-D2C8J-H872K-2YT43|
|Windows 11/10 Enterprise N|DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4|
|Windows 11/10 Enterprise G|YYVX9-NTFWV-6MDM3-9PT4T-4M68B|
|Windows 11/10 Enterprise G N|44RPN-FTY23-9VTTB-MP9BX-T84FV|

Windows Server 2022 产品密钥：

|Operating system edition|	KMS Client Product Key|
|-|-|
|Windows Server 2022 Datacenter|WX4NM-KYWYW-QJJR4-XV3QB-6VM33|
|Windows Server 2022 Datacenter Azure Edition|NTBV8-9K7Q8-V27C6-M2BTV-KHMXV|
|Windows Server 2022 Standard|VDYBN-27WPP-V4HQT-9VMD4-VMK7H|

# References

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

<https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys>

<https://learn.microsoft.com/en-us/answers/questions/909025/on-a-computer-running-microsoft-windows-non-core-e>

<https://www.yorkerspot.com/upgrade-windows-server-2019-evaluation-to-standard-full-version/>

<https://www.cnblogs.com/CnKker/p/15705769.html>

---

## 原文（English）

---
tags:
  - Windows
---

First, check your os version by:
```
PS C:\Users\Administrator> dism /Online /Get-CurrentEdition
Deployment Image Servicing and Management tool
Version: 10.0.20348.681
Image Version: 10.0.20348.1607
Current edition is:
Current Edition : ServerDatacenterEval
The operation completed successfully.
```
if your system version is evaluation version, an upgrade to non-evaluation version is needed:
```
dism /Online /Set-Edition:ServerDatacenter /AcceptEula /ProductKey:WX4NM-KYWYW-QJJR4-XV3QB-6VM33
```


Set KMS server:
```
slmgr.vbs /skms openwrt.hxp.plus
```
Check KMS server statue by:
```
slmgr /dlv
```
Get an activation key and run:
```
slmgr /ipk WX4NM-KYWYW-QJJR4-XV3QB-6VM33
slmgr /ato
```
Windows 11/10 Product Key:

|Operating system edition|KMS Client Product Key|
|-|-|
|Windows 11/10 Pro|W269N-WFGWX-YVC9B-4J6C9-T83GX|
|Windows 11/10 Pro N|MH37W-N47XK-V7XM9-C7227-GCQG9|
|Windows 11/10 Pro for Workstations|NRG8B-VKK3Q-CXVCJ-9G2XF-6Q84J|
|Windows 11/10 Pro for Workstations N|9FNHH-K3HBT-3W4TD-6383H-6XYWF|
|Windows 11/10 Pro Education|6TP4R-GNPTD-KYYHQ-7B7DP-J447Y|
|Windows 11/10 Pro Education N|YVWGF-BXNMC-HTQYQ-CPQ99-66QFC|
|Windows 11/10 Education|NW6C2-QMPVW-D7KKK-3GKT6-VCFB2|
|Windows 11/10 Education N|2WH4N-8QGBV-H22JP-CT43Q-MDWWJ|
|Windows 11/10 Enterprise|NPPR9-FWDCX-D2C8J-H872K-2YT43|
|Windows 11/10 Enterprise N|DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4|
|Windows 11/10 Enterprise G|YYVX9-NTFWV-6MDM3-9PT4T-4M68B|
|Windows 11/10 Enterprise G N|44RPN-FTY23-9VTTB-MP9BX-T84FV|

Windows Server 2022 Product Key:

|Operating system edition|	KMS Client Product Key|
|-|-|
|Windows Server 2022 Datacenter|WX4NM-KYWYW-QJJR4-XV3QB-6VM33|
|Windows Server 2022 Datacenter Azure Edition|NTBV8-9K7Q8-V27C6-M2BTV-KHMXV|
|Windows Server 2022 Standard|VDYBN-27WPP-V4HQT-9VMD4-VMK7H|

# References

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

<https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys>

<https://learn.microsoft.com/en-us/answers/questions/909025/on-a-computer-running-microsoft-windows-non-core-e>

<https://www.yorkerspot.com/upgrade-windows-server-2019-evaluation-to-standard-full-version/>

<https://www.cnblogs.com/CnKker/p/15705769.html>
