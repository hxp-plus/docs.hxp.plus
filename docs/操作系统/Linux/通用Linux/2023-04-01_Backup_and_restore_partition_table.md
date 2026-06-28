---
tags:
  - Linux
---

# 备份和恢复分区表

原英文标题：References

To backup /dev/sda partition table, enter:
```bash
sfdisk -d /dev/sda > sda.partition.table.12-30-2015.txt
```
To restore:
```bash
sfdisk -f /dev/sda < sda.partition.table.12-30-2015.txt
```
To change the part UUID of the first partition of sdc:
```bash
sgdisk -u 1:BC87D91A-02F3-4C52-87CD-536A3DF2A074 /dev/sdc
```
To change UUID of FAT32 partition:
```bash
mkdosfs -i ABCD1234 /dev/sdc1
```

# References

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

<https://www.cyberciti.biz/faq/linux-backup-restore-a-partition-table-with-sfdisk-command/>
