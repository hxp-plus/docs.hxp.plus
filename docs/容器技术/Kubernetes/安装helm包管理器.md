---
tags:
  - Kubernetes
  - helm
---

## 准备工作

### 介质下载

| 介质名称                        | 下载地址                              |
| ------------------------------- | ------------------------------------- |
| helm-v3.14.0-linux-amd64.tar.gz | https://github.com/helm/helm/releases |

## 使用 Ansible Playbook 为所有 k8s 节点批量安装 helm

将 helm 二进制程序放到`/usr/local/bin/`即可完成安装，playbook 如下：

```title="helm-install.yaml"
---
- name: install helm
  hosts: k8s
  tasks:
  - name: unarchive files to remote /tmp
    unarchive:
      src: helm-v3.14.0-linux-amd64.tar.gz
      dest: /tmp/
  - name: install helm
    copy:
      src: /tmp/linux-amd64/helm
      dest: /usr/local/bin/helm
      mode: 0755
      remote_src: yes
```

## 参考链接

https://helm.sh/docs/intro/install/

https://stackoverflow.com/questions/50343089/how-to-use-helm-charts-without-internet-access

https://stackoverflow.com/questions/60892265/extract-docker-images-from-helm-chart
