---
tags:
  - Hyper-V
---

# Hyper-V 多网卡绑定

自 Windows Server 2022 启，LBFO （即操作系统里内置的 NIC Teaming）不再被支持添加到 Hyper-V 的虚拟交换机内，需要使用 Switch Embedded Teaming (SET) ，添加方法如下：

获取网卡名：

```powershell
Get-NetAdapter
```

创建虚拟交换机：

```powershell
New-VMSwitch -Name "External" -NetAdapterName "以太网 2", "以太网 3" -AllowManagementOS $false
```

查看虚拟交换机参数：

```powershell
Get-VMSwitchTeam -Name External | Format-List
```

修改虚拟交换机负载均衡算法为动态：

```powershell
Set-VMSwitchTeam -Name "External" -LoadBalancingAlgorithm Dynamic
```

注意：SET 是不支持 LACP 的，只支持和交换机无关的绑定模式，需要把对端绑定模式修改为轮询。
