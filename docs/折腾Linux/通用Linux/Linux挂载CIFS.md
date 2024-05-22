---
tags:
  - Linux
  - CIFS
---

# Linux 挂载 CIFS

首先安装 cifs-utils，然后编辑文件`/etc/cifs-credentials`：

```
username=[username]
password=[password]
```

修改文件权限：

```bash
chmod 600 /etc/cifs-credentials
chown root:root /etc/cifs-credentials
```

在/etc/fstab 追加挂载项：

```
//[IP_address]/[share_name] /mnt/winshare cifs credentials=/etc/cifs-credentials,uid=1000,gid=1000,_netdev 0 0
```

挂载：

```bash
mkdir -p /mnt/winshare
systemctl daemon-reload
mount -a
```
