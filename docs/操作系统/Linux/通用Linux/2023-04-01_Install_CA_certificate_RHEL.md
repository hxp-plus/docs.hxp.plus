---
tags:
  - Linux
---

# 在 RHEL 上安装 CA 证书

原英文标题：References

1. Install ca-certificates
```bash
yum install ca-certificates
```

2. Enable the dynamic CA configuration feature
```bash
update-ca-trust enable
```

3. Put your CA.crt in `/etc/pki/ca-trust/source/anchors/`
```bash
vim /etc/pki/ca-trust/source/anchors/hxp-ca.crt
```

4. Update CA
```bash
update-ca-trust extract
```

5. Verify
```bash
curl https://speedtest.hxp.plus/
```

# References

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

<https://jermsmit.com/install-a-ca-certificate-on-red-hat-enterprise-linux/>
