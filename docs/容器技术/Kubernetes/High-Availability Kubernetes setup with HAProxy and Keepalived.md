---
tags:
  - Kubernetes
  - k8s
---

# High-Availability Kubernetes setup with HAProxy and Keepalived


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 本文使用的环境

| 主机名 | IP 地址 | 角色 |
|----------|------------|------|
| haproxy-1 | 192\.168.100.11 | 负载均衡器，VIP: 192.168.100.10 |
| haproxy-2 | 192\.168.100.12 | 负载均衡器，VIP: 192.168.100.10 |
| k8s-1 | 192\.168.100.21 | k8s master |
| k8s-2 | 192\.168.100.22 | k8s master |
| k8s-3 | 192\.168.100.23 | k8s master |

## Keepalived 配置

在主机 `haproxy-1` 上的 `/etc/keepalived/keepalived.conf`：

```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface enp1s0
    virtual_router_id 51
    priority 101
    authentication {
        auth_type PASS
        auth_pass 42
    }
    virtual_ipaddress {
        192.168.100.10
    }
    track_script {
        check_apiserver
    }
}
```

在主机 `haproxy-2` 上的 `/etc/keepalived/keepalived.conf`：

```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface enp1s0
    virtual_router_id 51
    priority 100
    authentication {
        auth_type PASS
        auth_pass 42
    }
    virtual_ipaddress {
        192.168.100.10
    }
    track_script {
        check_apiserver
    }
}
```

在 `haproxy-1` 和 `haproxy-2` 上的 `/etc/keepalived/check_apiserver.sh`：

```
#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
if ip addr | grep -q 192.168.100.10; then
    curl --silent --max-time 2 --insecure https://192.168.100.10:6443/ -o /dev/null || errorExit "Error GET https://192.168.100.10:6443/"
fi
```

## HAProxy 配置

在 `haproxy-1` 和 `haproxy-2` 上的 `/etc/haproxy/haproxy.cfg`：

```
# /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s

#---------------------------------------------------------------------
# apiserver frontend which proxys to the control plane nodes
#---------------------------------------------------------------------
frontend apiserver
    bind *:6443
    mode tcp
    option tcplog
    default_backend apiserver

#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
        server k8s-1 192.168.100.21:6443 check
        server k8s-2 192.168.100.22:6443 check
        server k8s-3 192.168.100.23:6443 check
```

记得添加执行权限：

```
chmod +x /etc/keepalived/check_apiserver.sh
```

## 启动服务

在 `haproxy-1` 和 `haproxy-2` 上：

```
systemctl enable haproxy --now
systemctl enable keepalived --now
```

# 配置 Kubernetes 集群

在 `k8s-01` 上，初始化控制平面：

```
kubeadm init --control-plane-endpoint=192.168.100.10 --apiserver-advertise-address=192.168.100.21 --pod-network-cidr="10.244.0.0/16" --upload-certs
```

```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join 192.168.100.10:6443 --token k4i43f.du1hk0dgpssmqon6 \
        --discovery-token-ca-cert-hash sha256:f7e6db5ca3e8e7f13f84a66e9b173ca21e9af675ef226e58025e1348ed99a426 \
        --control-plane --certificate-key 68ba3e6c511326fd22641ffe032d3cdfdf1e8f48481268a0c2d396a6e1121b21

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.100.10:6443 --token k4i43f.du1hk0dgpssmqon6 \
        --discovery-token-ca-cert-hash sha256:f7e6db5ca3e8e7f13f84a66e9b173ca21e9af675ef226e58025e1348ed99a426
```

在 `k8s-2` 上，加入集群：

```
kubeadm join 192.168.100.10:6443 --token k4i43f.du1hk0dgpssmqon6 \
        --discovery-token-ca-cert-hash sha256:f7e6db5ca3e8e7f13f84a66e9b173ca21e9af675ef226e58025e1348ed99a426 \
        --control-plane --certificate-key 68ba3e6c511326fd22641ffe032d3cdfdf1e8f48481268a0c2d396a6e1121b21 --apiserver-advertise-address=192.168.100.22
```

在 `k8s-3` 上：

```
kubeadm join 192.168.100.10:6443 --token k4i43f.du1hk0dgpssmqon6 \
        --discovery-token-ca-cert-hash sha256:f7e6db5ca3e8e7f13f84a66e9b173ca21e9af675ef226e58025e1348ed99a426 \
        --control-plane --certificate-key 68ba3e6c511326fd22641ffe032d3cdfdf1e8f48481268a0c2d396a6e1121b21 --apiserver-advertise-address=192.168.100.23
```

安装 flannel CNI 插件：

```
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

允许在控制平面节点上调度：

```
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

# 参考链接

https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/

---

## 原文（English）

---
tags:
  - Kubernetes
  - k8s
---

# High-Availability Kubernetes setup with HAProxy and Keepalived


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Environments used in this document

| hostname | IP Address | role |
|----------|------------|------|
| haproxy-1 | 192\.168.100.11 | load balancer with VIP: 192.168.100.10 |
| haproxy-2 | 192\.168.100.12 | load balancer with VIP: 192.168.100.10 |
| k8s-1 | 192\.168.100.21 | k8s master |
| k8s-2 | 192\.168.100.22 | k8s master |
| k8s-3 | 192\.168.100.23 | k8s master |

## Keepalived configuration

`/etc/keepalived/keepalived.conf` on host `haproxy-1` :

```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface enp1s0
    virtual_router_id 51
    priority 101
    authentication {
        auth_type PASS
        auth_pass 42
    }
    virtual_ipaddress {
        192.168.100.10
    }
    track_script {
        check_apiserver
    }
}
```

`/etc/keepalived/keepalived.conf` on host `haproxy-2` :

```
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface enp1s0
    virtual_router_id 51
    priority 100
    authentication {
        auth_type PASS
        auth_pass 42
    }
    virtual_ipaddress {
        192.168.100.10
    }
    track_script {
        check_apiserver
    }
}
```

`/etc/keepalived/check_apiserver.sh` on `haproxy-1` and `haproxy-2` :

```
#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
if ip addr | grep -q 192.168.100.10; then
    curl --silent --max-time 2 --insecure https://192.168.100.10:6443/ -o /dev/null || errorExit "Error GET https://192.168.100.10:6443/"
fi
```

## HAProxy configuration

`/etc/haproxy/haproxy.cfg` on `haproxy-1` and `haproxy-2` :

```
# /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s

#---------------------------------------------------------------------
# apiserver frontend which proxys to the control plane nodes
#---------------------------------------------------------------------
frontend apiserver
    bind *:6443
    mode tcp
    option tcplog
    default_backend apiserver

#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
        server k8s-1 192.168.100.21:6443 check
        server k8s-2 192.168.100.22:6443 check
        server k8s-3 192.168.100.23:6443 check
```

remember to add execute permission:

```
chmod +x /etc/keepalived/check_apiserver.sh
```

## Start the services

on `haproxy-1` and `haproxy-2` :

```
systemctl enable haproxy --now
systemctl enable keepalived --now
```

# Set up the Kubernetes cluster

on `k8s-01`, init the control plane :

```
kubeadm init --control-plane-endpoint=192.168.100.10 --apiserver-advertise-address=192.168.100.21 --pod-network-cidr="10.244.0.0/16" --upload-certs
```

```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join 192.168.100.10:6443 --token k4i43f.du1hk0dgpssmqon6 \
        --discovery-token-ca-cert-hash sha256:f7e6db5ca3e8e7f13f84a66e9b173ca21e9af675ef226e58025e1348ed99a426 \
        --control-plane --certificate-key 68ba3e6c511326fd22641ffe032d3cdfdf1e8f48481268a0c2d396a6e1121b21

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.100.10:6443 --token k4i43f.du1hk0dgpssmqon6 \
        --discovery-token-ca-cert-hash sha256:f7e6db5ca3e8e7f13f84a66e9b173ca21e9af675ef226e58025e1348ed99a426
```

on `k8s-2` , join the cluster :

```
kubeadm join 192.168.100.10:6443 --token k4i43f.du1hk0dgpssmqon6 \
        --discovery-token-ca-cert-hash sha256:f7e6db5ca3e8e7f13f84a66e9b173ca21e9af675ef226e58025e1348ed99a426 \
        --control-plane --certificate-key 68ba3e6c511326fd22641ffe032d3cdfdf1e8f48481268a0c2d396a6e1121b21 --apiserver-advertise-address=192.168.100.22
```

on `k8s-3` :

```
kubeadm join 192.168.100.10:6443 --token k4i43f.du1hk0dgpssmqon6 \
        --discovery-token-ca-cert-hash sha256:f7e6db5ca3e8e7f13f84a66e9b173ca21e9af675ef226e58025e1348ed99a426 \
        --control-plane --certificate-key 68ba3e6c511326fd22641ffe032d3cdfdf1e8f48481268a0c2d396a6e1121b21 --apiserver-advertise-address=192.168.100.23
```

install the flannel CNI plugin :

```
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

allow scheduling on the control plane :

```
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

# References

https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
