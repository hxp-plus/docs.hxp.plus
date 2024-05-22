---
tags:
  - Linux
---

# Linux 下载 yum 源

## 使用 reposync 下载

先创建 yum 源配置文件：

```bash
cat > kylin10-x86.repo <<-'EOF'
###Kylin Linux Advanced Server 10 - os repo###

[ks10-adv-os]
name = Kylin Linux Advanced Server 10 - Os
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1.1/os/adv/lic/base/$basearch/
gpgcheck = 0
enabled = 1

[ks10-adv-updates]
name = Kylin Linux Advanced Server 10 - Updates
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1.1/os/adv/lic/updates/$basearch/
gpgcheck = 0
enabled = 1

[ks10-adv-addons]
name = Kylin Linux Advanced Server 10 - Addons
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1.1/os/adv/lic/addons/$basearch/
gpgcheck = 0
enabled = 0
EOF
```

下载到 `/mnt/kylin10-x86` ：

```
dnf reposync -c kylin10-x86.repo -p /mnt/kylin10-x86 --repo ks10-adv-os,ks10-adv-updates
```

## 使用 wget 下载

也可以使用 wget 递归下载一个 YUM 源：

```bash
wget -np -P . -r -R "index.html*" --cut-dirs=6 https://update.cs2c.com.cn/NS/V10/V10SP1.1/os/adv/lic/updates/
```

其中`--cut-dirs`需要根据实际的远程目录层数进行调整，下载完成后需要检查 wget 有无报错。

# 参考链接

<https://rakeshjain-devops.medium.com/download-files-and-directories-from-web-using-curl-and-wget-9217bc2e34c9>
