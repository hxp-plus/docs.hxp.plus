---
tags:
  - Kubernetes
  - k8s
---

# 使用 Ansible 在 CentOS Stream 8 上安装 kubeadm


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Install kubeadm with ansible on CentOS Stream 8

## 本文使用的文件

k8s_hosts：

```
[control_plane]
192.168.100.21 hostname=k8s-1

[worker_nodes]
192.168.100.22 hostname=k8s-2
192.168.100.23 hostname=k8s-3

[all:vars]
control_plane_endpoint=192.168.100.10
```

00-prerequisites.YAML：

```
---
- name: Install and configure prerequisites
  hosts: all
  tasks:
  - name: Disable SElinux
    selinux:
      state: disabled
  - name: Enable kernel modules
    copy:
      content: |
        overlay
        br_netfilter
      dest: /etc/modules-load.d/k8s.conf
  - name: Forwarding IPv4 and letting iptables see bridged traffic
    copy:
      content: |
        net.bridge.bridge-nf-call-iptables  = 1
        net.bridge.bridge-nf-call-ip6tables = 1
        net.ipv4.ip_forward                 = 1
      dest: /etc/sysctl.d/k8s.conf
  - name: Disable firewalld
    systemd:
      name: firewalld
      state: stopped
      enabled: false
      masked: true
  - name: Disable swap
    lineinfile:
      path: /etc/fstab
      regexp: '.*\s*none\s*swap\s*.*$'
      state: absent
  - name: Reboot
    reboot:
      reboot_timeout: 3600
```

01-containerd.YAML：

```
---
- name: Install containerd, runc and CNI plugins
  hosts: all
  tasks:
  - name: Install containerd
    unarchive:
      src: files/containerd-1.7.2-linux-amd64.tar.gz
      dest: /usr/local
  - name: Install containerd systemd service
    copy:
      src: files/containerd.service
      dest: /etc/systemd/system/containerd.service
  - name: Enable containerd service
    systemd:
      name: containerd
      enabled: true
      state: started
      daemon_reload: true
  - name: Install runc
    copy:
      src: files/runc.amd64
      dest: /usr/local/sbin/runc
      mode: "0755"
  - name: Create directory /opt/cni/bin
    file:
      path: /opt/cni/bin
      state: directory
      recurse: yes
  - name: Install CNI plugins
    unarchive:
      src: files/cni-plugins-linux-amd64-v1.3.0.tgz
      dest: /opt/cni/bin
  - name: Generate default containerd config
    shell:
      cmd: |
        mkdir -p /etc/containerd/
        containerd config default > /etc/containerd/config.toml
  - name: Configure the systemd cgroup driver
    replace:
      path: /etc/containerd/config.toml
      regexp: "SystemdCgroup = false"
      replace: "SystemdCgroup = true"
  - name: Overriding the sandbox (pause) image
    replace:
      path: /etc/containerd/config.toml
      regexp: 'sandbox_image = "registry.k8s.io/pause:3.8"'
      replace: 'sandbox_image = "registry.k8s.io/pause:3.9"'
  - name: Restart containerd
    systemd:
      name: containerd
      state: restarted
```

02-kubeadm.YAML：

```
---
- name: Install kubeadm
  hosts: all
  tasks:
  - name: Install crictl
    unarchive:
      src: files/crictl-v1.27.0-linux-amd64.tar.gz
      dest: /usr/local/bin
  - name: Install kubeadm
    copy:
      src: files/kubeadm
      dest: /usr/local/bin
      mode: "0755"
  - name: Install kubelet
    copy:
      src: files/kubelet
      dest: /usr/local/bin
      mode: "0755"
  - name: Install kubectl
    copy:
      src: files/kubectl
      dest: /usr/local/bin
      mode: "0755"
  - name: Install bash-completion, socat, tc and conntrack
    yum:
      name: bash-completion,socat,tc,conntrack
  - name: Enable kubectl autocompletion
    lineinfile:
      path: /root/.bashrc
      line: "source <(kubectl completion bash)"
  - name: Install kubelet service
    copy:
      src: files/kubelet.service
      dest: /etc/systemd/system/kubelet.service
  - name: Create directory /etc/systemd/system/kubelet.service.d
    file:
      path: /etc/systemd/system/kubelet.service.d
      state: directory
      recurse: true
  - name: Install 10-kubeadm.conf
    copy:
      src: files/10-kubeadm.conf
      dest: /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  - name: Enable kubelet service
    systemd:
      name: kubelet
      daemon-reload: true
      enabled: true
      state: started
```

03-pull_images.YAML：

```
---
- name: Pull images
  hosts: all
  tasks:
  - name: Pull kubernetes container images
    shell:
      cmd: kubeadm config images pull
```

99-reset.YAML：

```
---
- name: Reset
  hosts: all
  tasks:
  - name: Reset
    shell:
      cmd: |
        kubeadm reset --force
        iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
```

## 步骤

安装 kubeadm：

```
ansible-playbook -i ../k8s_hosts 00-prerequisites.yaml
ansible-playbook -i ../k8s_hosts 01-containerd.yaml
ansible-playbook -i ../k8s_hosts 02-kubeadm.yaml
ansible-playbook -i ../k8s_hosts 03-pull_images.yaml
```

销毁 Kubernetes 集群：

```
ansible-playbook -i ../k8s_hosts 99-reset.yaml
```

# 参考链接

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/

---

## 原文（English）

---
tags:
  - Kubernetes
  - k8s
---

# Install kubeadm with ansible on CentOS Stream 8


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Files used in this document

k8s_hosts:

```
[control_plane]
192.168.100.21 hostname=k8s-1

[worker_nodes]
192.168.100.22 hostname=k8s-2
192.168.100.23 hostname=k8s-3

[all:vars]
control_plane_endpoint=192.168.100.10
```

00-prerequisites.YAML:

```
---
- name: Install and configure prerequisites
  hosts: all
  tasks:
  - name: Disable SElinux
    selinux:
      state: disabled
  - name: Enable kernel modules
    copy:
      content: |
        overlay
        br_netfilter
      dest: /etc/modules-load.d/k8s.conf
  - name: Forwarding IPv4 and letting iptables see bridged traffic
    copy:
      content: |
        net.bridge.bridge-nf-call-iptables  = 1
        net.bridge.bridge-nf-call-ip6tables = 1
        net.ipv4.ip_forward                 = 1
      dest: /etc/sysctl.d/k8s.conf
  - name: Disable firewalld
    systemd:
      name: firewalld
      state: stopped
      enabled: false
      masked: true
  - name: Disable swap
    lineinfile:
      path: /etc/fstab
      regexp: '.*\s*none\s*swap\s*.*$'
      state: absent
  - name: Reboot
    reboot:
      reboot_timeout: 3600
```

01-containerd.YAML:

```
---
- name: Install containerd, runc and CNI plugins
  hosts: all
  tasks:
  - name: Install containerd
    unarchive:
      src: files/containerd-1.7.2-linux-amd64.tar.gz
      dest: /usr/local
  - name: Install containerd systemd service
    copy:
      src: files/containerd.service
      dest: /etc/systemd/system/containerd.service
  - name: Enable containerd service
    systemd:
      name: containerd
      enabled: true
      state: started
      daemon_reload: true
  - name: Install runc
    copy:
      src: files/runc.amd64
      dest: /usr/local/sbin/runc
      mode: "0755"
  - name: Create directory /opt/cni/bin
    file:
      path: /opt/cni/bin
      state: directory
      recurse: yes
  - name: Install CNI plugins
    unarchive:
      src: files/cni-plugins-linux-amd64-v1.3.0.tgz
      dest: /opt/cni/bin
  - name: Generate default containerd config
    shell:
      cmd: |
        mkdir -p /etc/containerd/
        containerd config default > /etc/containerd/config.toml
  - name: Configure the systemd cgroup driver
    replace:
      path: /etc/containerd/config.toml
      regexp: "SystemdCgroup = false"
      replace: "SystemdCgroup = true"
  - name: Overriding the sandbox (pause) image
    replace:
      path: /etc/containerd/config.toml
      regexp: 'sandbox_image = "registry.k8s.io/pause:3.8"'
      replace: 'sandbox_image = "registry.k8s.io/pause:3.9"'
  - name: Restart containerd
    systemd:
      name: containerd
      state: restarted
```

02-kubeadm.YAML:

```
---
- name: Install kubeadm
  hosts: all
  tasks:
  - name: Install crictl
    unarchive:
      src: files/crictl-v1.27.0-linux-amd64.tar.gz
      dest: /usr/local/bin
  - name: Install kubeadm
    copy:
      src: files/kubeadm
      dest: /usr/local/bin
      mode: "0755"
  - name: Install kubelet
    copy:
      src: files/kubelet
      dest: /usr/local/bin
      mode: "0755"
  - name: Install kubectl
    copy:
      src: files/kubectl
      dest: /usr/local/bin
      mode: "0755"
  - name: Install bash-completion, socat, tc and conntrack
    yum:
      name: bash-completion,socat,tc,conntrack
  - name: Enable kubectl autocompletion
    lineinfile:
      path: /root/.bashrc
      line: "source <(kubectl completion bash)"
  - name: Install kubelet service
    copy:
      src: files/kubelet.service
      dest: /etc/systemd/system/kubelet.service
  - name: Create directory /etc/systemd/system/kubelet.service.d
    file:
      path: /etc/systemd/system/kubelet.service.d
      state: directory
      recurse: true
  - name: Install 10-kubeadm.conf
    copy:
      src: files/10-kubeadm.conf
      dest: /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  - name: Enable kubelet service
    systemd:
      name: kubelet
      daemon-reload: true
      enabled: true
      state: started
```

03-pull_images.YAML:

```
---
- name: Pull images
  hosts: all
  tasks:
  - name: Pull kubernetes container images
    shell:
      cmd: kubeadm config images pull
```

99-reset.YAML:

```
---
- name: Reset
  hosts: all
  tasks:
  - name: Reset
    shell:
      cmd: |
        kubeadm reset --force
        iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
```

## Procedures

To install kubeadm:

```
ansible-playbook -i ../k8s_hosts 00-prerequisites.yaml
ansible-playbook -i ../k8s_hosts 01-containerd.yaml
ansible-playbook -i ../k8s_hosts 02-kubeadm.yaml
ansible-playbook -i ../k8s_hosts 03-pull_images.yaml
```

To destroy the Kubernetes cluster:

```
ansible-playbook -i ../k8s_hosts 99-reset.yaml
```

# References

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/
