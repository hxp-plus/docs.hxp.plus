---
tags:
  - Windows
---

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

To create checkpoint for each virtual machine:
```powershell
Get-VM | Checkpoint-VM -Name {$_.Name} -SnapshotName "Daily Snapshot $((Get-Date).toshortdatestring())"
```

To delete checkpoint older than 14 days:
```powershell
Get-VM | Get-VMSnapshot -VMName {$_.Name} | Where-Object {$_.CreationTime -lt (Get-Date).AddDays(-14)} | Remove-VMSnapshot
```

Put these two commands into a powershell script, and let the task scheduler to invoke it at 4 am everyday:
```powershell
schtasks /create /tn vmbackup /tr "powershell -NoLogo -WindowStyle hidden -file C:\Hyper-V\backup.ps1" /sc daily /st 04:00 /ru SYSTEM
```
