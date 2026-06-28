---
tags:
  - Linux
  - CIFS
---

# Linux 挂载 CIFS

首先安装 cifs-utils，然后编辑文件 `/etc/cifs-credentials`：

```text
username=[username]
password=[password]
```

修改文件权限：

```bash
chmod 600 /etc/cifs-credentials
chown root:root /etc/cifs-credentials
```

!!! warning

    密码文件权限必须严格限制为 `600`，否则 mount 时可能因权限过宽而拒绝读取。

在 `/etc/fstab` 追加挂载项：

```text
//[IP_address]/[share_name] /mnt/winshare cifs credentials=/etc/cifs-credentials,uid=1000,gid=1000,_netdev 0 0
```

挂载：

```bash
mkdir -p /mnt/winshare
systemctl daemon-reload
mount -a
```

!!! tip

    如果挂载失败，可用 `dmesg | tail` 查看内核报错信息。
