---
tags:
  - VMware
  - 虚拟化
---

# 替换 vSphere 证书

原英文标题：vSphere Certificate Replacement

!!! warning "文档时效性说明"
本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## A. 生成证书

!!! warning "文档时效性说明"
本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

克隆此项目：<https://github.com/BenMorel/dev-certificates>

并运行：

```
cd dev-certificates
create-ca.sh
```

创建 CA，然后删除 `create-certificate.sh` 中的以下行：

```
DNS.2 = *.$DOMAIN
```

因为 VMware 不支持通配符证书。接着通过以下命令创建证书：

```
create-certificate.sh vcenter.hxp.plus
```

## B. 通过 SSH 登录 vCenter 并启动 Shell

```
[root@awx ~]# ssh root@vcenter.hxp.plus -p 22
Password:
Connected to service

    * List APIs: "help api list"
    * List Plugins: "help pi list"
    * Launch BASH: "shell"

Command> shell
Shell access is granted to root
root@vcenter [ ~ ]#
```

## C. 将证书复制到 /root

使用 vim 创建 ca、cert 和 key 文件，并粘贴之前生成的 ca、cert 和 key 内容。

## 启动证书管理器

```
root@vcenter [ ~ ]# /usr/lib/vmware-vmca/bin/certificate-manager
                 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
                |                                                                     |
                |      *** Welcome to the vSphere 7.0 Certificate Manager  ***        |
                |                                                                     |
                |                   -- Select Operation --                            |
                |                                                                     |
                |      1. Replace Machine SSL certificate with Custom Certificate     |
                |                                                                     |
                |      2. Replace VMCA Root certificate with Custom Signing           |
                |         Certificate and replace all Certificates                    |
                |                                                                     |
                |      3. Replace Machine SSL certificate with VMCA Certificate       |
                |                                                                     |
                |      4. Regenerate a new VMCA Root Certificate and                  |
                |         replace all certificates                                    |
                |                                                                     |
                |      5. Replace Solution user certificates with                     |
                |         Custom Certificate                                          |
                |         NOTE: Solution user certs will be deprecated in a future    |
                |         release of vCenter. Refer to release notes for more details.|
                |                                                                     |
                |      6. Replace Solution user certificates with VMCA certificates   |
                |                                                                     |
                |      7. Revert last performed operation by re-publishing old        |
                |         certificates                                                |
                |                                                                     |
                |      8. Reset all Certificates                                      |
                |_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _|
Note : Use Ctrl-D to exit.
Option[1 to 8]: 1

Please provide valid SSO and VC privileged user credential to perform certificate operations.
Enter username [Administrator@vsphere.local]:administrator@hxp.plus
Enter password:
         1. Generate Certificate Signing Request(s) and Key(s) for Machine SSL certificate

         2. Import custom certificate(s) and key(s) to replace existing Machine SSL certificate

Option [1 or 2]: 2

Please provide valid custom certificate for Machine SSL.
File : /root/vcenter.hxp.plus.crt

Please provide valid custom key for Machine SSL.
File : /root/vcenter.hxp.plus.key

Please provide the signing certificate of the Machine SSL certificate
File : /root/ca.crt

You are going to replace Machine SSL cert using custom cert
Continue operation : Option[Y/N] ? : Y
Command Output: /root/vcenter.hxp.plus.crt: OK

Status : 100% Completed [All tasks completed successfully]
```

## 参考

[Easily Replace vSphere Web Client Certificate](https://itomation.ca/easily-replace-vsphere-web-client-certificate/)

---

## 原文（English）

```
---
tags:
  - VMware
  - 虚拟化
---

## A. Generate certificate

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

Clone this project: <https://github.com/BenMorel/dev-certificates>

and run:

```

cd dev-certificates
create-ca.sh

```

to create a CA, and remove the line:

```

DNS.2 = \*.$DOMAIN

```

in `create-certificate.sh` since VMware does not support wildcard certificates. Then create certificate by:

```

create-certificate.sh vcenter.hxp.plus

```

## B. Login to vCenter via SSH and start a Shell

```

[root@AWX ~]# ssh root@vcenter.hxp.plus -p 22
Password:
Connected to service

    * List APIs: "help API list"
    * List Plugins: "help pi list"
    * Launch BASH: "shell"

Command> shell
Shell access is granted to root
root@vcenter [ ~ ]#

```

## C. Copy the certs to /root

Use vim to create the ca, cert and key, and paste the content of the ca, cert and key generated before.

## Lanuch certificate manager

```

root@vcenter [ ~ ]# /usr/lib/vmware-vmca/bin/certificate-manager
\_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ _
| |
| *** Welcome to the vSphere 7.0 Certificate Manager *** |
| |
| -- Select Operation -- |
| |
| 1. Replace Machine SSL certificate with Custom Certificate |
| |
| 2. Replace VMCA Root certificate with Custom Signing |
| Certificate and replace all Certificates |
| |
| 3. Replace Machine SSL certificate with VMCA Certificate |
| |
| 4. Regenerate a new VMCA Root Certificate and |
| replace all certificates |
| |
| 5. Replace Solution user certificates with |
| Custom Certificate |
| NOTE: Solution user certs will be deprecated in a future |
| release of vCenter. Refer to release notes for more details.|
| |
| 6. Replace Solution user certificates with VMCA certificates |
| |
| 7. Revert last performed operation by re-publishing old |
| certificates |
| |
| 8. Reset all Certificates |
|_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_ \_|
Note : Use Ctrl-D to exit.
Option[1 to 8]: 1

Please provide valid SSO and VC privileged user credential to perform certificate operations.
Enter username [Administrator@vsphere.local]:administrator@hxp.plus
Enter password: 1. Generate Certificate Signing Request(s) and Key(s) for Machine SSL certificate

         2. Import custom certificate(s) and key(s) to replace existing Machine SSL certificate

Option [1 or 2]: 2

Please provide valid custom certificate for Machine SSL.
File : /root/vcenter.hxp.plus.crt

Please provide valid custom key for Machine SSL.
File : /root/vcenter.hxp.plus.key

Please provide the signing certificate of the Machine SSL certificate
File : /root/ca.crt

You are going to replace Machine SSL cert using custom cert
Continue operation : Option[Y/N] ? : Y
Command Output: /root/vcenter.hxp.plus.crt: OK

Status : 100% Completed [All tasks completed successfully]

```

## References

[Easily Replace vSphere Web Client Certificate](https://itomation.ca/easily-replace-vsphere-web-client-certificate/)
```
