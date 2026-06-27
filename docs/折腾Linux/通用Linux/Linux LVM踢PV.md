---
tags:
  - Linux
---

# Linux LVM 踢 PV

lv_ubuntu 由 `/dev/sdb` 和 `/dev/sda3` 两个 PV 组成，其中部分数据写在了 `/dev/sdb` 上。如果想将 `/dev/sdb` 踢盘，需要先进行如下操作：

```bash
pvmove /dev/sdb /dev/sda3
```

!!! warning

    `pvmove` 操作期间不可中断，否则可能导致数据损坏。踢盘前请确保数据已完整迁移，且 VG 中剩余空间足够。

将 `/dev/sdb` 这个 PV 里的 PE 迁移到 `/dev/sda3` 上，之后踢盘：

```bash
vgreduce ubuntu-vg /dev/sdb
```
