# Linux 将最后一个磁盘分区扩容到最大

在扩容 Linux 的系统盘后， `/dev/sda` 后部有大量空闲空间没有使用，需要将其纳入最后一个磁盘分区中。

## 检查路由表

```
parted -s -a opt /dev/sda "print free"
```

```
Warning: Not all of the space available to /dev/sda appears to be used, you can fix the GPT to use all of the space (an extra 201326592 blocks) or continue with the current setting?
Model: Msft Virtual Disk (scsi)
Disk /dev/sda: 137GB
Sector size (logical/physical): 512B/4096B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name  Flags
        17.4kB  1049kB  1031kB  Free Space
 1      1049kB  1128MB  1127MB  fat32              boot, esp
 2      1128MB  3276MB  2147MB  ext4
 3      3276MB  34.4GB  31.1GB
        34.4GB  137GB   103GB   Free Space
```

## 扩容第 3 个分区到磁盘末尾

```
root@ubuntu:~# growpart /dev/sda 3
```

```
CHANGED: partition=3 start=6397952 old: size=60708864 end=67106815 new: size=262037471 end=268435422
```
