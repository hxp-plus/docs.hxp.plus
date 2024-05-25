# Linux LVM 踢 PV

lv_ubuntu 由 `/dev/sdb` 和 `/dev/sda3` 两个 pv 组成，其中部分数据写在了 `/dev/sdb` ，如果想把 `/dev/sdb` 踢盘，需要先进行如下操作：

```
pvmove /dev/sdb /dev/sda3
```

将 `/dev/sdb` 这个 PV 里的 PE 迁移到 `/dev/sda3` 上，之后踢盘：

```
vgreduce ubuntu-vg /dev/sdb
```
