---
tags:
  - ZFS
  - TrueNAS
---

# TrueNAS 删除所有空快照

## ZFS 列出所有快照

使用以下命令列出所有快照:

```
zfs list -t snap
```

该命令输出大致如下:

```
NAME                                   USED  AVAIL  REFER  MOUNTPOINT
boot-pool/ROOT/24.04.0@pristine          8K      -   164M  -
boot-pool/ROOT/24.04.0/conf@pristine     0B      -   140K  -
boot-pool/ROOT/24.04.0/etc@pristine   1.06M      -  5.54M  -
boot-pool/ROOT/24.04.0/opt@pristine      0B      -  74.1M  -
boot-pool/ROOT/24.04.0/usr@pristine      0B      -  2.12G  -
boot-pool/ROOT/24.04.0/var@pristine    716K      -  30.8M  -
nas@auto-2023-10-28_20-00               80K      -   120K  -
nas@auto-2023-10-28_21-00                0B      -   112K  -
nas@auto-2023-10-28_22-00                0B      -   112K  -
nas@auto-2023-10-28_23-00                0B      -   112K  -
nas@auto-2023-10-29_00-00                0B      -   112K  -
nas@auto-2023-10-29_01-00                0B      -   112K  -
nas@auto-2023-10-29_02-00                0B      -   112K  -
nas@auto-2023-10-29_03-00                0B      -   112K  -
nas@auto-2023-10-29_04-00                0B      -   112K  -
nas@auto-2023-10-29_05-00                0B      -   112K  -
nas@auto-2023-10-29_06-00                0B      -   112K  -
nas@auto-2023-10-29_07-00                0B      -   112K  -
nas@auto-2023-10-29_08-00                0B      -   112K  -
```

## 找出所有大小为 0B 的快照并删除

使用以下脚本,用 awk 提取出大小为 0B 的快照,并输出 zfs 删除快照的命令:

!!! note "remove_empty_snapshots.sh"

    ```
    #!/bin/bash
    snapshots=$(zfs list -t snap | awk '$2=="0B"{print $1}')
    while read -r line;do
        echo zfs destroy $line
    done <<< "$snapshots"
    ```

将此脚本输出重定向到文件 `remove.sh` :

```
/bin/bash remove_empty_snapshots.sh > remove.sh
```

在核对 `remove.sh` 内容后,运行 `remove.sh` :

```
/bin/bash remove.sh
```
