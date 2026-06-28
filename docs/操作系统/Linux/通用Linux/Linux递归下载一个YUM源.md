---
tags:
  - Linux
---

推荐使用reposync下载：
```bash
yum install dnf-utils
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
reposync -c kylin10-x86.repo -p /mnt/kylin10-x86 --repo ks10-adv-os,ks10-adv-updates
```

也可以使用wget递归下载一个YUM源：

```bash
wget -np -P . -r -R "index.html*" --cut-dirs=6 https://update.cs2c.com.cn/NS/V10/V10SP1.1/os/adv/lic/updates/
```

其中`--cut-dirs`需要根据实际的远程目录层数进行调整，下载完成后需要检查wget有无报错。

# 参考链接


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

<https://rakeshjain-devops.medium.com/download-files-and-directories-from-web-using-curl-and-wget-9217bc2e34c9>
